// SPDX-License-Identifier: UNKNOWN

pragma solidity ^0.8.9;
import "MerkleProof.sol";

contract SharedRevenueMerkle {
    // Address that can distribute the Ether
    address public owner;

    struct Distribution {
        bytes32 merkleroot;
        uint256 totalAmount;
        uint256 amountLocked;
        uint256 expirationTime;
        uint256 totalRecipients;
        bool isCancelled;
        mapping(address => bool) addressHasClaimed;
    }

    mapping(uint256 => Distribution) public distributions;

    uint256 public nextDistributionId = 0;

    // Amount of funds that are locked in an active Distribution
    uint256 lockedFunds = 0;

    // Event to log when Ether is distributed
    event Distributed(
        uint256 distributionId,
        uint256 amount,
        uint256 amountOfRecipients
    );

    event DistributionCanceled(uint256 distributionId, uint256 remainingAmount, uint256 totalAmount);

    // Event to log when Ether is claimed
    event Claimed(
        address indexed claimer,
        uint256 amount,
        uint256 distributionId
    );

    event Withdrawal(uint amount, uint when);

    // Contract constructor
    constructor() {
        owner = msg.sender;
    }

    // Modifier to ensure only the owner can call certain functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    // Function to change the owner of the contract
    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    // Function to withdraw all unlocked funds
    function withdraw() external onlyOwner(){
        emit Withdrawal(address(this).balance, block.timestamp);
        payable(owner).transfer(address(this).balance);
    }

    // Function to deposit Ether into the contract
    function deposit() external payable {}

    // Fallback function is called when a function that doesn't exist is called
    fallback() external payable {}

    // Receive function is specifically for sending Ether directly to the contract
    receive() external payable {}

    // Function to distribute Ether to a list of addresses
    function createDistribution(
        uint256 totalAmount,
        uint256 totalRecipients,
        uint256 lockDuration,
        bytes32 merkleroot
    ) external onlyOwner {
        require(
            address(this).balance - lockedFunds >= totalAmount,
            "Insufficient balance in contract"
        );

        Distribution storage dist = distributions[nextDistributionId];

        dist.merkleroot = merkleroot;
        dist.totalAmount = totalAmount;
        dist.amountLocked = totalAmount;
        dist.expirationTime = block.timestamp + lockDuration;
        dist.totalRecipients = totalRecipients;
        dist.isCancelled = false;

        lockedFunds += totalAmount;

        emit Distributed(nextDistributionId, totalAmount, totalRecipients);
        nextDistributionId++;
    }

    // Function to claim Ether
    function claim(
        uint256 distributionId,
        uint256 amount,
        bytes32[] memory proof
    ) external {
        Distribution storage dist = distributions[distributionId];
        require(
            !dist.addressHasClaimed[msg.sender],
            "Address has already claimed from this distribution"
        );
        require(!dist.isCancelled, "Distribution is cancelled");

        require(
            MerkleProof.verify(
                proof,
                dist.merkleroot,
                _generateClaimMerkleLeaf(msg.sender, amount)
            ),
            "Provided data does not match the proof"
        );
        // --- uncomment if you want to lock the claim after expiration
        require(block.timestamp < dist.expirationTime, "Distribution expired");

        dist.addressHasClaimed[msg.sender] = true;
        dist.amountLocked -= amount;
        

        lockedFunds -= amount;

        emit Claimed(msg.sender, amount, distributionId);
        payable(msg.sender).transfer(amount);
    }

    // Function to cancel Distribution
    function cancelDistribution(uint256 distributionId) external onlyOwner {
        Distribution storage dist = distributions[distributionId];
        require(
            block.timestamp > dist.expirationTime,
            "Distribution still active"
        );
        require(!dist.isCancelled, "Distribution is already cancelled");

        lockedFunds -= dist.amountLocked;

        dist.isCancelled = true;

        emit DistributionCanceled(distributionId, dist.amountLocked, dist.totalAmount);
    }

    function _generateClaimMerkleLeaf(
        address _account,
        uint256 _amount
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _amount));
    }

    // Function to get the contract balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Function to get the available balance from the contract
    function getAvailableBalance() external view returns (uint256) {
        return address(this).balance - lockedFunds;
    }

    function getLockedBalance() external view returns (uint256) {
        return lockedFunds;
    }

    // Function to get total eth claimed
    function getTotalClaimed() external view returns (uint256) {
        uint256 res = 0;
        for (uint i = 0; i < nextDistributionId; i++){
            res += (distributions[i].totalAmount - distributions[i].amountLocked);
        }

        return res;
    }
}
