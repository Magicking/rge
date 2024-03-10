pragma solidity 0.8.21;

interface IPricing {
    function getPrice(uint256 color) external returns (uint256 price, uint256 errno);
    function getPrice(uint256 color, bytes calldata proof) external returns (uint256 price, uint256 errno);
    function payment(address from, address destination, address dao) external payable;
    function baseURI() external view returns (string memory);
}

