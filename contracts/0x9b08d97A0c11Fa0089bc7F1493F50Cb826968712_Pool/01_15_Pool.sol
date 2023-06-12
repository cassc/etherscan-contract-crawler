// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./utils/SafeERC20.sol";
import "./utils/IERC20.sol";
import "./utils/Ownable.sol";
import "./utils/SafeMath.sol";
import "./Invite.sol";
import "./Token.sol";

contract Pool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    mapping(address => bool) public isBlackList;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 rewardTotal;
    }

    struct PoolInfo {
        IERC20 rewardToken;
        uint256 startBlock;
        uint256 bonusEndBlock;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        uint256 rewardPerBlock;
        uint256 totalReward;
        uint256 lpSupply;
    }

    uint256 public constant BONUS_MULTIPLIER = 1;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    Invite public invite;
    uint256 public inviteRate;

    constructor(
        IERC20 _rewardToken,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _rewardPerBlock,
        address _invite
    ) {
        inviteRate = 10;
        invite = Invite(_invite);
        require(
            _startBlock >= block.number,
            "startBlock must be in the future"
        );
        require(
            _bonusEndBlock >= _startBlock,
            "bonusEndBlock must be greater than startBlock"
        );
        uint256 lastRewardBlock = block.number > _startBlock
            ? block.number
            : _startBlock;
        poolInfo.push(
            PoolInfo({
                rewardToken: _rewardToken,
                startBlock: _startBlock,
                bonusEndBlock: _bonusEndBlock,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0,
                rewardPerBlock: _rewardPerBlock,
                totalReward: 0,
                lpSupply: 0
            })
        );
    }

    function setBlackList(address _address, bool _excluded) public onlyOwner {
        isBlackList[_address] = _excluded;
    }

    function setBlackLists(
        address[] memory _address,
        bool _excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            isBlackList[_address[i]] = _excluded;
        }
    }

    function setInviteRate(uint256 _rate) public onlyOwner {
        inviteRate = _rate;
    }

    function setAddress(address _invite) public onlyOwner {
        invite = Invite(_invite);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function editPool(
        address _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _bonusEndBlock
    ) public onlyOwner {
        updatePool(0);
        poolInfo[0].rewardToken = IERC20(_rewardToken);
        poolInfo[0].rewardPerBlock = _rewardPerBlock;
        poolInfo[0].bonusEndBlock = _bonusEndBlock;
    }

    function getMultiplier(
        uint256 _from,
        uint256 _to,
        uint256 _pid
    ) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        if (_to <= pool.bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= pool.bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                pool.bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(pool.bonusEndBlock)
                );
        }
    }

    function pendingInfo(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpSupply;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number,
                _pid
            );
            uint256 reward = multiplier.mul(pool.rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(
                reward.mul(1e12).div(lpSupply)
            );
        }
        return
            user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpSupply;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(
            pool.lastRewardBlock,
            block.number,
            _pid
        );

        uint256 reward = multiplier.mul(pool.rewardPerBlock);

        pool.accRewardPerShare = pool.accRewardPerShare.add(
            reward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    function mint(address _parent) public {
        if (
            _parent != address(0) &&
            Invite(invite).parents(_msgSender()) == address(0)
        ) {
            Invite(invite).setParentBySettingRole(_msgSender(), _parent);
        }

        uint256 _pid = 0;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        require(user.amount == 0, "minted");

        user.amount = user.amount.add(1 * 10 ** 18);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        pool.lpSupply = pool.lpSupply.add(1 * 10 ** 18);
    }

    function claim() public {
        uint256 _pid = 0;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        address payable token = payable(address(pool.rewardToken));
        require(!isBlackList[msg.sender], "blacklist");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(
            user.rewardDebt
        );

        user.rewardTotal = user.rewardTotal.add(pending);
        pool.totalReward = pool.totalReward.add(pending);

        uint256 inviteAmount = pending.mul(inviteRate).div(100);
        uint256 rewardAmount = pending.sub(inviteAmount);

        pool.rewardToken.safeTransfer(msg.sender, rewardAmount);
        pool.rewardToken.safeTransfer(
            invite.getParent(msg.sender),
            inviteAmount
        );

        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
    }
    
}