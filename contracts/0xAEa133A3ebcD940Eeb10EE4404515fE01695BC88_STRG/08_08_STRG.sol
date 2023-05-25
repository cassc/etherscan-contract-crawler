// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../interfaces/ITrg.sol";

contract STRG is ERC20, ERC20Burnable, Ownable {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    uint256 private _dividendPerToken;
    uint256 public totalStaked;
    address public trg;

    mapping(address => uint256) private _xDividendPerToken;
    mapping(address => UserInfo) public userInfo;

    error NotEnoughBalance();
    error NotEnoughDeposit();
    error NotEnoughRewards();
    error NonTransferableToken();

    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _trg) ERC20("sTRG", "sTRG") {
        trg = _trg;
    }

    function deposit(uint256 _amount) public {
        if (IERC20(trg).balanceOf(msg.sender) < _amount)
            revert NotEnoughBalance();

        UserInfo storage user = userInfo[msg.sender];

        if (user.amount > 0) {
            uint256 userReward = pendingRewards(msg.sender);
            if (userReward > 0) {
                IERC20(trg).transfer(msg.sender, userReward);
                user.rewardDebt += userReward;
            }
        }
        IERC20(trg).transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);

        user.amount += _amount;
        totalStaked += _amount;
        _xDividendPerToken[msg.sender] = dividendPerToken();

        emit Deposit(msg.sender, _amount);
    }

    function pendingRewards(address _user)
        public
        view
        returns (uint256 reward)
    {
        UserInfo storage user = userInfo[_user];

        if (user.amount == 0) return 0;
        reward =
            ((dividendPerToken() - _xDividendPerToken[_user]) * user.amount) /
            1e18;
    }

    function claimReward() public {
        UserInfo storage user = userInfo[msg.sender];
        uint256 userReward = pendingRewards(msg.sender);

        if (userReward == 0) revert NotEnoughRewards();

        IERC20(trg).transfer(msg.sender, userReward);

        user.rewardDebt += userReward;
        _xDividendPerToken[msg.sender] = dividendPerToken();
    }

    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];

        if (user.amount < _amount) revert NotEnoughDeposit();

        uint256 userReward = pendingRewards(msg.sender);

        IERC20(trg).transfer(msg.sender, _amount + userReward);
        _burn(msg.sender, _amount);

        user.amount -= _amount;
        user.rewardDebt += userReward;
        totalStaked -= _amount;
        _xDividendPerToken[msg.sender] = dividendPerToken();

        emit Withdraw(msg.sender, _amount);
    }

    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];

        if (user.amount == 0) revert NotEnoughDeposit();

        totalStaked -= user.amount;

        uint256 userReward = pendingRewards(msg.sender);
        if (userReward > 0)
            _dividendPerToken += (userReward * 1e18) / totalStaked;

        IERC20(trg).transfer(msg.sender, user.amount);
        _burn(msg.sender, user.amount);

        emit EmergencyWithdraw(msg.sender, user.amount);

        user.amount = 0;
        user.rewardDebt = 0;
    }

    function dividendPerToken() public view returns (uint256) {
        return _dividendPerToken + ITrg(trg).dividendPerToken();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == address(0) || to == address(0)) {
            super._beforeTokenTransfer(from, to, amount);
        } else {
            revert NonTransferableToken();
        }
    }
}