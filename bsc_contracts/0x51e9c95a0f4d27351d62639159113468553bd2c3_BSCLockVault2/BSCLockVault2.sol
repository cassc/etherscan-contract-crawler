/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

pragma solidity 0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BSCLockVault2 is Ownable {
    using SafeMath for uint;
    
    address public constant tokenAddress = 0xf5128928f85F16bD67C1E02DdD1b47A71d17aDF5;
    
    uint public constant tokensLocked = 550000 * 10**18;   // 550000 BSC with 18 decimals
    uint public constant unlockRate = 1 minutes;           // Once in 1 minute
    uint public constant lockDuration = 1 days;            // Before 1 day, it's impossible to unlock but running pending...
    uint public lastClaimedTime;
    uint public deployTime;

    function unlockableTokens() public view returns (uint) {
        if (block.timestamp >= deployTime.add(lockDuration)) {
            return tokenBalance();
        } else {
            uint timeSinceLastClaim = block.timestamp.sub(lastClaimedTime);
            uint periodsSinceLastClaim = timeSinceLastClaim.div(unlockRate);
            return periodsSinceLastClaim.mul(tokensPerPeriod());
        }
    }
    
    function tokensPerPeriod() public view returns (uint) {
        return tokensLocked.div(lockDuration.div(unlockRate));
    }
    
    function tokenBalance() public view returns (uint) {
        return IBEP20(tokenAddress).balanceOf(address(this));
    }
    
    function claimTokens() public onlyOwner {
        uint unlockedTokens = unlockableTokens();
        require(unlockedTokens > 0, "No tokens currently unlockable");
        lastClaimedTime = block.timestamp;
        IBEP20(tokenAddress).transfer(msg.sender, unlockedTokens);
    }

    function setDeployTime() public onlyOwner {
        require(deployTime == 0, "Deploy time has already been set");
        deployTime = block.timestamp;
        lastClaimedTime = deployTime;
    }
}