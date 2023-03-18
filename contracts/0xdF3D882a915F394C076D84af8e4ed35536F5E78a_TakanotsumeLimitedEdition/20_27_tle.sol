// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'operator-filter-registry/src/UpdatableOperatorFilterer.sol';
import 'operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol';
import './grave.sol';
import './addresslist.sol';

contract TakanotsumeLimitedEdition is ERC721Enumerable, ERC2981, AccessControl, Ownable, RevokableDefaultOperatorFilterer{

    using Strings for uint256;
    bytes32 CHANGE_ROLE = keccak256('CHANGE_ROLE');

    uint256 tokenIdCounter;
    string baseURI;
    string customURI;
    address graveAddress;
    address listAddress;

    struct mintTermData{
        uint256 mintMaxSupply;
        uint256 mintStartTime;
        uint256 allowListEndTime;
        uint256 freeMintEndTime;
        uint256 mintCounter;
    }
    mapping(uint256 => mintTermData) mintTermDatas;
    uint256 mintTerm;

    mapping(uint256 => uint256) customURIMode;
    mapping(uint256 => bool) customURIEnable;

    constructor(address _graveaddress, address _listaddress) ERC721('TakanotsumeLimitedEdition', 'TLE') {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(CHANGE_ROLE, DEFAULT_ADMIN_ROLE);
        _setDefaultRoyalty(0x3B4a211A88AAc938ee6f050F72987fB16B3eF260, 1000);
        graveAddress = _graveaddress;
        listAddress = _listaddress;
    }

    function changeDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function setMintTerm(uint256 _supply, uint256 _startTime, uint256 _finishALTime, uint256 _finishFreemintTime) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_supply > 0);
        require(_finishALTime > _startTime || _finishFreemintTime > _startTime);
        mintTermDatas[++mintTerm] = mintTermData(_supply, _startTime, _finishALTime, _finishFreemintTime, 0);
    }

    function setOnlyFreemintTerm(uint256 _supply, uint256 _startTime, uint256 _finishTime) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_supply > 0);
        require(_finishTime > _startTime);
        mintTermDatas[++mintTerm] = mintTermData(_supply, _startTime, _startTime, _finishTime, 0);
    }

    function setOnlyALMintTerm(uint256 _supply, uint256 _startTime, uint256 _finishTime) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_supply > 0);
        require(_finishTime > _startTime);
        mintTermDatas[++mintTerm] = mintTermData(_supply, _startTime, _finishTime, _finishTime, 0);
    }

    function changeMintData(uint256 _supply, uint256 _startTime, uint256 _finishALTime, uint256 _finishFreemintTime) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(mintTermDatas[mintTerm].mintCounter <= _supply);
        require(_supply > 0);
        require(_finishALTime > _startTime || _finishFreemintTime > _startTime);
        mintTermDatas[mintTerm].mintMaxSupply = _supply;
        mintTermDatas[mintTerm].mintStartTime = _startTime;
        mintTermDatas[mintTerm].allowListEndTime = _finishALTime;
        mintTermDatas[mintTerm].freeMintEndTime = _finishFreemintTime;
    }

    function singleMint() public {
        require(block.timestamp >= mintTermDatas[mintTerm].mintStartTime);
        require(block.timestamp <= mintTermDatas[mintTerm].allowListEndTime || block.timestamp <= mintTermDatas[mintTerm].freeMintEndTime);
        require(mintTermDatas[mintTerm].mintCounter < mintTermDatas[mintTerm].mintMaxSupply);
        require(GRAVE(graveAddress).checkRecievedNFTValue(msg.sender) / 3 - GRAVE(graveAddress).checkMintedNFTValue(msg.sender) >= 1);
        if(block.timestamp <= mintTermDatas[mintTerm].allowListEndTime) {
            require(AddressList(listAddress).checkRemainAmount(msg.sender) >= 1);
            AddressList(listAddress).useAllowAmount(msg.sender);
        }
        _safeMint(msg.sender, tokenIdCounter++);
        ++mintTermDatas[mintTerm].mintCounter;
        GRAVE(graveAddress).changeMintedValue(msg.sender);
    }

    function ownerMint(address _to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _safeMint(_to, tokenIdCounter++);
    }

    function changeBaseURI(string memory _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _uri;
    }

    function changeCustomURI(string memory _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        customURI = _uri;
    }

    function changeURIMode(uint256 _tokenId, uint256 _uriMode) public onlyRole(CHANGE_ROLE) {
        customURIMode[_tokenId] = _uriMode;
        customURIEnable[_tokenId] = true;
    }

    function changeCustomURIOff(uint256 _tokenId) public onlyRole(CHANGE_ROLE) {
        require(customURIEnable[_tokenId] = true);
        customURIEnable[_tokenId] = false;
    }

    function checkCustomURIMode(uint256 _tokenId) public view returns(uint256) {
        return customURIMode[_tokenId];
    }

    function checkCustomURIEnable(uint256 _tokenId) public view returns(bool) {
        return customURIEnable[_tokenId];
    }

    function changeListAddress(address _listaddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        listAddress = _listaddress;
    }

    function checkMintTerm() public view returns(uint256) {
        return mintTerm;
    }

    function checkMintTermData(uint256 _mintTerm) public view returns(mintTermData memory) {
        return mintTermDatas[_mintTerm];
    }

    function checkListAddress() public view returns(address) {
        return listAddress;
    }

    function checkAllowMintEnable(uint256 _term) public view returns(bool) {
        if(
            block.timestamp >= mintTermDatas[_term].mintStartTime &&
            block.timestamp <= mintTermDatas[_term].allowListEndTime &&
            block.timestamp <= mintTermDatas[_term].freeMintEndTime
        ) {
            return true;
        } else {
            return false;
        }
    }

    function checkFreeMintEnable(uint256 _term) public view returns(bool) {
        if(
            block.timestamp >= mintTermDatas[_term].mintStartTime &&
            block.timestamp >= mintTermDatas[_term].allowListEndTime &&
            block.timestamp <= mintTermDatas[_term].freeMintEndTime
        ) {
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
        if(customURIEnable[_tokenId] == true) {
            return string(abi.encodePacked(customURI, customURIMode[_tokenId].toString(), "/", _tokenId.toString(), ".json"));
        }
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(AccessControl).interfaceId ||
            interfaceId == type(ERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}