// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract KidzukiDistributor is Ownable {

    uint256 public SUPPLY_DISTRIBUTE = 5555;
    uint256 public DEPOSIT_ETH_DISTRIBUTION;
    bytes32 public distroMerkle;
    bool public claimPaused = true;

    mapping(address => bool) public userPaid;
    
    function claim(uint256 amountToClaim, bytes32[] calldata _merkleProof) external {
        require(!claimPaused, "Claim not open");
        address _caller = _msgSender();
        require(!userPaid[_caller], "Already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(_caller, amountToClaim));
        require(MerkleProof.verify(_merkleProof, distroMerkle, leaf), "Invalid proof");

        userPaid[_caller] = true;

        (bool success, ) = payable(_caller).call{value: calculatePayment(amountToClaim)}("");
        require(success, "Failed to send");
    }

    function calculatePayment(uint256 amountToClaim) public view returns(uint256) {
        require(DEPOSIT_ETH_DISTRIBUTION > 0, "No deposit");
        return ( DEPOSIT_ETH_DISTRIBUTION / SUPPLY_DISTRIBUTE ) * amountToClaim;
    }

    function makeDeposit() external payable {
        require(claimPaused, "Claim is open");
        DEPOSIT_ETH_DISTRIBUTION += msg.value;
    }

    function changeDeposit(uint256 _deposit) external onlyOwner {
        DEPOSIT_ETH_DISTRIBUTION = _deposit;
    }

    function setSupply(uint256 _supply) external onlyOwner {
        SUPPLY_DISTRIBUTE = _supply;
    }

    function setMerkle(bytes32 _merkle) external onlyOwner {
        distroMerkle = _merkle;
    }

    function toggleClaim() external onlyOwner {
        claimPaused = !claimPaused;
    }

    function withdrawDeposit() external onlyOwner {

        DEPOSIT_ETH_DISTRIBUTION = 0;
        claimPaused = true;

        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Failed to send");
    }

}