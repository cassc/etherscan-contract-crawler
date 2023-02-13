// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {CursedDrink} from "./CursedDrink.sol";

// _____/\\\\\\\\\\\___          __/\\\_____________
//  ___/\\\/////////\\\_          _\/\\\_____________
//   __\//\\\______\///__          _\/\\\_____________
//    ___\////\\\_________          _\/\\\_____________
//     ______\////\\\______          _\/\\\_____________
//      _________\////\\\__ Screaming _\/\\\_____________
//       __/\\\______\//\\\__   Labs   _\/\\\_____________
//        _\///\\\\\\\\\\\/___          _\/\\\\\\\\\\\\\\\_
//         ___\///////////_____          _\///////////////__

contract CursedDrinkAirdrop is Ownable, Pausable, ReentrancyGuard {
    CursedDrink public immutable cursedDrink;
    bytes32 public merkleRoot;

    mapping(address => bool) public airdropClaimed;

    constructor(
        CursedDrink _cursedDrink,
        bytes32 _merkleRoot
    ) {
        cursedDrink = _cursedDrink;
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Claim the Cursed Drink airdrop
     *
     * @param proof The Merkle Proof
     */
    function claim(
        bytes32[] calldata proof
    ) external whenNotPaused nonReentrant {
        require(
            isEligible(msg.sender, proof),
            "CursedDrinkAirdrop: Not eligible"
        );
        require(
            !airdropClaimed[msg.sender],
            "CursedDrinkAirdrop: Airdrop already claimed"
        );
        cursedDrink.mint(msg.sender, 0, 1, "");
        airdropClaimed[msg.sender] = true;
    }

    /**
     * @notice Change the merkle root
     *
     * @param _merkleRoot The new merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Hash an address
     *
     * @param _account The address to be hashed
     *
     * @return bytes32 The hashed address
     */
    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    /**
     * @notice Returns true if a leaf can be proved to be a part of a merkle tree defined by root
     *
     * @param _leaf The leaf
     * @param _proof The Merkle Proof
     *
     * @return bool Return true if a leaf can be proved to be a part of a merkle tree defined by root, false othewise
     */
    function _verify(
        bytes32 _leaf,
        bytes32[] memory _proof
    ) internal view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    /**
     * @notice Check if an address is eligible or not
     *
     * @param _account The account checked
     * @param _proof The Merkle Proof
     *
     * @return bool Return true if an address is eligible, false otherwise
     */
    function isEligible(
        address _account,
        bytes32[] calldata _proof
    ) public view returns (bool) {
        return _verify(leaf(_account), _proof);
    }
}