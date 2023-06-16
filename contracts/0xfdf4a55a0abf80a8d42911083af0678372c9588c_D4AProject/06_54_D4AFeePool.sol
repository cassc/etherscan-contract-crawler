// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract D4AFeePool is AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    string public name;
    bytes32 public constant AUTO_TRANSFER = keccak256("AUTO_TRANSFER");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name) public initializer {
        __ReentrancyGuard_init();
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        name = _name;
    }

    function transfer(address erc20_token_addr, address payable to, uint256 tokens)
        public
        nonReentrant
        returns (bool success)
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(AUTO_TRANSFER, msg.sender),
            "only admin or auto transfer can call this"
        );

        if (erc20_token_addr == address(0x0)) {
            (bool succ,) = to.call{value: tokens}("");
            require(succ, "transfer eth failed");
            return true;
        }

        IERC20Upgradeable(erc20_token_addr).safeTransfer(to, tokens);
        return true;
    }

    receive() external payable {}

    function changeAdmin(address new_admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(msg.sender != new_admin, "new admin cannot be same as old one");
        _grantRole(DEFAULT_ADMIN_ROLE, new_admin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

contract D4AFeePoolFactory {
    using Clones for address;

    D4AFeePool public impl;
    address public proxy_admin;

    constructor() {
        proxy_admin = address(new ProxyAdmin());
        ProxyAdmin(proxy_admin).transferOwnership(msg.sender);
        impl = new D4AFeePool();
    }

    event NewD4AFeePool(address proxy, address admin);

    function createD4AFeePool(string memory _name) public returns (address pool) {
        bytes memory data = abi.encodeWithSignature("initialize(string)", _name);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), proxy_admin, data);
        D4AFeePool(payable(address(proxy))).changeAdmin(msg.sender);
        emit NewD4AFeePool(address(proxy), proxy_admin);
        return address(proxy);
    }
}