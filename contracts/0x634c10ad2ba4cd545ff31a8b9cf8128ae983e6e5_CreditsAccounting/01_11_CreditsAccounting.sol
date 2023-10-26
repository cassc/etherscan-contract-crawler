// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IWETH.sol";
import "./SafeOwnable.sol";

// @title Smart contract tracks Credits purchase in exchange for a specific Stable Coins
contract CreditsAccounting is SafeOwnable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    struct Purchase {
        uint32 blockNumber;
        uint112 creditsBought;
        uint112 usdSpent;
    }

    address public immutable babyDogeRouter;
    address private immutable WETH;
    uint256 public constant CREDITS_DECIMALS = 18;

    IERC20 public stableCoin;
    address public feeReceiver;
    uint256 public usdPerCredit;

    mapping(address => Purchase[]) public purchases;
    EnumerableSet.AddressSet private approvedRouters;   // Set of V2 routers addresses, approved to be used

    event CreditsPurchased(address account, uint256 creditsAmount, uint256 usdSpent);

    event StableCoinUpdated(address);
    event FeeReceiverUpdated(address);
    event UsdPerCreditUpdated(uint256);
    event RouterApproved(address router, bool approved);


    /*
     * @param _router BabyDoge router address
     * @param _feeReceiver Address of account that will receive StableCoins
     * @param _stableCoin ERC20 token that should be used for payment
     * @param _usdPerCredit Amount of StableCoins should be spent to purchase 1 Credit
     */
    constructor(
        address _babyDogeRouter,
        address _feeReceiver,
        IERC20 _stableCoin,
        uint256 _usdPerCredit
    ){
        babyDogeRouter = _babyDogeRouter;
        WETH = IRouter(_babyDogeRouter).WETH();
        approvedRouters.add(_babyDogeRouter);

        stableCoin = _stableCoin;
        feeReceiver = _feeReceiver;
        usdPerCredit = _usdPerCredit;
    }


    /*
     * @notice Buy Credits by swapping tokens or transferring StableCoins
     * @param router Router address. Any address if path is empty
     * @param amountIn Amount of tokens IN to spend
     * @param amountOutMin Minimum amount of Credits to purchase
     * @param path Swap path. Empty for direct StableCoin transfer
     * @return Amount of Credits bought
     */
    function buyCredits(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external payable nonReentrant returns(uint256 creditsBought) {
        IERC20 _stableCoin = stableCoin;
        address _feeReceiver = feeReceiver;
        require(
            path.length == 0
            || (path[path.length - 1] == address(_stableCoin) && path.length >= 2),
            "Invalid path"
        );

        uint256 stableCoinsAmount = 0;

        if (path.length == 0) {
            _stableCoin.safeTransferFrom(msg.sender, _feeReceiver, amountIn);

            stableCoinsAmount = amountIn;
        } else {
            require(router == babyDogeRouter || approvedRouters.contains(router), "Router not approved");
            if (msg.value > 0) {
                require(msg.value == amountIn, "Invalid msg.value");
                require(path[0] == WETH, "Invalid path");
                IWETH(WETH).deposit{ value: amountIn }();
            } else {
                uint256 initialBalanceIn = IERC20(path[0]).balanceOf(address(this));
                IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);
                // in case fee on transfer token
                amountIn = IERC20(path[0]).balanceOf(address(this)) - initialBalanceIn;
            }
            uint256 initialBalance = _stableCoin.balanceOf(_feeReceiver);

            _approveIfRequired(path[0], router, amountIn);
            IRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                0,
                path,
                _feeReceiver,
                block.timestamp
            );

            stableCoinsAmount = _stableCoin.balanceOf(_feeReceiver) - initialBalance;
        }

        creditsBought = stableCoinsAmount * (10 ** CREDITS_DECIMALS) / usdPerCredit;

        require(creditsBought >= amountOutMin, "Below amountOutMin");

        purchases[msg.sender].push(Purchase({
            blockNumber: uint32(block.number),
            creditsBought: uint112(creditsBought),
            usdSpent: uint112(stableCoinsAmount)
        }));

        emit CreditsPurchased(msg.sender, creditsBought, stableCoinsAmount);
    }


    /*
     * @notice Updates StableCoin address
     * @param _stableCoin ERC20 token that should be used for payment
     * @dev Can be called only by the Owner
     */
    function setStableCoin(IERC20 _stableCoin) external onlyOwner {
        require(address(_stableCoin) != address(0), "Zero address");
        stableCoin = _stableCoin;

        emit StableCoinUpdated(address(_stableCoin));
    }


    /*
     * @notice Approves Router address
     * @param router Router address
     * @param approve true - approve, false - forbid
     */
    function approveRouter(address router, bool approve) external onlyOwner {
        require(router != babyDogeRouter, "BabyDoge router should stay approved");
        if (approve) {
            require(approvedRouters.add(router), "Already approved");
        } else {
            require(approvedRouters.remove(router), "Not approved");
        }

        emit RouterApproved(router, approve);
    }


    /*
     * @notice Updates fee receiver address
     * @param _feeReceiver Address of account that will receive StableCoins
     * @dev Can be called only by the Owner
     */
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), "Zero address");
        feeReceiver = _feeReceiver;

        emit FeeReceiverUpdated(_feeReceiver);
    }


    /*
     * @notice Updates USD/Credit price
     * @param _usdPerCredit Amount of StableCoins should be spent to purchase 1 Credit
     * @dev Can be called only by the Owner
     */
    function setUsdPerCredit(uint256 _usdPerCredit) external onlyOwner {
        require(_usdPerCredit > 0, "Zero value");
        usdPerCredit = _usdPerCredit;

        emit UsdPerCreditUpdated(_usdPerCredit);
    }


    /*
     * @notice Returns list of purchases for given account address
     * @param account Account address
     * @return _purchases List of purchases
     */
    function getPurchases(
        address account
    ) external view returns(Purchase[] memory _purchases) {
        return purchases[account];
    }


    /*
     * @notice Returns list of paginated purchases for given account address
     * @param account Account address
     * @param startIndex Start inder of purchases
     * @param pageSize Page size
     * @return _purchases List of purchases
     */
    function getPaginatedPurchases(
        address account,
        uint256 startIndex,
        uint256 pageSize
    ) external view returns(Purchase[] memory _purchases) {
        uint256 numberOfPurchases = purchases[account].length;
        if (numberOfPurchases - startIndex < pageSize) {
            pageSize = numberOfPurchases - startIndex;
        }
        _purchases = new Purchase[](pageSize);

        uint256 index = startIndex;
        for (uint i = 0; i < pageSize && index < numberOfPurchases; i++) {
            _purchases[i] = purchases[account][index];
            index++;
        }
    }


    /*
     * @notice Returns list of purchases for given account address, starting from the last
     * @param account Account address
     * @param pageSize Max number of purchases to get. 0 for full array
     * @return _purchases List of purchases
     */
    function getLastPurchases(
        address account,
        uint256 pageSize
    ) public view returns(Purchase[] memory _purchases) {
        uint256 numberOfPurchases = purchases[account].length;
        if (numberOfPurchases < pageSize || pageSize == 0) {
            pageSize = numberOfPurchases;
        }

        _purchases = new Purchase[](pageSize);

        uint256 index = numberOfPurchases > 0 ? numberOfPurchases - 1 : 0;
        for (uint i = 0; i < pageSize; i++) {
            _purchases[i] = purchases[account][index];
            if (index == 0) break;
            index--;
        }
    }


    /*
     * @notice Returns array length of purchases array
     * @param account Account address
     * @return Array length
     */
    function getNumberOfPurchases(address account) external view returns(uint256) {
        return purchases[account].length;
    }


    /*
     * @notice View function go get list or approved routers
     * @return List or approved routers
     */
    function getApprovedRouters() external view returns(address[] memory) {
        return approvedRouters.values();
    }


    /*
     * @notice View function go determine if Router is approved to be used to buy Credits
     * @param router Router address
     * @return Is approved router?
     */
    function isApprovedRouter(address router) external view returns(bool) {
        return approvedRouters.contains(router);
    }


    /*
     * @notice Approves tokens to be spent by the spender if required
     * @param token ERC20 token address to spend
     * @param toSpend Amount of ERC20 token to spend
     */
    function _approveIfRequired(address token, address spender, uint256 toSpend) private {
        if (IERC20(token).allowance(address(this), spender) < toSpend) {
            IERC20(token).approve(spender, type(uint256).max);
        }
    }
}