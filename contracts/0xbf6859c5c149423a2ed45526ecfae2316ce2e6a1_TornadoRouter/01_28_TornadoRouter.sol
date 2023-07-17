// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// OZ Imports

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/Initializable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";

// Tornado Imports

import { ITornadoInstance } from "tornado-anonymity-mining/contracts/interfaces/ITornadoInstance.sol";

// Local imports

import { RelayerRegistry } from "./RelayerRegistry.sol";
import { FeeOracleManager } from "./FeeOracleManager.sol";
import { TornadoStakingRewards } from "./TornadoStakingRewards.sol";
import { InstanceRegistry, InstanceState } from "./InstanceRegistry.sol";

/**
 * @title TornadoRouter
 * @author AlienTornadosaurusHex
 * @notice This contract is a router for all Tornado Cash deposits and withdrawals
 * @dev This is an improved version of the TornadoRouter with a modified design from the original contract.
 */
contract TornadoRouter is Initializable {
    using SafeERC20 for IERC20;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ VARIABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /**
     * @notice The address of the Governance proxy
     */
    address public immutable governanceProxyAddress;

    /**
     * @notice The Instance Registry
     */
    InstanceRegistry public instanceRegistry;

    /**
     * @notice The Relayer Registry
     */
    RelayerRegistry public relayerRegistry;

    /**
     * @notice The Fee Oracle Manager
     */
    FeeOracleManager public feeOracleManager;

    /**
     * @notice The Staking Rewards contract
     */
    TornadoStakingRewards public stakingRewards;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ EVENTS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    event EncryptedNote(address indexed sender, bytes encryptedNote);
    event TokenApproved(address indexed spender, uint256 amount);

    event WithdrawalWithRelayer(
        address sender, address relayer, address instanceAddress, bytes32 nullifierHash
    );

    event InstanceRegistryUpdated(address newInstanceRegistryProxyAddress);
    event RelayerRegistryUpdated(address newRelayerRegistryProxyAddress);
    event FeeOracleManagerUpdated(address newFeeOracleManagerProxyAddress);
    event StakingRewardsUpdated(address newStakingRewardsProxyAddress);

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ LOGIC ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    constructor(address _governanceProxyAddress) public {
        governanceProxyAddress = _governanceProxyAddress;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceProxyAddress, "TornadoRouter: only governance");
        _;
    }

    modifier onlyInstanceRegistry() {
        require(msg.sender == address(instanceRegistry), "TornadoRouter: only instance registry");
        _;
    }

    function version() public pure virtual returns (string memory) {
        return "v2-infrastructure-upgrade";
    }

    function initialize(
        address _instanceRegistryProxyAddress,
        address _relayerRegistryProxyAddress,
        address _feeOracleManagerProxyAddress,
        address _stakingRewardsProxyAddress
    ) external onlyGovernance initializer {
        instanceRegistry = InstanceRegistry(_instanceRegistryProxyAddress);
        relayerRegistry = RelayerRegistry(_relayerRegistryProxyAddress);
        feeOracleManager = FeeOracleManager(_feeOracleManagerProxyAddress);
        stakingRewards = TornadoStakingRewards(_stakingRewardsProxyAddress);
    }

    /**
     * @notice Function to deposit into a Tornado instance. We don't really case if an external contract
     * breaks for deposit since deposits can go through the instances too if need be.
     * @param _tornado The instance to deposit into (address).
     * @param _commitment The commitment which will be added to the Merkle Tree.
     * @param _encryptedNote An encrypted note tied to the commitment which may be logged.
     */
    function deposit(ITornadoInstance _tornado, bytes32 _commitment, bytes calldata _encryptedNote)
        public
        payable
        virtual
    {
        (IERC20 token,, bool isERC20, bool isEnabled) = instanceRegistry.instanceData(_tornado);

        // Better than having it revert at safeTransferFrom
        require(isEnabled, "TornadoRouter: instance not enabled");

        if (isERC20) {
            token.safeTransferFrom(msg.sender, address(this), _tornado.denomination());
        }

        _tornado.deposit{ value: msg.value }(_commitment);

        emit EncryptedNote(msg.sender, _encryptedNote);
    }

    /**
     * @notice Withdraw from a Tornado Instance.
     * @param _tornado The Tornado instance to withdraw from.
     * @param _proof Bytes proof data.
     * @param _root A current or historical bytes32 root of the Merkle Tree within the proofs context.
     * @param _nullifierHash The bytes32 nullifierHash for the deposit.
     * @param _recipient The address of recipient for withdrawn funds.
     * @param _relayer The address of the relayer which will be making the withdrawal.
     * @param _fee The fee in bips to pay the relayer.
     * @param _refund If swapping into ETH on the other side, use this to specify how much should be paid for
     * it.
     */
    function withdraw(
        ITornadoInstance _tornado,
        bytes calldata _proof,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) public payable virtual {
        if (relayerRegistry.isRegistered(_relayer)) {
            // Check whether someone is impersonating a relayer or a relayer is avoiding
            require(relayerRegistry.isWorkerOf(_relayer, msg.sender), "TornadoRouter: invalid sender");

            // Check whether the instance is enabled
            require(instanceRegistry.isEnabledInstance(_tornado), "TornadoRouter: instance not enabled");

            // Get the fee for the instance
            uint256 fee = feeOracleManager.updateFee(_tornado, true);

            // Deduct the relayers balance
            relayerRegistry.deductBalance(msg.sender, _relayer, fee);

            // Add burn rewards
            stakingRewards.addBurnRewards(fee);
        }

        // Everything has been explained above. This just works normally then.
        _tornado.withdraw{ value: msg.value }(
            _proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund
        );
    }

    function backupNotes(bytes[] calldata _encryptedNotes) public virtual {
        for (uint256 i = 0; i < _encryptedNotes.length; i++) {
            emit EncryptedNote(msg.sender, _encryptedNotes[i]);
        }
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ SETTERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    function approveTokenForInstance(IERC20 _token, address _spender, uint256 _amount)
        external
        onlyInstanceRegistry
    {
        _token.safeApprove(_spender, _amount);
        emit TokenApproved(_spender, _amount);
    }

    function setInstanceRegistry(address _newInstanceRegistryProxyAddress) external onlyGovernance {
        instanceRegistry = InstanceRegistry(_newInstanceRegistryProxyAddress);
        emit InstanceRegistryUpdated(_newInstanceRegistryProxyAddress);
    }

    function setFeeOracleManager(address _newFeeOracleManagerProxyAddress) external onlyGovernance {
        feeOracleManager = FeeOracleManager(_newFeeOracleManagerProxyAddress);
        emit FeeOracleManagerUpdated(_newFeeOracleManagerProxyAddress);
    }

    function setStakingRewards(address _newStakingRewardsProxyAddress) external onlyGovernance {
        stakingRewards = TornadoStakingRewards(_newStakingRewardsProxyAddress);
        emit StakingRewardsUpdated(_newStakingRewardsProxyAddress);
    }

    function setRelayerRegistry(address _newRelayerRegistryProxyAddress) external onlyGovernance {
        relayerRegistry = RelayerRegistry(_newRelayerRegistryProxyAddress);
        emit RelayerRegistryUpdated(_newRelayerRegistryProxyAddress);
    }
}