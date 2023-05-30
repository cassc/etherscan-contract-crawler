// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IITFKFreeMintable is IERC165 {
    function fkMint(
        uint256[] memory _fkPresaleTokenIds,
        uint256[] memory _fkFreeMintTokenIds,
        uint32 _amount,
        string memory _nonce,
        bytes memory _signature
    ) external;
}