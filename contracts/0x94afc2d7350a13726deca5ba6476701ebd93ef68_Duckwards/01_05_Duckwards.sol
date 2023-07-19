// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Duckwards is Ownable {

    using MerkleProof for bytes32[];

    // Processed claims by version
    mapping(uint256 => mapping(address => bool)) public claimed;

    // Merkle tree root hash
    bytes32 public _rootHash;

    // The version of the drop
    uint256 public _version;

    function setRootHash(bytes32 rootHash) public onlyOwner {
        _rootHash = rootHash;
    }

    function setVersion(uint256 version) public onlyOwner {
        _version = version;
    }

    function setVersionAndRootHash(uint256 version, bytes32 rootHash) public onlyOwner {
        _version = version;
        _rootHash = rootHash;
    }

    function _leaf(address recipient, uint256 amount)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(recipient, amount));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, _rootHash, leaf);
    }


    /**
     * @dev Function to verify merkle tree proofs and mint POAPs to the recipient
     * @param recipient Recipient address of the POAPs to be minted
     * @param amount The amount to be send in eth // TODO: Check if it's eth
     * @param proof Array of proofs to verify the claim
     */
    function claim(address payable recipient, uint256 amount, bytes32[] calldata proof) external {
        require(claimed[_version][recipient] == false, "Recipient already processed for this version!");
        require(_verify(_leaf(recipient, amount), proof), "Recipient not in merkle tree!");
        claimed[_version][recipient] = true;

        recipient.transfer(amount);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw(address payable payee, uint256 amount) public onlyOwner {
        payee.transfer(amount);
    }

    function withdrawAll(address payable payee) public onlyOwner {
        payee.transfer(address(this).balance);
    }

}