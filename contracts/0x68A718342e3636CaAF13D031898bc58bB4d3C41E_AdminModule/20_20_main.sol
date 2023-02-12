// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "../../common/helpers.sol";
import "./events.sol";

import {IProxy} from "../../../infiniteProxy/IProxy.sol";

contract AdminModule is Helpers, Events {
    /***********************************|
    |              ERRORS               |
    |__________________________________*/
    error AdminModule__NotAuth();
    error AdminModule__NotSecondaryAuth();
    error AdminModule__MoreThanMaxRatio();
    error AdminModule__NotValidAddress();

    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/
    /// @notice reverts if msg.sender is not auth.
    modifier onlyAuth() {
        if (IProxy(address(this)).getAdmin() != msg.sender) {
            revert AdminModule__NotAuth();
        }
        _;
    }

    /// @notice reverts if msg.sender is not secondaryAuth or auth
    modifier onlySecondaryAuth() {
        if (
            !(secondaryAuth == msg.sender ||
                IProxy(address(this)).getAdmin() == msg.sender)
        ) {
            revert AdminModule__NotSecondaryAuth();
        }
        _;
    }

    /// Initializes the vault for asset_ for the ERC4626 vault.
    /// @param asset_ The base ERC20 asset address for the ERC4626 vault.
    /// @param secondaryAuth_ Secondary auth for vault.
    /// @param treasury_ Address that collects vault's revenue.
    /// @param rebalancers_ Array of rebalancers to enable.
    /// @param maxRiskRatio_ Array of max risk ratio allowed for protocols.
    /// @param withdrawalFeePercentage_ Initial withdrawalFeePercentage.
    /// @param withdrawFeeAbsoluteMin_ Initial withdrawFeeAbsoluteMin.
    /// @param revenueFeePercentage_ Initial revenueFeePercentage_.
    /// @param aggrMaxVaultRatio_ Aggregated max ratio of the vault.
    /// @param leverageMaxUnitAmountLimit_  Max limit (in wei) allowed for wsteth per eth unit amount.
    function initialize(
        string memory name_,
        string memory symbol_,
        address asset_,
        address secondaryAuth_,
        address treasury_,
        address[] memory rebalancers_,
        uint256[] memory maxRiskRatio_,
        uint256 withdrawalFeePercentage_,
        uint256 withdrawFeeAbsoluteMin_,
        uint256 revenueFeePercentage_,
        uint256 aggrMaxVaultRatio_,
        uint256 leverageMaxUnitAmountLimit_
    ) external initializer onlyAuth {
        __ERC20_init(name_, symbol_);
        __ERC4626_init(IERC20Upgradeable(asset_));

        // Setting vault status as open.
        _status = 1;

        // Build DSA and set this vault contract as owner.
        address vaultDsaAddress_ = INSTA_INDEX_CONTRACT.build(
            address(this),
            2,
            address(this)
        );
        vaultDSA = IDSA(vaultDsaAddress_);

        // Setting up secondary auth and treasury.
        updateSecondaryAuth(secondaryAuth_);
        updateTreasury(treasury_);

        // Enabling rebalancers.
        uint256 rebalancerlength_ = rebalancers_.length;
        for (uint i = 0; i < rebalancerlength_; i++) {
            updateRebalancer(rebalancers_[i], true);
        }

        // Setting max risk ratio for protocols starting from 1.
        uint length_ = maxRiskRatio_.length;
        uint8[] memory protocolIds_ = new uint8[](length_);

        for (uint8 i = 0; i < length_; i++) {
            protocolIds_[i] = i + 1; // First protocol Id is 1.
        }
        updateMaxRiskRatio(protocolIds_, maxRiskRatio_);

        // Setting up aggregated max ratio for vault.
        updateAggrMaxVaultRatio(aggrMaxVaultRatio_);

        // Setting up initial fee values.
        updateFees(
            revenueFeePercentage_,
            withdrawalFeePercentage_,
            withdrawFeeAbsoluteMin_
        );

        // Setting up initial leverage max wsteth per weth unit amount limit.
        updateLeverageMaxUnitAmountLimit(leverageMaxUnitAmountLimit_);

        // Setting initial exchange price as 1e18.
        exchangePrice = 1e18;

        // Setting initial revenue exchange price as 1e18.
        revenueExchangePrice = 1e18;

        string[] memory targets_ = new string[](1);
        bytes[] memory calldatas_ = new bytes[](1);

        // Enabling Aave V3 e-mode. E-mode can be enabled without any deposit.
        targets_[0] = "AAVE-V3-A";
        calldatas_[0] = abi.encodeWithSignature(
            "setUserEMode(uint8)",
            1, // WETH correlated mode
            0,
            0
        );

        vaultDSA.cast(targets_, calldatas_, address(this));
    }

    /// @notice Vault owner and secondary wuth can update the secondary auth.
    /// @param secondaryAuth_ New secondary auth to set.
    function updateSecondaryAuth(
        address secondaryAuth_
    ) public onlySecondaryAuth {
        if (secondaryAuth_ == address(0)) {
            revert AdminModule__NotValidAddress();
        }
        emit LogUpdateSecondaryAuth(secondaryAuth, secondaryAuth_);
        secondaryAuth = secondaryAuth_;
    }

    /// @notice Auth can add or remove allowed rebalancers
    /// @param rebalancer_ the address for the rebalancer to set the flag for
    /// @param isRebalancer_ flag for if rebalancer is allowed or not
    function updateRebalancer(
        address rebalancer_,
        bool isRebalancer_
    ) public onlySecondaryAuth {
        isRebalancer[rebalancer_] = isRebalancer_;
        emit LogUpdateRebalancer(rebalancer_, isRebalancer_);
    }

    /// @notice Auth can update the risk ratio for each protocol.
    /// @param protocolId_ The Id of the protocol to update the risk ratio.
    /// @param newRiskRatio_ New risk ratio of the protocol in terms of Eth and Steth, scaled to factor 4. i.e 1e6 = 100%, 1e4 = 1%
    /// Note Risk ratio is calculated in terms of `ETH` and `STETH` to maintain a common
    /// standard between protocols. (Risk ratio = Eth debt / Steth collateral).
    function updateMaxRiskRatio(
        uint8[] memory protocolId_,
        uint256[] memory newRiskRatio_
    ) public onlyAuth {
        uint256 length_ = protocolId_.length;

        /// @dev No condition to check if a ratio is valid (i.e. scaled to factor 4) since
        /// a protocol's risk ratio might be set to 0 in case assets will only be supplied.

        for (uint256 i_ = 0; i_ < length_; ++i_) {
            maxRiskRatio[protocolId_[i_]] = newRiskRatio_[i_];
            emit LogUpdateMaxRiskRatio(protocolId_[i_], newRiskRatio_[i_]);
        }
    }

    /// @notice Secondary auth can lower the risk ratio of any protocol.
    /// @param protocolId_ The Id of the protocol to reduce the risk ratio.
    /// @param newRiskRatio_ New risk ratio of the protocol in terms of Eth and Steth, scaled to factor 4. i.e 1e6 = 100%, 1e4 = 1%
    /// Note Risk ratio is calculated in terms of `ETH` and `STETH` to maintain a common
    /// standard between protocols. (Risk ratio = Eth debt / Steth collateral).
    function reduceMaxRiskRatio(
        uint8[] memory protocolId_,
        uint256[] memory newRiskRatio_
    ) public onlySecondaryAuth {
        uint256 length_ = protocolId_.length;

        /// @dev No condition to check if a ratio is valid (i.e. scaled to factor 4) since
        /// a protocol's risk ratio might be set to 0 in case assets will only be supplied.

        for (uint256 i_ = 0; i_ < length_; ++i_) {
            if (newRiskRatio_[i_] > maxRiskRatio[protocolId_[i_]]) {
                revert AdminModule__MoreThanMaxRatio();
            }
            maxRiskRatio[protocolId_[i_]] = newRiskRatio_[i_];
            emit LogUpdateMaxRiskRatio(protocolId_[i_], newRiskRatio_[i_]);
        }
    }

    /// @notice Auth can update the max risk ratio set for the vault.
    /// @param newAggrMaxVaultRatio_ New aggregated max ratio of the vault. Scaled to factor 4. i.e 1e6 = 100%, 1e4 = 1%
    function updateAggrMaxVaultRatio(
        uint256 newAggrMaxVaultRatio_
    ) public onlyAuth {
        emit LogUpdateAggrMaxVaultRatio(
            aggrMaxVaultRatio,
            newAggrMaxVaultRatio_
        );
        aggrMaxVaultRatio = newAggrMaxVaultRatio_;
    }

    /// @notice Secondary auth can reduce the max risk ratio set for the vault.
    /// @param newAggrMaxVaultRatio_ New aggregated max ratio of the vault. Scaled to factor 4. i.e 1e6 = 100%, 1e4 = 1%
    function reduceAggrMaxVaultRatio(
        uint256 newAggrMaxVaultRatio_
    ) public onlySecondaryAuth {
        if (newAggrMaxVaultRatio_ > aggrMaxVaultRatio) {
            revert AdminModule__MoreThanMaxRatio();
        }
        emit LogUpdateAggrMaxVaultRatio(
            aggrMaxVaultRatio,
            newAggrMaxVaultRatio_
        );
        aggrMaxVaultRatio = newAggrMaxVaultRatio_;
    }

    /// @notice Secondary auth can update the max wsteth per weth unit amount deviation limit.
    /// @param newLimit_ New limit to set.
    function updateLeverageMaxUnitAmountLimit(
        uint256 newLimit_
    ) public onlySecondaryAuth {
        emit LogUpdateLeverageMaxUnitAmountLimit(
            leverageMaxUnitAmountLimit,
            newLimit_
        );
        leverageMaxUnitAmountLimit = newLimit_;
    }

    /// @notice Auth can pause or resume all functionality of the vault.
    /// @param status_ New status of the vault.
    /// Note status = 1 => Vault functions are enabled; status = 2 => Vault functions are paused.
    function changeVaultStatus(uint8 status_) public onlySecondaryAuth {
        _status = status_;
        emit LogChangeStatus(status_);
    }

    /// @notice Auth can update the revenue and withdrawal fee percentage.
    /// @param revenueFeePercent_ New revenue fee percentage, scaled to factor 4. i.e 1e6 = 100%, 1e4 = 1%
    /// @param withdrawalFeePercent_ New withdrawal fee percentage, scaled to factor 4. i.e 1e6 = 100%, 1e4 = 1%
    /// @param withdrawFeeAbsoluteMin_ New withdraw fee absolute. 1 ETH = 1e18, 0.01 = 1e16
    function updateFees(
        uint256 revenueFeePercent_,
        uint256 withdrawalFeePercent_,
        uint256 withdrawFeeAbsoluteMin_
    ) public onlyAuth {
        revenueFeePercentage = revenueFeePercent_;
        withdrawalFeePercentage = withdrawalFeePercent_;
        withdrawFeeAbsoluteMin = withdrawFeeAbsoluteMin_;
        emit LogUpdateFees(
            revenueFeePercent_,
            withdrawalFeePercent_,
            withdrawFeeAbsoluteMin_
        );
    }

    /// @notice Auth can update the address that collected revenue.
    /// @param newTreasury_ Address that will collect the revenue.
    function updateTreasury(address newTreasury_) public onlyAuth {
        if (newTreasury_ == address(0)) {
            revert AdminModule__NotValidAddress();
        }
        emit LogUpdateTreasury(treasury, newTreasury_);
        treasury = newTreasury_;
    }
}