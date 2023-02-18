// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import './interfaces/IDEXRouter.sol';
import './interfaces/IDEXFactory.sol';
import './interfaces/IDEXPair.sol';

contract OPTXLMS is OwnableUpgradeable {

    address public devAccount;
    IERC20Upgradeable OPTX;
    IERC20Upgradeable BUSD;

    IDEXRouter private commandSwapRouter;

    address public optxAddress;
    address public busdAddress;
    address public commandBNBPairAddress;
    address public commandBUSDPairAddress;
    bool public lmsEnabled;

    uint256 public priceUpThreshold;
    uint256 public priceDownThreshold;
    uint256 public priceDecThreshold;

    AggregatorV3Interface internal bnbPriceFeed;

    function initialize() external initializer {
        __Ownable_init();
        
        devAccount = 0x372B95Ac394F7dbdDc90f7a07551fb75509346A8;

        bnbPriceFeed = AggregatorV3Interface(
            0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        );
        
        optxAddress = 0x4Ef0F0f98326830d823F28174579C39592cDB367;
        busdAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

        OPTX = IERC20Upgradeable(optxAddress);
        BUSD = IERC20Upgradeable(busdAddress);

        commandSwapRouter = IDEXRouter(0x39255DA12f96Bb587c7ea7F22Eead8087b0a59ae);
        commandBNBPairAddress = 0xaD8833Ba01E84A27F39A8c411fDdf9bCB0D051d8;
        commandBUSDPairAddress = 0x894780893828c0516064Cb5804097033a871F6ff;

        priceDownThreshold = 30000000;
        priceUpThreshold = 40000000;
        priceDecThreshold = 10000;
        lmsEnabled = true;
    }

    receive() external payable {}

    modifier onlyDev {
        require(_msgSender() == devAccount, "Not developer");
        _;
    }

    function getBNBPrice() public view returns(int) {
        (
            ,
            int256 answer,
            ,
            ,
            
        ) = bnbPriceFeed.latestRoundData();
        return answer;
    }
    
    function canBNBPairLMS() external view returns(uint256, uint256, uint256, uint256, uint256){
        
        uint256 bnbPrice = uint256(getBNBPrice());
        (uint256 optxRes, uint256 bnbRes) = getPairReserves(commandBNBPairAddress);
        uint256 nowPrice = bnbRes * bnbPrice / optxRes ;
        
        uint256 optxResBuy = bnbRes * bnbPrice / priceDownThreshold;
        uint256 optxResSell = bnbRes * bnbPrice / priceUpThreshold;

        if(optxRes > optxResBuy) {
            return (
                nowPrice, 
                (optxRes - optxResBuy)*priceDownThreshold/bnbPrice, 
                0, 
                optxRes, 
                bnbRes
            );
        }

        if(optxRes < optxResSell) {
            return (
                nowPrice, 
                0, 
                optxResSell - optxRes, 
                optxRes, 
                bnbRes
            );
        }

        return (nowPrice, 0, 0, optxRes, bnbRes);
    }

    function canBUSDPairLMS() external view returns(uint256, uint256, uint256, uint256, uint256) {
        
        (uint256 optxRes, uint256 busdRes) = getPairReserves(commandBUSDPairAddress);
        uint256 nowPrice = busdRes * 10**8 / optxRes;

        uint256 optxResBuy = busdRes * 10**8 / priceDownThreshold;
        uint256 optxResSell = busdRes * 10**8 / priceUpThreshold;

        if(optxRes > optxResBuy) {
            return (
                nowPrice,
                (optxRes - optxResBuy) * priceDownThreshold / 10**8,
                0,
                optxRes,
                busdRes
            );
        }

        if(optxRes < optxResSell) {
            return (
                nowPrice,
                0,
                optxResSell - optxRes,
                optxRes,
                busdRes
            );
        }

        return ( nowPrice, 0, 0, optxRes, busdRes );
    }

    function executeBNBLMS() external onlyDev returns(uint256){

        uint256 bnbPrice = uint256(getBNBPrice());
        (uint256 optxRes, uint256 bnbRes) = getPairReserves(commandBNBPairAddress);
        uint256 nowPrice = bnbRes * bnbPrice / optxRes ;

        require(
        (
            lmsEnabled && 
            bnbPrice > 0 && 
            optxRes > 0 && 
            bnbRes > 0 &&
            (nowPrice + priceDecThreshold < priceDownThreshold ||
            nowPrice - priceDecThreshold > priceUpThreshold)
        ), "LMS could not be started");
        
        if(nowPrice + priceDecThreshold < priceDownThreshold) {
            uint256 optxResBuy = bnbRes * bnbPrice / priceDownThreshold;
            require(optxRes > optxResBuy && address(this).balance > (optxRes - optxResBuy) * priceDownThreshold / bnbPrice, "Not enough BNB");

            uint256 buyAmount = (optxRes - optxResBuy) * priceDownThreshold / bnbPrice;
            emit BnbPairLMS(true, buyAmount);
            _swapBNBForTokens(buyAmount);
            return buyAmount;
        }

        if(nowPrice - priceDecThreshold > priceUpThreshold) {
            uint256 optxResSell = bnbRes * bnbPrice / priceUpThreshold;
            require(optxRes < optxResSell && OPTX.balanceOf(address(this)) > (optxResSell - optxRes), "Not enough OPTX");
            
            uint256 sellAmount = optxResSell - optxRes;
            emit BnbPairLMS(false, sellAmount);
            _swapTokensForBNB(sellAmount);
            return sellAmount;
        }

        return 0;
    }

    function executeBUSDLMS() external onlyDev returns(uint256){

        (uint256 optxRes, uint256 busdRes) = getPairReserves(commandBUSDPairAddress);
        uint256 nowPrice = busdRes * 10**8 / optxRes ;

        require(
        (
            lmsEnabled && 
            optxRes > 0 && 
            busdRes > 0 &&
            (nowPrice + priceDecThreshold < priceDownThreshold ||
            nowPrice - priceDecThreshold > priceUpThreshold)
        ), "LMS could not be started");
        
        if(nowPrice + priceDecThreshold < priceDownThreshold) {
            uint256 optxResBuy = busdRes * 10**8 / priceDownThreshold;
            require(optxRes > optxResBuy && BUSD.balanceOf(address(this)) > (optxRes - optxResBuy) * priceDownThreshold / 10 ** 8, "Not enough BUSD");

            uint256 buyAmount = (optxRes - optxResBuy) * priceDownThreshold / 10 ** 8;
            emit BusdPairLMS(true, buyAmount);
            _swapBUSDForTokens(buyAmount);
            return buyAmount;
        }

        if(nowPrice - priceDecThreshold > priceUpThreshold) {
            uint256 optxResSell = busdRes * 10**8 / priceUpThreshold;
            require(optxRes < optxResSell && OPTX.balanceOf(address(this)) > (optxResSell - optxRes), "Not enough OPTX");
            
            uint256 sellAmount = optxResSell - optxRes;
            emit BusdPairLMS(false, sellAmount);
            _swapTokensForBUSD(sellAmount);
            return sellAmount;
        }

        return 0;
    }

    function getPairReserves(address _pairAddr) public view returns(uint256, uint256) {
        
        IDEXPair tokenPair = IDEXPair(_pairAddr);
        (uint256 res0, uint256 res1, ) = tokenPair.getReserves();
        
        uint256 optxReserve = res1;
        uint256 nativeReserve  = res0;

        address token0 = tokenPair.token0();
        if(token0 == optxAddress) {
            optxReserve = res0;
            nativeReserve  = res1;
        }

        return (optxReserve, nativeReserve);
    }

    function setLMSEnabled(bool _enable) external onlyOwner{
        lmsEnabled = _enable;
    }

    function setCommandPairs(address _bnbPairAddr, address _busdPairAddr) external onlyOwner{
        commandBNBPairAddress  = _bnbPairAddr;
        commandBUSDPairAddress = _busdPairAddr;
    }

    function setIntialValues(uint256 _up, uint256 _down, uint256 _dec) external onlyOwner{
        priceUpThreshold   = _up;
        priceDownThreshold = _down;
        priceDecThreshold = _dec;
    }

    function setDevAccount(address _addr) external onlyDev {
        devAccount = _addr;
    }

    function _swapBNBForTokens(uint256 _amount) private {
        address[] memory path = new address[](2);
        path[0] = commandSwapRouter.WETH();
        path[1] = optxAddress; 
        
        commandSwapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amount}(
            0, 
            path, 
            address(this), 
            block.timestamp
        );
    }

    function _swapBUSDForTokens(uint256 _amount) private {
        address[] memory path = new address[](2);
        path[0] = busdAddress;
        path[1] = optxAddress; 

        bool success = BUSD.approve(address(commandSwapRouter), _amount);
        require(success, "Approval of Token Amount failed");
        commandSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0, 
            path, 
            address(this), 
            block.timestamp
        );
    }

    function _swapTokensForBNB(
        uint256 _amount
    ) private {
        address[] memory path = new address[](2);
        path[0] = optxAddress;
        path[1] = commandSwapRouter.WETH();

        bool success = OPTX.approve(
            address(commandSwapRouter),
            _amount
        );

        require(success, "Approval of TOKEN amount failed");
        commandSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount, 
            0, 
            path, 
            address(this), 
            block.timestamp
        );
    }

    function _swapTokensForBUSD(
        uint256 _amount
    ) private {
        address[] memory path = new address[](2);
        path[0] = optxAddress;
        path[1] = busdAddress;

        bool success = OPTX.approve(
            address(commandSwapRouter),
            _amount
        );

        require(success, "Approval of TOKEN amount failed");
        commandSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount, 
            0, 
            path, 
            address(this), 
            block.timestamp
        );
    }

    function withdrawExactBNB(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Not enough BNB");
        payable(msg.sender).transfer(_amount);
    }

    function withdrawExactBUSD(uint256 _amount) external onlyOwner {
        uint256 busdBalance = BUSD.balanceOf(address(this));
        require(_amount <= busdBalance, "Not enough BUSD");
        BUSD.transfer(msg.sender, _amount);
    }

    function withdrawExactOptx(uint256 _amount) external onlyOwner {
        uint256 optxBalance = OPTX.balanceOf(address(this));
        require(_amount <= optxBalance, "Not enough OPTX");
        OPTX.transfer(msg.sender, _amount);
    }

    function showBNBAddress() external view returns(address) {
        return busdAddress;
    }

    function showOPTXAddress() external view returns(address) {
        return optxAddress;
    }

    event BnbPairLMS(bool flag, uint256 amount);
    event BusdPairLMS(bool flag, uint256 amount);
}