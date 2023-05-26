// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract FlufSceneAndMusic is ERC1155, ERC1155Holder, Ownable {
  // ERC1155 id => Asset Name
  struct flufLocked {
    uint256 background;
    uint256 music;
  }

  struct assetDescription {
    string assetType; // Background / Music
    string assetName; // Dunes / Lambo etc
  }

  mapping(uint256 => assetDescription) public assets;
  // fluf tokenId => ERC1155 id
  mapping(uint256 => flufLocked) public flufLock;
  mapping(uint256 => bool) public flufHasDefault;
  //mapping(uint256 => uint256) public flufLock;
  event Swap(
    address by,
    uint256 musicAssetLockIn,
    uint256 backgroundAssetLockIn,
    uint256 tokenId
  );

  address public signingWallet;
  address public flufAddress;

  string public name;

  constructor() ERC1155("https://erc1155-api.fluf.world/token/") {
    name = "FLUF World: Scenes and Sounds";
  }

  function setTokenURI(string memory _tokenURI) public onlyOwner {
      _setURI(_tokenURI);
  }
  
  function getTokenURI(uint256 _id) 
    public 
    view 
    returns (string memory)
  {
    string memory idToString = Strings.toString(_id);
    string memory uri = uri(_id);
    string memory tokenURI = string(abi.encodePacked(uri, idToString));
    return tokenURI;
  }

  function setContractName(string memory _name) public onlyOwner {
    name = _name;
  }

  function setFlufAddress(address _address) public onlyOwner {
    flufAddress = _address;
  }

  function updateSigningWallet(address _address) public onlyOwner {
    signingWallet = _address;
  }

  function setDefaultForFluf(
    uint256 _flufId,
    uint256 _defaultBackground,
    uint256 _defaultMusic
  ) internal {
    // Person has to be the owner of the fluf that he is setting the default for
    require(flufHasDefault[_flufId] != true, "Fluf default was already set");
    require(isFlufOwner(_flufId, msg.sender), "You do not own this FLUF");
    flufLock[_flufId].background = _defaultBackground;
    flufLock[_flufId].music = _defaultMusic;
    flufHasDefault[_flufId] = true;
  }

  function adminSetDefaultForFluf(
    uint256 _flufId,
    uint256 _defaultBackground,
    uint256 _defaultMusic
  ) public onlyOwner {
    flufLock[_flufId].background = _defaultBackground;
    flufLock[_flufId].music = _defaultMusic;
    flufHasDefault[_flufId] = true;
  }

  function splitSignature(bytes memory sig)
    public
    pure
    returns (
      bytes32 r,
      bytes32 s,
      uint8 v
    )
  {
    require(sig.length == 65, "invalid signature length");

    assembly {
      // first 32 bytes, after the length prefix
      r := mload(add(sig, 32))
      // second 32 bytes
      s := mload(add(sig, 64))
      // final byte (first byte of the next 32 bytes)
      v := byte(0, mload(add(sig, 96)))
    }

    // implicitly return (r, s, v)
  }

  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
    public
    pure
    returns (address)
  {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

    return ecrecover(_ethSignedMessageHash, v, r, s);
  }

  function approveAndSetDefault(
    bytes32 _ethSignedMessageHash,
    bytes memory _signature,
    uint256 flufId,
    uint256 _defaultBackground,
    uint256 _defaultMusic
  ) public {
    // Require _signature to be from signingWallet
    require(
      recoverSigner(_ethSignedMessageHash, _signature) == signingWallet,
      "VAULT LOCK: Message must be sent from authorized signer."
    );
    // Set Approval
    setApprovalForAll(address(this), true);
    setDefaultForFluf(flufId, _defaultBackground, _defaultMusic);
  }

  function listNewAsset(
    uint256 _id,
    string memory _assetName,
    string memory _assetType
  ) public onlyOwner returns (bool) {
    assets[_id].assetName = _assetName;
    assets[_id].assetType = _assetType;
    return true;
  }
  
  function listNewAssetBatch(
    uint256[] memory _ids,
    string[] memory _assetNames,
    string[] memory _assetTypes
  ) public onlyOwner returns (bool) {
    for (uint256 i = 0; i < _ids.length; i++) {
      assets[_ids[i]].assetName = _assetNames[i];
      assets[_ids[i]].assetType = _assetTypes[i];
    }
    return true;
  }


  function getAssetIdType(uint256 _id) public view returns (string memory) {
    return assets[_id].assetType;
  }

  function mintBatch(uint256[] memory ids, uint256[] memory amounts)
    public
    onlyOwner
  {
    _mintBatch(msg.sender, ids, amounts, "");
  }

  function withdrawFunds() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  // Let's see if this user is actually the holder of a specific fluf
  function isFlufOwner(uint256 tokenId, address _address)
    public
    view
    returns (bool)
  {
    address owner = IERC721(flufAddress).ownerOf(tokenId);
    if (owner == _address) {
      return true;
    } else {
      return false;
    }
  }

  function swap(
    uint256 tokenId,
    uint256 backgroundAssetLockIn,
    uint256 musicAssetLockIn
  ) public {
    require(
      isFlufOwner(tokenId, msg.sender),
      "VAULT HALT: You can't mess with other peoples flufs"
    );
    require(getFlufHasDefault(tokenId), "Fluf default was not set yet");

    bool doBackground = true;
    bool doMusic = true;

    // If the background is the same no need to be doing it
    if (backgroundAssetLockIn == flufLock[tokenId].background) {
      doBackground = false;
    }
    // If the music one is the same there is no need to be doing it
    if (musicAssetLockIn == flufLock[tokenId].music) {
      doMusic = false;
    }

    if (doBackground == true) {
      _safeTransferFrom(
        msg.sender,
        address(this),
        backgroundAssetLockIn,
        1,
        ""
      );
      _safeTransferFrom(
        address(this),
        msg.sender,
        flufLock[tokenId].background,
        1,
        ""
      );
      flufLock[tokenId].background = backgroundAssetLockIn;
    }

    if (doMusic == true) {
      _safeTransferFrom(msg.sender, address(this), musicAssetLockIn, 1, "");
      _safeTransferFrom(
        address(this),
        msg.sender,
        flufLock[tokenId].music,
        1,
        ""
      );
      flufLock[tokenId].music = musicAssetLockIn;
    }

    emit Swap(msg.sender, musicAssetLockIn, backgroundAssetLockIn, tokenId);
  }

  function getFlufHasDefault(uint256 _flufId) public view returns (bool) {
    if (flufHasDefault[_flufId]) {
      return true;
    }
    return false;
  }

  function emergencyTokenWithdraw(uint256 _asset, uint256 _amount)
    public
    onlyOwner
  {
    _safeTransferFrom(address(this), msg.sender, _asset, _amount, "");
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155, ERC1155Receiver)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}