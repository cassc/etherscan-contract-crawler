/**
 *Submitted for verification at Etherscan.io on 2023-07-24
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/EchoesRemainderEvent.sol


pragma solidity ^0.8.9;


contract EchoesRemainderEvent {
    IERC20 public tokenContract;
    address public owner;
    address public teamOracleFeeReceiver = address(0x3cbd714c6934321CBBb0af6F9B9Bc90B7043b5B3);
    bool public isActive;
    uint256 public minimumTokenToParticipate = 40 * 10**6;
    uint256 public timeStarted = 0;
    uint256 public timeEnding = 0;
    uint256 public delayEndTime = 2 * 24 * 60 * 60;
    uint256 public maximumParticipant = 500;

    mapping(address => bool) public isParticipant;

    struct Participant {
        address wallet;
        uint256 timestamp;
        uint256 balance;
    }

    Participant[] public participants;

    constructor(address _token) {
        tokenContract = IERC20(_token);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == teamOracleFeeReceiver, "Caller is not owner");
        _;
    }

    function toggleActive() external onlyOwner {
        isActive = !isActive;
        if (isActive){
            timeStarted = block.timestamp;
            timeEnding = block.timestamp + delayEndTime;
        }
    }

    function setMinimumToken(uint256 _t) external onlyOwner {
        minimumTokenToParticipate = _t;
    }

    function setDelayEnding(uint256 _d) external onlyOwner {
        delayEndTime = _d;
    }

    function setMaximumParticipant(uint256 _p) external onlyOwner {
        maximumParticipant = _p;
    }

    function clearParticipants() external onlyOwner {
        for (uint256 i = 0; i < participants.length; i++) {
            isParticipant[participants[i].wallet] = false;
        }
        delete participants;
    }

    function getParticipants() external view returns (Participant[] memory) {
        return participants;
    }

    function isEligible() external view returns (bool) {
        return tokenContract.balanceOf(msg.sender) >= minimumTokenToParticipate * 10**18;
    }

    function isParticipantLimitReached() external view returns (bool) {
        return participants.length >= maximumParticipant;
    }

    function participate() external {
        require(isActive, "Event is not active");
        require(block.timestamp < timeEnding, "Event ended");
        require(isParticipant[msg.sender] == false, "Already participant");
        require(tokenContract.balanceOf(msg.sender) >= minimumTokenToParticipate * 10**18, "Insufficient tokens hold");
        require(participants.length < maximumParticipant, "Maximum participant reached");
        
        participants.push(Participant({
            wallet: msg.sender,
            timestamp: block.timestamp,
            balance: tokenContract.balanceOf(msg.sender)
        }));

        isParticipant[msg.sender] = true;
    }
}