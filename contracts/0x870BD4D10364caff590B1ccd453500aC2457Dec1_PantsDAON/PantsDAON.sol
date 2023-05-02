/**
 *Submitted for verification at Etherscan.io on 2023-05-01
*/

// SPDX-License-Identifier: MIT

// PantsDAON is the way...

pragma solidity >=0.7.0 <0.9.0;

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

contract PantsDAON {
    
    enum VotingOptions { Yes, No }
    enum Status { Accepted, Rejected, Pending }
    struct Proposal {
        uint256 id;
        address author;
        string name;
        uint256 createdAt;
        uint256 votesForYes;
        uint256 votesForNo;
        Status status;
    }

    // store all proposals
    mapping(uint => Proposal) public proposals;
    // who already voted for who and to avoid voting twice
    mapping(address => mapping(uint => bool)) public votes;
    // one share for governance token
    mapping(address => uint256) public shares;
    uint public totalShares;
    // the IERC20 allow us to use Panto like our governance token.
    IERC20 public token;
    // need minimum 100,000 Panto to create a proposal.
    uint constant CREATE_PROPOSAL_MIN_SHARE = 100000 * 10 ** 18;
    uint constant VOTING_PERIOD = 7 days;
    uint public nextProposalId;
    
    constructor() {
        token = IERC20(0x54B8D105aA09342FAD6b352D41a0bAd3E1a9aA9d); // Pantomime address
    }
    
    function deposit(uint _amount) external {
        shares[msg.sender] += _amount;
        totalShares += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
    }
    
    function withdraw(uint _amount) external {
        require(shares[msg.sender] >= _amount, 'Not enough shares');
        shares[msg.sender] -= _amount;
        totalShares -= _amount;
        token.transfer(msg.sender, _amount);
    }

    function createProposal(string memory name) external {
    // validate the user has enough shares to create a proposal
    require(shares[msg.sender] >= CREATE_PROPOSAL_MIN_SHARE, 'Not enough shares to create a proposal');
    
    proposals[nextProposalId] = Proposal(
        nextProposalId,
        msg.sender,
        name,
        block.timestamp,
        0,
        0,
        Status.Pending
    );
    nextProposalId++;
    }

    function vote(uint _proposalId, VotingOptions _vote) external {
    Proposal storage proposal = proposals[_proposalId];
    require(votes[msg.sender][_proposalId] == false, 'already voted');
    require(block.timestamp <= proposal.createdAt + VOTING_PERIOD, 'Voting period is over');
    votes[msg.sender][_proposalId] = true;
    if(_vote == VotingOptions.Yes) {
        proposal.votesForYes += shares[msg.sender];
        if(proposal.votesForYes * 100 / totalShares > 50) {
            proposal.status = Status.Accepted;
        }
    } else {
        proposal.votesForNo += shares[msg.sender];
        if(proposal.votesForNo * 100 / totalShares > 50) {
            proposal.status = Status.Rejected;
        }
      }
    }
}