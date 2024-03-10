pragma solidity 0.8.21;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {NotAuthorized, PricingKO, ColorAlreadyUsed, PriceTooLow, OnlyLivingsGetEpitaph, BadColor} from "./errors.sol";
import {IReaperGambitEpitaph} from "./interfaces/IReaperGambitEpitaph.sol";

import {BMPImage} from "../src/BMPEncoder.sol";
import {IPricing} from "../src/interfaces/IPricing.sol";

interface IERC20ReaperGambit is IERC20 {
    // Return block death number or 0 if immortal or unknown
    function decimals() external view returns (uint8);
    function KnowDeath(address account) external view returns (uint256);
}

interface BokkyPooBahsDateTimeContract {
    function timestampToDateTime(uint256 timestamp)
        external
        pure
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second);
}

contract ReaperGambitEpitaph is ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable, IReaperGambitEpitaph {
    bytes32 private constant STORAGE_V0_LOCATION = 0x9d87395271d3df9de7534803da3336e5683fec18ecaee2e38d1318d0ae243200; //keccak256(abi.encode(uint256(keccak256("rge.v0")) - 1)) & ~bytes32(uint256(0xff))
    // bytes32 private constant STORAGE_V0_LOCATION = keccak256(abi.encode(uint256(keccak256("rge.v0")) - 1)) & ~bytes32(uint256(0xff));

    using Strings for uint256;
    using Strings for address;

    struct Epitaph {
        uint256 id;
        uint32 color;
        bool isTag;
        address inMemoryOf;
        address owner;
        address colorOwner;
        uint256 birthDate;
        uint256 deathDate;
        uint256 deathBlock;
        uint256[] graffity;
    }

    /// @custom:storage-location erc7201:rge.v0
    struct StorageV0 {
        IERC20ReaperGambit rg;
        IPricing pricer;
        BMPImage renderer;
        uint256 totalSupply;
        mapping(uint256 => uint256) usedColor;
        mapping(uint256 => uint256[12 + 1]) epitaphs;
    }

    function _getStorageV0() private pure returns (StorageV0 storage $) {
        assembly {
            $.slot := STORAGE_V0_LOCATION
        }
    }

    function getStorage() public view returns (IPricing pricer, BMPImage renderer) {
        StorageV0 storage $ = _getStorageV0();
        return ($.pricer, $.renderer);
    }

    function setDependencies(address rg, address pricer, address renderer) public onlyOwner {
        StorageV0 storage $ = _getStorageV0();
        $.rg = IERC20ReaperGambit(rg);
        $.pricer = IPricing(pricer);
        $.renderer = BMPImage(renderer);
    }

    uint256 immutable flagTagPosition = 255;

    function initialize(BMPImage _renderer, IPricing _pricer) public initializer {
        __Ownable_init_unchained(msg.sender);
        __ERC721_init_unchained("Reaper Gambit Epitaph", unicode"+†+");
        __UUPSUpgradeable_init_unchained();
        StorageV0 storage $ = _getStorageV0();
        $.rg = IERC20ReaperGambit(0x2C91D908E9fab2dD2441532a04182d791e590f2d);
        $.renderer = _renderer;
        $.pricer = _pricer;
        $.totalSupply = 0;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    constructor() {
        _disableInitializers();
    }

    function totalSupply() public view returns (uint256) {
        return _getStorageV0().totalSupply;
    }

    function getEpitaph(uint256 tokenId) public view returns (Epitaph memory) {
        uint256[] memory dynArray = new uint256[](12);
        StorageV0 storage $ = _getStorageV0();
        uint256 extraData = $.epitaphs[tokenId][12];
        for (uint256 i = 0; i < 12; i++) {
            dynArray[i] = $.epitaphs[tokenId][i];
        }
        Epitaph memory ret = Epitaph(
            tokenId,
            uint32(extraData & 0xffffff),
            (extraData & (0x1 << flagTagPosition)) > 0,
            address(uint160((extraData) >> 24)),
            ownerOf(tokenId),
            address(uint160($.usedColor[extraData & 0xffffff] & ~((~0x00 >> 160) << 160))),
            _getBirthDate(extraData),
            _getBirthDate(extraData) + (64800 * 12), // Thanks to the merge the ethereum clock is more steady
            0,
            dynArray
        );
        ret.deathBlock = $.rg.KnowDeath(ret.inMemoryOf);
        return ret;
    }

    function mintEpitaphOf(uint256[12] calldata sig, uint256 color, address to, bytes memory coupon) public payable {
        _doMint(to, color, coupon);
        _updateEpitaphTo(to, _getStorageV0().totalSupply - 1, sig, color, to != msg.sender);
    }

    function calcPrice(uint256 color, bytes memory coupon) public returns (uint256) {
        StorageV0 storage $ = _getStorageV0();
        (uint256 price, uint256 _errno) = $.pricer.getPrice(color, coupon);
        if (_errno != 0) revert PricingKO({errno: _errno});
        if ($.usedColor[color] != 0) revert ColorAlreadyUsed();
        return price;
    }

    function _doMint(address to, uint256 color, bytes memory coupon) internal {
        StorageV0 storage $ = _getStorageV0();
        uint256 price = calcPrice(color, coupon);
        if (msg.value < price) revert PriceTooLow({minPrice: price});

        // cut 20% of commission for creator
        uint256 comfee = msg.value - ((msg.value * 80) / 100);
        address payable creator = payable(0x227ff44462065bc328f68747e1A16318b5577967); // MK
        (bool success,) = creator.call{value: comfee}("");
        if (!success) comfee = 0; // Artist comission transfer failed, everything goes to the DAO

        $.pricer.payment{value: msg.value - comfee}(msg.sender, to, owner());
        uint256 totalSupply_ = $.totalSupply + 1;
        _safeMint(msg.sender, totalSupply_ - 1);
        $.usedColor[color] = (uint256(uint160(msg.sender)) | (totalSupply_ - 1) << 160);
        $.totalSupply = totalSupply_;
    }

    function calculateAvgBlockTime(uint256 blockNumber) internal view returns (uint256) {
        if (blockNumber > block.number) {
            return ((blockNumber - block.number) * 12) + block.timestamp;
        } else {
            return block.timestamp - ((block.number - blockNumber) * 12);
        }
    }

    function _updateEpitaphTo(address to, uint256 tokenId, uint256[12] calldata sig, uint256 color, bool isTag)
        internal
    {
        StorageV0 storage $ = _getStorageV0();
        if (($.rg.KnowDeath(to) < block.number) && !isTag) revert OnlyLivingsGetEpitaph();
        if ((color & 0xffffff) == 0x000000) revert BadColor();
        // Setting msg.sender in stone
        uint256 extraData = (calculateAvgBlockTime($.rg.KnowDeath(to) - 64800) << 184) | (color & uint256(0xffffff));
        extraData =
            (extraData & (~uint256(0xffffffffffffffffffffffffffffffffffffffff000000))) | (uint256(uint160(to)) << 24); // Blankaddress slot
        extraData =
            (extraData & (~uint256(0x0000000000000000000000000000000000000000000000))) | (uint256(uint160(to)) << 24); // Set address
        if (isTag) extraData = extraData | (0x1 << flagTagPosition); // Add a flag for tag (when someone else than the owner update the epitaph)

        uint256[13] memory newparts = [
            sig[0],
            sig[1],
            sig[2],
            sig[3],
            sig[4],
            sig[5],
            sig[6],
            sig[7],
            sig[8],
            sig[9],
            sig[10],
            sig[11],
            extraData
        ];
        $.epitaphs[tokenId] = newparts;
    }

    function metadata(uint256 id) internal view returns (string memory) {
        return _metadata(getEpitaph(id));
    }

    function _metadata(Epitaph memory ep) public view returns (string memory) {
        StorageV0 storage $ = _getStorageV0();
        string memory desc;
        //adding wall text mentionning the minter, the used color, the block number and birth date
        desc = string(abi.encodePacked("Epitaph ", ep.id.toString()));

        if (ep.id % 2 == 0) desc = string(abi.encodePacked(desc, unicode"º"));
        else desc = string(abi.encodePacked(desc, unicode"ª"));

        (uint256 year, uint256 month, uint256 day,,,) =
            BokkyPooBahsDateTimeContract(0x23d23d8F243e57d0b924bff3A3191078Af325101).timestampToDateTime(ep.birthDate);
        desc = string(
            abi.encodePacked(
                desc,
                " \\n\\nIn memory of ",
                ep.inMemoryOf.toHexString(),
                unicode"\\n\\n",
                " - Color: ",
                uint256(ep.color).toHexString(),
                unicode" \\n",
                " - Owner: ",
                ep.owner.toHexString(),
                " \\n",
                " - Color owner: ",
                ep.colorOwner.toHexString(),
                " \\n",
                " - Birth date: ",
                year.toString(),
                "-",
                month.toString(),
                "-",
                day.toString(),
                " (block: ",
                (ep.deathBlock - 64800).toString(),
                ") \\n" " - Status: ",
                (ep.deathBlock < block.number ? "Dead" : "Alive"),
                " \\n",
                (ep.isTag ? " - Tag \\n" : "")
            )
        );
        return string(
            abi.encodePacked(
                '{"name":"',
                name(),
                '", "description":"',
                desc,
                '", "attributes": [{"memoryOf": "',
                ep.inMemoryOf.toHexString(),
                '"}, ',
                addRGBTraits(ep.color),
                ", ",
                addBoolTrait("tag", ep.isTag),
                ", ",
                addAddressTrait("colorOwner", ep.colorOwner),
                ", ",
                addAddressTrait("ownerOf", ep.owner),
                ", ",
                addDateTraits(year, month, day),
                abi.encodePacked('], "external_url": "', $.pricer.baseURI(), ep.id.toString()),
                '", "image":"',
                $.renderer.B64MimeEncode("image/bmp", BMP_(ep)),
                '"}'
            )
        );
    }

    function addRGBTraits(uint256 color) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                addIntTrait("Red", ((color & 0xFF0000) >> 16)),
                ", ",
                addIntTrait("Green", ((color & 0x00FF00) >> 8)),
                ", ",
                addIntTrait("Red", ((color & 0x0000FF)))
            )
        );
    }

    function addDateTraits(uint256 y, uint256 m, uint256 d) internal pure returns (string memory) {
        return
            string(abi.encodePacked(addIntTrait("Year", y), ", ", addIntTrait("Month", m), ", ", addIntTrait("Day", d)));
    }

    function addIntTrait(string memory key, uint256 value) internal pure returns (string memory) {
        return string(abi.encodePacked('{"', key, '": ', value.toString(), "}"));
    }

    function addAddressTrait(string memory key, address value) internal pure returns (string memory) {
        return string(abi.encodePacked('{"', key, '": "', value.toHexString(), '"}'));
    }

    function addBoolTrait(string memory key, bool value) internal pure returns (string memory) {
        return string(abi.encodePacked('{"', key, '": ', (value ? "true" : "false"), "}"));
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return _getStorageV0().renderer.B64MimeEncode("application/json", bytes(metadata(id)));
    }

    function _getBirthDate(uint256 data) internal pure returns (uint256) {
        return (data >> 184) & 0xffffffffffffffff; // birth date value mask
    }

    function convertArray(uint256[13] storage arr) internal view returns (uint256[] memory, uint256) {
        uint256[] memory convertedArr = new uint256[](12);
        for (uint256 i = 0; i < 12; i++) {
            convertedArr[i] = arr[i];
        }
        return (convertedArr, arr[12]);
    }

    function BMP(uint256 tokenId) public view returns (bytes memory) {
        return BMP_(getEpitaph(tokenId));
    }

    function BMP_(Epitaph memory ep) public view returns (bytes memory) {
        uint32 line = uint32(ep.graffity.length * 2);
        StorageV0 storage $ = _getStorageV0();
        BMPImage renderer = $.renderer;
        BMPImage.Image memory img = renderer.newImage(42 * 4 + 2, line + 16);

        uint32 x1 = 1;
        uint32 y1 = 8;
        uint32 y2 = 1;
        string memory s = ep.inMemoryOf.toHexString();

        img = renderer.drawString(img, x1, y2, s);
        if (ep.deathBlock == 0) {
            img = renderer.drawString(img, x1, y1 + y2 + 2 + 3, "immortal for now");
        } else {
            uint32 xmax = img.infoHeader.width - 2;
            uint32 ymax = img.infoHeader.height - 2;
            uint8 r = 128;
            uint8 g = 128;
            uint8 b = 128;

            if (ep.isTag) {
                img = renderer.drawSkipLine(
                    img, xmax - 128 - 3, ymax - (line + 3), xmax, ymax - 15, r, g, b, 255, uint32(block.number % 3)
                ); // top
                img = renderer.drawSkipLine(
                    img, xmax - 128 - 3, ymax - (line + 3), xmax - 128 - 3, ymax, r, g, b, 255, uint32(block.number % 3)
                ); // right
                img = renderer.drawSkipLine(
                    img, xmax, ymax - (line + 3), xmax, ymax, r, g, b, 255, uint32(block.number % 3)
                ); // left
                img =
                    renderer.drawSkipLine(img, xmax - 128 - 3, ymax, xmax, ymax, r, g, b, 255, uint32(block.number % 3)); // bottom
            } else {
                img = renderer.drawLine(img, xmax - 128 - 3, ymax - (line + 3), xmax, ymax - 15, r, g, b, 255); // top
                img = renderer.drawLine(img, xmax - 128 - 3, ymax - (line + 3), xmax - 128 - 3, ymax, r, g, b, 255); // right
                img = renderer.drawLine(img, xmax, ymax - (line + 3), xmax, ymax, r, g, b, 255); // left
                img = renderer.drawLine(img, xmax - 128 - 3, ymax, xmax, ymax, r, g, b, 255); // bottom
            }

            (uint256 year, uint256 month, uint256 day,,,) = BokkyPooBahsDateTimeContract(
                0x23d23d8F243e57d0b924bff3A3191078Af325101
            ).timestampToDateTime(ep.birthDate);
            img = renderer.drawNumber(img, x1, y1 + y2 + 2, year, 4);
            img = renderer.drawNumber(img, x1 + 4 * 4 + 2, y1 + y2 + 2, month, 2);
            img = renderer.drawNumber(img, x1 + 6 * 4 + 4, y1 + y2 + 2, day, 2);
            img = renderer.drawString(img, x1 + 2 * 4, y1 + y2 + 9, "birth");

            if (ep.deathBlock < block.number || msg.sender == ep.owner) {
                // RIP
                if (ep.deathBlock < block.number) {
                    img = renderer.drawString(img, x1 + 3 * 4, y1 + y2 + 16, "death");
                    (year, month, day,,,) = BokkyPooBahsDateTimeContract(0x23d23d8F243e57d0b924bff3A3191078Af325101)
                        .timestampToDateTime(ep.deathDate);
                    img = renderer.drawNumber(img, x1, y1 + y2 + 24, year, 4);
                    img = renderer.drawNumber(img, x1 + 4 * 4 + 2, y1 + y2 + 24, month, 2);
                    img = renderer.drawNumber(img, x1 + 6 * 4 + 4, y1 + y2 + 24, day, 2);
                }
                img = renderer.draw128pxLinesBitfield(img, xmax - 128 - 1, ymax - line - 1, ep.color, ep.graffity);
            } else {
                // ALIVE
                // calculate the remaining percent of the time and draw a line
                uint32 remaining = uint32((ep.deathBlock - block.number) * 100 / (64800));
                if (remaining != 0) {
                    remaining = ((img.infoHeader.width - x1 - 1) * remaining) / 100;
                    img = renderer.drawLine(img, x1, 5 + y2 + 1, x1 + remaining, y1 + y2 + 1, 128, 0, 0, 255);
                }
                img = renderer.drawLine(img, x1 + remaining, 5 + y2 + 1, x1 + remaining, y1 + y2 + 1, 209, 134, 38, 255);

                uint256 remainingSeconds = (ep.deathBlock - block.number) * 12;
                img = renderer.drawString(img, xmax - 128 - 1 + 4 * 4 - 2, y1 + y2 + 3 * 5, "Reveal in");
                img = renderer.drawDuration(img, xmax - 128 - 1 + 14 * 4 - 2, y1 + y2 + 3 * 5, remainingSeconds);
            }
        }
        return renderer.encode(img);
    }
}
