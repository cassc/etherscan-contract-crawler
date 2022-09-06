// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solmate/src/utils/ReentrancyGuard.sol";

import "./IGaugeRewardsDistributor.sol";
import "../Misc_AMOs/harmony/IERC20EthManager.sol";
import "../Misc_AMOs/polygon/IRootChainManager.sol";
import "../Misc_AMOs/solana/IWormhole.sol";
import "../Staking/Owned.sol";

contract MiddlemanGauge is Owned, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    /* ========== STATE VARIABLES ========== */

    address public immutable reward_token_address;

    // Instances and addresses
    address public rewards_distributor_address;

    // Informational
    string public name;

    // Admin addresses
    address public timelock_address;

    // Tracking
    uint32 public fake_nonce;

    // Gauge-related
    uint32 public bridge_type;
    address public bridge_address;
    address public destination_address_override;
    string public non_evm_destination_address;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(
            msg.sender == owner || msg.sender == timelock_address,
            "Not owner or timelock"
        );
        _;
    }

    modifier onlyRewardsDistributor() {
        require(
            msg.sender == rewards_distributor_address,
            "Not rewards distributor"
        );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _reward_token_address,
        address _timelock_address,
        address _rewards_distributor_address,
        address _bridge_address,
        uint32 _bridge_type,
        address _destination_address_override,
        string memory _non_evm_destination_address,
        string memory _name
    ) Owned(_owner) {
        reward_token_address = _reward_token_address;
        timelock_address = _timelock_address;

        rewards_distributor_address = _rewards_distributor_address;

        bridge_address = _bridge_address;
        bridge_type = _bridge_type;
        destination_address_override = _destination_address_override;
        non_evm_destination_address = _non_evm_destination_address;

        name = _name;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Callable only by the rewards distributor
    function pullAndBridge(uint256 reward_amount)
        external
        onlyRewardsDistributor
        nonReentrant
    {
        require(bridge_address != address(0), "Invalid bridge address");

        // Pull in the rewards from the rewards distributor
        ERC20(reward_token_address).safeTransferFrom(
            rewards_distributor_address,
            address(this),
            reward_amount
        );

        address address_to_send_to = address(this);
        if (destination_address_override != address(0))
            address_to_send_to = destination_address_override;

        if (bridge_type == 0) {
            // Avalanche [Anyswap]
            ERC20(reward_token_address).safeTransfer(
                bridge_address,
                reward_amount
            );
        } else if (bridge_type == 1) {
            // BSC
            ERC20(reward_token_address).safeTransfer(
                bridge_address,
                reward_amount
            );
        } else if (bridge_type == 2) {
            // Fantom [Multichain / Anyswap]
            // Bridge is 0xC564EE9f21Ed8A2d8E7e76c085740d5e4c5FaFbE
            ERC20(reward_token_address).safeTransfer(
                bridge_address,
                reward_amount
            );
        } else if (bridge_type == 3) {
            // Polygon
            // Bridge is 0xA0c68C638235ee32657e8f720a23ceC1bFc77C77
            // Interesting info https://blog.cryption.network/cryption-network-launches-cross-chain-staking-6cf000c25477

            // Approve
            IRootChainManager rootChainMgr = IRootChainManager(bridge_address);
            bytes32 tokenType = rootChainMgr.tokenToType(reward_token_address);
            address predicate = rootChainMgr.typeToPredicate(tokenType);
            ERC20(reward_token_address).approve(predicate, reward_amount);

            // DepositFor
            bytes memory depositData = abi.encode(reward_amount);
            rootChainMgr.depositFor(
                address_to_send_to,
                reward_token_address,
                depositData
            );
        } else if (bridge_type == 4) {
            // Solana
            // Wormhole Bridge is 0xf92cD566Ea4864356C5491c177A430C222d7e678

            revert("Not supported yet");

            // // Approve
            // ERC20(reward_token_address).approve(bridge_address, reward_amount);

            // // lockAssets
            // require(non_evm_destination_address != 0, "Invalid destination");
            // // non_evm_destination_address = base58 -> hex
            // // https://www.appdevtools.com/base58-encoder-decoder
            // IWormhole(bridge_address).lockAssets(
            //     reward_token_address,
            //     reward_amount,
            //     non_evm_destination_address,
            //     1,
            //     fake_nonce,
            //     false
            // );
        } else if (bridge_type == 5) {
            // Harmony
            // Bridge is at 0x2dccdb493827e15a5dc8f8b72147e6c4a5620857

            // Approve
            ERC20(reward_token_address).approve(bridge_address, reward_amount);

            // lockToken
            IERC20EthManager(bridge_address).lockToken(
                reward_token_address,
                reward_amount,
                address_to_send_to
            );
        }

        // fake_nonce += 1;
    }

    /* ========== RESTRICTED FUNCTIONS - Owner or timelock only ========== */

    // Added to support recovering LP Rewards and other mistaken tokens from other systems to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyByOwnGov
    {
        // Only the owner address can ever receive the recovery withdrawal
        ERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit RecoveredERC20(tokenAddress, tokenAmount);
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyByOwnGov returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        return (success, result);
    }

    function setTimelock(address _new_timelock) external onlyByOwnGov {
        timelock_address = _new_timelock;
    }

    function setBridgeInfo(
        address _bridge_address,
        uint32 _bridge_type,
        address _destination_address_override,
        string memory _non_evm_destination_address
    ) external onlyByOwnGov {
        bridge_address = _bridge_address;

        // 0: Avalanche
        // 1: BSC
        // 2: Fantom
        // 3: Polygon
        // 4: Solana
        // 5: Harmony
        bridge_type = _bridge_type;

        // Overridden cross-chain destination address
        destination_address_override = _destination_address_override;

        // Set bytes32 / non-EVM address on the other chain, if applicable
        non_evm_destination_address = _non_evm_destination_address;

        emit BridgeInfoChanged(
            _bridge_address,
            _bridge_type,
            _destination_address_override,
            _non_evm_destination_address
        );
    }

    function setRewardsDistributor(address _rewards_distributor_address)
        external
        onlyByOwnGov
    {
        rewards_distributor_address = _rewards_distributor_address;
    }

    /* ========== EVENTS ========== */

    event RecoveredERC20(address token, uint256 amount);
    event BridgeInfoChanged(
        address bridge_address,
        uint256 bridge_type,
        address destination_address_override,
        string non_evm_destination_address
    );
}