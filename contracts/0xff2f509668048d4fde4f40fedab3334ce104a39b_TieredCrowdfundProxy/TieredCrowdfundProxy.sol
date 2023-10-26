/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.5;

/**
 * @title TieredCrowdfundStorage
 * @author MirrorXYZ
 */
contract TieredCrowdfundStorage {
    // The two states that this contract can exist in. "FUNDING" allows
    // contributors to add funds.
    enum Status {FUNDING, TRADING}

    // ============ Constants ============

    // The factor by which ETH contributions will multiply into crowdfund tokens.
    uint16 internal constant TOKEN_SCALE = 1000;
    uint256 internal constant REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant REENTRANCY_ENTERED = 2;
    uint8 public constant decimals = 18;

    // ============ Immutable Storage ============

    // The operator has a special role to change contract status.
    address payable public operator;
    address payable public fundingRecipient;
    // We add a hard cap to prevent raising more funds than deemed reasonable.
    uint256 public fundingCap;
    // The operator takes some equity in the tokens, represented by this percent.
    uint256 public operatorPercent;
    string public symbol;
    string public name;

    // ============ Mutable Storage ============

    // Represents the current state of the campaign.
    Status public status;
    uint256 internal reentrancy_status;

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


// File contracts/TieredCrowdfundProxy.sol


interface ITieredCrowdfundFactory {
    function mediaAddress() external returns (address);

    function logic() external returns (address);

    function editions() external returns (address);

    // ERC20 data.
    function parameters()
        external
        returns (
            address payable operator,
            address payable fundingRecipient,
            uint256 fundingCap,
            uint256 operatorPercent,
            string memory name,
            string memory symbol
        );
}

/**
 * @title TieredCrowdfundProxy
 * @author MirrorXYZ
 */
contract TieredCrowdfundProxy is TieredCrowdfundStorage {
    constructor() {
        logic = ITieredCrowdfundFactory(msg.sender).logic();
        editions = ITieredCrowdfundFactory(msg.sender).editions();
        // Crowdfund-specific data.
        (
            operator,
            fundingRecipient,
            fundingCap,
            operatorPercent,
            name,
            symbol
        ) = ITieredCrowdfundFactory(msg.sender).parameters();
        // Initialize mutable storage.
        status = Status.FUNDING;
    }

    fallback() external payable {
        address _impl = logic;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }

    receive() external payable {}
}