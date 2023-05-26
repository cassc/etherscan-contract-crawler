// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @title IVault
 * @notice Interface contract for Pods Vault
 * @author Pods Finance
 */
interface IVault is IERC4626, IERC20Permit {
    error IVault__CallerIsNotTheController();
    error IVault__NotProcessingDeposits();
    error IVault__AlreadyProcessingDeposits();
    error IVault__ForbiddenWhileProcessingDeposits();
    error IVault__ZeroAssets();
    error IVault__MigrationNotAllowed();
    error IVault__AssetsUnderMinimumAmount(uint256 assets);

    event FeeCollected(uint256 fee);
    event RoundStarted(uint32 indexed roundId, uint256 amountAddedToStrategy);
    event RoundEnded(uint32 indexed roundId);
    event DepositProcessed(address indexed owner, uint32 indexed roundId, uint256 assets, uint256 shares);
    event DepositRefunded(address indexed owner, uint32 indexed roundId, uint256 assets);
    event Migrated(address indexed caller, address indexed from, address indexed to, uint256 assets, uint256 shares);

    /**
     * @dev Describes the vault state variables.
     */
    struct VaultState {
        uint256 processedDeposits;
        uint256 totalIdleAssets;
        uint32 currentRoundId;
        uint40 lastEndRoundTimestamp;
        bool isProcessingDeposits;
    }

    struct Fractional {
        uint256 numerator;
        uint256 denominator;
    }

    /**
     * @notice Returns the current round ID.
     */
    function currentRoundId() external view returns (uint32);

    /**
     * @notice Determines whether the Vault is in the processing deposits state.
     * @dev While it's processing deposits, `processDeposits` can be called and new shares can be created.
     * During this period deposits, mints, withdraws and redeems are blocked.
     */
    function isProcessingDeposits() external view returns (bool);

    /**
     * @notice Returns the amount of processed deposits entering the next round.
     */
    function processedDeposits() external view returns (uint256);

    /**
     * @notice Returns the fee charged on withdraws.
     */
    function getWithdrawFeeRatio() external view returns (uint256);

    /**
     * @notice Returns the vault controller
     */
    function controller() external view returns (address);

    /**
     * @notice Outputs the amount of asset tokens of an `owner` is idle, waiting for the next round.
     */
    function idleAssetsOf(address owner) external view returns (uint256);

    /**
     * @notice Outputs the amount of asset tokens of an `owner` are either waiting for the next round,
     * deposited or committed.
     */
    function assetsOf(address owner) external view returns (uint256);

    /**
     * @notice Outputs the amount of asset tokens is idle, waiting for the next round.
     */
    function totalIdleAssets() external view returns (uint256);

    /**
     * @notice Outputs current size of the deposit queue.
     */
    function depositQueueSize() external view returns (uint256);

    /**
     * @notice Outputs addresses in the deposit queue
     */
    function queuedDeposits() external view returns (address[] memory);

    /**
     * @notice Deposit ERC20 tokens with permit, a gasless token approval.
     * @dev Mints shares to receiver by depositing exactly amount of underlying tokens.
     *
     * For more information on the signature format, see the EIP2612 specification:
     * https://eips.ethereum.org/EIPS/eip-2612#specification
     */
    function depositWithPermit(
        uint256 assets,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);

    /**
     * @notice Mint shares with permit, a gasless token approval.
     * @dev Mints exactly shares to receiver by depositing amount of underlying tokens.
     *
     * For more information on the signature format, see the EIP2612 specification:
     * https://eips.ethereum.org/EIPS/eip-2612#specification
     */
    function mintWithPermit(
        uint256 shares,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);

    /**
     * @notice Starts the next round, sending the idle funds to the
     * strategy where it should start accruing yield.
     * @return The new round id
     */
    function startRound() external returns (uint32);

    /**
     * @notice Closes the round, allowing deposits to the next round be processed.
     * and opens the window for withdraws.
     */
    function endRound() external;

    /**
     * @notice Withdraw all user assets in unprocessed deposits.
     */
    function refund() external returns (uint256 assets);

    /**
     * @notice Migrate assets from this vault to the next vault.
     * @dev The `newVault` will be assigned by the ConfigurationManager
     */
    function migrate() external;

    /**
     * @notice Handle migrated assets.
     * @return Estimation of shares created.
     */
    function handleMigration(uint256 assets, address receiver) external returns (uint256);

    /**
     * @notice Distribute shares to depositors queued in the deposit queue, effectively including their assets in the next round.
     *
     * @param depositors Array of owner addresses to process
     */
    function processQueuedDeposits(address[] calldata depositors) external;
}