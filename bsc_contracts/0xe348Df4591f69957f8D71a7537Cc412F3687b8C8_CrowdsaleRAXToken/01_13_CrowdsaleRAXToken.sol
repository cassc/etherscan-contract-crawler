// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/ICrowdsale.sol";
import "./interfaces/IWalletFactory.sol";
import "./interfaces/IRAX.sol";
import "./interfaces/IPancakeRouter.sol";


/**
 * @title Crowdsale
 */
contract CrowdsaleRAXToken is ICrowdsale, Ownable, Pausable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    /**
     * @dev Predefined max referral levels.
     */
    uint256 public constant REFERRAL_PROGRAM_LEVELS = 3;

    uint256 internal constant PERCENTAGE_DENOM = 10000;

    /**
     * @dev Getter for the price.
     */
    uint256 public immutable price;

    /**
     * @dev Getter for the raise.
     */
    uint256 public immutable raise;

    /**
     * @dev Getter for the min possible amountIn at time.
     */
    uint256 public minAmount;

    /**
     * @dev Getter for max possible amount total.
     */
    uint256 public maxAmount;

    /**
     * @dev Getter for sale start.
     */
    uint256 public start;

    /**
     * @dev Getter for duration.
     */
    uint256 public duration;

    /**
     * @dev Getter for the total RAX sold.
     */
    uint256 public totalSold;

    /**
     * @dev Getter for the total reward earned by all referrers.
     */
    uint256 public totalEarned;

    address public immutable BUSD; // 0xe9e7cea3dedca5984780bafc599bd69add087d56
    address public immutable USDT; // 0x55d398326f99059ff775485246999027b3197955
    address public immutable USDC; // 0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d
    address public immutable RAX;
    address public immutable pancakeRouter; // 0x10ed43c718714eb63d5aa57b78b54704e256024e
    
    /**
     * @dev Getter referres.
     */
    mapping(address => address) public referrers;

    /**
     * @dev Getter for spent amounts by user.
     */
    mapping(address => uint256) public spent;

    /**
     * @dev Getter for bought RAX amounts by user.
     */
    mapping(address => uint256) public bought;

    /**
     * @dev Getter for all level rewards by user.
     */
    mapping(address => uint256) public rewards;

    /**
     * @dev Factory address to create vesting wallets.
     */
    address internal _walletFactory;

    /**
     * @dev Internal vesting managers storage.
     */
    Vesting[] internal _vestingManagers;

    /**
     * @dev Internal vesting wallets storage.
     *
     * vestingManager => (beneficiary => wallet)
     */
    mapping(address => mapping(address => address)) internal _vestingWallets;

    modifier onlySalePeriod {
        require(block.timestamp >= start && block.timestamp < (start + duration), "Sale: sale not started or already finished");
        _;
    }

    modifier whenNotStarted {
        require(start == 0 || (start > 0 && block.timestamp < start), "Sale: sale already started");
        _;
    }

    /**
     * @param price_ The price for RAX token;
     * @param raise_ The target raise for this sale;
     * @param BUSD_ The BUSD address, preferable to buy for;
     * @param USDT_ The USDT address;
     * @param USDC_ The USDC_ address;
     * @param RAX_ The selling RAX address;
     * @param pancakeRouter_ The PancakeRouter address. Used to change BNB\USDT\USDC to BUSD;
     * @param walletFactory_ The IWalletFactory implementation.
     *
     * USDT, USDC and PancakeRouter are optional. In that case sale be possible only for BUSD.
     */
    constructor(uint256 price_, uint256 raise_, address BUSD_, address USDT_, address USDC_, address RAX_, address pancakeRouter_, address walletFactory_) {
        price = price_;
        raise = raise_;
        BUSD = BUSD_;
        USDT = USDT_;
        USDC = USDC_;
        RAX = RAX_;
        pancakeRouter = pancakeRouter_;
        _walletFactory = walletFactory_;
    }

    /**
     * @dev Getter for vesting managers count.
     */
    function getVestingManagersCount() external view virtual override returns (uint256) {
        return _vestingManagers.length;
    }

    /**
     * @dev Getter for vesting manager.
     *
     * @return The address of vesting manager and its distribution percentage.
     */
    function getVestingManager(uint256 index) external view virtual override returns (address, uint256) {
        return (_vestingManagers[index].vestingManager, _vestingManagers[index].distributionPercentage);
    }

    /**
     * @dev Getter for user's vesting wallet.
     */
    function getVestingWallets(address beneficiary) external view virtual override returns (address[] memory) {
        return _getVestingWallets(beneficiary);
    }

    /**
     * @dev Setter for the sale start.
     *
     * @param start_ in seconds, timestamp format.
     */
    function setStart(uint64 start_) external virtual override onlyOwner whenNotStarted {
        require(start_ > block.timestamp, "Sale: past timestamp");
        start = start_;
    }

    /**
     * @dev Setter for the sale duration.
     *
     * @param duration_ in seconds.
     */
    function setDuration(uint64 duration_) external virtual override onlyOwner whenNotStarted {
        duration = duration_;
    }

    /**
     * @dev Setter min possible amount for one beneficiary at time.
     */
    function setMinAmount(uint256 minAmount_) external virtual override onlyOwner whenNotStarted {
        minAmount = minAmount_;
    }

    /**
     * @dev Setter for total max possible amount for one beneficiary.
     */
    function setMaxAmount(uint256 maxAmount_) external virtual override onlyOwner whenNotStarted {
        maxAmount = maxAmount_;
    }

    /**
     * @dev Adds vesting manager.
     *
     * @param vestingManager_ The new vesting manager.
     * @param distributionPercentage_ The distribution percentage, with 3 decimals (100% is 10000).
     *
     * To start sale total sum of distributionPercentage of all managers have to be 10000 (100%).
     */
    function addVestingManager(address vestingManager_, uint256 distributionPercentage_) external virtual override onlyOwner whenNotStarted {
        uint256 distributionPercentageTotal = _getDistributionPercentageTotal();
        distributionPercentageTotal += distributionPercentage_;
        require(distributionPercentageTotal <= 10000, "Sale: wrong total distribution percentage");
        _vestingManagers.push(Vesting(vestingManager_, distributionPercentage_));
    }

    /**
     * @dev Removes vesting manager.
     */
    function removeVestingManager(uint256 index) external virtual override onlyOwner whenNotStarted {
        require(index < _vestingManagers.length, "Sale: wrong index");
        uint256 lastIndex = _vestingManagers.length - 1;
        _vestingManagers[index].vestingManager = _vestingManagers[lastIndex].vestingManager;
        _vestingManagers[index].distributionPercentage = _vestingManagers[lastIndex].distributionPercentage;
        _vestingManagers.pop();
    }

    /**
     * @dev Withdraws given `token` tokens from the contracts's account to owner.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function withdraw(address token) external virtual override onlyOwner {
        require(token != address(0), "Sale: zero address given");
        IERC20 tokenImpl = IERC20(token);
        tokenImpl.safeTransfer(msg.sender, tokenImpl.balanceOf(address(this)));
    }

    /**
     * @dev Triggers stopped state.
     */
    function pause() external virtual override onlyOwner onlySalePeriod {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     */
    function unpause() external virtual override onlyOwner onlySalePeriod {
        _unpause();
    }

    /**
     * @dev Buy tokens for `token`'s `amountIn`. 
     *
     * @param token For what token user want buy RAX. Can be BUSD\USDT\USDC\0x0. Use 0x0 and send value to buy RAX for BNB.
     *  USDT\USDC\BNB will be changed to BUSD 'on the fly';
     * @param amountIn Amount for which user want to buy RAX;
     * @param minAmountOut Min amount out in terms of PancakeRouter. Have to be given if token is USDT\USDC\BNB, 
     *  otherwise have to be 0;
     * @param referrer The referrer, if present. If possible will be set in the RAX token too, to get rewards from future
     *  transfers.
     *
     * Can be used only in sale period.
     *
     * Can be paused by owner in emergency case.
     *
     * minAmountOut can be get from PancakeRouter:
     *  - to deduct PancakeRouter's fee from amountIn (will not work with if amountIn is equal with minAmountIn set in sale):
     *      const minAmountOut = pancakeRouter.getAmountsOut(amountIn, [USDT, BUSD])
     *  - or add it amountIn before call:
     *      const amountsIn = pancakeRouter.getAmountsIn(amountOut, [USDT, BUSD])
     *      const minAmountOut = amountsIn[0]
     *      
     * Emits {TokenTransferred} event;
     * Emits {TokenSold} event;
     * Emits {RewardEarned} event if referrer provided;
     * Emits few {Transfer} event.
     */
    function buy(address token, uint256 amountIn, uint256 minAmountOut, address referrer) external payable virtual override onlySalePeriod whenNotPaused nonReentrant {
        _buy(token, amountIn, minAmountOut, referrer);
    }

    function _buy(address token, uint256 amountIn, uint256 minAmountOut, address referrer) internal {
        require(_getDistributionPercentageTotal() == 10000, "Sale: vestings are not correct");
        require(token == BUSD || token == USDT || token == USDC || (token == address(0) && msg.value > 0), "Sale: wrong asset or value");
        if (referrer != address(0)) {
            address existingReferrer = referrers[msg.sender];
            if (existingReferrer != address(0)) {
                require(existingReferrer == referrer, "Sale: referrer already set");
            }
            // check is referrer have vesting wallet
            address[] memory wallets = _getVestingWallets(referrer);
            // can check only first element, cause there is no case when first element is not set but second one is
            require(wallets.length > 0 && wallets[0] != address(0), "Sale: invalid referrer");
            
            IRAX RAXImpl = IRAX(RAX);
            if (RAXImpl.referrers(msg.sender) == address(0)) {
                RAXImpl.setReferrer(msg.sender, referrer);
            }
        }

        uint256 amountBusdIn = amountIn;
        if (token == address(0)) { // native asset (BNB)
            amountBusdIn = _swapToBusd(address(0), 0, minAmountOut);
        } else {
            IERC20 tokenImpl = IERC20(token);

            tokenImpl.safeTransferFrom(msg.sender, address(this), amountIn);

            if (token != BUSD) { // USDT or USDC
                amountBusdIn = _swapToBusd(token, amountIn, minAmountOut);
            }
        }

        require(amountBusdIn >= minAmount, "Sale: minAmount");
        spent[msg.sender] += amountBusdIn;
        require(spent[msg.sender] <= maxAmount, "Sale: maxAmount");

        referrers[msg.sender] = referrer;

        uint256[] memory amountRaxOuts = new uint256[](4);
        for (uint256 i = 0; i < _vestingManagers.length; ++i) {
            uint256 amountBusdInByVestinManager = (amountBusdIn * _vestingManagers[i].distributionPercentage) / PERCENTAGE_DENOM;

            amountRaxOuts[0] = (amountBusdInByVestinManager * 10**18) / price;
            amountRaxOuts[1] = (amountRaxOuts[0] * 500) / PERCENTAGE_DENOM;
            amountRaxOuts[2] = (amountRaxOuts[0] * 300) / PERCENTAGE_DENOM;
            amountRaxOuts[3] = (amountRaxOuts[0] * 200) / PERCENTAGE_DENOM;

            _execute(_vestingManagers[i].vestingManager, msg.sender, amountRaxOuts);
        }
    }

    function _swapToBusd(address erc20, uint256 amountIn, uint256 minAmountOut) private returns (uint256) {
        IPancakeRouter02 pancakeRouterImpl = IPancakeRouter02(pancakeRouter);

        address[] memory path = new address[](2);
        path[1] = BUSD;

        IERC20 BUSDImpl = IERC20(BUSD);
        uint256 balanceBefore = BUSDImpl.balanceOf(address(this));

        if (erc20 == address(0)) {
            path[0] = pancakeRouterImpl.WETH();
            pancakeRouterImpl.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: msg.value }(minAmountOut, path, address(this), block.timestamp);
        } else {
            path[0] = erc20;
            IERC20 erc20Impl = IERC20(erc20);
            erc20Impl.safeIncreaseAllowance(pancakeRouter, amountIn);
            pancakeRouterImpl.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, minAmountOut, path, address(this), block.timestamp);
        }

        uint256 balanceAfter = BUSDImpl.balanceOf(address(this));

        return balanceAfter - balanceBefore;
    }

    function _execute(address vestingManager, address beneficiary, uint256[] memory amountRaxOuts) private {
        (address[] memory allLevelsVestingWallets, address[] memory allLevelsReferrers) = _getAllLevelsVestingWallets(vestingManager, beneficiary);

        totalSold += amountRaxOuts[0];
        emit TokenTransferred(allLevelsVestingWallets[0], amountRaxOuts[0]);
        emit TokenSold(beneficiary, amountRaxOuts[0]);

        IERC20 erc20Impl = IERC20(RAX);

        bought[beneficiary] += amountRaxOuts[0];
        
        erc20Impl.safeTransfer(allLevelsVestingWallets[0], amountRaxOuts[0]);
        for (uint256 i = 1; i < allLevelsVestingWallets.length; ++i) {
            if (allLevelsVestingWallets[i] == address(0)) {
                break;
            }
            totalEarned += amountRaxOuts[i];
            emit RewardEarned(allLevelsVestingWallets[i], amountRaxOuts[i], i);
            rewards[allLevelsReferrers[i]] += amountRaxOuts[i];
            erc20Impl.safeTransfer(allLevelsVestingWallets[i], amountRaxOuts[i]);
        }
    }

    function _getVestingWallets(address beneficiary) internal view returns (address[] memory) {
        address[] memory wallets = new address[](_vestingManagers.length);
        for (uint256 i = 0; i < _vestingManagers.length; ++i) {
            address vestingManager = _vestingManagers[i].vestingManager;
            wallets[i] = _vestingWallets[vestingManager][beneficiary];
        }
        return wallets;
    }

    function _getDistributionPercentageTotal() internal view returns (uint256) {
        uint256 distributionPercentageTotal = 0;
        for (uint256 i = 0; i < _vestingManagers.length; ++i) {
            distributionPercentageTotal += _vestingManagers[i].distributionPercentage;
        }
        return distributionPercentageTotal;
    }

    function _getAllLevelsVestingWallets(address vestingManager, address beneficiary) internal returns (address[] memory, address[] memory) {
        address[] memory allLevelsVestingWallets = new address[](REFERRAL_PROGRAM_LEVELS + 1);
        address[] memory allLevelsReferrers = new address[](REFERRAL_PROGRAM_LEVELS + 1);

        address vestingWallet = _vestingWallets[vestingManager][beneficiary];

        if (vestingWallet == address(0)) {
            IWalletFactory factoryImpl = IWalletFactory(_walletFactory);
            vestingWallet = factoryImpl.createManagedVestingWallet(beneficiary, vestingManager);
            _vestingWallets[vestingManager][beneficiary] = vestingWallet;
        }

        allLevelsVestingWallets[0] = vestingWallet;

        address referrer = referrers[beneficiary];
        for (uint256 i = 1; i <= REFERRAL_PROGRAM_LEVELS; ++i) {
            address referrerVestingWallet = _vestingWallets[vestingManager][referrer];
            if (referrerVestingWallet == address(0)) {
                break;
            }
            allLevelsVestingWallets[i] = referrerVestingWallet;
            allLevelsReferrers[i] = referrer;
            referrer = referrers[referrer];
        }

        return (allLevelsVestingWallets, allLevelsReferrers);
    }
}