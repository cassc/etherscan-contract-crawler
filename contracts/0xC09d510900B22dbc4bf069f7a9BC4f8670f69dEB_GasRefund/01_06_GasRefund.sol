// SPDX-License-Identifier: MIT
/* solhint-disable quotes */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GasRefund is Ownable {
    event Received(address, uint256);

    bytes32 public refundMerkleRoot;
    bytes32 public cheethRefundMerkleRoot;
    address public cheethAddress;
    mapping(address => bool) public refundedAddresses;
    mapping(address => bool) public cheethRefundedAddresses;

    function refund(uint256 refundAmount, bytes32[] calldata proof) external {
        require(!refundedAddresses[msg.sender], "already refunded");
        require(_verify(refundMerkleRoot, refundAmount, proof), "invalid proof");
        refundedAddresses[msg.sender] = true;
        Address.sendValue(payable(msg.sender), refundAmount);
    }

    function refundCheeth(uint256 refundAmount, bytes32[] calldata proof) external {
        require(!cheethRefundedAddresses[msg.sender], "cheeth already refunded");
        require(_verify(cheethRefundMerkleRoot, refundAmount, proof), "invalid cheeth proof");
        cheethRefundedAddresses[msg.sender] = true;
        IERC20(cheethAddress).transfer(msg.sender, refundAmount);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function _verify(
        bytes32 merkleRoot,
        uint256 amount,
        bytes32[] calldata proof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function setCheethAddress(address _cheethAddress) external onlyOwner {
        cheethAddress = _cheethAddress;
    }

    function setRefundMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        refundMerkleRoot = merkleRoot;
    }

    function setCheethRefundMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        cheethRefundMerkleRoot = merkleRoot;
    }

    function withdraw(address to) external onlyOwner {
        uint256 totalEth = address(this).balance;
        uint256 totalCheeth = IERC20(cheethAddress).balanceOf(address(this));
        IERC20(cheethAddress).transfer(to, totalCheeth);
        Address.sendValue(payable(to), totalEth);
    }
}