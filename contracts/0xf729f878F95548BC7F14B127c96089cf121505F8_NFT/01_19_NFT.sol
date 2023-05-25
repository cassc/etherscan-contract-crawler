// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFT is ERC721, Pausable, Ownable, ERC721Burnable, VRFConsumerBase {
  using SafeERC20 for IERC20;

  // ERC-2981: NFT Royalty Standard
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  uint256 public immutable maxSupply;
  uint256 public pauseCutoffDays;
  uint256 public mintWhitelistSetTime;

  string private _tokenBaseURI;
  bool private _tokenBaseURILocked;
  uint256 private _randomness;
  bool private _randomnessHasBeenSet;
  address private _royaltyReceipientAddress;
  uint256 private _royaltyPercentageBasisPoints;

  // Chainlink configuration.
  bytes32 internal keyHash;
  uint256 internal fee;

  // Merkle root mint whitelist
  // hash(address, [inputIndexes]) // use inputIndexes as input to random function (with chainlink) to get the offset -> tokenId
  bytes32 public mintWhitelistMerkleRoot;

  bytes32 public metadataHash;

  //Mint address => hasMinted
  mapping(address => bool) private _hasMinted;

  event MetadataHashSet(bytes32 metadataHash);

  constructor(
    uint256 maxSupply_,
    address royaltyReceipientAddress_,
    uint256 royaltyPercentageBasisPoints_,
    address[] memory chainlinkAddresses_,
    bytes32 keyHash_,
    uint256 fee_,
    uint256 pauseCutoffDays_
  )
    ERC721("Anata NFT", "ANATA")
    VRFConsumerBase(chainlinkAddresses_[0], chainlinkAddresses_[1])
  {
    maxSupply = maxSupply_;
    _royaltyReceipientAddress = royaltyReceipientAddress_;
    _royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;
    keyHash = keyHash_;
    fee = fee_;
    pauseCutoffDays = pauseCutoffDays_;
  }

  function setMetadataHash(bytes32 metadataHash_) external onlyOwner {
    metadataHash = metadataHash_;
    emit MetadataHashSet(metadataHash_);
  }

  function getRandomness() public view returns (uint256) {
    return _randomness;
  }

  function getRandomnessHasBeenSet() public view returns (bool) {
    return _randomnessHasBeenSet;
  }

  // Requests randomness.
  function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
    require(!_randomnessHasBeenSet);
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
    return requestRandomness(keyHash, fee);
  }

  // Callback function used by VRF Coordinator.
  // This function is used to generate a random seed value to be used as the offset for minting.
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal
    override
  {
    require(!_randomnessHasBeenSet);
    _randomness = randomness;
    _randomnessHasBeenSet = true;
  }

  // A withdraw function to avoid locking ERC20 tokens in the contract forever.
  // Tokens can only be withdrawn by the owner, to the owner.
  function transferERC20Token(IERC20 token, uint256 amount) external onlyOwner {
    token.safeTransfer(owner(), amount);
  }

  function pause() external onlyOwner {
    require(
      mintWhitelistSetTime == 0 ||
        block.timestamp < (mintWhitelistSetTime + pauseCutoffDays * 1 days),
      "Can only pause until the cutoff"
    );
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function setMintWhitelistMerkleRoot(bytes32 mintWhitelistMerkleRoot_)
    external
    onlyOwner
  {
    require(
      mintWhitelistMerkleRoot == 0,
      "Mint merkle root can only be set once"
    );
    mintWhitelistMerkleRoot = mintWhitelistMerkleRoot_;
    mintWhitelistSetTime = block.timestamp;
  }

  function _mintHash(uint256[] calldata inputIndexes_, address bidder_)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encode(inputIndexes_, bidder_));
  }

  function _calculateTokenIdToMint(uint256 inputIndex_)
    internal
    view
    returns (uint256)
  {
    return (inputIndex_ + _randomness) % maxSupply;
  }

  // All tokens are minted using the random offset.
  // Tokens can only be minted once, even if burned.
  function mint(uint256[] calldata inputIndexes_, bytes32[] calldata proof_)
    external
    whenNotPaused
  {
    require(mintWhitelistMerkleRoot != 0, "Mint merkle root not set");

    require(_randomnessHasBeenSet, "Randomness must be set before minting");

    // Can only mint if we haven't already minted to this address:
    require(!_hasMinted[msg.sender], "Sender has already minted");

    // Check the proof is valid
    bytes32 leaf = _mintHash(inputIndexes_, msg.sender);
    require(
      MerkleProof.verify(proof_, mintWhitelistMerkleRoot, leaf),
      "Mint proof invalid"
    );

    _hasMinted[msg.sender] = true;

    for (uint256 i = 0; i < inputIndexes_.length; i++) {
      uint256 tokenIdToMint = _calculateTokenIdToMint(inputIndexes_[i]);
      _safeMint(msg.sender, tokenIdToMint);
    }
  }

  function setRoyaltyPercentageBasisPoints(
    uint256 royaltyPercentageBasisPoints_
  ) external onlyOwner {
    _royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;
  }

  function setRoyaltyReceipientAddress(
    address payable royaltyReceipientAddress_
  ) external onlyOwner {
    _royaltyReceipientAddress = royaltyReceipientAddress_;
  }

  function setTokenBaseURI(string calldata tokenBaseURI_) external onlyOwner {
    require(!_tokenBaseURILocked, "Token base URI is locked");
    _tokenBaseURI = tokenBaseURI_;
  }

  function lockTokenBaseURI() external onlyOwner {
    require(!_tokenBaseURILocked, "Token base URI is locked");
    _tokenBaseURILocked = true;
  }

  function tokenBaseURILocked() public view returns (bool) {
    return _tokenBaseURILocked;
  }

  function royaltyInfo(uint256 tokenId_, uint256 salePrice_)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    uint256 royalty = (salePrice_ * _royaltyPercentageBasisPoints) / 10000;
    return (_royaltyReceipientAddress, royalty);
  }

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
    return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

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
}