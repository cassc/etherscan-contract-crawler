pragma solidity >=0.8.4;
import '@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol';

contract SismoDaoToken is ERC1155PresetMinterPauser {
  bool public _transferable;

  event URIUpdated(string uri);
  event TransferableUpdated(bool transferable);

  /**
   * @dev Constructor.
   * @param baseTokenUri URI of the ERC1155.
   * @param owner The owner of the contract, i.e. which will have DEFAULT_ADMIN_ROLE, MINTER_ROLE and PAUSER_ROLE.
   */
  constructor(string memory baseTokenUri, address owner)
    ERC1155PresetMinterPauser(baseTokenUri)
  {
    if (owner != _msgSender()) {
      _setupRole(DEFAULT_ADMIN_ROLE, owner);
      _setupRole(MINTER_ROLE, owner);
      _setupRole(PAUSER_ROLE, owner);
      renounceRole(PAUSER_ROLE, _msgSender());
      renounceRole(MINTER_ROLE, _msgSender());
    }

    _transferable = true;
  }

  /**
   * @dev Modifier which require the sender to have the DEFAULT_ADMIN_ROLE.
   */
  modifier onlyDefaultAdmin() {
    require(
      hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
      'SISMO_DAO_TOKEN: NOT_DEFAULT_ADMIN'
    );
    _;
  }

  /**
   * @notice Grants the MINTER role to an address.
   * @dev Can only be called by default admin.
   * @param minter The address of the new minter.
   */
  function setMinter(address minter) public {
    // only default admin role can call
    grantRole(MINTER_ROLE, minter);
  }

  /**
   * @notice Update the URI.
   * @dev Can only be called by default admin.
   * @param uri The new URI.
   */
  function updateURI(string memory uri) external onlyDefaultAdmin {
    _setURI(uri);
    emit URIUpdated(uri);
  }

  /**
   * @notice Give up all the roles.
   * @dev Can only be called by the Default Admin.
   */
  function giveUpRoles() external onlyDefaultAdmin {
    renounceRole(PAUSER_ROLE, _msgSender());
    renounceRole(MINTER_ROLE, _msgSender());
    renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /**
   * @notice Update the transferable property.
   * @dev Can only be called by the Default Admin.
   * @param transferable The updated value of the transferable property.
   */
  function updateTransferable(bool transferable) external onlyDefaultAdmin {
    _transferable = transferable;
    emit TransferableUpdated(transferable);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    require(
      _transferable || from == address(0) || to == address(0),
      'SISMO_DAO_TOKEN: NON_TRANSFERABLE_ERC1155'
    );
  }
}