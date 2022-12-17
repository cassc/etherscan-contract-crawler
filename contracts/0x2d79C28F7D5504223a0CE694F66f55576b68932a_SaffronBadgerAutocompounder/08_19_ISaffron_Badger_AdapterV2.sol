// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ISaffron_Badger_AdapterV2 {
    function set_pool(address pool) external;
    function deploy_capital(uint256 lp_amount) external returns(uint256);
    function return_capital(uint256 lp_amount, address to) external;
    function get_holdings() external returns(uint256);
    function set_lp(address addr) external;
    function propose_governance(address to) external;
    function accept_governance() external;
    function get_holdings_view() external view returns(uint256);
    function set_deposit_token(address addr) external;
}