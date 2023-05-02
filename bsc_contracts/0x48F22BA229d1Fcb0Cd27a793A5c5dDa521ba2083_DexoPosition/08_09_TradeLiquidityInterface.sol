// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface ITradeLiquidity{

    struct stakingInfo {
        uint amount;
        bool requested;
        uint releaseDate;
    }
    struct pairInfo {
        address base;
        address priceFeed;
        uint spread;            //1e8 precision
        uint chainlinkdecimals;
        uint pairMinLeverage;
        uint pairMaxLeverage;
        bool active;
    }

    function allowedTokens(address) external view returns(bool);    
    function lendingFeesDecimas() external view returns(uint);
    function quteTokenDecimals() external view returns(uint);
    function lendingFees(address) external view returns(uint);
    function tokenTotalStaked(address) external view returns(uint);    
    function totalLocked(address) external view returns(uint);    
    function quoteToken() external view returns(address);    
    
    function distribute(uint _reward,address _tokenAddr) external returns (bool);
    function addAdminFee(uint _amount)  external;
    function getRewardAmount(address _receiver) external returns (uint);
    function sendProfit(address _receiver,uint _amount) external;
    function sendPnl(address _receiver,uint _amount) external;

    function pairInfos(uint) external view returns(pairInfo memory);    
    function totalPairs() external view returns(uint);    
    function pairMinLeverage(uint pairIndex) external view returns(uint);
    function pairMaxLeverage(uint pairIndex) external view  returns(uint);
    function addTotalLocked(address _token,uint _amount) external ;
    function removeTotalLocked(address _token,uint _amount) external;

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path
    ) external  returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path
    ) external  returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);

}