// SPDX-License-Identifier: MIT
// Creator: 0xR
pragma solidity ^0.8.13;

import "./Gladiator.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

error NotOwner();
error InvalidArenaFee();
error InvalidStakeAmount();
error InvalidGladiatorScore();
error GladiatorIsAlreadyWaitingToDuel();
error WithdrawGladiatorFailed();
error ArenaMustBeClosed();
error ArenaIsClosed();
error PaymentFailed();
error InvalidDuel();

/**
  @notice Degen Arena contract.

  Degen Arena game flow:

  1. The team will open the arena by setting arenaClosesAt to a future date.
     Gladiator holders can then create and accept duels until that date is due.

  2. A holder will create a duel by staking a gladiator NFT and wait for an opponent to accept that duel.
     The duel creator have the option to also stake any amount of eth which the opponent
     have to stake as well in order to accept the duel. The winner takes it all, NFTs and eth.

  3. Another holder will accept the duel by transfer their NFT (and staked eth if required) 
     to the DegenArena contract. DegenArena is now the current owner of both NFTs and the staked eth.

  4. The team will call throwDice() to fetch a random number between 1 and 100 from Chainlink VRF. 

  5. That random number will be used to pick winners in every duel based on their gladiator points.
     Both gladiators in a duel will be given a probability percentage to win which they use to compete.
     Each duel winner is rewarded with the opponents NFT and additional staked eth if there are any.
 */
