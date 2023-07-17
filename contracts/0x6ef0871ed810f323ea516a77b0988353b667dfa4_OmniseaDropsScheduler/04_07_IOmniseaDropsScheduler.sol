// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Phase} from "../structs/erc721/ERC721Structs.sol";

interface IOmniseaDropsScheduler {
    function isAllowed(address _account, uint24 _quantity, bytes32[] memory _merkleProof, uint8 _phaseId) external view returns (bool);
    function setPhase(
        uint8 _phaseId,
        uint256 _from,
        uint256 _to,
        bytes32 _merkleRoot,
        uint24 _maxPerAddress,
        uint256 _price
    ) external;
    function increasePhaseMintedCount(address _account,uint8 _phaseId, uint24 _quantity) external;
    function mintPrice(uint8 _phaseId) external view returns (uint256);
}