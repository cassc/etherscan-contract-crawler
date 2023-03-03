// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";

/**
* @title URI or Text Storage
* @dev Store & retrieve Links or Text in a mapping variable by name.
*/
/// @author developer's website 🐸 https://www.halfsupershop.com/ 🐸
contract LinkStorage is Ownable{

    mapping(string => string) public linkFromName;

    mapping(address => mapping(string => bool)) public editorApproval;

    address public projectLeader;
    address[] public admins;

    /**
    * @dev Store link in a name mapping
    * @param _name unique link name
    * @param _uri link
    */
    function storeLink(string memory _name, string memory _uri) public {
        require(keccak256(abi.encodePacked((linkFromName[_name]))) == keccak256(abi.encodePacked((""))), "Name Already Exists");
        if (!checkIfAdmin()) {
            require(editorApproval[msg.sender][_name], "Must Have Editor Approval");
        }
        linkFromName[_name] = _uri;
    }

    /**
    * @dev Edit a stored link in a name mapping
    * @param _name unique link name
    * @param _uri link
    */
    function editLink(string memory _name, string memory _uri) public {
        require(keccak256(abi.encodePacked((linkFromName[_name]))) != keccak256(abi.encodePacked((""))), "Name Doesn't Exists");
        require(keccak256(abi.encodePacked((linkFromName[_name]))) != keccak256(abi.encodePacked((_uri))), "Name Already Set To That");
        if (!checkIfAdmin()) {
            require(editorApproval[msg.sender][_name], "Must Have Editor Approval");
        }
        linkFromName[_name] = _uri;
    }

    /**
    * @dev Return Link from a Name 
    * @return linkFromName _name
    */
    function retrieveLinkByName(string memory _name) public view returns (string memory) {
        return linkFromName[_name];
    }

    /**
    * @dev Set the approval for an editor to edit linkFromName.
    * - Only Admins can call this function
    */
    function setEditor(address _editor, string memory _name, bool _state) public onlyAdmins {
        editorApproval[_editor][_name] = _state;
    }

    function transferEditor(address _newEditor, string memory _name) public {
        require(editorApproval[msg.sender][_name], "You Are Not The Editor Of That Name");
        editorApproval[msg.sender][_name] = false;
        editorApproval[_newEditor][_name] = true;
    }

    /**
    * @dev Throws if called by any account other than the owner or admin.
    */
    modifier onlyAdmins() {
        _checkAdmins();
        _;
    }

    /**
    * @dev Throws if the sender is not the owner or admin.
    */
    function _checkAdmins() internal view virtual {
        require(checkIfAdmin(), "!A");
    }

    function checkIfAdmin() public view returns(bool) {
        if (msg.sender == owner() || msg.sender == projectLeader) {
            return true;
        }
        if(admins.length > 0){
            for (uint256 i = 0; i < admins.length; i++) {
                if(msg.sender == admins[i]){
                    return true;
                }
            }
        }
        
        // Not an Admin
        return false;
    }

    /**
    * @dev Owner and Project Leader can set the addresses as approved Admins.
    * Example: ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"]
    */
    function setAdmins(address[] calldata _users) public onlyAdmins {
        require(msg.sender == owner() || msg.sender == projectLeader, "Not Owner or Project Leader");
        delete admins;
        admins = _users;
    }

    /**
    * @dev Owner or Project Leader can set the address as new Project Leader.
    */
    function setProjectLeader(address _user) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Not Owner or Project Leader");
        projectLeader = _user;
    }
}