// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { KeeperCompatible } from "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { ILPTokenProcessorV2 } from "../interfaces/ILPTokenProcessorV2.sol";
import { INonfungiblePositionManager } from "../../common/interfaces/INonfungiblePositionManager.sol";
import { IPriceOracleManager } from "../../common/interfaces/IPriceOracleManager.sol";

contract LPTokenProcessorV2 is ILPTokenProcessorV2, KeeperCompatible, AccessControlEnumerable {
    using SafeERC20 for IERC20Metadata;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    bytes32 public constant LP_ADMIN_ROLE = keccak256("LP_ADMIN_ROLE");

    address public treasury;
    mapping(address => address) public routerByFactory;
    mapping(address => bool) public V2Routers;
    address public immutable USDT;
    address public immutable FLOKI;

    address public routerForFloki;

    IPriceOracleManager public priceOracle;

    uint256 private _sellDelay;

    mapping(address => uint256) private _lastAdded;

    TokenSwapInfo[] private _tokens;
    mapping(address => bool) private _isV2LPToken;
    mapping(address => address) private _tokenFactories;

    uint256 public constant burnBasisPoints = 2500; // 25%
    uint256 public constant referrerBasisPoints = 2500; // 25%
    uint256 public slippageBasisPoints = 300; // 3%
    mapping(address => uint256) public perTokenSlippage;
    bool public requireOraclePrice;

    uint256 public feeCollectedLastBlock;
    uint256 public flokiBurnedLastBlock;
    uint256 public referrerShareLastBlock;

    event TokenAdded(address indexed tokenAddress);
    event TokenProcessed(address indexed tokenAddress);
    event TokenRemoved(address indexed tokenAddress);
    event SellDelayUpdated(uint256 indexed oldDelay, uint256 indexed newDelay);
    event PriceOracleUpdated(address indexed oldOracle, address indexed newOracle);
    event SlippageUpdated(uint256 oldSlippage, uint256 newSlippage);
    event SlippagePerTokenUpdated(uint256 oldSlippage, uint256 newSlippage, address token);
    event FeeCollected(uint256 indexed previousBlock, address indexed vault, uint256 usdAmount);
    event ReferrerSharedPaid(uint256 indexed previousBlock, address indexed vault, address referrer, uint256 usdAmount);
    event FlokiBurned(uint256 indexed previousBlock, address indexed vault, uint256 usdAmount, uint256 flokiAmount);

    constructor(
        address flokiAddress,
        uint256 sellDelay,
        address routerAddressForFloki,
        address usdtAddress,
        address treasuryAddress,
        address priceOracleAddress
    ) {
        require(
            routerAddressForFloki != address(0),
            "tokenProcessorV1::constructor::ZERO: Router cannot be zero address."
        );
        require(usdtAddress != address(0), "tokenProcessorV1::constructor::ZERO: USDT cannot be zero address.");
        require(treasuryAddress != address(0), "tokenProcessorV1::constructor::ZERO: Treasury cannot be zero address.");
        _sellDelay = sellDelay;
        routerForFloki = routerAddressForFloki;
        if (routerAddressForFloki != address(0)) {
            routerByFactory[IUniswapV2Router02(routerAddressForFloki).factory()] = routerAddressForFloki;
            V2Routers[routerAddressForFloki] = true;
        }
        FLOKI = flokiAddress;
        USDT = usdtAddress;
        treasury = treasuryAddress;
        priceOracle = IPriceOracleManager(priceOracleAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setSellDelay(uint256 newDelay) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldDelay = _sellDelay;
        _sellDelay = newDelay;

        emit SellDelayUpdated(oldDelay, newDelay);
    }

    function setPriceOracle(address newOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldOracle = address(priceOracle);
        priceOracle = IPriceOracleManager(newOracle);
        emit PriceOracleUpdated(oldOracle, newOracle);
    }

    function setSlippageBasisPoints(uint256 newSlippage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldSlippage = slippageBasisPoints;
        slippageBasisPoints = newSlippage;
        emit SlippageUpdated(oldSlippage, newSlippage);
    }

    function setSlippagePerToken(uint256 slippage, address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldSlippage = perTokenSlippage[token];
        perTokenSlippage[token] = slippage;
        emit SlippagePerTokenUpdated(oldSlippage, slippage, token);
    }

    function setRequireOraclePrice(bool requires) external onlyRole(DEFAULT_ADMIN_ROLE) {
        requireOraclePrice = requires;
    }

    function addTokenForSwapping(TokenSwapInfo memory params) external override onlyRole(LP_ADMIN_ROLE) {
        // Update timestamp before checking whether token was already in the
        // set of locked LP tokens, because otherwise the timestamp would
        // not be updated on repeated calls (within the selling timeframe).
        _lastAdded[params.tokenAddress] = block.timestamp;
        _tokens.push(params);
        _isV2LPToken[params.tokenAddress] = params.isV2;
        _tokenFactories[params.tokenAddress] = params.routerFactory;
        emit TokenAdded(params.tokenAddress);
    }

    function clearTokensFromSwapping() external onlyRole(LP_ADMIN_ROLE) {
        delete _tokens;
    }

    function removeTokensFromSwappingByIndexes(uint256[] memory indexes) external onlyRole(LP_ADMIN_ROLE) {
        for (uint256 i = 0; i < indexes.length; i++) {
            uint256 index = indexes[i];
            address tokenAddress = _tokens[index].tokenAddress;
            _tokens[index] = _tokens[_tokens.length - 1];
            _tokens.pop();
            emit TokenRemoved(tokenAddress);
        }
    }

    function removeTokenFromSwapping(address tokenAddress) external onlyRole(LP_ADMIN_ROLE) {
        for (uint256 i = _tokens.length; i > 0; i--) {
            if (_tokens[i - 1].tokenAddress == tokenAddress) {
                _tokens[i - 1] = _tokens[_tokens.length - 1];
                _tokens.pop();
                break;
            }
        }
    }

    function getTokensForSwapping() external view returns (address[] memory) {
        uint256 length = _tokens.length;
        address[] memory tokens = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = _tokens[i].tokenAddress;
        }
        return tokens;
    }

    function addRouter(address routerAddress, bool isV2) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(routerAddress != address(0), "tokenProcessorV1::addRouter::ZERO: Router cannot be zero address.");
        routerByFactory[IUniswapV2Router02(routerAddress).factory()] = routerAddress;
        V2Routers[routerAddress] = isV2;
    }

    function getRouter(address tokenAddress) external view override returns (address) {
        return routerByFactory[IUniswapV2Pair(tokenAddress).factory()];
    }

    function isV2LiquidityPoolToken(address token) external view override returns (bool) {
        bool success = false;
        bytes memory data;
        address tokenAddress;

        (success, data) = token.staticcall(abi.encodeWithSelector(IUniswapV2Pair.token0.selector));
        if (!success) {
            return false;
        }
        assembly {
            tokenAddress := mload(add(data, 32))
        }
        if (!_isContract(tokenAddress)) {
            return false;
        }

        (success, data) = token.staticcall(abi.encodeWithSelector(IUniswapV2Pair.token1.selector));
        if (!success) {
            return false;
        }
        assembly {
            tokenAddress := mload(add(data, 32))
        }
        if (!_isContract(tokenAddress)) {
            return false;
        }

        return true;
    }

    function _isContract(address externalAddress) private view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(externalAddress)
        }
        return codeSize > 0;
    }

    function isV3LiquidityPoolToken(address tokenAddress, uint256 tokenId) external view override returns (bool) {
        (address token0, address token1, ) = getV3Position(tokenAddress, tokenId);
        return token0 != address(0) && token1 != address(0);
    }

    function getV3Position(address tokenAddress, uint256 tokenId)
        public
        view
        override
        returns (
            address,
            address,
            uint128
        )
    {
        try INonfungiblePositionManager(tokenAddress).positions(tokenId) returns (
            uint96,
            address,
            address token0,
            address token1,
            uint24,
            int24,
            int24,
            uint128 liquidity,
            uint256,
            uint256,
            uint128,
            uint128
        ) {
            return (token0, token1, liquidity);
        } catch {
            return (address(0), address(0), 0);
        }
    }

    // Check whether any LP tokens are owned to sell.
    function checkUpkeep(
        bytes memory /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        uint256 loopLimit = _tokens.length;

        if (loopLimit == 0) {
            return (false, abi.encode(""));
        }

        for (uint256 i = 0; i < loopLimit; i++) {
            TokenSwapInfo memory tokenInfo = _tokens[i];
            if ((_lastAdded[tokenInfo.tokenAddress] + _sellDelay) < block.timestamp) {
                address routerFactory = _tokenFactories[tokenInfo.tokenAddress];
                address routerAddress = routerByFactory[routerFactory];
                if (routerAddress != address(0)) {
                    // We only need one token ready for processing
                    return (true, abi.encode(""));
                }
            }
        }
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        uint256 tokensLength = _tokens.length;
        if (tokensLength == 0) {
            return;
        }
        for (uint256 i = 0; i < tokensLength; i++) {
            bool success = _processTokenSwapping(i);
            if (success) break; // only process one token per transaction
        }
    }

    function processTokenSwapping(address token) external onlyRole(LP_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i].tokenAddress == token) {
                _processTokenSwapping(i);
                break;
            }
        }
    }

    function _processTokenSwapping(uint256 index) private returns (bool) {
        TokenSwapInfo memory info = _tokens[index];
        address routerFactory = _tokenFactories[info.tokenAddress];
        address routerAddress = routerByFactory[routerFactory];
        if (routerAddress == address(0)) return false;
        if ((_lastAdded[info.tokenAddress] + _sellDelay) >= block.timestamp) return false;

        uint256 initialUsdtAmount = IERC20Metadata(USDT).balanceOf(address(this));
        if (_isV2LPToken[info.tokenAddress]) {
            // V2 LP Tokens
            _swapV2TokenByUSDT(info.tokenAddress, info.amount, routerAddress);
        } else {
            // Regular ERC20 tokens
            bool success = _swapTokens(info.tokenAddress, info.amount, USDT, address(this), routerAddress);
            require(success, "tokenProcessorV1::performUpkeep: Failed to swap ERC20 token by USDT.");
        }
        uint256 newUsdtAmount = IERC20Metadata(USDT).balanceOf(address(this));
        uint256 usdtAmount = newUsdtAmount - initialUsdtAmount;
        _processFees(info, usdtAmount);
        _tokens[index] = _tokens[_tokens.length - 1];
        _tokens.pop();
        emit TokenProcessed(info.tokenAddress);
        return true;
    }

    /**
     * Unpairs the liquidity pool token and swap the unpaired tokens by USDT.
     */
    function _swapV2TokenByUSDT(
        address tokenAddress,
        uint256 lpBalance,
        address routerAddress
    ) private returns (uint256) {
        require(routerAddress != address(0), "tokenProcessorV1::_swapV2TokenByUSDT: Unsupported router.");
        IUniswapV2Pair lpToken = IUniswapV2Pair(tokenAddress);
        lpToken.approve(routerAddress, lpBalance);

        address token0 = lpToken.token0();
        address token1 = lpToken.token1();

        // liquidate and swap by USDT
        IUniswapV2Router02(routerAddress).removeLiquidity(
            token0,
            token1,
            lpBalance,
            0,
            0,
            address(this),
            block.timestamp
        );
        // we can't use the amounts returned from "removeLiquidity"
        //  because it doesn't take fees/taxes into account
        bool success = _swapTokens(
            token0,
            IERC20Metadata(token0).balanceOf(address(this)),
            USDT,
            address(this),
            routerAddress
        );
        require(success, "tokenProcessorV1::_swapV2TokenByUSDT: Failed to swap token0 to USDT.");
        success = _swapTokens(
            token1,
            IERC20Metadata(token1).balanceOf(address(this)),
            USDT,
            address(this),
            routerAddress
        );
        require(success, "tokenProcessorV1::_swapV2TokenByUSDT: Failed to swap token1 to USDT.");

        return lpBalance;
    }

    function _burnFloki(uint256 usdtAmount, address vault) private returns (uint256) {
        // Burn FLOKI
        if (FLOKI != address(0)) {
            uint256 burnShare = (usdtAmount * burnBasisPoints) / 10000;
            usdtAmount -= burnShare;
            uint256 flokiBurnedInitial = IERC20Metadata(FLOKI).balanceOf(BURN_ADDRESS);
            _swapTokens(USDT, burnShare, FLOKI, BURN_ADDRESS, routerForFloki);
            uint256 flokiBurned = IERC20Metadata(FLOKI).balanceOf(BURN_ADDRESS) - flokiBurnedInitial;
            emit FlokiBurned(flokiBurnedLastBlock, vault, usdtAmount, flokiBurned);
            flokiBurnedLastBlock = block.number;
        }
        return usdtAmount;
    }

    function _processFees(TokenSwapInfo memory info, uint256 usdtBalance) private {
        // Pay referrers
        uint256 treasuryShare = _burnFloki(usdtBalance, info.vault);
        if (info.referrer != address(0)) {
            uint256 referrerShare = (usdtBalance * referrerBasisPoints) / 10000;
            treasuryShare -= referrerShare;
            IERC20Metadata(USDT).safeTransfer(info.referrer, referrerShare);
            emit ReferrerSharedPaid(referrerShareLastBlock, info.vault, info.referrer, referrerShare);
            referrerShareLastBlock = block.number;
        }
        IERC20Metadata(USDT).safeTransfer(treasury, treasuryShare);
        emit FeeCollected(feeCollectedLastBlock, info.vault, treasuryShare);
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
        IERC20Metadata token = IERC20Metadata(sourceToken);
        // if they happen to be the same, no need to swap, just transfer
        if (sourceToken == destinationToken) {
            token.safeTransfer(receiver, sourceAmount);
            return true;
        }
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
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

        uint256 amount = 0;
        if (destinationToken == USDT) {
            uint256 price = _getPriceInUSDWithSlippage(sourceToken);
            amount = (sourceAmount * price) / 10**token.decimals();
        }
        try
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                sourceAmount,
                amount,
                path,
                receiver,
                block.timestamp
            )
        {} catch (
            bytes memory /* lowLevelData */
        ) {
            return false;
        }
        return true;
    }

    function _getPriceInUSDWithSlippage(address token) private returns (uint256) {
        if (address(priceOracle) == address(0)) {
            return 0;
        }
        priceOracle.fetchPriceInUSD(token);
        // the USD price in the same decimals as the USDT token
        uint256 price = priceOracle.getPriceInUSD(token, IERC20Metadata(USDT).decimals());
        require(price > 0 || !requireOraclePrice, "tokenProcessorV1::_getPriceWithSlippage: Price is zero.");
        uint256 slippage = perTokenSlippage[token];
        if (slippage == 0) {
            slippage = slippageBasisPoints;
        }
        return price - ((price * slippage) / 10000);
    }

    function adminWithdraw(
        address tokenAddress,
        uint256 amount,
        address destination
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenAddress == address(0)) {
            // We specifically ignore this return value.
            payable(destination).call{ value: amount }("");
        } else {
            IERC20Metadata(tokenAddress).safeTransfer(destination, amount);
        }
    }

    receive() external payable {}
}