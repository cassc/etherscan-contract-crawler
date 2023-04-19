// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVlQuoV2 {
    function quo() external view returns (IERC20);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function blockThirdPartyActions(address _user) external view returns (bool);

    function unlockGracePeriod() external view returns (uint256);

    function unlockPunishment() external view returns (uint256);

    function lock(
        address _user,
        uint256 _amount,
        uint256 _weeks
    ) external;

    function increaseBalance(address _user, uint256 _amount) external;

    function decreaseBalance(address _user, uint256 _amount) external;

    event Locked(address indexed _user, uint256 _amount, uint256 _weeks);

    event Unlocked(
        address indexed _user,
        uint256 _unlockTime,
        uint256 _quoAmount,
        uint256 _vlQuoAmount
    );

    event RewardTokenAdded(address indexed _rewardToken);

    event RewardAdded(address indexed _rewardToken, uint256 _reward);

    event RewardPaid(
        address indexed _user,
        address indexed _rewardToken,
        uint256 _reward
    );

    event AccessSet(address indexed _address, bool _status);

    event AllowedLockerSet(address indexed _locker, bool _allowed);

    event BalanceUpdated(address indexed _user, uint256 _balance);
}