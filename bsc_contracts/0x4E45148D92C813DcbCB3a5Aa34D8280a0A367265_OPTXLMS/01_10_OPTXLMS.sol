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
    
    IDEXRouter private commandSwapRouter;

    IDEXPair public commandBNBPair;
    IDEXPair public commandBUSDPair;

    address public optxAddress;
    address public busdAddress;
    address public commandBNBPairAddress;
    address public commandBUSDPairAddress;
    bool public lmsEnabled;

    uint256 public priceUpThreshold;
    uint256 public priceDownThreshold;
    uint256 public priceDecision;

    AggregatorV3Interface internal bnbPriceFeed;

    function initialize() external initializer {
        __Ownable_init();

        bnbPriceFeed = AggregatorV3Interface(
            0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        );
        
        OPTX = IERC20Upgradeable(0x894780893828c0516064Cb5804097033a871F6ff);
        BUSD = IERC20Upgradeable(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        commandSwapRouter = IDEXRouter(0x39255DA12f96Bb587c7ea7F22Eead8087b0a59ae);
        lmsEnabled = false;
    }

    receive() external payable {}

    function getBNBPrice() public view returns(int) {
        ( , int price, , , ) = bnbPriceFeed.latestRoundData();
        return price;
    }

    function shouldBNBPairTrade() external view returns(uint256, string memory, uint256) {

        int value = getBNBPrice();
        if(value <= 0) return (0, "Try it again", 0);
        
        uint256 bnbPrice = uint256(value);
        if(!lmsEnabled) return (0, "LMS is disabled", 0);
        
        (uint256 optxRes, uint256 bnbRes) = getPairReserves(commandBNBPairAddress);
        if(optxRes == 0 || bnbRes == 0) return (0, "Pair does not exist", 0);
        
        uint256 currentPrice = bnbRes * bnbPrice / optxRes / priceDecision;
        
        if(currentPrice >= priceDownThreshold && currentPrice <= priceUpThreshold) return (0, "Price is in our range", currentPrice);
        if(currentPrice > priceUpThreshold) {
            uint256 sellAmount = (bnbRes * bnbPrice / priceUpThreshold) - optxRes;
            return (sellAmount, "Price is out of Up Threshold", currentPrice);
        }
        if(currentPrice < priceDownThreshold) {
            uint256 buyAmount = optxRes - (bnbRes * bnbPrice / priceDownThreshold);
            return (buyAmount, "Price is down of Down Threshold", currentPrice);
        }
    }

    function shouldBUSDPairTrade() external view returns(uint256, string memory, uint256) {
        
        if(!lmsEnabled) return (0, "LMS is disabled", 0);
        
        (uint256 optxRes, uint256 bnbRes) = getPairReserves(commandBNBPairAddress);
        if(optxRes == 0 || bnbRes == 0) return (0, "Pair does not exist", 0);
        
        uint256 currentPrice = bnbRes  / optxRes / priceDecision;
        
        if(currentPrice >= priceDownThreshold && currentPrice <= priceUpThreshold) return (0, "Price is in our range", currentPrice);
        if(currentPrice > priceUpThreshold) {
            uint256 sellAmount = (bnbRes / priceUpThreshold) - optxRes;
            return (sellAmount, "Price is out of Up Threshold", currentPrice);
        }
        if(currentPrice < priceDownThreshold) {
            uint256 buyAmount = optxRes - (bnbRes / priceDownThreshold);
            return (buyAmount, "Price is down of Down Threshold", currentPrice);
        }
    }

    function getPairReserves(address _pairAddr) public view returns(uint256, uint256) {
        
        IDEXPair tokenPair = IDEXPair(_pairAddr);
        (uint256 res0, uint256 res1, ) = tokenPair.getReserves();
        
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

    function setIntialValues(uint256 _up, uint256 _down, uint256 _bnbNum, uint256 _num) external {
        priceUpThreshold   = _up;
        priceDownThreshold = _down;
        priceDecision = _num;
    }

    function setOptxAddress(address _addr) external {
        optxAddress = _addr;
    }

    function _swapBNBForTokens(uint256 _amount) private {
        address[] memory path = new address[](3);
        path[0] = commandSwapRouter.WETH();
        path[1] =optxAddress; 

        commandSwapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amount}(
            0, 
            path, 
            address(this), 
            block.timestamp
        );
    }

    function _swapBUSDForTokens(uint256 _amount) private {
        address[] memory path = new address[](3);
        path[0] = busdAddress;
        path[1] =optxAddress; 

        commandSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0, 
            path, 
            address(this), 
            block.timestamp
        );
    }

    function withdrawExactBNB(uint256 _amount) external onlyOwner {
        require(_amount * 10**18 <= address(this).balance, "Not enough BNB");
        payable(msg.sender).transfer(_amount);
    }

    function withdrawExactBUSD(uint256 _amount) external onlyOwner {
        uint256 busdBalance = BUSD.balanceOf(address(this));
        require(_amount * 10**18 <= busdBalance, "Not enough BUSD");
        bool success = BUSD.approve(msg.sender, _amount);
        require(success, "Approval of BUSD Amount Failed");
        BUSD.transfer(msg.sender, _amount);
    }

    function withdrawExactOptx(uint256 _amount) external onlyOwner {
        uint256 optxBalance = OPTX.balanceOf(address(this));
        require(_amount ** 10**18 <= optxBalance, "Not enough OPTX");
        bool success = OPTX.approve(msg.sender, _amount);
        require(success, "Approval of OPTX Amount Failed");
        OPTX.transfer(msg.sender, _amount);
    }

}