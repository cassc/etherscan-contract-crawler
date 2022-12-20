// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FoxToken is ERC20BurnableUpgradeable, ERC20CappedUpgradeable, OwnableUpgradeable {
    // admin contracts are allowed to mint
    mapping (address => bool) isAdmin;
    event SetAdmin(address indexed addr, bool value);
    
    /**
     * @dev Initializes the contract
     */
    function initialize() initializer public {
        __ERC20Capped_init(50000000 * 10**18); /*TODO*/
        __ERC20_init("DFOX TOKEN", "DFOX");
        __Ownable_init();
    }

    /*
     * @dev Override _mint because we're using both ERC20Burnable and ERC20Capped
     */
    function _mint(address account, uint256 amount) internal override(ERC20Upgradeable, ERC20CappedUpgradeable) {
        ERC20Upgradeable._mint(account, amount);
    }

    /*
     * @dev Mint to wallet; callable by owner
     */
    function mintOwner(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /*
     * @dev Mint to wallet; callable by owner
     */
    function mintOwnerArray(address[] calldata accounts, uint256[] calldata amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Bad array lengths");
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }

    /*
     * @dev Mint to wallet; callable by admin address
     */
    function mintAdminContract(address account, uint256 amount) external {
        require(isAdmin[msg.sender], "Not authorized");
        _mint(account, amount);
    }

    /*
     * @dev Set admin value for address
     */
    function setAdmin(address addr, bool value) external onlyOwner {
        isAdmin[addr] = value;
        emit SetAdmin(addr, value);
    }
}