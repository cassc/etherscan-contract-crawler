// SPDX-License-Identifier: MIT
// contract written by @ppape_io

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract PPAPECollection is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public craftBaseURI;

  string public constant UNREVEALED_TOKEN_URI = string(abi.encodePacked("https://nft.ppape.io/ag/unrevealed.json"));

  // PROVENANCE: Use the same hash mechanism as BAYC's.
  string public constant MINT_PROVENANCE = "e2d443f6dd8fff4ba1d69c3474e83beb8bc0d0e639cbe30c329ac94dd8f74fee";
  string public constant CRAFT_PROVENANCE = "ecd862bb217af0ea3870bdfb0c81567fb1daca9b60018e685e1c22aab3146bb5";

  uint256 public constant MAX_SUPPLY = 10000;
  uint256 public constant MINT_PER_WHITELIST_ADDRESS_LIMIT = 1;
  uint256 public constant MINT_PER_WAITING_LIST_ADDRESS_LIMIT = 1;

  // allSettings: 
  //        isRevealed | whitelistAcitve | waitinglistActive | mintActive | craftActive | tbd | tbd | tbd
  //           0              0                  0                0            0          0     0     0
  // mask:     0x80           0x40               0x20             0x10         0x08       0x04  0x02  0x01
  bytes1 public allSettings = 0x00;

  bytes32 public whitelistMerkleRoot;
  bytes32 public waitingListMerkleRoot;

  // schedule: whitelist -> waiting list -> mint -> craft
  uint256 public whitelistMintStartTime;
  uint256 public waitingListMintStartTime;
  uint256 public mintStartTime;
  uint256 public craftStartTime;

  // The counter for each whitelist address has minted.
  mapping(address => uint256) public addressWhitelistMintedBalance;

  // The counter for each waiting list address has minted.
  mapping(address => uint256) public addressWaitingListMintedBalance;

  uint256 private _maxAvailableTokens;
  mapping(uint256 => uint256) private _availableTokens;
  uint256 private _maxAvailableCraftings;
  mapping(uint256 => uint256) private _availableCraftings;

  event Mint(address to, uint256 tokenId);
  event Craft(address to, uint256 tokenId);

  constructor() ERC721("PPAPE-American Gothic", "PPAPEAG") {
    baseURI = UNREVEALED_TOKEN_URI;
    craftBaseURI = UNREVEALED_TOKEN_URI;
    whitelistMintStartTime = 1667782800;
    waitingListMintStartTime = 1667869200;
    mintStartTime = 1667876400;
    craftStartTime = 1668387600;
    whitelistMerkleRoot = 0xca2cb24b1f568d3a52d14be4b1d6297d114713cc327c312bf8206755a2542cec;
    waitingListMerkleRoot = 0xd6a39d429048f21d11e7c63fa929e8aa9389e42d8778102a7d5020f38dde5900;
    _maxAvailableTokens = MAX_SUPPLY;
    _maxAvailableCraftings = MAX_SUPPLY / 2;
  }

  function _getRandomIndex(address to, uint256 updatedMaxAvailableTokens) internal view returns (uint256) {
    uint256 randomNum = uint256(keccak256(abi.encode(to, tx.gasprice, block.number, block.timestamp, block.difficulty, address(this), updatedMaxAvailableTokens)));
    return randomNum % updatedMaxAvailableTokens;
  }

  function _isLeft(uint256 tokenId) internal pure returns (bool) {
    return tokenId < MAX_SUPPLY / 2;
  }

  function _isRight(uint256 tokenId) internal pure returns (bool) {
    return tokenId >= MAX_SUPPLY / 2 && tokenId < MAX_SUPPLY;
  }

  function _getAvailableTokenAtIndex(uint256 indexToUse, uint256 currentMaxAvailableTokens) internal returns (uint256) {
    uint256 valAtIndex = _availableTokens[indexToUse];

    uint256 lastIndex = currentMaxAvailableTokens - 1;
    if (indexToUse != lastIndex) {
        uint256 lastValInArray = _availableTokens[lastIndex];
        if (lastValInArray == 0) {
            _availableTokens[indexToUse] = lastIndex;
        } else {
            _availableTokens[indexToUse] = lastValInArray;

            delete _availableTokens[lastIndex];
        }
    }

    return valAtIndex == 0 ? indexToUse : valAtIndex;
  }

  function _getAvailableCraftingAtIndex(uint256 indexToUse, uint256 currentMaxAvailableCraftings) internal returns (uint256) {
    uint256 valAtIndex = _availableCraftings[indexToUse];

    uint256 lastIndex = currentMaxAvailableCraftings - 1;

    if (indexToUse != lastIndex) {
      uint256 lastValInArray = _availableCraftings[lastIndex];
      if (lastValInArray == 0) {
        _availableCraftings[indexToUse] = lastIndex;
      } else {
        _availableCraftings[indexToUse] = lastValInArray;

        delete _availableCraftings[lastIndex];
      }
    }

    return valAtIndex == 0 ? indexToUse : valAtIndex;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
    super._beforeTokenTransfer(from, to, tokenId);
    if (from != address(0)) {
      require(_isApprovedOrOwner(msg.sender, tokenId), "only the owner or approved contracts of NFT can transfer or burn it");
    }
  }

  function isRevealed() public view returns (bool) {
    return (allSettings & 0x80) != 0;
  }

  function isWhitelistMintActive() public view returns (bool) {
    return (allSettings & 0x40) != 0;
  }

  function isWaitingListMintActive() public view returns (bool) {
    return (allSettings & 0x20) != 0;
  }

  function isMintActive() public view returns (bool) {
    return (allSettings & 0x10) != 0;
  }

  function isCraftActive() public view returns (bool) {
    return (allSettings & 0x08) != 0;
  }

  function getTokenIdsOfOwner(address owner) external view returns (uint256[] memory) {
    uint256 balanceOfOwner = balanceOf(owner);
    uint256[] memory ownerTokenIds = new uint256[](balanceOfOwner);
    for (uint256 i = 0; i < balanceOfOwner; i++) {
      ownerTokenIds[i] = tokenOfOwnerByIndex(owner, i);
    }
    return ownerTokenIds;
  }

  // Function to verify the merkle tree root
  function _merkleProofCheck(bytes32[] calldata proof, bytes32 root) internal view {
    require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))), "invalid proof, you're not on the list.");
  }

  // Function to help users verify the whitelist eligibility publicly
  function isEligibleForWhitelistMint(bytes32[] calldata _merkleProof) external view returns (bool) {
    require(isWhitelistMintActive(), "the whitelist mint is paused");
    require(block.timestamp >= whitelistMintStartTime, "the whitelist is not started yet");
    require(block.timestamp < waitingListMintStartTime, "the whitelist is over");
    require(_maxAvailableTokens > 0, "all NFTs are minted!");

    _merkleProofCheck(_merkleProof, whitelistMerkleRoot);
    require(addressWhitelistMintedBalance[msg.sender] + 1 <= MINT_PER_WHITELIST_ADDRESS_LIMIT, "max NFTs per whitelist address exceeded");  

    return true;
  }

  // Function to help users verify the waiting list eligibility publicly
  function isEligibleForWaitingListMint(bytes32[] calldata _merkleProof) external view returns (bool) {
    require(isWaitingListMintActive(), "the waiting list mint is paused");
    require(block.timestamp >= waitingListMintStartTime, "the waiting list mint is not started yet");
    require(_maxAvailableTokens > 0, "all NFTs are minted!");

    _merkleProofCheck(_merkleProof, waitingListMerkleRoot);
    require(addressWaitingListMintedBalance[msg.sender] + 1 <= MINT_PER_WAITING_LIST_ADDRESS_LIMIT, "max NFTs per waiting list address exceeded");

    return true;
  }

  // Function to verify the whitelist eligibility
  function _isEligibleForWhitelistMint(bytes32[] calldata _merkleProof) internal view returns (bool) {
    require(isWhitelistMintActive(), "the whitelist mint is paused");
    require(block.timestamp >= whitelistMintStartTime, "the whitelist is not started yet");
    require(block.timestamp < waitingListMintStartTime, "the whitelist is over");
    require(_maxAvailableTokens > 0, "all NFTs are minted!");

    _merkleProofCheck(_merkleProof, whitelistMerkleRoot);
    require(addressWhitelistMintedBalance[msg.sender] + 1 <= MINT_PER_WHITELIST_ADDRESS_LIMIT, "max NFTs per whitelist address exceeded");  

    return true;
  }

  // Function to verify the waiting list eligibility
  function _isEligibleForWaitingListMint(bytes32[] calldata _merkleProof) internal view returns (bool) {
    require(isWaitingListMintActive(), "the waiting list mint is paused");
    require(block.timestamp >= waitingListMintStartTime, "the waiting list mint is not started yet");
    require(_maxAvailableTokens > 0, "all NFTs are minted!");

    _merkleProofCheck(_merkleProof, waitingListMerkleRoot);
    require(addressWaitingListMintedBalance[msg.sender] + 1 <= MINT_PER_WAITING_LIST_ADDRESS_LIMIT, "max NFTs per waiting list address exceeded");

    return true;
  }

  // Whitelist mint function for people on the whitelist
  function whitelistMint(bytes32[] calldata _merkleProof) external returns (uint256) {
    _isEligibleForWhitelistMint(_merkleProof);

    addressWhitelistMintedBalance[msg.sender] += 1;

    return _mint(msg.sender);
  }

  // Waiting list mint function for people on the waiting list
  function waitingListMint(bytes32[] calldata _merkleProof) external returns (uint256) {
    _isEligibleForWaitingListMint(_merkleProof);

    addressWaitingListMintedBalance[msg.sender] += 1;

    return _mint(msg.sender);
  }

  // Public mint function
  function mint() external returns (uint256) {
    require(isMintActive(), "the public mint is paused");
    require(block.timestamp >= mintStartTime, "the mint is not started yet");
    require(_maxAvailableTokens > 0, "all NFTs are minted!");

    return _mint(msg.sender);
  }

  function _mint(address to) internal virtual returns (uint256) {
    uint256 tokenId = _getAvailableTokenAtIndex(_getRandomIndex(to, _maxAvailableTokens), _maxAvailableTokens);
    _maxAvailableTokens--;
    _safeMint(to, tokenId);
    emit Mint(msg.sender, tokenId);
    return tokenId;
  }

  function craft(uint256 leftId, uint256 rightId) external returns (uint256) {
    require(isCraftActive(), "the craft is paused");
    require(block.timestamp >= craftStartTime, "the craft is not started yet");
    require(_isApprovedOrOwner(msg.sender, leftId) && _isApprovedOrOwner(msg.sender, rightId), "only the owner of both NFTs can craft them");

    require((_isLeft(leftId) && _isRight(rightId)), "invalid Token Id");
    require(_maxAvailableCraftings > 0, "all NFTs are crafted!");

    return _craft(msg.sender, leftId, rightId);
  }

  function _craft(address to, uint256 leftId, uint256 rightId) internal returns (uint256) {
    _burn(leftId);
    _burn(rightId);

    uint256 tokenId = _getAvailableCraftingAtIndex(_getRandomIndex(to, _maxAvailableCraftings), _maxAvailableCraftings);
    uint256 craftId = tokenId + MAX_SUPPLY;
    _maxAvailableCraftings--;
    _safeMint(to, craftId);

    emit Craft(msg.sender, craftId);
    return craftId;
  }  

  // Function to set whitelistMint start time
  function setWhitelistMintStartTime(uint256 ts) external onlyOwner {
      whitelistMintStartTime = ts;
  }

  // Function to set waitingListMint start time
  function setWaitingListMintStartTime(uint256 ts) external onlyOwner {
      waitingListMintStartTime = ts;
  }

  // Function to set mint start time
  function setMintStartTime(uint256 ts) external onlyOwner {
      mintStartTime = ts;
  }

  // Function to set craft start time
  function setCraftStartTime(uint256 ts) external onlyOwner {
      craftStartTime = ts;
  }

  // Function to set all settings
  function setAllSettings(bytes1 settings) external onlyOwner returns (bytes1) {
    return allSettings = settings;
  }

  // Function to toggle the nft revealed
  function toggleRevealed() external onlyOwner returns (bytes1) {
    return allSettings = allSettings ^ 0x80;
  }

  // Function to toggle the whitelist mint
  function toggleWhitelistMint() external onlyOwner returns (bytes1) {
    return allSettings = allSettings ^ 0x40;
  }

  // Function to toggle the waiting list mint
  function toggleWaitingListMint() external onlyOwner returns (bytes1) {
    return allSettings = allSettings ^ 0x20;
  }

  // Function to toggle the public mint
  function toggleMint() external onlyOwner returns (bytes1) {
    return allSettings = allSettings ^ 0x10;
  }

  // Function to toggle the public craft
  function toggleCraft() external onlyOwner returns (bytes1) {
    return allSettings = allSettings ^ 0x08;
  }
 
  // Function to set the whitelist merkle root  
  function setWhitelistMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
    whitelistMerkleRoot = _newMerkleRoot;
  }

  // Function to set the waiting list merkle root  
  function setWaitingListMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
    waitingListMerkleRoot = _newMerkleRoot;
  }

  // Function to set the base URI
  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  // Function to set the craft base URI
  function setCraftBaseURI(string memory _newBaseURI) external onlyOwner {
    craftBaseURI = _newBaseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token");
    
    if (!isRevealed()) {
      return UNREVEALED_TOKEN_URI;
    }

    return string(abi.encodePacked(
      tokenId < MAX_SUPPLY ? _baseURI() : _craftBaseURI(),
      tokenId.toString(),
      ".json"
    ));
  }

  // Function to return the base URI (only for pre-craft stage)
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // Function to return the base URI
  function _craftBaseURI() internal view virtual returns (string memory) {
    return craftBaseURI;
  }
}