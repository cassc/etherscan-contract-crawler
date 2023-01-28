//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IAllowlist.1.sol";
import "./interfaces/IOperatorRegistry.1.sol";
import "./interfaces/IRiver.1.sol";
import "./interfaces/IELFeeRecipient.1.sol";

import "./components/ConsensusLayerDepositManager.1.sol";
import "./components/UserDepositManager.1.sol";
import "./components/SharesManager.1.sol";
import "./components/OracleManager.1.sol";
import "./Initializable.sol";
import "./Administrable.sol";

import "./state/river/AllowlistAddress.sol";
import "./state/river/OperatorsRegistryAddress.sol";
import "./state/river/CollectorAddress.sol";
import "./state/river/GlobalFee.sol";
import "./state/river/ELFeeRecipientAddress.sol";

/// @title River (v1)
/// @author Kiln
/// @notice This contract merges all the manager contracts and implements all the virtual methods stitching all components together
/// @notice
/// @notice    +---------------------------------------------------------------------+
/// @notice    |                                                                     |
/// @notice    |                           Consensus Layer                           |
/// @notice    |                                                                     |
/// @notice    | +-------------------+  +-------------------+  +-------------------+ |
/// @notice    | |                   |  |                   |  |                   | |
/// @notice    | |  EL Fee Recipient |  |      Oracle       |  |  Deposit Contract | |
/// @notice    | |                   |  |                   |  |                   | |
/// @notice    | +---------|---------+  +---------|---------+  +---------|---------+ |
/// @notice    +---------------------------------------------------------------------+
/// @notice                |         7            |            5         |
/// @notice                +-----------------|    |    |-----------------+
/// @notice                                  |    |6   |
/// @notice                                  |    |    |
/// @notice        +---------+          +----|----|----|----+            +---------+
/// @notice        |         |          |                   |     2      |         |
/// @notice        |Operator |          |       River       --------------  User   |
/// @notice        |         |          |                   |            |         |
/// @notice        +----|----+          +----|---------|----+            +---------+
/// @notice             |                    |         |
/// @notice             |             4      |         |       3
/// @notice             |1     +-------------|         |--------------+
/// @notice             |      |                                      |
/// @notice             |      |                                      |
/// @notice      +------|------|------------+           +-------------|------------+
/// @notice      |                          |           |                          |
/// @notice      |    Operators Registry    |           |         Allowlist        |
/// @notice      |                          |           |                          |
/// @notice      +--------------------------+           +--------------------------+
/// @notice
/// @notice      1. Operators are adding BLS Public Keys of validators running in their
/// @notice         infrastructure.
/// @notice      2. User deposit ETH to the system and get shares minted in exchange
/// @notice      3. Upon deposit, the system verifies if the User is allowed to deposit
/// @notice         by querying the Allowlist
/// @notice      4. When the system has enough funds to deposit validators, keys are pulled
/// @notice         from the Operators Registry
/// @notice      5. The deposit data is computed and the validators are funded via the official
/// @notice         deposit contract
/// @notice      6. Oracles report the total balance of the running validators and the total count
/// @notice         of running validators
/// @notice      7. The running validators propose blocks that reward the EL Fee Recipient. The funds
/// @notice         are pulled back in the system.
/// @notice
contract RiverV1 is
    ConsensusLayerDepositManagerV1,
    UserDepositManagerV1,
    SharesManagerV1,
    OracleManagerV1,
    Initializable,
    Administrable,
    IRiverV1
{
    /// @notice The mask for the deposit right
    uint256 internal constant DEPOSIT_MASK = 0x1;

    /// @inheritdoc IRiverV1
    function initRiverV1(
        address _depositContractAddress,
        address _elFeeRecipientAddress,
        bytes32 _withdrawalCredentials,
        address _oracleAddress,
        address _systemAdministratorAddress,
        address _allowlistAddress,
        address _operatorRegistryAddress,
        address _collectorAddress,
        uint256 _globalFee
    ) external init(0) {
        _setAdmin(_systemAdministratorAddress);

        CollectorAddress.set(_collectorAddress);
        emit SetCollector(_collectorAddress);

        GlobalFee.set(_globalFee);
        emit SetGlobalFee(_globalFee);

        ELFeeRecipientAddress.set(_elFeeRecipientAddress);
        emit SetELFeeRecipient(_elFeeRecipientAddress);

        AllowlistAddress.set(_allowlistAddress);
        emit SetAllowlist(_allowlistAddress);

        OperatorsRegistryAddress.set(_operatorRegistryAddress);
        emit SetOperatorsRegistry(_operatorRegistryAddress);

        ConsensusLayerDepositManagerV1.initConsensusLayerDepositManagerV1(
            _depositContractAddress, _withdrawalCredentials
        );

        OracleManagerV1.initOracleManagerV1(_oracleAddress);
    }

    /// @inheritdoc IRiverV1
    function getGlobalFee() external view returns (uint256) {
        return GlobalFee.get();
    }

    /// @inheritdoc IRiverV1
    function getAllowlist() external view returns (address) {
        return AllowlistAddress.get();
    }

    /// @inheritdoc IRiverV1
    function getCollector() external view returns (address) {
        return CollectorAddress.get();
    }

    /// @inheritdoc IRiverV1
    function getELFeeRecipient() external view returns (address) {
        return ELFeeRecipientAddress.get();
    }

    /// @inheritdoc IRiverV1
    function setGlobalFee(uint256 newFee) external onlyAdmin {
        GlobalFee.set(newFee);
        emit SetGlobalFee(newFee);
    }

    /// @inheritdoc IRiverV1
    function setAllowlist(address _newAllowlist) external onlyAdmin {
        AllowlistAddress.set(_newAllowlist);
        emit SetAllowlist(_newAllowlist);
    }

    /// @inheritdoc IRiverV1
    function setCollector(address _newCollector) external onlyAdmin {
        CollectorAddress.set(_newCollector);
        emit SetCollector(_newCollector);
    }

    /// @inheritdoc IRiverV1
    function setELFeeRecipient(address _newELFeeRecipient) external onlyAdmin {
        ELFeeRecipientAddress.set(_newELFeeRecipient);
        emit SetELFeeRecipient(_newELFeeRecipient);
    }

    /// @inheritdoc IRiverV1
    function getOperatorsRegistry() external view returns (address) {
        return OperatorsRegistryAddress.get();
    }

    /// @inheritdoc IRiverV1
    function sendELFees() external payable {
        if (msg.sender != ELFeeRecipientAddress.get()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
    }

    /// @notice Overriden handler to pass the system admin inside components
    /// @return The address of the admin
    function _getRiverAdmin()
        internal
        view
        override (OracleManagerV1, ConsensusLayerDepositManagerV1)
        returns (address)
    {
        return Administrable._getAdmin();
    }

    /// @notice Overriden handler called whenever a token transfer is triggered
    /// @param _from Token sender
    /// @param _to Token receiver
    function _onTransfer(address _from, address _to) internal view override {
        IAllowlistV1 allowlist = IAllowlistV1(AllowlistAddress.get());
        if (allowlist.isDenied(_from)) {
            revert Denied(_from);
        }
        if (allowlist.isDenied(_to)) {
            revert Denied(_to);
        }
    }

    /// @notice Overriden handler called whenever a user deposits ETH to the system. Mints the adequate amount of shares.
    /// @param _depositor User address that made the deposit
    /// @param _amount Amount of ETH deposited
    function _onDeposit(address _depositor, address _recipient, uint256 _amount) internal override {
        uint256 mintedShares = SharesManagerV1._mintShares(_depositor, _amount);
        IAllowlistV1 allowlist = IAllowlistV1(AllowlistAddress.get());
        if (_depositor == _recipient) {
            allowlist.onlyAllowed(_depositor, DEPOSIT_MASK); // this call reverts if unauthorized or denied
        } else {
            allowlist.onlyAllowed(_depositor, DEPOSIT_MASK); // this call reverts if unauthorized or denied
            if (allowlist.isDenied(_recipient)) {
                revert Denied(_recipient);
            }
            _transfer(_depositor, _recipient, mintedShares);
        }
    }

    /// @notice Overriden handler called whenever a deposit to the consensus layer is made. Should retrieve _requestedAmount or lower keys
    /// @param _requestedAmount Amount of keys required. Contract is expected to send _requestedAmount or lower.
    /// @return publicKeys Array of fundable public keys
    /// @return signatures Array of signatures linked to the public keys
    function _getNextValidators(uint256 _requestedAmount)
        internal
        override
        returns (bytes[] memory publicKeys, bytes[] memory signatures)
    {
        return IOperatorsRegistryV1(OperatorsRegistryAddress.get()).pickNextValidators(_requestedAmount);
    }

    /// @notice Overriden handler to pull funds from the execution layer fee recipient to River and return the delta in the balance
    /// @param _max The maximum amount to pull from the execution layer fee recipient
    /// @return The amount pulled from the execution layer fee recipient
    function _pullELFees(uint256 _max) internal override returns (uint256) {
        address elFeeRecipient = ELFeeRecipientAddress.get();
        if (elFeeRecipient == address(0)) {
            return 0;
        }
        uint256 initialBalance = address(this).balance;
        IELFeeRecipientV1(payable(elFeeRecipient)).pullELFees(_max);
        uint256 collectedELFees = address(this).balance - initialBalance;
        BalanceToDeposit.set(BalanceToDeposit.get() + collectedELFees);
        emit PulledELFees(collectedELFees);
        return collectedELFees;
    }

    /// @notice Overriden handler called whenever the balance of ETH handled by the system increases. Computes the fees paid to the collector
    /// @param _amount Additional ETH received
    function _onEarnings(uint256 _amount) internal override {
        uint256 oldTotalSupply = _totalSupply();
        if (oldTotalSupply == 0) {
            revert ZeroMintedShares();
        }
        uint256 newTotalBalance = _assetBalance();
        uint256 globalFee = GlobalFee.get();
        uint256 numerator = _amount * oldTotalSupply * globalFee;
        uint256 denominator = (newTotalBalance * LibBasisPoints.BASIS_POINTS_MAX) - (_amount * globalFee);
        uint256 sharesToMint = denominator == 0 ? 0 : (numerator / denominator);

        if (sharesToMint > 0) {
            address collector = CollectorAddress.get();
            _mintRawShares(collector, sharesToMint);
            uint256 newTotalSupply = _totalSupply();
            uint256 oldTotalBalance = newTotalBalance - _amount;
            emit RewardsEarned(collector, oldTotalBalance, oldTotalSupply, newTotalBalance, newTotalSupply);
        }
    }

    /// @notice Overriden handler called whenever the total balance of ETH is requested
    /// @return The current total asset balance managed by River
    function _assetBalance() internal view override returns (uint256) {
        uint256 clValidatorCount = CLValidatorCount.get();
        uint256 depositedValidatorCount = DepositedValidatorCount.get();
        if (clValidatorCount < depositedValidatorCount) {
            return CLValidatorTotalBalance.get() + BalanceToDeposit.get()
                + (depositedValidatorCount - clValidatorCount) * ConsensusLayerDepositManagerV1.DEPOSIT_SIZE;
        } else {
            return CLValidatorTotalBalance.get() + BalanceToDeposit.get();
        }
    }
}