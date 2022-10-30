//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IHasVersion} from "../IHasVersion.sol";

import "hardhat/console.sol";

contract QurableRegistryV2 is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IHasVersion
{
    address public vault;
    mapping(address => bool) public marketOperators;
    mapping(address => bool) public transferOperators;

    event OperatorAdded(address indexed operator);
    event VaultChanged(address indexed vault);
    event OperatorRemoved(address indexed operator);

    event TransferOperatorAdded(address indexed operator);
    event TransferOperatorRemoved(address indexed operator);

    function initialize(address owner_, address vault_) public initializer {
        require(owner_ != address(0), "InvalidOwner");
        require(vault_ != address(0), "InvalidVault");

        __Ownable_init();

        vault = vault_;

        // register as operator
        marketOperators[address(this)] = true;

        transferOwnership(owner_);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function version() external pure override returns (string memory) {
        return "2";
    }

    function setVault(address newVault) external onlyOwner {
        require(newVault != address(0), "InvalidVault");
        vault = newVault;

        emit VaultChanged(vault);
    }

    function addMarketOperator(address operator) external onlyOwner {
        require(operator != address(0), "InvalidOperator");
        marketOperators[operator] = true;

        emit OperatorAdded(operator);
    }

    function removeMarketOperator(address operator) external onlyOwner {
        marketOperators[operator] = false;
        emit OperatorRemoved(operator);
    }

    function replaceMarketOperator(address oldOperator, address newOperator)
        external
        onlyOwner
    {
        require(newOperator != address(0), "InvalidNewOperator");

        marketOperators[oldOperator] = false;
        marketOperators[newOperator] = true;

        emit OperatorRemoved(oldOperator);
        emit OperatorAdded(newOperator);
    }

    function addTransferOperator(address operator) external onlyOwner {
        require(operator != address(0), "InvalidOperator");
        transferOperators[operator] = true;

        emit TransferOperatorAdded(operator);
    }

    function removeTransferOperator(address operator) external onlyOwner {
        transferOperators[operator] = false;
        emit TransferOperatorRemoved(operator);
    }

    function replaceTransferOperator(address oldOperator, address newOperator)
        external
        onlyOwner
    {
        require(newOperator != address(0), "InvalidNewOperator");

        transferOperators[oldOperator] = false;
        transferOperators[newOperator] = true;

        emit TransferOperatorRemoved(oldOperator);
        emit TransferOperatorAdded(newOperator);
    }
}