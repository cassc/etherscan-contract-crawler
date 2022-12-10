// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface ILiquidCVaultV6 is IERC20{
    function strategy() external view returns (address);
    function want() external view returns (address);
    function balance() external view returns (uint);
    function available() external view returns (uint256);
    function getPricePerFullShare() external view returns (uint256);

    function depositAll() external;
    function deposit(uint _amount) external;
    function earn() external;
    function withdrawAll() external;
    function withdraw(uint256 _shares) external;
}