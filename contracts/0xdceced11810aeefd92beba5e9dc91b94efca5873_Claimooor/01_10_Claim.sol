// SPDX-License-Identifier: Do whatever you want

pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";
import {ERC1155Receiver} from "openzeppelin/token/ERC1155/utils/ERC1155Receiver.sol";
import {INameWrapper} from "./INameWrapper.sol";

interface IEnsHood {
    function domainClaimed(string memory domain) external view returns (bool);
}

contract Claimooor is Ownable, ERC1155Receiver {
    INameWrapper public nameWrapper;
    bytes32 private _namesRoot;
    address public resolver;

    bytes32 public parentNode;

    IEnsHood public ensHood;

    mapping(address => bool) public claimed;

    constructor(
        INameWrapper _nameWrapper,
        bytes32 _parentId,
        bytes32 namesRoot,
        address _resolver,
        IEnsHood _ensHood
    ) {
        nameWrapper = _nameWrapper;
        parentNode = _parentId;

        _namesRoot = namesRoot;
        resolver = _resolver;
        ensHood = _ensHood;
    }

    function claim(
        string memory subdomain,
        bytes32[] memory nameProof
    ) external {
        require(!claimed[msg.sender], "1 claim per wallet");

        require(!ensHood.domainClaimed(subdomain), "domain already claimed");

        bytes32 nameLeaf = keccak256(
            bytes.concat(keccak256(abi.encode(subdomain)))
        );

        // check is valid domain
        require(
            MerkleProof.verify(nameProof, _namesRoot, nameLeaf),
            "Invalid name proof"
        );

        claimed[msg.sender] = true;

        nameWrapper.setSubnodeRecord(
            parentNode, //parentNode
            subdomain, //name
            msg.sender, //new owner
            resolver, //resolver
            0, //ttl
            0, //fuses
            0 //expiry0
        );
    }

    // withdraw parent for future city creation airdrop contracts based on tree planting leaderboard
    function withdrawENS() external onlyOwner {
        nameWrapper.safeTransferFrom(
            address(this),
            owner(),
            uint256(parentNode),
            1,
            ""
        );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }
}