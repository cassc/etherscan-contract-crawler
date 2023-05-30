// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract VaultOwned is Ownable {
    address internal _vault;

    function setVault(address vault_) external onlyOwner returns (bool) {
        _vault = vault_;

        return true;
    }

    function vault() public view returns (address) {
        return _vault;
    }

    modifier onlyVault() {
        require(_vault == msg.sender, "VaultOwned: caller is not the Vault");
        _;
    }
}

contract Rockets is ERC20Burnable, ERC20Permit, VaultOwned {
    uint8 private constant __decimals = 9;
    uint256 private constant __initialSupply = 200000 * 1e9; // two hundred thousand, 9 decimals
    string private constant __name = "Rockets";
    string private constant __symbol = "RKTS";

    event Deployed(address sender, uint256 supply);

    constructor() ERC20(__name, __symbol) ERC20Permit(__name) {
        _mint(_msgSender(), __initialSupply);
        emit Deployed(_msgSender(), __initialSupply);
    }

    function mint(address to, uint256 amount) public onlyVault {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return __decimals;
    }
}