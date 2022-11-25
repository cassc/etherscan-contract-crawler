// SPDX-License-Identifier: PRIVATE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IZToken.sol";
import "./utils/SimpleRoles.sol";
import "./utils/Pause.sol";

contract ZToken is ERC20Upgradeable, Pause {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeMathUpgradeable for uint;

    uint public _transferFee;
    uint public _transferFeeDecimals;

    address public _collector;
    address public _marketplace;

    EnumerableSetUpgradeable.AddressSet _transferWhitelist;

    function initialize(
        string memory name,
        string memory symbol,
        uint decimals,
        uint totalSupply
    ) public initializer {
        __ERC20_init_unchained(name, symbol);

        Pause.initialize();

        _transferWhitelist.add(msg.sender);
        _transferWhitelist.add(address(0));

        _transferFeeDecimals = 18;
        _transferFee = 0.1 * (10**18);

        _mint(msg.sender, totalSupply * (10 ** decimals));
    }

    function setTransferFee(uint transferFee) external onlyAdmin {
        _transferFee = transferFee;
    }

    function addToTransferWhitelist(address account) external onlyAdmin {
        _transferWhitelist.add(account);
    }

    function removeFromTransferWhitelist(address account) external onlyAdmin {
        _transferWhitelist.remove(account);
    }

    function setCollectorAddress(address newCollector) external onlyAdmin {
        require(newCollector != address(0), "ZToken: can not be zero address");
        require(
            newCollector != _collector,
            "ZToken: can not be the same as the current collector address"
        );

        if (_collector != address(0)) {
            _transferWhitelist.remove(_collector);
        }

        _collector = newCollector;
        _transferWhitelist.add(_collector);
    }

    function setMarketplaceAddress(address marketplace) external onlyAdmin {
        require(marketplace != address(0), "ZToken: can not be zero address");
        require(
            marketplace != msg.sender,
            "ZToken: can not be the same like caller"
        );
        require(
            marketplace != _marketplace,
            "ZToken: can not be the same as the current marketplace address"
        );

        if (_marketplace != address(0)) {
            _transferWhitelist.remove(_marketplace);
        }

        _marketplace = marketplace;
        _transferWhitelist.add(_marketplace);
    }

    function mint(address account, uint amount) external onlyAdminOrManager {
        _mint(account, amount);
    }

    function burn(uint amount) external whenNotPaused {
        _burn(msg.sender, amount);
    }

    function burn(address account, uint amount) external onlyAdminOrManager {
        _burn(account, amount);
    }

    function getTransferFeeForAmount(uint amount)
        public
        view
        returns (uint)
    {
        return _transferFee.mul(amount).div(100).div(10**_transferFeeDecimals);
    }

    function getTotalSupplyExceptAdmins() external view returns (uint) {
        uint adminBalances = 0;
        uint len = _admins.length();
        for (uint i = 0; i < len; ++i) {
            if (isAdmin(_admins.at(i)))
                adminBalances = adminBalances.add(balanceOf(_admins.at(i)));
        }
        len = _managers.length();
        for (uint i = 0; i < len; ++i) {
            if (isManager(_managers.at(i)))
                adminBalances = adminBalances.add(balanceOf(_managers.at(i)));
        }

        return totalSupply().sub(adminBalances).add(balanceOf(_marketplace));
    }

    function isInTransferWhitelist(address account)
        external
        view
        returns (bool)
    {
        return _transferWhitelist.contains(account);
    }

/*     function _transfer(
        address sender,
        address recipient,
        uint amount
    ) internal override {
        if (
            _transferWhitelist.contains(sender) ||
            _transferWhitelist.contains(recipient) ||
            isAdmin(msg.sender)
        ) {
            ERC20Upgradeable._transfer(sender, recipient, amount);
        } else {
            uint fee = getTransferFeeForAmount(amount);

            ERC20Upgradeable._transfer(sender, recipient, amount.sub(fee));
            ERC20Upgradeable._transfer(sender, _collector, fee);
        }
    }
 */
    function transferOverride(
        address sender,
        address recipient,
        uint amount
    ) external onlyAdmin {
        _transfer(sender, recipient, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal override {
        require(!paused(), "ZToken: token transfer while paused");
    }
}