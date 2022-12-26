pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./helpers/TransferHelper.sol";
import "./interfaces/IvToken.sol";

contract USDB is ERC20, AccessControl, Ownable, IvToken {
  using SafeMath for uint256;

  bytes32 public excludedFromTaxRole = keccak256(abi.encodePacked("EXCLUDED_FROM_TAX"));
  bytes32 public retrieverRole = keccak256(abi.encodePacked("RETRIEVER_ROLE"));
  bytes32 public minterRole = keccak256(abi.encodePacked("MINTER_ROLE"));
  address public taxCollector;
  uint8 public taxPercentage;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 amount,
    address tCollector,
    uint8 tPercentage
  ) ERC20(name_, symbol_) {
    _grantRole(excludedFromTaxRole, _msgSender());
    _grantRole(retrieverRole, _msgSender());
    _mint(_msgSender(), amount);
    {
      taxCollector = tCollector;
      taxPercentage = tPercentage;
    }
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override(ERC20) {
    if (!hasRole(excludedFromTaxRole, sender) && sender != address(this)) {
      uint256 tax = amount.mul(uint256(taxPercentage)).div(100);
      super._transfer(sender, taxCollector, tax);
      super._transfer(sender, recipient, amount.sub(tax));
    } else {
      super._transfer(sender, recipient, amount);
    }
  }

  function mint(address to, uint256 amount) external {
    require(hasRole(minterRole, _msgSender()), "only_minter");
    _mint(to, amount);
  }

  function burn(address account, uint256 amount) external {
    require(hasRole(minterRole, _msgSender()), "only_minter");
    _burn(account, amount);
  }

  function retrieveEther(address to) external {
    require(hasRole(retrieverRole, _msgSender()), "only_retriever");
    TransferHelpers._safeTransferEther(to, address(this).balance);
  }

  function retrieveERC20(
    address token,
    address to,
    uint256 amount
  ) external {
    require(hasRole(retrieverRole, _msgSender()), "only_retriever");
    TransferHelpers._safeTransferERC20(token, to, amount);
  }

  function excludeFromPayingTax(address account) external onlyOwner {
    require(!hasRole(excludedFromTaxRole, account), "already_excluded_from_paying_tax");
    _grantRole(excludedFromTaxRole, account);
  }

  function includeInPayingTax(address account) external onlyOwner {
    require(hasRole(excludedFromTaxRole, account), "not_paying_tax");
    _revokeRole(excludedFromTaxRole, account);
  }

  function addRetriever(address account) external onlyOwner {
    require(!hasRole(retrieverRole, account), "already_retriever");
    _grantRole(retrieverRole, account);
  }

  function removeRetriever(address account) external onlyOwner {
    require(hasRole(retrieverRole, account), "not_retriever");
    _revokeRole(retrieverRole, account);
  }

  function setTaxPercentage(uint8 tPercentage) external onlyOwner {
    require(tPercentage <= 10, "tax_must_be_ten_percent_or_less");
    taxPercentage = tPercentage;
  }

  function setMinter(address account) external onlyOwner {
    require(!hasRole(minterRole, account), "already_minter");
    _grantRole(minterRole, account);
  }

  function removeMinter(address account) external onlyOwner {
    require(hasRole(minterRole, account), "not_a_minter");
    _revokeRole(minterRole, account);
  }

  function setTaxCollector(address tCollector) external onlyOwner {
    taxCollector = tCollector;
  }

  receive() external payable {}
}