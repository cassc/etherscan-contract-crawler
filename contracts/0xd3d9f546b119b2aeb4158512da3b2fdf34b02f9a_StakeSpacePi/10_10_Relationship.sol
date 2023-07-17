// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IRelationship.sol";

/* @title Relationship
 * @author [email protected]
 * @dev This contract is used to manage the invitation relationship.
 *
 * @rules can't invite someone who has already invited you
 * @rules can't invite someone who has already been invited
 * @rules maximum of invitees is limited by gas
*/
contract Relationship is Ownable,IRelationship {

    // @dev default code
    bytes32 public constant defaultCode = keccak256("space0");
    // @dev start time
    uint256 public beginsTime;
    // @dev end time
    uint256 public endsTime;
    // User is the address of the person who is invited
    mapping(address => User) private _relations;
    // code used to invite
    mapping(bytes32 => address) public codeUsed;

    event Binding(address indexed inviter, address indexed invitee, bytes32 code);

    constructor(uint256 ends) {
        beginsTime = block.timestamp;
        endsTime = ends;
        _relations[msg.sender].code = defaultCode;
        _relations[msg.sender].inviter = msg.sender;
        codeUsed[defaultCode] = msg.sender;
    }

    modifier inDuration {
        require(block.timestamp < endsTime, "not in time");
        _;
    }

    // @param inviter address of the person who is inviting
    function binding(bytes32 c) external override inDuration {
        address sender = msg.sender;
        address inviter = codeUsed[c];
        require(inviter != address(0), "code not found");
        require(inviter != sender, "Not allow inviter by self");
        // invitee address info
        User storage self = _relations[sender];
        // inviter address info
        User storage parent = _relations[inviter];

        require(parent.lengths[sender] == 0, "Can not accept child invitation");
        require(self.inviter == address(0), "Already bond invite");
        parent.inviteeList.push(Invitee(sender, block.timestamp));
        parent.lengths[sender] = self.inviteeList.length;

        self.inviter = inviter;
        bytes32 code = _genCode(sender);
        require(codeUsed[code] == address(0), "please try again");
        self.code = code;

        codeUsed[code] = sender;
        emit Binding(inviter, sender, code);
    }

    // @param player address if not invited
    function isInvited(address player) public view override returns (bool){
        if (_relations[player].inviter != address(0)) return true;
        return false;
    }

    // @param get player address invitee list
    function getInviteeList(address player) external view override returns (Invitee[] memory){
        return _relations[player].inviteeList;
    }

    // @param get player address inviter
    function getParent(address player) public view override returns (address){
        return _relations[player].inviter;
    }

    // @param get player address invitation code
    function getInviteCode() external view override returns (bytes32){
        return _relations[msg.sender].code;
    }

    // @param get player address by invitation code
    function getPlayerByCode(bytes32 code) external view override returns (address){
        return codeUsed[code];
    }

    function _genCode(address player) private view  returns (bytes32 hash){
        hash = keccak256(abi.encode(player, block.number));
        return hash;
    }
}