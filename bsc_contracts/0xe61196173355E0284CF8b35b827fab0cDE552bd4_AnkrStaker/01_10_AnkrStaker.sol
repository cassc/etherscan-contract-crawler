// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../Interfaces/IWombatBooster.sol";

interface IBaseRewardPoolLocked {
    function stakeFor(address, uint256) external;

    function setLock(address[] calldata, uint256[] calldata) external;
}

contract AnkrStaker is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Deposited(address indexed _user, uint256 _amount);

    function initialize() public initializer {
        __Ownable_init();
    }

    function depositFor(
        address _booster,
        uint256 _pid,
        address[] calldata _users,
        uint256[] calldata _amounts
    ) external {
        require(_booster != address(0), "invalid _booster");
        require(_users.length == _amounts.length, "invalid length");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount = totalAmount.add(_amounts[i]);
        }
        require(totalAmount > 0, "invalid _amounts");

        (
            address lptoken,
            address token,
            ,
            address rewardPool,

        ) = IWombatBooster(_booster).poolInfo(_pid);
        IERC20(lptoken).safeTransferFrom(
            msg.sender,
            address(this),
            totalAmount
        );

        for (uint256 i = 0; i < _users.length; i++) {
            address user = _users[i];
            uint256 amount = _amounts[i];
            require(user != address(0), "invalid user");
            require(amount > 0, "invalid amount");

            _approveTokenIfNeeded(lptoken, _booster, amount);
            IWombatBooster(_booster).deposit(_pid, amount, false);

            _approveTokenIfNeeded(token, rewardPool, amount);
            IBaseRewardPoolLocked(rewardPool).stakeFor(user, amount);

            emit Deposited(user, amount);
        }

        IBaseRewardPoolLocked(rewardPool).setLock(_users, _amounts);
    }

    function _approveTokenIfNeeded(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _to) < _amount) {
            IERC20(_token).safeApprove(_to, 0);
            IERC20(_token).safeApprove(_to, type(uint256).max);
        }
    }
}