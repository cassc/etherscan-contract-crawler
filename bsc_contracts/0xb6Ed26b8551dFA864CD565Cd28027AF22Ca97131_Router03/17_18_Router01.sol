pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

import "./interfaces/IRouter01.sol";
import "./interfaces/IPoolToken.sol";
import "./interfaces/IBorrowable.sol";
import "./interfaces/ICollateral.sol";
import "./interfaces/ITarotCallee.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./libraries/SafeMath.sol";
import "./libraries/TransferHelper.sol";

contract Router01 is IRouter01, ITarotCallee {
    using SafeMath for uint256;

    address public immutable override factory;
    address public immutable override bDeployer;
    address public immutable override cDeployer;
    address public immutable override WETH;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "TarotRouter: EXPIRED");
        _;
    }

    modifier checkETH(address poolToken) {
        require(
            WETH == IPoolToken(poolToken).underlying(),
            "TarotRouter: NOT_WETH"
        );
        _;
    }

    constructor(
        address _factory,
        address _bDeployer,
        address _cDeployer,
        address _WETH
    ) public {
        factory = _factory;
        bDeployer = _bDeployer;
        cDeployer = _cDeployer;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    /*** Mint ***/

    function _mint(
        address poolToken,
        address underlying,
        uint256 amount,
        address from,
        address to
    ) internal virtual returns (uint256 tokens) {
        if (from == address(this))
            TransferHelper.safeTransfer(underlying, poolToken, amount);
        else
            TransferHelper.safeTransferFrom(
                underlying,
                from,
                poolToken,
                amount
            );
        tokens = IPoolToken(poolToken).mint(to);
    }

    function mint(
        address poolToken,
        uint256 amount,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 tokens) {
        return
            _mint(
                poolToken,
                IPoolToken(poolToken).underlying(),
                amount,
                msg.sender,
                to
            );
    }

    function mintETH(
        address poolToken,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        checkETH(poolToken)
        returns (uint256 tokens)
    {
        IWETH(WETH).deposit{value: msg.value}();
        return _mint(poolToken, WETH, msg.value, address(this), to);
    }

    function mintCollateral(
        address poolToken,
        uint256 amount,
        address to,
        uint256 deadline,
        bytes calldata permitData
    ) external virtual override ensure(deadline) returns (uint256 tokens) {
        address uniswapV2Pair = IPoolToken(poolToken).underlying();
        _permit(uniswapV2Pair, amount, deadline, permitData);
        return _mint(poolToken, uniswapV2Pair, amount, msg.sender, to);
    }

    /*** Redeem ***/

    function redeem(
        address poolToken,
        uint256 tokens,
        address to,
        uint256 deadline,
        bytes memory permitData
    ) public virtual override ensure(deadline) returns (uint256 amount) {
        _permit(poolToken, tokens, deadline, permitData);
        IPoolToken(poolToken).transferFrom(msg.sender, poolToken, tokens);
        amount = IPoolToken(poolToken).redeem(to);
    }

    function redeemETH(
        address poolToken,
        uint256 tokens,
        address to,
        uint256 deadline,
        bytes memory permitData
    )
        public
        virtual
        override
        ensure(deadline)
        checkETH(poolToken)
        returns (uint256 amountETH)
    {
        amountETH = redeem(
            poolToken,
            tokens,
            address(this),
            deadline,
            permitData
        );
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /*** Borrow ***/

    function borrow(
        address borrowable,
        uint256 amount,
        address to,
        uint256 deadline,
        bytes memory permitData
    ) public virtual override ensure(deadline) {
        _borrowPermit(borrowable, amount, deadline, permitData);
        IBorrowable(borrowable).borrow(msg.sender, to, amount, new bytes(0));
    }

    function borrowETH(
        address borrowable,
        uint256 amountETH,
        address to,
        uint256 deadline,
        bytes memory permitData
    ) public virtual override ensure(deadline) checkETH(borrowable) {
        borrow(borrowable, amountETH, address(this), deadline, permitData);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /*** Repay ***/

    function _repayAmount(
        address borrowable,
        uint256 amountMax,
        address borrower
    ) internal virtual returns (uint256 amount) {
        IBorrowable(borrowable).accrueInterest();
        uint256 borrowedAmount = IBorrowable(borrowable).borrowBalance(
            borrower
        );
        amount = amountMax < borrowedAmount ? amountMax : borrowedAmount;
    }

    function repay(
        address borrowable,
        uint256 amountMax,
        address borrower,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 amount) {
        amount = _repayAmount(borrowable, amountMax, borrower);
        TransferHelper.safeTransferFrom(
            IBorrowable(borrowable).underlying(),
            msg.sender,
            borrowable,
            amount
        );
        IBorrowable(borrowable).borrow(borrower, address(0), 0, new bytes(0));
    }

    function repayETH(
        address borrowable,
        address borrower,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        checkETH(borrowable)
        returns (uint256 amountETH)
    {
        amountETH = _repayAmount(borrowable, msg.value, borrower);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(borrowable, amountETH));
        IBorrowable(borrowable).borrow(borrower, address(0), 0, new bytes(0));
        // refund surpluss eth, if any
        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    /*** Liquidate ***/

    function liquidate(
        address borrowable,
        uint256 amountMax,
        address borrower,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256 amount, uint256 seizeTokens)
    {
        amount = _repayAmount(borrowable, amountMax, borrower);
        TransferHelper.safeTransferFrom(
            IBorrowable(borrowable).underlying(),
            msg.sender,
            borrowable,
            amount
        );
        seizeTokens = IBorrowable(borrowable).liquidate(borrower, to);
    }

    function liquidateETH(
        address borrowable,
        address borrower,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        checkETH(borrowable)
        returns (uint256 amountETH, uint256 seizeTokens)
    {
        amountETH = _repayAmount(borrowable, msg.value, borrower);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(borrowable, amountETH));
        seizeTokens = IBorrowable(borrowable).liquidate(borrower, to);
        // refund surpluss eth, if any
        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    /*** Leverage LP Token ***/

    function _leverage(
        address uniswapV2Pair,
        uint256 amountA,
        uint256 amountB,
        address to
    ) internal virtual {
        address borrowableA = getBorrowable(uniswapV2Pair, 0);
        // mint collateral
        bytes memory borrowBData = abi.encode(
            CalleeData({
                callType: CallType.ADD_LIQUIDITY_AND_MINT,
                uniswapV2Pair: uniswapV2Pair,
                borrowableIndex: 1,
                data: abi.encode(
                    AddLiquidityAndMintCalldata({
                        amountA: amountA,
                        amountB: amountB,
                        to: to
                    })
                )
            })
        );
        // borrow borrowableB
        bytes memory borrowAData = abi.encode(
            CalleeData({
                callType: CallType.BORROWB,
                uniswapV2Pair: uniswapV2Pair,
                borrowableIndex: 0,
                data: abi.encode(
                    BorrowBCalldata({
                        borrower: msg.sender,
                        receiver: address(this),
                        borrowAmount: amountB,
                        data: borrowBData
                    })
                )
            })
        );
        // borrow borrowableA
        IBorrowable(borrowableA).borrow(
            msg.sender,
            address(this),
            amountA,
            borrowAData
        );
    }

    function leverage(
        address uniswapV2Pair,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bytes calldata permitDataA,
        bytes calldata permitDataB
    ) external virtual override ensure(deadline) {
        _borrowPermit(
            getBorrowable(uniswapV2Pair, 0),
            amountADesired,
            deadline,
            permitDataA
        );
        _borrowPermit(
            getBorrowable(uniswapV2Pair, 1),
            amountBDesired,
            deadline,
            permitDataB
        );
        (uint256 amountA, uint256 amountB) = _optimalLiquidity(
            uniswapV2Pair,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        _leverage(uniswapV2Pair, amountA, amountB, to);
    }

    function _addLiquidityAndMint(
        address uniswapV2Pair,
        uint256 amountA,
        uint256 amountB,
        address to
    ) internal virtual {
        (
            address collateral,
            address borrowableA,
            address borrowableB
        ) = getLendingPool(uniswapV2Pair);
        // add liquidity to uniswap pair
        TransferHelper.safeTransfer(
            IBorrowable(borrowableA).underlying(),
            uniswapV2Pair,
            amountA
        );
        TransferHelper.safeTransfer(
            IBorrowable(borrowableB).underlying(),
            uniswapV2Pair,
            amountB
        );
        IUniswapV2Pair(uniswapV2Pair).mint(collateral);
        // mint collateral
        ICollateral(collateral).mint(to);
    }

    /*** Deleverage LP Token ***/

    function deleverage(
        address uniswapV2Pair,
        uint256 redeemTokens,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline,
        bytes calldata permitData
    ) external virtual override ensure(deadline) {
        address collateral = getCollateral(uniswapV2Pair);
        uint256 exchangeRate = ICollateral(collateral).exchangeRate();
        require(redeemTokens > 0, "TarotRouter: REDEEM_ZERO");
        uint256 redeemAmount = (redeemTokens - 1).mul(exchangeRate).div(1e18);
        _permit(collateral, redeemTokens, deadline, permitData);
        bytes memory redeemData = abi.encode(
            CalleeData({
                callType: CallType.REMOVE_LIQ_AND_REPAY,
                uniswapV2Pair: uniswapV2Pair,
                borrowableIndex: 0,
                data: abi.encode(
                    RemoveLiqAndRepayCalldata({
                        borrower: msg.sender,
                        redeemTokens: redeemTokens,
                        redeemAmount: redeemAmount,
                        amountAMin: amountAMin,
                        amountBMin: amountBMin
                    })
                )
            })
        );
        // flashRedeem
        ICollateral(collateral).flashRedeem(
            address(this),
            redeemAmount,
            redeemData
        );
    }

    function _removeLiqAndRepay(
        address uniswapV2Pair,
        address borrower,
        uint256 redeemTokens,
        uint256 redeemAmount,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual {
        (
            address collateral,
            address borrowableA,
            address borrowableB
        ) = getLendingPool(uniswapV2Pair);
        address tokenA = IBorrowable(borrowableA).underlying();
        address tokenB = IBorrowable(borrowableB).underlying();
        // removeLiquidity
        TransferHelper.safeTransfer(uniswapV2Pair, uniswapV2Pair, redeemAmount);
        (uint256 amountAMax, uint256 amountBMax) = IUniswapV2Pair(uniswapV2Pair)
        .burn(address(this));
        require(amountAMax >= amountAMin, "TarotRouter: INSUFFICIENT_A_AMOUNT");
        require(amountBMax >= amountBMin, "TarotRouter: INSUFFICIENT_B_AMOUNT");
        // repay and refund
        _repayAndRefund(borrowableA, tokenA, borrower, amountAMax);
        _repayAndRefund(borrowableB, tokenB, borrower, amountBMax);
        // repay flash redeem
        ICollateral(collateral).transferFrom(
            borrower,
            collateral,
            redeemTokens
        );
    }

    function _repayAndRefund(
        address borrowable,
        address token,
        address borrower,
        uint256 amountMax
    ) internal virtual {
        //repay
        uint256 amount = _repayAmount(borrowable, amountMax, borrower);
        TransferHelper.safeTransfer(token, borrowable, amount);
        IBorrowable(borrowable).borrow(borrower, address(0), 0, new bytes(0));
        // refund excess
        if (amountMax > amount) {
            uint256 refundAmount = amountMax - amount;
            if (token == WETH) {
                IWETH(WETH).withdraw(refundAmount);
                TransferHelper.safeTransferETH(borrower, refundAmount);
            } else TransferHelper.safeTransfer(token, borrower, refundAmount);
        }
    }

    /*** Tarot Callee ***/

    enum CallType {
        ADD_LIQUIDITY_AND_MINT,
        BORROWB,
        REMOVE_LIQ_AND_REPAY
    }
    struct CalleeData {
        CallType callType;
        address uniswapV2Pair;
        uint8 borrowableIndex;
        bytes data;
    }
    struct AddLiquidityAndMintCalldata {
        uint256 amountA;
        uint256 amountB;
        address to;
    }
    struct BorrowBCalldata {
        address borrower;
        address receiver;
        uint256 borrowAmount;
        bytes data;
    }
    struct RemoveLiqAndRepayCalldata {
        address borrower;
        uint256 redeemTokens;
        uint256 redeemAmount;
        uint256 amountAMin;
        uint256 amountBMin;
    }

    function tarotBorrow(
        address sender,
        address borrower,
        uint256 borrowAmount,
        bytes calldata data
    ) external virtual override {
        borrower;
        borrowAmount;
        CalleeData memory calleeData = abi.decode(data, (CalleeData));
        address declaredCaller = getBorrowable(
            calleeData.uniswapV2Pair,
            calleeData.borrowableIndex
        );
        // only succeeds if called by a borrowable and if that borrowable has been called by the router
        require(sender == address(this), "TarotRouter: SENDER_NOT_ROUTER");
        require(
            msg.sender == declaredCaller,
            "TarotRouter: UNAUTHORIZED_CALLER"
        );
        if (calleeData.callType == CallType.ADD_LIQUIDITY_AND_MINT) {
            AddLiquidityAndMintCalldata memory d = abi.decode(
                calleeData.data,
                (AddLiquidityAndMintCalldata)
            );
            _addLiquidityAndMint(
                calleeData.uniswapV2Pair,
                d.amountA,
                d.amountB,
                d.to
            );
        } else if (calleeData.callType == CallType.BORROWB) {
            BorrowBCalldata memory d = abi.decode(
                calleeData.data,
                (BorrowBCalldata)
            );
            address borrowableB = getBorrowable(calleeData.uniswapV2Pair, 1);
            IBorrowable(borrowableB).borrow(
                d.borrower,
                d.receiver,
                d.borrowAmount,
                d.data
            );
        } else revert();
    }

    function tarotRedeem(
        address sender,
        uint256 redeemAmount,
        bytes calldata data
    ) external virtual override {
        redeemAmount;
        CalleeData memory calleeData = abi.decode(data, (CalleeData));
        address declaredCaller = getCollateral(calleeData.uniswapV2Pair);
        // only succeeds if called by a collateral and if that collateral has been called by the router
        require(sender == address(this), "TarotRouter: SENDER_NOT_ROUTER");
        require(
            msg.sender == declaredCaller,
            "TarotRouter: UNAUTHORIZED_CALLER"
        );
        if (calleeData.callType == CallType.REMOVE_LIQ_AND_REPAY) {
            RemoveLiqAndRepayCalldata memory d = abi.decode(
                calleeData.data,
                (RemoveLiqAndRepayCalldata)
            );
            _removeLiqAndRepay(
                calleeData.uniswapV2Pair,
                d.borrower,
                d.redeemTokens,
                d.redeemAmount,
                d.amountAMin,
                d.amountBMin
            );
        } else revert();
    }

    /*** Utilities ***/

    function _permit(
        address poolToken,
        uint256 amount,
        uint256 deadline,
        bytes memory permitData
    ) internal virtual {
        if (permitData.length == 0) return;
        (bool approveMax, uint8 v, bytes32 r, bytes32 s) = abi.decode(
            permitData,
            (bool, uint8, bytes32, bytes32)
        );
        uint256 value = approveMax ? uint256(-1) : amount;
        IPoolToken(poolToken).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
    }

    function _borrowPermit(
        address borrowable,
        uint256 amount,
        uint256 deadline,
        bytes memory permitData
    ) internal virtual {
        if (permitData.length == 0) return;
        (bool approveMax, uint8 v, bytes32 r, bytes32 s) = abi.decode(
            permitData,
            (bool, uint8, bytes32, bytes32)
        );
        uint256 value = approveMax ? uint256(-1) : amount;
        IBorrowable(borrowable).borrowPermit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
    }

    function _optimalLiquidity(
        address uniswapV2Pair,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) public view virtual returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB, ) = IUniswapV2Pair(uniswapV2Pair)
        .getReserves();
        uint256 amountBOptimal = _quote(amountADesired, reserveA, reserveB);
        if (amountBOptimal <= amountBDesired) {
            require(
                amountBOptimal >= amountBMin,
                "TarotRouter: INSUFFICIENT_B_AMOUNT"
            );
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            uint256 amountAOptimal = _quote(amountBDesired, reserveB, reserveA);
            assert(amountAOptimal <= amountADesired);
            require(
                amountAOptimal >= amountAMin,
                "TarotRouter: INSUFFICIENT_A_AMOUNT"
            );
            (amountA, amountB) = (amountAOptimal, amountBDesired);
        }
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function _quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "TarotRouter: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "TarotRouter: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function getBorrowable(address uniswapV2Pair, uint8 index)
        public
        view
        virtual
        override
        returns (address borrowable)
    {
        require(index < 2, "TarotRouter: INDEX_TOO_HIGH");
        borrowable = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        bDeployer,
                        keccak256(
                            abi.encodePacked(factory, uniswapV2Pair, index)
                        ),
                        hex"721ca65ff8c327d91c0cbfff6b09c0d4a60a2cdc400730bda4582a6adc1447e5" // Borrowable bytecode keccak256
                    )
                )
            )
        );
    }

    function getCollateral(address uniswapV2Pair)
        public
        view
        virtual
        override
        returns (address collateral)
    {
        collateral = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        cDeployer,
                        keccak256(abi.encodePacked(factory, uniswapV2Pair)),
                        hex"326662b4eab5ef52fa98ce27b557770bbf166e66fe2b9c9877b907cca7504017" // Collateral bytecode keccak256
                    )
                )
            )
        );
    }

    function getLendingPool(address uniswapV2Pair)
        public
        view
        virtual
        override
        returns (
            address collateral,
            address borrowableA,
            address borrowableB
        )
    {
        collateral = getCollateral(uniswapV2Pair);
        borrowableA = getBorrowable(uniswapV2Pair, 0);
        borrowableB = getBorrowable(uniswapV2Pair, 1);
    }
}