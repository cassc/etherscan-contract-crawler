// SPDX-License-Identifier: MIT


/*

 /$$      /$$  /$$$$$$  /$$   /$$ /$$$$$$$$ /$$     /$$
| $$$    /$$$ /$$__  $$| $$$ | $$| $$_____/|  $$   /$$/
| $$$$  /$$$$| $$  \ $$| $$$$| $$| $$       \  $$ /$$/
| $$ $$/$$ $$| $$  | $$| $$ $$ $$| $$$$$     \  $$$$/
| $$  $$$| $$| $$  | $$| $$  $$$$| $$__/      \  $$/
| $$\  $ | $$| $$  | $$| $$\  $$$| $$          | $$
| $$ \/  | $$|  $$$$$$/| $$ \  $$| $$$$$$$$    | $$
|__/     |__/ \______/ |__/  \__/|________/    |__/

  /$$      /$$  /$$$$$$  /$$   /$$ /$$$$$$ /$$   /$$  /$$$$$$
 | $$$    /$$$ /$$__  $$| $$  /$$/|_  $$_/| $$$ | $$ /$$__  $$
 | $$$$  /$$$$| $$  \ $$| $$ /$$/   | $$  | $$$$| $$| $$  \__/
 | $$ $$/$$ $$| $$$$$$$$| $$$$$/    | $$  | $$ $$ $$| $$ /$$$$
 | $$  $$$| $$| $$__  $$| $$  $$    | $$  | $$  $$$$| $$|_  $$
 | $$\  $ | $$| $$  | $$| $$\  $$   | $$  | $$\  $$$| $$  \ $$
 | $$ \/  | $$| $$  | $$| $$ \  $$ /$$$$$$| $$ \  $$|  $$$$$$/
 |__/     |__/|__/  |__/|__/  \__/|______/|__/  \__/ \______/

  /$$$$$$  /$$$$$$$  /$$$$$$$   /$$$$$$  /$$$$$$$  /$$$$$$$$ /$$   /$$ /$$   /$$ /$$$$$$ /$$$$$$$$ /$$     /$$
 /$$__  $$| $$__  $$| $$__  $$ /$$__  $$| $$__  $$|__  $$__/| $$  | $$| $$$ | $$|_  $$_/|__  $$__/|  $$   /$$/
| $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$   | $$   | $$  | $$| $$$$| $$  | $$     | $$    \  $$ /$$/
| $$  | $$| $$$$$$$/| $$$$$$$/| $$  | $$| $$$$$$$/   | $$   | $$  | $$| $$ $$ $$  | $$     | $$     \  $$$$/
| $$  | $$| $$____/ | $$____/ | $$  | $$| $$__  $$   | $$   | $$  | $$| $$  $$$$  | $$     | $$      \  $$/
| $$  | $$| $$      | $$      | $$  | $$| $$  \ $$   | $$   | $$  | $$| $$\  $$$  | $$     | $$       | $$
|  $$$$$$/| $$      | $$      |  $$$$$$/| $$  | $$   | $$   |  $$$$$$/| $$ \  $$ /$$$$$$   | $$       | $$
 \______/ |__/      |__/       \______/ |__/  |__/   |__/    \______/ |__/  \__/|______/   |__/       |__/


by steviep.eth


Money Making Opportunity (MMO) is a smart contract-based collaboration game in which an unbound
number of participants send 0.03 ETH to the MMO contract, and must then coordinate to distribute
the resulting contract balance. MMO is inspired by the Pirate Game [1], but modified to work within
the context of a smart contract with a non specified number of participants.

At a high level, the game works as follows:

- Participants blindly send 0.03 ETH to moneymakingopportunity.eth, which sends the funds to the
  MMO contract.
- The artist starts the game. After this point, sending ETH to moneymakingopportunity.eth does not
  allow the sender to participate in Money Making Opportunity.
- Once the game is started, all participants who contributed at least 0.03 ETH before the starting
  time may claim an MMO NFT.
- Every week, one token is designated as the "Leader".
- This continues until all tokens have been the Leader.
- The Leader can propose a "Settlement Address" (i.e., an address for which the MMO contract balance
  can be sent to).
- The Settlement Address can by an EOA, a smart contract that splits the balance according to custom
  logic, etc.
- If at least 50% of eligible participants vote in favor of the active week's proposal, the balance
  can be then be sent to that contract.
- If a proposal is not successfully settle within one week, then that week's Leader can no longer vote
  on future proposals.
- Leadership order is determined by reverse order of token id. For example, if there are 100 tokens,
  then the owner of token #99 is the Leader for week 1, and the owner of token #0 is the Leader for
  week 99.
- MMO tokens may be traded as normal NFTs.
- Each token may make *one single proposal* for the Settlement Address. This proposal can be made at
  any time.
- Tokens can vote on the proposal for any week at any time. These votes can no longer be changed once
  a proposal has succeeded.

[1] https://en.wikipedia.org/wiki/Pirate_game


# ERRORS #
All errors were truncated to integers in order to obfuscate functionality during the contribution phase.
  1: Cannot take this action because contract is locked
  2: Cannot take this action because contract is unlocked
  3: This error doesn't exist because I fucked up
  4: Only the token owner can call this function
  5: Cannot vote on weeks that have already passed
  6: Cannot propose a settlement address because token has already been eliminated
  7: A settlement address has already been proposed for this token
  8: Contract has already been settled
  9: Cannot vote after contract has been settled
  10: Cannot settle contract because yays < nays
  11: This action can only be taken by the artist
  12: Cannot cast votes on tokens assigned to a later week

*/




