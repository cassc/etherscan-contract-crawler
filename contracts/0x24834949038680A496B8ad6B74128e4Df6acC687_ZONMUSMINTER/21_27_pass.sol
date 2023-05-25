// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import './addresslisttemp.sol';

contract ZONMUSPASS is ERC721Royalty, AccessControl, DefaultOperatorFilterer {
    using Strings for uint256;

    bytes32 FREEZE_ROLE = keccak256('FREEZE_ROLE');
    string baseURI = 'https://ousiass.com/zmp/';

    mapping(address => bool) isFreezed;

    uint256 nightStartTime = 9;
    uint256 nightEndTime = 21;
    address feereceiver = 0x110891d31cAc4498F97FFDeD3aE191BeA5252BEf;
    uint16 mintMaxAmount = 100;
    uint16 tokenIdCounter;
    address passEnableAddressList;

    constructor(address passAddress) ERC721('ZONMUSPASS', 'ZMP') {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(FREEZE_ROLE, DEFAULT_ADMIN_ROLE);
        _setDefaultRoyalty(feereceiver, 1000);
        passEnableAddressList = passAddress;
    }

    function setUri(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = uri;
    }

    function firstMint(uint256 endid) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(endid < mintMaxAmount);
        require(endid >= tokenIdCounter);
        for (uint256 i = tokenIdCounter; i <= endid; i++) {
            _safeMint(passaddresslist(passEnableAddressList).getAddress(i), tokenIdCounter++);
        }
    }

    function changeRoyalty(address feeaddress, uint16 feeprice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(feeaddress, feeprice);
    }

    function freezeToken(address holder) public onlyRole(FREEZE_ROLE) {
        isFreezed[holder] = true;
    }

    function checkFreeze(address holder) public view returns(bool) {
        return isFreezed[holder];
    }

    function checkPassEnableAddressList() public view onlyRole(DEFAULT_ADMIN_ROLE) returns(address){
        return passEnableAddressList;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal  {
        require(!isFreezed[from], 'token is freezed');
        super._beforeTokenTransfer(from, to, tokenId,1);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from){
        require(balanceOf(to) == 0);
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from){
        require(balanceOf(to) == 0);
        ERC721.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Royalty, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(AccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) 
        public 
        override
        onlyAllowedOperatorApproval(operator) 
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns(string memory)
    {
        return getURI(tokenId, block.timestamp);
    }

    function getURI(uint256 tokenId, uint256 timestamp)
        public
        view
        returns(string memory)
    {
        uint256 hour = ((timestamp % (60 * 60 * 24)) / (60 * 60));
        if(balanceOf((ownerOf(tokenId))) > 1) {
            return string(abi.encodePacked(baseURI, "x.json"));
        } else if (isFreezed[ownerOf(tokenId)] == true) {
            return string(abi.encodePacked(baseURI, tokenId.toString(), "s.json"));
        } else if(isFreezed[ownerOf(tokenId)] == false && hour < nightStartTime) {
            return string(abi.encodePacked(baseURI, tokenId.toString(), "d.json"));
        } else if(isFreezed[ownerOf(tokenId)] == false && hour >= nightEndTime) {
            return string(abi.encodePacked(baseURI, tokenId.toString(), "d.json"));
        } else if(isFreezed[ownerOf(tokenId)] == false) {
            return string(abi.encodePacked(baseURI, tokenId.toString(), "n.json"));
        } else {
            revert('invalid version');
        }
    }
}