// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFractonXERC20 {
    function erc20TransferFeerate() external view returns(uint256);
    function setFee(uint256 erc20TransferFeerate) external;
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}