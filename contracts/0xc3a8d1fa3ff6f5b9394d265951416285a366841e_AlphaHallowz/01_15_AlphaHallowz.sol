// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//                                                   ......
//                                         .';codxOO00KKKK00Okxdoc;'.
//                                     .,lkKNWMMMMMMMMMMMMMMMMMMMMWNKkl,.
//                                   ,o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o'
//                                 'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx'
//                               .cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.
//                              .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.
//                              cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc
//                             .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.
//                             :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:
//                             lWMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXNWMMMNl
//                             'lolc:;,,,:lxKWMMMMMMMMMMMMMMMMMMMW0d:'....',:lol'
//                                          .:xXWMMMMMMMMMMMMMMXx;.
//                                             .oKMMMMMMMMMMMNx'
//                                               'xNMMMMMMMMXl.
//                               :Od:'.        ..;dXMMMMWMMMXd;..        .'cdx,
//                               oWMWNK0kxxxxkOKNWMMMXdccdXMMMWNKOkxxxxk0KNWMX:
//                               oWMMMMMMMMMMMMMMMMWk,    ,kWMMMMMMMMMMMMMMMMX;
//                               ;KMMMMMMMMMMMMMMMNd.      .dNMMMMMMMMMMMMMMMO.
//                                'ok0KXNNNWWMMMMMK,        ,KMMMMMWWNNNNXKOd'
//                                   ...''',dNMMMMNd'      'dNMMMMNd,'''...
//                                          :NMMMMMWXkollokXWMMMMMN:
//                                          cNMMMMMMMMMMMMMMMMMMMMNc
//                                          lNMNOkXMMMNXNWMMWKkKWMNl
//                                          oWM0'.dWMNo,;kMMX: :XMWo
//                                          oWMx. lWMX; .oWM0' '0MWo
//                                          'cl,  ;0Xk.  :0Xd.  ,ll,
//                                                 ...    ...
//
//   ▄▄▄       ██▓     ██▓███   ██░ ██  ▄▄▄       ██░ ██  ▄▄▄       ██▓     ██▓     ▒█████   █     █░▒███████▒
//  ▒████▄    ▓██▒    ▓██░  ██▒▓██░ ██▒▒████▄    ▓██░ ██▒▒████▄    ▓██▒    ▓██▒    ▒██▒  ██▒▓█░ █ ░█░▒ ▒ ▒ ▄▀░
//  ▒██  ▀█▄  ▒██░    ▓██░ ██▓▒▒██▀▀██░▒██  ▀█▄  ▒██▀▀██░▒██  ▀█▄  ▒██░    ▒██░    ▒██░  ██▒▒█░ █ ░█ ░ ▒ ▄▀▒░
//  ░██▄▄▄▄██ ▒██░    ▒██▄█▓▒ ▒░▓█ ░██ ░██▄▄▄▄██ ░▓█ ░██ ░██▄▄▄▄██ ▒██░    ▒██░    ▒██   ██░░█░ █ ░█   ▄▀▒   ░
//   ▓█   ▓██▒░██████▒▒██▒ ░  ░░▓█▒░██▓ ▓█   ▓██▒░▓█▒░██▓ ▓█   ▓██▒░██████▒░██████▒░ ████▓▒░░░██▒██▓ ▒███████▒
//   ▒▒   ▓▒█░░ ▒░▓  ░▒▓▒░ ░  ░ ▒ ░░▒░▒ ▒▒   ▓▒█░ ▒ ░░▒░▒ ▒▒   ▓▒█░░ ▒░▓  ░░ ▒░▓  ░░ ▒░▒░▒░ ░ ▓░▒ ▒  ░▒▒ ▓░▒░▒
//    ▒   ▒▒ ░░ ░ ▒  ░░▒ ░      ▒ ░▒░ ░  ▒   ▒▒ ░ ▒ ░▒░ ░  ▒   ▒▒ ░░ ░ ▒  ░░ ░ ▒  ░  ░ ▒ ▒░   ▒ ░ ░  ░░▒ ▒ ░ ▒
//    ░   ▒     ░ ░   ░░        ░  ░░ ░  ░   ▒    ░  ░░ ░  ░   ▒     ░ ░     ░ ░   ░ ░ ░ ▒    ░   ░  ░ ░ ░ ░ ░
//        ░  ░    ░  ░          ░  ░  ░      ░  ░ ░  ░  ░      ░  ░    ░  ░    ░  ░    ░ ░      ░      ░ ░
//                                                                                                   ░

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";
import "./ISoulz.sol";

