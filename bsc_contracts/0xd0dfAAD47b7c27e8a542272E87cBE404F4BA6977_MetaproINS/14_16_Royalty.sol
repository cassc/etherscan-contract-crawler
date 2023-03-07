//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Define the struct in the SharedStruct contract
contract Royalty {
    struct RoyaltyTeamMember {
        address member;
        // @dev: royalty fee - integer value - example: 1000 -> 10%
        uint256 royaltyFee;
    }

    struct RoyaltyTeamConfiguration {
        uint256 teamId;
        uint256 tokenId;
        address teamOwner;
    }
}

//  royalty
interface MetaproRoyalty {
    function getTeamMembers(uint256 _tokenId, address _tokenContractAddress)
        external
        view
        returns (Royalty.RoyaltyTeamMember[] memory);

    function getTeam(uint256 _tokenId, address _tokenContractAddress)
        external
        view
        returns (Royalty.RoyaltyTeamConfiguration memory);
}