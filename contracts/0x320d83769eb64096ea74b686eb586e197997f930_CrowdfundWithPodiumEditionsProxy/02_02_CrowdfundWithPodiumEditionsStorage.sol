// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title CrowdfundWithPodiumEditionsStorage
 * @author MirrorXYZ
 */
contract CrowdfundWithPodiumEditionsStorage {
    // The two states that this contract can exist in. "FUNDING" allows
    // contributors to add funds.
    enum Status {
        FUNDING,
        TRADING
    }

    // ============ Constants ============

    // The factor by which ETH contributions will multiply into crowdfund tokens.
    uint16 internal constant TOKEN_SCALE = 1000;
    uint256 internal constant REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant REENTRANCY_ENTERED = 2;
    uint16 public constant PODIUM_TIME_BUFFER = 900;
    uint8 public constant decimals = 18;

    // ============ Immutable Storage ============

    // The operator has a special role to change contract status.
    address payable public operator;
    address payable public fundingRecipient;
    address public treasuryConfig;
    // We add a hard cap to prevent raising more funds than deemed reasonable.
    uint256 public fundingCap;
    uint256 public feePercentage;
    // The operator takes some equity in the tokens, represented by this percent.
    uint256 public operatorPercent;
    string public symbol;
    string public name;

    // ============ Mutable Storage ============

    // Represents the current state of the campaign.
    Status public status;
    uint256 internal reentrancy_status;


    // Podium storage
    uint256 public podiumStartTime;
    uint256 public podiumDuration;

    // ============ Mutable ERC20 Attributes ============

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    // ============ Delegation logic ============
    address public logic;

    // ============ Tiered Campaigns ============
    // Address of the editions contract to purchase from.
    address public editions;
}