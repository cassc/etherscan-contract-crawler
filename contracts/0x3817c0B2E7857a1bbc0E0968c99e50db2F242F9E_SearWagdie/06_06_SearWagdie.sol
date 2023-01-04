//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../external/IWagdie.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface IConcord {
    function burn(address _from, uint256 _token, uint256 _quantity) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}


contract SearWagdie is Ownable {
    bool public isSearingEnabled;
    address public wagdieAddress;
    address public concordAddress;
    
    mapping(uint16 => uint16) public wagdieSeared;
    mapping(uint16 => bool) public wagdieBlocked;
    mapping(uint16 => bool) public concordBlocked;
    
    event ConcordSeared(uint16 wagdieId, uint16 tokenId, address owner);
    event SearingEnabledChanged(bool isSearingEnabled);

    constructor(address _wagdieAddress, address _concordAddress) {
        wagdieAddress = _wagdieAddress;
        concordAddress = _concordAddress;
    }

    function searConcords(
        SearParams[] calldata _searParams)
    external
    {
        require(isSearingEnabled, "Searing is not enabled");
        require(_searParams.length > 0, "No parameters given");

        for(uint256 i = 0; i < _searParams.length; i++) {
            _searConcord(_searParams[i].wagdieId, _searParams[i].tokenId);
        }
    }

    // Sear WAGDIE and Burn Concord
    function _searConcord(
        uint16 _wagdieId,
        uint16 _tokenId)
    private
    {
        require(wagdieSeared[_wagdieId] == 0, "Character Already Seared");
        require(IConcord(concordAddress).balanceOf(msg.sender, _tokenId) > 0, "You Lack Available Concords");
        require(msg.sender == IWagdie(wagdieAddress).ownerOf(_wagdieId), "Not Character Owner");
        require(!wagdieBlocked[_wagdieId], "Unable to sear this WAGDIE");
        require(!concordBlocked[_tokenId], "Unable to sear this Concord");
        
        // Record Token Searing
        wagdieSeared[_wagdieId] = _tokenId;

        // Burn Concord
        IConcord(concordAddress).burn(msg.sender, _tokenId, 1);

        emit ConcordSeared(_wagdieId, _tokenId, msg.sender);
    }

    function updateIsSearingEnabled(bool _isSearingEnabled) external onlyOwner {
        isSearingEnabled = _isSearingEnabled;
        emit SearingEnabledChanged(isSearingEnabled);
    }

    function setBlockedWAGDIE(BlockParams[] calldata _blockParams) external onlyOwner {
        for(uint256 i = 0; i < _blockParams.length; i++) {
            wagdieBlocked[_blockParams[i].tokenId] = _blockParams[i].isBlocked;
        }
    }

    function setBlockedConcords(BlockParams[] calldata _blockParams) external onlyOwner {
        require(_blockParams.length > 0, "No parameters given");
        for(uint256 i = 0; i < _blockParams.length; i++) {
            concordBlocked[_blockParams[i].tokenId] = _blockParams[i].isBlocked;
        }
    }
}

struct SearParams {
    // Slot1 (32/256 used)
    uint16 wagdieId;
    uint16 tokenId;
}

struct BlockParams {
    // Slot1 (24/256 used)
    uint16 tokenId;
    bool isBlocked;
}