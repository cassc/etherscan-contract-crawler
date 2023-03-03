// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IVeFPIS {
    struct LockedBalance {
        uint256 amount;
        uint256 end;
    }

    function balanceOf(address addr) external view returns (uint256);

    function create_lock(uint256 _value, uint256 _unlock_time) external;

    function increase_amount(uint256 _value) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function locked(address) external view returns (LockedBalance memory);

    function withdraw() external;

    function smart_wallet_checker() external returns(address);

    function stakerSetProxy(address _proxy) external;
}