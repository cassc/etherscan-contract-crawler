// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import {ERC721Psi} from './ERC721Psi.sol';
import {ERC2981Base, ERC2981ContractWideRoyalties} from './ERC2981ContractWideRoyalties.sol';
import {VRFConsumerBaseV2} from './VRFConsumerBaseV2.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ERC165} from '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {VRFCoordinatorV2Interface} from './VRFCoordinatorV2Interface.sol';

/// @notice NFTs for visitors to the WHIM stands at VeeCon and NFT.NYC.
/// @author Duffles (https://github.com/DefiMatt).
contract WHIM is
  ERC721Psi,
  ERC2981ContractWideRoyalties,
  VRFConsumerBaseV2,
  Pausable,
  Ownable
{
  using Strings for uint256;

  /*//////////////////////////////////////////////////////////////
    Enums.
  //////////////////////////////////////////////////////////////*/

  /// @notice Lifecycle management.
  enum Stage {
    /// @notice Minting hasn't started yet.
    Premint,
    /// @notice Only the owner can mint.
    OwnerMint,
    /// @notice Addresses on the allowlist can mint.
    AllowlistMint,
    /// @notice Minting has finished.
    Closed,
    /// @notice Metadata has been revealed.
    Revealed,
    /// @notice Metadata is permanently frozen.
    Frozen
  }

  /*//////////////////////////////////////////////////////////////
    Events.
  //////////////////////////////////////////////////////////////*/

  /// @notice Used by Chainlink VRF v2 to pick winning token numbers.
  event RandomToken(uint256 indexed tokenId);

  /*//////////////////////////////////////////////////////////////
    Public state.
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Base URI for computing {tokenURI}.
   *
   * @dev The URI for each token is the concatenation of the baseURI, token id
   * and '.json'.
   */
  string public baseURI;
  /// @notice Whether an address has already claimed their NFT.
  mapping(address => bool) public claimed;
  /// @notice The address of the Chainlink VRF v2 coordinator.
  VRFCoordinatorV2Interface public immutable coordinator;
  /**
   * @notice This ensures that the token ids for the legendary items cannot be
   * known in advance, even by the team.
   *
   * @dev When minting concludes and metadata is revealed, Chainlink VRF v2 will
   * provide a random offset, applied to token ids so that the metadata files
   * they map to are given by (offset + token id) mod {ERC721Psi-totalSupply}.
   */
  uint256 public offset;
  /// @notice The Merkle root used to validate addresses are on the allowlist.
  bytes32 public root;
  /**
   * @notice Allows checking the legendary tokens are correct.
   *
   * @dev N token ids will be granted legendary status. These will be determined
   * by taking the block hashes for the blocks following the contract deployment
   * block and taking each one's value in base 10 mod {ERC721Psi-totalSupply}.
   *
   * (Block hashes that generate duplicate ids will be skipped, and the process
   * will continue until all N legendary ids have been generated.)
   *
   * Until / if the metadata is frozen, legendaryTokenHash acts to ensure that
   * hypothetical changes to the legendary token ids can be spotted and reverted
   * by informing the community of their values.
   *
   * This value is the keccak256 hash of the legendary token ids in ascending
   * numerical order separated by newlines ('\n'). For example, if 218, 565,
   * 1096, 5128 and 6676 are the legendary token ids, the field value will be
   * keccak256('218\n565\n1096\n5128\n6676') =
   * 0x1cd8a88948cc5d6128719fa11a9928e55f1ceab16b5792533b24da7c2517ed9c.
   *
   * Legendary token ids will be published to allow validation. When checking
   * legendary status in the associated metadata, ensure you take {offset} into
   * consideration!
   */
  bytes32 public legendaryTokenHash;
  /// @notice The current stage in the lifecycle.
  Stage public stage;
  /**
   * @notice URI for {tokenURI} before the reveal.
   */
  string public unrevealedURI;

  /*//////////////////////////////////////////////////////////////
    Constructor.
  //////////////////////////////////////////////////////////////*/

  /**
   * @param _coordinator The address of the Chainlink VRF v2 coordinator.
   * @param royaltyReceiver Address to receive royalty payments.
   * @param royaltyAmount Permyriadage / basis points (‱) of sale amounts to be
   * paid as royalties.
   * @param _unrevealedURI URI for {tokenURI} before the reveal.
   */
  constructor(
    VRFCoordinatorV2Interface _coordinator,
    address royaltyReceiver,
    uint256 royaltyAmount,
    string memory _unrevealedURI
  ) ERC721Psi('WHIM', 'WHIM') VRFConsumerBaseV2(address(_coordinator)) {
    coordinator = _coordinator;
    _setRoyalties(royaltyReceiver, royaltyAmount);
    unrevealedURI = _unrevealedURI;
  }

  /*//////////////////////////////////////////////////////////////
    Modifiers.
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Enforce the current lifecycle stage positively.
   *
   * @param _stage The stage in the lifecycle the contract must be in.
   */
  modifier inStage(Stage _stage) {
    require(stage == _stage, 'Wrong stage');
    _;
  }

  /**
   * @notice Enforce the current lifecycle stage negatively.
   *
   * @param _stage The stage in the lifecycle the contract must *not* be in.
   */
  modifier notInStage(Stage _stage) {
    require(stage != _stage, 'Wrong stage');
    _;
  }

  /*//////////////////////////////////////////////////////////////
    Privileged functions.
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Move the to the {Stage.OwnerMint} stage of the lifecycle.
   *
   * @dev Can only be used:
   * - By the owner.
   * - When unpaused.
   * - In {Stage.Premint} stage of the lifecycle.
   */
  function moveToOwnerMint()
    external
    onlyOwner
    whenNotPaused
    inStage(Stage.Premint)
  {
    stage = Stage.OwnerMint;
  }

  /**
   * @notice Move the to the {Stage.AllowlistMint} stage of the lifecycle.
   *
   * @dev Can only be used:
   * - By the owner.
   * - When unpaused.
   * - In {Stage.OwnerMint} stage of the lifecycle.
   *
   * @param _root New non-zero value for {root}.
   */
  function moveToAllowlistMint(bytes32 _root)
    external
    onlyOwner
    whenNotPaused
    inStage(Stage.OwnerMint)
  {
    require(bytes32(0) != _root, 'Invalid root');

    root = _root;

    stage = Stage.AllowlistMint;
  }

  /**
   * @notice Move the to the {Stage.Closed} stage of the lifecycle.
   *
   * @dev Can only be used:
   * - By the owner.
   * - When unpaused.
   * - In {Stage.AllowlistMint} stage of the lifecycle.
   */
  function moveToClosed()
    external
    onlyOwner
    whenNotPaused
    inStage(Stage.AllowlistMint)
  {
    stage = Stage.Closed;
  }

  /**
   * @notice Move the to the {Stage.Frozen} stage of the lifecycle.
   *
   * @dev Can only be used:
   * - By the owner.
   * - When unpaused.
   * - In {Stage.Revealed} stage of the lifecycle.
   */
  function moveToFrozen()
    external
    onlyOwner
    whenNotPaused
    inStage(Stage.Revealed)
  {
    stage = Stage.Frozen;
  }

  /**
   * @notice Mint an arbitrary number of tokens to an arbitrary address.
   *
   * @dev Can only be used:
   * - By the owner.
   * - When unpaused.
   * - In {Stage.OwnerMint} stage of the lifecycle.
   *
   * @param to Address to mint the tokens to.
   * @param amount Number of tokens to mint.
   */
  function ownerMint(address to, uint256 amount)
    external
    onlyOwner
    whenNotPaused
    inStage(Stage.OwnerMint)
  {
    _mint(to, amount);
  }

  /**
   * @notice Pause any functions in the contract marked with the
   * {Pausable-whenNotPaused} modifier.
   *
   * @dev Can only be used:
   * - By the owner.
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Reveal the metadata!
   *
   * @dev Ensures fairness by requesting that Chainlink VRF v2 provide a random
   * {offset}.
   *
   * @dev NB Do not re-request randomness even if you do not receive an answer
   * right away. Doing so would give the VRF service provider the option to
   * withhold a VRF fulfillment, if it doesn't like the outcome, and wait for
   * the re-request in the hopes that it gets a better outcome.
   *
   * @dev Can only be used:
   * - By the owner.
   * - When unpaused.
   * - In {Stage.Closed} stage of the lifecycle.
   *
   * @param newBaseURI The new {baseURI}.
   * @param _legendaryTokenHash The {legendaryTokenHash} that allows checking
   * the legendary tokens are correct. NB Once the VRF callback has occurred,
   * this cannot be set again, so make sure it's correct!
   * @param keyHash Corresponds to a particular oracle job which uses that key
   * for generating the VRF proof. Different keyHashes have different gas price
   * ceilings, so selecting a specific one bounds the maximum per-request cost.
   * @param subscription The id of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks the oracle will wait
   * before responding to the request.
   * @param callbackGasLimit - How much gas to receive in the
   * {fulfillRandomWords} callback.
   * @param numWords - The number of uint256 random values to receive in the
   * {fulfillRandomWords} callback.
   */
  function reveal(
    string calldata newBaseURI,
    bytes32 _legendaryTokenHash,
    bytes32 keyHash,
    uint64 subscription,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external onlyOwner whenNotPaused inStage(Stage.Closed) {
    baseURI = newBaseURI;
    legendaryTokenHash = _legendaryTokenHash;

    coordinator.requestRandomWords(
      keyHash,
      subscription,
      minimumRequestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

  /**
   * @notice Change {baseURI}.
   *
   * @dev Can only be used:
   * - By the owner.
   * - When unpaused.
   * - When not in the {Stage.Frozen} stage of the lifecycle.
   *
   * @param newBaseURI The new {baseURI}.
   */
  function setBaseURI(string memory newBaseURI)
    external
    onlyOwner
    whenNotPaused
    notInStage(Stage.Frozen)
  {
    baseURI = newBaseURI;
  }

  /**
   * @notice Change {root}.
   *
   * @dev Can only be used:
   * - By the owner.
   * - When unpaused.
   *
   * @param _root The new {root}.
   */
  function setRoot(bytes32 _root) external onlyOwner whenNotPaused {
    root = _root;
  }

  /**
   * @notice Change royalties (see {ERC2981ContractWideRoyalties-royaltyInfo}).
   *
   * @dev Can only be used:
   * - By the owner.
   * - When unpaused.
   *
   * @param royaltyReceiver Address to receive royalty payments.
   * @param royaltyAmount Permyriadage / basis points (‱) of sale amounts to be
   * paid as royalties.
   */
  function setRoyalties(address royaltyReceiver, uint256 royaltyAmount)
    external
    onlyOwner
    whenNotPaused
  {
    _setRoyalties(royaltyReceiver, royaltyAmount);
  }

  /**
   * @notice Change {unrevealedURI}.
   *
   * @dev Can only be used:
   * - By the owner.
   * - When unpaused.
   *
   * @param _unrevealedURI URI for {tokenURI} before the reveal.
   */
  function setUnrevealedURI(string memory _unrevealedURI)
    external
    onlyOwner
    whenNotPaused
  {
    unrevealedURI = _unrevealedURI;
  }

  /**
   * @notice Unpause any functions in the contract marked with the
   * {Pausable-whenNotPaused} modifier.
   *
   * @dev Can only be used:
   * - By the owner.
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /*//////////////////////////////////////////////////////////////
    Public functions.
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Mint an NFT to the sender.
   *
   * @dev Can only be used:
   * - When unpaused.
   * - In {Stage.AllowlistMint} stage of the lifecycle.
   *
   * @param _proof How to climb the tree.
   */
  function mint(bytes32[] calldata _proof)
    external
    whenNotPaused
    inStage(Stage.AllowlistMint)
  {
    require(!claimed[msg.sender], 'Already claimed');
    require(
      MerkleProof.verify(_proof, root, keccak256(abi.encodePacked(msg.sender))),
      'Not allowlisted'
    );

    claimed[msg.sender] = true;
    _mint(msg.sender, 1);
  }

  /*//////////////////////////////////////////////////////////////
    View functions.
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the URI for the token with id `tokenId`.
   *
   * @dev Returns {unrevealedURI} pre-reveal, and the concatenation of
   * {baseURI}, ({offset} + `tokenId`) mod {ERC721Psi-totalSupply} and '.json'
   * post-reveal (see {offset} and {baseURI} for more details).
   *
   * @param tokenId The token id to get the URI for.
   * @return The URI for the token.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), 'Token does not exist');

    return
      stage < Stage.Revealed
        ? unrevealedURI
        : string(
          abi.encodePacked(
            baseURI,
            ((tokenId + offset) % totalSupply()).toString(),
            '.json'
          )
        );
  }

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Psi, ERC2981Base)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /*//////////////////////////////////////////////////////////////
    Callbacks.
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Handles the Chainlink VRF v2 response and sets {offset}.
   *
   * @dev Because this function can only be called in the {Stage.Closed} stage
   * of the lifecycle, and it sets the lifecycle stage to {Stage.Revealed}, this
   * callback can only be executed once. This makes the {offset} permanent.
   *
   * @dev Can only be used:
   * - By the Chainlink VRF v2 coordinator (verified in
   * {VRFConsumerBaseV2-rawFulfillRandomWords}).
   * - In {Stage.Closed} stage of the lifecycle.
   *
   * @param randomWords The VRF output expanded to the requested number of
   * words. The first word is used to set {offset}.
   */
  function fulfillRandomWords(uint256, uint256[] memory randomWords)
    internal
    override
    inStage(Stage.Closed)
  {
    stage = Stage.Revealed;

    uint256 _offset = randomWords[0];
    uint256 _totalSupply = totalSupply();

    /*
     * Prevents overflow when calculating {tokenURI} if VRF returns a
     * particularly large number.
     */
    unchecked {
      if (_offset + _totalSupply < _offset) _offset -= _totalSupply;
    }

    offset = _offset;

    uint256 length = randomWords.length;

    for (uint256 i = 1; i < length; ++i) {
      emit RandomToken(randomWords[i] % _totalSupply);
    }
  }
}