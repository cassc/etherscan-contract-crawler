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

    bytes32 public constant LP_ADMIN_ROLE = keccak256("LP_ADMIN_ROLE");

    address public treasury;
    mapping(address => address) public routerByFactory;
    address public immutable USDT;

    uint256 private _sellDelay;

    mapping(address => uint256) private _lastAdded;

    EnumerableSet.AddressSet private _lpTokens;

    event LPTokenAdded(address indexed tokenAddress);
    event LPTokenCleared(address indexed tokenAddress);
    event SellDelayUpdated(uint256 indexed oldDelay, uint256 indexed newDelay);

    constructor(
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
        if (uniswapV2RouterAddress != address(0)) {
            routerByFactory[IUniswapV2Router01(uniswapV2RouterAddress).factory()] = uniswapV2RouterAddress;
        }
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
        for (uint256 i = lpTokensLength - 1; i > 0; i--) {
            address lpToken = _lpTokens.at(i);
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
        IUniswapV2Pair lpToken = IUniswapV2Pair(tokenAddress);

        try lpToken.token0() returns (address) {} catch (
            bytes memory /* lowLevelData */
        ) {
            return false;
        }

        try lpToken.token1() returns (address) {} catch (
            bytes memory /* lowLevelData */
        ) {
            return false;
        }

        return true;
    }

    function _removeLiquidity(address lpTokenAddress, address routerAddress) private {
        IUniswapV2Router01 router = IUniswapV2Router01(routerAddress);
        address WETHAddress = router.WETH();
        IUniswapV2Pair lpToken = IUniswapV2Pair(lpTokenAddress);
        uint256 lpBalance = lpToken.balanceOf(address(this));
        lpToken.approve(routerAddress, lpBalance);

        if (lpToken.token0() == WETHAddress) {
            router.removeLiquidityETH(lpToken.token1(), lpBalance, 0, 0, address(this), block.timestamp);

            _swapTokensForETH(lpToken.token1(), WETHAddress, routerAddress);
        } else if (lpToken.token1() == WETHAddress) {
            router.removeLiquidityETH(lpToken.token0(), lpBalance, 0, 0, address(this), block.timestamp);

            _swapTokensForETH(lpToken.token0(), WETHAddress, routerAddress);
        } else {
            router.removeLiquidity(lpToken.token0(), lpToken.token1(), lpBalance, 0, 0, address(this), block.timestamp);

            _swapTokensForETH(lpToken.token0(), WETHAddress, routerAddress);
            _swapTokensForETH(lpToken.token1(), WETHAddress, routerAddress);
        }

        _lpTokens.remove(lpTokenAddress);

        emit LPTokenCleared(lpTokenAddress);
    }

    function _swapTokensForETH(
        address tokenAddress,
        address WETHAddress,
        address routerAddress
    ) private {
        IUniswapV2Router01 router = IUniswapV2Router01(routerAddress);
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = WETHAddress;

        token.approve(address(router), tokenBalance);
        try router.swapExactTokensForETH(tokenBalance, 0, path, treasury, block.timestamp) returns (
            uint256[] memory /* amounts */
        ) {} catch (
            bytes memory /* lowLevelData */
        ) {}
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