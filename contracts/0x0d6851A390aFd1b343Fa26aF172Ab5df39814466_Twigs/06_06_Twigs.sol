// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
  CryptoHoots (TWIGS)         
                        ____________________     
                      /                      \    
       ________      |   Burn moar twiggies!  |   
      |        |     |      Hoot Hoot MF!     |   
      |        |      \ ____________________ /      
    __|________|__   /
     / ___  ___ \    
    / / @ \/ @ \ \     
    \ \___/\___/ /     
     \____\/____/        
    /  \      /  \
   /    \    /    \ 
   |    |    |    |
    \  /      \  /
     \/\______/\/
       | |  | |
       /|\  /|\

 */

interface IHoots {
    function balanceOf(address _user) external view returns(uint256);
    function ownerOf(uint256 _tokenId) external view returns(address);
    function totalSupply() external view returns (uint256);
}

contract Twigs is ERC20("Twigs", "TWIGS"), Ownable {
    struct ContractSettings {
        uint256 baseRate;
        uint256 initIssuance;
        uint256 start;
        uint256 end;
    }

    mapping(address => ContractSettings) public contractSettings;
    mapping(address => bool) public trustedContracts;

    uint256 constant public MAX_BASE_RATE = 10 ether;
    uint256 constant public MAX_INITIAL_ISSUANCE = 300 ether;

    // Prevents new contracts from being added or changes to disbursement if permanently locked
    bool public isLocked = false;
    mapping(bytes32 => uint256) public lastClaim;
    
    event RewardPaid(address indexed user, uint256 reward);

    constructor() {}

    /**
        - needs onlyOwner flag
        - needs to check that the baseRate and initIssuance are not greater than the max settings
        - require that contract isn't locked
     */
    function addContract(address _contractAddress, uint256 _baseRate, uint256 _initIssuance) public onlyOwner {
        require(_baseRate <= MAX_BASE_RATE && _initIssuance <= MAX_INITIAL_ISSUANCE, "baseRate or initIssuance exceeds max value.");
        require(!isLocked, "Cannot add any more contracts.");

        // add to trustedContracts
        trustedContracts[_contractAddress] = true;

        // initialize contractSettings
        contractSettings[_contractAddress] = ContractSettings({ 
            baseRate: _baseRate,
            initIssuance: _initIssuance,
            start: block.timestamp,
            end: type(uint256).max
        });
    }

    /**
        - sets an end date for when rewards officially end
     */
    function setEndDateForContract(address _contractAddress, uint256 _endTime) public onlyOwner {
        require(!isLocked, "Cannot modify end dates after lock");
        require(trustedContracts[_contractAddress], "Not a trusted contract");
        
        contractSettings[_contractAddress].end = _endTime;
    }

    function claimReward(address _contractAddress, uint256 _tokenId) public returns (uint256) {
        require(trustedContracts[_contractAddress], "Not a trusted contract.");
        require(contractSettings[_contractAddress].end > block.timestamp, "Time for claiming on that contract has expired.");
        require(IHoots(_contractAddress).ownerOf(_tokenId) == msg.sender, "Caller does not own the token being claimed for.");

        // compute twigs to be claimed
        uint256 unclaimedReward = computeUnclaimedReward(_contractAddress, _tokenId);

        // update the lastClaim date for tokenId and contractAddress
        bytes32 lastClaimKey = keccak256(abi.encode(_contractAddress, _tokenId));
        lastClaim[lastClaimKey] = block.timestamp;

        // mint the tokens and distribute to msg.sender
        _mint(msg.sender, unclaimedReward);
        emit RewardPaid(msg.sender, unclaimedReward);

        return unclaimedReward;
    }

    function claimRewards(address _contractAddress, uint256[] calldata _tokenIds) public returns (uint256) {
        require(trustedContracts[_contractAddress], "Not a trusted contract.");
        require(contractSettings[_contractAddress].end > block.timestamp, "Time for claiming has expired");

        uint256 totalUnclaimedRewards = 0;

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            require(IHoots(_contractAddress).ownerOf(_tokenId) == msg.sender, "Caller does not own the token being claimed for.");

            // compute twigs to be claimed
            uint256 unclaimedReward = computeUnclaimedReward(_contractAddress, _tokenId);
            totalUnclaimedRewards = totalUnclaimedRewards + unclaimedReward;

            // update the lastClaim date for tokenId and contractAddress
            bytes32 lastClaimKey = keccak256(abi.encode(_contractAddress, _tokenId));
            lastClaim[lastClaimKey] = block.timestamp;
        }

        // mint the tokens and distribute to msg.sender
        _mint(msg.sender, totalUnclaimedRewards);
        emit RewardPaid(msg.sender, totalUnclaimedRewards);

        return totalUnclaimedRewards;
    }

    function permanentlyLock() public onlyOwner {
        isLocked = true;
    }

    function getUnclaimedRewardAmount(address _contractAddress, uint256 _tokenId) public view returns (uint256) {
        require(trustedContracts[_contractAddress], "Not a trusted contract");

        uint256 unclaimedReward  = computeUnclaimedReward(_contractAddress, _tokenId);
        return unclaimedReward;
    }

    function getUnclaimedRewardsAmount(address _contractAddress, uint256[] calldata _tokenIds) public view returns (uint256) {
        require(trustedContracts[_contractAddress], "Not a trusted contract");

        uint256 totalUnclaimedRewards = 0;

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            totalUnclaimedRewards += computeUnclaimedReward(_contractAddress, _tokenIds[i]);
        }

        return totalUnclaimedRewards;
    }

    function getTotalUnclaimedRewardsForContract(address _contractAddress) public view returns (uint256) {
        require(trustedContracts[_contractAddress], "Not a trusted contract");

        uint256 totalUnclaimedRewards = 0;
        uint256 totalSupply = IHoots(_contractAddress).totalSupply();

        for(uint256 i = 0; i < totalSupply; i++) {
            totalUnclaimedRewards += computeUnclaimedReward(_contractAddress, i);
        }

        return totalUnclaimedRewards;
    }

    function getLastClaimedTime(address _contractAddress, uint256 _tokenId) public view returns (uint256) {
        require(trustedContracts[_contractAddress], "Not a trusted contract");

        bytes32 lastClaimKey = keccak256(abi.encode(_contractAddress, _tokenId));

        return lastClaim[lastClaimKey];
    }

    function computeAccumulatedReward(uint256 _lastClaimDate, uint256 _baseRate, uint256 currentTime) internal pure returns (uint256) {
        require(currentTime > _lastClaimDate, "Last claim date must be smaller than block timestamp");

        uint256 secondsElapsed = currentTime - _lastClaimDate;
        uint256 accumulatedReward = secondsElapsed * _baseRate / 1 days;

        return accumulatedReward;
    }

    function computeUnclaimedReward(address _contractAddress, uint256 _tokenId) internal view returns (uint256) {
        require(trustedContracts[_contractAddress], "Not a trusted contract");
        
        // Will revert if tokenId does not exist
        IHoots(_contractAddress).ownerOf(_tokenId);

        // build the hash for lastClaim based on contractAddress and tokenId
        bytes32 lastClaimKey = keccak256(abi.encode(_contractAddress, _tokenId));
        uint256 lastClaimDate = lastClaim[lastClaimKey];
        uint256 baseRate = contractSettings[_contractAddress].baseRate;

        // if there has been a lastClaim, compute the value since lastClaim
        if (lastClaimDate != uint256(0)) {
            return computeAccumulatedReward(lastClaimDate, baseRate, block.timestamp);
        } 
        else {
            // if there has not been a lastClaim, add the initIssuance + computed value since contract startDate
            uint256 totalReward = computeAccumulatedReward(contractSettings[_contractAddress].start, baseRate, block.timestamp) + contractSettings[_contractAddress].initIssuance;

            return totalReward;
        }
    }
}