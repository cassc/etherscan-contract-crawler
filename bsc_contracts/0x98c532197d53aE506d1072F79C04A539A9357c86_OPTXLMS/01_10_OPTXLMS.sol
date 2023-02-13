// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import './interfaces/IDEXRouter.sol';
import './interfaces/IDEXFactory.sol';
import './interfaces/IDEXPair.sol';

contract OPTXLMS is OwnableUpgradeable {

    IERC20Upgradeable OPTX;
    IERC20Upgradeable BUSD;
    IDEXRouter public commandSwapRouter;
    IDEXRouter public pancakeSwapRouter;
    IDEXPair public commandBNBPair;
    IDEXPair public commandBUSDPair;
    IDEXPair public pancakeBNBPair;
    IDEXPair public pancakeBUSDPair;

    address public optxAddress;
    address public busdAddress;
    address public commandBNBPairAddress;
    address public commandBUSDPairAddress;
    address public pancakeBNBPairAddress;
    address public pancakeBUSDPairAddress;
    bool public lmsEnabled;

    uint256 public priceUpThreshold;
    uint256 public priceDownThreshold;
    uint256 public priceBNBDecision;
    uint256 public priceDecision;

    AggregatorV3Interface internal bnbPriceFeed;
    uint256 public currentPrice;
    uint256 public buyAmount;

    function initialize() external initializer {
        __Ownable_init();

        bnbPriceFeed = AggregatorV3Interface(
            0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        );
        
        // OPTX = IERC20Upgradeable(0x4Ef0F0f98326830d823F28174579C39592cDB367);
        // BUSD = IERC20Upgradeable(0x4Ef0F0f98326830d823F28174579C39592cDB367);
        // commandSwapRouter = IDEXRouter(0x39255DA12f96Bb587c7ea7F22Eead8087b0a59ae);

        // lmsEnabled = false;
    }

    function getBNBPrice() public view returns(int) {
        ( , int price, , , ) = bnbPriceFeed.latestRoundData();
        return price;
    }

    function executeCommandBNBPairLMS() external returns(string memory) {

        int value = getBNBPrice();
        if(value <= 0) return "Try it again";
        uint256 bnbPrice = uint256(value);
        
        if(!lmsEnabled) return "LMS is disabled";
        (uint256 optxRes, uint256 bnbRes) = getPairReserves(commandBNBPairAddress);
        if(optxRes == 0 || bnbRes == 0) return "Pair does not exist";
        
        currentPrice = bnbRes * bnbPrice / optxRes / priceDecision;
        buyAmount = optxRes * bnbRes / (priceDownThreshold + 100);
        if(currentPrice >= priceDownThreshold && currentPrice <= priceUpThreshold) return "Price is in our range";
        if(currentPrice > priceUpThreshold) {
            return "Price is out of Up Threshold";
        }
        if(currentPrice < priceDownThreshold) {
            return "Price is down of Down Threshold";
        }
    }

    function executeCommandBUSDPairLMS() external returns(string memory) {
        
        if(!lmsEnabled) return "LMS is disabled";
        (uint256 optxRes, uint256 busdRes) = getPairReserves(commandBUSDPairAddress);
        if(optxRes == 0 || busdRes == 0) return "Pair does not exist";
        
        currentPrice = busdRes * priceDecision / optxRes;
        buyAmount = optxRes * busdRes / (priceDownThreshold + 100);
        if(currentPrice >= priceDownThreshold && currentPrice <= priceUpThreshold) return "Price is in our range";
        if(currentPrice > priceUpThreshold) {
            return "Price is out of Up Threshold";
        }
        if(currentPrice < priceDownThreshold) {
            return "Price is down of Down Threshold";
        }
    }

    function executePancakeBNBPairLMS() external returns(string memory) {

    }

    function executePancakeBUSDPairLMS() external returns(string memory) {
        
    }

    function getPairReserves(address _pairAddr) public view returns(uint256, uint256) {
        
        IDEXPair optxPair = IDEXPair(_pairAddr);
        (uint256 res0, uint256 res1, ) = optxPair.getReserves();
        
        uint256 optxReserve = res1;
        uint256 nativeReserve  = res0;

        address token0 = commandBNBPair.token0();
        if(token0 == optxAddress) {
            optxReserve = res0;
            nativeReserve  = res1;
        }

        return (optxReserve, nativeReserve);
    }

    function setLMSEnabled(bool _enable) external {
        lmsEnabled = _enable;
    }

    function setCommandPairs(address _bnbPairAddr, address _busdPairAddr) external {
        commandBNBPair  = IDEXPair(_bnbPairAddr);
        commandBUSDPair = IDEXPair(_busdPairAddr);
        commandBNBPairAddress  = _bnbPairAddr;
        commandBUSDPairAddress = _busdPairAddr;
    }

    function setPancakePairs(address _bnbPairAddr, address _busdPairAddr) external {
        pancakeBNBPair  = IDEXPair(_bnbPairAddr);
        pancakeBUSDPair = IDEXPair(_busdPairAddr);
        pancakeBNBPairAddress  = _bnbPairAddr;
        pancakeBUSDPairAddress = _busdPairAddr;
    }

    function setIntialValues(uint256 _up, uint256 _down, uint256 _bnbNum, uint256 _num) external {
        priceUpThreshold   = _up;
        priceDownThreshold = _down;
        priceBNBDecision = _bnbNum;
        priceDecision = _num;
    }

    function setOptxAddress(address _addr) external {
        optxAddress = _addr;
    }

}