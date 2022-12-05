// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFT.sol";

contract Planting is Ownable {
    NFT nft;

    struct Plant {
        uint256 phase;
        uint256 timestampPhaseStarted;
    }

    mapping(address => Plant) public plantPerUser;
    uint256[5] public phaseDuration;
    uint256 lastPhase = 4;

    event PlantingSuccessful(address user);

    constructor(address _nftAddress) {
        nft = NFT(_nftAddress);

        phaseDuration[0] = 0; // Can start planting right away
        phaseDuration[1] = 6 * 3600; // 6 Hours
        phaseDuration[2] = 18 * 3600; // 18 Hours
        phaseDuration[3] = 48 * 3600; // 48 Hours
        phaseDuration[4] = 96 * 3600; // 96 Hours
    }

    function plant(uint256 _tokenId) public {
        if (plantPerUser[msg.sender].phase == 0) {
            require(nft.ownerOf(_tokenId) == msg.sender, "You don't own this bean!");
            nft.burn(_tokenId);
        }
        require(currentPhaseFinished(msg.sender), "The current growing phase of your plant is not finished yet!");
        require(plantPerUser[msg.sender].phase < lastPhase, "Your plant already reached maximum growth!");

        plantPerUser[msg.sender].phase += 1;
        plantPerUser[msg.sender].timestampPhaseStarted = block.timestamp;

        emit PlantingSuccessful(msg.sender);
    }

    function currentPhaseFinished(address _user) public view returns(bool) {
        Plant memory userPlant = plantPerUser[_user];
        uint256 _currentTimestamp = block.timestamp;
        return userPlant.timestampPhaseStarted + phaseDuration[userPlant.phase] < _currentTimestamp;
    }

    function getPlant(address _user) public view returns(Plant memory plant) {
        return plantPerUser[_user];
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}