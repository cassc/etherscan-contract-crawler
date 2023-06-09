//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import './MacroCoin.sol';

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MacroVesting is Ownable {

    MacroCoin public macroCoin;
    uint256 constant public GRACE_PERIOD = 24 hours;
    uint256 public dueDate;
    bytes32 public root;
    address public treasury;
    bool public permanentlyPaused;

    struct AllocationTerm {
        uint256 tokenCount;
        uint256 vestingSchedule;
        uint256 cliff;
        uint256 vestingCadence;
        uint256 startDate;
        bool exempt;
    }

    mapping(bytes32 => bool) public acceptedTerms;
    mapping(bytes32 => uint256) public stopDates;

    mapping(bytes32 => AllocationTerm) public allocationTerms; 
    mapping(bytes32 => uint256) public coinsClaimed;
    mapping(bytes32 => uint256) public lastClaimed;

    mapping(address => bytes32) public activeAllocations;

    event UpdateWhitelist(bytes32 root);
    event Accept(address claimer);
    event Claim(address claimer, uint256 amount);
    event Stop(address claimer);

    constructor(address owner, address coinAddress) {
        transferOwnership(owner);
        macroCoin = MacroCoin(coinAddress);
        treasury = owner;
    }

    modifier notPermanentlyPaused() {
        require(!permanentlyPaused, "PERMANENTLY_PAUSED");
        _;
    }

    /// @notice Sets a new coin address if coin has been updated
    function updateCoinAddress() external notPermanentlyPaused {
        require(macroCoin.newMacroCoin() != address(0x0), "COIN_NOT_UPDATED");
        macroCoin = MacroCoin(macroCoin.newMacroCoin());
    }

    /// @notice Sets a new treasury 
    /// @param newTreasury address of the new treasury
    function setTreasury(address newTreasury) external {
        require(msg.sender == treasury, "NOT_TREASURY");
        treasury = newTreasury;
    }

    /// @notice Define the root merkle hash which will be used 
    /// to verify what addresses are on the whitelist
    /// @param merkleRoot the root of the merkle tree object created from the
    /// hashes of the whitelisted addresses and their data
    function setWhitelist(bytes32 merkleRoot) 
        external 
        onlyOwner 
        notPermanentlyPaused 
    {
        root = merkleRoot;
        emit UpdateWhitelist(merkleRoot);
    }

    /// @notice Users need to accept their allocation before they can claim
    /// @param allocationTerm the caller's data in the leaf node of the merkle tree
    function acceptAllocation(AllocationTerm calldata allocationTerm, bytes32[] memory proof) 
        external 
        notPermanentlyPaused 
    {

        require(_verify(_leaf(allocationTerm.tokenCount, allocationTerm.vestingSchedule, allocationTerm.cliff,
            allocationTerm.vestingCadence, allocationTerm.startDate, 
            msg.sender, allocationTerm.exempt), proof), "DATA_INVALID");

        bytes32 terms = keccak256(abi.encodePacked(allocationTerm.tokenCount, allocationTerm.vestingSchedule, allocationTerm.cliff,
            allocationTerm.vestingCadence, allocationTerm.startDate, msg.sender, allocationTerm.exempt));

        // make sure they don't accidentally lose claimable tokens from
        // a previous allocation by accepting this allocation
        require(remainingVestedTokens(msg.sender) == 0, "MUST_CLAIM_OLD_BEFORE_ACCEPT_NEW");

        require(!acceptedTerms[terms], "ALREADY_ACCEPTED");
        acceptedTerms[terms] = true;

        activeAllocations[msg.sender] = terms;

        allocationTerms[terms].tokenCount = allocationTerm.tokenCount;
        allocationTerms[terms].vestingSchedule = allocationTerm.vestingSchedule;
        allocationTerms[terms].cliff = allocationTerm.cliff;
        allocationTerms[terms].vestingCadence = allocationTerm.vestingCadence;
        allocationTerms[terms].startDate = allocationTerm.startDate;
        allocationTerms[terms].exempt = allocationTerm.exempt;

        emit Accept(msg.sender);

        macroCoin.transferFrom(treasury, address(this), allocationTerm.tokenCount);
    }

    /// @notice Owner can set a stop date for a user
    /// to the time of calling the function
    /// @param user the user the owner is setting the stop date for
    function setStopDate(address user) 
        external 
        onlyOwner 
        notPermanentlyPaused 
    {
        bytes32 activeClaim = activeAllocations[user];
        require(allocationTerms[activeClaim].tokenCount > 0, "NEVER_ACCEPTED");
        require(!allocationTerms[activeClaim].exempt, "EXEMPT");
        require(stopDates[activeClaim] == 0, "STOP_DATE_ALREADY_SET");
        require((block.timestamp - allocationTerms[activeClaim].startDate) <= allocationTerms[activeClaim].vestingSchedule, 
            "VESTING_COMPLETE");
        stopDates[activeClaim] = block.timestamp;

        uint256 totalTime = _timePassed(stopDates[activeClaim], allocationTerms[activeClaim].startDate);
        uint256 remaining = _claimable(totalTime, allocationTerms[activeClaim].tokenCount, coinsClaimed[activeClaim], user);

        emit Stop(user);

        macroCoin.transfer(treasury, allocationTerms[activeClaim].tokenCount - (coinsClaimed[activeClaim] + remaining));
    }

    /// @notice Owner is allowed to pause the vesting if
    /// it needs to be updated
    function permanentlyPause() 
        external 
        onlyOwner
        notPermanentlyPaused 
    {
        permanentlyPaused = true;
        dueDate = block.timestamp + GRACE_PERIOD;
    }

    /// @notice Owner can undo the pause with a grace period
    function undoPermanentPause() external onlyOwner {
        require(permanentlyPaused, "NOT_PERMANENT");
        require(block.timestamp < dueDate, "CANNOT_UNDO_PERMANENT_PAUSE");
        permanentlyPaused = false;
        dueDate = 0;
    }

    /// @notice Users claim their macro coins that are 
    /// available to them at the current time
    /// @dev This contract is an operator of the owner's coins so that this 
    /// contract can send the owner's macro coins to the caller 
    function claim() external notPermanentlyPaused 
    {
        bytes32 activeClaim = activeAllocations[msg.sender];
        uint256 amountToClaim = claimableTokens(msg.sender);
        require(amountToClaim > 0, "NO_TOKENS_TO_CLAIM");
        coinsClaimed[activeClaim] += amountToClaim;
        lastClaimed[activeClaim] = block.timestamp;
        emit Claim(msg.sender, amountToClaim);
        macroCoin.transfer(msg.sender, amountToClaim);
    }

    function remainingVestedTokens() public view returns (uint256) 
    {
        return remainingVestedTokens(msg.sender);
    }

    /// @notice Returns the remaining amount of macro coins that a whitelisted 
    /// address has left to claim throughout the vesting schedule
    function remainingVestedTokens(address user) public view returns (uint256) 
    {
        /*  If the caller doesn't have a stop date, the total amount of remaining coins 
            they have left to claim is the total amount they have been allocated throughout 
            the course of the vesting schedule minus the amount of coins they have claimed already.
            If they do have a stop date but it has already passed, the remaining amount of coins 
            they can claim is equal to the amount they have claimable at the time.
            If the stop date is in the future, the total amount they will be allocated is calculated
            minus what they have already claimed.
        */
        bytes32 activeClaim = activeAllocations[user];        
        if (stopDates[activeClaim] == 0) {
            return allocationTerms[activeClaim].tokenCount - coinsClaimed[activeClaim];
        } else if (stopDates[activeClaim] < block.timestamp) {
            return claimableTokens(user);
        } else {
            uint256 totalTime = _timePassed(stopDates[activeClaim], allocationTerms[activeClaim].startDate);
            return _claimable(totalTime, allocationTerms[activeClaim].tokenCount, coinsClaimed[activeClaim], user);
        }  
    }

    function claimableTokens() public view returns (uint256) 
    {
        return claimableTokens(msg.sender);
    }

    /// @notice Returns the amount of macro coins that a whitelisted address can 
    /// claim at the current time
    function claimableTokens(address user) public view returns (uint256) 
    {
        bytes32 activeClaim = activeAllocations[user];
        // Can only claim coins up to their stop date or end of vesting schedule
        uint256 timePassed;
        if (stopDates[activeClaim] == 0 || stopDates[activeClaim] > block.timestamp) {  
            timePassed = _timePassed(block.timestamp, allocationTerms[activeClaim].startDate);
        } else {
            timePassed = _timePassed(stopDates[activeClaim], allocationTerms[activeClaim].startDate);
        }

        /* If the time hasnt passed their cliff since their start date,
           they have 0 claimable coins at the current moment */
      
        if (timePassed < allocationTerms[activeClaim].cliff) {                                
            return 0;
        }

        if (timePassed < allocationTerms[activeClaim].vestingSchedule) {
            return _claimable(timePassed, allocationTerms[activeClaim].tokenCount, coinsClaimed[activeClaim], user);
        } else {
            return allocationTerms[activeClaim].tokenCount - coinsClaimed[activeClaim];
        }
    }

    /// @notice Returns the earliest date the user hasn't claimed yet
    function nextClaimDate() public view returns (uint256) 
    {
        return nextClaimDate(msg.sender);
    }

    function nextClaimDate(address user) public view returns (uint256) 
    {
        bytes32 activeClaim = activeAllocations[user];
        // If they have claimed everything already, they do not have a 
        // next claim date
        if (coinsClaimed[activeClaim] == allocationTerms[activeClaim].tokenCount) {
            return 0;
        }

        uint256 claimDate;
        if (lastClaimed[activeClaim] == 0) {
            claimDate = allocationTerms[activeClaim].startDate + allocationTerms[activeClaim].cliff;
        } else {
            // Find how many cadences they have claimed so far 
            uint256 cadencesClaimed = (lastClaimed[activeClaim] - allocationTerms[activeClaim].startDate) 
                / allocationTerms[activeClaim].vestingCadence;

            // Find their next claim date
            claimDate = allocationTerms[activeClaim].startDate + (cadencesClaimed * allocationTerms[activeClaim].vestingCadence) 
                + allocationTerms[activeClaim].vestingCadence;
        }

        // If their next claim date is past their stop date, they cannot claim anymore coins
        if ((stopDates[activeClaim] != 0) && (claimDate > stopDates[activeClaim])) {
            return 0;
        }

        return claimDate;
    }

    function _timePassed(uint256 finalDate, uint256 startDate) private pure returns (uint256) {
        return finalDate - startDate;
    }

    function _claimable(uint256 time, uint256 allocation, uint256 amtTokens, address account) 
        private view returns (uint256) 
    {
        bytes32 activeClaim = activeAllocations[account];
        // Total cadences there have been
        uint256 cadencesPassed = time / allocationTerms[activeClaim].vestingCadence;
        // Every cadence, a user can claim cadence / vesting schedule of their total allocation 
        uint256 totalClaimable = allocation * cadencesPassed * 
            allocationTerms[activeClaim].vestingCadence / allocationTerms[activeClaim].vestingSchedule; 
        return (totalClaimable - amtTokens);
    }

    /// @notice Creates a leaf node from the keccak256 hash of the address's data 
    function _leaf(
        uint256 allocation, 
        uint256 vestingSchedule,
        uint256 cliff,
        uint256 vestingCadence,
        uint256 startDate, 
        address account,
        bool exempt
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(allocation, vestingSchedule, cliff, 
            vestingCadence, startDate, account, exempt));
    }

    /// @notice Verifies that the leaf node created from the user's data is 
    /// in the merkle tree defined by `root`
    /// @dev Uses Open Zeppelin's MerkleProof library to verify
    function _verify(bytes32 leaf, bytes32[] memory proof) private view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

}