// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

import "../interfaces/ILPTokenProcessor.sol";

contract LPTokenProcessorV1 is ILPTokenProcessor, KeeperCompatible, AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    bytes32 public constant LP_ADMIN_ROLE = keccak256("LP_ADMIN_ROLE");

    address public treasury;
    mapping(address => address) public routerByFactory;
    address public immutable USDT;
    address public immutable FLOKI;

    IUniswapV2Router01 public routerForFloki;

    uint256 private _sellDelay;

    mapping(address => uint256) private _lastAdded;

    EnumerableSet.AddressSet private _lpTokens;

    uint256 public constant burnBasisPoints = 2500;

    event LPTokenAdded(address indexed tokenAddress);
    event LPTokenCleared(address indexed tokenAddress);
    event SellDelayUpdated(uint256 indexed oldDelay, uint256 indexed newDelay);

    constructor(
        address flokiAddress,
        uint256 sellDelay,
        address uniswapV2RouterAddress,
        address usdtAddress,
        address treasuryAddress
    ) {
        require(
            uniswapV2RouterAddress != address(0),
            "LPTokenProcessorV1::constructor::ZERO: Router cannot be zero address."
        );
        require(usdtAddress != address(0), "LPTokenProcessorV1::constructor::ZERO: USDT cannot be zero address.");
        require(
            treasuryAddress != address(0),
            "LPTokenProcessorV1::constructor::ZERO: Treasury cannot be zero address."
        );
        _sellDelay = sellDelay;
        routerForFloki = IUniswapV2Router01(uniswapV2RouterAddress);
        if (uniswapV2RouterAddress != address(0)) {
            routerByFactory[IUniswapV2Router01(uniswapV2RouterAddress).factory()] = uniswapV2RouterAddress;
        }
        FLOKI = flokiAddress;
        USDT = usdtAddress;
        treasury = treasuryAddress;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setSellDelay(uint256 newDelay) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldDelay = _sellDelay;
        _sellDelay = newDelay;

        emit SellDelayUpdated(oldDelay, newDelay);
    }

    function addLiquidityPoolToken(address tokenAddress) external override onlyRole(LP_ADMIN_ROLE) {
        // Update timestamp before checking whether token was already in the
        // set of locked LP tokens, because otherwise the timestamp would
        // not be updated on repeated calls (within the selling timeframe).
        _lastAdded[tokenAddress] = block.timestamp;

        if (_lpTokens.add(tokenAddress)) {
            emit LPTokenAdded(tokenAddress);
        }
    }

    function addRouter(address routerAddress) external onlyRole(LP_ADMIN_ROLE) {
        require(routerAddress != address(0), "LPTokenProcessorV1::addRouter::ZERO: Router cannot be zero address.");
        routerByFactory[IUniswapV2Router01(routerAddress).factory()] = routerAddress;
    }

    // Check whether any LP tokens are owned to sell.
    function checkUpkeep(
        bytes memory /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = false;

        uint256 loopLimit = _lpTokens.length();

        if (loopLimit == 0) {
            return (upkeepNeeded, abi.encode(""));
        }

        address[] memory tokenBatch = new address[](loopLimit);
        uint256 tokenBatchCounter = 0;
        for (uint256 i = 0; i < loopLimit; i++) {
            address lpToken = _lpTokens.at(i);

            if ((_lastAdded[lpToken] + _sellDelay) < block.timestamp) {
                address routerAddress = routerByFactory[IUniswapV2Pair(lpToken).factory()];
                if (routerAddress != address(0)) {
                    tokenBatch[tokenBatchCounter] = lpToken;
                    tokenBatchCounter += 1;
                }
            }
        }

        if (tokenBatchCounter > 0) {
            upkeepNeeded = true;
        }

        return (upkeepNeeded, abi.encode(tokenBatch));
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        uint256 lpTokensLength = _lpTokens.length();
        if (lpTokensLength == 0) {
            return;
        }
        for (uint256 i = lpTokensLength; i > 0; i--) {
            address lpToken = _lpTokens.at(i - 1);
            if ((_lastAdded[lpToken] + _sellDelay) < block.timestamp) {
                address routerAddress = routerByFactory[IUniswapV2Pair(lpToken).factory()];
                if (routerAddress != address(0)) {
                    _removeLiquidity(lpToken, routerAddress);
                }
            }
        }
    }

    function getRouter(address lpTokenAddress) external view override returns (address) {
        return routerByFactory[IUniswapV2Pair(lpTokenAddress).factory()];
    }

    function isLiquidityPoolToken(address tokenAddress) external view override returns (bool) {
        try IUniswapV2Pair(tokenAddress).token0() returns (address) {} catch (
            bytes memory /* lowLevelData */
        ) {
            return false;
        }

        try IUniswapV2Pair(tokenAddress).token1() returns (address) {} catch (
            bytes memory /* lowLevelData */
        ) {
            return false;
        }

        return true;
    }

    function _removeLiquidity(address lpTokenAddress, address routerAddress) private {
        IUniswapV2Pair lpToken = IUniswapV2Pair(lpTokenAddress);
        uint256 lpBalance = lpToken.balanceOf(address(this));
        lpToken.approve(routerAddress, lpBalance);

        address token0 = lpToken.token0();
        address token1 = lpToken.token1();

        bool isAlternateRouter = routerAddress != address(routerForFloki);

        // liquidate and swap by USDT
        IUniswapV2Router01(routerAddress).removeLiquidity(
            token0,
            token1,
            lpBalance,
            0,
            0,
            address(this),
            block.timestamp
        );
        // we can't use the amounts returned from removeLiquidity
        //  because it doesn't account for tokens with fees
        uint256 amount0 = IERC20(token0).balanceOf(address(this));
        uint256 amount1 = IERC20(token1).balanceOf(address(this));
        bool success = _swapTokens(token0, amount0, USDT, address(this), routerAddress);
        if (!success && isAlternateRouter) {
            // if swap failed, attempt main router
            _swapTokens(token0, amount0, USDT, address(this), address(routerForFloki));
        }
        success = _swapTokens(token1, amount1, USDT, address(this), routerAddress);
        if (!success && isAlternateRouter) {
            _swapTokens(token1, amount1, USDT, address(this), address(routerForFloki));
        }

        // burn FLOKI
        uint256 usdtAmount = IERC20(USDT).balanceOf(address(this));
        if (FLOKI != address(0)) {
            uint256 burnShare = (usdtAmount * burnBasisPoints) / 10000;
            usdtAmount -= burnShare;
            // we try using the same router as the LP Token
            success = _swapTokens(USDT, burnShare, FLOKI, BURN_ADDRESS, routerAddress);
            // but if it fails, we fallback to the main router
            if (!success && isAlternateRouter) {
                _swapTokens(USDT, burnShare, FLOKI, BURN_ADDRESS, address(routerForFloki));
            }
        }
        IERC20(USDT).safeTransfer(treasury, usdtAmount);
        _lpTokens.remove(lpTokenAddress);

        emit LPTokenCleared(lpTokenAddress);
    }

    function swapTokens(
        address sourceToken,
        uint256 sourceAmount,
        address destinationToken,
        address receiver,
        address routerAddress
    ) external override onlyRole(LP_ADMIN_ROLE) returns (bool) {
        return _swapTokens(sourceToken, sourceAmount, destinationToken, receiver, routerAddress);
    }

    function _swapTokens(
        address sourceToken,
        uint256 sourceAmount,
        address destinationToken,
        address receiver,
        address routerAddress
    ) private returns (bool) {
        IERC20 token = IERC20(sourceToken);
        // if they happen to be the same, no need to swap, just transfer
        if (sourceToken == destinationToken) {
            token.safeTransfer(receiver, sourceAmount);
            return true;
        }
        IUniswapV2Router01 router = IUniswapV2Router01(routerAddress);
        address WETH = router.WETH();

        address[] memory path;
        if (sourceToken == WETH || destinationToken == WETH) {
            path = new address[](2);
            path[0] = sourceToken;
            path[1] = destinationToken;
        } else {
            path = new address[](3);
            path[0] = sourceToken;
            path[1] = WETH;
            path[2] = destinationToken;
        }

        uint256 allowed = token.allowance(address(this), routerAddress);
        if (allowed > 0) {
            token.safeApprove(routerAddress, 0);
        }
        token.safeApprove(routerAddress, sourceAmount);

        try router.swapExactTokensForTokens(sourceAmount, 0, path, receiver, block.timestamp) returns (
            uint256[] memory /* amounts */
        ) {} catch (
            bytes memory /* lowLevelData */
        ) {
            return false;
        }
        return true;
    }

    function adminWithdraw(address tokenAddress, uint256 amount) external onlyRole(LP_ADMIN_ROLE) {
        if (tokenAddress == address(0)) {
            // We specifically ignore this return value.
            payable(treasury).call{ value: amount }("");
        } else {
            IERC20(tokenAddress).safeTransfer(treasury, amount);
        }
    }

    receive() external payable {}
}