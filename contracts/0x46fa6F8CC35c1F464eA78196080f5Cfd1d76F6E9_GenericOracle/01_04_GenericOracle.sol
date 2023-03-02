// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "Ownable.sol";

import "IOracle.sol";

contract GenericOracle is IOracle, Ownable {
    event CustomOracleAdded(address token, address oracle);

    mapping(address => IOracle) public customOracles;

    IOracle internal _chainlinkOracle;
    IOracle internal _curveLpOracle;

    function initialize(address curveLpOracle, address chainlinkOracle) external {
        require(address(_curveLpOracle) == address(0), "already initialized");
        _chainlinkOracle = IOracle(chainlinkOracle);
        _curveLpOracle = IOracle(curveLpOracle);
    }

    function isTokenSupported(address token) external view override returns (bool) {
        return
            address(customOracles[token]) != address(0) ||
            _chainlinkOracle.isTokenSupported(token) ||
            _curveLpOracle.isTokenSupported(token);
    }

    function getUSDPrice(address token) external view virtual returns (uint256) {
        if (_chainlinkOracle.isTokenSupported(token)) {
            return _chainlinkOracle.getUSDPrice(token);
        }
        if (address(customOracles[token]) != address(0)) {
            return customOracles[token].getUSDPrice(token);
        }
        return _curveLpOracle.getUSDPrice(token);
    }

    function setCustomOracle(address token, address oracle) external onlyOwner {
        customOracles[token] = IOracle(oracle);
        emit CustomOracleAdded(token, oracle);
    }
}