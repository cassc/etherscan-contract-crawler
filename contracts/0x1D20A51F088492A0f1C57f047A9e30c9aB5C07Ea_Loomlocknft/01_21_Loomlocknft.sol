// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Loomlocknft is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable, VRFConsumerBase {
  using Counters for Counters.Counter;
  using SafeERC20 for IERC20;

  // ERC-2981: NFT Royalty Standard
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  uint256 public constant RESERVED_TOKEN_COUNT = 1;

  uint256 public immutable maxSupply;
  uint256 public immutable developerAllocation;
  address public immutable developerAddress;
  uint256 public immutable revealTimestamp;
  address public immutable reservedTokenRecipient;

  string private _tokenBaseURI;
  string private _contractURI;
  Counters.Counter private _tokenIdCounter;
  Counters.Counter private _developerAllocationCounter;
  uint256 private _randomness;
  bool private _randomnessHasBeenSet;
  address payable private _royaltyReceipientAddress;
  uint256 private _royaltyPercentageBasisPoints;

  // Chainlink configuration.
  bytes32 internal keyHash;
  uint256 internal fee;

  constructor(
    address[] memory specialMintAddresses_,
    uint256 developerAllocation_,
    uint256 maxSupply_,
    uint256 revealTimestamp_,
    address payable royaltyReceipientAddress_,
    uint256 royaltyPercentageBasisPoints_,
    string[] memory uris_,
    address vrfCoordinator_,
    address link_,
    bytes32 keyHash_,
    uint256 fee_
  )
  ERC721("loomlocknft", "LL")
  VRFConsumerBase(vrfCoordinator_, link_) {
    reservedTokenRecipient = specialMintAddresses_[0];
    developerAddress = specialMintAddresses_[1];
    developerAllocation = developerAllocation_;
    maxSupply = maxSupply_;
    revealTimestamp = revealTimestamp_;
    _contractURI = uris_[0];
    _tokenBaseURI = uris_[1];
    _royaltyReceipientAddress = royaltyReceipientAddress_;
    _royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;
    keyHash = keyHash_;
    fee = fee_;
  }

  function mintedSupply() public view returns (uint256) {
    return _tokenIdCounter.current();
  }

  function mintedDeveloperAllocationCounter() public view returns (uint256) {
    return _developerAllocationCounter.current();
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
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
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

  // Token 0 is reserved for the fractionalised hexcode airdrop.
  function mintReservedToken(uint256 tokenId) public onlyOwner whenNotPaused {
    if (tokenId == 0) {
      require(mintedSupply() == 0, "Token 0 already minted");
      _safeMint(reservedTokenRecipient, tokenId);
      _tokenIdCounter.increment();
    } else {
      revert("Only for 0");
    }
  }

  // All tokens other than token 0 are minted using the random offset.
  // Tokens can only be minted once, even if burned.
  function mint(address to_) public onlyOwner whenNotPaused {
    require(mintedSupply() >= RESERVED_TOKEN_COUNT, "Token 0 must be minted first");
    require(_randomnessHasBeenSet, "Randomness must be set before minting");
    require(mintedSupply() < maxSupply, "Max supply minted");

    uint256 indexToMint = (mintedSupply() + _randomness) % (maxSupply - RESERVED_TOKEN_COUNT) + RESERVED_TOKEN_COUNT;

    if (mintedDeveloperAllocationCounter() < developerAllocation) {
      // The first developerAllocation tokens (excluding token 0) must be given to developerAddress.
      // These tokens and all others are subject to the random offset.
      require(to_ == developerAddress, "First batch for dev");
      // Preemptively increment this counter, since it's not used for safeMint.
      _developerAllocationCounter.increment();
    }

    _safeMint(to_, indexToMint);
    _tokenIdCounter.increment();
  }

  // Provide an array of addresses and a corresponding array of quantities.
  function mintBatch(address[] calldata addresses, uint256[] calldata quantities) public onlyOwner whenNotPaused {
    require(addresses.length == quantities.length, "Addresses & quantites length not equal");
    for (uint256 i = 0; i < addresses.length; i++) {
      for (uint256 j = 0; j < quantities[i]; j++) {
        mint(addresses[i]);
      }
    }
  }

  function addressHoldings(address _addr) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_addr);
    uint256[] memory tokens = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokens[i] = tokenOfOwnerByIndex(_addr, i);
    }
    return tokens;
  }

  function preRevealTokenURI(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    // Return an empty string for the tokenURI until the reveal timestamp.
    if (block.timestamp >= revealTimestamp) {
      return preRevealTokenURI(tokenId);
    } else {
      return "";
    }
  }

  function setRoyaltyPercentageBasisPoints(uint256 royaltyPercentageBasisPoints_) public onlyOwner {
    _royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;
  }

  function setRoyaltyReceipientAddress(address payable royaltyReceipientAddress_) public onlyOwner {
    _royaltyReceipientAddress = royaltyReceipientAddress_;
  }

  // Contract-level metadata for OpenSea.
  function setContractURI(string calldata contractURI_) public onlyOwner {
    _contractURI = contractURI_;
  }

  // Contract-level metadata for OpenSea.
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    uint256 royalty = (_salePrice * _royaltyPercentageBasisPoints) / 10000;
    return (_royaltyReceipientAddress, royalty);
  }

  function _baseURI() internal view override returns (string memory) {
    return _tokenBaseURI;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
  }
}