// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC20_Game_Currency.sol";
import "../common/ERC2771Context_Upgradeable.sol";
import "../common/Roles.sol";

contract ERC20_Game_Currency is IERC20_Game_Currency, ERC20, ERC2771Context_Upgradeable, Roles, AccessControl {
  uint256 public feeBps;
  uint256 public feeFixed;
  uint256 public feeCap;
  address public feeRecipient;
  address public childChainManagerProxy;
  uint256 public immutable supplyCap;

  constructor(string memory _name, string memory _symbol, uint256 _supplyCap, address _forwarder)
  ERC20(_name, _symbol)
  ERC2771Context_Upgradeable(_forwarder) {
    feeRecipient = _msgSender();
    supplyCap = _supplyCap;
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(OWNER_ROLE, _msgSender());
  }

  function mint(address _to, uint256 _amount) external canMint {
    require(childChainManagerProxy == address(0), "Minting disabled when Polygon bridge is enabled.");

    _mint(_to, _amount);
  }

  function burn(uint256 _amount) external {
    _burn(_msgSender(), _amount);
  }

  function transferWithRef(address recipient, uint256 amount, uint256 ref) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    emit TransferRef(_msgSender(), recipient, amount, ref);
    return true;
  }

  /**
   * @dev Support for transfer batching
   */

  function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external returns (bool) {
    return _batchTransfer(recipients, amounts, false);
  }

  function batchTransferWithRefs(address[] calldata recipients, uint256[] calldata amounts, uint256[] calldata refs) external returns (bool) {
    return _batchTransferWithRefs(recipients, amounts, refs, false);
  }

  function batchTransferWithFees(address[] calldata recipients, uint256[] calldata amounts) external returns (bool) {
    return _batchTransfer(recipients, amounts, true);
  }

  function batchTransferWithFeesRefs(address[] calldata recipients, uint256[] calldata amounts, uint256[] calldata refs) external returns (bool) {
    return _batchTransferWithRefs(recipients, amounts, refs, true);
  }

  function _batchTransfer(address[] calldata recipients, uint256[] calldata amounts, bool withFee) private returns (bool) {
    require(recipients.length > 0, "No recipients");
    require(recipients.length == amounts.length, "amounts argument size mismatched");

    for (uint256 i = 0; i < recipients.length; i++) {
      if (withFee) {
        transferWithFee(recipients[i], amounts[i]);
      } else {
        transfer(recipients[i], amounts[i]);
      }
    }

    return true;
  }

  function _batchTransferWithRefs(address[] calldata recipients, uint256[] calldata amounts, uint256[] calldata refs, bool withFee) private returns (bool) {
    require(recipients.length > 0, "No recipients");
    require(recipients.length == amounts.length, "amounts argument size mismatched");
    require(recipients.length == refs.length, "refs argument size mismatched");

    for (uint256 i = 0; i < recipients.length; i++) {
      if (withFee) {
        transferWithFee(recipients[i], amounts[i]);
      } else {
        transfer(recipients[i], amounts[i]);
      }

      if (refs[i] > 0) {
        emit TransferRef(_msgSender(), recipients[i], amounts[i], refs[i]);
      }
    }

    emit BatchTransferRef(_msgSender(), recipients, amounts, refs);

    return true;
  }

  /**
   * @dev Support for Polygon bridge
   */

  function deposit(address user, bytes calldata depositData) external {
    require(_msgSender() == childChainManagerProxy, "Address not allowed to deposit.");

    uint256 amount = abi.decode(depositData, (uint256));

    _mint(user, amount);
  }

  function withdraw(uint256 amount) external {
    _burn(_msgSender(), amount);
  }

  function updateChildChainManager(address _childChainManagerProxy) external onlyRole(OWNER_ROLE) {
    require(_childChainManagerProxy != address(0), "Bad ChildChainManagerProxy address.");

    childChainManagerProxy = _childChainManagerProxy;
  }

  /**
   * @dev Support for fee based transfers, typically used with gasless transactions
   */

  function burnWithFee(uint256 amount) external returns (bool) {
    _transferWithFee(address(0), amount, true);

    return true;
  }

  function transferWithFee(address recipient, uint256 amount) public returns (bool) {
    _transferWithFee(recipient, amount, false);

    return true;
  }

  function transferWithFeeRef(address recipient, uint256 amount, uint256 ref) external returns (bool) {
    transferWithFee(recipient, amount);

    emit TransferRef(_msgSender(), recipient, amount, ref);

    return true;
  }

  function _transferWithFee(address recipient, uint256 amount, bool isBurn) private {
    uint256 senderBalance = balanceOf(_msgSender());
    require(feeRecipient != address(0), "Fee recipient not set, cannot use transferWithFee");
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance.");

    uint256 percentageFee = amount * feeBps / 10000 + feeFixed;
    uint256 fee = percentageFee <= feeCap ? percentageFee : feeCap;

    _transfer(_msgSender(), feeRecipient, fee);

    if (isBurn) {
      _burn(_msgSender(), amount - fee);
    } else {
      _transfer(_msgSender(), recipient, amount - fee);
    }
  }

  function setFees(address recipient, uint256 _feeBps, uint256 _feeFixed, uint256 _feeCap) external onlyRole(OWNER_ROLE) {
    require(recipient != address(0), "recipient is 0 addr");
    feeRecipient = recipient;
    feeBps = _feeBps;
    feeFixed = _feeFixed;
    feeCap = _feeCap;
  }

  /**
   * @dev Support for gasless transactions
   */

  function upgradeTrustedForwarder(address _newTrustedForwarder) external onlyRole(OWNER_ROLE) {
    _upgradeTrustedForwarder(_newTrustedForwarder);
  }

  function _msgSender() internal view override(Context, ERC2771Context_Upgradeable) returns (address) {
    return super._msgSender();
  }

  function _msgData() internal view override(Context, ERC2771Context_Upgradeable) returns (bytes calldata) {
    return super._msgData();
  }

  /**
   * @dev Support for optional supply cap
   */

  function _mint(address _account, uint256 _amount) internal virtual override {
    if (supplyCap > 0) {
      require(ERC20.totalSupply() + _amount <= supplyCap, "ERC20 supply cap exceeded");
    }

    super._mint(_account, _amount);
  }

  /**
   * @dev ERC165
   */

  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, IERC165) returns (bool) {
    return interfaceId == type(IERC20_Game_Currency).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev Modifiers
   */

  modifier canMint {
    require(hasRole(OWNER_ROLE, _msgSender()) || hasRole(MINTER_ROLE, _msgSender()), "Not authorized to mint.");
    _;
  }
}