// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

// External Libraries
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@pooltogether/fixed-point/contracts/FixedPoint.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

// External Interfaces
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

// Local Libraries
import "./libraries/ExtendedSafeCast.sol";

/**
 * @title TokenDrop - Calculates Asset Distribution using Measure Token
 * @notice Calculates distribution of POOL rewards for users deposting into PoolTogether PrizePools using the Pod smart contract.
 * @dev A simplified version of the PoolTogether TokenFaucet that simplifies an asset token distribution using totalSupply calculations.
 * @author Kames Cox-Geraghty
 */
contract TokenDrop is ReentrancyGuardUpgradeable {
    /***********************************|
    |   Libraries                       |
    |__________________________________*/
    using SafeMathUpgradeable for uint128;
    using SafeMathUpgradeable for uint256;
    using ExtendedSafeCast for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /***********************************|
    |   Constants                       |
    |__________________________________*/
    /**
     * @notice The token that is being disbursed
     */
    IERC20Upgradeable public asset;

    /**
     * @notice The token that is user to measure a user's portion of disbursed tokens
     */
    IERC20Upgradeable public measure;

    /**
     * @notice The cumulative exchange rate of measure token supply : dripped tokens
     */
    uint112 public exchangeRateMantissa;

    /**
     * @notice The total amount of tokens that have been dripped but not claimed
     */
    uint112 public totalUnclaimed;

    /**
     * @notice The timestamp at which the tokens were last dripped
     */
    uint32 public lastDripTimestamp;

    /***********************************|
    |   Events                          |
    |__________________________________*/
    /**
     * @dev Emitted when the new asset tokens are added to the disbursement reserve
     */
    event Dropped(uint256 newTokens);

    /**
     * @dev Emitted when a User claims disbursed tokens
     */
    event Claimed(address indexed user, uint256 newTokens);

    /***********************************|
    |   Structs                         |
    |__________________________________*/
    struct UserState {
        uint128 lastExchangeRateMantissa;
        uint128 balance;
    }

    /**
     * @notice The data structure that tracks when a user last received tokens
     */
    mapping(address => UserState) public userStates;

    /***********************************|
    |   Initialize                      |
    |__________________________________*/
    /**
     * @notice Initialize TokenDrop Smart Contract
     * @dev Initialize TokenDrop Smart Contract with the measure (i.e. Pod) and asset (i.e. POOL) variables
     * @param _measure The token being tracked to calculate user asset rewards
     * @param _asset The token being rewarded when maintaining a positive balance of the "measure" token
     */
    function initialize(IERC20Upgradeable _measure, IERC20Upgradeable _asset)
        external
        initializer
    {
        require(address(_measure) != address(0), "Pod:invalid-measure-token");
        require(address(_asset) != address(0), "Pod:invalid-asset-token");

        // Initialize ReentrancyGuard
        __ReentrancyGuard_init();

        // Set measure/asset tokens.
        measure = _measure;
        asset = _asset;
    }

    /***********************************|
    |   Public/External                 |
    |__________________________________*/

    /**
     * @notice Should be called before "measure" tokens are transferred or burned
     * @param from The user who is sending the tokens
     * @param to The user who is receiving the tokens
     *@param token The token token they are burning
     */
    function beforeTokenTransfer(
        address from,
        address to,
        address token
    ) external {
        // must be measure and not be minting
        if (token == address(measure)) {
            // Calcuate to tokens balance
            _captureNewTokensForUser(to);

            // If NOT minting calcuate from tokens balance
            if (from != address(0)) {
                _captureNewTokensForUser(from);
            }
        }
    }

    /**
     * @notice Add Asset to TokenDrop and update with drop()
     * @dev Add Asset to TokenDrop and update with drop()
     * @param amount User account
     */
    function addAssetToken(uint256 amount) external returns (bool) {
        // Transfer asset/reward token from msg.sender to TokenDrop
        asset.safeTransferFrom(msg.sender, address(this), amount);

        // Update TokenDrop asset balance
        drop();

        // Return BOOL for transaction gas savings
        return true;
    }

    /**
     * @notice Claim asset rewards
     * @dev Claim asset rewards
     * @param user User account
     */
    function claim(address user) external returns (uint256) {
        UserState memory userState = _computeNewTokensForUser(user);

        uint256 balance = userState.balance;
        userState.balance = 0;
        userStates[user] = userState;

        totalUnclaimed = uint256(totalUnclaimed).sub(balance).toUint112();

        // Internal _nonReentrantTransfer
        _nonReentrantTransfer(user, balance);

        // Emit Claimed
        emit Claimed(user, balance);

        return balance;
    }

    /**
     * @notice Add asset tokens to disburment reserve
     * @dev Should be called immediately before any measure token mints/transfers/burns
     * @return The number of new tokens dropped
     */

    // change to drop
    function drop() public nonReentrant returns (uint256) {
        uint256 assetTotalSupply = asset.balanceOf(address(this));
        uint256 newTokens = assetTotalSupply.sub(totalUnclaimed);

        // if(newTokens > 0)
        if (newTokens > 0) {
            // Check measure token totalSupply()
            uint256 measureTotalSupply = measure.totalSupply();

            // Check measure supply exists
            if (measureTotalSupply > 0) {
                uint256 indexDeltaMantissa =
                    FixedPoint.calculateMantissa(newTokens, measureTotalSupply);
                uint256 nextExchangeRateMantissa =
                    uint256(exchangeRateMantissa).add(indexDeltaMantissa);

                exchangeRateMantissa = nextExchangeRateMantissa.toUint112();
                totalUnclaimed = uint256(totalUnclaimed)
                    .add(newTokens)
                    .toUint112();
                // Emit Dropped
                emit Dropped(newTokens);
            }
        }

        return newTokens;
    }

    /***********************************|
    |   Private/Internal                |
    |__________________________________*/

    /**
     * @dev Transfer asset with reenrancy protection
     * @param user User account
     * @param amount Transfer amount
     */
    function _nonReentrantTransfer(address user, uint256 amount)
        internal
        nonReentrant
    {
        asset.safeTransfer(user, amount);
    }

    /**
     * @notice Captures new tokens for a user
     * @dev This must be called before changes to the user's balance (i.e. before mint, transfer or burns)
     * @param user The user to capture tokens for
     * @return The number of new tokens
     */
    function _captureNewTokensForUser(address user)
        private
        returns (UserState memory)
    {
        UserState memory userState = _computeNewTokensForUser(user);

        userStates[user] = userState;

        return userState;
    }

    /**
     * @notice Compute new token disbursement for a user
     * @dev Calculates a user disbursement via the current measure token balance
     * @param user The user account
     * @return UserState struct
     */
    function _computeNewTokensForUser(address user)
        private
        view
        returns (UserState memory)
    {
        UserState memory userState = userStates[user];
        if (exchangeRateMantissa == userState.lastExchangeRateMantissa) {
            // ignore if exchange rate is same
            return userState;
        }
        uint256 deltaExchangeRateMantissa =
            uint256(exchangeRateMantissa).sub(
                userState.lastExchangeRateMantissa
            );
        uint256 userMeasureBalance = measure.balanceOf(user);
        uint128 newTokens =
            FixedPoint
                .multiplyUintByMantissa(
                userMeasureBalance,
                deltaExchangeRateMantissa
            )
                .toUint128();

        userState = UserState({
            lastExchangeRateMantissa: exchangeRateMantissa,
            balance: userState.balance.add(newTokens).toUint128()
        });

        return userState;
    }
}