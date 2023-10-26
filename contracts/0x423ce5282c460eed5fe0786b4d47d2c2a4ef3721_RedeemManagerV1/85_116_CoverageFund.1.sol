//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IRiver.1.sol";
import "./interfaces/IAllowlist.1.sol";
import "./interfaces/ICoverageFund.1.sol";

import "./libraries/LibUint256.sol";
import "./libraries/LibAllowlistMasks.sol";

import "./Initializable.sol";

import "./state/shared/RiverAddress.sol";
import "./state/slashingCoverage/BalanceForCoverage.sol";

/// @title Coverage Fund (v1)
/// @author Kiln
/// @notice This contract receive donations for the slashing coverage fund and pull the funds into river
/// @notice This contract acts as a temporary buffer for funds that should be pulled in case of a loss of money on the consensus layer due to slashing events.
/// @notice There is no fee taken on these funds, they are entirely distributed to the LsETH holders, and no shares will get minted.
/// @notice Funds will be distributed by increasing the underlying value of every LsETH share.
/// @notice The fund will be called on every report and if eth is available in the contract, River will attempt to pull as much
/// @notice ETH as possible. This maximum is defined by the upper bound allowed by the Oracle. This means that it might take multiple
/// @notice reports for funds to be pulled entirely into the system due to this upper bound, ensuring a lower secondary market impact.
/// @notice The value provided to this contract is computed off-chain and provided manually by Alluvial or any authorized insurance entity.
/// @notice The Coverage funds are pulled upon an oracle report, after the ELFees have been pulled in the system, if there is a margin left
/// @notice before crossing the upper bound. The reason behind this is to favor the revenue stream, that depends on market and network usage, while
/// @notice the coverage fund will be pulled after the revenue stream, and there won't be any commission on the eth pulled.
/// @notice Once a Slashing event occurs, the team will do its best to inject the recovery funds in at maximum 365 days
/// @notice The entities allowed to donate are selected by the team. It will mainly be treasury entities or insurance protocols able to fill this coverage fund properly.
contract CoverageFundV1 is Initializable, ICoverageFundV1 {
    /// @inheritdoc ICoverageFundV1
    function initCoverageFundV1(address _riverAddress) external init(0) {
        RiverAddress.set(_riverAddress);
        emit SetRiver(_riverAddress);
    }

    /// @inheritdoc ICoverageFundV1
    function pullCoverageFunds(uint256 _maxAmount) external {
        address river = RiverAddress.get();
        if (msg.sender != river) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        uint256 amount = LibUint256.min(_maxAmount, BalanceForCoverage.get());

        if (amount > 0) {
            BalanceForCoverage.set(BalanceForCoverage.get() - amount);
            IRiverV1(payable(river)).sendCoverageFunds{value: amount}();
        }
    }

    /// @inheritdoc ICoverageFundV1
    function donate() external payable {
        if (msg.value == 0) {
            revert EmptyDonation();
        }
        BalanceForCoverage.set(BalanceForCoverage.get() + msg.value);

        IAllowlistV1 allowlist = IAllowlistV1(IRiverV1(payable(RiverAddress.get())).getAllowlist());
        allowlist.onlyAllowed(msg.sender, LibAllowlistMasks.DONATE_MASK);

        emit Donate(msg.sender, msg.value);
    }

    /// @inheritdoc ICoverageFundV1
    receive() external payable {
        revert InvalidCall();
    }

    /// @inheritdoc ICoverageFundV1
    fallback() external payable {
        revert InvalidCall();
    }
}