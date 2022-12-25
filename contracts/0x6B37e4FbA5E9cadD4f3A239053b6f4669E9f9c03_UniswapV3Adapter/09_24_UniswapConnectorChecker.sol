// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @dev The length of the bytes encoded address
uint256 constant ADDR_SIZE = 20;

/// @dev The length of the uint24 encoded address
uint256 constant FEE_SIZE = 3;

/// @dev Minimal path length in bytes
uint256 constant MIN_PATH_LENGTH = 2 * ADDR_SIZE + FEE_SIZE;

/// @dev Number of bytes in path per single token
uint256 constant ADDR_PLUS_FEE_LENGTH = ADDR_SIZE + FEE_SIZE;

/// @dev Maximal allowed path length in bytes (3 hops)
uint256 constant MAX_PATH_LENGTH = 4 * ADDR_SIZE + 3 * FEE_SIZE;

abstract contract UniswapConnectorChecker {
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
        address[10] memory _connectorTokens;
        uint256 len = _connectorTokensInit.length;

        for (uint256 i = 0; i < 10; ++i) {
            _connectorTokens[i] = i >= len
                ? address(0)
                : _connectorTokensInit[i];
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

        numConnectors = len;
    }

    function isConnector(address token) public view returns (bool) {
        return
            token == connectorToken0 ||
            token == connectorToken1 ||
            token == connectorToken2 ||
            token == connectorToken3 ||
            token == connectorToken4 ||
            token == connectorToken5 ||
            token == connectorToken6 ||
            token == connectorToken7 ||
            token == connectorToken8 ||
            token == connectorToken9;
    }

    function getConnectors()
        external
        view
        returns (address[] memory connectors)
    {
        uint256 len = numConnectors;

        connectors = new address[](len);

        for (uint256 i = 0; i < len; ) {
            if (i == 0) connectors[0] = connectorToken0;
            if (i == 1) connectors[1] = connectorToken1;
            if (i == 2) connectors[2] = connectorToken2;
            if (i == 3) connectors[3] = connectorToken3;
            if (i == 4) connectors[4] = connectorToken4;
            if (i == 5) connectors[5] = connectorToken5;
            if (i == 6) connectors[6] = connectorToken6;
            if (i == 7) connectors[7] = connectorToken7;
            if (i == 8) connectors[8] = connectorToken8;
            if (i == 9) connectors[9] = connectorToken9;

            unchecked {
                ++i;
            }
        }
    }
}