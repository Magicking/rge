pragma solidity 0.8.21;

interface IReaperGambitEpitaph {
    function totalSupply() external view returns (uint256);
    function mintEpitaphOf(uint256[12] calldata sig, uint256 color, address to, bytes memory coupon) external payable;
    function BMP(uint256 tokenId) external view returns (bytes memory);
}
