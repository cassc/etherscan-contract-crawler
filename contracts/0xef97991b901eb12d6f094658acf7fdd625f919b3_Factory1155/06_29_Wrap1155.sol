// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import '../interfaces/IMarket.sol';
import '../interfaces/IVault.sol';

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract Wrap1155 is ERC1155 {
  string public name;
  string public symbol;
  address private _vault;
  address private _market;
  uint256 initialized = 0;

  /* tokenId => renter EOA address => lockId */
  mapping(uint256 => mapping(address => uint256[])) private _userToLocks;
  // tokenId => lockId[]
  mapping(uint256 => uint256[]) private _tokenToLocks;

  constructor(
    string memory _name,
    string memory _symbol,
    address marketAddress
  ) ERC1155('') {
    name = _name;
    symbol = _symbol;
    _vault = msg.sender;
    _market = marketAddress;
  }

  function setURI(string memory _uri) public {
    require(msg.sender == IVault(_vault).collectionOwner(), 'onlyCollectionOwner');
    _setURI(_uri);
    initialized = 1;
  }

  function balanceOf(address account, uint256 id) public view override returns (uint256) {
    uint256 _now = block.timestamp;
    uint256 _balance = 0;
    for (uint256 x = 0; x < _userToLocks[id][account].length; x++) {
      IMarket.Rent[] memory _rents = IMarket(_market)
        .getLendRent(_userToLocks[id][account][x])
        .rent;
      for (uint256 i = 0; i < _rents.length; i++) {
        if (
          _rents[i].renterAddress == account &&
          _rents[i].rentalStartTime <= _now &&
          _now <= _rents[i].rentalExpireTime
        ) _balance += _rents[i].amount;
      }
    }
    return _balance; // balanceOfBatch calls balanceOf internally, so no implementation required
  }

  function emitTransfer(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    uint256 lockId
  ) public {
    require(msg.sender == _vault, 'onlyVault');

    bool _exist = false;
    //トークンIDごとに、ロックIDが複数つく場合があるので、今なんこLockIDが紐づいているか確認
    for (uint256 i = 0; i < _tokenToLocks[id].length; i++)
      // 今借りたNFTのlockIDがすでに借りられていた場合：つまり10個あるうち、自分が借りた分以外の数を誰かが先に借りていた場合
      if (_tokenToLocks[id][i] == lockId) _exist = true; // 存在するフラグを立てる
    if (!_exist) _tokenToLocks[id].push(lockId); // 存在していなかった場合には、lockIdを追加する
    _exist = false; //フラグを戻す
    for (
      uint256 i = 0;
      i < _userToLocks[id][to].length;
      i++ //トークンIDごとにユーザーを複数紐づけているのでその長さをとる
    ) if (_userToLocks[id][to][i] == lockId) _exist = true; //自分が借りたトークンIDを別の貸板で借りていた場合 true
    if (!_exist) _userToLocks[id][to].push(lockId); // そうでなかった場合は追加する
    emit TransferSingle(_vault, from, to, id, amount); //transfer
  }

  function uri(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC1155Metadata: URI query for nonexistent token');
    if (initialized == 0) {
      address _originalNftAddress = IVault(_vault).originalCollection();
      return IERC1155MetadataURI(_originalNftAddress).uri(_tokenId);
    } else {
      return string(abi.encodePacked(super.uri(_tokenId), Strings.toString(_tokenId)));
    }
  }

  function _exists(uint256 _tokenId) internal view returns (bool) {
    // Check Lend existence
    if (_tokenToLocks[_tokenId].length == 0) return false;
    // Check Rent existence
    for (uint256 i = 0; i < _tokenToLocks[_tokenId].length; i++) {
      IMarket.Rent[] memory _rents = IMarket(_market).getLendRent(_tokenToLocks[_tokenId][i]).rent;
      for (uint256 j = 0; j < _rents.length; j++) {
        if (_rents[j].rentalExpireTime > block.timestamp) return true;
      }
    }
    return false;
  }

  modifier disabled() {
    require(false, 'Disabled function');
    _;
  }

  function setApprovalForAll(address operator, bool _approved) public override disabled {}

  function isApprovedForAll(address owner, address operator)
    public
    view
    override
    disabled
    returns (bool)
  {}

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) public override disabled {}

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) public override disabled {}
}