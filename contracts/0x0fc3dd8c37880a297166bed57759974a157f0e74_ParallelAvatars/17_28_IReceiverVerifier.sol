// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../nfts/Structs.sol";

interface IReceiverVerifier {
    function handleInvoke(
        address _userAddress,
        RouterEndpoint memory _routerEndpoint,
        uint256 _ethValue,
        uint256 _primeValue,
        uint256[] memory _tokenIds,
        bytes memory _data
    ) external;
}