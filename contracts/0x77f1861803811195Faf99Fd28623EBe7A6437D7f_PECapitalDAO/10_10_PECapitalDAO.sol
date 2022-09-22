// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.16;

import { IPECapitalDAO, Error } from "./IPECapitalDAO.sol";
import { SafeCastLib } from "solmate/src/utils/SafeCastLib.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract PECapitalDAO is IPECapitalDAO, Initializable, UUPSUpgradeable {
  using SafeCastLib for uint256;

  /*//////////////////////////////////////////////////////////////
                        Constants & Storage
  //////////////////////////////////////////////////////////////*/

  // Token decimals
  uint8 public constant decimals = 18;
  // Token symbol
  string public constant symbol = "PECAPEQ";
  // Token name
  string public constant name = "P/E Capital DAO LLC";

  // Treasury address
  address public treasury;
  // Amount of share tokens in existence
  uint256 private _totalSupply;
  // Mapping from address to user data
  mapping(address => Member) private _members;
  // Mapping from proposalId to proposal data
  mapping(bytes32 => Proposal) private _proposals;
  // Mapping from proposalId
  mapping(bytes32 => mapping(address => Vote)) private _votes;

  /*//////////////////////////////////////////////////////////////
                      Config, Proxy Initilization
  //////////////////////////////////////////////////////////////*/

  /**
   * @param ceo Initial address of CEO
   * @param treasury_ Treasury account
   */
  function initialize(address ceo, address treasury_) external initializer {
    _setRole(ceo, Role.CEO);
    treasury = treasury_;
  }

  function setTreasury(address treasury_) external onlyCEO {
    treasury = treasury_;
  }

  /**
   * @dev Required by OpenZeppelin UUPS module
   */
  function _authorizeUpgrade(address) internal override onlyCEO {}

  /*//////////////////////////////////////////////////////////////
                            Token Logic
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the amount of share tokens in existence.
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @notice Returns the amount of share tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256) {
    return _members[account].share;
  }

  /**
   * @notice Moves `amount` share tokens from msg.sender to `to`.
   * @param to Must be a member or treasury address
   * @param amount Must be within uint192
   */
  function transfer(address to, uint256 amount) external returns (bool) {
    // This implicity excludes the zero address
    if (to != treasury && _members[to].role == Role.NON_MEMBER) {
      revert Error.OnlyInternalTransfer();
    }

    _transfer(msg.sender, to, amount.safeCastTo192());

    return true; // See EIP20
  }

  /**
   * @notice Mints `amount` share tokens to treasury, increasing total supply.
   */
  function mintToTreasury(uint192 amount) external onlyCEO {
    // User balance is stored as uint192
    require((_totalSupply += amount) < 1 << 192);

    unchecked {
      _members[treasury].share += amount; // Total supply is the sum of shares, hence cannot overflow
    }

    emit Transfer(address(0), treasury, amount);
  }

  /**
   * @notice Burns `amount` share tokens from treasury, reducing total supply.
   */
  function burnFromTreasury(uint192 amount) external onlyCEO {
    _members[treasury].share -= amount;

    unchecked {
      _totalSupply -= amount; // Total supply is the sum of shares, hence cannot underflow
    }

    emit Transfer(treasury, address(0), amount);
  }

  /**
   * @dev Moves `amount` token from `from` to `to`.
   */
  function _transfer(
    address from,
    address to,
    uint192 amount
  ) private {
    _members[from].share -= amount;

    unchecked {
      _members[to].share += amount;
    }

    emit Transfer(from, to, amount);
  }

  /*//////////////////////////////////////////////////////////////
                            DAO Logic
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns role of an `account`.
   */
  function roleOf(address account) external view returns (Role) {
    return _members[account].role;
  }

  /**
   * @notice Adds list of `accounts` to the DAO and transfers amounts of `shares` tokens from the treasury.
   * @param accounts Cannot add if account is already added
   * @param shares The sum of shares cannot exceed treasury balance
   */
  function addMembers(address[] memory accounts, uint192[] memory shares) external onlyMember {
    if (accounts.length != shares.length) revert Error.LengthMismatch();

    for (uint256 i = 0; i < accounts.length; ++i) {
      if (_members[accounts[i]].role != Role.NON_MEMBER) revert Error.AlreadyAdded(accounts[i]);

      _setRole(accounts[i], Role.DIRECTOR);

      _transfer(treasury, accounts[i], shares[i]);
    }
  }

  /**
   * @notice Removes list of `accounts` from the DAO and revokes share tokens to the treasury.
   * @param accounts Cannot remove CEO or non-member
   */
  function removeMembers(address[] memory accounts) external onlyMember {
    for (uint256 i = 0; i < accounts.length; ++i) {
      if (accounts[i] == msg.sender) revert Error.CannotRemoveYourself();

      if (_members[accounts[i]].role == Role.NON_MEMBER) revert Error.NotMemeber(accounts[i]);

      _setRole(accounts[i], Role.NON_MEMBER);

      _transfer(accounts[i], treasury, _members[accounts[i]].share);
    }
  }

  /**
   * @notice Withdraws from the DAO and revokes all share tokens to the treasury.
   */
  function leave() external onlyDirector {
    _setRole(msg.sender, Role.NON_MEMBER);

    _transfer(msg.sender, treasury, _members[msg.sender].share);
  }

  /**
   * @notice Transfers CEO role and share tokens to `to`.
   */
  function transferCEO(address to, uint192 tokenToTransfer) external onlyCEO {
    _setRole(msg.sender, Role.DIRECTOR);

    _setRole(to, Role.CEO);

    _transfer(msg.sender, to, tokenToTransfer);
  }

  /**
   * @dev Sets role of `to` to `role`
   */
  function _setRole(address to, Role role) private {
    emit UpdateRole(to, _members[to].role, role);

    _members[to].role = role;
  }

  modifier onlyMember() {
    if (_members[msg.sender].role == Role.NON_MEMBER) revert Error.OnlyMember();
    _;
  }

  modifier onlyDirector() {
    if (_members[msg.sender].role != Role.DIRECTOR) revert Error.OnlyDirector();
    _;
  }

  modifier onlyCEO() {
    if (_members[msg.sender].role != Role.CEO) revert Error.OnlyCEO();
    _;
  }

  /*//////////////////////////////////////////////////////////////
                         Voting Logic
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Queries proposal data of the given `proposalId`.
   */
  function getProposal(bytes32 proposalId) external view returns (Proposal memory proposal) {
    if ((proposal = _proposals[proposalId]).startTime == 0) revert Error.ProposalNotFound();
  }

  /**
   * @notice Returns support of given proposal casted by `account`.
   */
  function supportOf(bytes32 proposalId, address account) external view returns (Vote) {
    return _votes[proposalId][account];
  }

  /**
   * @notice Calculates and returns the current state of a proposal.
   */
  function state(bytes32 proposalId) public view returns (State) {
    Proposal storage proposal = _proposals[proposalId];

    // startTime is always > 0 for created proposals
    if (proposal.startTime == 0) revert Error.ProposalNotFound();

    if (proposal.overturned == Vote.FOR) return State.SUCCEDED;

    if (proposal.overturned == Vote.AGAINST) return State.DEFEATED;

    if (proposal.startTime > block.timestamp) {
      return State.PENDING;
    }

    if (proposal.endTime > block.timestamp) {
      return State.ACTIVE;
    }

    // Passes if quorum is reached and vote is succeeded
    if (proposal.forVotes >= proposal.quorum && proposal.forVotes > proposal.againstVotes) {
      return State.SUCCEDED;
    } else {
      return State.DEFEATED;
    }
  }

  /**
   * @notice Creates a new proposal.
   * @param delay Voting delay between the proposal is created and the vote starts.
   * @param period Voting delay between the vote start and vote ends.
   * @param quorum Number of FOR votes required to pass the proposal.
   * @param data Proposal data, preferably link to off-chain storage.
   */
  function propose(
    uint64 delay,
    uint64 period,
    uint64 quorum,
    string calldata data
  ) external onlyMember returns (bytes32 proposalId) {
    Proposal storage proposal = _proposals[proposalId = _hashProposal(data)];

    if (proposal.startTime > 0) revert Error.ProposalAlreadyExists();

    uint64 startTime = (block.timestamp + delay).safeCastTo64();
    uint64 endTime = startTime + period;

    proposal.quorum = quorum;
    proposal.proposer = msg.sender;
    proposal.startTime = startTime;
    proposal.endTime = endTime;
    proposal.data = data;

    emit Propose(proposalId, msg.sender, startTime, endTime, quorum, data);
  }

  /**
   * @notice Casts vote of a proposal with a `reason`.
   * @param reason Reason data, preferably link to off-chain storage.
   *               The reason will be stored as an event.
   */
  function castVote(
    bytes32 proposalId,
    Support support,
    string calldata reason
  ) external onlyMember {
    Proposal storage proposal = _proposals[proposalId];

    if (state(proposalId) != State.ACTIVE) revert Error.VoteNotActive();

    if (_votes[proposalId][msg.sender] != Vote.NULL) revert Error.AlreadyCastedVote();

    _votes[proposalId][msg.sender] = _toTypeVote(support);

    if (support == Support.FOR) {
      proposal.forVotes += 1;
    } else {
      proposal.againstVotes += 1;
    }

    emit CastVote(proposalId, msg.sender, support, reason);
  }

  /**
   * @notice Overturns the result of a proposal with a `reason`.
   *         Overturning will result in ending the voting period.
   * @param reason Reason data, preferably link to off-chain storage.
   *               The reason will be stored as an event.
   */
  function overturn(
    bytes32 proposalId,
    Support support,
    string calldata reason
  ) external onlyCEO {
    Proposal storage proposal = _proposals[proposalId];

    if (proposal.startTime == 0) revert Error.ProposalNotFound();

    proposal.overturned = _toTypeVote(support);

    emit Overturn(proposalId, msg.sender, support, reason);
  }

  /**
   * @dev Converts type Support to type Vote.
   */
  function _toTypeVote(Support support) private pure returns (Vote) {
    return Vote(uint8(support) + 1);
  }

  /**
   * @dev Hashes proposal `data` string using keccak256 algorithm.
   */
  function _hashProposal(string calldata data) private pure returns (bytes32) {
    return keccak256(bytes(data));
  }
}