// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/CloberMarketFactory.sol";
import "./interfaces/CloberVolatileMarketDeployer.sol";
import "./interfaces/CloberStableMarketDeployer.sol";
import "./Errors.sol";
import "./utils/RevertOnDelegateCall.sol";
import "./utils/ReentrancyGuard.sol";
import "./OrderNFT.sol";
import "./utils/BoringERC20.sol";

contract MarketFactory is CloberMarketFactory, ReentrancyGuard, RevertOnDelegateCall {
    using BoringERC20 for IERC20;

    uint24 private constant _MAX_FEE = 500000; // 50%
    int24 private constant _MIN_FEE = -500000; // -50%
    uint24 private constant _VOLATILE_MIN_NET_FEE = 400; // 0.04%
    uint24 private constant _STABLE_MIN_NET_FEE = 80; // 0.008%

    uint256 private immutable _cachedChainId;
    address public immutable override volatileMarketDeployer;
    address public immutable override stableMarketDeployer;
    address public immutable override canceler;
    bytes32 private immutable _orderTokenBytecodeHash;

    mapping(address => bool) public override registeredQuoteTokens;
    address public override owner;
    address public override futureOwner;
    address public override daoTreasury;
    uint256 public override nonce;

    mapping(address => MarketInfo) private _marketInfos;

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function _checkOwner() internal view {
        if (msg.sender != owner) {
            revert Errors.CloberError(Errors.ACCESS);
        }
    }

    modifier onlyRegisteredQuoteToken(address token) {
        if (!registeredQuoteTokens[token]) {
            revert Errors.CloberError(Errors.INVALID_QUOTE_TOKEN);
        }
        _;
    }

    constructor(
        address volatileMarketDeployer_,
        address stableMarketDeployer_,
        address initialDaoTreasury,
        address canceler_,
        address[] memory initialQuoteTokenRegistrations_
    ) {
        _cachedChainId = block.chainid;
        owner = msg.sender;
        emit ChangeOwner(address(0), msg.sender);

        volatileMarketDeployer = volatileMarketDeployer_;
        stableMarketDeployer = stableMarketDeployer_;
        daoTreasury = initialDaoTreasury;
        emit ChangeDaoTreasury(address(0), initialDaoTreasury);
        _orderTokenBytecodeHash = keccak256(
            abi.encodePacked(type(OrderNFT).creationCode, abi.encode(address(this), canceler_))
        );
        canceler = canceler_;

        for (uint256 i = 0; i < initialQuoteTokenRegistrations_.length; ++i) {
            registeredQuoteTokens[initialQuoteTokenRegistrations_[i]] = true;
        }
    }

    function createVolatileMarket(
        address marketHost,
        address quoteToken,
        address baseToken,
        uint96 quoteUnit,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 r
    ) external revertOnDelegateCall onlyRegisteredQuoteToken(quoteToken) returns (address market) {
        _checkFee(marketHost, makerFee, takerFee, _VOLATILE_MIN_NET_FEE);
        bytes32 salt = _calculateSalt(nonce);
        address orderToken = _deployToken(salt);
        if (quoteUnit == 0) {
            revert Errors.CloberError(Errors.EMPTY_INPUT);
        }
        market = CloberVolatileMarketDeployer(volatileMarketDeployer).deploy(
            orderToken,
            quoteToken,
            baseToken,
            salt,
            quoteUnit,
            makerFee,
            takerFee,
            a,
            r
        );
        emit CreateVolatileMarket(
            market,
            orderToken,
            quoteToken,
            baseToken,
            quoteUnit,
            nonce,
            makerFee,
            takerFee,
            a,
            r
        );
        _storeMarketInfo(market, marketHost, MarketType.VOLATILE, a, r);
        _initToken(orderToken, quoteToken, baseToken, nonce, market);
        nonce++;
    }

    function createStableMarket(
        address marketHost,
        address quoteToken,
        address baseToken,
        uint96 quoteUnit,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 d
    ) external revertOnDelegateCall onlyRegisteredQuoteToken(quoteToken) returns (address market) {
        _checkFee(marketHost, makerFee, takerFee, _STABLE_MIN_NET_FEE);
        bytes32 salt = _calculateSalt(nonce);
        address orderToken = _deployToken(salt);
        if (quoteUnit == 0) {
            revert Errors.CloberError(Errors.EMPTY_INPUT);
        }

        market = CloberStableMarketDeployer(stableMarketDeployer).deploy(
            orderToken,
            quoteToken,
            baseToken,
            salt,
            quoteUnit,
            makerFee,
            takerFee,
            a,
            d
        );
        emit CreateStableMarket(market, orderToken, quoteToken, baseToken, quoteUnit, nonce, makerFee, takerFee, a, d);
        _storeMarketInfo(market, marketHost, MarketType.STABLE, a, d);
        _initToken(orderToken, quoteToken, baseToken, nonce, market);
        nonce++;
    }

    function changeDaoTreasury(address treasury) external onlyOwner {
        emit ChangeDaoTreasury(daoTreasury, treasury);
        daoTreasury = treasury;
    }

    function prepareChangeOwner(address newOwner) external onlyOwner {
        futureOwner = newOwner;
    }

    function executeChangeOwner() external {
        address newOwner = futureOwner;
        if (msg.sender != newOwner) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        emit ChangeOwner(owner, newOwner);
        owner = newOwner;
        delete futureOwner;
    }

    function getMarketHost(address market) external view returns (address) {
        return _marketInfos[market].host;
    }

    function prepareHandOverHost(address market, address newHost) external {
        address previousHost = _marketInfos[market].host;
        if (previousHost != msg.sender) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        _marketInfos[market].futureHost = newHost;
    }

    function executeHandOverHost(address market) external {
        MarketInfo storage info = _marketInfos[market];
        address previousHost = info.host;
        address newHost = info.futureHost;
        if (newHost != msg.sender) {
            revert Errors.CloberError(Errors.ACCESS);
        }
        info.host = newHost;
        delete info.futureHost;
        emit ChangeHost(market, previousHost, newHost);
    }

    function _checkFee(
        address marketHost,
        int24 makerFee,
        uint24 takerFee,
        uint24 minNetFee
    ) internal view {
        // check makerFee
        if (makerFee < _MIN_FEE || int24(_MAX_FEE) < makerFee) {
            revert Errors.CloberError(Errors.INVALID_FEE);
        }
        // check takerFee
        // takerFee is always positive
        if (_MAX_FEE < takerFee) {
            revert Errors.CloberError(Errors.INVALID_FEE);
        }
        // check net fee
        if (marketHost != owner && int256(uint256(takerFee)) + makerFee < int256(uint256(minNetFee))) {
            revert Errors.CloberError(Errors.INVALID_FEE);
        } else if (makerFee < 0 && int256(uint256(takerFee)) + makerFee < 0) {
            revert Errors.CloberError(Errors.INVALID_FEE);
        }
    }

    function _deployToken(bytes32 salt) internal returns (address) {
        return address(new OrderNFT{salt: salt}(address(this), canceler));
    }

    function _initToken(
        address token,
        address quoteToken,
        address baseToken,
        uint256 marketNonce,
        address market
    ) internal {
        OrderNFT(token).init(
            formatOrderTokenName(quoteToken, baseToken, marketNonce),
            formatOrderTokenSymbol(quoteToken, baseToken, marketNonce),
            market
        );
    }

    function _storeMarketInfo(
        address market,
        address host,
        MarketType marketType,
        uint128 a,
        uint128 factor
    ) internal {
        if (host == address(0)) {
            revert Errors.CloberError(Errors.EMPTY_INPUT);
        }
        _marketInfos[market] = MarketInfo({
            host: host,
            marketType: marketType,
            a: a,
            factor: factor,
            futureHost: address(0)
        });
        emit ChangeHost(market, address(0), host);
    }

    function computeTokenAddress(uint256 marketNonce) external view returns (address) {
        return Create2.computeAddress(_calculateSalt(marketNonce), _orderTokenBytecodeHash);
    }

    function getMarketInfo(address market) external view returns (MarketInfo memory) {
        return _marketInfos[market];
    }

    function registerQuoteToken(address token) external onlyOwner {
        registeredQuoteTokens[token] = true;
    }

    function unregisterQuoteToken(address token) external onlyOwner {
        registeredQuoteTokens[token] = false;
    }

    function _calculateSalt(uint256 marketNonce) internal view returns (bytes32) {
        return keccak256(abi.encode(_cachedChainId, marketNonce));
    }

    function formatOrderTokenName(
        address quoteToken,
        address baseToken,
        uint256 marketNonce
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "Clober Order: ",
                    IERC20(baseToken).safeSymbol(),
                    "/",
                    IERC20(quoteToken).safeSymbol(),
                    "(",
                    Strings.toString(marketNonce),
                    ")"
                )
            );
    }

    function formatOrderTokenSymbol(
        address quoteToken,
        address baseToken,
        uint256 marketNonce
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "CLOB-",
                    IERC20(baseToken).safeSymbol(),
                    "/",
                    IERC20(quoteToken).safeSymbol(),
                    "(",
                    Strings.toString(marketNonce),
                    ")"
                )
            );
    }
}