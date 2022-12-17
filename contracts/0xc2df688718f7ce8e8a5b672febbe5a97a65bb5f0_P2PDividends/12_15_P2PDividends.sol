// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin-upgradeable/contracts/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/math/MathUpgradeable.sol";
import "../utils/math/DecimalMath.sol";

import "../utils/access/Whitelistable.sol";

contract P2PDividends is Whitelistable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;
    using MathUpgradeable for uint256;

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using DecimalMath for uint256;

    IERC20Upgradeable private _asset;

    uint256 private _totalShares;
    EnumerableMapUpgradeable.AddressToUintMap private _shares;
    EnumerableSetUpgradeable.AddressSet private _dividendTokens;

    mapping(address /* account */ => mapping(address /* reward token */ => uint256)) _accountDividends;

    event Claim(address indexed account, address indexed dividendToken, uint256 amount);
    event Distribute(address indexed distributor, address indexed dividendToken, uint256 amount);
    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);

    function initialize(address manager_, address asset_) public initializer {
        __Whitelistable_init(manager_);
        _asset = IERC20Upgradeable(asset_);
    }

    function distribute(uint256 amount_, address dividendToken_) external virtual onlyManager {
        address distributor = _msgSender();
        IERC20Upgradeable(dividendToken_).safeTransferFrom(distributor, address(this), amount_);
        _dividendTokens.add(dividendToken_);
        for (uint256 i = 0; i < _shares.length(); i++) {
            (address account, uint256 sharesAmount) = _shares.at(i);
            _accountDividends[account][dividendToken_] += amount_.mulDiv(
                sharesAmount,
                _totalShares,
                MathUpgradeable.Rounding.Down
            );
        }
        emit Distribute(distributor, dividendToken_, amount_);
    }

    function claimable(address account_, address dividendToken_) public view returns (uint256) {
        return _accountDividends[account_][dividendToken_];
    }

    function claim(address dividendToken_) public virtual returns (uint256) {
        address account = _msgSender();
        uint256 amount = _accountDividends[account][dividendToken_];
        if (amount > 0) {
            IERC20Upgradeable(dividendToken_).safeTransfer(account, amount);
            _accountDividends[account][dividendToken_] = 0;
        }
        emit Claim(account, dividendToken_, amount);
        return amount;
    }

    function claimAll() public virtual {
        uint256 len = _dividendTokens.length();
        for (uint256 i = 0; i < len; i++) {
            claim(_dividendTokens.at(i));
        }
    }

    function deposit(uint256 amount_) public onlyWhitelisted {
        address account = _msgSender();
        _asset.safeTransferFrom(account, address(this), amount_);
        (, uint256 shares) = _shares.tryGet(account);
        _shares.set(account, shares + amount_);
        _totalShares += amount_;
        emit Deposit(account, amount_);
    }

    function withdraw(uint256 amount_) public {
        address account = _msgSender();
        (, uint256 shares) = _shares.tryGet(account);
        require(amount_ <= shares, "P2Dividends: Insufficient shares balance");
        if (shares == amount_) _shares.remove(account);
        else _shares.set(account, shares - amount_);
        _asset.safeTransfer(account, amount_);
        _totalShares -= amount_;
        emit Withdraw(account, amount_);
    }

    function asset() public view returns (address) {
        return address(_asset);
    }

    function sharesOf(address account_) public view returns (uint256 shares) {
        (, shares) = _shares.tryGet(account_);
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function dividendTokensLength() public view returns (uint256) {
        return _dividendTokens.length();
    }

    function dividendToken(uint256 index) public view returns (address) {
        return _dividendTokens.at(index);
    }
}