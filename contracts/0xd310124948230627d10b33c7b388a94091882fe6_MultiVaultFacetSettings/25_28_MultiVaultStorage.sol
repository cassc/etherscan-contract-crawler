// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/IEverscale.sol";
import "../../interfaces/multivault/IMultiVaultFacetTokens.sol";
import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawals.sol";
import "../../interfaces/multivault/IMultiVaultFacetLiquidity.sol";


library MultiVaultStorage {
    uint constant MAX_BPS = 10_000;
    uint constant FEE_LIMIT = MAX_BPS / 2;

    uint8 constant DECIMALS_LIMIT = 18;
    uint256 constant SYMBOL_LENGTH_LIMIT = 32;
    uint256 constant NAME_LENGTH_LIMIT = 32;

    string constant DEFAULT_NAME_PREFIX = '';
    string constant DEFAULT_SYMBOL_PREFIX = '';

    string constant DEFAULT_NAME_LP_PREFIX = 'Octus LP ';
    string constant DEFAULT_SYMBOL_LP_PREFIX = 'octLP';

    uint256 constant WITHDRAW_PERIOD_DURATION_IN_SECONDS = 60 * 60 * 24; // 24 hours

    // Previous version of the Vault contract was built with Upgradable Proxy Pattern, without using Diamond storage
    bytes32 constant MULTIVAULT_LEGACY_STORAGE_POSITION = 0x0000000000000000000000000000000000000000000000000000000000000002;

    uint constant LP_EXCHANGE_RATE_BPS = 10_000_000_000;

    struct Storage {
        mapping (address => IMultiVaultFacetTokens.Token) tokens_;
        mapping (address => IEverscale.EverscaleAddress) natives_;

        uint defaultNativeDepositFee;
        uint defaultNativeWithdrawFee;
        uint defaultAlienDepositFee;
        uint defaultAlienWithdrawFee;

        bool emergencyShutdown;

        address bridge;
        mapping(bytes32 => bool) withdrawalIds;
        IEverscale.EverscaleAddress rewards_;
        IEverscale.EverscaleAddress configurationNative_;
        IEverscale.EverscaleAddress configurationAlien_;

        address governance;
        address pendingGovernance;
        address guardian;
        address management;

        mapping (address => IMultiVaultFacetTokens.TokenPrefix) prefixes_;
        mapping (address => uint) fees;

        // STORAGE UPDATE 1
        // Pending withdrawals
        // - Counter pending withdrawals per user
        mapping(address => uint) pendingWithdrawalsPerUser;
        // - Pending withdrawal details
        mapping(address => mapping(uint256 => IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams)) pendingWithdrawals_;

        // - Total amount of pending withdrawals per token
        mapping(address => uint) pendingWithdrawalsTotal;

        // STORAGE UPDATE 2
        // Withdrawal limits per token
        mapping(address => IMultiVaultFacetPendingWithdrawals.WithdrawalLimits) withdrawalLimits_;

        // - Withdrawal periods. Each period is `WITHDRAW_PERIOD_DURATION_IN_SECONDS` seconds long.
        // If some period has reached the `withdrawalLimitPerPeriod` - all the future
        // withdrawals in this period require manual approve, see note on `setPendingWithdrawalsApprove`
        mapping(address => mapping(uint256 => IMultiVaultFacetPendingWithdrawals.WithdrawalPeriodParams)) withdrawalPeriods_;

        address withdrawGuardian;

        // STORAGE UPDATE 3
        mapping (address => IMultiVaultFacetLiquidity.Liquidity) liquidity;
        uint defaultInterest;

        // STORAGE UPDATE 4
        // - Receives native value, attached to the deposit
        address gasDonor;
        address weth;
    }

    function _storage() internal pure returns (Storage storage s) {
        assembly {
            s.slot := MULTIVAULT_LEGACY_STORAGE_POSITION
        }
    }
}