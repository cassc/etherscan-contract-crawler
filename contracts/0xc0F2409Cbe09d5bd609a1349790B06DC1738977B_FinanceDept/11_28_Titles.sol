// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Regular Titles v1.0 
 */

import "./Seniority.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// TO-DO: Titles still exceed the max chars

contract Titles is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public constant MAX_LEVELS = 5;
    uint public MAX_CHARS = 28;
    mapping(uint => string) private customs;
    mapping(uint => bool) public customExists;
    Seniority seniority;

    event SeniorityUpdate (uint _tokenId, uint _newLevel, string _newPrefix);
    event TitleUpdate (uint _tokenId, string _newTitle);

// define values

    string[] private entryLevelTitles = [
        "Asst.", 
        "Asst. to", 
        "Jr."
    ];

    string[] private PRE = [
        "Entry Level",
        "",
        "Lead",
        "Sr.",
        "VP",
        "Chief"
    ];

    string[] private A = [
        // "Night-shift",
        "Office",
        "Account",
        "Program",
        "Project",
        "Regional",
        "Branch"
    ];

    string[] private B = [
        "Department",
        "Team",
        "Facilities",
        "Compliance",
        "Mailroom",
        "Finance",
        "Sales",
        "Marketing",
        "IT",
        "HR",
        "Operations",
        "Community",
        "Business",
        "Technical",
        "Helpdesk",
        "Custodial",
        "Data-Entry"
    ];

    string[] private C = [
        "Officer",
        "Accountant",
        "Associate",
        "Leader",
        "Clerk",
        "Administrator",
        "Consultant",
        "Coordinator",
        "Inspector",
        "Rep.",
        "Support",
        "Auditor",
        "Specialist",
        "Analyst",
        "Executive",
        "Controller",
        "Programmer",
        "Developer",
        "Support",
        "Professional",
        "Salesperson",
        "Receptionist"
    ];

//

    constructor(address _addr) {
	    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	    _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
	    _grantRole(MINTER_ROLE, msg.sender);
	    _grantRole(MINTER_ROLE, tx.origin);
        seniority = Seniority(_addr);
	}

// Public View

    function title(uint _jobID) public view returns (string memory) {
        if (customExists[_jobID])
            return (customs[_jobID]);
        string memory _prefix = titlePrefix(_jobID);
        string memory _a;
        string memory _b;
        string memory _c;
        (_a,_b,_c) = titleSeperated(_jobID);

        bool _isAssistant = keccak256(abi.encodePacked((_prefix))) == keccak256(abi.encodePacked((entryLevelTitles[0]))); 
        bool _makeSuffix = (_isAssistant && cointoss(_jobID + 10000)); // move "assistant" to end, half the time
        
        // shorten job if it's bigger than max characters
        uint _jobLength = bytes(_prefix).length + bytes(_a).length + bytes(_b).length + bytes(_c).length + 3; // add 3 characters for spaces
        if (_jobLength > MAX_CHARS) { 
            // reduce number of words
            if (cointoss(_jobID)){
                if (_makeSuffix)
                    return myConcat(_b,_c,_prefix,"");
                else
                    return myConcat(_prefix,_b,_c,"");
            } else {
                if (_makeSuffix)
                    return myConcat(_a, _c, _prefix, "");
                else
                    return myConcat(_prefix,_a, _c, "");
            }
        } else {
            if (_makeSuffix)
                return myConcat(_a, _b, _c, titlePrefix(_jobID));
            else 
                return myConcat(titlePrefix(_jobID),_a, _b, _c);
        }
    }   

    function level(uint _jobID) public view returns (uint) {
        return seniority.level(_jobID);
    }

// Admin

    function setCustomTitle(uint _jobID, string memory _newTitle) public onlyRole(MINTER_ROLE) {
        customs[_jobID] = _newTitle;
        customExists[_jobID] = true;
        emit TitleUpdate(_jobID,_newTitle);
    }

    function setMaxChars(uint _newMax) public onlyRole(MINTER_ROLE) {
        MAX_CHARS = _newMax;
    }

// Contract Management
    
    function seniorityContractAddress() public view returns (address) {
        return address(seniority);
    }

    function setSeniorityContractAddr(address _addr) public onlyRole(MINTER_ROLE) {
        seniority = Seniority(_addr);
    }

// internal

    function titleSeperated(uint _jobID) internal view returns (string memory,string memory,string memory) {
        uint _a = uint(keccak256(abi.encodePacked(_jobID))) % A.length;
        uint _b = uint(keccak256(abi.encodePacked(_jobID,"abc"))) % B.length;
        uint _c = uint(keccak256(abi.encodePacked(_jobID,"def"))) % C.length;
        return (A[_a],B[_b],C[_c]);
    }

    function myConcat(string memory s1, string memory s2, string memory s3, string memory s4) internal pure returns (string memory) {
        string memory result;
        if (bytes(s1).length > 0) 
            result = string.concat(s1, " ", s2," ", s3);
        else    
            result = string.concat(s2," ", s3);
        if (bytes(s4).length > 0)
            result = string.concat(result, " ", s4);
        return result;
    }

    function titlePrefix(uint _jobID) internal view returns (string memory) {
        if (level(_jobID) == 0) {
            uint _x = uint(keccak256(abi.encodePacked(_jobID))) % entryLevelTitles.length;
            return entryLevelTitles[_x];
        } else if (level(_jobID) == 1) {
            return "";
        } else {
            return PRE[level(_jobID)];    
        }
    }

    function cointoss(uint _num) internal pure returns (bool){
        return (uint(keccak256(abi.encodePacked(_num))) % 2 == 0);
    }

}