error ClaimPaused();
error AlreadyClaimed();
error InvalidSignature();
error MintPaused();
error MintExceedsMintLimit();
error MintExceedsMaxSupply();

contract AlphaHallowz is AccessControl, ERC721A {
  bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

  uint256 public collectionSize;
  uint256 public basePrice;
  uint256 public maxTokenPrice;
  uint256 public maxPerMint;
  ISoulz public soulzAddress;

  string private baseTokenURI;

  bool public claimActive = false;
  bool public mintActive = false;

  constructor(
    uint256 _collectionSize,
    uint256 _basePrice,
    uint256 _maxTokenPrice,
    uint256 _maxPerMint,
    address _soulzAddress
  ) ERC721A("AlphaHallowz", "HALLOWZ") {
    collectionSize = _collectionSize;
    basePrice = _basePrice;
    maxTokenPrice = _maxTokenPrice;
    maxPerMint = _maxPerMint;
    soulzAddress = ISoulz(_soulzAddress);

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function claim(uint256 amount, bytes calldata signature) external {
    if (!claimActive) revert ClaimPaused();
    if (totalSupply() + amount > collectionSize) revert MintExceedsMaxSupply();
    if (!_validateClaim(signature, amount)) revert InvalidSignature();

    uint64 numClaimed = _getAux(_msgSender());
    if (numClaimed > 0) revert AlreadyClaimed();

    _safeMint(_msgSender(), amount);
    _setAux(_msgSender(), uint64(amount));
  }

  function mint(uint256 amount) external {
    if (!mintActive) revert MintPaused();
    if (amount > maxPerMint) revert MintExceedsMintLimit();
    if (totalSupply() + amount > collectionSize) revert MintExceedsMaxSupply();

    uint256 price = _getPrice(_msgSender(), amount);
    soulzAddress.spendSoulz(_msgSender(), price);

    _safeMint(_msgSender(), amount);
  }

  function getPrice(address owner, uint256 amount) external view returns (uint256) {
    return _getPrice(owner, amount);
  }

  function numberClaimed(address owner) external view returns (uint256) {
    return _getAux(owner);
  }

  function numberMinted(address owner) external view returns (uint256) {
    return _numberMinted(owner);
  }

  function ownershipDataOf(uint256 tokenId) external view returns (TokenOwnership memory) {
    return ownershipOf(tokenId);
  }

  function setCollectionSize(uint256 _collectionSize) external onlyRole(DEFAULT_ADMIN_ROLE) {
    collectionSize = _collectionSize;
  }

  function setBasePrice(uint256 _basePrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
    basePrice = _basePrice;
  }

  function setMaxTokenPrice(uint256 _maxTokenPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
    maxTokenPrice = _maxTokenPrice;
  }

  function setMaxPerMint(uint256 _maxPerMint) external onlyRole(DEFAULT_ADMIN_ROLE) {
    maxPerMint = _maxPerMint;
  }

  function setClaimStatus(bool _active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    claimActive = _active;
  }

  function setMintStatus(bool _active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    mintActive = _active;
  }

  function setBaseURI(string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
    baseTokenURI = _uri;
  }

  function devMint(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (totalSupply() + amount > collectionSize) revert MintExceedsMaxSupply();
    require(amount % maxPerMint == 0, "can only mint a multiple of the maxPerMint");
    uint256 numChunks = amount / maxPerMint;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(_msgSender(), maxPerMint);
    }
  }

  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 balance = address(this).balance;
    (bool ok, ) = payable(_msgSender()).call{value: balance}("");
    require(ok, "Failed to withdraw payment");
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function _getPrice(address owner, uint256 amount) internal view returns (uint256) {
    uint64 claimed = _getAux(owner);
    uint256 minted = _numberMinted(owner) - claimed;
    uint256 total = 0;
    for (uint256 i = minted; i < (minted + amount); i++) {
      uint256 tokenPrice = (i + 1) * basePrice;
      if (tokenPrice > maxTokenPrice) tokenPrice = maxTokenPrice;
      total += tokenPrice;
    }
    return total;
  }

  function _validateClaim(bytes calldata signature, uint256 amount) internal view returns (bool) {
    bytes32 dataHash = keccak256(abi.encodePacked(amount, _msgSender()));
    bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

    address signer = ECDSA.recover(message, signature);
    return hasRole(SIGNER_ROLE, signer);
  }
}