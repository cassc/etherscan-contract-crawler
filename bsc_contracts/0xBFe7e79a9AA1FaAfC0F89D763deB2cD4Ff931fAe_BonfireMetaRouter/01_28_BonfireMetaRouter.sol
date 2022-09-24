// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

import "../strategies/IBonfireStrategyAccumulator.sol";
import "../swap/IBonfireMetaRouter.sol";
import "../swap/IBonfirePair.sol";
import "../swap/IBonfireTokenManagement.sol";
import "../swap/ISwapFactoryRegistry.sol";
import "../swap/BonfireRouterPaths.sol";
import "../swap/BonfireQuoteCheck.sol";
import "../swap/BonfireSwapHelper.sol";
import "../token/IBonfireTokenWrapper.sol";
import "../token/IBonfireTokenTracker.sol";
import "../token/IBonfireProxyToken.sol";
import "../utils/BonfireTokenHelper.sol";

contract BonfireMetaRouter is IBonfireMetaRouter, Ownable {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    address public constant override tracker =
        address(0xBFac04803249F4C14f5d96427DA22a814063A5E1);
    address public constant override wrapper =
        address(0xBFbb27219f18d7463dD91BB4721D445244F5d22D);
    address public constant tokenManagement =
        address(0xBF5051b1794aEEB327852Df118f77C452bFEd00d);
    address public constant factoryRegistry =
        address(0xBF57511A971278FCb1f8D376D68078762Ae957C4);
    address public constant paths =
        address(0xBF6c6c21FcbA3697d5de9B1CdCDAB678517Eb734);

    uint256 public constant maxFeePermille = 20;

    address public immutable WETH;
    address public override accumulator;
    uint256 public defaultWETHThreshold;
    uint256 public feeP = 1;
    uint256 public feeQ = 400;

    event AccumulatorUpdate(
        address indexed _accumulator,
        uint256 indexed _defaultWETHThreshold
    );
    event MetaSwap(
        address[] poolPath,
        address[] tokenPath,
        uint256 indexed amountIn,
        uint256 indexed amountOut,
        address indexed to
    );
    event MetaTransfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event MetaAccumulation(
        address indexed bonusToken,
        address indexed outToken,
        address indexed bonusTo,
        uint256 bonusGains
    );
    event FeeUpdate(uint256 indexed feeP, uint256 indexed feeQ);

    error BadUse(uint256 location);
    error BadAddress(uint256 position, address a);
    error InsufficientAmountOut(uint256 amountOut, uint256 minAmountOut);
    error Expired();

    modifier ensure(uint256 deadline) {
        if (deadline < block.timestamp) {
            revert Expired(); //expired
        }
        _;
    }

    constructor(address admin) Ownable() {
        transferOwnership(admin);
        WETH = IBonfireTokenManagement(tokenManagement).WETH();
        if (WETH == address(0)) {
            revert BadAddress(0, tokenManagement);
        }
    }

    function _takeFee(uint256 fromAmount)
        internal
        view
        returns (uint256 newAmount)
    {
        unchecked {
            uint256 fee = (fromAmount * feeP) / feeQ;
            newAmount = fromAmount - fee;
        }
    }

    /*
     * TokenThreshold is used to decide input value for accumulation.
     * Lower threshold values can result in higher gas costs, but do
     * not pose a risk to user assets.
     */
    function tokenThreshold(address token)
        public
        view
        returns (uint256 threshold)
    {
        threshold = ISwapFactoryRegistry(factoryRegistry).getWETHEquivalent(
            token,
            defaultWETHThreshold
        );
    }

    function setFee(uint256 _feeP, uint256 _feeQ) external onlyOwner {
        if (_feeP > (maxFeePermille * feeQ) / 1000 || _feeP > 1e9) {
            revert BadUse(0); //fee to high
        }
        feeP = _feeP;
        feeQ = _feeQ;
        emit FeeUpdate(_feeP, _feeQ);
    }

    function setAccumulator(address _accumulator, uint256 _defaultWETHThreshold)
        external
        onlyOwner
    {
        accumulator = _accumulator;
        defaultWETHThreshold = _defaultWETHThreshold;
        emit AccumulatorUpdate(_accumulator, _defaultWETHThreshold);
    }

    /*
     * The main purpose of this function is to allow transfers that immediately
     * skim the liquidity pools (and potentially invoke other no-risk strategies).
     */
    function transferToken(
        address token,
        address to,
        uint256 amount,
        uint256 bonusThreshold
    ) external override {
        IERC20(token).safeTransferFrom(msg.sender, to, amount);
        emit MetaTransfer(token, msg.sender, to, amount);
        accumulate(token, bonusThreshold);
    }

    function simpleQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address to
    )
        external
        view
        override
        returns (
            uint256 amountOut,
            address[] memory poolPath,
            address[] memory tokenPath,
            bytes32[] memory poolDescriptions,
            address bonusToken,
            uint256 bonusThreshold,
            uint256 bonusAmount,
            string memory message
        )
    {
        amountIn = _takeFee(amountIn);
        (amountOut, poolPath, tokenPath) = BonfireRouterPaths.getBestPath(
            tokenIn,
            tokenOut,
            amountIn,
            to,
            ISwapFactoryRegistry(factoryRegistry).getUniswapFactories(),
            IBonfireTokenManagement(tokenManagement).getIntermediateTokens()
        );
        poolDescriptions = new bytes32[](poolPath.length);
        for (uint256 i = 0; i < poolPath.length; i++) {
            if (BonfireSwapHelper.isWrapper(poolPath[i])) {
                poolDescriptions[i] = bytes32(
                    abi.encodePacked(
                        "Bonfire Token Wrapper ",
                        bytes1(keccak256(abi.encode(poolPath[i])))
                    )
                );
            } else {
                poolDescriptions[i] = ISwapFactoryRegistry(factoryRegistry)
                    .factoryDescription(IBonfirePair(poolPath[i]).factory());
            }
        }
        (bonusToken, bonusThreshold, bonusAmount) = IBonfireMetaRouter(this)
            .getBonusParameters(tokenPath);
        {
            (
                uint256 suggestedAmountIn,
                uint256 permilleIncrease
            ) = BonfireQuoteCheck.querySwapAmount(
                    poolPath,
                    tokenPath,
                    amountIn,
                    1,
                    5
                );
            if (suggestedAmountIn < amountIn) {
                message = string(
                    abi.encodePacked(
                        "Beware: expected ",
                        Strings.toString(permilleIncrease - 1000),
                        " permille price increase! Better use ",
                        Strings.toString(suggestedAmountIn),
                        "as amountIn."
                    )
                );
            }
        }
    }

    function getBonusParameters(address[] calldata tokenPath)
        external
        view
        returns (
            address bonusToken,
            uint256 bonusThreshold,
            uint256 bonusAmount
        )
    {
        if (accumulator != address(0)) {
            for (uint256 i = tokenPath.length; i > 0; ) {
                //gas optimization
                unchecked {
                    i--;
                }
                if (
                    IBonfireStrategyAccumulator(accumulator).tokenRegistered(
                        tokenPath[i]
                    )
                ) {
                    bonusThreshold = tokenThreshold(tokenPath[i]);
                    bonusAmount = IBonfireStrategyAccumulator(accumulator)
                        .quote(tokenPath[i], bonusThreshold);
                    if (bonusAmount > 0) {
                        bonusToken = tokenPath[i];
                        break;
                    }
                }
            }
            if (bonusAmount == 0) {
                bonusToken = IBonfireTokenManagement(tokenManagement)
                    .defaultToken();
                bonusThreshold = tokenThreshold(bonusToken);
                bonusAmount = IBonfireStrategyAccumulator(accumulator).quote(
                    bonusToken,
                    bonusThreshold
                );
            }
        }
    }

    function quote(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        uint256 amount,
        address to
    ) external view override returns (uint256 amountOut) {
        amount = _takeFee(amount);
        amountOut = BonfireRouterPaths.quote(poolPath, tokenPath, amount, to);
    }

    function _pairSwap(
        address pool,
        address tokenA,
        address tokenB,
        address target
    ) internal {
        (uint256 reserveA, uint256 reserveB, ) = IBonfirePair(pool)
            .getReserves();
        (reserveA, reserveB) = IBonfirePair(pool).token0() == tokenA
            ? (reserveA, reserveB)
            : (reserveB, reserveA);
        uint256 amount = IERC20(tokenA).balanceOf(pool) - reserveA;
        //compute amountOut
        uint256 projectedBalanceB;
        (amount, , projectedBalanceB) = BonfireSwapHelper.getAmountOutFromPool(
            amount,
            tokenB,
            pool
        );
        if (IBonfireTokenTracker(tracker).getReflectionTaxP(tokenB) > 0) {
            //reflection adjustment
            amount = BonfireSwapHelper.reflectionAdjustment(
                tokenB,
                pool,
                amount,
                projectedBalanceB
            );
        }
        if (IBonfirePair(pool).token0() == tokenA) {
            IBonfirePair(pool).swap(uint256(0), amount, target, new bytes(0));
        } else {
            IBonfirePair(pool).swap(amount, uint256(0), target, new bytes(0));
        }
    }

    function _prepareWrapperInCase(address target, address[] calldata tokenPath)
        internal
        returns (bool targetToThis)
    {
        if (tokenPath.length > 2 && BonfireSwapHelper.isWrapper(target)) {
            //the else to this is swapping into wrapper without control (could be used for custom two-step deposit though
            address t2 = BonfireTokenHelper.getSourceToken(tokenPath[2]);
            if (t2 == tokenPath[1]) {
                //prepare wrapping
                IBonfireTokenWrapper(target).announceDeposit(t2);
            } else {
                address t1 = BonfireTokenHelper.getSourceToken(tokenPath[1]);
                if (t1 == tokenPath[2] || (t1 == t2 && t1 != address(0))) {
                    //prepare unwrapping or converting
                    targetToThis = true;
                } else {
                    revert BadUse(1); //wrapper is not a swap
                }
            }
        }
    }

    function _firstSwap(
        address pool,
        address target,
        address[] calldata tokenPath,
        uint256 amount
    ) internal {
        if (_prepareWrapperInCase(target, tokenPath)) {
            target = address(this); //unwrap or convert in next step
        }
        if (BonfireSwapHelper.isWrapper(pool)) {
            if (target == pool) {
                revert BadUse(2); //two times the same wrapper
            }
            address t1 = BonfireTokenHelper.getSourceToken(tokenPath[1]);
            if (t1 == tokenPath[0]) {
                //wrap it
                IBonfireTokenWrapper(pool).announceDeposit(tokenPath[0]);
                if (amount > 0)
                    //with this it also works for skimming
                    IERC20(tokenPath[0]).safeTransferFrom(
                        msg.sender,
                        pool,
                        amount
                    );
                IBonfireTokenWrapper(pool).executeDeposit(tokenPath[1], target);
            } else {
                address t0 = BonfireTokenHelper.getSourceToken(tokenPath[0]);
                if (t0 == tokenPath[1]) {
                    //unwrap it
                    IBonfireTokenWrapper(pool).withdrawSharesFrom(
                        tokenPath[0],
                        msg.sender,
                        target,
                        IBonfireProxyToken(tokenPath[0]).tokenToShares(amount)
                    );
                } else if (t0 == t1 && t0 != address(0)) {
                    //convert it
                    IBonfireTokenWrapper(pool).moveShares(
                        tokenPath[0],
                        tokenPath[1],
                        IBonfireProxyToken(tokenPath[0]).tokenToShares(amount),
                        msg.sender,
                        target
                    );
                } else {
                    revert BadUse(3); //wrapper is not a swap
                }
            }
        } else {
            //swap
            if (amount > 0)
                //with this it also works for skimming
                IERC20(tokenPath[0]).safeTransferFrom(msg.sender, pool, amount);
            _pairSwap(pool, tokenPath[0], tokenPath[1], target);
        }
    }

    function _coreSwapOrWrap(
        address pool,
        address target,
        address[] calldata tokenPath,
        uint256 amount
    ) internal {
        if (_prepareWrapperInCase(target, tokenPath)) {
            target = address(this); //unwrap or convert in next step
        }
        if (BonfireSwapHelper.isWrapper(pool)) {
            if (target == pool) {
                revert BadAddress(1, target); //wrapper should not occur twice in succession in path
            }
            address t1 = BonfireTokenHelper.getSourceToken(tokenPath[1]);
            if (t1 == tokenPath[0]) {
                //wrap it
                IBonfireTokenWrapper(pool).executeDeposit(tokenPath[1], target);
            } else {
                address t0 = BonfireTokenHelper.getSourceToken(tokenPath[0]);
                if (t0 == tokenPath[1]) {
                    //unwrap it
                    IBonfireTokenWrapper(pool).withdrawShares(
                        tokenPath[0],
                        target,
                        IBonfireProxyToken(tokenPath[0]).tokenToShares(amount)
                    );
                } else if (t0 == t1 && t0 != address(0)) {
                    //convert it
                    IBonfireTokenWrapper(pool).moveShares(
                        tokenPath[0],
                        tokenPath[1],
                        IBonfireProxyToken(tokenPath[0]).tokenToShares(amount),
                        address(this),
                        target
                    );
                }
            }
        } else {
            //swap
            _pairSwap(pool, tokenPath[0], tokenPath[1], target);
        }
    }

    function _swapTokenCore(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        uint256 amount,
        address to
    ) internal returns (uint256) {
        if (poolPath.length > 0) {
            for (uint256 i = 0; i < poolPath.length; ) {
                (address pool, address target) = i < poolPath.length - 1
                    ? (poolPath[i], poolPath[i + 1])
                    : (poolPath[i], to);
                uint256 before = IERC20(tokenPath[i + 1]).balanceOf(target);
                _coreSwapOrWrap(pool, target, tokenPath[i:], amount);
                amount = IERC20(tokenPath[i + 1]).balanceOf(target) - before;
                //gas optimization
                unchecked {
                    i++;
                }
            }
        }
        return amount;
    }

    function accumulate(address bonusToken, uint256 threshold) public override {
        if (bonusToken != address(0) && accumulator != address(0)) {
            address token = bonusToken;
            address target = address(this);
            bool isTaxed = IBonfireTokenTracker(tracker).getTotalTaxP(
                bonusToken
            ) > 0;
            if (isTaxed) {
                token = IBonfireTokenManagement(tokenManagement)
                    .getDefaultProxy(bonusToken);
                target = wrapper;
                IBonfireTokenWrapper(wrapper).announceDeposit(bonusToken);
            }
            uint256 gains = IERC20(token).balanceOf(address(this));
            uint256 aGains = IBonfireStrategyAccumulator(accumulator).execute(
                bonusToken,
                threshold,
                block.timestamp,
                target
            );
            if (isTaxed && aGains > 0) {
                IBonfireTokenWrapper(wrapper).executeDeposit(
                    token,
                    address(this)
                );
                gains = IERC20(token).balanceOf(address(this)) - gains;
                gains = _takeFee(gains);
                IERC20(token).safeTransfer(msg.sender, gains);
                emit MetaAccumulation(bonusToken, token, msg.sender, gains);
            }
        }
    }

    function swapToken(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline,
        address to,
        address bonusToken,
        uint256 bonusThreshold
    ) external virtual override ensure(deadline) returns (uint256 amountOut) {
        amountOut = _swapToken(poolPath, tokenPath, amountIn, to);
        if (amountOut < minAmountOut) {
            revert InsufficientAmountOut(amountOut, minAmountOut);
        }
        emit MetaSwap(poolPath, tokenPath, amountIn, amountOut, to);
        accumulate(bonusToken, bonusThreshold);
    }

    function _swapToken(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        uint256 amount,
        address to
    ) internal returns (uint256 amountB) {
        address swapDestination = to;
        if (
            IBonfireTokenTracker(tracker).getTotalTaxP(tokenPath[0]) == 0 ||
            IBonfireTokenTracker(tracker).getTotalTaxP(
                tokenPath[tokenPath.length - 1]
            ) >
            0
        ) {
            (amount, amountB) = (_takeFee(amount), amount);
            if (amountB > amount) {
                IERC20(tokenPath[0]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    amountB - amount
                );
            }
        } else {
            //take fee later (needs to be untaxed token for this)
            swapDestination = address(this);
        }
        address target = poolPath.length > 1 ? poolPath[1] : swapDestination;
        amountB = IERC20(tokenPath[1]).balanceOf(target);
        _firstSwap(poolPath[0], target, tokenPath, amount);
        amount = IERC20(tokenPath[1]).balanceOf(target) - amountB;
        amountB = _swapTokenCore(
            poolPath[1:],
            tokenPath[1:],
            amount,
            swapDestination
        );
        if (swapDestination != to) {
            amount = _takeFee(amountB);
            //in case of taxed token that is not registerd with the tracker the user
            //would receive less than amountB
            amountB = IERC20(tokenPath[tokenPath.length - 1]).balanceOf(to);
            IERC20(tokenPath[tokenPath.length - 1]).safeTransfer(to, amount);
            amountB =
                IERC20(tokenPath[tokenPath.length - 1]).balanceOf(to) -
                amountB;
            //require (amountB == amount, "Meta: Please register this taxed token with BonfireTokenTracker");
        }
    }

    function buyToken(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        uint256 minAmountOut,
        uint256 deadline,
        address to,
        address bonusToken,
        uint256 bonusThreshold
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256 amountOut)
    {
        amountOut = _buyToken(poolPath, tokenPath, to);
        if (amountOut < minAmountOut) {
            revert InsufficientAmountOut(amountOut, minAmountOut);
        }
        emit MetaSwap(poolPath, tokenPath, msg.value, amountOut, to);
        accumulate(bonusToken, bonusThreshold);
    }

    function _buyToken(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        address to
    ) internal returns (uint256 amountB) {
        uint256 amount = _takeFee(msg.value);
        if (amount == 0) {
            revert BadUse(4); //buying requires value > 0
        }
        IWETH(WETH).deposit{value: amount}();
        address target = poolPath.length > 1 ? poolPath[1] : to;
        if (BonfireSwapHelper.isWrapper(poolPath[0])) {
            if (BonfireSwapHelper.isWrapper(target) && poolPath.length > 1) {
                revert BadUse(5); //do not wrap/convert the wrapped weth
            }
            //only case: wrap weth
            address weth = BonfireTokenHelper.getSourceToken(tokenPath[1]);
            if (weth != WETH) {
                revert BadAddress(2, weth); //proxy token needs to have source weth
            }
            IBonfireTokenWrapper(poolPath[0]).announceDeposit(weth);
            IERC20(tokenPath[0]).safeTransfer(poolPath[0], amount);
            {
                amountB = IERC20(tokenPath[1]).balanceOf(target);
                IBonfireTokenWrapper(poolPath[0]).executeDeposit(
                    tokenPath[1],
                    target
                );
                amount = IERC20(tokenPath[1]).balanceOf(target) - amountB;
            }
        } else {
            if (_prepareWrapperInCase(target, tokenPath)) {
                target = address(this);
            }
            //and swap
            IERC20(tokenPath[0]).safeTransfer(poolPath[0], amount);
            amountB = IERC20(tokenPath[1]).balanceOf(target);
            _pairSwap(poolPath[0], tokenPath[0], tokenPath[1], target);
            amount = IERC20(tokenPath[1]).balanceOf(target) - amountB;
        }
        amountB = _swapTokenCore(poolPath[1:], tokenPath[1:], amount, to);
    }

    function sellToken(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline,
        address to,
        address bonusToken,
        uint256 bonusThreshold
    ) external virtual override ensure(deadline) returns (uint256 amountOut) {
        amountOut = _sellToken(poolPath, tokenPath, amountIn, to);
        if (amountOut < minAmountOut) {
            revert InsufficientAmountOut(amountOut, minAmountOut);
        }
        emit MetaSwap(poolPath, tokenPath, amountIn, amountOut, to);
        accumulate(bonusToken, bonusThreshold);
    }

    function _sellToken(
        address[] calldata poolPath,
        address[] calldata tokenPath,
        uint256 amount,
        address to
    ) internal returns (uint256 amountB) {
        address weth = WETH; //gas optimization
        if (tokenPath[tokenPath.length - 1] != weth) {
            revert BadAddress(3, tokenPath[tokenPath.length - 1]); //last token in sell must be weth
        }
        address target = poolPath.length > 1 ? poolPath[1] : address(this);
        amountB = IERC20(tokenPath[1]).balanceOf(target);
        _firstSwap(poolPath[0], target, tokenPath, amount);
        amount = IERC20(tokenPath[1]).balanceOf(target) - amountB;
        amountB = _swapTokenCore(
            poolPath[1:],
            tokenPath[1:],
            amount,
            address(this)
        );
        IWETH(weth).withdraw(amountB);
        amountB = _takeFee(amountB);
        TransferHelper.safeTransferETH(to, amountB);
    }

    /*
     * The only reason for this contract to receive uncontrolled ETH is for
     * unwrapping WETH.
     */
    receive() external payable {
        assert(msg.sender == WETH);
    }

    /*
     * nota bene:
     * we assume that only untaxed tokens are withdrawn
     * none of the fee taking functions should collect taxed tokens, but either
     * only untaxed tokens, eth or wrapped taxed tokens.
     */
    function withdrawToken(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (amount == 0) amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, amount);
    }

    function withdrawETH(address payable to, uint256 amount)
        external
        onlyOwner
    {
        if (amount == 0) amount = address(this).balance;
        TransferHelper.safeTransferETH(to, amount);
    }
}