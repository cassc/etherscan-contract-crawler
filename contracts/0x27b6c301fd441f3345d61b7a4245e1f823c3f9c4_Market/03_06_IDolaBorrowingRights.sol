pragma solidity ^0.8.13;
import "src/interfaces/IERC20.sol";

interface IDolaBorrowingRights is IMintableERC20{
    //Variables
    function totalDueTokensAccrued() external view returns(uint);
    function replenishmentPriceBps() external view returns(uint);
    //Mappings
    function markets(address market) external view returns(bool);
    function debts(address borrower) external view returns(uint);
    function dueTokensAccrued(address borrower) external view returns(uint);
    function lastUpdated(address borrower) external view returns(uint);
    //Functions
    function allowMarket(address market) external;
    function deficitOf(address borrower) external view returns(uint);
    function signedBalanceOf(address borrower) external view returns(int);
    function accrueDueTokens(address borrower) external;
    function onBorrow(address borrower, uint additionalDebt) external;
    function onRepay(address user, uint repaidDebt) external;
    function onForceReplenish(address user, address replenisher, uint amount, uint replenisherReward) external;
    function burn(uint amount) external;
}