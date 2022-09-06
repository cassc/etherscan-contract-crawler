// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IWebaverseLand.sol";

/**
 *
 * @dev Inheritance details:
 *      ERC721            ERC721 token standard, imported from openzeppelin
 *      Pausable          Allows functions to be Paused, note that this contract includes the metadrop
 *                        time-limited pause, where the contract can only be paused for a defined time period.
 *                        Imported from openzeppelin.
 *      Ownable           Allow priviledged access to certain functions. Imported from openzeppelin.
 *      ERC721Burnable    Helper library for convenient burning of ERC721s. Imported from openzeppelin.
 *      VRFConsumerBaseV2   Chainlink RNG contract. Imported from chainlink.
 *
 */
contract WebaverseGenesisPass is
  ERC721,
  Pausable,
  Ownable,
  ERC721Burnable,
  VRFConsumerBaseV2
{
  using SafeERC20 for IERC20;
  using Strings for uint256;

  /**
   * @dev Chainlink config.
   */
  VRFCoordinatorV2Interface vrfCoordinator;
  uint64 vrfSubscriptionId;
  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 vrfKeyHash;
  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 vrfCallbackGasLimit = 150000;
  // The default is 3, but you can set this higher.
  uint16 vrfRequestConfirmations = 3;
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 vrfNumWords = 1;

  uint256 public immutable maxSupply;
  uint256 public immutable numberOfCommunities;
  uint256 public immutable mintPrice;
  uint256 public immutable maxCommunityWhitelistLength;
  uint256 public immutable whitelistMintStart;
  uint256 public immutable whitelistMintEnd;
  address payable public immutable beneficiaryAddress;

  string private _tokenBaseURI;
  string public placeholderTokenURI;

  uint256 public communityRandomness;

  uint256 private _royaltyPercentageBasisPoints;

  uint256 public tokenIdCounter;

  uint256 public burnCounter;

  // Slot size (32 + 160 + 8 + 8 + 8 = 216)
  // ERC-2981: NFT Royalty Standard
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  address private _royaltyReceipientAddress;
  bool public tokenBaseURILocked;
  bool public listsLocked;
  bool public webaverseLandAddressLocked;
  bool public placeholderTokenURILocked;

  // Claim whitelist merkle root - for auction
  // hash(quantity, address)
  bytes32 public claimWhitelistMerkleRoot;
  mapping(address => bool) private _claimHasMinted;

  // Treasury whitelist merkle root - for metadrop & webaverse treasury
  // hash(quantity, address)
  bytes32 public treasuryWhitelistMerkleRoot;
  mapping(address => uint256) private _treasuryAllocationMinted;

  // Direct whitelist merkle root
  // hash(position, address)
  bytes32 public directWhitelistMerkleRoot;

  // Community whitelist merkle root
  // hash(community, position, address)
  bytes32 public communityWhitelistMerkleRoot;
  // Community ID => Community whitelist merkle length
  mapping(uint256 => uint256) public communityWhitelistLengths;

  // Completion whitelist merkle root
  // hash(quantity, address, unitPrice)
  bytes32 public completionWhitelistMerkleRoot;
  mapping(address => uint256) private _completionAllocationMinted;

  uint256 public pauseCutoffDays;

  // Single bool for first stage mint (direct and community) - each
  // address can only mint once, regardless of multiple eligibility:
  mapping(address => bool) private _firstStageAddressHasMinted;

  // Webaverse Land contract address:
  address public webaverseLandAddress;

  /**
   *
   * @dev constructor: Must be passed following addresses:
   *                   * chainlink VRF address and Link token address
   *
   */
  constructor(
    // configIntegers array must contain the following:
    // [0]: numberOfCommunities (e.g. 7)
    // [1]: maxCommunityWhitlistLength (how many slots are open per community, beyond which we 'lottery' using a randon start position)
    // [2]: whitelistMintStart (timestamp of when the stage 1 mint will start)
    // [3]: pauseCutoffDays (when the ability to pause this contract expires)
    uint256[] memory configIntegers_,
    uint256 maxSupply_,
    uint256 mintPrice_,
    address royaltyReceipientAddress_,
    uint256 royaltyPercentageBasisPoints_,
    address vrfCoordinator_,
    bytes32 vrfKeyHash_,
    address payable beneficiaryAddress_
  )
    ERC721("Webaverse Genesis Pass", "WEBA")
    VRFConsumerBaseV2(vrfCoordinator_)
  {
    numberOfCommunities = configIntegers_[0];
    maxCommunityWhitelistLength = configIntegers_[1];
    whitelistMintStart = configIntegers_[2];
    pauseCutoffDays = configIntegers_[3];
    whitelistMintEnd = whitelistMintStart + 2 days;

    maxSupply = maxSupply_;
    mintPrice = mintPrice_;
    _royaltyReceipientAddress = royaltyReceipientAddress_;
    _royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;
    vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
    vrfKeyHash = vrfKeyHash_;
    beneficiaryAddress = beneficiaryAddress_;
  }

  /**
   *
   * @dev WebaverseVotes: Emit the votes cast with this mint to be tallied off-chain.
   *
   */
  event WebaverseVotes(address voter, uint256 quantityMinted, uint256[] votes);

  /**
   *
   * @dev Only allow when stage 1 whitelist minting is open:
   *
   */
  modifier whenStage1MintingOpen() {
    require(stage1MintingOpen(), "Stage 1 mint closed");
    require(communityRandomness != 0, "Community randomness not set");
    _;
  }

  /**
   *
   * @dev whenListsUnlocked: restrict access to when the lists are unlocked.
   * This allows the owner to effectively end new minting, with eligibility
   * fixed to the details on the merkle roots (and associated lists) already
   * saved in storage
   *
   */
  modifier whenListsUnlocked() {
    require(!listsLocked, "Lists locked");
    _;
  }

  /**
   *
   * @dev whenLandAddressUnlocked: the webaverse land address cannot be
   * updated after it has been locked
   *
   */
  modifier whenLandAddressUnlocked() {
    require(!webaverseLandAddressLocked, "Land address locked");
    _;
  }

  /**
   *
   * @dev whenPlaceholderURIUnlocked: the placeholder URI cannot be
   * updated after it has been locked
   *
   */
  modifier whenPlaceholderURIUnlocked() {
    require(!placeholderTokenURILocked, "Place holder URI locked");
    _;
  }

  /**
   *
   * @dev whenSupplyRemaining: Supply is controlled by lists and cannot be exceeded, but as
   * an explicity and clear control we check here that the mint operation requested will not
   * exceed the max supply.
   *
   */
  modifier whenSupplyRemaining(uint256 quantity_) {
    require((tokenIdCounter + quantity_) <= maxSupply, "Max supply exceeded");
    _;
  }

  /**
   *
   * @dev stage1MintingOpen: View of whether stage 1 mint is open
   *
   */
  function stage1MintingOpen() public view returns (bool) {
    return
      block.timestamp > (whitelistMintStart - 1) &&
      block.timestamp < (whitelistMintEnd + 1);
  }

  /**
   *
   * @dev isStage1MintingEnded: View of whether stage 1 mint is ended
   *
   */
  function stage1MintingEnded() public view returns (bool) {
    return block.timestamp > whitelistMintEnd;
  }

  /**
   * totalSupply is the number of tokens minted (value tokenIdCounter, as this is 0
   * indexed by always set to the next ID it will issue) minus burned
   */
  function totalSupply() public view returns (uint256) {
    return tokenIdCounter - burnCounter;
  }

  /**
   *
   * @dev getRandomNumber: Requests randomness.
   *
   */
  function getRandomNumber() public onlyOwner returns (uint256) {
    require(communityWhitelistMerkleRoot != 0, "Community list not set");
    require(communityRandomness == 0, "Randomness set");
    return
      vrfCoordinator.requestRandomWords(
        vrfKeyHash,
        vrfSubscriptionId,
        vrfRequestConfirmations,
        vrfCallbackGasLimit,
        vrfNumWords
      );
  }

  /**
   *
   * @dev fulfillRandomWords: Callback function used by VRF Coordinator.
   * This function is used to generate random values used in community & claim minting
   *
   */
  function fulfillRandomWords(uint256, uint256[] memory randomWords_)
    internal
    override
  {
    require(communityRandomness == 0, "Randomness set");
    communityRandomness = randomWords_[0];
  }

  /**
   *
   * @dev setVRFSubscriptionId: Set the chainlink subscription id.
   *
   */
  function setVRFSubscriptionId(uint64 vrfSubscriptionId_) external onlyOwner {
    vrfSubscriptionId = vrfSubscriptionId_;
  }

  /**
   *
   * @dev withdrawContractBalance: A withdraw function to allow ETH balance to be withdrawn to the beneficiary address
   * set in the constructor
   *
   */
  function withdrawContractBalance() external onlyOwner {
    (bool success, ) = beneficiaryAddress.call{value: address(this).balance}(
      ""
    );
    require(success, "Transfer failed");
  }

  /**
   *
   * @dev receive: Handles receiving ether to the contract. Reject all direct payments to the contract except from beneficiary and owner.
   * set in the constructor
   *
   */
  receive() external payable {
    require(msg.value > 0, "No ETH");
    require(
      msg.sender == beneficiaryAddress || msg.sender == owner(),
      "Only owner or beneficiary"
    );
  }

  /**
   *
   * @dev transferERC20Token: A withdraw function to avoid locking ERC20 tokens in the contract forever.
   * Tokens can only be withdrawn by the owner, to the owner.
   *
   */
  function transferERC20Token(IERC20 token, uint256 amount) public onlyOwner {
    token.safeTransfer(owner(), amount);
  }

  /**
   *
   * @dev pause: Allow owner to pause.
   *
   */
  function pause() public onlyOwner {
    require(
      whitelistMintStart == 0 ||
        block.timestamp < (whitelistMintStart + pauseCutoffDays * 1 days),
      "Pause cutoff passed"
    );
    _pause();
  }

  /**
   *
   * @dev unpause: Allow owner to unpause.
   *
   */
  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   *
   * @dev lockLists: Prevent any further changes to list merkle roots.
   *
   */
  function lockLists() public onlyOwner {
    listsLocked = true;
  }

  /**
   *
   * @dev lockLandAddress: Prevent any further changes to the webaverse land contract address.
   *
   */
  function lockLandAddress() public onlyOwner {
    webaverseLandAddressLocked = true;
  }

  /**
   *
   * @dev setLandAddress: Set the root for the auction claims.
   *
   */
  function setLandAddress(address webaverseLandAddress_)
    external
    onlyOwner
    whenLandAddressUnlocked
  {
    webaverseLandAddress = webaverseLandAddress_;
  }

  /**
   *
   * @dev lockPlaceholderTokenURI: Prevent any further changes to the placeholder URI.
   *
   */
  function lockPlaceholderTokenURI() public onlyOwner {
    placeholderTokenURILocked = true;
  }

  /**
   *
   * @dev setPlaceholderTokenURI: Set the string for the placeholder
   * token URI.
   *
   */
  function setPlaceholderTokenURI(string memory placeholderTokenURI_)
    external
    onlyOwner
    whenPlaceholderURIUnlocked
  {
    placeholderTokenURI = placeholderTokenURI_;
  }

  /**
   *
   * @dev setDirectWhitelist: Set the initial data for the direct list mint.
   *
   */
  function setDirectWhitelist(bytes32 directWhitelistMerkleRoot_)
    external
    whenListsUnlocked
    onlyOwner
  {
    directWhitelistMerkleRoot = directWhitelistMerkleRoot_;
  }

  /**
   *
   * @dev setCommunityWhitelist: Set the initial data for the community mint.
   *
   */
  function setCommunityWhitelist(
    uint256[] calldata communityWhitelistLengths_,
    bytes32 communityWhitelistMerkleRoot_
  ) external whenListsUnlocked onlyOwner {
    require(
      communityWhitelistLengths_.length == numberOfCommunities,
      "Community length doesnt match"
    );

    communityWhitelistMerkleRoot = communityWhitelistMerkleRoot_;

    for (
      uint256 communityId = 0;
      communityId < numberOfCommunities;
      communityId++
    ) {
      communityWhitelistLengths[communityId] = communityWhitelistLengths_[
        communityId
      ];
    }
  }

  /**
   *
   * @dev setClaimWhitelistMerkleRoot: Set the root for the auction claims.
   *
   */
  function setClaimWhitelistMerkleRoot(bytes32 claimWhitelistMerkleRoot_)
    external
    whenListsUnlocked
    onlyOwner
  {
    claimWhitelistMerkleRoot = claimWhitelistMerkleRoot_;
  }

  /**
   *
   * @dev setTreasuryWhitelistMerkleRoot: Set the root for the treasury claims (metadrop + webaverse allocations).
   *
   */
  function setTreasuryWhitelistMerkleRoot(bytes32 treasuryWhitelistMerkleRoot_)
    external
    whenListsUnlocked
    onlyOwner
  {
    treasuryWhitelistMerkleRoot = treasuryWhitelistMerkleRoot_;
  }

  /**
   *
   * @dev setCompletionWhitelistMerkleRoot: Set the root for completion mints.
   *
   */
  function setCompletionWhitelistMerkleRoot(
    bytes32 completionWhitelistMerkleRoot_
  ) external whenListsUnlocked onlyOwner {
    completionWhitelistMerkleRoot = completionWhitelistMerkleRoot_;
  }

  /**
   *
   * @dev _getCommunityHash: Get hash of information for the community mint.
   *
   */
  function _getCommunityHash(
    uint256 community_,
    uint256 position_,
    address minter_
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(community_, position_, minter_));
  }

  /**
   *
   * @dev _getDirectHash: Get hash of information for mints for direct list.
   *
   */
  function _getDirectHash(address minter_) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(minter_));
  }

  /**
   *
   * @dev _getClaimAndTreasuryHash: Get hash of information for mints from the auction (claims).
   * Also the same hash format as the treasury whitelist, used for treasuryWhitelistMerkleRoot too
   *
   */
  function _getClaimAndTreasuryHash(uint256 quantity_, address minter_)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(quantity_, minter_));
  }

  /**
   *
   * @dev _getCompletionHash: Get hash of information for mints from the auction (claims).
   * Also the same hash format as the treasury whitelist, used for treasuryWhitelistMerkleRoot too
   *
   */
  function _getCompletionHash(
    uint256 quantity_,
    address minter_,
    uint256 unitPrice_
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(quantity_, minter_, unitPrice_));
  }

  /**
   *
   * @dev isValidPosition: Check is this is a valid position for this community allowlist. There are
   * 1,000 positions per community. If more than 1,000 have registered a random start position in the
   * allowlist is used to determine eligibility.
   *
   */
  function isValidPosition(uint256 position_, uint256 community_)
    internal
    view
    returns (bool)
  {
    uint256 communityWhitelistLength = communityWhitelistLengths[community_];
    require(communityWhitelistLength > 0, "Length not set");

    if (communityWhitelistLength > maxCommunityWhitelistLength) {
      // Find the random starting point somewhere in the whitelist length array
      uint256 startPoint = communityRandomness % communityWhitelistLength;
      uint256 endPoint = startPoint + maxCommunityWhitelistLength;
      // If the valid range exceeds the length of the whitelist, it must roll over
      if (endPoint > communityWhitelistLength) {
        return
          position_ >= startPoint ||
          position_ < endPoint - communityWhitelistLength;
      } else {
        return position_ >= startPoint && position_ < endPoint;
      }
    } else {
      return true;
    }
  }

  /**
   *
   * @dev _checkTheVote: check the count of votes = the quantity minted:
   *
   */
  function _checkTheVote(uint256[] memory votesToCount_, uint256 quantity_)
    internal
    view
  {
    // (1) Check that we have been passed the right number of community votes in the array:
    require(
      votesToCount_.length == numberOfCommunities,
      "Vote array does not match community count"
    );

    // (2) Check that the total votes matches the mint quantity:
    uint256 totalVotes;
    for (uint256 i = 0; i < votesToCount_.length; i++) {
      totalVotes += votesToCount_[i];
    }
    require(totalVotes == quantity_, "Votes do not match minting quantity");
  }

  /**
   *
   * @dev communityMint: Minting of community allocations from the allowlist.
   *
   */
  function communityMint(
    uint256 community_,
    uint256 position_,
    bytes32[] calldata proof_,
    uint256[] calldata votes_
  ) external payable whenStage1MintingOpen whenSupplyRemaining(1) {
    require(msg.value == mintPrice, "Insufficient ETH passed");

    require(communityWhitelistMerkleRoot != 0, "Community merkle root not set");

    // Check the total votes passed equals the minted quantity:
    _checkTheVote(votes_, 1);

    bytes32 leaf = _getCommunityHash(community_, position_, msg.sender);

    require(
      MerkleProof.verify(proof_, communityWhitelistMerkleRoot, leaf),
      "Community mint proof invalid"
    );

    require(
      isValidPosition(position_, community_),
      "This position has missed out"
    );

    _performDirectAndCommunityMint(msg.sender, votes_);
  }

  /**
   *
   * @dev directMint:  Mint allocations from the webaverse direct allowlist
   *
   */
  function directMint(bytes32[] calldata proof_, uint256[] calldata votes_)
    external
    payable
    whenStage1MintingOpen
    whenSupplyRemaining(1)
  {
    require(msg.value == mintPrice, "Insufficient ETH passed");

    require(directWhitelistMerkleRoot != 0, "Direct merkle root not set");

    // Check the total votes passed equals the minted quantity:
    _checkTheVote(votes_, 1);

    bytes32 leaf = _getDirectHash(msg.sender);

    require(
      MerkleProof.verify(proof_, directWhitelistMerkleRoot, leaf),
      "Direct mint proof invalid"
    );

    _performDirectAndCommunityMint(msg.sender, votes_);
  }

  /**
   *
   * @dev claimMint: Whitelist proof is generated from quantity and address
   *
   */
  function claimMint(
    uint256 quantityToMint_,
    bytes32[] calldata proof_,
    uint256[] calldata votes_
  ) public whenSupplyRemaining(quantityToMint_) {
    require(claimWhitelistMerkleRoot != 0, "Mint merkle root not set");

    // Check the total votes passed equals the minted quantity:
    _checkTheVote(votes_, quantityToMint_);

    bytes32 leaf = _getClaimAndTreasuryHash(quantityToMint_, msg.sender);

    require(
      MerkleProof.verify(proof_, claimWhitelistMerkleRoot, leaf),
      "Claim mint proof invalid"
    );

    require(!_claimHasMinted[msg.sender], "Claim: Address has already minted");

    _claimHasMinted[msg.sender] = true;

    _batchMint(msg.sender, quantityToMint_);

    emit WebaverseVotes(msg.sender, quantityToMint_, votes_);
  }

  /**
   *
   * @dev treasuryMint: Mint function for metadrop & webaverse treasury + other parties
   *
   */
  function treasuryMint(
    uint256 quantityEligible_,
    bytes32[] calldata proof_,
    uint256 quantityToMint_
  ) public whenSupplyRemaining(quantityToMint_) {
    require(treasuryWhitelistMerkleRoot != 0, "Mint merkle root not set");

    bytes32 leaf = _getClaimAndTreasuryHash(quantityEligible_, msg.sender);

    require(
      MerkleProof.verify(proof_, treasuryWhitelistMerkleRoot, leaf),
      "Treasury: mint proof invalid"
    );

    require(
      (_treasuryAllocationMinted[msg.sender] + quantityToMint_) <=
        quantityEligible_,
      "Treasury: Requesting more than remaining allocation"
    );

    _treasuryAllocationMinted[msg.sender] += quantityToMint_;

    _batchMint(msg.sender, quantityToMint_);
  }

  /**
   *
   * @dev completionMint
   *
   */
  function completionMint(
    uint256 quantityEligible_,
    bytes32[] calldata proof_,
    uint256 quantityToMint_,
    uint256 unitPrice_
  ) public payable whenSupplyRemaining(quantityToMint_) {
    require(
      msg.value == (quantityToMint_ * unitPrice_),
      "Insufficient ETH passed"
    );

    require(
      completionWhitelistMerkleRoot != 0,
      "Completion merkle root not set"
    );

    bytes32 leaf = _getCompletionHash(
      quantityEligible_,
      msg.sender,
      unitPrice_
    );

    require(
      MerkleProof.verify(proof_, completionWhitelistMerkleRoot, leaf),
      "Completion: mint proof invalid"
    );

    require(
      (_completionAllocationMinted[msg.sender] + quantityToMint_) <=
        quantityEligible_,
      "Completion: Requesting more than remaining allocation"
    );

    _completionAllocationMinted[msg.sender] += quantityToMint_;

    _batchMint(msg.sender, quantityToMint_);
  }

  /**
   *
   * @dev _performDirectAndCommunityMint:  Unified processing for direct and community mint
   *
   */
  function _performDirectAndCommunityMint(
    address minter_,
    uint256[] calldata votes_
  ) internal {
    require(
      !_firstStageAddressHasMinted[minter_],
      "Community and Direct: Address has already minted"
    );

    _firstStageAddressHasMinted[minter_] = true;

    _safeMint(minter_, tokenIdCounter);
    tokenIdCounter += 1;

    emit WebaverseVotes(minter_, 1, votes_);
  }

  /**
   *
   * @dev _batchMint:  Unified processing for treasury, claim and completion mint
   *
   */
  function _batchMint(address minter_, uint256 quantity_) internal {
    uint256 tempTokenIdCounter = tokenIdCounter;
    for (uint256 i = 0; i < quantity_; i++) {
      _safeMint(minter_, tempTokenIdCounter);
      tempTokenIdCounter += 1;
    }
    tokenIdCounter = tempTokenIdCounter;
  }

  /**
   *
   * @dev setRoyaltyPercentageBasisPoints: allow the owner to set the base royalty percentage.
   *
   */
  function setRoyaltyPercentageBasisPoints(
    uint256 royaltyPercentageBasisPoints_
  ) external onlyOwner {
    _royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;
  }

  /**
   *
   * @dev setRoyaltyReceipientAddress: Allow the owner to set the royalty recipient.
   *
   */
  function setRoyaltyReceipientAddress(
    address payable royaltyReceipientAddress_
  ) external onlyOwner {
    _royaltyReceipientAddress = royaltyReceipientAddress_;
  }

  /**
   *
   * @dev setTokenBaseURI: Allow the owner to set the base token URI
   *
   */
  function setTokenBaseURI(string calldata tokenBaseURI_) external onlyOwner {
    require(!tokenBaseURILocked, "Token base URI is locked");
    _tokenBaseURI = tokenBaseURI_;
  }

  /**
   *
   * @dev lockTokenBaseURI: allow the owner to lock the base token URI, after which the URI cannot be altered.
   *
   */
  function lockTokenBaseURI() external onlyOwner {
    require(!tokenBaseURILocked, "Token base URI is locked");
    tokenBaseURILocked = true;
  }

  /**
   *
   * @dev royaltyInfo: Returns recipent address and royalty.
   *
   */
  function royaltyInfo(uint256, uint256 salePrice_)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    uint256 royalty = (salePrice_ * _royaltyPercentageBasisPoints) / 10000;
    return (_royaltyReceipientAddress, royalty);
  }

  /**
   *
   * @dev _baseURI: returns the URI
   *
   */
  function _baseURI() internal view override returns (string memory) {
    return _tokenBaseURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    // If there is a land contract address set, use that address to retrieve the tokenURI:
    if (webaverseLandAddress != address(0)) {
      // Call the contract to return the token URI for this token ID:
      return IWebaverseLand(webaverseLandAddress).uriForToken(tokenId);

      // See if we have a token base URI set:
    } else if (bytes(_tokenBaseURI).length != 0) {
      // Return tokenBaseURI appended with the tokenId number:
      return
        string(abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json"));

      // If neither of the above, use the placeholder URI
    } else {
      // The placeholder URI is the same for all tokenIds:
      return placeholderTokenURI;
    }
  }

  /**
   *
   * @dev _beforeTokenTransfer: function called before tokens are transfered.
   *
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   *
   * @dev supportsInterface: ERC2981 interface support.
   *
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721)
    returns (bool)
  {
    return
      interfaceId == _INTERFACE_ID_ERC2981 ||
      super.supportsInterface(interfaceId);
  }

  /**
   * ============================
   * Web app eligibility getters:
   * ============================
   */

  /**
   *
   * @dev eligibleForCommunityMint: Eligibility check for the COMMUNITY mint. This can be called from front-end (for example to control
   * screen components that indicate if the connected address is eligible).
   *
   * Function flow is as follows:
   * (1) Check that the position, community and address are in the allowlist.
   * (2) Check if this leaf has already minted. If so, exit with false eligibility and reason "Sender has already minted for this community"
   * (3) Check if this leaf is in a valid position in the allowlist. If not, exit with false eligilibity and reason "This position has missed out"
   * (4) All checks passed, return elibility = true, the delivery address and valid leaf.
   *
   */
  function eligibleForCommunityMint(
    address addressToCheck_,
    uint256 position_,
    uint256 community_,
    bytes32[] calldata proof_
  )
    external
    view
    returns (
      address,
      bool eligible,
      string memory reason,
      bytes32 leaf,
      address
    )
  {
    leaf = _getCommunityHash(community_, position_, addressToCheck_);

    if (
      MerkleProof.verify(proof_, communityWhitelistMerkleRoot, leaf) == false
    ) {
      return (
        addressToCheck_,
        false,
        "Community mint proof invalid",
        leaf,
        addressToCheck_
      );
    }

    if (_firstStageAddressHasMinted[addressToCheck_]) {
      return (
        addressToCheck_,
        false,
        "Community: Address has already minted",
        leaf,
        addressToCheck_
      );
    }

    if (!isValidPosition(position_, community_)) {
      return (
        addressToCheck_,
        false,
        "This position has missed out",
        leaf,
        addressToCheck_
      );
    }

    return (addressToCheck_, true, "", leaf, addressToCheck_);
  }

  /**
   *
   * @dev eligibleForDirectMint: Eligibility check for the DIRECT mint. This can be called from front-end (for example to control
   * screen components that indicate if the connected address is eligible).
   *
   * Function flow is as follows:
   * (1) Check that the position and address are in the allowlist.
   * (2) Check if this minter address has already minted. If so, exit with false eligibility and reason "Address has already minted"
   * (3) All checks passed, return elibility = true, the delivery address and valid minter adress.
   *
   */
  function eligibleForDirectMint(
    address addressToCheck_,
    bytes32[] calldata proof_
  )
    external
    view
    returns (
      address,
      address,
      bool eligible,
      string memory reason
    )
  {
    bytes32 leaf = _getDirectHash(addressToCheck_);

    if (MerkleProof.verify(proof_, directWhitelistMerkleRoot, leaf) == false) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Direct mint proof invalid"
      );
    }

    if (_firstStageAddressHasMinted[addressToCheck_]) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Direct: Address has already minted"
      );
    }

    return (addressToCheck_, addressToCheck_, true, "");
  }

  /**
   *
   * @dev eligibleForClaimMint: Eligibility check for the CLAIM mint. This can be called from front-end (for example to control
   * screen components that indicate if the connected address is eligible).
   *
   * Function flow is as follows:
   * (1) Check that the position and address are in the allowlist.
   * (2) Check if this minter address has already minted. If so, exit with false eligibility and reason "Address has already minted"
   * (3) All checks passed, return elibility = true, the delivery address and valid minter adress.
   *
   */
  function eligibleForClaimMint(
    address addressToCheck_,
    uint256 quantity_,
    bytes32[] calldata proof_
  )
    external
    view
    returns (
      address,
      address,
      bool eligible,
      string memory reason
    )
  {
    bytes32 leaf = _getClaimAndTreasuryHash(quantity_, addressToCheck_);

    if (MerkleProof.verify(proof_, claimWhitelistMerkleRoot, leaf) == false) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Claim mint proof invalid"
      );
    }

    if (_claimHasMinted[addressToCheck_]) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Claim: Address has already minted"
      );
    }

    return (addressToCheck_, addressToCheck_, true, "");
  }

  /**
   *
   * @dev eligibleForTreasuryMint: Eligibility check for the treasury mint. This can be called from front-end (for example to control
   * screen components that indicate if the connected address is eligible).
   * Function flow is as follows:
   * (1) Check that the quantityEligible and address are in the allowlist.
   * (2) Check if this minter is requesting more than its allocation. If so, exit with false eligibility and reason "Treasury: Requesting more than remaining allocation"
   * (3) All checks passed, return elibility = true, the delivery address and valid minter adress.
   *
   */
  function eligibleForTreasuryMint(
    address addressToCheck_,
    uint256 quantityEligible_,
    bytes32[] calldata proof_,
    uint256 quantityToMint_
  )
    external
    view
    returns (
      address,
      address,
      bool eligible,
      string memory reason
    )
  {
    // (2) Check the proof is valid
    bytes32 leaf = _getClaimAndTreasuryHash(quantityEligible_, addressToCheck_);

    if (
      MerkleProof.verify(proof_, treasuryWhitelistMerkleRoot, leaf) == false
    ) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Treasury: mint proof invalid"
      );
    }

    if (
      (_treasuryAllocationMinted[addressToCheck_] + quantityToMint_) >
      quantityEligible_
    ) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Treasury: Requesting more than remaining allocation"
      );
    }

    return (addressToCheck_, addressToCheck_, true, "");
  }

  /**
   *
   * @dev eligibleForCompletionMint: Eligibility check for the completion mint. This can be called from front-end (for example to control
   * screen components that indicate if the connected address is eligible).
   * Function flow is as follows:
   * (1) Check that the quantityEligible, address and unitPrice are in the allowlist.
   * (2) Check if this minter is requesting more than its allocation. If so, exit with false eligibility and reason "Treasury: Requesting more than remaining allocation"
   * (3) All checks passed, return elibility = true, the delivery address and valid minter adress.
   *
   */
  function eligibleForCompletionMint(
    address addressToCheck_,
    uint256 quantityEligible_,
    bytes32[] calldata proof_,
    uint256 quantityToMint_,
    uint256 unitPrice_
  )
    external
    view
    returns (
      address,
      address,
      bool eligible,
      string memory reason
    )
  {
    bytes32 leaf = _getCompletionHash(
      quantityEligible_,
      addressToCheck_,
      unitPrice_
    );

    if (
      MerkleProof.verify(proof_, completionWhitelistMerkleRoot, leaf) == false
    ) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Completion: mint proof invalid"
      );
    }

    if (
      (_completionAllocationMinted[addressToCheck_] + quantityToMint_) >
      quantityEligible_
    ) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Completion: Requesting more than remaining allocation"
      );
    }

    return (addressToCheck_, addressToCheck_, true, "");
  }

  /**
   * @dev Burns `tokenId`. See {ERC721-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId) public override {
    super.burn(tokenId);
    burnCounter += 1;
  }
}