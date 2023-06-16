pragma solidity 0.8.15;

interface IFrxEthMinter {
    function submitAndDeposit(address recipient) external payable returns (uint256 shares);

    function currentWithheldETH() external view returns (uint256);
}