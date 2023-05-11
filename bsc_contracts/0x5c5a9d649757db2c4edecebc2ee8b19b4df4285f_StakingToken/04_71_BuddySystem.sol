// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./Address.sol";
import "./Math.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IERC20.sol";

import "./Pausable.sol";
import "./Whitelist.sol";
import "./ReentrancyGuard.sol";
import "./TokensRecoverable.sol";

contract BuddySystem is Whitelist, Pausable, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /////////////////////////////////
    // CONFIGURABLES AND VARIABLES //
    /////////////////////////////////

    struct UserData {
        address upline;
        uint256 downlines;

        mapping(uint256 => address) member;
    }
    
    //////////////////
    // DATA MAPPING //
    //////////////////

    mapping(address => UserData) private _users;

    /////////////////////
    // CONTRACT EVENTS //
    /////////////////////

    event onSetUpline(address indexed player, address indexed buddy);

    //////////////////////////////
    // CONSTRUCTOR AND FALLBACK //
    //////////////////////////////

    constructor () {
        _users[address(0)].upline = address(0);
    }

    receive() payable external {
        revert();
    }

    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////

    // Return the upline of the sender
    function myUpline() public view returns (address){
        return uplineOf(msg.sender);
    }

    // Return the downline count of the sender
    function myDownlines() public view returns (uint256){
        return downlinesOf(msg.sender);
    }

    // Get Team of a User, as an array
    function getTeamOf(address _addr) public view returns (address[] memory team) {
        team = new address[](_users[_addr].downlines);
        for(uint256 i = 0; i < _users[_addr].downlines; i ++) {
            team[i] = _users[_addr].member[i];
        }
    }

    // Return the upline of a player
    function uplineOf(address player) public view returns (address) {
        return _users[player].upline;
    }

    // Return the downline count of a player
    function downlinesOf(address player) public view returns (uint256) {
        return _users[player].downlines;
    }

    // Return the downline address of a player at member
    function getDownlineById(address player, uint256 _pos) public view returns (address) {
        return _users[player].member[_pos];
    }

    /////////////////////
    // WRITE FUNCTIONS //
    /////////////////////

    // Set the upline of the sender
    function setUpline(address _newUpline) public whenNotPaused() returns (uint256) {
        require(_users[msg.sender].upline == address(0), "UPLINE_ALREADY_SET");

        // Set the upline address
        _users[msg.sender].upline = _newUpline;
        _users[_newUpline].downlines += 1;

        uint256 newDownlineId = _users[_newUpline].downlines;
        
        // Store the caller in upline's downline mapping
        _users[_newUpline].member[newDownlineId] = msg.sender;

        // Fire Event
        emit onSetUpline(msg.sender, _newUpline);
        return (downlinesOf(msg.sender));
    }

    //////////////////////
    // SYSTEM FUNCTIONS //
    //////////////////////

    // Pause the Team Airdrop System
    function pause() public ownerOnly() {
        _pause();
    }

    // Unpause the Team Airdrop System
    function unpause() public ownerOnly() {
        _unpause();
    }

    // Reset Upline
    function resetUpline(address _user) public ownerOnly() returns (bool _success) {
        address userUpline = _users[_user].upline;
        
        _users[_user].upline = address(0);
        _users[userUpline].downlines -= 1;

        return true;
    }
}