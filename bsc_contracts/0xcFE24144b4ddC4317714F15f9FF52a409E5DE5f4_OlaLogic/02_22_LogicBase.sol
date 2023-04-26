// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./utils/UpgradeableBase.sol";
import "./interfaces/IXToken.sol";
import "./interfaces/ISwap.sol";
import "./interfaces/IMultiLogicProxy.sol";
import "./interfaces/ILogicContract.sol";
import "./interfaces/ICompound.sol";

abstract contract LogicBase is ILogic, UpgradeableBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal constant ZERO_ADDRESS = address(0);
    address public multiLogicProxy;
    address internal blid;
    address public comptroller;
    address public rainMaker;
    address public swapGateway;
    address internal expenseAddress;
    address internal xBNB;
    mapping(address => bool) internal usedXTokens;
    mapping(address => address) internal XTokens;

    event SetBLID(address _blid);
    event SetExpenseAddress(address expenseAddress);
    event SetSwapGateway(address swapGateway);
    event SetMultiLogicProxy(address multiLogicProxy);

    function __Logic_init(
        address _expenseAddress,
        address _comptroller,
        address _rainMaker
    ) public initializer {
        UpgradeableBase.initialize();
        expenseAddress = _expenseAddress;

        comptroller = _comptroller;
        rainMaker = _rainMaker;
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlyMultiLogicProxy() {
        require(msg.sender == multiLogicProxy, "E14");
        _;
    }

    modifier isUsedXToken(address xToken) {
        require(usedXTokens[xToken], "E2");
        _;
    }

    /*** Owner function ***/

    /**
     * @notice Set expenseAddress
     * @param _expenseAddress Address of Expense Account
     */
    function setExpenseAddress(address _expenseAddress) external onlyOwner {
        expenseAddress = _expenseAddress;
        emit SetExpenseAddress(_expenseAddress);
    }

    /**
     * @notice Set swapGateway
     * @param _swapGateway Address of SwapGateway
     */
    function setSwapGateway(address _swapGateway) external onlyOwner {
        swapGateway = _swapGateway;
        emit SetSwapGateway(_swapGateway);
    }

    /**
     * @notice Set blid in contract and approve blid for storage, venus, pancakeswap/apeswap/biswap
     * router, and pancakeswap/apeswap/biswap master(Main Staking contract), you can call the
     * function once
     * @param blid_ Address of BLID
     */
    function setBLID(address blid_) external onlyOwner {
        blid = blid_;
        IERC20Upgradeable(blid).safeApprove(multiLogicProxy, type(uint256).max);
        emit SetBLID(blid_);
    }

    /**
     * @notice Set MultiLogicProxy, you can call the function once
     * @param _multiLogicProxy Address of Storage Contract
     */
    function setMultiLogicProxy(address _multiLogicProxy) external onlyOwner {
        require(multiLogicProxy == address(0), "E15");
        multiLogicProxy = _multiLogicProxy;

        emit SetMultiLogicProxy(_multiLogicProxy);
    }

    /*** Strategy function ***/

    /**
     * @notice Add XToken in Contract and approve token  for storage, venus,
     * pancakeswap/apeswap router, and pancakeswap/apeswap master(Main Staking contract)
     * @param token Address of Token for deposited
     * @param xToken Address of XToken
     */
    function addXTokens(address token, address xToken)
        external
        override
        onlyOwnerAndAdmin
    {
        require(_checkMarkets(xToken), "E5");

        if ((token) != address(0)) {
            IERC20Upgradeable(token).approve(xToken, type(uint256).max);
            IERC20Upgradeable(token).approve(
                multiLogicProxy,
                type(uint256).max
            );
            approveTokenForSwap(swapGateway, token);

            XTokens[token] = xToken;
        } else {
            xBNB = xToken;
        }

        usedXTokens[xToken] = true;
    }

    /**
     * @notice Transfer amount of token from Storage to Logic contract token - address of the token
     * @param amount Amount of token
     * @param token Address of token
     */
    function takeTokenFromStorage(uint256 amount, address token)
        external
        override
        onlyOwnerAndAdmin
    {
        IMultiLogicProxy(multiLogicProxy).takeToken(amount, token);
        if (token == address(0)) {
            require(address(this).balance >= amount, "E16");
        }
    }

    /**
     * @notice Transfer amount of token from Logic to Storage contract token - address of token
     * @param amount Amount of token
     * @param token Address of token
     */
    function returnTokenToStorage(uint256 amount, address token)
        external
        override
        onlyOwnerAndAdmin
    {
        if (token == address(0)) {
            _send(payable(multiLogicProxy), amount);
        }

        IMultiLogicProxy(multiLogicProxy).returnToken(amount, token);
    }

    /**
     * @notice Transfer amount of ETH from Logic to MultiLogicProxy
     * @param amount Amount of ETH
     */
    function returnETHToMultiLogicProxy(uint256 amount)
        external
        override
        onlyOwnerAndAdmin
    {
        _send(payable(multiLogicProxy), amount);
    }

    /**
     * @notice Distribution amount of blid to depositors.
     * @param amount Amount of BLID
     */
    function addEarnToStorage(uint256 amount)
        external
        override
        onlyOwnerAndAdmin
    {
        IERC20Upgradeable(blid).safeTransfer(
            expenseAddress,
            (amount * 3) / 100
        );
        IMultiLogicProxy(multiLogicProxy).addEarn(
            amount - ((amount * 3) / 100),
            blid
        );
    }

    /**
     * @notice Approve swap for token
     * @param _swap Address of swapRouter
     * @param token Address of token
     */
    function approveTokenForSwap(address _swap, address token)
        public
        onlyOwnerAndAdmin
    {
        if (IERC20Upgradeable(token).allowance(address(this), _swap) == 0) {
            IERC20Upgradeable(token).safeApprove(_swap, type(uint256).max);
        }
    }

    /*** LendingSystem function ***/

    /**
     * @notice Get all entered xTokens to comptroller
     */
    function getAllMarkets() external view override returns (address[] memory) {
        return _getAllMarkets();
    }

    /**
     * @notice Enter into a list of markets(address of XTokens) - it is not an
     * error to enter the same market more than once.
     * @param xTokens The addresses of the xToken markets to enter.
     * @return For each market, returns an error code indicating whether or not it was entered.
     * Each is 0 on success, otherwise an Error code
     */
    function enterMarkets(address[] calldata xTokens)
        external
        override
        onlyOwnerAndAdmin
        returns (uint256[] memory)
    {
        return _enterMarkets(xTokens);
    }

    /**
     * @notice Every user accrues rewards for each block
     * Venus : XVS, Ola : BANANA, dForce : DF
     * they are supplying to or borrowing from the protocol.
     */
    function claim() external override onlyOwnerAndAdmin {
        // Get all markets
        address[] memory xTokens = _getAllMarkets();

        // Claim
        _claim(xTokens);
    }

    /**
     * @notice Stake token and mint XToken
     * @param xToken: that mint XTokens to this contract
     * @param mintAmount: The amount of the asset to be supplied, in units of the underlying asset.
     * @return 0 on success, otherwise an Error code
     */
    function mint(address xToken, uint256 mintAmount)
        external
        override
        isUsedXToken(xToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        return _mint(xToken, mintAmount);
    }

    /**
     * @notice The borrow function transfers an asset from the protocol to the user and creates a
     * borrow balance which begins accumulating interest based on the Borrow Rate for the asset.
     * The amount borrowed must be less than the user's Account Liquidity and the market's
     * available liquidity.
     * @param xToken: that mint XTokens to this contract
     * @param borrowAmount: The amount of underlying to be borrow.
     * @return 0 on success, otherwise an Error code
     */
    function borrow(address xToken, uint256 borrowAmount)
        external
        override
        isUsedXToken(xToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        return _borrow(xToken, borrowAmount);
    }

    /**
     * @notice The repay function transfers an asset into the protocol, reducing the user's borrow balance.
     * @param xToken: that mint XTokens to this contract
     * @param repayAmount: The amount of the underlying borrowed asset to be repaid.
     * A value of -1 (i.e. 2256 - 1) can be used to repay the full amount.
     * @return 0 on success, otherwise an Error code
     */
    function repayBorrow(address xToken, uint256 repayAmount)
        external
        override
        isUsedXToken(xToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        return _repayBorrow(xToken, repayAmount);
    }

    /**
     * @notice The redeem underlying function converts xTokens into a specified quantity of the
     * underlying asset, and returns them to the user.
     * The amount of xTokens redeemed is equal to the quantity of underlying tokens received,
     * divided by the current Exchange Rate.
     * The amount redeemed must be less than the user's Account Liquidity and the market's
     * available liquidity.
     * @param xToken: that mint XTokens to this contract
     * @param redeemAmount: The amount of underlying to be redeemed.
     * @return 0 on success, otherwise an Error code
     */
    function redeemUnderlying(address xToken, uint256 redeemAmount)
        external
        virtual
        override
        isUsedXToken(xToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        return _redeemUnderlying(xToken, redeemAmount);
    }

    /**
     * @notice The redeem function converts xTokens into a specified quantity of the
     * underlying asset, and returns them to the user.
     * The amount of xTokens redeemed is equal to the quantity of underlying tokens received,
     * divided by the current Exchange Rate.
     * The amount redeemed must be less than the user's xToken baalance.
     * @param xToken: that mint XTokens to this contract
     * @param redeemTokenAmount: The amount of underlying to be redeemed.
     * @return 0 on success, otherwise an Error code
     */
    function redeem(address xToken, uint256 redeemTokenAmount)
        external
        virtual
        override
        isUsedXToken(xToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        return _redeem(xToken, redeemTokenAmount);
    }

    /*** Swap function ***/

    /**
     * @notice Swap tokens using swapRouter
     * @param swapRouter Address of swapRouter contract
     * @param amountIn Amount for in
     * @param amountOut Amount for out
     * @param path swap path, path[0] is in, path[last] is out
     * @param isExactInput true : swapExactTokensForTokens, false : swapTokensForExactTokens
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swap(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        bool isExactInput,
        uint256 deadline
    ) external payable override returns (uint256[] memory amounts) {
        if (path[0] == ZERO_ADDRESS) {
            require(address(this).balance >= amountIn, "E18");

            amounts = ISwapGateway(swapGateway).swap{value: amountIn}(
                swapRouter,
                amountIn,
                amountOut,
                path,
                isExactInput,
                deadline
            );
        } else {
            require(
                IERC20Upgradeable(path[0]).balanceOf(address(this)) >= amountIn,
                "E18"
            );
            require(
                IERC20Upgradeable(path[0]).allowance(
                    address(this),
                    swapGateway
                ) >= amountIn,
                "E19"
            );

            amounts = ISwapGateway(swapGateway).swap(
                swapRouter,
                amountIn,
                amountOut,
                path,
                isExactInput,
                deadline
            );
        }
    }

    /*** Private Function ***/

    /**
     * @notice Send ETH to address
     * @param _to target address to receive ETH
     * @param amount ETH amount (wei) to be sent
     */
    function _send(address payable _to, uint256 amount) private {
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "E17");
    }

    /*** Private Virtual Function ***/

    /**
     * @notice Check if xToken is in market
     * for each strategy, this function should be override
     */
    function _checkMarkets(address xToken)
        internal
        view
        virtual
        returns (bool)
    {}

    /**
     * @notice enterMarket with xToken
     */
    function _enterMarkets(address[] calldata xTokens)
        internal
        virtual
        returns (uint256[] memory)
    {
        return IComptrollerCompound(comptroller).enterMarkets(xTokens);
    }

    /**
     * @notice Stake token and mint XToken
     */
    function _mint(address xToken, uint256 mintAmount)
        internal
        virtual
        returns (uint256)
    {
        if (xToken == xBNB) {
            IXTokenETH(xToken).mint{value: mintAmount}();
            return 0;
        }

        return IXToken(xToken).mint(mintAmount);
    }

    /**
     * @notice borrow underlying token
     */
    function _borrow(address xToken, uint256 borrowAmount)
        internal
        virtual
        returns (uint256)
    {
        // Get my account's total liquidity value in Compound
        (
            uint256 error,
            uint256 liquidity,
            uint256 shortfall
        ) = IComptrollerCompound(comptroller).getAccountLiquidity(
                address(this)
            );

        require(error == 0, "E10");
        require(liquidity > 0, "E12");
        require(shortfall == 0, "E11");

        return IXToken(xToken).borrow(borrowAmount);
    }

    /**
     * @notice repayBorrow underlying token
     */
    function _repayBorrow(address xToken, uint256 repayAmount)
        internal
        virtual
        returns (uint256)
    {
        if (xToken == xBNB) {
            IXTokenETH(xToken).repayBorrow{value: repayAmount}();
            return 0;
        }

        return IXToken(xToken).repayBorrow(repayAmount);
    }

    /**
     * @notice redeem underlying staked token
     */
    function _redeemUnderlying(address xToken, uint256 redeemAmount)
        internal
        virtual
        returns (uint256)
    {
        return IXToken(xToken).redeemUnderlying(redeemAmount);
    }

    /**
     * @notice redeem underlying staked token
     */
    function _redeem(address xToken, uint256 redeemTokenAmount)
        internal
        virtual
        returns (uint256)
    {
        return IXToken(xToken).redeem(redeemTokenAmount);
    }

    /**
     * @notice Claim strategy rewards token
     * for each strategy, this function should be override
     */
    function _claim(address[] memory xTokens) internal virtual {}

    /**
     * @notice Get all entered xTokens to comptroller
     */
    function _getAllMarkets() internal view virtual returns (address[] memory) {
        return IComptrollerCompound(comptroller).getAllMarkets();
    }
}