// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: mhxalt.eth
/// @author: seesharp.eth

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// __/\\\\\\\\\\\\___________________________________________________________/\\\\\\\\\\\\\____/\\\\\\___________________________________________________________        
///  _\/\\\////////\\\________________________________________________________\/\\\/////////\\\_\////\\\_________________________________/\\\______________________       
///   _\/\\\______\//\\\____________________/\\\_______________________________\/\\\_______\/\\\____\/\\\________________________________\/\\\______________________      
///    _\/\\\_______\/\\\__/\\\\\\\\\_____/\\\\\\\\\\\__/\\\\\\\\\______________\/\\\\\\\\\\\\\\_____\/\\\________/\\\\\________/\\\\\\\\_\/\\\\\\\\_____/\\\\\\\\\\_     
///     _\/\\\_______\/\\\_\////////\\\___\////\\\////__\////////\\\_____________\/\\\/////////\\\____\/\\\______/\\\///\\\____/\\\//////__\/\\\////\\\__\/\\\//////__    
///      _\/\\\_______\/\\\___/\\\\\\\\\\_____\/\\\________/\\\\\\\\\\____________\/\\\_______\/\\\____\/\\\_____/\\\__\//\\\__/\\\_________\/\\\\\\\\/___\/\\\\\\\\\\_   
///       _\/\\\_______/\\\___/\\\/////\\\_____\/\\\_/\\___/\\\/////\\\____________\/\\\_______\/\\\____\/\\\____\//\\\__/\\\__\//\\\________\/\\\///\\\___\////////\\\_  
///        _\/\\\\\\\\\\\\/___\//\\\\\\\\/\\____\//\\\\\___\//\\\\\\\\/\\___________\/\\\\\\\\\\\\\/___/\\\\\\\\\__\///\\\\\/____\///\\\\\\\\_\/\\\_\///\\\__/\\\\\\\\\\_ 
///         _\////////////______\////////\//______\/////_____\////////\//____________\/////////////____\/////////_____\/////________\////////__\///____\///__\//////////__

interface ZEN_BLOCKS {
  function mint(address _addr, uint256 _amount) external;
  function upgrade(uint256 _tokenId) external;
  function ownerOf(uint256 tokenId) external view returns (address);
}

