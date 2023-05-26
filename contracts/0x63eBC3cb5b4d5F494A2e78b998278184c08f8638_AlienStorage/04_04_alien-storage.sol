// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IAlienFrensIncubator {
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function burnIncubatorForAddress(address burnTokenAddress) external;
}

interface IAFE {
    function ownerOf(uint256 id) external view returns (address);
}

contract AlienStorage is Ownable, ReentrancyGuard {
    address public IncubatorContract =
        0x9C8882c6B3e40530CDBCe404Eef003443b1E455A;
    address public AFEContract = 0x47A00fC8590C11bE4c419D9Ae50DEc267B6E24ee;
    mapping(uint256 => bool) public IdIsEvolved;
    mapping(uint8 => string) public partnershipName; // partnershipID => partnershipName -- there is no partnership 0
    mapping(uint8 => uint256) public partnershipMaxMints; // partnershipID => maxMints
    mapping(uint8 => uint256) public partnershipMintCounter; // partnershipID => numMints
    mapping(uint8 => bool) public partnershipIsActive; // partnershipID => isActive
    mapping(uint256 => uint8) public partnershipTokens; // tokenID => partnershipID
    mapping(uint256 => uint256) public metadataId; // tokenID => metadataId -- this associates the tokenID with the ID for metadata
    mapping(uint8 => bool) public partnershipOpen; // partnershipID => allTokensCanEvolve (if true, all tokens can evolve
    uint8 public numberOfPartnerships;
    uint256[] oneOfOnes = [
        0,
        1,
        2,
        3,
        4,
        5,
        708,
        1421,
        2121,
        2988,
        3637,
        4200,
        4946,
        5560,
        6281,
        6969,
        7549,
        8181,
        8700,
        9425,
        9999,
        10719,
        11451,
        12104
    ];
    bool public isActive = false;

    function setIncubatorContract(address _IncubatorContract) public onlyOwner {
        IncubatorContract = _IncubatorContract;
    }

    function setAFEContract(address _contract) public onlyOwner {
        AFEContract = _contract;
    }

    function setIsActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function isOneOfOne(uint256 tokenId) public view returns (bool) {
        for (uint8 i = 0; i < oneOfOnes.length; i++) {
            if (tokenId == oneOfOnes[i]) {
                return true;
            }
        }
        return false;
    }

    function createPartnership(
        string calldata _partnershipName,
        uint256 maxMints
    ) public onlyOwner {
        require(numberOfPartnerships < 255, "Max partnerships reached");
        require(maxMints > 0, "Max mints must be greater than 0");
        require(
            bytes(_partnershipName).length > 0,
            "Partnership name must be greater than 0"
        );
        numberOfPartnerships++;
        partnershipName[numberOfPartnerships] = _partnershipName;
        partnershipMaxMints[numberOfPartnerships] = maxMints;
    }

    function updatePartnership(
        uint8 partnershipId,
        uint256 maxMints,
        bool allTokensCanEvolve,
        bool _partnershipIsActive
    ) public onlyOwner {
        require(
            partnershipId <= numberOfPartnerships,
            "Partnership doesn't exist"
        );
        require(partnershipId != 0, "Partnership doesn't exist");
        require(maxMints > 0, "Max mints must be greater than 0");
        require(
            partnershipMintCounter[partnershipId] < maxMints,
            "Max mints must be greater than current mints"
        );
        partnershipMaxMints[partnershipId] = maxMints;
        partnershipOpen[partnershipId] = allTokensCanEvolve;
        partnershipIsActive[partnershipId] = _partnershipIsActive;
    }

    function addTokensToPartnership(
        uint8 partnershipId,
        uint256[] calldata tokenIds
    ) public onlyOwner {
        require(
            partnershipId <= numberOfPartnerships,
            "Partnership doesn't exist"
        );
        require(partnershipId != 0, "Partnership doesn't exist");
        for (uint8 i = 0; i < tokenIds.length; i++) {
            partnershipTokens[tokenIds[i]] = partnershipId;
        }
    }

    function getTokenInfo(
        uint256 tokenId
    ) public view returns (string memory, uint8, bool, uint256) {
        // partnershipName, partnershipId, isEvolved, metadataId
        return (
            partnershipName[partnershipTokens[tokenId]],
            partnershipTokens[tokenId],
            IdIsEvolved[tokenId],
            metadataId[tokenId]
        );
    }

    function getPartnershipInfo(
        uint8 partnershipId
    ) public view returns (string memory, uint256, uint256, bool) {
        // partnershipName, maxMints, numMints
        return (
            partnershipName[partnershipId],
            partnershipMaxMints[partnershipId],
            partnershipMintCounter[partnershipId],
            partnershipOpen[partnershipId]
        );
    }

    event EvolveEvent(uint256 tokenId);

    function evolve(uint256 AFEtokenId, uint8 partnershipId) external {
        require(isActive == true, "Evolving is not active");
        require(
            IAlienFrensIncubator(IncubatorContract).balanceOf(msg.sender, 0) >
                0,
            "You don't own an Incubator"
        );
        require(
            IAFE(AFEContract).ownerOf(AFEtokenId) == msg.sender,
            "You are not the owner of this token"
        );
        require(IdIsEvolved[AFEtokenId] == false, "Already evolved");
        require(
            partnershipMintCounter[partnershipId] <
                partnershipMaxMints[partnershipId],
            "Max mints reached for this partnership"
        );
        require(isOneOfOne(AFEtokenId) == false, "This token is a one of one");
        if (partnershipOpen[partnershipId] == false) {
            require(
                partnershipTokens[AFEtokenId] == partnershipId,
                "Token ID not associated with this partnership"
            );
        }
        require(
            partnershipIsActive[partnershipId] == true,
            "Partnership is not active"
        );
        IdIsEvolved[AFEtokenId] = true;
        metadataId[AFEtokenId] = partnershipMintCounter[partnershipId];
        partnershipMintCounter[partnershipId]++;
        if (partnershipOpen[partnershipId]){
            partnershipTokens[AFEtokenId] = partnershipId;
        }
        // burn Incubator
        IAlienFrensIncubator(IncubatorContract).burnIncubatorForAddress(
            msg.sender
        );

        emit EvolveEvent(AFEtokenId);
    }
}