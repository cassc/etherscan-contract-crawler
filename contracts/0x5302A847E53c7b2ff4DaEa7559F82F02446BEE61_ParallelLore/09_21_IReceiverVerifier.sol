// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Structs.sol";

interface IReceiverVerifier {
    function handleInvoke(
        address _userAddress,
        RouterEndpoint memory _routerEndpoint,
        uint256 _ethValue,
        uint256 _primeValue,
        uint256[] memory _tokenIds,
        uint256[] memory _tokenQuantities,
        bytes memory _data
    ) external;
}