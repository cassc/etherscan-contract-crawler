// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interface/IVault.sol";
import "./interface/IRouter.sol";

/// @title Glitter Finance router
/// @author Ackee Blockchain
/// @notice Glitter Finance central point of interaction
contract GlitterRouter is
    IRouter,
    Ownable2StepUpgradeable,
    PausableUpgradeable
{
    bytes32 public constant CONTRACT_ID = keccak256("GlitterRouter");
    uint32 public constant MIN_INACTIVE_PERIOD = 7 days;
    uint32 public constant MAX_INACTIVE_PERIOD = 21 days;
    mapping(address => bool) public vaults;
    uint16 public maxFeeRate;
    uint256 public inactivityPeriod;
    uint256 public lastActivity;
    address public recoverer;
    address public feeCollector;
    uint256 public nonce;

    modifier onlyRecoverer() {
        require(msg.sender == recoverer, "Router: caller is not the recoverer");
        _;
    }

    constructor() initializer {}

    /// @notice Initializer function
    /// @param _owner Owner address
    /// @param _recoverer Recoverer address
    /// @param _feeCollector Fee collector address
    /// @param _inactivityPeriod Inactivity period for upgrades
    function initialize(
        address _owner,
        address _recoverer,
        address _feeCollector,
        uint256 _inactivityPeriod
    ) public initializer {
        require(_owner != address(0), "Router: owner is zero-address");
        require(_recoverer != address(0), "Router: recoverer is zero-address");
        require(
            _inactivityPeriod >= MIN_INACTIVE_PERIOD,
            "Router: inactivity period too low"
        );
        require(
            _inactivityPeriod <= MAX_INACTIVE_PERIOD,
            "Router: inactivity period too high"
        );
        _setFeeCollector(_feeCollector);
        __Ownable2Step_init();
        __Pausable_init();
        _transferOwnership(_owner);
        recoverer = _recoverer;
        inactivityPeriod = _inactivityPeriod;
        lastActivity = block.timestamp;
        maxFeeRate = 200;
    }

    /// @notice Add a new vault into the router
    /// @param _vault Address of the new vault
    function addVault(address _vault) external onlyOwner {
        require(_vault != address(0), "Router: vault is zero-address");
        require(
            IVault(_vault).CONTRACT_ID() == keccak256("GlitterVault"),
            "Router: invalid vault contract"
        );
        vaults[_vault] = true;

        emit VaultAdd(_vault);
    }

    /// @notice Deposit tokens into the vault (source chain)
    /// @param _vault Address of the vault to deposit to
    /// @param _amount Amount of tokens
    /// @param _destinationChainId ID of the destination chain
    /// @param _destinationAddress Receiver address on the destination chain
    /// @param _protocolId ID of protocol
    function deposit(
        address _vault,
        uint256 _amount,
        uint16 _destinationChainId,
        bytes calldata _destinationAddress,
        uint32 _protocolId
    ) external payable whenNotPaused {
        require(vaults[_vault], "Router: vault does not exist");
        require(
            _destinationAddress.length != 0,
            "Router: destination is zero-address"
        );
        IVault(_vault).deposit{value: msg.value}(msg.sender, _amount);
        nonce++;
        emit BridgeDeposit(
            nonce,
            _vault,
            _amount,
            _destinationChainId,
            _destinationAddress,
            _protocolId
        );
    }

    /// @notice Release tokens from the vault (destination chain)
    /// @param _vault Address of the vault to release from
    /// @param _destinationAddress Destination address
    /// @param _amount Amount of tokens
    /// @param _feeRate Fee rate multiplied by BaseVault.FEE_DENOMINATOR
    /// @param _depositId Deposit ID calculated on BE
    function release(
        address _vault,
        address _destinationAddress,
        uint256 _amount,
        uint16 _feeRate,
        bytes32 _depositId
    ) external payable onlyOwner whenNotPaused {
        require(vaults[_vault], "Router: vault does not exist");
        require(
            _destinationAddress != address(0),
            "Router: destination is zero-address"
        );
        require(_feeRate <= maxFeeRate, "Router: value is higher than max fee");
        lastActivity = block.timestamp;
        IVault(_vault).release(_destinationAddress, _amount, _feeRate);
        nonce++;
        emit BridgeRelease(
            nonce,
            _vault,
            _destinationAddress,
            _amount,
            _feeRate,
            _depositId
        );
    }

    /// @notice Refund tokens to depositor (source chain)
    /// @param _vault Address of the vault to release from
    /// @param _destinationAddress Destination address
    /// @param _amount Amount of tokens
    /// @param _depositId Deposit ID calculated on BE
    function refund(
        address _vault,
        address _destinationAddress,
        uint256 _amount,
        bytes32 _depositId
    ) external payable onlyOwner whenNotPaused {
        require(vaults[_vault], "Router: vault does not exist");
        lastActivity = block.timestamp;
        IVault(_vault).refund(_destinationAddress, _amount);
        nonce++;
        emit BridgeRefund(
            nonce,
            _vault,
            _destinationAddress,
            _amount,
            _depositId
        );
    }

    /// @notice Set maximum fee rate
    /// @param _maxFeeRate Maximum fee rate multiplied by BaseVault.FEE_DENOMINATOR
    function setMaxFeeRate(uint16 _maxFeeRate) external onlyOwner {
        maxFeeRate = _maxFeeRate;
        emit SetMaxFeeRate(maxFeeRate);
    }

    /// @notice Set fee collector
    /// @param _feeCollector Fee collector address
    function setFeeCollector(address _feeCollector) external onlyOwner {
        _setFeeCollector(_feeCollector);
    }

    /// @notice Set fee collector (private)
    /// @param _feeCollector Fee collector address
    function _setFeeCollector(address _feeCollector) private {
        require(
            _feeCollector != address(0),
            "Router: fee collector is zero-address"
        );
        feeCollector = _feeCollector;
        emit SetFeeCollector(feeCollector);
    }

    /// @notice Pause the protocol
    function pause() external onlyRecoverer {
        _pause();
    }

    /// @notice Unpause the protocol
    function unpause() external onlyRecoverer {
        _unpause();
    }

    /// @notice Return true if release or refund has been called in inactivityPeriod
    function isActive() external view returns (bool) {
        return (lastActivity + inactivityPeriod > block.timestamp);
    }

    /// @notice Disable ownership renounce
    function renounceOwnership() public override onlyOwner {
        revert("Router: renounceOwnership is disabled");
    }
}