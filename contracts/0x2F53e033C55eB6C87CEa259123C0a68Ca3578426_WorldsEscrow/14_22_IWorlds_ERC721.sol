// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWorlds_ERC721 is IERC721 {
    function updateWorld(
        uint _tokenId, 
        string calldata _ipfsHash, 
        uint256 _nonce, 
        bytes calldata _updateApproverSignature
    ) external;
}