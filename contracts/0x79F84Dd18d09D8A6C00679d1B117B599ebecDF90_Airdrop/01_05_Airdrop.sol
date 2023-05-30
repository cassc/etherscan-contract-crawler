//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
 
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Airdrop {
    ERC20 erc20Contract;
    address deployer;
    bytes32 merkleRootAddress;
    mapping(address => bool) claimedAccount;

    constructor(address targetToken, bytes32 root) {
        erc20Contract = ERC20(targetToken);
        deployer = msg.sender;
        merkleRootAddress = root;
    }

    function claim(
        address recipient,
        uint256 amount,
        bytes32[] memory proof
    ) public {
        require(!claimedAccount[recipient], "already claimed");
        require(
            inclusionProof(
                recipient,
                amount,
                proof
            ),
            "merkle proof failed"
        );
        erc20Contract.transfer(recipient, amount);
        claimedAccount[recipient] = true;
    }

    function inclusionProof(
        address recipient,
        uint256 amount,
        bytes32[] memory proof
    ) internal view returns (bool) {
        bytes32 computedHash = keccak256(abi.encodePacked(recipient, amount));

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        return computedHash == merkleRootAddress;
    }
}