// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./utils/LogicUpgradeable.sol";
import "./Interfaces/IXToken.sol";
import "./Interfaces/ISwap.sol";
import "./Interfaces/ICompoundOla.sol";
import "./Interfaces/ICompoundVenus.sol";
import "./Interfaces/IMultiLogicProxy.sol";

contract Logic is LogicUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public multiLogicProxy;
    address private blid;
    address private venusComptroller;
    address private olaComptroller;
    address private olaRainMaker;
    address private pancake;
    address private apeswap;
    address private biswap;
    address private pancakeMaster;
    address private apeswapMaster;
    address private biswapMaster;
    address private expenseAddress;
    address private vBNB;
    address private oBNB;
    mapping(address => bool) private usedXTokens;
    mapping(address => address) private XTokens;

    uint8 private constant vTokenType = 0;
    uint8 private constant oTokenType = 1;

    event SetBLID(address _blid);
    event SetMultiLogicProxy(address multiLogicProxy);

    function __Logic_init(
        address _expenseAddress,
        address _venusComptroller,
        address _olaComptroller,
        address _olaRainMaker,
        address _pancakeRouter,
        address _apeswapRouter,
        address _biswapRouter,
        address _pancakeMaster,
        address _apeswapMaster,
        address _biswapMaster
    ) public initializer {
        LogicUpgradeable.initialize();
        expenseAddress = _expenseAddress;

        venusComptroller = _venusComptroller;
        olaComptroller = _olaComptroller;
        olaRainMaker = _olaRainMaker;

        apeswap = _apeswapRouter;
        pancake = _pancakeRouter;
        biswap = _biswapRouter;
        pancakeMaster = _pancakeMaster;
        apeswapMaster = _apeswapMaster;
        biswapMaster = _biswapMaster;
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

    modifier isUsedSwap(address swap) {
        require(swap == apeswap || swap == pancake || swap == biswap, "E3");
        _;
    }

    modifier isUsedMaster(address swap) {
        require(
            swap == pancakeMaster ||
                apeswapMaster == swap ||
                biswapMaster == swap,
            "E4"
        );
        _;
    }

    modifier isTokenTypeAccepted(uint8 leadingTokenType) {
        require(
            leadingTokenType == vTokenType || leadingTokenType == oTokenType,
            "E8"
        );
        _;
    }

    /*** User function ***/

    /**
     * @notice Add XToken in Contract and approve token  for storage, venus,
     * pancakeswap/apeswap router, and pancakeswap/apeswap master(Main Staking contract)
     * @param token Address of Token for deposited
     * @param xToken Address of XToken
     * @param leadingTokenType Type of XToken
     */
    function addXTokens(
        address token,
        address xToken,
        uint8 leadingTokenType
    ) external onlyOwnerAndAdmin isTokenTypeAccepted(leadingTokenType) {
        bool _isUsedXToken;

        if (leadingTokenType == vTokenType) {
            (_isUsedXToken, , ) = IComptrollerVenus(venusComptroller).markets(
                xToken
            );
        }

        if (leadingTokenType == oTokenType) {
            (_isUsedXToken, , , , , ) = IComptrollerOla(olaComptroller).markets(
                xToken
            );
        }

        require(_isUsedXToken, "E5");

        if ((token) != address(0)) {
            IERC20Upgradeable(token).approve(xToken, type(uint256).max);
            IERC20Upgradeable(token).approve(
                multiLogicProxy,
                type(uint256).max
            );
            approveTokenForSwap(token);

            XTokens[token] = xToken;
        } else {
            if (leadingTokenType == vTokenType) vBNB = xToken;
            if (leadingTokenType == oTokenType) oBNB = xToken;
        }

        usedXTokens[xToken] = true;
    }

    /**
     * @notice Set blid in contract and approve blid for storage, venus, pancakeswap/apeswap/biswap
     * router, and pancakeswap/apeswap/biswap master(Main Staking contract), you can call the
     * function once
     * @param blid_ Address of BLID
     */
    function setBLID(address blid_) external onlyOwner {
        require(blid == address(0), "E6");
        blid = blid_;
        IERC20Upgradeable(blid).safeApprove(apeswap, type(uint256).max);
        IERC20Upgradeable(blid).safeApprove(pancake, type(uint256).max);
        IERC20Upgradeable(blid).safeApprove(biswap, type(uint256).max);
        IERC20Upgradeable(blid).safeApprove(pancakeMaster, type(uint256).max);
        IERC20Upgradeable(blid).safeApprove(apeswapMaster, type(uint256).max);
        IERC20Upgradeable(blid).safeApprove(biswapMaster, type(uint256).max);
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

    /**
     * @notice Approve token for storage, venus, pancakeswap/apeswap/biswap router,
     * and pancakeswap/apeswap/biswap master(Main Staking contract)
     * @param token  Address of Token that is approved
     */
    function approveTokenForSwap(address token) public onlyOwnerAndAdmin {
        (IERC20Upgradeable(token).approve(apeswap, type(uint256).max));
        (IERC20Upgradeable(token).approve(pancake, type(uint256).max));
        (IERC20Upgradeable(token).approve(biswap, type(uint256).max));
        (IERC20Upgradeable(token).approve(pancakeMaster, type(uint256).max));
        (IERC20Upgradeable(token).approve(apeswapMaster, type(uint256).max));
        (IERC20Upgradeable(token).approve(biswapMaster, type(uint256).max));
    }

    /**
     * @notice Transfer amount of token from Storage to Logic contract token - address of the token
     * @param amount Amount of token
     * @param token Address of token
     */
    function takeTokenFromStorage(uint256 amount, address token)
        external
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
        onlyOwnerAndAdmin
    {
        _send(payable(multiLogicProxy), amount);
    }

    /**
     * @notice Distribution amount of blid to depositors.
     * @param amount Amount of BLID
     */
    function addEarnToStorage(uint256 amount) external onlyOwnerAndAdmin {
        IERC20Upgradeable(blid).safeTransfer(
            expenseAddress,
            (amount * 3) / 100
        );
        IMultiLogicProxy(multiLogicProxy).addEarn((amount * 97) / 100, blid);
    }

    /**
     * @notice Enter into a list of markets(address of XTokens) - it is not an
     * error to enter the same market more than once.
     * @param xTokens The addresses of the xToken markets to enter.
     * @param leadingTokenType Type of XToken
     * @return For each market, returns an error code indicating whether or not it was entered.
     * Each is 0 on success, otherwise an Error code
     */
    function enterMarkets(address[] calldata xTokens, uint8 leadingTokenType)
        external
        onlyOwnerAndAdmin
        isTokenTypeAccepted(leadingTokenType)
        returns (uint256[] memory)
    {
        if (leadingTokenType == vTokenType)
            return IComptrollerVenus(venusComptroller).enterMarkets(xTokens);
        if (leadingTokenType == oTokenType)
            return IComptrollerOla(olaComptroller).enterMarkets(xTokens);

        revert("E13");
    }

    /**
     * @notice Every Venus user accrues XVS for each block
     * they are supplying to or borrowing from the protocol.
     * @param xTokens The addresses of the xToken markets to enter.
     * @param leadingTokenType Type of XToken
     */
    function claim(address[] calldata xTokens, uint8 leadingTokenType)
        external
        onlyOwnerAndAdmin
        isTokenTypeAccepted(leadingTokenType)
    {
        if (leadingTokenType == vTokenType)
            IDistributionVenus(venusComptroller).claimVenus(
                address(this),
                xTokens
            );
        if (leadingTokenType == oTokenType)
            IDistributionOla(olaRainMaker).claimComp(address(this), xTokens);
    }

    /**
     * @notice Stake token and mint XToken
     * @param xToken: that mint XTokens to this contract
     * @param mintAmount: The amount of the asset to be supplied, in units of the underlying asset.
     * @return 0 on success, otherwise an Error code
     */
    function mint(address xToken, uint256 mintAmount)
        external
        isUsedXToken(xToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        require(mintAmount > 0, "E8");

        if (xToken == vBNB || xToken == oBNB) {
            IXTokenETH(xToken).mint{value: mintAmount}();
            return 0;
        }

        return IXToken(xToken).mint(mintAmount);
    }

    /**
     * @notice The borrow function transfers an asset from the protocol to the user and creates a
     * borrow balance which begins accumulating interest based on the Borrow Rate for the asset.
     * The amount borrowed must be less than the user's Account Liquidity and the market's
     * available liquidity.
     * @param xToken: that mint XTokens to this contract
     * @param borrowAmount: The amount of underlying to be borrow.
     * @param leadingTokenType Type of XToken
     * @return 0 on success, otherwise an Error code
     */
    function borrow(
        address xToken,
        uint256 borrowAmount,
        uint8 leadingTokenType
    )
        external
        payable
        isUsedXToken(xToken)
        onlyOwnerAndAdmin
        isTokenTypeAccepted(leadingTokenType)
        returns (uint256)
    {
        // Get my account's total liquidity value in Compound
        uint256 error;
        uint256 liquidity;
        uint256 shortfall;

        if (leadingTokenType == vTokenType)
            (error, liquidity, shortfall) = IComptrollerVenus(venusComptroller)
                .getAccountLiquidity(address(this));
        if (leadingTokenType == oTokenType)
            (error, liquidity, shortfall) = IComptrollerOla(olaComptroller)
                .getAccountLiquidity(address(this));

        require(error == 0, "E10");
        require(shortfall == 0, "E11");
        require(liquidity > 0, "E12");

        return IXToken(xToken).borrow(borrowAmount);
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
        isUsedXToken(xToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        if (xToken == vBNB || xToken == oBNB) {
            IXTokenETH(xToken).repayBorrow{value: repayAmount}();
            return 0;
        }

        return IXToken(xToken).repayBorrow(repayAmount);
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
        isUsedXToken(xToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        return IXToken(xToken).redeemUnderlying(redeemAmount);
    }

    /**
     * @notice Adds liquidity to a BEP20⇄BEP20 pool.
     * @param swap Address of swap router
     * @param tokenA The contract address of one token from your liquidity pair.
     * @param tokenB The contract address of the other token from your liquidity pair.
     * @param amountADesired The amount of tokenA you'd like to provide as liquidity.
     * @param amountBDesired The amount of tokenA you'd like to provide as liquidity.
     * @param amountAMin The minimum amount of tokenA to provide (slippage impact).
     * @param amountBMin The minimum amount of tokenB to provide (slippage impact).
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function addLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        isUsedSwap(swap)
        onlyOwnerAndAdmin
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountADesired, amountBDesired, amountAMin) = IPancakeRouter01(swap)
            .addLiquidity(
                tokenA,
                tokenB,
                amountADesired,
                amountBDesired,
                amountAMin,
                amountBMin,
                address(this),
                deadline
            );

        return (amountADesired, amountBDesired, amountAMin);
    }

    /**
     * @notice Removes liquidity from a BEP20⇄BEP20 pool.
     * @param swap Address of swap router
     * @param tokenA The contract address of one token from your liquidity pair.
     * @param tokenB The contract address of the other token from your liquidity pair.
     * @param liquidity The amount of LP Tokens to remove.
     * @param amountAMin he minimum amount of tokenA to provide (slippage impact).
     * @param amountBMin The minimum amount of tokenB to provide (slippage impact).
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function removeLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        onlyOwnerAndAdmin
        isUsedSwap(swap)
        returns (uint256 amountA, uint256 amountB)
    {
        (amountAMin, amountBMin) = IPancakeRouter01(swap).removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            address(this),
            deadline
        );

        return (amountAMin, amountBMin);
    }

    /**
     * @notice Adds liquidity to a BEP20⇄WBNB pool.
     * @param swap Address of swap router
     * @param token The contract address of one token from your liquidity pair.
     * @param amountTokenDesired The amount of the token you'd like to provide as liquidity.
     * @param amountETHDesired The minimum amount of the token to provide (slippage impact).
     * @param amountTokenMin The minimum amount of token to provide (slippage impact).
     * @param amountETHMin The minimum amount of BNB to provide (slippage impact).
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function addLiquidityETH(
        address swap,
        address token,
        uint256 amountTokenDesired,
        uint256 amountETHDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        isUsedSwap(swap)
        onlyOwnerAndAdmin
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountETHDesired, amountTokenMin, amountETHMin) = IPancakeRouter01(
            swap
        ).addLiquidityETH{value: amountETHDesired}(
            token,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );

        return (amountETHDesired, amountTokenMin, amountETHMin);
    }

    /**
     * @notice Removes liquidity from a BEP20⇄WBNB pool.
     * @param swap Address of swap router
     * @param token The contract address of one token from your liquidity pair.
     * @param liquidity The amount of LP Tokens to remove.
     * @param amountTokenMin The minimum amount of the token to remove (slippage impact).
     * @param amountETHMin The minimum amount of BNB to remove (slippage impact).
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function removeLiquidityETH(
        address swap,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        payable
        isUsedSwap(swap)
        onlyOwnerAndAdmin
        returns (uint256 amountToken, uint256 amountETH)
    {
        (deadline, amountETHMin) = IPancakeRouter01(swap).removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );

        return (deadline, amountETHMin);
    }

    /**
     * @notice Receive an as many output tokens as possible for an exact amount of input tokens.
     * @param swap Address of swap router
     * @param amountIn TPayable amount of input tokens.
     * @param amountOutMin The minimum amount tokens to receive.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapExactTokensForTokens(
        address swap,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    )
        external
        isUsedSwap(swap)
        onlyOwnerAndAdmin
        returns (uint256[] memory amounts)
    {
        return
            IPancakeRouter01(swap).swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),
                deadline
            );
    }

    /**
     * @notice Receive an exact amount of output tokens for as few input tokens as possible.
     * @param swap Address of swap router
     * @param amountOut Payable amount of input tokens.
     * @param amountInMax The minimum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapTokensForExactTokens(
        address swap,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint256 deadline
    )
        external
        onlyOwnerAndAdmin
        isUsedSwap(swap)
        returns (uint256[] memory amounts)
    {
        return
            IPancakeRouter01(swap).swapTokensForExactTokens(
                amountOut,
                amountInMax,
                path,
                address(this),
                deadline
            );
    }

    /**
     * @notice Receive as many output tokens as possible for an exact amount of BNB.
     * @param swap Address of swap router
     * @param amountETH Payable BNB amount.
     * @param amountOutMin 	The minimum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapExactETHForTokens(
        address swap,
        uint256 amountETH,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    )
        external
        isUsedSwap(swap)
        onlyOwnerAndAdmin
        returns (uint256[] memory amounts)
    {
        return
            IPancakeRouter01(swap).swapExactETHForTokens{value: amountETH}(
                amountOutMin,
                path,
                address(this),
                deadline
            );
    }

    /**
     * @notice Receive an exact amount of output tokens for as few input tokens as possible.
     * @param swap Address of swap router
     * @param amountOut Payable BNB amount.
     * @param amountInMax The minimum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapTokensForExactETH(
        address swap,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint256 deadline
    )
        external
        payable
        isUsedSwap(swap)
        onlyOwnerAndAdmin
        returns (uint256[] memory amounts)
    {
        return
            IPancakeRouter01(swap).swapTokensForExactETH(
                amountOut,
                amountInMax,
                path,
                address(this),
                deadline
            );
    }

    /**
     * @notice Receive as much BNB as possible for an exact amount of input tokens.
     * @param swap Address of swap router
     * @param amountIn Payable amount of input tokens.
     * @param amountOutMin The maximum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapExactTokensForETH(
        address swap,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    )
        external
        payable
        isUsedSwap(swap)
        onlyOwnerAndAdmin
        returns (uint256[] memory amounts)
    {
        return
            IPancakeRouter01(swap).swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                address(this),
                deadline
            );
    }

    /**
     * @notice Receive an exact amount of output tokens for as little BNB as possible.
     * @param swap Address of swap router
     * @param amountOut The amount tokens to receive.
     * @param amountETH Payable BNB amount.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapETHForExactTokens(
        address swap,
        uint256 amountETH,
        uint256 amountOut,
        address[] calldata path,
        uint256 deadline
    )
        external
        isUsedSwap(swap)
        onlyOwnerAndAdmin
        returns (uint256[] memory amounts)
    {
        return
            IPancakeRouter01(swap).swapETHForExactTokens{value: amountETH}(
                amountOut,
                path,
                address(this),
                deadline
            );
    }

    /**
     * @notice Deposit LP tokens to Master
     * @param swapMaster Address of swap master(Main staking contract)
     * @param _pid pool id
     * @param _amount amount of lp token
     */
    function deposit(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external isUsedMaster(swapMaster) onlyOwnerAndAdmin {
        IMasterChef(swapMaster).deposit(_pid, _amount);
    }

    /**
     * @notice Withdraw LP tokens from Master
     * @param swapMaster Address of swap master(Main staking contract)
     * @param _pid pool id
     * @param _amount amount of lp token
     */
    function withdraw(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external isUsedMaster(swapMaster) onlyOwnerAndAdmin {
        IMasterChef(swapMaster).withdraw(_pid, _amount);
    }

    /**
     * @notice Stake BANANA/Cake tokens to STAKING.
     * @param swapMaster Address of swap master(Main staking contract)
     * @param _amount amount of lp token
     */
    function enterStaking(address swapMaster, uint256 _amount)
        external
        isUsedMaster(swapMaster)
        onlyOwnerAndAdmin
    {
        IMasterChef(swapMaster).enterStaking(_amount);
    }

    /**
     * @notice Withdraw BANANA/Cake tokens from STAKING.
     * @param swapMaster Address of swap master(Main staking contract)
     * @param _amount amount of lp token
     */
    function leaveStaking(address swapMaster, uint256 _amount)
        external
        isUsedMaster(swapMaster)
        onlyOwnerAndAdmin
    {
        IMasterChef(swapMaster).leaveStaking(_amount);
    }

    /*** Prvate Function ***/

    /**
     * @notice Send ETH to address
     * @param _to target address to receive ETH
     * @param amount ETH amount (wei) to be sent
     */
    function _send(address payable _to, uint256 amount) private {
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "E17");
    }
}