pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ERC20TokenList.sol";

// interface for payment ERC20 Token List
interface ERC20TokenListLike {
    function contains(address addr) external view returns (bool);
}

contract StakePool is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    struct PoolInfo {
        address erc20;
        uint256 cap;
        uint256 apr;
        uint256 open;
        uint256 start;
        uint256 end;
        uint256 amount;
        uint256 finalAmount; //achievement
    }
    
    struct UserInfo {
        uint256 amount;
        uint256 reward;
    }

    address public valut;

    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    ERC20TokenListLike public erc20s;

    address public feeTo;
    uint256 public feeRate;

    event Valut(address indexed addr);
    event FeeTo(address indexed addr);
    event FeeRate(uint256 rate);
    

    event Pool(uint256 indexed pid, address _erc20, uint256 _cap, uint256 _apr, uint256 _open, uint256 _start, uint256 _end);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        ERC20TokenListLike _erc20s
    ) 
    {
        erc20s = ERC20TokenListLike(_erc20s);
        valut = msg.sender;
        feeTo = msg.sender;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    
    /**
     * @dev setValut : Valut address 변경
     *
     * Requirements:
     *
     */ 	
    function setValut(address _valut) public onlyOwner {
        valut = _valut;
        emit Valut(_valut);
    }

    /**
     * @dev setValut : Valut address 변경
     *
     * Requirements:
     *
     */ 	

    function setFeeTo(address _feeTo) public onlyOwner {
        feeTo = _feeTo;
        emit FeeTo(feeTo);
    }

    /**
     * @dev setFeeRate : 수수료 설정
     *
     * Requirements:
     *
     *   Fee Rate : 0 ~ 100 
     *
     */
    function setFeeRate(uint256 _feeRate) public onlyOwner {
        require( _feeRate <= 100,"StakePool/setFeeRate__feeRate <= 100");
        feeRate = _feeRate;
        emit FeeRate(feeRate);
    }

    /**
     * @dev add : 풀 생성
     *   args  
     *     _erc20 : token erc20
     *     _cap : deposit max amount
     *     _apr : 1 year apr
     *     _open : open time
     *     _start : start time
     *     _end : end time
     *
     * Requirements:
     *
     *   time은 초단위, open < start < end
     *   현재시간 < start
     * 
     */ 	
    function add(address _erc20, uint256 _cap, uint256 _apr, uint256 _open, uint256 _start, uint256 _end) public onlyOwner {
        require(_open < _start,"StakePool/add_should_open_<_start");
        require(block.timestamp < _start,"StakePool/add_should_block_timestamp_<_start");
        require(_start < _end,"StakePool/add_should_start_<_end");
        require(erc20s.contains(_erc20),"StakePool/add_erc20_not_registered");
        
        poolInfo.push(PoolInfo({
            erc20: _erc20,
            cap: _cap,
            apr: _apr,
            open: _open,
            start: _start,
            end: _end,
            amount: 0,
            finalAmount: 0
        }));
        
        emit Pool(poolInfo.length.sub(1), _erc20, _cap, _apr, _open, _start, _end);
    }

    /**
     * @dev add : 풀 수정  
     *
     */    
    function set(uint256 _pid, address _erc20, uint256 _cap, uint256 _apr, uint256 _open, uint256 _start, uint256 _end) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        
        require(pool.open > block.timestamp,"StakePool/set_pool_opened");
        
        require(_open < _start,"StakePool/set_should_open_<_start");
        require(block.timestamp < _start,"StakePool/set_should_block_timestamp_<_start");
        require(_start < _end,"StakePool/set_should_start_<_end");
        require(erc20s.contains(_erc20),"StakePool/set_erc20_not_registered");
        
        pool.erc20 = _erc20;
        pool.cap = _cap;
        pool.apr = _apr;
        pool.open = _open;
        pool.start = _start;
        pool.end = _end;

        emit Pool(_pid, _erc20, _cap, _apr, _open, _start, _end);
    }

    /**
     * @dev deposit : 입금 하기
     *   args  
     *     _pid : pool id
     *     _amount : deposit amount
     *
     * Requirements:
     *
     *   open < 현재시간 < start
     * 
     */ 	
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(pool.open < block.timestamp,"StakePool/deposit_not opened");
        require(pool.start > block.timestamp,"StakePool/deposit_should_start_>_block_timestamp");
        require(pool.cap >= pool.amount.add(_amount),"StakePool/deposit_cap_max");
        pool.amount = pool.amount.add(_amount);
        pool.finalAmount = pool.amount;

        IERC20 erc20 = IERC20(pool.erc20);

        erc20.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);

        uint256 day = pool.end.sub(pool.start).div(1 days);
        uint256 days_apr = pool.apr.mul(1e12).div(365).mul(day);
        user.reward = user.amount.mul(days_apr).div(1e12).div(100);

        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
     * @dev withdraw : 출금 하기
     *   args  
     *     _pid : pool id
     *     _amount : withdraw amount
     *
     * Requirements:
     *
     *   현재 < 시작일-1day 일때 _amount 만큼 출금
     *   end < 현재 일때 모두 출금 + reward - fee (_amount 상관없음)
     * 
     */ 
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "StakePool/withdraw_amount_fall_short");
        require(block.timestamp  < pool.start - 1 days || pool.end < block.timestamp ,"StakePool/withdraw_time_error");
        
        IERC20 erc20 = IERC20(poolInfo[_pid].erc20);

        if(pool.end > block.timestamp){ //종료 전
            erc20.safeTransfer(address(msg.sender), _amount);
            user.amount = user.amount.sub(_amount);
            uint256 day = pool.end.sub(pool.start).div(1 days);
            uint256 days_apr = pool.apr.mul(1e12).div(365).mul(day);
            user.reward = user.amount.mul(days_apr).div(1e12).div(100);
            pool.amount = pool.amount.sub(_amount);
            pool.finalAmount = pool.amount;
        } else { //종료 후
            if((erc20.balanceOf(address(valut)) >= user.reward) && (erc20.allowance(address(valut), address(this)) >= user.reward)) {
                uint256 fee = user.reward.mul(feeRate).div(100);
                erc20.safeTransferFrom(address(valut), address(msg.sender), user.reward.sub(fee));
                erc20.safeTransferFrom(address(valut), address(feeTo), fee);
                user.reward = 0;
            }
            erc20.safeTransfer(address(msg.sender), user.amount);
                       
            pool.amount = pool.amount.sub(user.amount);
            user.amount = 0;
        }

        emit Withdraw(msg.sender, _pid, _amount);
    }

}