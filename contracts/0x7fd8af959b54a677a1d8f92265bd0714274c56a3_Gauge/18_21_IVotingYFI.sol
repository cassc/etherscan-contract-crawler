// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVotingYFI is IERC20 {
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function totalSupply() external view returns (uint256);

    function locked(address _user) external view returns (LockedBalance memory);

    function modify_lock(
        uint256 _amount,
        uint256 _unlock_time,
        address _user
    ) external;
}