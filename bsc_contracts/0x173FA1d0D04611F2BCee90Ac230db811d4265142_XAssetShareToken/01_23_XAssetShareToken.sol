// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@prb/proxy/contracts/IPRBProxyRegistry.sol";

contract XAssetShareToken is ERC20PermitUpgradeable, OwnableUpgradeable, UUPSUpgradeable {

    address public xAsset;

    address public proxyRegistry;

    function initialize(
        string memory name_,
        string memory symbol_,
        address proxyRegistry_
    ) initializer public {
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
        __Ownable_init();
        __UUPSUpgradeable_init();
        xAsset = address(0);
        proxyRegistry = proxyRegistry_;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    // contract
    function mint(address to, uint256 amount) public onlyXAsset {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyXAsset {
        _burn(from, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) override internal virtual {
        if (spender == address(IPRBProxyRegistry(proxyRegistry).getCurrentProxy(owner))) {
            // The proxy of the owner is allowed to spend on its behalf
            return;
        }
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new xAsset (`newXasset`).
     * Can only be called by the current owner.
     */
    function setXAsset(address newXasset) public virtual onlyOwner {
        require(xAsset == address(0), "XAsset already set");
        require(newXasset != address(0), "xAsset address can not be zero address");
        xAsset = newXasset;
    }

    /**
     * @dev Throws if called by any account other than the xAsset contract.
     */
    modifier onlyXAsset() {
        _checkXAsset();
        _;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkXAsset() internal view virtual {
        require(xAsset == _msgSender(), "Caller is not the xAsset contract");
    }
}