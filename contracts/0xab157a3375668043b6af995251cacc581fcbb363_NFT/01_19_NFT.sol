// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract NFT is ERC721, Pausable, Ownable, ERC721Burnable, VRFConsumerBase {
  using Counters for Counters.Counter;
  using SafeERC20 for IERC20;

  event RandomNumberReceived(uint256 randomNumber);

  // ERC-2981: NFT Royalty Standard
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  uint256 public immutable numberOfBreeds;
  uint256 public immutable maxSupplyPerBreed;
  uint256 public immutable maxSupply;
  address public immutable developerAddress;
  uint256 public immutable developerAllocation;

  Counters.Counter private _mintedTotalSupplyCounter;
  // breedIndex => minted tokens per breed
  mapping(uint256 => Counters.Counter) private _mintedBreedCounter;

  string private _tokenBaseURI;
  string private _contractURI;
  uint256 private _randomness;
  bool private _randomnessHasBeenSet;
  address private _royaltyReceipientAddress;
  uint256 private _royaltyPercentageBasisPoints;

  // Chainlink configuration.
  bytes32 internal keyHash;
  uint256 internal fee;

  constructor(
    address[] memory specialMintAddresses_,
    uint256[] memory specialMintAllocations_,
    uint256 numberOfBreeds_,
    uint256 maxSupplyPerBreed_,
    address royaltyReceipientAddress_,
    uint256 royaltyPercentageBasisPoints_,
    string[] memory uris_,
    address[] memory chainlinkAddresses_,
    bytes32 keyHash_,
    uint256 fee_
  )
    ERC721("Vailiens", "VAILIENS")
    VRFConsumerBase(chainlinkAddresses_[0], chainlinkAddresses_[1])
  {
    developerAddress = specialMintAddresses_[0];
    developerAllocation = specialMintAllocations_[0];
    maxSupply = numberOfBreeds_ * maxSupplyPerBreed_;
    numberOfBreeds = numberOfBreeds_;
    maxSupplyPerBreed = maxSupplyPerBreed_;
    _tokenBaseURI = uris_[0];
    _contractURI = uris_[1];
    _royaltyReceipientAddress = royaltyReceipientAddress_;
    _royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;
    keyHash = keyHash_;
    fee = fee_;
  }

  function mintedTotalSupply() public view returns (uint256) {
    return _mintedTotalSupplyCounter.current();
  }

  function mintedBreedSupply(uint256 breedIndex) public view returns (uint256) {
    require(breedIndex < numberOfBreeds, "breedIndex out of bounds");
    return _mintedBreedCounter[breedIndex].current();
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
    emit RandomNumberReceived(randomness);
    require(!_randomnessHasBeenSet);
    _randomness = randomness;
    _randomnessHasBeenSet = true;
  }

  // A withdraw function to avoid locking ERC20 tokens in the contract forever.
  // Tokens can only be withdrawn by the owner, to the owner.
  function transferERC20Token(IERC20 token, uint256 amount) public onlyOwner {
    token.safeTransfer(owner(), amount);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function calculateIndexToMint(uint256 breedIndex)
    internal
    view
    returns (uint256)
  {
    uint256 offset = (mintedBreedSupply(breedIndex) + _randomness) %
      maxSupplyPerBreed;
    return (maxSupplyPerBreed * breedIndex) + offset;
  }

  // All tokens are minted using the random offset.
  // Tokens can only be minted once, even if burned.
  function mint(uint256 breedIndex, address to_) public onlyOwner {
    require(_randomnessHasBeenSet, "Randomness must be set before minting");
    require(mintedTotalSupply() < maxSupply, "Max supply minted");
    require(
      mintedBreedSupply(breedIndex) < maxSupplyPerBreed,
      "Max supply for breed minted"
    );

    uint256 indexToMint = calculateIndexToMint(breedIndex);

    // It's the responsibility of the minting script to select an even distribution of breeds for these special allocations.
    // The special allocations are automatically subject to the random offset.
    // The first developerAllocation tokens must be given to developerAddress.
    if (mintedTotalSupply() < developerAllocation) {
      require(to_ == developerAddress, "First batch for developer");
    }

    _safeMint(to_, indexToMint);
    _mintedBreedCounter[breedIndex].increment();
    _mintedTotalSupplyCounter.increment();
  }

  // Provide an array of addresses and a corresponding array of quantities.
  function mintBatch(
    uint256[] calldata breedIndexes,
    address[] calldata addresses,
    uint256[] calldata quantities
  ) external onlyOwner {
    require(
      breedIndexes.length == addresses.length &&
        addresses.length == quantities.length,
      "Input array lengths not equal"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      for (uint256 j = 0; j < quantities[i]; j++) {
        mint(breedIndexes[i], addresses[i]);
      }
    }
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

  function setRoyaltyPercentageBasisPoints(
    uint256 royaltyPercentageBasisPoints_
  ) public onlyOwner {
    _royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;
  }

  function setRoyaltyReceipientAddress(
    address payable royaltyReceipientAddress_
  ) public onlyOwner {
    _royaltyReceipientAddress = royaltyReceipientAddress_;
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    uint256 royalty = (_salePrice * _royaltyPercentageBasisPoints) / 10000;
    return (_royaltyReceipientAddress, royalty);
  }

  // Contract-level metadata for OpenSea.
  function setContractURI(string calldata contractURI_) public onlyOwner {
    _contractURI = contractURI_;
  }

  // Contract-level metadata for OpenSea.
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return _tokenBaseURI;
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