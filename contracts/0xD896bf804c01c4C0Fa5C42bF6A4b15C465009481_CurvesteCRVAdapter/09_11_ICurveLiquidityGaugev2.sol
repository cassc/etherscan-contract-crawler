// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface ICurveLiquidityGaugev2 {
    function decimals() external view returns (uint256);

    function integrate_checkpoint() external view returns (uint256);

    function user_checkpoint(address addr) external returns (bool);

    function claimable_tokens(address addr) external returns (uint256);

    function claimable_reward(address _addr, address _token)
        external
        returns (uint256);

    function claim_rewards() external;

    function claim_rewards(address _addr) external;

    function claim_historic_rewards(address[8] calldata _reward_tokens)
        external;

    function claim_historic_rewards(
        address[8] calldata _reward_tokens,
        address _addr
    ) external;

    function kick(address addr) external;

    function set_approve_deposit(address addr, bool can_deposit) external;

    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address _addr) external;

    function withdraw(uint256 _value) external;

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function increaseAllowance(address _spender, uint256 _added_value)
        external
        returns (bool);

    function decreaseAllowance(address _spender, uint256 _subtracted_value)
        external
        returns (bool);

    function set_rewards(
        address _reward_contract,
        bytes32 _sigs,
        address[8] calldata _reward_tokens
    ) external;

    function set_killed(bool _is_killed) external;

    function commit_transfer_ownership(address addr) external;

    function accept_transfer_ownership() external;

    function minter() external view returns (address);

    function crv_token() external view returns (address);

    function lp_token() external view returns (address);

    function controller() external view returns (address);

    function voting_escrow() external view returns (address);

    function future_epoch_time() external view returns (uint256);

    function balanceOf(address arg0) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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

    function reward_contract() external view returns (address);

    function reward_tokens(uint256 arg0) external view returns (address);

    function reward_integral(address arg0) external view returns (uint256);

    function reward_integral_for(address arg0, address arg1)
        external
        view
        returns (uint256);

    function admin() external view returns (address);

    function future_admin() external view returns (address);

    function is_killed() external view returns (bool);
}