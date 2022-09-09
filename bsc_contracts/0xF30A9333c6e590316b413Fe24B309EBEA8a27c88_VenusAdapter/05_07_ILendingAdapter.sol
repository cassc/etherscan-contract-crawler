// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDefiAdapter.sol";

struct MarketInfo {
    address platformToken;
    address asset;
    uint collateralFactor;
}

struct AccountDetailInfo {
    address platformToken;
    address asset;
    uint deposit;
    uint collateral;
    uint borrow;
    uint depositValue;
    uint borrowValue;
    bool listed;
    uint oraclePriceMantissa;
    uint exchangeRateMantissa;
}

interface ILendingAdapter is IDefiAdapter {
    function getMarket(address asset) external view returns(address platformToken);
    function getMarkets() external view returns(MarketInfo[] memory markets);
    function isCollateral(address account, address platformToken) external view returns(bool);
    function enableCollateral(address platformToken) external;
    function rewardTokens() external view returns(address[] memory);

    function collateralFactor(address platformToken) external view returns(uint);

    function priceUnderlying(address platformToken) external view returns(uint);
    /**
    @notice healthFactor is stored scale 1e18, and should be greater than 1.0
            otherwise, the account will be liquidated.
     */
    function accountInfo(address account) external view 
        returns(uint totalDeposit,
                uint totalCollateral, 
                uint totalBorrow, 
                uint healthFactor);
    function accountInfo(address account, address platformToken) external view 
        returns(uint depositToken, uint borrowToken);

    function rewardAccrued(address account) external view returns(uint);
    function accountDetailInfo(address account) external view returns(AccountDetailInfo[] memory) ;

    function deposit(address platformToken, uint amount) external;
    function withdraw(address platformToken, uint amount) external;
    function borrow(address platformToken, uint amount) external;
    function repay(address platformToken, uint amount) external;
    function harvestReward(address account) external;

    function getBorrowableToken(address account, address platformToken, uint expectedHealthFactor) external view returns(uint);
    function getWithdrawableToken(address account, address platformToken, uint expectedHealthFactor) external view returns(uint);
}