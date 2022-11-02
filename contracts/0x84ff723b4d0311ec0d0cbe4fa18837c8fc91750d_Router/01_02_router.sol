/*router*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./SafeMath.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface Vault {
    function deposit(address token, uint256 amount) payable external returns(bool);
    function withdraw(address token, address to, uint256 amount)  payable external returns(bool);
    function getEthBalance() external view returns (uint256);
}


contract Router {

    using SafeMath for uint256;

    address payable public owner;
    address payable public operater;
    address payable public vault;
   
    event Received(address from, uint256 amount); 
    event Bingo(uint256 blockid, string hash, address to, uint256 amount);

    event LogShareInfo(uint256 _balance, uint256 _share, uint256 _totalShares);
    event LogWithDrawInfo(address from, address token, uint256 _amount, uint256 _ownerAmount, uint256 _wAmount);

    struct PoolInfo {
        IERC20 token;
        uint256 min;
        uint256 max;
        uint256 ownerRate;
        uint256 operaterRate;
        uint256 totalShares;
    }
    PoolInfo[] public poolInfo;

    struct UserInfo {
        uint256 share;
    }
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    constructor() {
        owner = payable(msg.sender);
        operater = payable(msg.sender);

        uint256 _min = 1000000000000000000;
        uint256 _max = 10000000000000000000000;
        uint256 _ownerRate = 100;
        uint256 _operaterRate = 100;
        addPool(address(0),  _min,  _max, _ownerRate, _operaterRate);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier onlyOperater {
        require(msg.sender == operater, "You are not the operater");
        _;
    }

    function setOperater(address payable _operater) onlyOwner external {
        operater = _operater;
    }

    function setOwner(address payable _owner) onlyOwner external {
        owner = _owner;
    }

    function set1x2vault(address payable _1x2vault) onlyOwner external {
        vault = _1x2vault;
    }

    function setOperateRate(uint256 _pid, uint256 _operaterRate) onlyOwner external {
        PoolInfo storage pool = poolInfo[_pid];
        pool.operaterRate = _operaterRate;
    }

    function setOwnerRate(uint256 _pid, uint256 _ownerRate) onlyOwner external {
        PoolInfo storage pool = poolInfo[_pid];
        pool.ownerRate = _ownerRate;
    }

    function setPoolMin(uint256 _pid, uint256 _min) onlyOwner external {
        PoolInfo storage pool = poolInfo[_pid];
        pool.min = _min;
    }

    function setPoolMax(uint256 _pid, uint256 _max) onlyOwner external {
        PoolInfo storage pool = poolInfo[_pid];
        pool.max = _max;
    }


    function getOwner() public view returns (address) {
        return owner;
    }


    function deposit(uint256 _pid, uint256 _amount) payable external {

        require(_amount > 0, "Invalid Amount");

        uint256 _before;
        uint256 _after ;
        uint256 _userShare;

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
                
        if(address(pool.token) == address(0)) {
            require(_amount == msg.value, "Invalid Amount");
            _before = Vault(vault).getEthBalance();
            vault.transfer(_amount);
            _after = Vault(vault).getEthBalance();
        } else {
            _before = IERC20(pool.token).balanceOf(vault);
            IERC20(pool.token).transferFrom(msg.sender, address(vault), _amount);
            _after = IERC20(pool.token).balanceOf(vault);
        }

        if(pool.totalShares == 0) {
            _userShare = _after.sub(_before);
            user.share = _userShare;
            pool.totalShares = _userShare;
        } else {
            // notice  _after.sub(_before).div(_before) may be zero
            _userShare = _after.sub(_before).mul(pool.totalShares).div(_before);
            user.share = user.share.add(_userShare);
            pool.totalShares = pool.totalShares.add(_userShare);
        }

        // log
        emit LogShareInfo(_after, _userShare, user.share);
    }


    function withdraw(uint256 _pid, uint256 _share) payable external {

        uint256 _amount;
        uint256 _balance;
        uint256 _ownerAmount;

        require(_pid < poolInfo.length, 'Invalid pid');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(_share > 0, 'Invalid _share');
        require(_share <= user.share, 'Invalid _share');

        if(address(pool.token) == address(0)) {
            _balance = Vault(vault).getEthBalance();
        } else {
            _balance = IERC20(pool.token).balanceOf(vault);
        }

        _amount = _share.mul(_balance).div(pool.totalShares);
        _ownerAmount = _amount.mul(pool.ownerRate).div(10000);

        Vault(vault).withdraw(address(pool.token), msg.sender, _amount.sub(_ownerAmount));
        Vault(vault).withdraw(address(pool.token), owner, _ownerAmount);

        user.share = user.share.sub(_share);
        pool.totalShares = pool.totalShares.sub(_share);

        emit LogShareInfo(_balance, _share, pool.totalShares);
        emit LogWithDrawInfo(msg.sender, address(pool.token), _amount, _ownerAmount, _amount.sub(_ownerAmount));
    }


    function addPool(address _token, uint256 _min, uint256 _max, uint256 _ownerRate, uint256 _operaterRate) public onlyOwner {
        poolInfo.push(PoolInfo({
            token: IERC20(_token),
            min: _min,
            max: _max,
            ownerRate: _ownerRate,
            operaterRate: _operaterRate,
            totalShares: 0
        }));
    }
    
    function getPoolInfo() public view returns(PoolInfo[] memory) {
        return poolInfo;
    }


    function getUserShare(address addr) public view returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](poolInfo.length);
        
        for (uint i = 0; i < poolInfo.length; i++) {
            UserInfo memory u = userInfo[i][addr];
            ret[i] = u.share;
        }
        return ret;
    }


    function bingo(uint256 _blockid, string memory _pHash, uint256 _pid , address _to, uint256 _amount) onlyOperater external {

        require(_pid < poolInfo.length, "Invalid pid");
        
        uint256 _ownerAmount;
        uint256 _operaterAmount = 0;

        PoolInfo storage pool = poolInfo[_pid];
        require(_amount <= pool.max.mul(2), "Invalid Amount");

        _ownerAmount = _amount.mul(pool.ownerRate).div(10000);
        if(pool.operaterRate > 0) {
            _operaterAmount = _amount.mul(pool.operaterRate).div(10000);
            Vault(vault).withdraw(address(pool.token), operater, _operaterAmount);
        }

        Vault(vault).withdraw(address(pool.token), _to, _amount.sub(_ownerAmount.add(_operaterAmount)));
        Vault(vault).withdraw(address(pool.token), owner, _ownerAmount);

        emit Bingo(_blockid, _pHash, _to, _amount);
    }


    receive() external payable {}
    fallback() external payable {}
}