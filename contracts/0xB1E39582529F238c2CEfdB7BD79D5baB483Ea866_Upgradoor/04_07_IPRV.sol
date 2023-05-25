pragma solidity 0.8.16;

interface IPRV {
    function depositFor(address account, uint256 amount) external;
    function previewWithdraw(uint256 amount) external view returns (uint256);
    function AUXO() external view returns (address);
}