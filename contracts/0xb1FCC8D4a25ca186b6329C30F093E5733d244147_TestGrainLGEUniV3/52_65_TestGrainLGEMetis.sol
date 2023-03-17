// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../interfaces/IGrainLGE.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

error GrainLGE__WrongInput();
error GrainLGE__UnknownToken();
error GrainLGE__Unauthorized();
error GrainLGE__NotLive();
error GrainLGE__Completed();
error GrainLGE__NotCompleted();
error GrainLGE__DoesNotOwn();
error GrainLGE__BonusAlreadyClaimed();
error GrainLGE__NotWhitelisted();
error GrainLGE__GrainNotSet();
error GrainLGE__Slippage();

/// Grain Liquidity Generation Event contract, tailored for chains with a dominant uniswapV2-style DEX.
contract TestGrainLGEMetis is IGrainLGE, Ownable {
    using SafeERC20 for IERC20;

    /// Represent the max number of releasePeriod a vest can support
    /// If the longest vesting period is 8 years, and the tokens are
    /// released every 3 months, there should be 32 periods
    uint256 public constant MAX_KINK_RELEASES = 8; // 2 years
    uint256 public constant MAX_RELEASES = 20; // 5 years
    uint256 public constant PERIOD = 91 days; // 3 months
    uint256 public constant maxKinkDiscount = 4e26; // 40% premium for users with kink vesting
    uint256 public constant maxDiscount = 6e26; // 60% premium for users with maximum vesting
    uint256 public constant PERCENT_DIVISOR = 1e27;

    IERC20 public immutable grain;
    address public immutable unirouter;
    address public immutable treasury;
    mapping(address => address[]) public pathToUsdc;
    IERC20 public immutable usdc;
    uint256 public immutable lgeStart;
    uint256 public lgeEnd; // Probably 2 weeks after
    bool public gracePeriodOver;
    address[] public supportedTokens;

    /// Information related to user buying in the LGE
    /// usdcValue - How much user bought with in USDC
    /// numberOfReleases - How long a user is vesting
    /// weight - Numerical value representing the user's contribution
    /// totalClaimed - how much a user has already claimed
    /// nft - nft used for a bouns
    /// nftId - id of nft
    /// bonusWeight - added weight thanks to nft
    struct UserShare {
        uint256 usdcValue;
        uint256 numberOfReleases;
        uint256 weight;
        uint256 totalClaimed;
        address nft;
        uint256 nftId;
        uint256 bonusWeight;
    }
    mapping (address => UserShare) public userShares;

    /// @notice
    /// {whitelistedNfts} - NFTs that users can get a bonus of X% with. Users should only be able to get one of these
    /// {bonusReceiver} - NFT + ID returns user getting a bonus.
    mapping (address => uint256) public whitelistedBonuses;
    mapping (address => mapping(uint => address)) public bonusReceiver;

    /// How much has been raised in USDC
    uint256 public totalRaisedUsdc;
    uint256 public totalWeight;
    uint256 public totalGrain;

    constructor(address _grain, address _usdc, address _unirouter, address _treasury, uint256 _lgeStart) {
        grain = IERC20(_grain);
        usdc = IERC20(_usdc);
        unirouter = _unirouter;
        treasury = _treasury;
        lgeStart = _lgeStart;
        lgeEnd = lgeStart + 2 weeks;
        supportedTokens.push(_usdc);
    }

    ///----- * STOREFRONT * -----///

    /// @notice Allows a user to buy a share of the Grain LGE using {amount} of {token} and vesting for {numberOfReleases}
    /// @dev numberOfReleases has a max
    /// Set numberOfReleases to 0 to chose the no-vesting option
    function buy(address token, uint256 amount, uint256 minUsdcAmountOut, uint256 numberOfReleases, address onBehalfOf) public returns (uint256 usdcValue, uint256 vestingPremium) {
        /// Check for errors
        if (block.timestamp < lgeStart) {
            revert GrainLGE__NotLive();
        }
        if (onBehalfOf != msg.sender) {
            revert GrainLGE__Unauthorized();
        }
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (token != address(usdc) && pathToUsdc[token].length < 2) {
            revert GrainLGE__UnknownToken();
        }
        if (numberOfReleases > MAX_RELEASES) {
            revert GrainLGE__WrongInput();
        }

        /// Fetch tokens, turn into USDC if necessary
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        if (token == address(usdc)) {
            usdcValue = amount;
        } else {
            usdcValue = _swapTokenToUsdc(token, amount);
            if (usdcValue < minUsdcAmountOut) revert GrainLGE__Slippage();
        }

        /// If user has previously bought, we need to recalculate the weight, and remove it from total
        if (userShares[onBehalfOf].usdcValue != 0) {
            totalWeight -= _userTotalWeight(onBehalfOf);
        }

        if (numberOfReleases == 0) {
            vestingPremium = 0;
        } else if (numberOfReleases <= MAX_KINK_RELEASES) {
            // range from 0 to 40% discount
            vestingPremium = maxKinkDiscount * numberOfReleases / MAX_KINK_RELEASES;
        } else if (numberOfReleases <= MAX_RELEASES) {
            // range from 40% to 60% discount
            // ex: user goes for 20 (5 years) -> 60%
            vestingPremium = (((maxDiscount - maxKinkDiscount) * (numberOfReleases - MAX_KINK_RELEASES)) / (MAX_RELEASES - MAX_KINK_RELEASES)) + maxKinkDiscount;
        }

        /// Store values needed to calculate the user's share after the LGE's end
        userShares[onBehalfOf].usdcValue += usdcValue;
        userShares[onBehalfOf].numberOfReleases = numberOfReleases;

        userShares[onBehalfOf].weight = vestingPremium == 0 ? userShares[onBehalfOf].usdcValue : (userShares[onBehalfOf].usdcValue) * (PERCENT_DIVISOR / (PERCENT_DIVISOR - vestingPremium));
        if (userShares[onBehalfOf].nft != address(0)) {
            userShares[onBehalfOf].bonusWeight = userShares[onBehalfOf].weight * whitelistedBonuses[userShares[onBehalfOf].nft] / PERCENT_DIVISOR;
        }

        totalRaisedUsdc += usdcValue;
        totalWeight += _userTotalWeight(onBehalfOf);

        /// Transfer usdc to treasury
        /// Sending the whole balance should there be leftovers
        usdc.safeTransfer(treasury, usdc.balanceOf(address(this)));
    }

    /// @notice adds a bonus to the user final weight in the LGE
    /// @dev setting nft to address(0) should remove the bonus
    function addNftBonus(address nft, uint256 nftId, address onBehalfOf) public {
        if (block.timestamp < lgeStart) {
            revert GrainLGE__NotLive();
        }
        if (onBehalfOf != msg.sender) {
            revert GrainLGE__Unauthorized();
        }
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (whitelistedBonuses[nft] == 0) {
            revert GrainLGE__NotWhitelisted();
        }
        if (IERC721(nft).ownerOf(nftId) != onBehalfOf) {
            revert GrainLGE__DoesNotOwn();
        }
        if (bonusReceiver[nft][nftId] != address(0)) {
            /// Someone has already claimed this nft
            revert GrainLGE__BonusAlreadyClaimed();
        }

        /// Clears onBehalfOf's previous NFT ownership mapping (if any), so others can use previous NFT again
        bonusReceiver[userShares[onBehalfOf].nft][userShares[onBehalfOf].nftId] = address(0);

        totalWeight -= _userTotalWeight(onBehalfOf);

        userShares[onBehalfOf].nft = nft;
        userShares[onBehalfOf].nftId = nftId;
        userShares[onBehalfOf].bonusWeight = userShares[onBehalfOf].weight * whitelistedBonuses[nft] / PERCENT_DIVISOR;
        bonusReceiver[nft][nftId] = onBehalfOf;

        totalWeight += _userTotalWeight(onBehalfOf);
    }

    /// @dev combines the nft-less buy function and the function to add an nft
    function buy(
        address token,
        uint256 amount,
        uint256 minUsdcAmountOut,
        uint256 numberOfReleases,
        address onBehalfOf,
        address nft,
        uint256 nftId
    ) external returns (uint256 usdcValue, uint256 vestingPremium) {
        if (token != address(0)) {
            (usdcValue, vestingPremium) = buy(token, amount, minUsdcAmountOut, numberOfReleases, onBehalfOf);
        }
        if (nft != address(0)) {
            addNftBonus(nft, nftId, onBehalfOf);
        }
    }

    /// @notice Allows a user to claim all the tokens he can according to his share and the vesting duration he chose
    function claim() external returns (uint256 claimable) {
        if (gracePeriodOver == false) {
            revert GrainLGE__GrainNotSet();
        }
        claimable = pending(msg.sender);
        if (claimable != 0) {
            userShares[msg.sender].totalClaimed += claimable;
            grain.safeTransfer(msg.sender, claimable);
        }
    }

    ///----- * PUBLIC GARDEN * -----///

    /// @notice Get how much GRAIN a user can claim
    // Will handle differently a user that is vested and one who is not
    function pending(address user) public view returns (uint256 claimable) {
        /// Get how many periods user is claiming
        if (userShares[user].numberOfReleases == 0) {
            // No vest
            claimable = totalOwed(user) - userShares[user].totalClaimed;
        } else {
            // Vest
            uint256 periodsSinceEnd = (block.timestamp - lgeEnd) / PERIOD;
            if(periodsSinceEnd > userShares[user].numberOfReleases){
                periodsSinceEnd = userShares[user].numberOfReleases;
            }
            claimable = (totalOwed(user) * periodsSinceEnd / userShares[user].numberOfReleases) - userShares[user].totalClaimed;
        }
    }

    /// @notice Get how much GRAIN a user is owed by the end of his vesting
    function totalOwed(address user) public view returns (uint256 userTotal) {
        uint256 shareOfLge = _userTotalWeight(user) * PERCENT_DIVISOR / totalWeight;
        userTotal = (shareOfLge * totalGrain) / PERCENT_DIVISOR;
    }

    /// @notice Get how much GRAIN a user has yet to receive
    function userGrainLeft(address user) public view returns (uint256 grainLeft) {
        grainLeft = totalOwed(user) - userShares[user].totalClaimed;
    }

    /// @notice Check if nft collection is whitelisted
    function isNftWhitelisted(address nft) public view returns (bool isWhitelisted) {
        isWhitelisted = whitelistedBonuses[nft] != 0;
    }

    /// @notice Get list of suported tokens to buy with
    function getSupportedTokens() public view returns (address[] memory) {
        return supportedTokens;
    }

    function getSupportedTokensLength() public view returns (uint256 length) {
        length = supportedTokens.length;
    }

    ///----- * PRIVATE GREENHOUSE * -----///

    /// Swap tokens using a uniV2 protocol and router
    function _swapTokenToUsdc(address token, uint256 amount) internal returns (uint256 usdcValue) {
        if (amount == 0) {
            return 0;
        }

        uint256 usdcBalBefore = usdc.balanceOf(address(this));

        IERC20(token).safeIncreaseAllowance(unirouter, amount);
        IUniswapV2Router02(unirouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            pathToUsdc[token],
            address(this),
            block.timestamp
        );
        usdcValue = usdc.balanceOf(address(this)) - usdcBalBefore;
    }

    /// Returns user base weight + his bonus thanks to using an nft
    function _userTotalWeight(address user) internal view returns (uint256 userTotalWeight) {
        userTotalWeight = userShares[user].weight + userShares[user].bonusWeight;
    }

    ///----- * MINISTRY OF GRAINS * -----///

    /// @notice Set how many grain are to be distributed across the buyers
    function setTotalChainShare(uint256 grainAmount) external onlyOwner {
        if (block.timestamp <= lgeEnd) {
            revert GrainLGE__NotCompleted();
        }

        /// Fetch the tokens to guarantee the amount received
        grain.safeTransferFrom(msg.sender, address(this), grainAmount);
        totalGrain += grainAmount;

        gracePeriodOver = true;
    }

    /// @notice Add a token to the lsit of tokens that can be swapped, or update one's path
    function setPathToUsdc(address[] memory _path) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (_path[_path.length-1] != address(usdc)) {
            revert GrainLGE__WrongInput();
        }
        pathToUsdc[_path[0]] = _path;

        bool containsToken;
        for (uint256 i; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == _path[0]) {
                containsToken = true;
            }
        }

        if (containsToken == false) {
            supportedTokens.push(_path[0]);
        }
    }

    /// @notice Set bonus to a nft collection
    /// @dev There is no limit to the bonus, please use responsibly (10000 = 100% and is like a x2 multiplier)
    function setWhitelistedBonus(address nft, uint256 pctBonus) external onlyOwner {
        if (block.timestamp > lgeEnd) {
            revert GrainLGE__Completed();
        }
        if (pctBonus > 1e26) {
            revert GrainLGE__WrongInput();
        }
        whitelistedBonuses[nft] = pctBonus;
    }

    function setLgeEnd(uint256 timestamp) external onlyOwner {
        lgeEnd = timestamp;
    }
}