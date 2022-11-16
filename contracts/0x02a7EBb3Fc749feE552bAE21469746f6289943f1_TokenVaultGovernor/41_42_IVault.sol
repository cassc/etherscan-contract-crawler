// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20Burnable} from "../libraries/openzeppelin/token/ERC20/IERC20Burnable.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IVault is IERC20Burnable {
    //

    function listTokens(uint256 _index) external view returns (address);

    function listIds(uint256 _index) external view returns (uint256);

    function listTokensLength() external view returns (uint256);

    function nftGovernor() external view returns (address);

    function curator() external view returns (address);

    function treasury() external view returns (address);

    function staking() external view returns (address);

    function government() external view returns (address);

    function bnft() external view returns (address);

    function exchange() external view returns (address);

    function decimals() external view returns (uint256);

    function initializeGovernorToken() external;

    function permitTransferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}