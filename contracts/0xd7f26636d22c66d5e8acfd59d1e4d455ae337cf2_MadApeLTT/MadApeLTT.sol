/**
 *Submitted for verification at Etherscan.io on 2023-09-29
*/

// TG: @BR_BIGBOSS DEV Copyrights
// TG: @madapeeth

// SPDX-License-Identifier: MIT
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


contract MadApeLTT {

    address public owner;
    IERC20 public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    uint256 public round = 1; 
    uint256 public constant PARTICIPATION_AMOUNT = 50e18;
    uint256 public constant MAX_PARTICIPANTS = 100;
    uint256 public constant WINNERS_COUNT = 5;
    uint256 public constant REWARD_AMOUNT = 900e18;
    address public constant HOUSE = 0x4902a41e25cda21E4d052f589a480f5b4CfB8b76;
    uint256 public constant HOUSE_AMOUNT = 500e18;

    address[] private participants;
    mapping(uint256 => mapping(address => bool)) public hasParticipated;
    mapping(uint256 => uint256) public roundParticipantsCount;
    mapping(uint256 => address[]) public roundWinners;

    event Participated(address indexed participant, uint256 round);
    event WinnerSelected(address indexed winner, uint256 round);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function participate() external {
        require(!hasParticipated[round][msg.sender], "Already participated this round");
        require(USDT.transferFrom(msg.sender, address(this), PARTICIPATION_AMOUNT), "Transfer failed");

        hasParticipated[round][msg.sender] = true;
        participants.push(msg.sender);
        roundParticipantsCount[round]++;

        if (participants.length == MAX_PARTICIPANTS) {
            _endCurrentRound();
            _resetGame();
        }

        emit Participated(msg.sender, round);
    }

    function getApprovalStatus(address user) external view returns (uint256 requiredAmount, bool hasApproved) {
        requiredAmount = PARTICIPATION_AMOUNT;
        hasApproved = USDT.allowance(user, address(this)) >= requiredAmount;
    }

    function getWinnersOfRound(uint256 _round) external view returns (address[] memory) {
        return roundWinners[_round];
    }

    function getParticipantsCountOfRound(uint256 _round) external view returns (uint256) {
        return roundParticipantsCount[_round];
    }

    function withdrawRemainingUSDT() external onlyOwner {
        USDT.transfer(owner, USDT.balanceOf(address(this)));
    }

    function _endCurrentRound() private {
        for (uint i = 0; i < WINNERS_COUNT; i++) {
            address winner = _selectRandomWinner();
            if (winner == address(0)) break;

            USDT.transfer(winner, REWARD_AMOUNT);
            emit WinnerSelected(winner, round);
            roundWinners[round].push(winner);
            _removeWinnerFromParticipants(winner);
        }
    }

    function _selectRandomWinner() private view returns (address) {
        if (participants.length == 0) return address(0);
        return participants[random() % participants.length];
    }

    function _removeWinnerFromParticipants(address winner) private {
        for (uint i = 0; i < participants.length; i++) {
            if (participants[i] == winner) {
                participants[i] = participants[participants.length - 1];
                participants.pop();
                break;
            }
        }
    }

    function _resetGame() private {
        USDT.transfer(HOUSE, HOUSE_AMOUNT);
        delete participants;
        round++;
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    }
}