contract DegenArena is Ownable, IERC721Receiver, VRFConsumerBaseV2 {
  Gladiator private _gladiator; // Gladiator NFT contract
  address payable public treasury; // Team treasury wallet
  uint256 public arenaFee; // Fee to participate in the game
  uint256 public arenaClosesAt; // Arena is open until this date
  Duel[] public duels; // All duels, old and new
  uint256 public dice; // Random rumber from Chainlink

  // Chainlink
  VRFCoordinatorV2Interface public coordinator;
  uint64 public subscriptionId;
  bytes32 public keyHash;
  uint256 public requestId;

  /**
  @notice DegenArena constructor.
  @param __gladiator Gladiator.sol
  @param _treasury Treasury wallet for transfer of revenue
  @param _subscriptionId Chainlink VRF subscription id
  @param vrfCoordinator Chainlink VRFCoordinatorV2Interface
  @param _keyHash Chainlink key hash
 */
  constructor(
    Gladiator __gladiator,
    address payable _treasury,
    uint64 _subscriptionId,
    address vrfCoordinator,
    bytes32 _keyHash
  ) VRFConsumerBaseV2(vrfCoordinator) {
    _gladiator = __gladiator;
    treasury = _treasury;
    subscriptionId = _subscriptionId;
    coordinator = VRFCoordinatorV2Interface(vrfCoordinator);
    keyHash = _keyHash;
  }

  // Emitted when there is a value returned in fulfillRandomWords by Chainlink VRF
  event DiceResult(uint256 dice);

  /**
    @notice Created when the first holder enrolls their gladiator.
    Later updated when the holder of the second gladiator accepts the duel.
    Finally updated by the contract owner with the duel result.
  */
  struct Duel {
    uint256 tokenId1;
    address owner1;
    uint256 tokenId2;
    address owner2;
    uint256 winner;
    uint256 stake;
  }

  /**
    @notice STEP 1.
    Opens the arena which makes holders able to create and accept duels with their gladiators.
    @param _enrollmentCloses - Time in millis when holders can enroll their gladiator NFTs.
    Arena is closed if _enrollmentCloses is set to 0.
    @param _arenaFee - Cost in wei to participate in the game.
  */
  function openArena(uint256 _enrollmentCloses, uint256 _arenaFee)
    external
    onlyOwner
  {
    arenaClosesAt = _enrollmentCloses;
    arenaFee = _arenaFee;
  }

  /**
    @notice STEP 2.
    Called when a holder wants to enroll their gladiator in the arena and find an opponent.
    If the holder send more eth than the arena fee that eth will be staked as a prize.
    Anyone who accepts that duel have to stake the same amount of eth. 
    @param _tokenId - NFT token id.
  */
  function createDuel(uint256 _tokenId) external payable {
    _checkDuelRequirements(_tokenId);
    _gladiator.transferFrom(msg.sender, address(this), _tokenId);
    uint256 stake = (msg.value - arenaFee);
    Duel memory duel = Duel(_tokenId, msg.sender, 0, address(0), 0, stake);
    duels.push(duel);
  }

  /**
    @notice STEP 3.
    Called when a holder wants to accept a duel created by another holder.
    The holder is also sending eth for the arena fee and the staked prize (if there is a prize).
    @param _tokenId - NFT token id.
    @param _duelIndex - The index of the  duel in the duel list that the holder wants to accept.
  */
  function acceptDuel(uint256 _tokenId, uint256 _duelIndex) external payable {
    _checkDuelRequirements(_tokenId);
    _gladiator.transferFrom(msg.sender, address(this), _tokenId);
    uint256 stake = (msg.value - arenaFee);
    if (duels[_duelIndex].tokenId1 == 0) revert InvalidDuel(); // Withdrawn duel
    if (duels[_duelIndex].tokenId2 != 0) revert InvalidDuel(); // Already accepted duel
    if (duels[_duelIndex].stake != stake) revert InvalidStakeAmount();
    duels[_duelIndex].tokenId2 = _tokenId;
    duels[_duelIndex].owner2 = msg.sender;
  }

  /**
    @notice STEP 4.
    Called by the team after the game enrollment is ended.
    Fetches a random number from Chainlink VRF to pick the winners from in duels list.
  */
  function throwDice() external onlyOwner {
    requestId = coordinator.requestRandomWords(
      keyHash,
      subscriptionId,
      3, // requestConfirmations
      200000, // callbackGasLimit
      1 // numWords
    );
  }

  /**
    @notice STEP 5.
    Called after Chainlink returned a random number.
    Picking winners using the random number (dice) and closes the arena to stop further enrollments.
  */
  function closeArenaAndPickWinners() external onlyOwner {
    arenaClosesAt = 0; // Prevent enrollements
    for (uint256 i = 0; i < duels.length; i++) {
      if (duels[i].winner != 0) continue; // Skip old duels
      if (duels[i].tokenId1 == 0) continue; // Skip withdrawn duels
      if (duels[i].tokenId2 == 0) continue; // Skip unaccepted duels
      duels[i].winner = pickWinner(duels[i]);
      _payWinner(duels[i]);
    }
  }

  /**
    @notice Check that:
    1. Caller is the actual token owner.
    2. Arena is not closed.
    3. Arena fee is the same as requried.
    @param _tokenId - NFT token id.
  */
  function _checkDuelRequirements(uint256 _tokenId) private {
    address owner = _gladiator.ownerOf(_tokenId);
    if (msg.sender != owner) revert NotOwner();
    if (block.timestamp > arenaClosesAt) revert ArenaIsClosed();
    if (msg.value < arenaFee) revert InvalidArenaFee();
  }

  /**
    @notice Pick winner based on the gladiator points and dice result.
    1. Caller is the token owner.
    2. Arena is not closed.
    3. Arena fee is the same as requried.
    Will revert with InvalidGladiatorScore if gladiator scores are not on chain yet.
    Gladiator poins will be updated to on chain before every game.
    @param duel - The duel do pick a winner from.
    @return The duel winner token id.
  */
  function pickWinner(Duel memory duel) public view returns (uint256) {
    uint256 gladiator1points = _gladiator.tokenIdToGladiatorPoints(
      duel.tokenId1
    );
    uint256 gladiator2points = _gladiator.tokenIdToGladiatorPoints(
      duel.tokenId2
    );
    if (gladiator1points < 1 || gladiator2points < 1)
      revert InvalidGladiatorScore();
    uint256 combinedPoints = (gladiator1points + gladiator2points);
    uint256 gladiator1chance = (gladiator1points * 100) / combinedPoints;
    return (dice <= gladiator1chance) ? duel.tokenId1 : duel.tokenId2;
  }

  /**
    @notice Pay the winner opponents NFT and staked eth (if there is a staked prize).
    1. Transfer the winners NFT back to the winner.
    2. Transfer the opponents NFT to to winner.
    3. Transfer the winners staked eth back to the winner plus the opponents staked eth.
    @param duel - The duel do pay the winner from.
  */
  function _payWinner(Duel memory duel) private {
    address winner = duel.winner == duel.tokenId1 ? duel.owner1 : duel.owner2;
    _gladiator.transferFrom(address(this), winner, duel.tokenId1);
    _gladiator.transferFrom(address(this), winner, duel.tokenId2);
    if (duel.stake == 0) return;
    payable(winner).transfer(duel.stake * 2);
  }

  /**
    @notice Withdraw gladiator before.
    Gladiator can only be withdrawn before arena closes and if no one accepted the duel.
    Hence, the second gladiator into a duel cannot be withdrawn.
    @param _tokenId - NFT token id.
  */
  function withdrawGladiatorFromDuel(uint256 _tokenId) external {
    for (uint256 i = 0; i < duels.length; i++) {
      if (duels[i].tokenId1 == _tokenId && duels[i].tokenId2 == 0) {
        if (msg.sender != duels[i].owner1) revert NotOwner();
        duels[i].tokenId1 = 0;
        duels[i].owner1 = address(0);
        payable(msg.sender).transfer(duels[i].stake);
        _gladiator.safeTransferFrom(address(this), msg.sender, _tokenId);
        return;
      }
    }
    revert WithdrawGladiatorFailed();
  }

  /**
    @notice Withdraw funds to treasury wallet.
    Withdrawn funds will only include arena fees.
  */
  function withdrawFunds() external onlyOwner {
    if (arenaClosesAt != 0) revert ArenaMustBeClosed();
    uint256 totalStaked;
    for (uint256 i = 0; i < duels.length; i++) {
      if (duels[i].winner == 0) {
        totalStaked += duels[i].stake * (duels[i].tokenId2 != 0 ? 2 : 1);
      }
    }
    payable(treasury).transfer(address(this).balance - totalStaked);
  }

  /**
    @notice Get duels as a list.
    @return duels
  */
  function getDuels() external view returns (Duel[] memory) {
    return duels;
  }

  /**
  @notice Set the treasury team wallet address.
 */
  function setTreasury(address payable _treasury) external onlyOwner {
    treasury = _treasury;
  }

  /**
    @notice ERC721 override function.
    To make the smart contract able to receive NFTs.
  */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /**
    @notice VRFCoordinatorV2Interface override function.
    Callback from Chainlink with a random number.
  */
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    dice = (randomWords[0] % 100) + 1;
    emit DiceResult(dice);
  }
}