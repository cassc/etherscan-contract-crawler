// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract ZONMUS is ERC721Enumerable, ERC721Royalty, AccessControl, DefaultOperatorFilterer {
    using Strings for uint256;

    bytes32 CHANGE_ROLE = keccak256('CHANGE_ROLE');
    bytes32 MINT_ROLE = keccak256('MINT_ROLE');
    bytes32 ITEM_MINTER_ROLE = keccak256('ITEM_MINTER_ROLE');

    uint256 tokenIdCounter;

    struct seasonMintData {
        string seasonBaseURI;
        uint256 seasonMaxSupply;
        uint256 seasonTokenCounter;
        uint256 seasonMintStartTime;
        uint256 seasonMintFinishTime;
    }
    mapping(uint256 => seasonMintData) public seasonMintDatas;
    uint256 public seasonCounter;

    struct zonmusData {
        uint256 tokenSeason;
        uint256 evoMode;
        uint256 zonMode;
        uint256 experientPoint;
        uint256 timeCount;
        uint256 evolutionCount;
        uint256 itemFoundTime;
    }
    mapping(uint256 => zonmusData) public zonmusDatas;

    mapping(uint256 => uint256) public zonDexCounter;
    mapping(uint256 => mapping(uint256 => address)) public zonDexByEvoMode;
    mapping(address => mapping(uint256 => bool)) public zonDexByAddress;

    constructor() ERC721('ZONMUS', 'ZMS') {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(CHANGE_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MINT_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ITEM_MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setDefaultRoyalty(msg.sender, 1000);
    }

    function setNewSeason(uint256 _maxsupply, string memory _uri, uint256 _starttime, uint256 _finishtime) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_starttime < _finishtime);
        require(_maxsupply >= 1);
        seasonMintDatas[++seasonCounter] = seasonMintData(
            _uri,
            _maxsupply,
            0,
            _starttime,
            _finishtime
        );
    }

    function changeURI(uint256 _season, string memory _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        seasonMintDatas[_season].seasonBaseURI = _uri;
    }

    function changeRoyalty(address _to, uint96 _fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(_to, _fee);
    }

    function changeEvoMode(uint256 _tokenId, uint256 _evonum) public onlyRole(CHANGE_ROLE) {
        zonmusDatas[_tokenId] = zonmusData(
            zonmusDatas[_tokenId].tokenSeason,
            _evonum,
            0,
            0,
            block.timestamp,
            zonmusDatas[_tokenId].evolutionCount++,
            block.timestamp
        );
        zonDexByEvoMode[_evonum][++zonDexCounter[_evonum]] = this.ownerOf(_tokenId);
        zonDexByAddress[this.ownerOf(_tokenId)][_evonum] = true;
    }

    function itemFound(uint256 _tokenId) public onlyRole(ITEM_MINTER_ROLE) {
        zonmusDatas[_tokenId].itemFoundTime = block.timestamp;
    }

    function batchItemFound(uint256[] memory _tokenIds) public onlyRole(ITEM_MINTER_ROLE) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            zonmusDatas[_tokenIds[i]].itemFoundTime = block.timestamp;
        }
    }

    function changeZonMode(uint256 _tokenId, uint256 _modenum) public onlyRole(CHANGE_ROLE) {
        zonmusDatas[_tokenId].zonMode = _modenum;
    }

    function firstReveal(uint256 _tokenId, uint256 _evonum) public onlyRole(CHANGE_ROLE) {
        zonmusDatas[_tokenId].evoMode = _evonum;
        zonmusDatas[_tokenId].itemFoundTime = block.timestamp - (60 * 60 * 24);
        zonmusDatas[_tokenId].evolutionCount++;
        zonDexByEvoMode[_evonum][++zonDexCounter[_evonum]] = this.ownerOf(_tokenId);
        zonDexByAddress[this.ownerOf(_tokenId)][_evonum] = true;
    }

    function addExperientPoint(uint256 _tokenId, uint256 _epValue) public onlyRole(CHANGE_ROLE) {
        zonmusDatas[_tokenId].experientPoint += _epValue;
    }

    function batchAddExperientPoint(uint256[] memory _tokenIds, uint256 _epValue) public onlyRole(ITEM_MINTER_ROLE) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            zonmusDatas[_tokenIds[i]].experientPoint += _epValue;
        }
    }

    function remainingCheck(uint256 _season) public view returns(uint256) {
        uint256 remainingAmount = seasonMintDatas[_season].seasonMaxSupply - seasonMintDatas[_season].seasonTokenCounter;
        return remainingAmount;
    }
    
    function evomodeOfOwnerByIndex(address _holder, uint256 _index) public view returns(uint256) {
        return zonmusDatas[tokenOfOwnerByIndex(_holder, _index)].evoMode;
    }

    function singleMint(uint256 _season, address _to, uint256 _evomode) public onlyRole(MINT_ROLE) {
        require(seasonMintDatas[_season].seasonTokenCounter < seasonMintDatas[_season].seasonMaxSupply);
        require(block.timestamp >= seasonMintDatas[_season].seasonMintStartTime);
        require(block.timestamp <= seasonMintDatas[_season].seasonMintFinishTime);
        zonmusDatas[tokenIdCounter] = zonmusData(
            _season,
            _evomode,
            0,
            0,
            block.timestamp,
            0,
            block.timestamp
        );
        _safeMint(_to, tokenIdCounter++);
        seasonMintDatas[_season].seasonTokenCounter++;
        zonDexByEvoMode[_evomode][++zonDexCounter[_evomode]] = _to;
        zonDexByAddress[_to][_evomode] = true;
    }

    function multiMint(uint256 _season, address _to, uint256 _times, uint256 _evomode) public onlyRole(MINT_ROLE) {
        require((seasonMintDatas[_season].seasonTokenCounter + _times) <= seasonMintDatas[_season].seasonMaxSupply, "SUPPLY IS FULL");
        require(block.timestamp >= seasonMintDatas[_season].seasonMintStartTime, "before mint start time");
        require(block.timestamp <= seasonMintDatas[_season].seasonMintFinishTime, "after mint finish time");
        for(uint256 i = 0; i < _times; i++) {
            zonmusDatas[tokenIdCounter] = zonmusData(
                _season,
                _evomode,
                0,
                0,
                block.timestamp,
                0,
                block.timestamp
            );
            _safeMint(_to, tokenIdCounter++);
        }
        seasonMintDatas[_season].seasonTokenCounter += _times;
        zonDexByEvoMode[_evomode][++zonDexCounter[_evomode]] = _to;
        zonDexByAddress[_to][_evomode] = true;
    }

    function checkZonmusData(uint256 _tokenId) public view returns(zonmusData memory) {
        return zonmusDatas[_tokenId];
    }

    function checkSeasonMintData(uint256 _season) public view returns(seasonMintData memory) {
        return seasonMintDatas[_season];
    }

    function transferEnable(uint256 tokenId) public view returns(bool) {
        uint256 _spentTime = block.timestamp - zonmusDatas[tokenId].timeCount;
        uint256 _requirementTime = 60 * 60 * 12;
        if (_spentTime >= _requirementTime) {
            return true;
        } else {
            return false;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns(string memory)
    {
        return getURI(tokenId);
    }
    
    function getURI(uint256 _tokenId)
        public
        view
        returns(string memory)
    {
        return string(abi.encodePacked(seasonMintDatas[zonmusDatas[_tokenId].tokenSeason].seasonBaseURI, zonmusDatas[_tokenId].zonMode.toString(), "/", zonmusDatas[_tokenId].evoMode.toString(), ".json"));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721Royalty, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(AccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721Royalty)
    {
        super._burn(tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        require(transferEnable(tokenId) == true);
        super.transferFrom(from, to, tokenId);
        zonmusDatas[tokenId].experientPoint++;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        require(transferEnable(tokenId) == true);
        super.safeTransferFrom(from, to, tokenId);
        zonmusDatas[tokenId].experientPoint++;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        require(transferEnable(tokenId) == true);
        super.safeTransferFrom(from, to, tokenId, data);
        zonmusDatas[tokenId].experientPoint++;
    }

}