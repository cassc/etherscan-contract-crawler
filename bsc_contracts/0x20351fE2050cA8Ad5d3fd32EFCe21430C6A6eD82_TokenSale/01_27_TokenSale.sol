// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";
import "PausableUpgradeable.sol";
import "SafeERC20Upgradeable.sol";
import "SafeMathUpgradeable.sol";
import "AccessControlEnumerableUpgradeable.sol";
import "ContextUpgradeable.sol";
import "CountersUpgradeable.sol";
import "Initializable.sol";
import "ERC20Token.sol";


contract TokenSale is 
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable
{

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    ERC20Token _token;
    uint256 public _balance;
    uint256 private MIN_AMOUNT;

    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(address => uint256) public _currencies;
    address[] private currenciesList;

    event Bought(address currency, uint256 amount);
    event CurrencySet(address currency, uint256 amount);

    function initialize(address token, uint256 amount, uint256 minimal) public virtual initializer {
        _token = ERC20Token(token);
        _balance = amount;
        MIN_AMOUNT = minimal;

        __AccessControl_init();
        __Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(SELLER_ROLE, _msgSender());
    }

    function tokenOf(address currency, uint256 amount) public view returns (uint256) {
        return amount.div(_currencies[currency]);
    }

    function currencyList() public view returns (address[] memory) {
        return currenciesList;
    }

    function buy(address currency, uint256 amount) external whenNotPaused {
        require(_currencies[currency] != 0, "TokenSale: unknown currency");
        require(amount.div(_currencies[currency]) <= _balance, "TokenSale: no balance");
        require(amount.div(_currencies[currency]) >= MIN_AMOUNT, "TokenSale: Too small amount");

        uint256 count = amount.div(_currencies[currency]);
        _balance = _balance.sub(count);

        IERC20Upgradeable(currency).safeTransferFrom(_msgSender(), address(this), amount);
        _token.mintSeed(_msgSender(), count);

        emit Bought(currency, count);
    }

    function adminSetCurrency(address currency, uint256 amount) external onlyRole(SELLER_ROLE) {
        _currencies[currency] = amount;
        currenciesList.push(currency);

        emit CurrencySet(currency, amount);
    }

    function adminWithdraw(address currency, address target, uint256 amount) external onlyRole(SELLER_ROLE) whenPaused {
        IERC20Upgradeable(currency).safeTransfer(target, amount);
    }

    function adminBurn(uint256 amount) external onlyRole(SELLER_ROLE) whenPaused {
        _balance = _balance.sub(amount);
    }

    function adminAddMint(uint256 amount) external onlyRole(SELLER_ROLE) whenPaused {
        _balance = _balance.add(amount);
    }

    function adminPause() public virtual onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function adminUnpause() public virtual onlyRole(PAUSER_ROLE) {
        _unpause();
    }

}