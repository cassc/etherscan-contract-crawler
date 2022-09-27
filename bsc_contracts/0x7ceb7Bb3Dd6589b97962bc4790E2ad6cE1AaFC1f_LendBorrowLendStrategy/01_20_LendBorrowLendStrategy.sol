// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./../utils/LogicUpgradeable.sol";
import "./../Interfaces/ILogicContract.sol";
import "./../Interfaces/IXToken.sol";
import "./../Interfaces/ICompoundOla.sol";
import "./../Interfaces/IMultiLogicProxy.sol";

contract LendBorrowLendStrategy is LogicUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private blid;
    address private comptroller;
    address private rewardsSwapRouter;
    address private rewardsToken;
    address private logic;
    address[] private pathToSwapRewardsToBLID;
    address private multiLogicProxy;

    uint8 public circlesCount;
    bool private rewardsInit;
    uint8 private avoidLiquidationFactor;

    mapping(address => address) private oTokens;

    event SetBLID(address _blid);
    event SetMultiLogicProxy(address multiLogicProxy);
    event SetCirclesCount(uint8 _circlesCount);
    event BuildCircle(address token, uint256 _circlesCount);
    event DestroyCircle(
        address token,
        uint256 amountMultiLogicBalance,
        uint256 balanceToken
    );
    event RebuildCircle(address token, uint256 _circlesCount);
    event ClaimRewards(address token, uint256 amount);
    event Init(address token);
    event ReleaseToken(address token, uint256 amount);

    function __LendBorrowLendStrategy_init(
        address _comptroller,
        address _rewardsSwapRouter,
        address _rewardsToken,
        address _logic
    ) public initializer {
        LogicUpgradeable.initialize();
        comptroller = _comptroller;
        rewardsSwapRouter = _rewardsSwapRouter;
        rewardsToken = _rewardsToken;
        logic = _logic;
        rewardsInit = false;
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlyMultiLogicProxy() {
        require(msg.sender == multiLogicProxy, "L1");
        _;
    }

    modifier isUsedToken(address token) {
        require(oTokens[token] != address(0), "L2");
        _;
    }

    /**
     * @notice Set blid in contract
     * @param blid_ Address of BLID
     */
    function setBLID(address blid_) external onlyOwner {
        require(blid == address(0), "L3");
        blid = blid_;
        emit SetBLID(blid_);
    }

    /**
     * @notice Set MultiLogicProxy, you can call the function once
     * @param _multiLogicProxy Address of Multilogic Contract
     */
    function setMultiLogicProxy(address _multiLogicProxy) external onlyOwner {
        require(multiLogicProxy == address(0), "L5");
        multiLogicProxy = _multiLogicProxy;

        emit SetMultiLogicProxy(_multiLogicProxy);
    }

    /**
     * @notice Set circlesCount
     * @param _circlesCount Count number
     */
    function setCirclesCount(uint8 _circlesCount) external onlyOwner {
        circlesCount = _circlesCount;

        emit SetCirclesCount(_circlesCount);
    }

    /**
     * @notice Set pathToSwapRewardsToBLID
     * @param path path to rewards to BLID
     */
    function setPathToSwapRewardsToBLID(address[] calldata path)
        external
        onlyOwner
    {
        uint256 length = path.length;
        require(length >= 2, "L6");
        require(path[0] == rewardsToken, "L7");
        require(path[length - 1] == blid, "L8");

        pathToSwapRewardsToBLID = new address[](length);
        for (uint256 i = 0; i < length; ) {
            pathToSwapRewardsToBLID[i] = path[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Set avoidLiquidationFactor
     * @param _factor factor value
     */
    function setAvoidLiquidationFactor(uint8 _factor) external onlyOwner {
        avoidLiquidationFactor = _factor;
    }

    /**
     * @notice Add XToken in Contract and approve token
     * Approve token for storage, venus, pancakeswap/apeswap/biswap router,
     * and pancakeswap/apeswap/biswap master(Main Staking contract)
     * Approve rewardsToken for swap
     */
    function init(address token, address oToken) public onlyOwner {
        require(oTokens[token] == address(0), "L10");

        address _logic = logic;
        oTokens[token] = oToken;

        // Add token/oToken to Logic
        ILogicContract(_logic).addXTokens(token, oToken, 1);

        // Entermarkets with token/otoken
        address[] memory tokens = new address[](1);
        tokens[0] = oToken;
        ILogicContract(_logic).enterMarkets(tokens, 1);

        // Approve rewards token
        if (!rewardsInit) {
            ILogicContract(_logic).approveTokenForSwap(rewardsToken);

            rewardsInit = true;
        }

        emit Init(token);
    }

    /**
     * @notice Build circle strategy
     * take token from storage and create circle
     * @param amount amount of token
     * @param token token address
     */
    function build(uint256 amount, address token)
        external
        onlyOwnerAndAdmin
        isUsedToken(token)
    {
        address _logic = logic;

        // Take token from storage
        ILogicContract(_logic).takeTokenFromStorage(amount, token);

        // create circle with total balance of token
        amount = IERC20Upgradeable(token).balanceOf(_logic);
        createCircles(token, amount, circlesCount);

        emit BuildCircle(token, amount);
    }

    /**
     * @notice Destroy circle strategy
     * destroy circle and return all tokens to storage
     * @param token token address
     */
    function destroy(address token)
        external
        onlyOwnerAndAdmin
        isUsedToken(token)
    {
        address _logic = logic;

        // Destruct circle
        destructCircles(token, circlesCount);

        // Return all tokens to storage
        uint256 balanceToken = IERC20Upgradeable(token).balanceOf(_logic);
        uint256 amountStrategy = IMultiLogicProxy(multiLogicProxy)
            .getTokenBalance(token, _logic);

        if (amountStrategy < balanceToken)
            ILogicContract(_logic).returnTokenToStorage(amountStrategy, token);
        else ILogicContract(_logic).returnTokenToStorage(balanceToken, token);

        emit DestroyCircle(token, amountStrategy, balanceToken);
    }

    /**
     * @notice Rebuild circle strategy
     * destroy/build circle
     * @param token token address
     * @param _circlesCount Count number
     */
    function rebuild(address token, uint8 _circlesCount)
        external
        onlyOwnerAndAdmin
        isUsedToken(token)
    {
        // destruct circle with previous circlesCount
        destructCircles(token, circlesCount);

        // Set circlesCount
        circlesCount = _circlesCount;

        // create circle with total balance of token
        uint256 amount = IERC20Upgradeable(token).balanceOf(logic);
        createCircles(token, amount, _circlesCount);

        emit RebuildCircle(token, _circlesCount);
    }

    /**
     * @notice claim distribution rewards USDT both borrow and lend swap banana token to BLID
     * @param token token address
     */
    function claimRewards(address token)
        external
        onlyOwnerAndAdmin
        isUsedToken(token)
    {
        require(pathToSwapRewardsToBLID.length >= 2, "L9");

        address _logic = logic;

        // Claim Rewards token
        address[] memory tokens = new address[](1);
        tokens[0] = oTokens[token];
        ILogicContract(_logic).claim(tokens, 1);

        // Convert Rewards to BLID
        uint256 amountIn = IERC20Upgradeable(rewardsToken).balanceOf(_logic);
        uint256 amountOutMin = 0;
        uint256 deadline = block.timestamp + 100;
        ILogicContract(_logic).swapExactTokensForTokens(
            rewardsSwapRouter,
            amountIn,
            amountOutMin,
            pathToSwapRewardsToBLID,
            deadline
        );

        // Add BLID earn to storage
        uint256 amountBLID = IERC20Upgradeable(blid).balanceOf(_logic);
        ILogicContract(_logic).addEarnToStorage(amountBLID);

        emit ClaimRewards(token, amountBLID);
    }

    /**
     * @notice Frees up tokens for the user, but Storage doesn't transfer token for the user,
     * only Storage can this function, after calling this function Storage transfer
     * from Logic to user token.
     * @param amount Amount of token
     * @param token Address of token
     */
    function releaseToken(uint256 amount, address token)
        external
        payable
        onlyMultiLogicProxy
        isUsedToken(token)
    {
        address _logic = logic;

        // destruct circle with previous circlesCount
        destructCircles(token, circlesCount);

        uint256 balance;

        if (token == address(0)) {
            balance = address(_logic).balance;
        } else {
            balance = IERC20Upgradeable(token).balanceOf(_logic);
        }

        if (balance < amount) {
            revert("no money");
        } else if (token == address(0)) {
            ILogicContract(_logic).returnETHToMultiLogicProxy(amount);
        }

        // create circle with remaind balance of token
        createCircles(token, balance - amount, circlesCount);

        emit ReleaseToken(token, amount);
    }

    /**
     * @notice multicall to Logic
     */
    function multicall(bytes[] memory callDatas)
        public
        onlyOwnerAndAdmin
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        uint256 length = callDatas.length;
        returnData = new bytes[](length);
        for (uint256 i = 0; i < length; i++) {
            (bool success, bytes memory ret) = address(logic).call(
                callDatas[i]
            );
            require(success, "F99");
            returnData[i] = ret;
        }
    }

    /*** Prive Function ***/

    /**
     * @notice creates circle (borrow-lend) of the base token
     * @param token token address
     * @param _iterateCount the number circles to
     */
    function createCircles(
        address token,
        uint256 _amount,
        uint8 _iterateCount
    ) private {
        uint256 collateralFactor; // the maximum proportion of borrow/lend
        address cToken = oTokens[token];
        address _logic = logic;
        uint8 iterateCount = _iterateCount;
        uint256 amount = _amount;

        require(amount > 0, "L12");

        // Get information from comptroller
        (, collateralFactor, , , , ) = IComptrollerOla(comptroller).markets(
            cToken
        );

        // Apply avoidLiquidationFactor to collateralFactor
        collateralFactor =
            ((collateralFactor * 100) / (10**18)) -
            avoidLiquidationFactor;
        require(collateralFactor > 0, "L11");

        for (uint256 i = 0; i < iterateCount; ) {
            ILogicContract(_logic).mint(cToken, amount);

            uint256 borrowAmount = (amount * collateralFactor) / 100;
            ILogicContract(_logic).borrow(cToken, borrowAmount, 1);

            amount = borrowAmount;

            unchecked {
                ++i;
            }
        }

        // lend the last borrowed amount
        ILogicContract(_logic).mint(cToken, amount);
    }

    /**
     * @notice unblock all the money
     * @param token token address
     * @param _iterateCount the number circles to : maximum iterates to do, the real number might be less then iterateCount
     */
    function destructCircles(address token, uint8 _iterateCount) private {
        uint256 collateralFactor;
        address cToken = oTokens[token];
        uint8 iterateCount = _iterateCount + 3; // additional iteration to repay all borrowed
        address _logic = logic;

        // Get information from comptroller
        (, collateralFactor, , , , ) = IComptrollerOla(comptroller).markets(
            cToken
        );

        // Apply avoidLiquidationFactor to collateralFactor
        collateralFactor =
            ((collateralFactor * 100) / (10**18)) -
            avoidLiquidationFactor;
        require(collateralFactor > 0, "L11");

        for (uint256 i = 0; i < iterateCount; ) {
            uint256 cTokenBalance; // balance of cToken
            uint256 borrowBalance; // balance of borrowed amount
            uint256 exchangeRateMantissa; //conversion rate from cToken to token

            // get infromation of account
            (, cTokenBalance, borrowBalance, exchangeRateMantissa) = IXToken(
                cToken
            ).getAccountSnapshot(_logic);

            // calculates of supplied balance, divided by 10^18 to safe digits correctly
            uint256 supplyBalance = (cTokenBalance * exchangeRateMantissa) /
                10**18;

            // calculates how much percents could be borroewed and not to be liquidated, then multiply fo supply balance to calculate the amount
            uint256 withdrawBalance = ((collateralFactor -
                ((100 * borrowBalance) / supplyBalance)) * supplyBalance) / 100;

            // if nothing to repay
            if (borrowBalance == 0) {
                if (cTokenBalance > 0) {
                    // redeem and exit
                    ILogicContract(_logic).redeemUnderlying(
                        cToken,
                        supplyBalance
                    );
                    return;
                }
            }
            // if already redeemed
            if (supplyBalance == 0) {
                return;
            }

            // if redeem tokens
            ILogicContract(_logic).redeemUnderlying(cToken, withdrawBalance);
            uint256 repayAmount = IERC20Upgradeable(token).balanceOf(_logic);

            // if there is something to repay
            if (repayAmount > 0) {
                // if borrow balance more then we have on account
                if (borrowBalance > repayAmount) {
                    ILogicContract(_logic).repayBorrow(cToken, repayAmount);
                } else {
                    ILogicContract(_logic).repayBorrow(cToken, borrowBalance);
                }
            }

            unchecked {
                ++i;
            }
        }
    }
}