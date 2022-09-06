pragma solidity ^0.5.16;

contract LiquidityMiningInterface {
    function comptroller() external view returns (address);

    function updateSupplyIndex(address apeToken, address[] calldata accounts) external;

    function updateBorrowIndex(address apeToken, address[] calldata accounts) external;
}