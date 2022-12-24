// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract SockDrop_2022_12 is ERC721A, Ownable {
  mapping(address => bool) public claimedList;

  string private _name = "SockDrop_2022_12";
  string private _symbol = "SD2212";

  bytes32 public merkleRoot;
  uint256 public maxSupply = 38;
  uint256 public maxMintAmountPerWallet = 1;

  bool private _publicMintEnabled = false;
  uint256 private royaltyFee = 1000; // Default 1000 BP (10%)

  // Metadata bits
  string private metadataName = 'PlsdSock POA w/ OHJERO X2';
  string private externalUrl = "https://pulsedoge.exchange/";

  // image url format: baseUri + tokenId + imageUrl
  string private baseUri = "ipfs://bafybeifycwpqrwevpvmtejlfs7ppe4jm4cmdeimx7cfgwd3f4puhgwcxqy/";
  string private imageUrl = ".jpg";

  constructor(bytes32 _merkleRoot, address _owner) ERC721A(_name, _symbol) {
    merkleRoot = _merkleRoot;

    if(_owner != address(0)) {
      _transferOwnership(_owner);
    }
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /*
  ******
  ** Assertions and booleans
  ******
  */
  function publicMintEnabled() external view returns(bool) {
    return _publicMintEnabled;
  }

  function canWhitelistMint(bytes32[] calldata proof) external view returns(bool) {
    return _assertCanWhitelistMint(proof);
  }

  function canPublicMint() external view returns(bool) {
    return _assertCanPublicMint();
  }

  function _assertCanPublicMint() internal view returns(bool) {
    require(_publicMintEnabled == true, "Public mint not available");
    require(claimedList[_msgSender()] == false, "You've already claimed");

    return true;
  }

  function _assertCanWhitelistMint(bytes32[] calldata proof) internal view returns(bool) {
    require(claimedList[_msgSender()] == false, "You've already claimed");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), uint256(1)));
    require(MerkleProof.verify(proof, merkleRoot, leaf), "No claim in the whitelist!");

    return true;
  }

  function remainingMintAmount(bytes32[] calldata proof) external view returns(uint256) {
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), uint256(1)));
    bool verified = MerkleProof.verify(proof, merkleRoot, leaf);

    if(verified) {
      if(claimedList[_msgSender()]) {
        return 0;
      } else {
        return 1;
      }
    } else {
      return 0;
    }
  }

  modifier mintCompliance() {
    require(totalSupply() + 1 <= maxSupply, "Max supply exceeded!");
    _;
  }

  /*
  ******
  ** Minting functions
  ******
  */
  function whitelistMint(bytes32[] calldata proof) public mintCompliance() {
    _assertCanWhitelistMint(proof);

    claimedList[_msgSender()] = true;
    _safeMint(_msgSender(), 1);
  }

  function mint() public mintCompliance() {
    _assertCanPublicMint();

    claimedList[_msgSender()] = true;
    _safeMint(_msgSender(), 1);
  }

  function mintForAddress(address receiver, uint256 mintAmount) public onlyOwner {
    require(totalSupply() + mintAmount <= maxSupply, "Max supply exceeded!");

    _safeMint(receiver, mintAmount);
  }

  /*
  ******
  ** Token URI functions
  ******
  */
  function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(
      '{',
        '"name": "', metadataName, ' #', Strings.toString(tokenId), '", ',
        '"external_url": "', externalUrl, '", ',
        '"image": "', baseUri, Strings.toString(tokenId), imageUrl, '"',
      '}'
    ))));
  }

  /*
  ******
  ** Australian Setters
  ******
  */
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }
  function setPublicMintEnabled(bool _state) public onlyOwner {
    _publicMintEnabled = _state;
  }
  function setBaseUri(string memory _baseUri) public onlyOwner {
    baseUri = _baseUri;
  }
  function setTokenUriDetails(
    string memory _metadataName,
    string memory _externalUrl,
    string memory _imageUrl
  ) public onlyOwner {
    bytes(_metadataName).length != 0 ? metadataName = _metadataName : '';
    bytes(_externalUrl).length != 0 ? externalUrl = _externalUrl : '';
    bytes(_imageUrl).length != 0 ? imageUrl = _imageUrl : '';
  }
}