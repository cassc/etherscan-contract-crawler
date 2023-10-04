pragma solidity ^0.8.9;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./SupplyController.sol";


// ERC20("Aura", "AURA", 18)
contract AuraToken is
    Initializable,
    UUPSUpgradeable,
    ERC20Upgradeable,
    OwnableUpgradeable
{

    function initialize(string calldata version) external initializer {
        __ERC20_init("Aura", "AURA");
        __Ownable_init();
    }


    SupplyController public supplyController;

    function setSupplyController(
        SupplyController _controller
    ) external onlyOwner {
        supplyController = _controller;
    }

    modifier onlyController() {
        require(msg.sender == address(supplyController));
        _;
    }

    function mint(address to, uint256 amount) external onlyController {
        require(supplyController.isMintingAllowed(), "minting is not allowed");
        // just another sanity check. a bit insane at this point and possible waste of gas. L.
        require(amount + totalSupply() <= supplyController.getMaxSupply(), "supply limit reached");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyController {
        require(supplyController.isBurningAllowed(), "burning is not allowed");
        _burn(from, amount);
    }


    // Only the contract owner is allowed to upgrade this contract.
    // This will fail if the contract owner does not upgrade
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}
}