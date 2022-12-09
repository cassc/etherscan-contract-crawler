// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IMaiExchange {
    function lastPrice() external view returns (uint256);
}

contract PriceOracle is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    address public constant MAI = 0x35803e77c3163FEd8A942536C1c8e0d5bF90f906;
    address public constant MAI_EXCHANGE = 0x0663C4b19D139b9582539f6053a9C69a2bCEBC9f;

    mapping(address => uint256) tokenPrice;

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    function updatePrice(address token, uint256 price) external onlyRole(OPERATOR_ROLE) {
        tokenPrice[token] = price;
    }

    function getPrice(address token) external view returns (uint256) {
        if (token == MAI) {
            return IMaiExchange(MAI_EXCHANGE).lastPrice();
        } else {
            return tokenPrice[token];
        }
    }
}