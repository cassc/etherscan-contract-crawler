// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//      _                 ____            _           _
//     / \   _ __   ___  |  _ \ _ __ ___ (_) ___  ___| |_ ___
//    / _ \ | '_ \ / _ \ | |_) | '__/ _ \| |/ _ \/ __| __/ __|
//   / ___ \| |_) |  __/ |  __/| | | (_) | |  __/ (__| |_\__ \
//  /_/   \_\ .__/ \___| |_|   |_|  \___// |\___|\___|\__|___/
//          |_|                        |__/
//
// https://apeprojects.info/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


interface WarmWallet {
    function balanceOf(address contractAddress, address owner) external view returns (uint256);
}

/// @title ApeProjects is a contract to record projects and possible discounts for BAYC and MAYC owners.
/// @author Darrel Herbst
/// @notice You can see the projects on the web at the _website https://apeprojects.info
contract ApeProjects is Ownable {

    address public _baycaddr;
    address public _maycaddr;
    address public _warmaddr;
    bool public _paused;

    /// @notice _website is where you can view the projects on the web
    string public _website;

    uint256 public _numProjects;
    mapping(uint256 => mapping(string => string)) public _projects;
    mapping(uint256 => address) public _projectOwner;

    /// @notice _allkeys is the list of keys needed to create a project, and the list of keys rendered in getProject.
    string[] public _allkeys;

    /// @notice _adminkeys are keys that cannot be set by users, only the contract owner can set these keys.
    mapping(string => bool) public _adminkeys;

    /// @notice ProjectCreated event is emitted from createProject holds the project id created and the address that created the project.
    event ProjectCreated(uint256 id, address creator);

    /// @notice ProjectEdited event is emitted when a project is changed.
    event ProjectEdited(uint256 id);

    /// @dev constructor with initial configuration
    constructor(address baycaddr, address maycaddr, address warmaddr, string[] memory allkeys, string[] memory adminkeys, string memory website) {
        _baycaddr = baycaddr;
        _maycaddr = maycaddr;
        _warmaddr = warmaddr;
        _website = website;
        for (uint i=0; i < allkeys.length; i++) {
            _allkeys.push(allkeys[i]);
        }
        for (uint i=0; i < adminkeys.length; i++) {
            _adminkeys[adminkeys[i]] = true;
        }
    }

    /// @notice pause will toggle the _pause variable. When false, the contract is not usable. Only the contract owner can call this.
    function pause() public onlyOwner {
        _paused = !_paused;
    }

    /// @notice setWebsite sets the _website variable, only the contract owner can call this.
    function setWebsite(string calldata website) public onlyOwner {
        _website = website;
    }

    /// @notice isAnApe returns true if the caller owns a BAYC or MAYC.
    /// @param caller is a wallet address
    /// @return true if the caller owns a BAYC or MAYC
    function isAnApe(address caller) public view returns (bool) {
        if (WarmWallet(_warmaddr).balanceOf(_baycaddr, caller) > 0) {
            return true;
        }
        if (WarmWallet(_warmaddr).balanceOf(_maycaddr, caller) > 0) {
            return true;
        }
        return false;
    }

    /// @notice keyIndex returns true and the index in _allkeys if the key exists, false if it is not an approved key.
    /// @param key is a key to check
    /// @return bool if the key is an approved key
    /// @return uint256 the index in the _allkeys array
    function keyIndex(string calldata key) public view returns (bool, uint256) {
        for (uint256 i = 0; i < _allkeys.length; i++) {
            if (keccak256(bytes(key)) == keccak256(bytes(_allkeys[i]))) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /// @notice addAdminKey adds the key into the _adminkeys map, only the contract owner can call this.
    /// @param key is the key to add
    function addAdminKey(string calldata key) public onlyOwner {
        _adminkeys[key] = true;
    }

    /// @notice delAdminKey removes the key from the _adminkeys map, only the contract owner can call this.
    /// @param key is the key to remove.
    function delAdminKey(string calldata key) public onlyOwner {
        _adminkeys[key] = false;
    }

    /// @notice addKey adds a key into the _allkeys array, only the contract owner can call this..
    /// @param key is the key to add.
    function addKey(string calldata key) public onlyOwner {
        _allkeys.push(key);
    }

    /// @notice delKey removes a key from the _allkeys array, only the contract owner can call this.
    /// @param key is the key to remove
    function delKey(string calldata key) public onlyOwner {
        uint256 idx = 0;
        bool found = false;
        (found, idx) = keyIndex(key);
        if (found) {
            for (uint256 i = idx; i < _allkeys.length; i++) {
                _allkeys[i] = _allkeys[i+1];
            }
            _allkeys.pop();
        }
    }

    /// @notice getKeys returns the _allkeys array, which is used to render the project in getProject, and needed in createProject.
    /// @return string[] is the list of keys
    function getKeys() public view returns (string[] memory) {
        string[] memory keys  = new string[](_allkeys.length);
        for (uint i = 0; i < _allkeys.length; i++) {
            keys[i] = _allkeys[i];
        }
        return keys;
    }

    /// @notice createProject takes a list of keys and the list of values to create a project entry owned by the caller.
    /// @notice Emits ProjectCreated(id, creator address) event.
    /// @param keys is the list of keys that must match order and length of the _allkeys array
    /// @param vals is the list of values that correspond with each key.
    function createProject(string[] calldata keys, string[] calldata vals) public {
        if (msg.sender != owner()) {
            require(!_paused, "paused");
        }
        require(keys.length == _allkeys.length, "keys length mismatch");
        require(keys.length == vals.length, "keys length != vals length");
        require(isAnApe(msg.sender) == true, "Only apes");
        uint256 pid = _numProjects;

        for (uint256 i = 0; i<_allkeys.length; i++) {
            require(keccak256(bytes(_allkeys[i])) == keccak256(bytes(keys[i])), "Wrong key order");
            if (_adminkeys[keys[i]]) {
                continue;
            }
            if (keccak256(bytes(_allkeys[i])) == keccak256(bytes("owner"))) {
                _projects[pid][_allkeys[i]] = Strings.toHexString(uint256(uint160(msg.sender)), 20);
            } else {
                _projects[pid][_allkeys[i]] = vals[i];
            }
        }
        _projectOwner[pid] = msg.sender;
        _numProjects++;

        emit ProjectCreated(pid, msg.sender);
    }

    /// @notice getProject returns the list of keys and values for the project.
    /// @param id is the project id.
    /// @return retkeys is the list of keys
    /// @return retvals is the corresponding list of values
    function getProject(uint256 id) public view returns (string[] memory retkeys, string[] memory retvals) {
        if (msg.sender != owner()) {
            require(!_paused, "paused");
        }
        retkeys = new string[](_allkeys.length);
        retvals = new string[](_allkeys.length);

        for (uint256 i=0; i < _allkeys.length; i++) {
            retkeys[i] = _allkeys[i];
            retvals[i] = _projects[id][_allkeys[i]];
        }

        return (retkeys, retvals);
    }

    /// @notice editProject allows the project owner (the address that created the project) to add or modify a key's value.
    /// @param id is the project id
    /// @param key is the key being modified
    /// @param value is the new value assigned to the key
    function editProject(uint256 id, string memory key, string memory value) public {
        if (msg.sender != owner()) {
            require(!_paused, "paused");
            require(msg.sender == _projectOwner[id], "Not owner.");
            require(_adminkeys[key] != true, "Not admin");
        }

        _projects[id][key] = value;

        emit ProjectEdited(id);
    }

    /// @notice editProjectOwner can be used to overwrite the project owner address if the address has been compromised or lost.
    /// @notice There will be an off-chain process to decide when this should be done.
    /// @param id is the project id.
    /// @param newOwner is the new address to overwrite as the project owner.
    function editProjectOwner(uint256 id, address newOwner) public onlyOwner {
        _projectOwner[id] = newOwner;
    }
}