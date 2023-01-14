// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/ICreate2Deployer.sol";

contract Create2Deployer is
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ICreate2Deployer
{
    bytes32 public constant DEPLOYER_ROLE = keccak256("CREATE2.DEPLOYER.ROLE");
    uint8 public constant VERSION = 2;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public reinitializer(VERSION) {}

    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode,
        bytes memory initializer
    ) external override onlyProxy onlyRole(DEPLOYER_ROLE) returns (address) {
        address newContract = Create2.deploy(amount, salt, bytecode);
        if (initializer.length > 0) {
            (bool success, ) = newContract.call(initializer);
            require(success, "Init failed");
        }
        emit Deployed(newContract, salt, keccak256(bytecode));
        return newContract;
    }

    function deployToken(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode,
        bytes memory initializer
    ) external override onlyProxy onlyRole(DEPLOYER_ROLE) returns (address) {
        address newContract = Create2.deploy(amount, salt, bytecode);
        if (initializer.length > 0) {
            (bool success, ) = newContract.call(initializer);
            require(success, "Init failed");
        }
        string memory name = IERC20Detailed(newContract).name();
        string memory symbol = IERC20Detailed(newContract).symbol();
        emit DeployedToken(
            newContract,
            salt,
            keccak256(bytecode),
            name,
            symbol
        );
        return newContract;
    }

    function computeAddress(bytes32 salt, bytes32 bytecodeHash)
        external
        view
        override
        onlyProxy
        returns (address)
    {
        return Create2.computeAddress(salt, bytecodeHash);
    }

    /**
     * Allow send ether
     */
    receive() external payable {}

    function withdraw(uint256 amount)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        payable(_msgSender()).transfer(amount);
        return true;
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}