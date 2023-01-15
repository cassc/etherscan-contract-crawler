//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract AdminUpgradeable is ContextUpgradeable {
  event AdminAdded(address);
  event AdminRemoved(address);

  /**
   * @dev 管理者のマッピング。管理者でないならばfalseを返す。
   */
  mapping(address => bool) private _admin;

  function __Admin_init() internal onlyInitializing {
    __Context_init();
    // 初期化時にデプロイ者を管理者に追加する。
    _addAdmin(_msgSender());
  }

  /**
   * @dev 管理者を複数追加
   */
  function addAdmin(address[] calldata newAdmin) public virtual onlyAdmin {
    for (uint256 idx = 0; idx < newAdmin.length; idx++) {
      _addAdmin(newAdmin[idx]);
    }
  }

  /**
   * @dev 管理者を一人追加
   */
  function addAdmin(address newAdmin) public virtual onlyAdmin {
    _addAdmin(newAdmin);
  }

  /**
   * @dev 管理者を一人追加
   * 無制限 Internal function
   */
  function _addAdmin(address newAdmin) internal virtual {
    require(
      newAdmin != address(0),
      "Admin:addAdmin newAdmin is the zero address"
    );

    _admin[newAdmin] = true;
    emit AdminAdded(newAdmin);
  }

  /**
   * @dev 管理者を一人削除
   */
  function removeAdmin(address admin) public virtual onlyAdmin {
    require(
      _admin[admin],
      "Admin:removeAdmin trying to remove non existing Admin"
    );

    _removeAdmin(admin);
  }

  /**
   * @dev 管理者を一人削除
   * 無制限 Internal function
   */
  function _removeAdmin(address admin) internal virtual {
    delete _admin[admin];
    emit AdminRemoved(admin);
  }

  /**
   * @dev
   * Adminかどうかのチェック
   */
  function isAdmin(address checkAdmin) public view virtual returns (bool) {
    return _admin[checkAdmin];
  }

  /**
   * @dev Throws if called by any account other than Admin.
   */
  modifier onlyAdmin() {
    require(_admin[_msgSender()], "Admin:onlyAdmin caller is not an Admin");
    _;
  }
}