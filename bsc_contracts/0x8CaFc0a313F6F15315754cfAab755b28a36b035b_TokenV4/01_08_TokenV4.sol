//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IRegistry.sol";

contract TokenV4 is ERC20, Ownable {
    // Storage

    uint256 public constant DENOM = 1000;

    IRegistry private registry;

    uint256 public purchaseFee;

    uint256 public saleFee;

    // Constructor

    constructor(
        string memory name_,
        string memory symbol_,
        address admin_,
        uint256 totalSupply_,
        IRegistry registry_,
        uint256 purchaseFee_,
        uint256 saleFee_
    ) ERC20(name_, symbol_) {
        _mint(admin_, totalSupply_ * 10**decimals());
        transferOwnership(admin_);

        registry = registry_;
        purchaseFee = purchaseFee_;
        saleFee = saleFee_;
    }

    // Public

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Override

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        registry.registerTransfer(from, to, amount);

        uint256 fee;
        if (registry.isAmmPair(from)) {
            fee = (amount * purchaseFee) / DENOM;
        } else if (registry.isAmmPair(to)) {
            fee = (amount * saleFee) / DENOM;
        }

        super._transfer(from, to, amount - fee);
        if (fee > 0) {
            _burn(from, fee);
        }
    }
}