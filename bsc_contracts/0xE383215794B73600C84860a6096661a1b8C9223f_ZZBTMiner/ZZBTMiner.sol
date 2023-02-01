/**
 *Submitted for verification at BscScan.com on 2023-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Calculates the average of two numbers. Since these are integers,
     * averages of an even and odd number cannot be represented, and will be
     * rounded down.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzAddresseppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address public _owner;

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value
        );
        require(token.approve(spender, newAllowance));
    }
}

interface IZZBTMiner {
    function userEarned(address user) external view returns (uint256,uint256,uint256);
}



contract ZZBTMiner is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public nzAddress =
        address(0x5854972A4de57DF158aC429E7Ef4F5083cD354E4);

    IZZBTMiner public oldMiner = IZZBTMiner(0xCE2b966caAe73500C50c8ebFB846312188ce551C);
    

    uint256 public rRate = 100;
    uint256 private tRate = 10000;
    uint256 public claimTime = 30 days;

    uint256 public claims;

    mapping(uint256 => Claim) public claimInfo;
    mapping(address => uint256[]) private userClaims;
    mapping(address => uint256) public userHistoryClaims;
    mapping(address => uint256) public userLastClaimTime;

    struct Claim {
        address user;
        uint256 amount;
        uint256 rewardTime;
    }

    event RewardPaid(address indexed user, uint256 reward);


    constructor() {
        _owner = msg.sender;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function getUserClaims(address user) public view returns (uint256[] memory) {
        return userClaims[user];
    }

    function claim() external {
        require(block.timestamp - userLastClaimTime[msg.sender] >= claimTime);

        (, , uint256 pClaim) = oldMiner.userEarned(msg.sender);
        uint256 totalRewards = pClaim.sub(userHistoryClaims[msg.sender]).mul(rRate).div(tRate);

        userHistoryClaims[msg.sender] = userHistoryClaims[msg.sender].add(totalRewards);
        userLastClaimTime[msg.sender] = block.timestamp;

        claims = claims.add(1);
        Claim storage c = claimInfo[claims];
        c.user = msg.sender;
        c.amount = totalRewards;
        c.rewardTime = block.timestamp;

        userClaims[msg.sender].push(claims);


        IERC20(nzAddress).safeTransfer(msg.sender, totalRewards);
        emit RewardPaid(msg.sender, totalRewards);
    }

    function changeRate(uint256 newRate) external onlyOwner {
        rRate = newRate;
    }

    function changeTime(uint256 newTime) external onlyOwner {
        claimTime = newTime;
    }

    function clearPot(address to, uint256 amount) external onlyOwner {
        if (amount > IERC20(nzAddress).balanceOf(address(this))) {
            amount = IERC20(nzAddress).balanceOf(address(this));
        }
        IERC20(nzAddress).safeTransfer(to, amount);
    }
}