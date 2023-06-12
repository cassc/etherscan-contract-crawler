// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

/**
 * @title CreampieClaim
 * @author https://twitter.com/TonkaTruckEth
 * @notice get pied - https://twitter.com/TonkaTruckEth
 */

import "./Creampie.sol";

contract CreampieClaim is Ownable {
    Creampie public immutable CREAM_PIE;

    constructor(Creampie _creampie) {
        CREAM_PIE = _creampie;
    }

    uint256 public nutStartedAt;
    bytes32 public nutClaimMerkleRoot;
    uint256 public constant NUT_CLAIM_AMOUNT = 1000000000000000000000;
    uint256 public constant NUT_DURATION = 10 days;
    uint256 public constant INITIAL_VEST = 1 days;

    mapping(address => uint256) public nutClaimed;

    function startNut(bytes32 merkleRoot) external onlyOwner {
        require(nutStartedAt == 0, "Nut: already started");
        nutStartedAt = block.timestamp;
        nutClaimMerkleRoot = merkleRoot;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        nutClaimMerkleRoot = merkleRoot;
    }

    function getNutClaimed(address account) public view returns (uint256) {
        return nutClaimed[account];
    }

    function getClaimableNut(address account) public view returns (uint256) {
        if (nutStartedAt == 0) {
            return 0;
        }

        uint256 timeSinceStarted = (block.timestamp - nutStartedAt) +
            INITIAL_VEST;

        if (timeSinceStarted >= NUT_DURATION) {
            return NUT_CLAIM_AMOUNT;
        }

        return
            ((NUT_CLAIM_AMOUNT * timeSinceStarted) / NUT_DURATION) -
            nutClaimed[account];
    }

    function claimNut(bytes32[] calldata proof) external payable {
        require(nutStartedAt > 0, "Nut: has not started");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        require(
            MerkleProof.verify(proof, nutClaimMerkleRoot, leaf),
            "Nut: Invalid proof for this nut"
        );

        uint256 claimableNut = getClaimableNut(_msgSender());

        require(claimableNut > 0, "Nut: already bust");

        nutClaimed[_msgSender()] += claimableNut;

        CREAM_PIE.transfer(_msgSender(), claimableNut);
    }
}