// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// coded by Crypto Tester: https://twitter.com/crypto_tester_

contract DeconstructedPunkdApes is ERC721,
  ERC721Enumerable,
  ERC721URIStorage,
  Ownable,
  ERC165Storage,
  IERC2981 {
  
  uint16 public mintCount;
  uint16 public supply;  
  uint16 public freeSupply;
  uint16 public freeCount;
  uint8 public rareSupply;
  uint8 public rareCount;
  uint8 public maxPerUser;
  uint8 public royaltyFee;
  address public royaltyAddress;
  bool public mintingEnabled;
  string public baseUrl;
  
  bytes32 public whitelistRoot;
  bytes32 public rareWhitelistRoot;
  mapping(address => uint8) public freeClaimed;
  mapping(address => bool) public rareClaimed;
  mapping(uint16 => uint16) private tokenMatrix;

  struct UserStatus {
    bool whitelisted;
    uint8 minted;
    uint8 canMint;
  }
  
  event Mint(address addr, uint16 tokenId);
  event RareMint(address addr, uint16 tokenId);
  event UpdateBaseUrl(string newBaseUrl);
  event UpdateTokenURI(uint256 id, string newTokenURI);
  event UintPropertyChange(string param, uint256 value);
  event BoolPropertyChange(string param, bool value);
  event AddressPropertyChange(string param, address value);
  event WhitelistChange();

  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
  bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  constructor(uint8 _maxPerUser, uint16 _free, uint8 _rares)
  ERC721("Deconstructed Punk'd Apes", "DPA")
  {
    maxPerUser = _maxPerUser;
    freeSupply = _free;
    rareSupply = _rares;
    supply = freeSupply + rareSupply;
    mintCount = 0;
    royaltyFee = 10;
    royaltyAddress = 0x5b59610a0F18958E6ECa3A24DBf2D27F9Cd7bdB7;
    mintingEnabled = true;
    baseUrl = "";

    // ERC721 interface
    _registerInterface(_INTERFACE_ID_ERC721);
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);

    // Royalties interface
    _registerInterface(_INTERFACE_ID_ERC2981);
  }

  function getStatus(bytes32[] calldata merkleProof) public view returns (UserStatus memory) {
    return _getUserStatus(msg.sender, merkleProof);
  }

  function _getUserStatus(address addr, bytes32[] calldata merkleProof) private view returns (UserStatus memory) {
    UserStatus memory userStatus;
    bytes32 leaf = keccak256(abi.encodePacked(addr));
    if (freeCount < freeSupply) {
      userStatus.whitelisted = MerkleProof.verifyCalldata(merkleProof, whitelistRoot, leaf);
      userStatus.minted = freeClaimed[addr];
      userStatus.canMint = userStatus.whitelisted ? maxPerUser - userStatus.minted : 0;
    }
    else if (rareCount < rareSupply) {
      userStatus.whitelisted = MerkleProof.verifyCalldata(merkleProof, rareWhitelistRoot, leaf);
      userStatus.minted = rareClaimed[addr] ? 1 : 0;
      userStatus.canMint = userStatus.whitelisted ? 1 - userStatus.minted : 0;
    }
    return userStatus;
  }

  // FREE MINT
  function mint(bytes32[] calldata merkleProof) external {
    require(mintCount < supply, "MINTED_OUT");
    require(mintingEnabled, "MINTING_DISABLED");

    UserStatus memory userStatus = _getUserStatus(msg.sender, merkleProof);
    uint16 tokenId;
    if (freeCount < freeSupply) {
      // Free Mint
      require(userStatus.whitelisted, "NOT_WHITELISTED");
      require(userStatus.canMint > 0, "USER_QUOTA_REACHED");
      tokenId = getNextRandomTokenId();
      _mint(msg.sender, tokenId);
      _setTokenURI(tokenId, _endOfURI(tokenId));
      freeCount++;
      mintCount++;
      freeClaimed[msg.sender] += 1;
      emit Mint(msg.sender, tokenId);
    }
    else if (rareCount < rareSupply) {
      // Rares Mint
      require(userStatus.whitelisted, "NOT_WHITELISTED_FOR_RARES");
      require(userStatus.canMint > 0, "USER_QUOTA_REACHED");
      rareClaimed[msg.sender] = true;
      _rareMint(1, msg.sender);
    }
  }

  function _rareMint(uint8 quantity, address to) private {
    for (uint8 i = 0; i < quantity; i++) {
      uint16 tokenId = rareCount;
      _mint(to, tokenId);
      _setTokenURI(tokenId, _endOfURI(tokenId));
      rareCount++;
      mintCount++;
      emit RareMint(to, tokenId);
    }
  }

  function adminMint(uint8 quantity, address to) external {
    // Admin & Founder can mint rares
    require(rareCount < rareSupply, "MINTED_OUT");
    require(msg.sender == owner() || msg.sender == royaltyAddress, "UNAUTHORIZED");
    _rareMint(quantity, to);
  }

  function getNextRandomTokenId() private returns (uint16) {
    uint16 maxIndex = supply - mintCount - rareSupply;
    uint16 random = uint16(uint256(
      keccak256(
        abi.encodePacked(
          msg.sender,
          block.coinbase,
          block.difficulty,
          block.gaslimit,
          block.timestamp
        )
      )
    ) % maxIndex);

    uint16 randomNr = 0;
    if (tokenMatrix[random] == 0) {
      randomNr = random;
    } else {
      randomNr = tokenMatrix[random];
    }

    if (tokenMatrix[maxIndex - 1] == 0) {
      tokenMatrix[random] = maxIndex - 1;
    } else {
      tokenMatrix[random] = tokenMatrix[maxIndex - 1];
    }

    return randomNr + rareSupply;
  }

  function setWhitelistRoot(bytes32 value) external onlyOwner {
    whitelistRoot = value;
    emit WhitelistChange();
  }

  function setRareWhitelistRoot(bytes32 value) external onlyOwner {
    rareWhitelistRoot = value;
    emit WhitelistChange();
  }

  function setMintingEnabled(bool value) external onlyOwner {
    mintingEnabled = value;
    emit BoolPropertyChange("mintingEnabled", mintingEnabled);
  }

  function setRoyaltyAddress(address addr) external onlyOwner {
    royaltyAddress = addr;
    emit AddressPropertyChange("royaltyAddress", addr);
  }

  function setRoyaltyFee(uint8 feePercent) external onlyOwner {
    royaltyFee = feePercent;
    emit UintPropertyChange("royaltyFee", feePercent);
  }

  function setBaseUrl(string calldata url) external onlyOwner {
    baseUrl = url;
    emit UpdateBaseUrl(url);
  }

  function setTokenURI(uint256 id, string calldata dotJson) external onlyOwner {
    _setTokenURI(id, dotJson);
    emit UpdateTokenURI(id, dotJson);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseUrl;
  }

  function _uint2str(uint256 nr) internal pure returns (string memory str) {
    if (nr == 0) {
      return "0";
    }
    uint256 j = nr;
    uint256 length;
    while (j != 0) {
      length++;
      j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint256 k = length;
    j = nr;
    while (j != 0) {
      bstr[--k] = bytes1(uint8(48 + j % 10));
      j /= 10;
    }
    str = string(bstr);
  }

  function _endOfURI(uint256 nr) internal pure returns (string memory jsonString) {
    string memory number = _uint2str(nr);
    string memory dotJson = ".json";
    jsonString = string(abi.encodePacked(number, dotJson));
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function royaltyInfo(uint256, uint256 salePrice) external view override(IERC2981) returns (address receiver, uint256 royaltyAmount) {
    receiver = royaltyAddress;
    royaltyAmount = salePrice * royaltyFee / 100;
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC165Storage, IERC165) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function sweepEth() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "NO_FUNDS");
    (bool sent, ) = owner().call{value: balance}("");
    require(sent, "FAILED_SENDING_FUNDS");
  }

  function sweepErc20(IERC20 token) external onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    require(balance > 0, "NO_FUNDS");
    token.transfer(owner(), balance);
  }

  receive() external payable {}

  fallback() external payable {}
}