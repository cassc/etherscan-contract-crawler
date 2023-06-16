// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.17;

import {IUniswapConnectorChecker} from "../../interfaces/uniswap/IUniswapConnectorChecker.sol";

abstract contract UniswapConnectorChecker is IUniswapConnectorChecker {
    address public immutable connectorToken0;
    address public immutable connectorToken1;
    address public immutable connectorToken2;
    address public immutable connectorToken3;
    address public immutable connectorToken4;
    address public immutable connectorToken5;
    address public immutable connectorToken6;
    address public immutable connectorToken7;
    address public immutable connectorToken8;
    address public immutable connectorToken9;

    uint256 public immutable numConnectors;

    constructor(address[] memory _connectorTokensInit) {
        numConnectors = _connectorTokensInit.length;
        if (numConnectors > 10) {
            revert TooManyConnectorsException();
        }

        address[10] memory _connectorTokens;
        for (uint256 i = 0; i < numConnectors; ++i) {
            _connectorTokens[i] = _connectorTokensInit[i];
        }

        connectorToken0 = _connectorTokens[0];
        connectorToken1 = _connectorTokens[1];
        connectorToken2 = _connectorTokens[2];
        connectorToken3 = _connectorTokens[3];
        connectorToken4 = _connectorTokens[4];
        connectorToken5 = _connectorTokens[5];
        connectorToken6 = _connectorTokens[6];
        connectorToken7 = _connectorTokens[7];
        connectorToken8 = _connectorTokens[8];
        connectorToken9 = _connectorTokens[9];
    }

    /// @notice Returns true if given token is a registered connector token
    function isConnector(address token) public view override returns (bool) {
        return token == connectorToken0 || token == connectorToken1 || token == connectorToken2
            || token == connectorToken3 || token == connectorToken4 || token == connectorToken5 || token == connectorToken6
            || token == connectorToken7 || token == connectorToken8 || token == connectorToken9;
    }

    /// @notice Returns the array of registered connector tokens
    function getConnectors() external view override returns (address[] memory connectors) {
        uint256 len = numConnectors;

        connectors = new address[](len);

        if (len > 0) connectors[0] = connectorToken0;
        if (len > 1) connectors[1] = connectorToken1;
        if (len > 2) connectors[2] = connectorToken2;
        if (len > 3) connectors[3] = connectorToken3;
        if (len > 4) connectors[4] = connectorToken4;
        if (len > 5) connectors[5] = connectorToken5;
        if (len > 6) connectors[6] = connectorToken6;
        if (len > 7) connectors[7] = connectorToken7;
        if (len > 8) connectors[8] = connectorToken8;
        if (len > 9) connectors[9] = connectorToken9;
    }
}