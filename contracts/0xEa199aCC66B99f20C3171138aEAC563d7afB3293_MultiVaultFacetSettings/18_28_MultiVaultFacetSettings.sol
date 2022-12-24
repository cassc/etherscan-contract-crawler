// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/IEverscale.sol";
import "../../interfaces/multivault/IMultiVaultFacetTokens.sol";
import "../../interfaces/multivault/IMultiVaultFacetSettings.sol";
import "../../interfaces/multivault/IMultiVaultFacetSettingsEvents.sol";

import "../helpers/MultiVaultHelperInitializable.sol";
import "../helpers/MultiVaultHelperTokens.sol";
import "../helpers/MultiVaultHelperActors.sol";
import "../helpers/MultiVaultHelperFee.sol";

import "../storage/MultiVaultStorage.sol";
import "../storage/MultiVaultStorageInitializable.sol";


interface IERC173 {
    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);
}


contract MultiVaultFacetSettings is
    MultiVaultHelperInitializable,
    MultiVaultHelperActors,
    MultiVaultHelperFee,
    MultiVaultHelperTokens,
    IMultiVaultFacetSettings,
    IMultiVaultFacetSettingsEvents
{
    /// @notice MultiVault initializer
    /// @param _bridge Bridge address
    /// @param _governance Governance address
    function initialize(
        address _bridge,
        address _governance
    ) external override initializer {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.bridge = _bridge;
        s.governance = _governance;
    }

    /// @notice Rewards address
    /// @return Everscale address, used for collecting rewards.
    function rewards()
        external
        view
        override
    returns (IEverscale.EverscaleAddress memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.rewards_;
    }

    /// @notice Native configuration address
    /// @return Everscale address, used for verifying native withdrawals
    function configurationNative()
        external
        view
        override
    returns (IEverscale.EverscaleAddress memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.configurationNative_;
    }

    /// @notice Alien configuration address
    /// @return Everscale address, used for verifying alien withdrawals
    function configurationAlien()
        external
        view
        override
    returns (IEverscale.EverscaleAddress memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.configurationAlien_;
    }

    /// @notice Set address to receive fees.
    /// This may be called only by `governance`
    /// @param _rewards Rewards receiver in Everscale network
    function setRewards(
        IEverscale.EverscaleAddress memory _rewards
    ) external override onlyGovernance {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.rewards_ = _rewards;

        emit UpdateRewards(s.rewards_.wid, s.rewards_.addr);
    }

    /// @notice Set alien configuration address.
    /// @param _configuration The address to use for alien configuration.
    function setConfigurationAlien(
        IEverscale.EverscaleAddress memory _configuration
    ) external override onlyGovernance {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.configurationAlien_ = _configuration;

        emit UpdateConfiguration(
            IMultiVaultFacetTokens.TokenType.Alien,
            _configuration.wid,
            _configuration.addr
        );
    }

    /// @notice Set native configuration address.
    /// @param _configuration The address to use for native configuration.
    function setConfigurationNative(
        IEverscale.EverscaleAddress memory _configuration
    ) external override onlyGovernance {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.configurationNative_ = _configuration;

        emit UpdateConfiguration(
            IMultiVaultFacetTokens.TokenType.Native,
            _configuration.wid,
            _configuration.addr
        );
    }

    /// @notice Enable or upgrade withdrawal limits for specific token
    /// Can be called only by governance
    /// @param token Token address
    /// @param daily Daily withdrawal amount limit
    function setDailyWithdrawalLimits(
        address token,
        uint daily
    ) external override onlyGovernance {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(daily >= s.withdrawalLimits_[token].undeclared);

        s.withdrawalLimits_[token].daily = daily;
    }

    /// @notice Enable or upgrade withdrawal limits for specific token
    /// Can be called only by governance
    /// @param token Token address
    /// @param undeclared Undeclared withdrawal amount limit
    function setUndeclaredWithdrawalLimits(
        address token,
        uint undeclared
    ) external override onlyGovernance {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(s.withdrawalLimits_[token].daily >= undeclared);

        s.withdrawalLimits_[token].undeclared = undeclared;
    }

    /// @notice Disable withdrawal limits for specific token
    /// Can be called only by governance
    /// @param token Token address
    function disableWithdrawalLimits(
        address token
    ) external override onlyGovernance {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.withdrawalLimits_[token].enabled = false;
    }

    /// @notice Enable withdrawal limits for specific token
    /// Can be called only by governance
    /// @param token Token address
    function enableWithdrawalLimits(
        address token
    ) external override onlyGovernance {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.withdrawalLimits_[token].enabled = true;
    }

    /// @notice Nominate new address to use as a governance.
    /// The change does not go into effect immediately. This function sets a
    /// pending change, and the governance address is not updated until
    /// the proposed governance address has accepted the responsibility.
    /// This may only be called by the `governance`.
    /// @param _governance The address requested to take over Vault governance.
    function setGovernance(
        address _governance
    ) external override onlyGovernance {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.pendingGovernance = _governance;

        emit NewPendingGovernance(s.pendingGovernance);
    }

    /// @notice Once a new governance address has been proposed using `setGovernance`,
    /// this function may be called by the proposed address to accept the
    /// responsibility of taking over governance for this contract.
    /// This may only be called by the `pendingGovernance`.
    function acceptGovernance()
        external
        override
        onlyPendingGovernance
    {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.governance = s.pendingGovernance;

        emit UpdateGovernance(s.governance);
    }

    /// @notice Changes the management address.
    /// This may only be called by `governance`
    /// @param _management The address to use for management.
    function setManagement(
        address _management
    )
        external
        override
        onlyGovernance
    {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.management = _management;

        emit UpdateManagement(s.management);
    }

    /// @notice Changes the address of `guardian`.
    /// This may only be called by `governance`.
    /// @param _guardian The new guardian address to use.
    function setGuardian(
        address _guardian
    )
        external
        override
        onlyGovernance
    {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.guardian = _guardian;

        emit UpdateGuardian(s.guardian);
    }

    /// @notice Activates or deactivates MultiVault emergency shutdown.
    ///     During emergency shutdown:
    ///     - Deposits are disabled
    ///     - Withdrawals are disabled
    /// This may only be called by `governance` or `guardian`.
    /// @param active If `true`, the MultiVault goes into Emergency Shutdown. If `false`, the MultiVault goes back into
    ///     Normal Operation.
    function setEmergencyShutdown(
        bool active
    ) external override {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        if (active) {
            require(msg.sender == s.guardian || msg.sender == s.governance);
        } else {
            require(msg.sender == s.governance);
        }

        s.emergencyShutdown = active;
    }

    function setCustomNative(
        IEverscale.EverscaleAddress memory token,
        address custom
    ) external override onlyGovernance {
        require(IERC173(custom).owner() == address(this));

        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        address native = _getNativeToken(token);

        s.tokens_[native].custom = custom;
    }

    function setGasDonor(
        address _gasDonor
    ) external override onlyGovernance {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.gasDonor = _gasDonor;
    }

    function withdrawGuardian() external view override returns(address) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.withdrawGuardian;
    }

    function management() external view override returns(address) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.management;
    }

    function guardian() external view override returns(address) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.guardian;
    }

    function governance() external view override returns(address) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.governance;
    }

    function emergencyShutdown() external view override returns(bool) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.emergencyShutdown;
    }

    function bridge() external view override returns(address) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.bridge;
    }

    function gasDonor() external view override returns(address) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.gasDonor;
    }
}