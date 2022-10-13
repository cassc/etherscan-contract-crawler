// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './MountainNFT.sol';

contract WarriorsDrop is Ownable, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;

    MountainNFT private __MTContract;
    mapping(address => uint256) private nonces;

    constructor(address mtContractAddress) {
        __MTContract = MountainNFT(mtContractAddress);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setMTContract(address addr) external onlyOwner {
        __MTContract = MountainNFT(addr);
    }

    function verify(
        address addr,
        uint32[5] calldata allocations,
        uint32 totalQty,
        uint256 nonce,
        bytes memory signature,
        bool isGen0
    ) public view returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                addr,
                allocations[0],
                allocations[1],
                allocations[2],
                allocations[3],
                allocations[4],
                totalQty,
                nonce,
                isGen0
            )
        );

        return owner() == ECDSA.recover(ECDSA.toEthSignedMessageHash(messageHash), signature);
    }

    function airdropMT(
        address addr,
        uint32[5] calldata allocations,
        uint256 nonce,
        bytes calldata signature,
        bool isGen0
    ) public nonReentrant whenNotPaused {
        require(_msgSender() == addr, 'Invalid caller');
        uint32 totalQty;
        for (uint256 i = 0; i < allocations.length; i++) {
            totalQty += allocations[i];
        }
        require(verify(addr, allocations, totalQty, nonce, signature, isGen0), 'Invalid signature');
        require(nonce == nonces[addr]++, 'Nonce is already used');

        __MTContract.ritualOfSummon(addr, allocations, totalQty, isGen0);
    }

    function getNonce(address addr) public view returns (uint256) {
        return nonces[addr];
    }
}