//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "hardhat/console.sol";

interface ERC1155Token is IERC1155 {
    function creators(uint256 _tokenId)
        external
        returns (address _tokenCreator);
}

contract MetaproRoyalty is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

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

    // @dev: dictionary with RoyaltyTeamMember[] - tokenContractAddress => token_id => RoyaltyTeamMember[]
    mapping(address => mapping(uint256 => RoyaltyTeamMember[]))
        private royaltyTeamMembers;

    // @dev: dictionary with RoyaltyTeamConfiguration - token_id -> RoyaltyTeamConfiguration
    mapping(address => mapping(uint256 => RoyaltyTeamConfiguration))
        public royaltyTeam;

    uint256 public currentTeamId = 1;

    event CreateTeam(address owner);

    modifier shouldBeTheSameLenght(
        address[] memory _members,
        uint256[] memory _royaltyMemberFees
    ) {
        require(
            _royaltyMemberFees.length == _members.length,
            "Royality member fees must be equal to members quantity"
        );
        _;
    }

    modifier royaltySumShouldBeCorrect(uint256[] memory _royaltyMemberFees) {
        uint256 rayaltyFeesSum = 0;
        for (uint256 i = 0; i < _royaltyMemberFees.length; i++) {
            rayaltyFeesSum += _royaltyMemberFees[i];
        }
        require(
            rayaltyFeesSum <= 1000,
            "Royality member fees sum can not be greater than 1000 = 10%"
        );
        _;
    }

    function checkIfImplemented(uint256 _tokenId, address _tokenContractAddress)
        private
        returns (bool)
    {
        (bool success, bytes memory _unusedData) = address(
            _tokenContractAddress
        ).delegatecall(abi.encodeWithSignature("creators(uint256)", _tokenId));
        return success;
    }

    function createTeam(
        uint256 _tokenId,
        address _tokenContractAddress,
        address[] memory _members,
        uint256[] memory _royaltyMemberFees
    )
        external
        shouldBeTheSameLenght(_members, _royaltyMemberFees)
        royaltySumShouldBeCorrect(_royaltyMemberFees)
        returns (uint256)
    {
        bool creatorsImplemented = checkIfImplemented(
            _tokenId,
            _tokenContractAddress
        );

        require(
            creatorsImplemented,
            "Token contract does not implement creators(uint256 _tokenId) -> address function "
        );
        // If the function is not implemented, halt execution with an error message

        require(
            ERC1155Token(_tokenContractAddress).creators(_tokenId) ==
                msg.sender,
            "Account needs to be creator of the token"
        );

        require(_members.length > 0, "Members should not be empty");

        RoyaltyTeamConfiguration storage currentTeam = royaltyTeam[
            _tokenContractAddress
        ][_tokenId];

        require(
            currentTeam.tokenId != _tokenId,
            "Team for the current token id is already created"
        );

        RoyaltyTeamMember[] storage currentTeamMembers = royaltyTeamMembers[
            _tokenContractAddress
        ][_tokenId];

        for (uint256 i = 0; i < _members.length; i++) {
            RoyaltyTeamMember memory teamMember = RoyaltyTeamMember(
                _members[i],
                _royaltyMemberFees[i]
            );
            currentTeamMembers.push(teamMember);
        }

        RoyaltyTeamConfiguration
            memory teamConfiguration = RoyaltyTeamConfiguration(
                currentTeamId,
                _tokenId,
                msg.sender
            );

        royaltyTeam[_tokenContractAddress][_tokenId] = teamConfiguration;
        currentTeamId += 1;

        emit CreateTeam(msg.sender);

        return teamConfiguration.teamId;
    }

    function changeTeamMembersAndRoyalty(
        uint256 _tokenId,
        address _tokenContractAddress,
        address[] memory _members,
        uint256[] memory _royaltyMemberFees
    )
        external
        shouldBeTheSameLenght(_members, _royaltyMemberFees)
        royaltySumShouldBeCorrect(_royaltyMemberFees)
    {
        RoyaltyTeamConfiguration storage teamConfiguration = royaltyTeam[
            _tokenContractAddress
        ][_tokenId];

        RoyaltyTeamMember[] storage currentTeamMembers = royaltyTeamMembers[
            _tokenContractAddress
        ][_tokenId];

        require(
            teamConfiguration.teamOwner == msg.sender,
            "Only owner can change the team configuration"
        );

        if (currentTeamMembers.length > 0) {
            for (uint256 i = 0; i < currentTeamMembers.length; i++) {
                delete currentTeamMembers[i];
            }
        }

        for (uint256 i = 0; i < _members.length; i++) {
            RoyaltyTeamMember memory teamMember = RoyaltyTeamMember(
                _members[i],
                _royaltyMemberFees[i]
            );
            if (i <= currentTeamMembers.length - 1) {
                currentTeamMembers[i] = teamMember;
            } else {
                currentTeamMembers.push(teamMember);
            }
        }
    }

    function getTeamMembers(uint256 _tokenId, address _tokenContractAddress)
        external
        view
        returns (RoyaltyTeamMember[] memory)
    {
        RoyaltyTeamMember[] storage allMembers = royaltyTeamMembers[
            _tokenContractAddress
        ][_tokenId];

        uint256 correctMembersSize = 0;

        for (uint256 i = 0; i < allMembers.length; i++) {
            if (allMembers[i].member != address(0)) {
                correctMembersSize += 1;
            }
        }

        RoyaltyTeamMember[] memory correctTeamMembers = new RoyaltyTeamMember[](
            correctMembersSize
        );

        uint256 correctIndex = 0;
        for (uint256 i = 0; i < allMembers.length; i++) {
            if (allMembers[i].member != address(0)) {
                correctTeamMembers[correctIndex] = allMembers[i];
                correctIndex++;
            }
        }

        return correctTeamMembers;
    }

    function getTeam(uint256 _tokenId, address _tokenContractAddress)
        external
        view
        returns (RoyaltyTeamConfiguration memory)
    {
        RoyaltyTeamConfiguration storage team = royaltyTeam[
            _tokenContractAddress
        ][_tokenId];
        return team;
    }
}