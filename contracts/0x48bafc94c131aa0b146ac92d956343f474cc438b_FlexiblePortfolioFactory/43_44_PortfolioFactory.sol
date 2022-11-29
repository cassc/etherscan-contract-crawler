// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20Metadata} from "ERC20.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";
import {ProxyWrapper} from "ProxyWrapper.sol";
import {Upgradeable} from "Upgradeable.sol";

abstract contract PortfolioFactory is Upgradeable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address public portfolioImplementation;
    address[] public portfolios;
    IProtocolConfig public protocolConfig;

    event PortfolioCreated(address indexed newPortfolio, address indexed manager);
    event PortfolioImplementationChanged(address indexed newImplementation);

    function initialize(address _portfolioImplementation, IProtocolConfig _protocolConfig) external initializer {
        __Upgradeable_init(msg.sender, _protocolConfig.pauserAddress());
        portfolioImplementation = _portfolioImplementation;
        protocolConfig = _protocolConfig;
    }

    function setPortfolioImplementation(address newImplementation) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(portfolioImplementation != newImplementation, "PortfolioFactory: New portfolio implementation needs to be different");
        portfolioImplementation = newImplementation;
        emit PortfolioImplementationChanged(newImplementation);
    }

    function getPortfolios() external view returns (address[] memory) {
        return portfolios;
    }

    function _deployPortfolio(bytes memory initData) internal {
        address newPortfolio = address(new ProxyWrapper(address(portfolioImplementation), initData));
        portfolios.push(newPortfolio);
        emit PortfolioCreated(newPortfolio, msg.sender);
    }
}