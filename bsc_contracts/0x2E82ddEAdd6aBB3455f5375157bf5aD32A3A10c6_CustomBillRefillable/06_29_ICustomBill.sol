// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./ICustomTreasury.sol";
import "./IVestingCurve.sol";

interface ICustomBill {
    /// @notice Info for bill holder
    /// @param payout Total payout value
    /// @param payoutClaimed Amount of payout claimed
    /// @param vesting Seconds left until vesting is complete
    /// @param vestingTerm Length of vesting in seconds
    /// @param vestingStartTimestamp Timestamp at start of vesting
    /// @param lastClaimTimestamp Last timestamp interaction
    /// @param truePricePaid Price paid (principal tokens per payout token) in ten-millionths - 4000000 = 0.4
    struct Bill {
        uint256 payout; 
        uint256 payoutClaimed;
        uint256 vesting;
        uint256 vestingTerm; 
        uint256 vestingStartTimestamp;
        uint256 lastClaimTimestamp; 
        uint256 truePricePaid; 
    }

    struct BillCreationDetails {
        address payoutToken;
        address principalToken;
        address initialOwner;
        IVestingCurve vestingCurve;
        uint256[] tierCeilings;
        uint256[] fees;
        bool feeInPayout;
    }

    struct BillTerms {
        uint256 controlVariable;
        uint256 vestingTerm;
        uint256 minimumPrice;
        uint256 maxPayout;
        uint256 maxDebt;
        uint256 maxTotalPayout;
        uint256 initialDebt;
    }

    struct BillAccounts {
        address treasury;
        address DAO;
        address billNft;
    }

    function initialize(
        ICustomTreasury _customTreasury,
        BillCreationDetails memory _billCreationDetails,
        BillTerms memory _billTerms,
        BillAccounts memory _billAccounts
    ) external;

    function customTreasury() external returns (ICustomTreasury);

    function claim(uint256 billId) external returns (uint256);

    function pendingVesting(uint256 billId) external view returns (uint256);

    function pendingPayout(uint256 billId) external view returns (uint256);

    function vestingPeriod(uint256 billId) external view returns (uint256 vestingStart_, uint256 vestingEnd_);

    function vestingPayout(uint256 billId) external view returns (uint256 vestingPayout_);

    function vestedPayoutAtTime(uint256 billId, uint256 timestamp) external view returns (uint256 vestedPayout_);

    function claimablePayout(uint256 billId) external view returns (uint256 claimablePayout_);

    function payoutToken() external view returns (IERC20MetadataUpgradeable);
    
    function principalToken() external view returns (IERC20MetadataUpgradeable);

    function getBillInfo(uint256 billId) external view returns (Bill memory);
}