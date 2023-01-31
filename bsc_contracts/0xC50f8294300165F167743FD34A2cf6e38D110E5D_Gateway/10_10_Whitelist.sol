// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Whitelist is Ownable {
        using Address for address;
        using SafeERC20 for IERC20;

        mapping(bytes32 => bytes32) public destinations;

        mapping(bytes32 => bytes32) public providers;

        bytes32 internal constant TRUE = bytes32(uint256(1));
        bytes32 internal constant ZERO = bytes32(uint256(0));

        event AddedDestination(address indexed dest, address indexed token);
        event RemovedDestination(address indexed dest, address indexed token);
        event AddedProvider(address indexed provider, address indexed providerSpender);
        event RemovedProvider(address indexed provider, address indexed providerSpender);

        constructor() {}

        function validDestination(address dest, address token) internal view returns (bytes32) {
                return destinations[keccak256(abi.encode(dest, token))];
        }

        function validProviderSpender(address providerAddress, address spenderAddress) internal view returns (bytes32) {
                return providers[keccak256(abi.encode(providerAddress, spenderAddress))];
        }

        function validProvider(address providerAddress) internal view returns (bytes32) {
                return providers[keccak256(abi.encode(providerAddress))];
        }

        function setDestinations(address[] memory dests, address[] memory tokens, bytes32 flag) public onlyOwner {
                uint256 len = dests.length;
                for (uint256 i = 0; i < len; i++) {
                        if (flag == TRUE) {
                                emit AddedDestination(dests[i], tokens[i]);
                        } else {
                                emit RemovedDestination(dests[i], tokens[i]);
                        }
                        destinations[keccak256(abi.encode(dests[i], tokens[i]))] = flag;
                }
        }

        function setProviders(address[] memory _providers, address[] memory _providerSpenders, bytes32 flag) public onlyOwner {
                uint256 len = _providers.length;
                for (uint256 i = 0; i < len; i++) {
                        if (flag == TRUE) {
                                emit AddedProvider(_providers[i], _providerSpenders[i]);
                        } else {
                                emit RemovedProvider(_providers[i], _providerSpenders[i]);
                        }
                        providers[keccak256(abi.encode(_providers[i]))] = flag;
                        providers[keccak256(abi.encode(_providers[i], _providerSpenders[i]))] = flag;
                }
        }
}