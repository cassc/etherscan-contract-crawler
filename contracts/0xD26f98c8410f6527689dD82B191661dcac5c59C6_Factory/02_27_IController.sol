// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IController {
    function create_loan(uint256 collateral, uint256 debt, uint256 N) external;
    function collateral_token() external view returns(address);
    function add_collateral(uint256 collateral, address user) external;
    function remove_collateral(uint256 collateral, bool use_eth) external;
    function borrow_more(uint256 collateral, uint256 debt) external;
    function repay(uint256 debt) external;
    function liquidate(address user, uint256 min_x) external;
    function amm_price() external view returns(uint256);
    function amm() external view returns(address);
    function health(address user, bool full) external view returns(int256);
    function max_borrowable(uint256 collateral, uint256 N) external view returns(uint256);
    function debt(address user) external view returns(uint256);
}