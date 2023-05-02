// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "../core/SemanticSBTUpgradeable.sol";
import "../interfaces/social/INameService.sol";
import {SemanticSBTLogicUpgradeable} from "../libraries/SemanticSBTLogicUpgradeable.sol";
import {NameServiceLogic} from "../libraries/NameServiceLogic.sol";


contract NameService is INameService, SemanticSBTUpgradeable {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;

    uint256 internal constant PROFILE_URI_PREDICATE_INDEX = 3;

    uint256 internal constant NAME_CLASS_INDEX = 2;


    string public suffix;


    mapping(address => uint256) internal _ownedResolvedName;
    mapping(uint256 => address) internal _ownerOfResolvedName;

    mapping(address => string) internal _profileURI;
    mapping(address => bool) internal _ownedProfileURI;

    function initialize(
        string memory suffix_,
        string memory name_,
        string memory symbol_,
        string memory schemaURI_,
        string[] memory classes_,
        Predicate[] memory predicates_
    ) public virtual initializer {
        super.initialize(msg.sender, name_, symbol_, "", schemaURI_, classes_, predicates_);
        suffix = suffix_;
    }


    function register(address owner, string calldata name, bool resolve) external virtual override returns (uint tokenId) {
        return _register(owner, name, resolve);
    }


    /**
     * To set a record for resolving the name, linking the name to an address.
     * @param addr_ : The owner of the name. If the address is zero address, then the link is canceled.
     * @param name : The name.
     */
    function setNameForAddr(address addr_, string calldata name) external override {
        require(addr_ == msg.sender || addr_ == address(0), "NameService:can not set for others");
        uint256 sIndex = _subjectIndex[NAME_CLASS_INDEX][name];
        uint256 tokenId = sIndex;
        require(ownerOf(tokenId) == msg.sender, "NameService:not the owner");
        SPO storage spo = _tokens[tokenId];
        NameServiceLogic.setNameForAddr(addr_, sIndex,
            _ownedResolvedName,
            _ownerOfResolvedName);
        NameServiceLogic.updatePIndexOfToken(addr_, spo);
        emit UpdateRDF(tokenId, rdfOf(tokenId));
    }

    function setProfileURI(string calldata profileURI_) external {
        _profileURI[msg.sender] = profileURI_;
        string memory rdf = SemanticSBTLogicUpgradeable.buildStringRDFCustom(SOUL_CLASS_NAME, msg.sender.toHexString(), _predicates[PROFILE_URI_PREDICATE_INDEX].name, string.concat('"', profileURI_, '"'));
        if (!_ownedProfileURI[msg.sender]) {
            _ownedProfileURI[msg.sender] = true;
            emit CreateRDF(0, rdf);
        } else {
            emit UpdateRDF(0, rdf);
        }
    }



    function addr(string calldata name) virtual override external view returns (address){
        uint256 sIndex = _subjectIndex[NAME_CLASS_INDEX][name];
        return _ownerOfResolvedName[sIndex];
    }


    function nameOf(address addr_) external view returns (string memory){
        if (addr_ == address(0)) {
            return "";
        }
        uint256 sIndex = _ownedResolvedName[addr_];
        return _subjects[sIndex].value;
    }

    function nameOfTokenId(uint256 tokenId) external view returns (string memory){
        return _subjects[tokenId].value;
    }

    function profileURI(address addr_) external view returns (string memory){
        return _profileURI[addr_];
    }

    function tokenURI(uint256 tokenId)
    public
    virtual
    view
    override(SemanticSBTUpgradeable)
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
        bytes(_baseTokenURI).length > 0
        ? string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"))
        : NameServiceLogic.getTokenURI(tokenId, _subjects[tokenId].value, rdfOf(tokenId));
    }

    function ownerOfName(string calldata name) external view returns (address){
        uint256 sIndex = _subjectIndex[NAME_CLASS_INDEX][name];
        return ownerOf(sIndex);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(SemanticSBTUpgradeable) returns (bool) {
        return interfaceId == type(INameService).interfaceId ||
        super.supportsInterface(interfaceId);
    }


    function _register(address owner, string calldata name, bool resolve) internal returns (uint tokenId) {
        string memory fullName = string.concat(name, suffix);
        require(_subjectIndex[NAME_CLASS_INDEX][fullName] == 0, "NameService: already added");
        tokenId = _addEmptyToken(owner, 0);
        uint256 sIndex = SemanticSBTLogicUpgradeable._addSubject(fullName, NAME_CLASS_INDEX, _subjects, _subjectIndex);
        SubjectPO[] memory subjectPOList = NameServiceLogic.register(msg.sender, owner, sIndex, resolve,
            _ownedResolvedName, _ownerOfResolvedName
        );
        _mint(tokenId, owner,  subjectPOList);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable) virtual {
        require(from == address(0) || _ownerOfResolvedName[firstTokenId] == address(0), "NameService:can not transfer when resolved");
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable) virtual {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
        if (from != address(0)) {
            emit UpdateRDF(firstTokenId, rdfOf(firstTokenId));
        }
    }


}