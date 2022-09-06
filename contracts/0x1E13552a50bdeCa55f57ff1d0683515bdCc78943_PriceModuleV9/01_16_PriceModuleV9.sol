// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./ChainlinkService.sol";
import "../interfaces/IPriceModule.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/curve/IAddressProvider.sol";
import "../interfaces/curve/IRegistry.sol";
import "../interfaces/yearn/IVault.sol";
import "../interfaces/yieldster/IYieldsterVault.sol";
import "../interfaces/compound/IUniswapAnchoredView.sol";
import "../interfaces/aave/Iatoken.sol";
import "../interfaces/convex/IConvex.sol";
import "../interfaces/compound/ICToken.sol";
import "../interfaces/IERC20.sol";

contract PriceModuleV9 is ChainlinkService, Initializable {
    using SafeMath for uint256;

    address public priceModuleManager; // Address of the Price Module Manager
    address public curveAddressProvider; // Address of the Curve Address provider contract.
    address public uniswapAnchoredView; // Address of the Uniswap Anchored view. Used by Compound.

    struct Token {
        address feedAddress;
        uint256 tokenType;
        bool created;
    }

    mapping(address => Token) tokens; // Mapping from address to Token Information
    mapping(address => address) wrappedToUnderlying; // Mapping from wrapped token to underlying

    address public apContract;

    /// @dev Function to initialize priceModuleManager and curveAddressProvider.
    function initialize() public {
        priceModuleManager = msg.sender;
        curveAddressProvider = 0x0000000022D53366457F9d5E68Ec105046FC4383;
        uniswapAnchoredView = 0x65c816077C29b557BEE980ae3cC2dCE80204A0C5;
    }

    /// @dev Function to change the address of UniswapAnchoredView Address provider contract.
    /// @param _uniswapAnchoredView Address of new UniswapAnchoredView provider contract.
    function changeUniswapAnchoredView(address _uniswapAnchoredView) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        uniswapAnchoredView = _uniswapAnchoredView;
    }

    /// @dev Function to change the address of Curve Address provider contract.
    /// @param _crvAddressProvider Address of new Curve Address provider contract.
    function changeCurveAddressProvider(address _crvAddressProvider) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        curveAddressProvider = _crvAddressProvider;
    }

    /// @dev Function to set new Price Module Manager.
    /// @param _manager Address of new Manager.
    function setManager(address _manager) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        priceModuleManager = _manager;
    }

    /// @dev Function to add a token to Price Module.
    /// @param _tokenAddress Address of the token.
    /// @param _feedAddress Chainlink feed address of the token if it has a Chainlink price feed.
    /// @param _tokenType Type of token.
    function addToken(
        address _tokenAddress,
        address _feedAddress,
        uint256 _tokenType
    ) external {
        require(
            msg.sender == priceModuleManager || msg.sender == apContract,
            "Not Authorized"
        );
        Token memory newToken = Token({
            feedAddress: _feedAddress,
            tokenType: _tokenType,
            created: true
        });
        tokens[_tokenAddress] = newToken;
    }

    /// @dev Function to add tokens to Price Module in batch.
    /// @param _tokenAddress Address List of the tokens.
    /// @param _feedAddress Chainlink feed address list of the tokens if it has a Chainlink price feed.
    /// @param _tokenType Type of token list.
    function addTokenInBatches(
        address[] memory _tokenAddress,
        address[] memory _feedAddress,
        uint256[] memory _tokenType
    ) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            Token memory newToken = Token({
                feedAddress: address(_feedAddress[i]),
                tokenType: _tokenType[i],
                created: true
            });
            tokens[address(_tokenAddress[i])] = newToken;
        }
    }

    /// @dev Function to retrieve price of a token from Chainlink price feed.
    /// @param _feedAddress Chainlink feed address the tokens.
    function getPriceFromChainlink(address _feedAddress)
        internal
        view
        returns (uint256)
    {
        (int256 price, , uint8 decimals) = getLatestPrice(_feedAddress);
        if (decimals < 18) {
            return (uint256(price)).mul(10**uint256(18 - decimals));
        } else if (decimals > 18) {
            return (uint256(price)).div(uint256(decimals - 18));
        } else {
            return uint256(price);
        }
    }

    /// @dev Function to get price of a token.
    ///     Token Types
    ///     1 = Token with a Chainlink price feed.
    ///     2 = USD based Curve Liquidity Pool token.
    ///     3 = Yearn Vault Token.
    ///     4 = Yieldster Strategy Token.
    ///     5 = Yieldster Vault Token.
    ///     6 = Ether based Curve Liquidity Pool Token.
    ///     7 = Euro based Curve Liquidity Pool Token.
    ///     8 = BTC based Curve Liquidity Pool Token.
    ///     9 = Compound based Token.
    ///     12 = curve lp Token.

    /// @param _tokenAddress Address of the token..

    function getUSDPrice(address _tokenAddress) public view returns (uint256) {
        require(tokens[_tokenAddress].created, "Token not present");

        if (tokens[_tokenAddress].tokenType == 1) {
            return getPriceFromChainlink(tokens[_tokenAddress].feedAddress);
        } else if (tokens[_tokenAddress].tokenType == 2) {
            return
                IRegistry(IAddressProvider(curveAddressProvider).get_registry())
                    .get_virtual_price_from_lp_token(_tokenAddress);
        } else if (tokens[_tokenAddress].tokenType == 3) {
            address token = IVault(_tokenAddress).token();
            uint256 tokenPrice = getUSDPrice(token);
            return
                (tokenPrice.mul(IVault(_tokenAddress).pricePerShare())).div(
                    1e18
                );
        } else if (tokens[_tokenAddress].tokenType == 5) {
            return IYieldsterVault(_tokenAddress).tokenValueInUSD();
        } else if (tokens[_tokenAddress].tokenType == 6) {
            uint256 priceInEther = getPriceFromChainlink(
                tokens[_tokenAddress].feedAddress
            );
            uint256 etherToUSD = getUSDPrice(
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            );
            return (priceInEther.mul(etherToUSD)).div(1e18);
        } else if (tokens[_tokenAddress].tokenType == 7) {
            uint256 lpPriceEuro = IRegistry(
                IAddressProvider(curveAddressProvider).get_registry()
            ).get_virtual_price_from_lp_token(_tokenAddress);
            uint256 euroToUSD = getUSDPrice(
                address(0xb49f677943BC038e9857d61E7d053CaA2C1734C1) // Address representing Euro.
            );
            return (lpPriceEuro.mul(euroToUSD)).div(1e18);
        } else if (tokens[_tokenAddress].tokenType == 8) {
            uint256 lpPriceBTC = IRegistry(
                IAddressProvider(curveAddressProvider).get_registry()
            ).get_virtual_price_from_lp_token(_tokenAddress);
            uint256 btcToUSD = getUSDPrice(
                address(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c) // Address representing BTC.
            );
            return (lpPriceBTC.mul(btcToUSD)).div(1e18);
        } else if (tokens[_tokenAddress].tokenType == 9) {
            uint256 exchangeRate = calcExchangePrice(
                _tokenAddress,
                tokens[_tokenAddress].feedAddress
            );
            return
                (
                    (getUSDPrice(tokens[_tokenAddress].feedAddress)).mul(
                        exchangeRate
                    )
                ).div(1e18);
            // return
            //     IUniswapAnchoredView(uniswapAnchoredView).getUnderlyingPrice(
            //         _tokenAddress
            //     ); // Address of cToken (compound )
        } else if (tokens[_tokenAddress].tokenType == 10) {
            address underlyingAsset = Iatoken(_tokenAddress)
                .UNDERLYING_ASSET_ADDRESS();
            return getUSDPrice(underlyingAsset);
            // Address of aToken (aave)
        } else if (tokens[_tokenAddress].tokenType == 11) {
            address underlyingAsset = wrappedToUnderlying[_tokenAddress];
            return getUSDPrice(underlyingAsset); // Address of generalized underlying token. Eg, Convex
        } else if (tokens[_tokenAddress].tokenType == 12) {
            return
                IConvex(tokens[_tokenAddress].feedAddress).get_virtual_price(); // get USD Price from pool contract
        } else if (tokens[_tokenAddress].tokenType == 13) {
            uint256 priceInEther = IConvex(tokens[_tokenAddress].feedAddress)
                .get_virtual_price();
            uint256 etherToUSD = getUSDPrice(
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            );
            return (priceInEther.mul(etherToUSD)).div(1e18);
        } else if (tokens[_tokenAddress].tokenType == 14) {
            //similar to type 8
            uint256 lpPriceBTC = IConvex(tokens[_tokenAddress].feedAddress)
                .get_virtual_price();
            uint256 btcToUSD = getUSDPrice(
                address(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c) // Address representing BTC.
            );
            return (lpPriceBTC.mul(btcToUSD)).div(1e18);
        } else revert("Token not present");
    }

    /// @dev Function to add wrapped token to Price Module
    /// @param _wrappedToken Address of wrapped token
    /// @param _underlying Address of underlying token
    function addWrappedToken(address _wrappedToken, address _underlying)
        external
    {
        require(msg.sender == priceModuleManager, "Not Authorized");
        wrappedToUnderlying[_wrappedToken] = _underlying;
    }

    /// @dev Function to add wrapped token to Price Module in batches
    /// @param _wrappedTokens Address of wrapped tokens
    /// @param _underlyings Address of underlying tokens

    function addWrappedTokenInBatches(
        address[] memory _wrappedTokens,
        address[] memory _underlyings
    ) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        for (uint256 i = 0; i < _wrappedTokens.length; i++) {
            wrappedToUnderlying[address(_wrappedTokens[i])] = address(
                _underlyings[i]
            );
        }
    }

    function changeAPContract(address _apContract) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        apContract = _apContract;
    }

    /**
oneCTokenInUnderlying = exchangeRateCurrent / (1 * 10 ^ (18 + underlyingDecimals - cTokenDecimals))

 */
    function calcExchangePrice(address _token, address _underlying)
        internal
        view
        returns (uint256)
    {
        uint8 decimals;
        ICToken token = ICToken(_token);
        IERC20 underlying = IERC20(_underlying);
        if (_underlying == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            decimals = 18;
        else decimals = underlying.decimals();

        uint256 oneCTokenInUnderlying = ((token.exchangeRateStored()).mul(1e18))
            .div(10**(18 + decimals - token.decimals()));
        return oneCTokenInUnderlying;
    }
}