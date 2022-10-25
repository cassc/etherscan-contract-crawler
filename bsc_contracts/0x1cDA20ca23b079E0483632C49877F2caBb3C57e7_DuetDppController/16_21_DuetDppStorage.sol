// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title DppStorage
/// @author So. Lu
/// @notice record dpp state
contract DuetDppStorage {
    // ============ pool info ===============
    address public _DPP_ADDRESS_;
    address public _DPP_ADMIN_ADDRESS_;
    IERC20Metadata public _BASE_TOKEN_;
    IERC20Metadata public _QUOTE_TOKEN_;
    uint64 public _LP_FEE_RATE_; // lp fee rate for dpp pool, unit is 10**18, range in [0, 10**18],eg 3,00000,00000,00000 = 0.003 = 0.3%
    uint128 public _I_; // base to quote price, decimals 18 - baseTokenDecimals+ quoteTokenDecimals. If use oracle, i set here wouldn't be used.
    uint64 public _K_; // a param for swap curve, limit in [0，10**18], unit is  10**18，0 is stable price curve，10**18 is bonding curve like uni

    // ============ Shares (ERC20) ============

    string public symbol;
    uint8 public decimals;
    string public name;

    uint256 public totalSupply;
    mapping(address => uint256) internal _SHARES_;
    mapping(address => mapping(address => uint256)) internal _ALLOWED_;

    // ================= Permit ======================

    uint256 public _CACHED_CHAIN_ID;
    bytes32 public _CACHED_DOMAIN_SEPARATOR;
    address public _CACHED_THIS;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;
}