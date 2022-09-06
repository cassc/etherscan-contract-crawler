// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@siblings/modules/AdminPrivileges.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract StarlistLootboxC3 is AdminPrivileges {
    address constant private LOSTPOETS_PAGES = 0xA7206d878c5c3871826DfdB42191c49B1D11F466;
    address constant private LOSTPOETS = 0x4b3406a41399c7FD2BA65cbC93697Ad9E7eA61e5;
    address private vault = 0x218c36A974D3C6D3C95dE44896E802eE94e8A2ce;

    mapping(address => uint8) public claimed;
    bytes32 private merkleRootOne;
    bytes32 private merkleRootTwo;
    uint16[] private poetTokenIDs = [3090, 3088, 3087, 3086, 3084, 3082];

    function setMerkleRoots(bytes32 rootOne, bytes32 rootTwo) public onlyAdmins {
        merkleRootOne = rootOne;
        merkleRootTwo = rootTwo;
    }

    function setVaultAddress(address addr) public onlyAdmins {
        vault = addr;
    }

    function setPoetTokenIDs(uint16[] calldata ids) public onlyAdmins {
        poetTokenIDs = ids;
    }

    function claim(bytes32[] calldata _merkleProof) public {
        require(claimed[msg.sender] == 0, "This wallet has already claimed");
        claimed[msg.sender]++;

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(_merkleProof, merkleRootOne, leaf)) {
            IERC1155(LOSTPOETS_PAGES).safeTransferFrom(vault, msg.sender, 1, 1, "");
        } else {
            require(MerkleProof.verify(_merkleProof, merkleRootTwo, leaf), "Invalid Merkle proof");

            uint16 id = poetTokenIDs[poetTokenIDs.length - 1];
            poetTokenIDs.pop();

            IERC721(LOSTPOETS).safeTransferFrom(vault, msg.sender, id);
        }
    }
}