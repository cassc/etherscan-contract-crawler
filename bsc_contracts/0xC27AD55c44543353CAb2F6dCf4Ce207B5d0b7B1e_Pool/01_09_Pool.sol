// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./utils/Ownable.sol";
import "./utils/SafeERC20.sol";
import "./utils/IERC20.sol";
import "./utils/SafeMath.sol";
import "./DAPP.sol";


contract Pool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 rewardTotal;
        uint256 tokenRewardDebt;
        uint256 tokenRewardTotal;
    }

    struct PoolInfo {
        IERC20 rewardToken;
        IERC20 lpToken;
        uint256 startBlock;
        uint256 bonusEndBlock;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        uint256 rewardPerBlock;

        uint256 accTokenRewardPerShare;
        uint256 rewardTokenPerBlock;

        uint256 totalReward;
        uint256 totalTokenReward;
        uint256 lpSupply;
    }

    uint256 public constant BONUS_MULTIPLIER = 1;


    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);


    address public dapp;
    address public invite;

    constructor(
        address payable _dapp,
        address payable _invite,
        IERC20 _lpToken,
        IERC20 _rewardToken,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _rewardPerBlock,
        uint256 _rewardTokenPerBlock
    ) {

        dapp = _dapp;
        invite = _invite;

        require(_startBlock >= block.number, "startBlock must be in the future");

        require(
            _bonusEndBlock >= _startBlock,
            "bonusEndBlock must be greater than startBlock"
        );

        uint256 lastRewardBlock =
        block.number > _startBlock ? block.number : _startBlock;

        poolInfo.push(
            PoolInfo({
        rewardToken : _rewardToken,
        lpToken : _lpToken,
        startBlock : _startBlock,
        bonusEndBlock : _bonusEndBlock,
        lastRewardBlock : lastRewardBlock,
        accRewardPerShare : 0,
        rewardPerBlock : _rewardPerBlock,
        accTokenRewardPerShare : 0,
        rewardTokenPerBlock : _rewardTokenPerBlock,
        totalReward : 0,
        totalTokenReward : 0,
        lpSupply : 0
        })
        );

    }

    function setDAPP(address payable _dapp) public onlyOwner {
        dapp = _dapp;
    }

    function setInvite(address payable _invite) public onlyOwner {
        invite = _invite;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function editPool(
        address _lpToken,
        address _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _bonusEndBlock,
        uint256 _rewardTokenPerBlock
    ) public onlyOwner {
        updatePool(0);
        poolInfo[0].lpToken = IERC20(_lpToken);
        poolInfo[0].rewardToken = IERC20(_rewardToken);
        poolInfo[0].rewardTokenPerBlock = _rewardTokenPerBlock;
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

    function pendingInfo(uint256 _pid, address _user)
    external
    view
    returns (uint256)
    {
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

    // Update reward vairables for all pools. Be careful of gas spending!
    //更新所有矿池信息
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    //更新某个矿池信息
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
        uint256 tokenReward = multiplier.mul(pool.rewardTokenPerBlock);

        pool.accRewardPerShare = pool.accRewardPerShare.add(
            reward.mul(1e12).div(lpSupply)
        );
        pool.accTokenRewardPerShare = pool.accTokenRewardPerShare.add(
            tokenReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _amount, address _parent) public {

        if (_parent != address(0) && Invite(invite).getParent(_msgSender()) == address(0)) {
            Invite(invite).setParentBySettingRole(_msgSender(), _parent);
        }

        uint256 _pid = 0;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
            .amount
            .mul(pool.accRewardPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
            user.rewardTotal = user.rewardTotal.add(pending);

            uint256 pendingToken = user
            .amount
            .mul(pool.accTokenRewardPerShare)
            .div(1e12)
            .sub(user.tokenRewardDebt);
            user.tokenRewardTotal = user.tokenRewardTotal.add(pendingToken);


            DAPP(dapp).setTokenBalance(_msgSender(), DAPP(dapp).tokenBalance(_msgSender()).add(pendingToken));
            pool.rewardToken.safeTransfer(msg.sender, pending);

            pool.totalReward = pool.totalReward.add(pending);
            pool.totalTokenReward = pool.totalTokenReward.add(pendingToken);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);

        user.tokenRewardDebt = user.amount.mul(pool.accTokenRewardPerShare).div(1e12);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        pool.lpSupply = pool.lpSupply.add(_amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _amount) public {
        uint256 _pid = 0;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(
            user.rewardDebt
        );
        user.rewardTotal = user.rewardTotal.add(pending);

        uint256 pendingToken = user
        .amount
        .mul(pool.accTokenRewardPerShare)
        .div(1e12)
        .sub(user.tokenRewardDebt);
        user.tokenRewardTotal = user.tokenRewardTotal.add(pendingToken);

        DAPP(dapp).setTokenBalance(_msgSender(), DAPP(dapp).tokenBalance(_msgSender()).add(pendingToken));
        pool.rewardToken.safeTransfer(msg.sender, pending);

        pool.totalReward = pool.totalReward.add(pending);
        pool.totalTokenReward = pool.totalTokenReward.add(pendingToken);

        user.amount = user.amount.sub(_amount);
        user.tokenRewardDebt = user.amount.mul(pool.accTokenRewardPerShare).div(1e12);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);

        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        pool.lpSupply = pool.lpSupply.sub(_amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function claim() public {
        uint256 _pid = 0;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(
            user.rewardDebt
        );
        user.rewardTotal = user.rewardTotal.add(pending);

        uint256 pendingToken = user
        .amount
        .mul(pool.accTokenRewardPerShare)
        .div(1e12)
        .sub(user.tokenRewardDebt);
        user.tokenRewardTotal = user.tokenRewardTotal.add(pendingToken);

        DAPP(dapp).setTokenBalance(_msgSender(), DAPP(dapp).tokenBalance(_msgSender()).add(pendingToken));
        pool.rewardToken.safeTransfer(msg.sender, pending);

        pool.totalReward = pool.totalReward.add(pending);
        pool.totalTokenReward = pool.totalTokenReward.add(pendingToken);

        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        user.tokenRewardDebt = user.amount.mul(pool.accTokenRewardPerShare).div(1e12);
        emit Claim(msg.sender, _pid, pending);
    }


    function rescueToken(address tokenAddress, uint256 tokens)
    public
    onlyOwner
    returns (bool success)
    {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function rescueBNB(address payable _recipient) public onlyOwner {
        _recipient.transfer(address(this).balance);
    }

}