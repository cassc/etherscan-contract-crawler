pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {IBasketFacet} from "./Interfaces/IBasketFacet.sol";
import {ILendingRegistry} from "./Interfaces/ILendingRegistry.sol";
import {IChainLinkOracle} from "./Interfaces/IChainLinkOracle.sol";
import {IRETH} from "./Interfaces/IRETH.sol";
import {IWSTETH} from "./Interfaces/IWSTETH.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {ILendingLogic} from "./Interfaces/ILendingLogic.sol";
import {IERC20Metadata} from "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

contract BasketsPriceFeed is Ownable {
    IBasketFacet immutable basket;
    ILendingRegistry immutable lendingRegistry;
    IRETH public constant RETH = IRETH(0xae78736Cd615f374D3085123A210448E74Fc6393);
    IWSTETH public constant WSTETH = IWSTETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    uint8 public constant decimals = 18;
    mapping(address => IChainLinkOracle) public linkFeeds;

    constructor (address _basket, address _lendingRegistry) {
        basket = IBasketFacet(_basket);
        lendingRegistry = ILendingRegistry(_lendingRegistry);
    }

    /**
     * Function to retrieve the price of 1 basket token in USD, scaled by 1e18
     *
     * @return usdPrice Price of 1 basket token in USD
     */
    function latestAnswer() external view returns (uint256 usdPrice) {
        address[] memory components = basket.getTokens();

        uint256 marketCapUSD = 0;

        // Gather link prices, component balances, and basket market cap
        for (uint8 i = 0; i < components.length; i++) {
            address component = components[i];
            address underlying = lendingRegistry.wrappedToUnderlying(component);
            IERC20 componentToken = IERC20(component);
            IChainLinkOracle linkFeed;
            if (underlying != address(0)) { // Wrapped tokens
                ILendingLogic lendingLogic = ILendingLogic(lendingRegistry.protocolToLogic(lendingRegistry.wrappedToProtocol(component)));
                linkFeed = linkFeeds[underlying];
                marketCapUSD += (
                    fmul(fmul(componentToken.balanceOf(address(basket)), lendingLogic.exchangeRateView(component), 1 ether),
                    10 ** (36 - IERC20Metadata(address(componentToken)).decimals() - linkFeed.decimals()) * uint256(linkFeed.latestAnswer()),1 ether)
                );
            } else if (component == address(RETH)) { // rETH
                linkFeed = linkFeeds[component];
                marketCapUSD += (
                    fmul(fmul(componentToken.balanceOf(address(basket)), RETH.getExchangeRate(), 1 ether),
                    10 ** (36 - IERC20Metadata(address(componentToken)).decimals() - linkFeed.decimals()) * uint256(linkFeed.latestAnswer()),1 ether)
                );
            } else if (component == address(WSTETH)) { // wstETH
                linkFeed = linkFeeds[component];
                marketCapUSD += (
                    fmul(fmul(componentToken.balanceOf(address(basket)), WSTETH.stEthPerToken(), 1 ether),
                    10 ** (36 - IERC20Metadata(address(componentToken)).decimals() - linkFeed.decimals()) * uint256(linkFeed.latestAnswer()),1 ether)
                );
            } else { // Non-wrapped tokens
                linkFeed = linkFeeds[component];
                marketCapUSD += (
                    fmul(componentToken.balanceOf(address(basket)),10 ** (36 - IERC20Metadata(address(componentToken)).decimals() - linkFeed.decimals())  * uint256(linkFeed.latestAnswer()),1 ether)
                );
            }
        }
        usdPrice = fdiv(marketCapUSD, IERC20(address(basket)).totalSupply(), 1 ether);	
	return usdPrice;
    }

    function setTokenFeed(address _token, address _oracle) external onlyOwner {
        linkFeeds[_token] = IChainLinkOracle(_oracle);
    }

    function removeTokenFeed(address _token) external onlyOwner {
        delete linkFeeds[_token];
    }

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            if iszero(eq(div(mul(x,y),x),y)) {revert(0,0)}
            z := div(mul(x,y),baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            if iszero(eq(div(mul(x,baseUnit),x),baseUnit)) {revert(0,0)}
            z := div(mul(x,baseUnit),y)
        }
    }
}