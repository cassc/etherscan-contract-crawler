// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
contract aLGP is ERC20Votes {
    struct UserInfo {
        bool isExist;
        uint256 amount;
        uint256 rewardDebt;
        uint256 balance;
        uint256 rewardTotal;
    }
    struct RankInfo {
        address owner;
        uint256 amount;
    }
    mapping(address => UserInfo) public users;
    mapping(uint256 => address) public userAdds;
    uint256 public userTotal;
    mapping(uint256 => RankInfo) public ranks;
    uint256 public rankTotal;
    uint256 public totalStakeLGP;
    uint256 private _rewardPerLP;
    uint256 private _lastBalance;
    uint256 private _rewardTotal;
    uint256 private _withdrawTotal;
    address public manager;
    IERC20 private _LGP;
    constructor() ERC20("aLGP", "aLGP") ERC20Permit("aLGP") {
        manager = 0x1Df6Bcef949B52192D04923d59e630f7F5ca5E88;
        _LGP = IERC20(0x496EaBf0571eFecbD4e8BBcf47EdA7144972f25e);
    }
    event Deposit(address account, uint256 amount);
    event Relieve(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    function setManager(address account) public {
        if (manager == _msgSender()) {
            manager = account;
        }
    }
    function setLGP(address lgp) public {
        if (manager == _msgSender()) {
            _LGP = IERC20(lgp);
        }
    }
    function getParams()
        public
        view
        returns (
            uint256 rewardPerLP,
            uint256 lastBalance,
            uint256 rewardTotal,
            uint256 withdrawTotal
        )
    {
        rewardPerLP = _rewardPerLP;
        lastBalance = _lastBalance;
        rewardTotal = _rewardTotal;
        withdrawTotal = _withdrawTotal;
    }
    function getRanks() public view returns (RankInfo[] memory infos) {
        infos = new RankInfo[](rankTotal);
        for (uint256 i = 0; i < rankTotal; i++) {
            infos[i] = ranks[i + 1];
        }
    }
    function checkStaker(address account) public view returns (bool) {
        for (uint256 i; i < rankTotal; i++) {
            if (i < 50 && ranks[i + 1].owner == account) {
                return true;
            }
        }
        return false;
    }
    function getUserPending(address account) external view returns (uint256) {
        UserInfo memory user = users[account];
        uint256 accCakePerShare = _rewardPerLP;
        if (_LGP.balanceOf(address(this)) > _lastBalance) {
            uint256 balance = _LGP.balanceOf(address(this)) - _lastBalance;
            if (totalStakeLGP == 0) accCakePerShare += (balance * 1e12);
            else accCakePerShare += (balance * 1e12) / totalStakeLGP;
        }
        uint256 pending = ((user.amount * accCakePerShare) / 1e12) -
            user.rewardDebt;
        return pending + user.balance;
    }
    function getUserReward(address account) external view returns (uint256) {
        UserInfo memory user = users[account];
        uint256 accCakePerShare = _rewardPerLP;
        if (_LGP.balanceOf(address(this)) > _lastBalance) {
            uint256 balance = _LGP.balanceOf(address(this)) - _lastBalance;
            if (totalStakeLGP == 0) accCakePerShare += (balance * 1e12);
            else accCakePerShare += (balance * 1e12) / totalStakeLGP;
        }
        uint256 pending = ((user.amount * accCakePerShare) / 1e12) -
            user.rewardDebt;
        return pending + user.rewardTotal;
    }
    function deposit(uint256 amount) public {
        address account = msg.sender;
        require(amount > 0, "amount cann't zero");
        require(_LGP.balanceOf(account) >= amount, "Insufficient LP");
        _updatePool();
        UserInfo storage user = users[account];
        if (!user.isExist) {
            user.isExist = true;
            userTotal += 1;
            userAdds[userTotal] = account;
        }
        if (user.amount > 0) {
            uint256 pending = ((user.amount * _rewardPerLP) / 1e12) -
                user.rewardDebt;
            if (pending > 0) {
                user.balance += pending;
                user.rewardTotal += pending;
            }
        }
        _LGP.transferFrom(account, address(this), amount);
        user.amount += amount;
        totalStakeLGP += amount;
        user.rewardDebt = (user.amount * _rewardPerLP) / 1e12;
        _lastBalance = _LGP.balanceOf(address(this));
        _mint(account, amount);
        emit Deposit(account, amount);
        _updateOpenRank(account, user.amount);
    }
    function relieve(uint256 amount) public {
        require(amount > 0, "amount cann't zero");
        address account = msg.sender;
        UserInfo storage user = users[account];
        require(user.amount >= amount, "Insufficient LP");
        require(balanceOf(account) >= amount, "Insufficient aLGP");
        _updatePool();
        if (user.amount > 0) {
            uint256 pending = ((user.amount * _rewardPerLP) / 1e12) -
                user.rewardDebt;
            if (pending > 0) {
                user.balance += pending;
                user.rewardTotal += pending;
            }
        }
        _LGP.transfer(account, amount);
        user.amount -= amount;
        user.rewardDebt = (user.amount * _rewardPerLP) / 1e12;
        if (totalStakeLGP >= amount) totalStakeLGP -= amount;
        else totalStakeLGP = 0;
        _lastBalance = _LGP.balanceOf(address(this));
        _burn(account, amount);
        emit Relieve(account, amount);
        _updateOpenRank(account, user.amount);
    }
    function withdraw() public {
        UserInfo storage user = users[msg.sender];
        _updatePool();
        if (user.amount > 0) {
            uint256 pending = ((user.amount * _rewardPerLP) / 1e12) -
                user.rewardDebt;
            if (pending > 0) {
                user.balance += pending;
                user.rewardTotal += pending;
            }
            user.rewardDebt = (user.amount * _rewardPerLP) / 1e12;
        }
        if (user.balance > 0) {
            _LGP.transfer(msg.sender, user.balance);
            emit Withdraw(msg.sender, user.balance);
            _withdrawTotal += user.balance;
            user.balance = 0;
            _lastBalance = _LGP.balanceOf(address(this));
        }
    }
    function _updatePool() private {
        if (_LGP.balanceOf(address(this)) > _lastBalance) {
            uint256 balance = _LGP.balanceOf(address(this)) - _lastBalance;
            _lastBalance = _LGP.balanceOf(address(this));
            _rewardTotal += balance;
            if (totalStakeLGP == 0) _rewardPerLP += (balance * 1e12);
            else _rewardPerLP += (balance * 1e12) / totalStakeLGP;
        }
    }
    function _updateOpenRank(address account, uint256 amount) private {
        if (rankTotal == 0) {
            rankTotal = 1;
            ranks[1] = RankInfo({owner: account, amount: amount});
            return;
        }
        bool isExist;
        uint256 rankNumOld = 10000;
        for (uint256 i = 0; i < rankTotal; i++) {
            if (ranks[i + 1].owner == account) {
                isExist = true;
                rankNumOld = i + 1;
                break;
            }
        }
        uint256 rankNum = 10000;
        for (uint256 i = 0; i < rankTotal; i++) {
            if (ranks[i + 1].amount < amount) {
                rankNum = i + 1;
                break;
            }
        }
        if (rankTotal < 55 && !isExist) {
            rankTotal++;
            ranks[rankTotal] = RankInfo({owner: account, amount: amount});
        }
        if (rankNum < 56) {
            for (uint256 i = rankTotal; i >= rankNum; i--) {
                if (rankNum == i) {
                    ranks[i] = RankInfo({owner: account, amount: amount});
                    break;
                } else if (!isExist || (isExist && i <= rankNumOld)) {
                    ranks[i] = ranks[i - 1];
                }
            }
        }
    }
}