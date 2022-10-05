pragma solidity 0.8.13;

interface ICErc20 {
    function accrualBlockNumber() view external returns (uint256);
    function balanceOf(address owner) view external returns (uint256);
    function balanceOfUnderlying(address owner) external returns (uint256);
    function borrowRatePerBlock() view external returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() view external returns (uint256);
    function getCash() view external returns (uint256);
    function mint(uint256 mintAmount) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function reserveFactorMantissa() view external returns (uint256);
    function totalBorrows() view external returns (uint256);
    function totalReserves() view external returns (uint256);
    function totalSupply() view external returns (uint256);
    function underlying() view external returns (address);
}