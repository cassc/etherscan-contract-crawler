/**
 *Submitted for verification at Etherscan.io on 2023-06-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
  
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


interface IERC20 {
  
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {

        _status = _NOT_ENTERED;
    }
}

contract MonoLetherStaking is ReentrancyGuard, Ownable {

    using SafeMath for uint256;

    IERC20 public token;
    bool public paused;

    uint tokendecimal = 18;

    uint public minStakeAmount = 1 * 10 ** tokendecimal;
    uint public maxStakeAmount = 1000000000 * 10 ** tokendecimal;
    
    uint public generationTime =  3 days;

    uint public totalStakers;

    uint public totalStakedSoFar;
    uint public totalUnstakedSoFar;

    struct database {
        uint amount;
        uint stakedTime;
        uint claimTime;
    }

    mapping (address => database[]) public _userRecord;
    mapping(address => uint256) public dueReward;
    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) public userStakedAmount;
    mapping(address => uint256) public userUnstakedAmount;
    mapping(address => uint256) public userTotalRecievable;

    constructor(address _token
    ) {
        token = IERC20(_token);
    }

    function stake(uint _amount) public nonReentrant {
        require(!paused,"We are Closed due to some reasons!! Will back soon :");
        require(_amount >= minStakeAmount && _amount <= maxStakeAmount,"Error: Value Exceed from Limit!");
        address account = msg.sender;
        token.transferFrom(account,address(this),_amount);
        totalStakedSoFar += _amount;
        _userRecord[account].push(
            database({
                amount: _amount,
                stakedTime: block.timestamp,
                claimTime: block.timestamp
            })
        );
        userStakedAmount[account] += _amount;
        totalStakers += 1;
    }

    function unstake(uint _amount) public {

        require(!paused,"We are Closed due to some reasons!! Will back soon :");
        address account = msg.sender;
        uint length = _userRecord[account].length;
        uint totalAmount;
        uint AmountwithApy;
        uint leftover = _amount;

        for(uint i = 0; i < length; i++) {

            uint _slottime = _userRecord[account][i].stakedTime;
            uint slotAmount = _userRecord[account][i].amount;
            uint rewardSec = _userRecord[account][i].claimTime;
            
            if(slotAmount == 0) continue;

            if(_slottime + 1 days > block.timestamp){   //1-5 days (25%}

                if(leftover >= slotAmount) {
                    _userRecord[account][i].amount = 0;
                    _userRecord[account][i].stakedTime = 0;
                    _userRecord[account][i].claimTime = 0;
                    leftover = leftover - slotAmount;
                    totalAmount += slotAmount;

                    uint sec = calreward(rewardSec);
                    uint factor = calapy(slotAmount);
                    AmountwithApy += sec.mul(factor);
                } 
                else {
                    _userRecord[account][i].amount = _userRecord[account][i].amount - leftover;
                    _userRecord[account][i].claimTime = block.timestamp;
                    totalAmount += leftover;
                    
                    uint sec = calreward(rewardSec);
                    uint factor = calapy(leftover);
                    AmountwithApy += sec.mul(factor);
                    leftover = 0;
                    break;
                }

            }
            else if(_slottime + 2 days > block.timestamp){   //6-10 days (20%)

                if(leftover >= slotAmount) {
                    _userRecord[account][i].amount = 0;
                    _userRecord[account][i].stakedTime = 0;
                    _userRecord[account][i].claimTime = 0;
                    leftover = leftover - slotAmount;
                    totalAmount += slotAmount;
                    uint sec = calreward(rewardSec);
                    uint factor = calapy(slotAmount);
                    AmountwithApy += sec.mul(factor);
                } 
                else {
                    _userRecord[account][i].amount = _userRecord[account][i].amount - leftover;
                    _userRecord[account][i].claimTime = block.timestamp;
                    totalAmount += leftover;
                    uint sec = calreward(rewardSec);
                    uint factor = calapy(leftover);
                    AmountwithApy += sec.mul(factor);
                    leftover = 0;
                    break;
                }
               
            }
            else if(_slottime + 3 days > block.timestamp){   //11-15 days (15%)

                if(leftover >= slotAmount) {
                    _userRecord[account][i].amount = 0;
                    _userRecord[account][i].stakedTime = 0;
                    _userRecord[account][i].claimTime = 0;
                    leftover = leftover - slotAmount;
                    totalAmount += slotAmount;
                    uint sec = calreward(rewardSec);
                    uint factor = calapy(slotAmount);
                    AmountwithApy += sec.mul(factor);
                } 
                else {
                    _userRecord[account][i].amount = _userRecord[account][i].amount - leftover;
                    _userRecord[account][i].claimTime = block.timestamp;
                    totalAmount += leftover;
                    uint sec = calreward(rewardSec);
                    uint factor = calapy(leftover);
                    AmountwithApy += sec.mul(factor);
                    leftover = 0;
                    break;
                }
               
            }
            else if(_slottime + 4 days > block.timestamp){   //16-20 days (10%)

                if(leftover >= slotAmount) {
                    _userRecord[account][i].amount = 0;
                    _userRecord[account][i].stakedTime = 0;
                    _userRecord[account][i].claimTime = 0;
                    leftover = leftover - slotAmount;
                    totalAmount += slotAmount;
                    uint sec = calreward(rewardSec);
                    uint factor = calapy(slotAmount);
                    AmountwithApy += sec.mul(factor);
                } 
                else {
                    _userRecord[account][i].amount = _userRecord[account][i].amount - leftover;
                    _userRecord[account][i].claimTime = block.timestamp;
                    totalAmount += leftover;
                    uint sec = calreward(rewardSec);
                    uint factor = calapy(leftover);
                    AmountwithApy += sec.mul(factor);
                    leftover = 0;
                    break;
                }
                
            }
            else if(_slottime + 5 days > block.timestamp){   //21-25 days (5%)

                if(leftover >= slotAmount) {
                    _userRecord[account][i].amount = 0;
                    _userRecord[account][i].stakedTime = 0;
                    _userRecord[account][i].claimTime = 0;
                    leftover = leftover - slotAmount;
                    totalAmount += slotAmount;
                    uint sec = calreward(rewardSec);
                    uint factor = calapy(slotAmount);
                    AmountwithApy += sec.mul(factor);
                } 
                else {
                    _userRecord[account][i].amount = _userRecord[account][i].amount - leftover;
                    _userRecord[account][i].claimTime = block.timestamp;
                    totalAmount += leftover;
                    uint sec = calreward(rewardSec);
                    uint factor = calapy(leftover);
                    AmountwithApy += sec.mul(factor);
                    leftover = 0;
                    break;
                }

            }
            else if(_slottime + 6 days > block.timestamp){   //26-30 days (3%)

                if(leftover >= slotAmount) {
                    _userRecord[account][i].amount = 0;
                    _userRecord[account][i].stakedTime = 0;
                    _userRecord[account][i].claimTime = 0;
                    leftover = leftover - slotAmount;
                    totalAmount += slotAmount;
                    uint sec = calreward(rewardSec);
                    uint factor = calapy(slotAmount);
                    AmountwithApy += sec.mul(factor);
                } 
                else {
                    _userRecord[account][i].amount = _userRecord[account][i].amount - leftover;
                    _userRecord[account][i].claimTime = block.timestamp;
                    totalAmount += leftover;
                    uint sec = calreward(rewardSec);
                    uint factor = calapy(leftover);
                    AmountwithApy += sec.mul(factor);
                    leftover = 0;
                    break;
                }
                
            }
            else {                                       // >30 days (2%)
                
                if(leftover >= slotAmount) {
                    _userRecord[account][i].amount = 0;
                    _userRecord[account][i].stakedTime = 0;
                    _userRecord[account][i].claimTime = 0;
                    leftover = leftover - slotAmount;
                    totalAmount += slotAmount;
                    uint sec = calreward(rewardSec);
                    uint factor = calapy(slotAmount);
                    AmountwithApy += sec.mul(factor);
                } 
                else {
                    _userRecord[account][i].amount = _userRecord[account][i].amount - leftover;
                    _userRecord[account][i].claimTime = block.timestamp;
                    totalAmount += leftover;
                    uint sec = calreward(rewardSec);
                    uint factor = calapy(leftover);
                    AmountwithApy += sec.mul(factor);
                    leftover = 0;
                    break;
                }

            }

        }
        require(totalAmount > 0,"Error: 404!");

        dueReward[account] += AmountwithApy;    

        userTotalRecievable[account] += totalAmount;

        totalStakedSoFar -= totalAmount;
        totalUnstakedSoFar += totalAmount;

        userStakedAmount[account] -= totalAmount;
        userUnstakedAmount[account] += totalAmount;

    }

    function withdraw() public {

        require(!paused,"We are Closed due to some reasons!! Will back soon :");
        address account = msg.sender;
        uint256 SubTotal = userTotalRecievable[account];
        uint256 additional =  dueReward[account];
        uint transferable = SubTotal + additional;

        userTotalRecievable[account] = 0;
        dueReward[account] = 0;

        token.transfer(account,transferable);
    }


    function claimReward() public nonReentrant() {

        address account = msg.sender;

        require(!paused,"We are Closed due to some reasons!! Will back soon :");

        uint length = _userRecord[account].length;
        uint AmountwithApy;

        for(uint i = 0; i < length; i++) {

            uint _runningAmount = _userRecord[account][i].amount;
            uint timer = _userRecord[account][i].claimTime;

            uint sec = calreward(timer);
            uint factor = calapy(_runningAmount);

            AmountwithApy += sec.mul(factor);

            if(timer != 0) {
                _userRecord[account][i].claimTime = block.timestamp;
            }
            
        }

        uint extra = dueReward[account];
        uint subtotal = AmountwithApy + extra;

        token.transfer(account,subtotal);

        lastClaim[account] = block.timestamp;
        dueReward[account] = 0;

    }


    function seeReward(address account) public view returns(uint){

        uint length = _userRecord[account].length;
        uint AmountwithApy;

        for(uint i = 0; i < length; i++) {
            uint _runningAmount = _userRecord[account][i].amount;
            uint timer = _userRecord[account][i].claimTime;
            uint sec = calreward(timer);
            uint factor = calapy(_runningAmount);
            AmountwithApy += sec.mul(factor);
        }
        return AmountwithApy + dueReward[account];

    } 

    function unstakeable(address _account) public view returns (uint256) {
        uint length = _userRecord[_account].length;
        uint timer = block.timestamp;
        uint releasable;
        for(uint i=0; i < length; i++){
            if(_userRecord[_account][i].amount == 0) continue;
            if(timer > _userRecord[_account][i].stakedTime +  generationTime) {
                releasable += _userRecord[_account][i].amount;
            }
        }
        return releasable;
    }


    function calapy(uint _amount) internal pure returns (uint){
        uint num = _amount.mul(7).div(10e2);
        return num.div(31536000);
    }

    function calreward(uint _time) internal view returns (uint) {
        if(_time == 0) return 0;
        uint sec = block.timestamp.sub(_time);
        return sec;
    }
    

    //donot change if the contract is working
    function setToken(address _adr) public onlyOwner {
        token = IERC20(_adr);
    }

    function setTokenDecimal(uint _dec) public onlyOwner {
        tokendecimal = _dec;
    }

    function emergencyPause(bool _status) public onlyOwner {
        paused = _status;
    }

    function setUnstakeTimeI(uint _time) public onlyOwner {
        generationTime = _time;
    }

    function rescueToken(address _erc20,address recipient,uint _amount) public onlyOwner {
        IERC20(_erc20).transfer(recipient,_amount);
    }

    function rescueFunds() public onlyOwner {
        (bool os,) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }


}