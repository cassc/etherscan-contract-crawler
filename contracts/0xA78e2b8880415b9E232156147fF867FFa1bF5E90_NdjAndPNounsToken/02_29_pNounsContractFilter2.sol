// SPDX-License-Identifier: MIT

/*
 * Created by Eiba (@eiba8884)
 */
/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import './libs/ProviderTokenA1.sol';
import 'contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';

contract pNounsContractFilter2 is ProviderTokenA1, AccessControlEnumerable, ERC2981 {
  bytes32 public constant CONTRACT_ADMIN = keccak256('CONTRACT_ADMIN');

  IContractAllowListProxy public cal;
  uint256 public calLevel = 1;

  mapping(address => bool) public isPNounsMarketplaces; // approveを許可するコントラクトアドレス

  constructor(
    IAssetProvider _assetProvider,
    string memory _title,
    string memory _shortTitle,
    address[] memory _administrators
  ) ProviderTokenA1(_assetProvider, _title, _shortTitle) {
    _setRoleAdmin(CONTRACT_ADMIN, CONTRACT_ADMIN);

    for (uint256 i = 0; i < _administrators.length; i++) {
      _setupRole(CONTRACT_ADMIN, _administrators[i]);
    }
  }

  ////////// modifiers //////////
  modifier onlyAdminOrOwner() {
    require(hasAdminOrOwner(), 'caller is not the admin');
    _;
  }

  ////////// internal functions start //////////
  function hasAdminOrOwner() internal view returns (bool) {
    return owner() == _msgSender() || hasRole(CONTRACT_ADMIN, _msgSender());
  }

  ////////// onlyOwner functions start //////////
  function setAdminRole(address[] memory _administrators) external onlyAdminOrOwner {
    for (uint256 i = 0; i < _administrators.length; i++) {
      _grantRole(CONTRACT_ADMIN, _administrators[i]);
    }
  }

  function revokeAdminRole(address[] memory _administrators) external onlyAdminOrOwner {
    for (uint256 i = 0; i < _administrators.length; i++) {
      _revokeRole(CONTRACT_ADMIN, _administrators[i]);
    }
  }

  ////////// ERC2981 functions start //////////
  function setDefaultRoyalty(address payable recipient, uint96 value) external onlyAdminOrOwner {
    _setDefaultRoyalty(recipient, value);
  }

  function deleteDefaultRoyalty() external onlyAdminOrOwner {
    _deleteDefaultRoyalty();
  }

  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) external onlyAdminOrOwner {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  function resetTokenRoyalty(uint256 tokenId) external onlyAdminOrOwner {
    _resetTokenRoyalty(tokenId);
  }

  ////////////// CAL 関連 ////////////////
  function setCalContract(IContractAllowListProxy _cal) external onlyAdminOrOwner {
    cal = _cal;
  }

  function setCalLevel(uint256 _value) external onlyAdminOrOwner {
    calLevel = _value;
  }

  // overrides
  function setApprovalForAll(address operator, bool approved) public virtual override {
    // calLevel=0は calProxyに依存せずにfalseにする
    if (calLevel == 0) {
      revert('cant trade in marcket places');
    }

    if (address(cal) != address(0)) {
      require(cal.isAllowed(operator, calLevel) == true, 'address no list');
    }
    super.setApprovalForAll(operator, approved);
  }

  function approve(address to, uint256 tokenId) public payable virtual override {
    // calLevel=0は calProxyに依存せずにfalseにする
    if (calLevel == 0) {
      revert('cant trade in marcket places');
    }

    if (address(cal) != address(0)) {
      require(cal.isAllowed(to, calLevel) == true, 'address no list');
    }
    super.approve(to, tokenId);
  }

  function setPNounsMarketplace(address _marketplace, bool _allow) public onlyAdminOrOwner {
    isPNounsMarketplaces[_marketplace] = _allow;
  }

  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    // 登録済みアドレスはOK
    if (isPNounsMarketplaces[operator]) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(AccessControlEnumerable, ERC721AP2P, ERC2981)
    returns (bool)
  {
    return
      interfaceId == type(IAccessControlEnumerable).interfaceId ||
      interfaceId == type(IAccessControl).interfaceId ||
      interfaceId == type(ERC2981).interfaceId ||
      ERC721A.supportsInterface(interfaceId);
  }
}