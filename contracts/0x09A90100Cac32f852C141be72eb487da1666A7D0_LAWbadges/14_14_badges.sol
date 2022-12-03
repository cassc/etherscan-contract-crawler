// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


/// @title Badges for Legends at War
/// @author SabreGames
/// @notice This contract is the soulbound token(SBT) representation of all the badges that you can earn in LAW game 
contract LAWbadges is ERC721Enumerable,Ownable{

    string private _baseURIextended;

    mapping(address => uint256[]) private _badgeUserArray;

    mapping(uint256 => uint256) public tokenIndex;

    mapping(address => bool) private _operators;

    event BadgeRewarded(address to, uint256 badgeID);

    event BadgeRevoked(address user, uint256 badgeID);

    constructor() ERC721("LegendsAtWarBadges", "badges") {
    }

    /// @notice Reward badge to user
    /// @param to The address of the rewarded user
    /// @param badgeID The ID of the rewarded badge
    function rewardBadge(address to, uint256 badgeID) external onlyOperator {
        _safeMint(to, badgeID);
        _badgeUserArray[to].push(badgeID);
        tokenIndex[badgeID] = _badgeUserArray[to].length;
        emit BadgeRewarded(to, badgeID);
    }

    /// @notice Reward multiple badges using 1 tx
    /// @param to Array of address of the rewarded users
    /// @param badgeID Array of IDs of the rewarded badges
    function rewardBadgeBatch(address[] calldata to, uint256[] calldata badgeID) external onlyOperator {
        require(to.length == badgeID.length,"");
        for (uint256 i = 0; i < badgeID.length; i++) {
            _safeMint(to[i], badgeID[i]);
            _badgeUserArray[to[i]].push(badgeID[i]);
            tokenIndex[badgeID[i]] = _badgeUserArray[to[i]].length;
            emit BadgeRewarded(to[i], badgeID[i]);
        }
    }

    /// @notice Revoke rewarded badge
    /// @param badgeID The ID of the revoked badge
    function revokeBadge(uint256 badgeID) external onlyOperator {
        address owner = ownerOf(badgeID);
        _burn(badgeID);
        _badgeUserArray[owner][tokenIndex[badgeID]] = 0;
        emit BadgeRevoked(owner, badgeID);
    }

    /// @notice Revoke multiple badges
    /// @param badgeID Array of IDs of the revoked badge
    function revokeBadgeBatch(uint256[] calldata badgeID) external onlyOperator {
        for (uint256 i = 0; i < badgeID.length; i++) {
            address owner = ownerOf(badgeID[i]);
            _burn(badgeID[i]);
            _badgeUserArray[owner][tokenIndex[badgeID[i]]] = 0;
            emit BadgeRevoked(owner, badgeID[i]);
        }
    }

    /// @notice Add address as operator
    /// @param addr The address of the new operator
    function addOperator(address addr) external onlyOwner{
        _operators[addr] = true;
    }

    /// @notice Remove address from operators
    /// @param addr The address of the operator
    function removeOperator(address addr) external onlyOwner{
        _operators[addr] = false;
    }

    /// @dev badges with '0' value are revoked
    /// @return Badges as an array of badgeIDs 
    function getAllBadgesIDForUser(address user) external view returns(uint256[] memory){
       return _badgeUserArray[user];
    }

    //overwrite of _baseURI function
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    modifier onlyOperator{
        require(_operators[msg.sender], "Ownable: caller is not operator");
        _;
    }


    /// @notice disabling the 'transfer' option between users as required for the SBT standard
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        require(from == address(0) || to == address(0),"You cannot transfer this token");
        return super._beforeTokenTransfer( from, to, firstTokenId, batchSize);
    }
}