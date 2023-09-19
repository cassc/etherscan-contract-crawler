// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/oracles/IBaseOracle.sol";
import "../interfaces/oracles/IOracle.sol";
import "../utils/DefaultAccessControl.sol";
import "../libraries/CommonLibrary.sol";

import "../interfaces/oracles/IMellowBaseOracle.sol";
import "../interfaces/utils/IProxyToken.sol";
import "../interfaces/utils/ISupportedByOracleToken.sol";

contract Oracle is IOracle, DefaultAccessControl {
    error AddressZero();
    error InvalidLength();
    error TokenNotFound();
    error InvalidState();
    error InvalidOrderOfTokens();
    error InvalidToken();
    error OracleNotFound();

    struct OracleData {
        IBaseOracle oracle;
        bytes params;
    }

    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => OracleData) public erc20Oracles;
    mapping(address => OracleData) public mellowOracles;

    EnumerableSet.AddressSet private _supportedTokens;
    EnumerableSet.AddressSet private _mellowOracles;

    constructor(address admin) DefaultAccessControl(admin) {}

    function updateBaseOracles(address[] calldata tokens, OracleData[] calldata newOracles) external {
        _requireAdmin();
        for (uint256 i = 0; i < tokens.length; i++) {
            if (address(newOracles[i].oracle) == address(0)) {
                _supportedTokens.remove(tokens[i]);
            } else {
                _supportedTokens.add(tokens[i]);
            }
            erc20Oracles[tokens[i]] = newOracles[i];
        }
    }

    function addMellowOracles(OracleData[] memory oracles) external {
        _requireAdmin();
        for (uint256 i = 0; i < oracles.length; i++) {
            mellowOracles[address(oracles[i].oracle)] = oracles[i];
            _mellowOracles.add(address(oracles[i].oracle));
        }
    }

    function removeMellowOracles(address[] memory oracles) external {
        _requireAdmin();
        for (uint256 i = 0; i < oracles.length; i++) {
            mellowOracles[oracles[i]] = OracleData({oracle: IBaseOracle(address(0)), params: new bytes(0)});
            _mellowOracles.remove(oracles[i]);
        }
    }

    function supportedTokens() public view returns (address[] memory) {
        return _supportedTokens.values();
    }

    function supportedMellowOracles() public view returns (address[] memory) {
        return _mellowOracles.values();
    }

    function getUnderlyingIfProxy(address token) public view returns (bool isProxyToken, address underlyingToken) {
        try IERC165(token).supportsInterface(type(IProxyToken).interfaceId) returns (bool isSupported) {
            if (isSupported) return (true, IProxyToken(token).token());
        } catch {}
        return (false, address(0));
    }

    function isTokenSupported(address token) public view returns (bool) {
        if (token == address(0)) return false;
        if (address(erc20Oracles[token].oracle) != address(0)) return true;

        (bool isProxyToken, address underlyingToken) = getUnderlyingIfProxy(token);
        if (isProxyToken) return isTokenSupported(underlyingToken);

        try ISupportedByOracleToken(token).oracle() returns (address oracle) {
            if (oracle == address(0)) return false;
            OracleData memory data = mellowOracles[oracle];
            if (address(data.oracle) != address(oracle)) return false;
            try IMellowBaseOracle(oracle).isTokenSupported(token) returns (bool isSupported) {
                if (isSupported) return true;
            } catch {}
        } catch {}
        return false;
    }

    function getOracle(address token) public view returns (address, bytes memory) {
        {
            OracleData memory data = erc20Oracles[token];
            if (address(data.oracle) != address(0)) return (address(data.oracle), data.params);
        }

        (bool isProxyToken, address underlyingToken) = getUnderlyingIfProxy(token);
        if (isProxyToken) return getOracle(underlyingToken);

        try ISupportedByOracleToken(token).oracle() returns (address oracle) {
            if (oracle == address(0)) revert OracleNotFound();
            OracleData memory data = mellowOracles[oracle];
            if (address(data.oracle) != address(oracle)) revert OracleNotFound();
            try IMellowBaseOracle(oracle).isTokenSupported(token) returns (bool isSupported) {
                if (isSupported) return (oracle, data.params);
            } catch {}
        } catch {}
        revert OracleNotFound();
    }

    function getOracles(
        address[] calldata tokens
    ) public view returns (address[] memory requestedOracles, bytes[] memory parameters) {
        uint256 n = tokens.length;
        requestedOracles = new address[](n);
        parameters = new bytes[](n);
        for (uint256 i = 0; i < n; ++i) {
            (requestedOracles[i], parameters[i]) = getOracle(tokens[i]);
        }
    }

    function quote(
        address token,
        uint256 amount,
        bytes memory securityParams
    ) public view returns (address[] memory tokens, uint256[] memory tokenAmounts) {
        (address oracle, bytes memory params) = getOracle(token);
        if (oracle == address(0)) revert AddressZero();
        if (securityParams.length > 0) params = securityParams;
        (tokens, tokenAmounts) = IBaseOracle(oracle).quote(token, amount, params);
    }

    function quote(
        address[] calldata tokensInOrderOfDifficulty,
        uint256[] memory tokenAmounts,
        bytes[] calldata securityParams
    ) public view override returns (uint256) {
        // there is no need to check the last token, since the function `quote(address,uint256,bytes)` will not be called for it
        for (uint256 i = 0; i + 1 < tokensInOrderOfDifficulty.length; i++) {
            if (!isTokenSupported(tokensInOrderOfDifficulty[i])) {
                revert InvalidToken();
            }
        }

        if (
            tokensInOrderOfDifficulty.length != tokenAmounts.length ||
            tokensInOrderOfDifficulty.length != securityParams.length ||
            tokensInOrderOfDifficulty.length == 0
        ) revert InvalidLength();

        uint256 length = tokenAmounts.length;
        bool finished = false;
        while (!finished) {
            finished = true;
            for (uint256 i = 0; i + 1 < length; i++) {
                if (tokenAmounts[i] == 0) continue;
                finished = false;
                (address[] memory subTokens, uint256[] memory subTokenAmounts) = quote(
                    tokensInOrderOfDifficulty[i],
                    tokenAmounts[i],
                    securityParams[i]
                );

                for (uint256 j = 0; j < subTokens.length; j++) {
                    address subToken = subTokens[j];

                    bool found = false;
                    for (uint256 index = 0; index < length; index++) {
                        if (tokensInOrderOfDifficulty[index] == subToken) {
                            if (index == i) revert InvalidState();
                            tokenAmounts[index] += subTokenAmounts[j];

                            found = true;
                            break;
                        }
                    }
                    if (!found) revert InvalidOrderOfTokens();
                }
                tokenAmounts[i] = 0;
            }
        }

        return tokenAmounts[length - 1];
    }
}