contract DATA_BLOCKS is ERC1155, Ownable {
  uint256 constant public maxSupply = 2222;
  uint256 public mintedSupply = 0;
  uint256 public burnedSupply = 0;
  uint256 public remainingAirDropSupply = 120;
  
  uint256 public mintActiveTs = 0;
  uint256 public mintPublicActiveTs = 0;
  uint256 public mintZenBlockActiveTs = 0;
  uint256 public upgradeZenBlockActiveTs = 0;

  address public ashContract;
  address public zenBlocksContract;
  address private validatorAddress;

  uint256 constant private _tokenId = 1;
  uint256 constant public priceInASH = 8000000000000000000; // 8 ASH

  uint256 constant private _mintPerAddressLimit = 2; // per wallet mint limit (public sale and allow list are counted separately)
  mapping(address => uint256) private _allowlistMintCntPerAddress;
  mapping(address => uint256) private _mintPublicCntPerAddress;

  bool private _transferLock = true;
  uint256 private _royaltyBps;
  address payable private _royaltyRecipient;

  bytes4 constant private _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
  bytes4 constant private _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
  bytes4 constant private _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

  string constant private _eip191prefixAL = "\x19Ethereum Signed Message:\n34AL_DATA_BLOCKS";
  string constant private _eip191prefixPS = "\x19Ethereum Signed Message:\n130PS_DATA_BLOCKS";

  event MintWillActivateOn(uint256 timestamp);
  event MintDeactivated();
  event MintPublicWillActivateOn(uint256 timestamp);
  event MintPublicDeactivated();
  event MintZenBlockWillActivateOn(uint256 timestamp);
  event MintZenBlockDeactivated();
  event UpgradeZenBlockWillActivateOn(uint256 timestamp);
  event UpgradeZenBlockDeactivated();

  constructor(address _ashContract, address _validatorAddress, string memory uri) ERC1155(uri) {
    ashContract = _ashContract;
    validatorAddress = _validatorAddress;
  }
  
  /**
   * MINT FUNCTIONS
   * NOTE: first 8 bits of nonce is always 0
   */
  function mintPublicWithASH(uint256 _mintAmount, uint256 _timestamp, uint256 _nonce, uint8 v, bytes32 r, bytes32 s) public {
    require(mintPublicActiveTs != 0, "public mint date is not set");
    require(block.timestamp >= mintPublicActiveTs, "wait for public mint time");

    require(block.timestamp <= _timestamp, "timeout");

    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require((mintedSupply + remainingAirDropSupply + _mintAmount) <= maxSupply, "max NFT limit exceeded");

    uint256 addressPublicMintedCount = (_mintPublicCntPerAddress[msg.sender] & 0xFF); // last byte is mint count, other bytes are last used nonce
    require(addressPublicMintedCount + _mintAmount <= _mintPerAddressLimit, "max NFT per address exceeded");

    uint256 old_nonce = (_mintPublicCntPerAddress[msg.sender] >> 8); // to prevent reuse of single mint signature
    require(old_nonce != _nonce, "this signature has already been used");

    require(validatorAddress != address(0x0), "validator not set");
    bytes32 hash = keccak256(abi.encodePacked(_eip191prefixPS, msg.sender, _mintAmount, _timestamp, _nonce));
    require(validatorAddress == ecrecover(hash, v, r, s), "signature is wrong!!");

    bool success = IERC20(ashContract).transferFrom(msg.sender, address(this), priceInASH * _mintAmount);
    require(success, "approve contract for ASH");

    _mintPublicCntPerAddress[msg.sender] = (addressPublicMintedCount + _mintAmount) | (_nonce << 8);
    mintedSupply += _mintAmount;
    _mint(msg.sender, _tokenId, _mintAmount, "");

    if ((mintedSupply + remainingAirDropSupply) == maxSupply) {
      _transferLock = false; // unlock NFT's when mint ends
    }
  }

  function mintAllowlistedWithASH(uint256 _mintAmount, uint8 v, bytes32 r, bytes32 s) public {
    require(mintActiveTs != 0, "mint date is not set");
    require(block.timestamp >= mintActiveTs, "wait for mint time");

    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require((mintedSupply + remainingAirDropSupply + _mintAmount) <= maxSupply, "max NFT limit exceeded");

    uint256 addressMintedCount = _allowlistMintCntPerAddress[msg.sender];
    require(addressMintedCount + _mintAmount <= _mintPerAddressLimit, "max NFT per address exceeded");

    require(validatorAddress != address(0x0), "validator not set");
    bytes32 hash = keccak256(abi.encodePacked(_eip191prefixAL, msg.sender));
    require(validatorAddress == ecrecover(hash, v, r, s), "signature is wrong!!");

    bool success = IERC20(ashContract).transferFrom(msg.sender, address(this), priceInASH * _mintAmount);
    require(success, "approve contract for ASH");

    _allowlistMintCntPerAddress[msg.sender] = addressMintedCount + _mintAmount;
    mintedSupply += _mintAmount;
    _mint(msg.sender, _tokenId, _mintAmount, "");

    if ((mintedSupply + remainingAirDropSupply) == maxSupply) {
      _transferLock = false; // unlock NFT's when mint ends
    }
  }

  /**
   * BURN MECHANICS
   */
  function burnToMintZenBlock(uint256 _burnAmount) public {
    require(mintZenBlockActiveTs != 0, "mint zen block time is not set");
    require(block.timestamp >= mintZenBlockActiveTs, "wait for mint zen block time");

    uint256 userDataBlockCount = balanceOf(msg.sender, _tokenId);
    require(userDataBlockCount >= _burnAmount, "Not enough data block");

    burnedSupply += _burnAmount;
    _burn(msg.sender, _tokenId, _burnAmount);
    ZEN_BLOCKS(zenBlocksContract).mint(msg.sender, _burnAmount);
  }
  function burnToUpgradeZenBlock(uint256 _zenBlockTokenId) public {
    require(upgradeZenBlockActiveTs != 0, "upgrade zen block time is not set");
    require(block.timestamp >= upgradeZenBlockActiveTs, "wait for upgrade zen block time");

    uint256 userDataBlockCount = balanceOf(msg.sender, _tokenId);
    require(userDataBlockCount >= 1, "Not enough data block");
    require(ZEN_BLOCKS(zenBlocksContract).ownerOf(_zenBlockTokenId) == msg.sender, "Not your token");

    burnedSupply += 1;
    _burn(msg.sender, _tokenId, 1);
    ZEN_BLOCKS(zenBlocksContract).upgrade(_zenBlockTokenId);
  }

  /**
   * PUBLIC FUNCTIONS
   */
  function allowlistMintedAmount(address addr) public view returns (uint256) {
    return _allowlistMintCntPerAddress[addr];
  }

  function publicMintedAmount(address addr) public view returns (uint256) {
    return _mintPublicCntPerAddress[addr] & 0xFF;
  }

  function remainingMintableAmount() public view returns (uint256) {
    return maxSupply - mintedSupply - remainingAirDropSupply;
  }


  /**
   * TRANSFER LOCK
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    if (from != address(0x0)){ // minting is allowed
      require(!_transferLock, "ERC1155: transfer not permitted");
    }
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(!_transferLock, "ERC1155: approval not permitted");
    _setApprovalForAll(_msgSender(), operator, approved);
  }


  /**
   * ADMIN FUNCTIONS
   */
  function airDrop(address[] memory _targets, uint256[] memory _mintAmounts) external onlyOwner {
    require((_targets.length) == (_mintAmounts.length), "array lengths should match");

    uint256 txMintedAmount = 0;
    for (uint256 i = 0; i < _targets.length; i++) {
      _mint(_targets[i], _tokenId, _mintAmounts[i], "");
      txMintedAmount += _mintAmounts[i];
    }

    require(txMintedAmount <= remainingAirDropSupply, "max NFT limit exceeded");

    remainingAirDropSupply -= txMintedAmount;
    mintedSupply += txMintedAmount;
  }

  function activateMint(uint256 _mintActiveTs) external onlyOwner {
    require(mintActiveTs == 0, "Already activated");
    mintActiveTs = _mintActiveTs;
    emit MintWillActivateOn(mintActiveTs);
  }
  function deactivateMint() external onlyOwner {
    mintActiveTs = 0;
    emit MintDeactivated();
  }

  function activatePublicMint(uint256 _mintPublicActiveTs) external onlyOwner {
    require(mintPublicActiveTs == 0, "Already activated");
    mintPublicActiveTs = _mintPublicActiveTs;
    emit MintPublicWillActivateOn(mintPublicActiveTs);
  }
  function deactivatPubliceMint() external onlyOwner {
    mintPublicActiveTs = 0;
    emit MintPublicDeactivated();
  }

  function activateZenBlockMint(uint256 _mintZenBlockActiveTs) external onlyOwner {
    require(mintZenBlockActiveTs == 0, "Already activated");
    mintZenBlockActiveTs = _mintZenBlockActiveTs;
    emit MintZenBlockWillActivateOn(mintZenBlockActiveTs);
  }
  function deactivateZenBlockMint() external onlyOwner {
    mintZenBlockActiveTs = 0;
    emit MintZenBlockDeactivated();
  }

  function activateZenBlockUpgrade(uint256 _upgradeZenBlockActiveTs) external onlyOwner {
    require(upgradeZenBlockActiveTs == 0, "Already activated");
    upgradeZenBlockActiveTs = _upgradeZenBlockActiveTs;
    emit UpgradeZenBlockWillActivateOn(upgradeZenBlockActiveTs);
  }
  function deactivateZenBlockUpgrade() external onlyOwner {
    upgradeZenBlockActiveTs = 0;
    emit UpgradeZenBlockDeactivated();
  }

  function setASHContractAddress(address _ashContract) external onlyOwner {
    ashContract = _ashContract;
  }

  function setZenBlocksContractAddress(address _zenBlocksContract) external onlyOwner {
    zenBlocksContract = _zenBlocksContract;
  }

  function setValidatorAddress(address _validatorAddress) external onlyOwner {
    validatorAddress = _validatorAddress;
  }

  function setURI(string memory newuri) external onlyOwner {
    _setURI(newuri);
  }

  function removeTransferLock() external onlyOwner {
    require(_transferLock, "Transfer lock already removed");
    _transferLock = false;
  }

  function withdraw() external onlyOwner {
    require(_royaltyRecipient != address(0x0), "Must set royalty recipient");

    (bool os, ) = _royaltyRecipient.call{value: address(this).balance}("");
    require(os);
  }

  function withdrawERC20(address erc20_addr) external onlyOwner {
    require(_royaltyRecipient != address(0x0), "Must set royalty recipient");

    IERC20 erc20_int = IERC20(erc20_addr);
    uint256 balance = erc20_int.balanceOf(address(this));

    bool os = erc20_int.transfer(_royaltyRecipient, balance);
    require(os);
  }

  /**
   * ROYALTY FUNCTIONS
   */
  function updateRoyalties(address payable recipient, uint256 bps) external onlyOwner {
    _royaltyRecipient = recipient;
    _royaltyBps = bps;
  }

  function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
    if (_royaltyRecipient != address(0x0)) {
      recipients = new address payable[](1);
      recipients[0] = _royaltyRecipient;
      bps = new uint256[](1);
      bps[0] = _royaltyBps;
    }
    return (recipients, bps);
  }

  function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
    if (_royaltyRecipient != address(0x0)) {
      recipients = new address payable[](1);
      recipients[0] = _royaltyRecipient;
    }
    return recipients;
  }

  function getFeeBps(uint256) external view returns (uint[] memory bps) {
    if (_royaltyRecipient != address(0x0)) {
      bps = new uint256[](1);
      bps[0] = _royaltyBps;
    }
    return bps;
  }

  function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
    return (_royaltyRecipient, value*_royaltyBps/10000);
  }

  receive() external payable {
  }


  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
    return ERC1155.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE
           || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
  }
}