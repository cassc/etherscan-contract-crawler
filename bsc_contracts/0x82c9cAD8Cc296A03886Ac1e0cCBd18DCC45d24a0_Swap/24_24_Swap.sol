//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

import "./internal-upgradeable/BaseUpgradeable.sol";
import "./internal-upgradeable/ProxyCheckerUpgradeable.sol";
import "./internal-upgradeable/FundForwarderUpgradeable.sol";

contract Swap is
    BaseUpgradeable,
    ProxyCheckerUpgradeable,
    FundForwarderUpgradeable
{
    uint256 public tokenPrice;

    IERC20Upgradeable public fiat;
    IERC20Upgradeable public token;

    event Swapped(
        IERC20Upgradeable indexed token,
        address indexed user,
        uint256 indexed amount
    );

    event NewPrice(uint256 indexed from, uint256 indexed to);

    function initialize(
        IAuthority authority_,
        ITreasury treasury_,
        uint256 initPrice_,
        IERC20Upgradeable fiat_,
        IERC20Upgradeable token_
    ) external initializer {
        __Base_init_unchained(authority_, 0);
        __FundForwarder_init_unchained(treasury_);
        fiat = fiat_;
        token = token_;
        tokenPrice = initPrice_;
    }

    function updateTreasury(
        ITreasury treasury_
    ) external override onlyRole(Roles.OPERATOR_ROLE) {
        _updateTreasury(treasury_);
    }

    function setPrice(uint256 price_) external onlyRole(Roles.OPERATOR_ROLE) {
        emit NewPrice(tokenPrice, price_);
        tokenPrice = price_;
    }

    function swapToFiat(
        address user_,
        address token_,
        uint256 value_
    ) external onlyRole(Roles.FACTORY_ROLE) {
        require(token_ == address(token), "SWAP: INVALID_TOKEN");

        _checkBlacklist(user_);

        value_ = (value_ * tokenPrice) / 10_000;
        IERC20Upgradeable _fiat = fiat;
        _safeERC20Transfer(_fiat, user_, value_);

        emit Swapped(_fiat, user_, value_);
    }

    function swapToFiat(uint256 value_) external whenNotPaused {
        address user = _msgSender();
        _onlyEOA(user);
        _checkBlacklist(user);
        _safeERC20TransferFrom(
            token,
            user,
            address(treasury()),
            value_
        );
        value_ = (value_ * tokenPrice) / 10_000;
        IERC20Upgradeable _fiat = fiat;
        _safeERC20Transfer(_fiat, user, value_);

        emit Swapped(_fiat, user, value_);
    }
    function widthdraw(IERC20Upgradeable token_, address to_ ,uint256 value_) external onlyRole(Roles.OPERATOR_ROLE) {
        _safeERC20Transfer(token_, to_, value_);
    }
    uint256[47] private __gap;
}