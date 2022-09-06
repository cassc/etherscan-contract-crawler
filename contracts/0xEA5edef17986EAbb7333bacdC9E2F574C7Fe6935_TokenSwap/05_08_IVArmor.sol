/// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVArmor is IERC20 {
    function vArmorToArmor(uint256 _varmor) external view returns (uint256);

    function armorToVArmor(uint256 _armor) external view returns (uint256);
}