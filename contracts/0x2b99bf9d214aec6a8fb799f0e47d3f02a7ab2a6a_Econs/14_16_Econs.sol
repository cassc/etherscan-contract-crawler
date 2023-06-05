// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ERC20Permit.sol";

/**
 * @title ECONS ERC20 token
 * @notice This contract is used for common operations with
 * ERC20 token, claiming rewards from Econia, and operations
 * with Econia NFT's
 */
contract Econs is ERC20Permit, AccessControl {
    address public REWARDS;
    address public IEO;
    address public liquidityPool;
    address public SG_FOUNDATION;
    address public CORE_TEAM;
    address public PRIVATE_SALE;
    address public PARTNERSHIP;
    address public GROWTH;

    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    constructor(address[] memory wallets, uint256[] memory amounts)
        ERC20Permit("Econs")
        ERC20("Econs", "ECON")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Initial distribution
        REWARDS = wallets[0];
        IEO = wallets[1];
        liquidityPool = wallets[2];
        SG_FOUNDATION = wallets[3];
        CORE_TEAM = wallets[4];
        PRIVATE_SALE = wallets[5];
        PARTNERSHIP = wallets[6];
        GROWTH = wallets[7];

        _mint(REWARDS, amounts[0]);
        _mint(IEO, amounts[1]);
        _mint(liquidityPool, amounts[2]);
        _mint(SG_FOUNDATION, amounts[3]);
        _mint(CORE_TEAM, amounts[4]);
        _mint(PRIVATE_SALE, amounts[5]);
        _mint(PARTNERSHIP, amounts[6]);
        _mint(GROWTH, amounts[7]);
    }

    /**
     * @notice Use this function to get Econs tokens
     * @dev Signature parts are from signature of X wallet
     * @param wallet X wallet address
     * @param amount Amount of tokens to claim
     * @param _deadline Timestamp that represents signature activation period
     * @param v Part of signature
     * @param r Part of signature
     * @param s Part of signature
     */
    function claimTokens(
        address wallet, // signature from
        uint256 amount,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        permit(wallet, msg.sender, amount, _deadline, v, r, s);
        transferFrom(wallet, msg.sender, amount);
    }

    /**
     * @dev This function is for bridge contract only
     * @param to Address to mint to
     * @param amount Amount of tokens
     */
    function mintBridge(address to, uint256 amount)
        external
        onlyRole(BRIDGE_ROLE)
    {
        _mint(to, amount);
    }

    /**
     * @dev This function is for bridge contract only
     * @param from Address to burn from
     * @param amount Amount of tokens
     */
    function burnBridge(address from, uint256 amount)
        external
        onlyRole(BRIDGE_ROLE)
    {
        _burn(from, amount);
    }
}