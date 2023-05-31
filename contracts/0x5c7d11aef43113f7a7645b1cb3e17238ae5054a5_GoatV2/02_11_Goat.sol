// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721AQueryableGoat.sol";

contract Goat is ERC721AQueryableGoat, BaseTokenURI {
  using Strings for uint256;
  using ECDSA for bytes32;

  address public signatureSigner;

  mapping(uint256 => bool) public isTokenNotNested; // false == nesting, true == not nested
  mapping(uint256 => uint256) public sendNonce;
  mapping(address => uint256) public mintNonce;
  mapping(address => bool) public isAdmin;

  event Nested(uint256 indexed tokenId);
  event Unnested(uint256 indexed tokenId);

  modifier isAdminOrOwner(address _address) {
    require(isAdmin[_address] || _address == owner(), "Goat: Only admin or owner can call this function");
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    address _signer
  ) ERC721AGoat(_name, _symbol) BaseTokenURI(_initBaseURI) {
    signatureSigner = _signer;
  }

  function _baseURI() internal view override(BaseTokenURI, ERC721AGoat) returns (string memory) {
    return BaseTokenURI._baseURI();
  }

  function tokenURI(uint256 tokenId) public view override(ERC721AGoat) returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: tokenURI queried for nonexistent token");
    string memory currentBaseURI = Goat._baseURI();
    return
      bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
  }

  function mint(uint256 _mintPrice, bytes memory _signature) external payable {
    require(
      isSignatureValid(address(0), _msgSender(), 0, _mintPrice, mintNonce[_msgSender()], _signature),
      "Goat: Invalid signature"
    );
    require(msg.value >= _mintPrice, "Goat: price is higher than the amount of ETH sent");

    if (_mintPrice < msg.value) {
      (bool success, ) = address(_msgSender()).call{value: msg.value - _mintPrice}("");
      require(success, "Unable to send ETH to minter");
    }

    _mint(_msgSender(), 1);
    mintNonce[_msgSender()] += 1;
  }

  function sendToken(
    uint256 _tokenId,
    address _receiver,
    uint256 _price,
    bytes memory _signature
  ) external payable virtual {
    address owner = ownerOf(_tokenId);
    require(
      isSignatureValid(owner, _receiver, _tokenId, _price, sendNonce[_tokenId], _signature),
      "Goat: invalid signature"
    );
    require(msg.value >= _price, "Goat: price is higher than the amount of ETH sent");

    if (owner != _msgSender()) {
      _tokenApprovals[_tokenId] = _msgSender();
    }

    safeTransferFromWithoutCheckingNesting(owner, _receiver, _tokenId);

    if (_price != 0) {
      (bool success, ) = address(owner).call{value: _price}("");
      require(success, "Unable to send ETH to owner of token");

      if (_price < msg.value) {
        (success, ) = address(_receiver).call{value: msg.value - _price}("");
        require(success, "Unable to send ETH to buyer");
      }
    }

    sendNonce[_tokenId] += 1;
  }

  /**
    @dev Block transfers while nesting.
     */
  function _beforeTokenTransfers(
    address from,
    address,
    uint256 startTokenId,
    uint256 quantity
  ) internal view override {
    uint256 tokenId = startTokenId;
    for (uint256 i = tokenId; i < (tokenId + quantity); ++i) {
      require(from == address(0) || isTokenNotNested[i], "Goat: token is nesting");
    }
  }

  // ONLY ADMIN FUNCTION
  function toggleNesting(uint256 _tokenId) external isAdminOrOwner(_msgSender()) {
    bool isNesting = !isTokenNotNested[_tokenId];
    isTokenNotNested[_tokenId] = !isTokenNotNested[_tokenId];
    if (isNesting == false) {
      emit Nested(_tokenId);
    } else {
      emit Unnested(_tokenId);
    }
  }

  function adminMint(address[] calldata _tos, bool[] calldata _isNested) external isAdminOrOwner(_msgSender()) {
    require(_tos.length == _isNested.length, "Goat: entries length not match");
    for (uint256 i; i < _tos.length; i++) {
      uint256 tokenId = _nextTokenId();
      _mint(_tos[i], 1);
      if (_isNested[i] == false) {
        isTokenNotNested[i] = true;
      }
      emit Nested(tokenId);
    }
  }

  // ONLY OWNER FUNCTION
  function ownerMint(
    address[] calldata _tos,
    uint256[] calldata _amounts,
    bool[] calldata _isNested
  ) external onlyOwner {
    require(_tos.length == _amounts.length && _tos.length == _isNested.length, "Goat: entries length not match");
    for (uint256 i; i < _tos.length; i++) {
      uint256 tokenId = _nextTokenId();
      _mint(_tos[i], _amounts[i]);
      if (_isNested[i] == false) {
        for (uint256 j = tokenId; j < (tokenId + _amounts[i]); ++j) {
          isTokenNotNested[j] = true;
        }
      }
      emit Nested(tokenId);
    }
  }

  function assignAdmins(address[] calldata _admins) external onlyOwner {
    for (uint256 i = 0; i < _admins.length; i++) {
      isAdmin[_admins[i]] = true;
    }
  }

  function revokeAdmins(address[] calldata _admins) external onlyOwner {
    for (uint256 i = 0; i < _admins.length; i++) {
      isAdmin[_admins[i]] = false;
    }
  }

  function setSignatureSigner(address _signer) external onlyOwner {
    signatureSigner = _signer;
  }

  function withdraw(address _receiver) external onlyOwner {
    (bool success, ) = address(_receiver).call{value: address(this).balance}("");
    require(success, "Unable to withdraw balance");
  }

  function isSignatureValid(
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _price,
    uint256 _nonce,
    bytes memory signature
  ) internal view returns (bool) {
    bytes32 hash = keccak256(abi.encodePacked(_from, _to, _tokenId, _price, _nonce, address(this)));
    hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    return signatureSigner == hash.recover(signature);
  }
}