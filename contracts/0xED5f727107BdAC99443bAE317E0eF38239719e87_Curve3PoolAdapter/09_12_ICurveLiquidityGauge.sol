// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface ICurveLiquidityGauge {
    function user_checkpoint(address addr) external returns (bool);

    function claimable_tokens(address addr) external returns (uint256);

    function kick(address addr) external;

    function set_approve_deposit(address addr, bool can_deposit) external;

    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address addr) external;

    function withdraw(uint256 _value) external;

    function integrate_checkpoint() external view returns (uint256);

    function minter() external view returns (address);

    function crv_token() external view returns (address);

    function lp_token() external view returns (address);

    function controller() external view returns (address);

    function voting_escrow() external view returns (address);

    function balanceOf(address arg0) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function future_epoch_time() external view returns (uint256);

    function approved_to_deposit(address arg0, address arg1)
        external
        view
        returns (bool);

    function working_balances(address arg0) external view returns (uint256);

    function working_supply() external view returns (uint256);

    function period() external view returns (int128);

    function period_timestamp(uint256 arg0) external view returns (uint256);

    function integrate_inv_supply(uint256 arg0) external view returns (uint256);

    function integrate_inv_supply_of(address arg0)
        external
        view
        returns (uint256);

    function integrate_checkpoint_of(address arg0)
        external
        view
        returns (uint256);

    function integrate_fraction(address arg0) external view returns (uint256);

    function inflation_rate() external view returns (uint256);
}