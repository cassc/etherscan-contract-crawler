// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

pragma solidity 0.8.17;

/*
 * @title  pTON ERC20 token
 * @notice pTON wraps sTON token, which is a rebasing token to receive staking rewards from TON,
 *         to a classic ERC20 token via minting shares
 *         Vault is built on OpenZeppelin's ERC4626 Vault extension
 *         https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC4626
 *         and ERC20Permit extension with Multicall
 *         https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Permit
 *         https://docs.openzeppelin.com/contracts/4.x/utilities#multicall
 */
contract pTON is ERC4626, ERC20Permit, Multicall {
    constructor(
        string memory name_,
        string memory symbol_,
        IERC20 stTONaddress_
    ) ERC20(name_, symbol_) ERC20Permit(name_) ERC4626(stTONaddress_) {}

    function decimals() public view override(ERC4626, ERC20) returns (uint8) {
        return ERC4626.decimals();
    }
}