// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract PLSDSock is ERC721A, Ownable, ReentrancyGuard {

  mapping(address => uint256) public whitelistClaimedAmount;
  mapping(address => uint256) public amountBurned;
  mapping(uint256 => bool) private _claimedSocks;

  string private _name = "PLSDSock Genesis";
  string private _symbol = "PLSDSock";

  bytes32 public merkleRoot;
  uint256 public maxSupply = 1085;
  uint256 public fee = 0.0085 ether; // 8500000000000000 wei

  bool public revealed = false;
  uint256 private royaltyFee = 1000; // Default 1000 BP (10%)

  string private baseUri = "ipfs://nonexistentkey/"; // baseUri MUST end in a slash

  // Metadata bits
  string private metadataName = 'PLSDSock Genesis';
  string private externalUrl = "https://pulsedogecoin.com/";

  // The final ver. of animationUrl and imageUrl will be a basename with a slash.
  // Example: /image.gif
  string private animationUrl = "ipfs://bafybeidevyv7ahy7li2ips4cz5euglgwsxbsd377kyqo32k6k32viyxcsi/blob";
  string private imageUrl = "ipfs://bafybeihhsup6evyhugc7s23zsaei4qlr5d4afpjegczzkkgxrme7on633i/blob";

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
  ** Assertions and booleans.
  ******
  */
  function canClaim(
    bytes32[] calldata proof,
    uint256 whitelistAmount,
    uint256 mintAmount
  )
    external
    view
    returns(bool)
  {
    return _assertCanClaim(proof, whitelistAmount, mintAmount);
  }

  function remainingMintAmount(
    bytes32[] calldata proof,
    uint256 whitelistAmount
  )
    external
    view
    returns(uint256)
  {
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), whitelistAmount));
    bool verified = MerkleProof.verify(proof, merkleRoot, leaf);

    if(verified) {
      uint256 whitelistClaimed = whitelistClaimedAmount[_msgSender()];

      return whitelistClaimed == uint256(0x0) ? whitelistAmount : whitelistAmount - whitelistClaimed;
    } else {
      return 0;
    }
  }

  function _assertCanClaim(
    bytes32[] calldata proof,
    uint256 whitelistAmount,
    uint256 mintAmount
  )
    internal
    view
    returns(bool)
  {
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), whitelistAmount));
    require(MerkleProof.verify(proof, merkleRoot, leaf), "No claim in the whitelist!");

    uint256 whitelistClaimed = whitelistClaimedAmount[_msgSender()] == uint256(0x0)
      ? 0
      : whitelistClaimedAmount[_msgSender()];

    require(whitelistClaimed + mintAmount <= whitelistAmount, "Exceeded your whitelist amount!");

    return true;
  }

  function _assertFeeEnough(uint256 mintAmount)
    internal
    view
    returns(bool)
  {
    require(msg.value >= (fee * mintAmount), "Not enough ETH provided for fee");

    return true;
  }

  modifier mintCompliance(uint256 mintAmount) {
    require(totalSupply() + mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  /*
  ******
  ** Minting functions
  ******
  */
  function whitelistMint(bytes32[] calldata proof, uint256 whitelistAmount, uint256 mintAmount) public payable mintCompliance(mintAmount) nonReentrant {
    _assertCanClaim(proof, whitelistAmount, mintAmount);
    _assertFeeEnough(mintAmount);

    whitelistClaimedAmount[_msgSender()] += mintAmount;
    _safeMint(_msgSender(), mintAmount);
  }

  function mintForAddress(address receiver, uint256 mintAmount) public mintCompliance(mintAmount) onlyOwner {
    _safeMint(receiver, mintAmount);
  }

  /*
  ******
  ** Token URI functions
  ******
  */
  function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
    if (revealed == false) {
      return _hiddenTokenUri(tokenId);
    }

    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(
      '{',
        '"name": "', metadataName, ' #', Strings.toString(tokenId), '", ',
        '"external_url": "', externalUrl, '", ',
        '"image": "', baseUri, Strings.toString(tokenId), imageUrl, '", ',
        '"animation_url": "', baseUri, Strings.toString(tokenId), animationUrl, '", ',
        '"attributes": [',
          '{',
            '"trait_type": "Sock Claim Status",',
            '"value": ', _claimedSocks[tokenId] ? '"Claimed"' : '"Not Claimed"',
          '}',
        ']',
      '}'
    ))));
  }

  function _hiddenTokenUri(uint256 tokenId) internal view returns(string memory) {
    return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(
      '{',
        '"name": "', metadataName, ' #', Strings.toString(tokenId), '", ',
        '"external_url": "', externalUrl, '", ',
        '"image": "', imageUrl, '", ',
        '"animation_url": "', animationUrl, '", ',
        '"attributes": [',
          '{',
            '"trait_type": "Sock Claim Status",',
            '"value": ', _claimedSocks[tokenId] ? '"Claimed"' : '"Not Claimed"',
          '}',
        ']',
      '}'
    ))));
  }

  /*
  ******
  ** Royalty Info (EIP 2981)
  ** This interface isn't supported yet by major nft marketplaces, but could be in the future
  ******
  */

  // Support the royalty interface
  function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {

    return
      interfaceId == 0x2a55205a || // ERC165 interface ID for ERC2981 NFT Royalty Standard.
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
      interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
      interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
  }

  function setRoyalty(address /*_receiver*/, uint96 _fee) public onlyOwner {
    royaltyFee = _fee;
  }

  // Royalty the same regardless of tokenId
  function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice) public view virtual returns (address, uint256) {
    uint256 royaltyAmount = (_salePrice * royaltyFee) / 10000;

    return (owner(), royaltyAmount);
  }

  /*
  ******
  ** Australian Setters
  ******
  */
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }
  function setFee(uint256 _fee) public onlyOwner {
    fee = _fee;
  }
  function setBaseUri(string memory _baseUri) public onlyOwner {
    baseUri = _baseUri;
  }
  function setTokenUriDetails(
    string memory _metadataName,
    string memory _externalUrl,
    string memory _imageUrl,
    string memory _animationUrl
  ) public onlyOwner {
    bytes(_metadataName).length != 0 ? metadataName = _metadataName : '';
    bytes(_externalUrl).length != 0 ? externalUrl = _externalUrl : '';
    bytes(_animationUrl).length != 0 ? animationUrl = _animationUrl : '';
    bytes(_imageUrl).length != 0 ? imageUrl = _imageUrl : '';
  }

  /*
  ******
  ** Burn baby burn
  ******
  */
  function burn(uint256 tokenId) public virtual {
    amountBurned[_msgSender()] += 1;
    _burn(tokenId, true);
  }

  /*
  ******
  ** Claimer-aimers
  ******
  */
  function claimSock(uint256 tokenId) public {
    require(ownerOf(tokenId) == _msgSender(), "You must own tokens that you claim");
    require(_claimedSocks[tokenId] == false, "Sock already claimed");

    _claimedSocks[tokenId] = true;
  }

  function hasClaimedSock(uint256 tokenId) public view returns(bool) {
    return _claimedSocks[tokenId];
  }

  /*
  ******
  ** Withdrawly
  ******
  */
  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
    require(address(this).balance == 0x0, "Transfer failed");
  }
}