import "./Dependencies.sol";

pragma solidity ^0.8.17;

interface ITokenURI {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

/// @title Money Making Opportunity
/// @author steviep.eth
/// @dev All contract errors are reduced to integers in order to obfuscate the pre-verified code
/// @notice A smart contract-base collaboration game in which participants
/// must coordinate to split the contract balance
contract MoneyMakingOpportunity is ERC721 {
  /// @notice Participants must send at least 0.03 ether to the contract in order to claim a token
  uint256 constant public FAIR_CONTRIBUTION = 0.03 ether;

  /// @notice The contribution phase takes place when isLocked == true. The voting/proposal phase
  /// only becomes active when isLocked == false
  bool public isLocked = true;

  /// @notice When this is locked, the URI contract can no longer be updated
  bool public uriLocked;

  /// @notice Total supply of mined tokens
  uint256 public totalSupply;

  /// @notice Timestamp of the beggining of the voting/proposal phase
  uint256 public beginning;

  /// @notice Timestamp of the end of the voting/proposal phase
  uint256 public ending;

  /// @notice Total number of addresses that successfully contributed 0.03 ETH during the contribution phase
  uint256 public contributors;

  /// @notice Address of the URI contract
  address public tokenURIContract;

  /// @notice Deployer of contract. Has the sole ability to unlock the contract, update the URI contract
  /// and lock the URI contract
  address public artist;

  /// @notice Mapping of addresses to their total contributions
  mapping(address => uint256) public amountPaid;

  /// @notice Mapping of addresses to the token ID they may claim
  mapping(address => uint256) public addrToTokenId;

  /// @notice Mapping of token IDs to their proposed settlement addresses
  mapping(uint256 => address) public settlementAddressProposals;

  /// @notice Mapping of token IDs to their votes
  mapping(uint256 => mapping(uint256 => bool)) private _tokenVotes;

  /// @dev This event emits when the metadata of a token is changed.
  /// So that the third-party platforms such as NFT market could
  /// timely update the images and related attributes of the NFT.
  event MetadataUpdate(uint256 _tokenId);

  /// @dev This event emits when the metadata of a range of tokens is changed.
  /// So that the third-party platforms such as NFT market could
  /// timely update the images and related attributes of the NFTs.
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

  /// @dev Sets the artist to the contract deployer
  constructor() ERC721('Money Making Opportunity', 'MMO') {
    artist = msg.sender;
    contributors++;
  }

  /// @notice Handles all ETH sent to the contract. If the contract is locked and the
  /// cumulative amount of ETH sent to the contract is >= 0.03, then that address is
  /// assigned a token ID to mint later. If the contract has been settled, the amount
  /// included in msg.value is forwarded to the final settlement address. Otherwise,
  /// the ETH is jsut held by the MMO contract.
  receive() external payable {
    uint256 originalAmount = amountPaid[msg.sender];
    amountPaid[msg.sender] += msg.value;

    if (
      isLocked
      && originalAmount < FAIR_CONTRIBUTION
      && amountPaid[msg.sender] >= FAIR_CONTRIBUTION
    ) {
      addrToTokenId[msg.sender] = contributors;
      contributors++;

    } else if (ending > 0) {
      payable(settlementAddressProposals[currentWeek()]).transfer(address(this).balance);
    }
  }

  /// @notice Unlocks the contract and sends token 0 to the caller
  /// @param _uriContract Address of the URI contract
  /// @dev Can only be called by the artist
  function unlock(address _uriContract) external {
    require(msg.sender == artist, '11');
    require(isLocked, '1');
    isLocked = false;
    beginning = block.timestamp;
    tokenURIContract = _uriContract;
    totalSupply++;
    _mint(msg.sender, 0);
  }

  /// @notice Mints the appropriate token to the caller if the contract is unlocked
  function claim() external {
    require(!isLocked, '2');

    totalSupply++;
    _mint(msg.sender, addrToTokenId[msg.sender]);
  }

  /// @notice Casts a vote for a given week and token ID
  /// @param tokenId Token ID for vote
  /// @param week Week # for vote
  /// @param vote Vote value
  /// @dev Votes can be made at any time, but cannot be changed once a proposal has been accepted or rejected
  /// @dev Tokens cannot be used to vote for proposals issued by lower token IDs (or higher week #s)
  function castVote(uint256 tokenId, uint256 week, bool vote) external {
    require(ownerOf(tokenId) == msg.sender, '4');
    require(week >= currentWeek(), '5');
    require(ending == 0, '9');
    require(tokenIdToWeek(tokenId) > week, '12');

    _tokenVotes[tokenId][week] = vote;
  }

  /// @notice Proposes a settlement address for a given week
  /// @param week Week # of proposal
  /// @param settlementAddress The proposed settlement address for the provided week
  /// @dev Proposals can only be made for future weeks
  /// @dev Proposals can only be made by the corresponding token owner for that week
  /// @dev Proposals can be made at any time, but once they are made the token can no
  /// longer propose settlement addresses
  function proposeSettlementAddress(uint256 week, address settlementAddress) external {
    uint256 tokenId = weekToTokenId(week);
    require(!isEliminated(tokenId), '6');
    require(ownerOf(tokenId) == msg.sender, '4');
    require(settlementAddressProposals[week] == address(0), '7');
    settlementAddressProposals[week] = settlementAddress;
    emit MetadataUpdate(tokenId);
  }


  /// @notice Sends the balance of the contract to the week's proposed settlement address
  /// if it has garnered at least 50% of all remaining valid votes.
  /// @dev This can be called by anyone
  /// @dev This must be called while the week is still active
  function settlePayment() external {
    require(ending == 0, '8');
    uint256 week = currentWeek();
    if (week == contributors) require(ownerOf(0) == msg.sender);

    (uint256 yays, uint256 nays) = calculateVotes(week);

    require(yays >= nays, '10');

    ending = block.timestamp;
    payable(settlementAddressProposals[week]).transfer(address(this).balance);
    emit BatchMetadataUpdate(0, contributors);
  }

  /// @notice Calculates all yay/nay votes for a given week
  /// @dev Only leaders for future weeks are valid. (ex. The leader of week 10 cannot vote on week 9)
  /// @param week Week # to calculate
  /// @return yayVotes Number of yays received for that week. The week's leader automatically
  /// votes yay for that week
  /// @return nayVotes Number of nay votes received for that week. All votes are nay by default
  function calculateVotes(uint256 week) public view returns (uint256, uint256) {
    uint256 yays = 1;
    uint256 nays;
    uint256 tokenId = weekToTokenId(week);

    for (uint256 i = 0; i < tokenId; i++) {
      if (_tokenVotes[i][week]) yays++;
      else nays++;
    }

    return (yays, nays);
  }

  /// @notice Maps a token ID to its leadership week
  /// @param tokenId Token ID to query
  /// @return week Leadership week of token id
  function tokenIdToWeek(uint256 tokenId) public view returns (uint256) {
    return contributors - tokenId;
  }

  /// @notice Finds the leader token of a given week
  /// @param week Week # to query
  /// @return tokenId Leader of queried week
  /// @dev Weeks start at 1, but will return 0 if the contract is locked
  function weekToTokenId(uint256 week) public view returns (uint256) {
    if (isLocked) return 0;
    return contributors - week;
  }

  /// @notice Returns the current Active Week number
  /// @return week Active week number
  /// @dev This will return 0 if locked
  /// @dev This will return the last valid week if the contract has been settled
  /// @dev if the contract is never settled, it will default to the highest possible
  /// week number
  function currentWeek() public view returns (uint256) {
    if (isLocked) return 0;
    uint256 endTime = ending > 0 ? ending : block.timestamp;
    uint256 week = 1 + (endTime - beginning) / 1 weeks;

    return week >= contributors ? contributors : week;
  }

  /// @notice Returns the token ID of the leader for the current week
  /// @return tokenId Token ID of leader for current week
  function leaderToken() public view returns (uint256) {
    return weekToTokenId(currentWeek());
  }

  /// @notice Denotes whether the current leader token can vote on proposals
  /// made by the provided token ID
  /// @param tokenId Token ID
  /// @return canVote
  function isEliminated (uint256 tokenId) public view returns (bool) {
    return tokenId > leaderToken();
  }

  /// @notice Returns the current vote state of a token ID/week
  /// @param tokenId Token ID
  /// @param week Week
  /// @return voteState
  /// @dev This will always return true for the week in which the given token
  /// is the leader
  function votes(uint256 tokenId, uint256 week) public view returns (bool) {
    if (tokenIdToWeek(tokenId) == week) return true;
    return _tokenVotes[tokenId][week];
  }

  /// @notice Token URI
  /// @param tokenId Token ID to look up URI of
  /// @return Token URI
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return ITokenURI(tokenURIContract).tokenURI(tokenId);
  }

  /// @notice Checks if given token ID exists
  /// @param tokenId Token to run existence check on
  /// @return True if token exists
  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  /// @notice Set the Token URI contract
  /// @param _uriContract New address of URI contract
  /// @dev This can only be set by the artists, and cannot be reset after
  /// the URI is locked
  function setURIContract(address _uriContract) external {
    require(msg.sender == artist && !uriLocked, '11');
    tokenURIContract = _uriContract;
    emit BatchMetadataUpdate(0, contributors);
  }

  /// @notice Locks the URI contract
  function commitURI() external {
    require(msg.sender == artist, '11');
    require(!isLocked, '13');
    uriLocked = true;
  }

  /// @notice Query if a contract implements an interface
  /// @param interfaceId The interface identifier, as specified in ERC-165
  /// @return `true` if the contract implements `interfaceId` and
  ///         `interfaceId` is not 0xffffffff, `false` otherwise
  /// @dev Interface identification is specified in ERC-165. This function
  ///      uses less than 30,000 gas. See: https://eips.ethereum.org/EIPS/eip-165
  ///      See EIP-4906: https://eips.ethereum.org/EIPS/eip-4906
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }
}
