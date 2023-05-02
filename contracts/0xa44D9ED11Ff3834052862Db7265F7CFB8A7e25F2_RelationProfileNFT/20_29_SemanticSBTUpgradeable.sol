// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/ISemanticSBTSchema.sol";
import "../interfaces/ISemanticSBT.sol";
import "../interfaces/IERC5192.sol";
import "./SemanticBaseStruct.sol";
import {SemanticSBTLogicUpgradeable} from "../libraries/SemanticSBTLogicUpgradeable.sol";

contract SemanticSBTUpgradeable is Initializable, OwnableUpgradeable, ERC165Upgradeable, ERC721Upgradeable, IERC721EnumerableUpgradeable, ISemanticSBT, ISemanticSBTSchema, IERC5192 {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for uint160;

    using StringsUpgradeable for address;


    string internal _name;

    string private _symbol;

    SPO[] internal _tokens;

    uint256 private _burnCount;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address => bool) internal _minters;

    bool private _transferable;

    Subject[] internal _subjects;

    mapping(uint256 => mapping(string => uint256)) internal _subjectIndex;

    string internal _baseTokenURI;

    string public schemaURI;


    mapping(string => uint256) internal _classIndex;
    string[] internal _classNames;

    mapping(string => uint256) internal _predicateIndex;
    Predicate[] internal _predicates;


    string[] internal _stringO;
    BlankNodeO[] internal _blankNodeO;

    string  constant SOUL_CLASS_NAME = "Soul";

    event SetMinter(address indexed addr, bool isMinter);

    modifier onlyMinter() {
        require(_minters[msg.sender], "SemanticSBT: must be minter");
        _;
    }

    modifier onlyTransferable() {
        require(_transferable, "SemanticSBT: must transferable");
        _;
    }


    function before_init() internal {
        __Ownable_init();
        SPO memory _spo = SPO(0, 0, new uint256[](0), new uint256[](0));
        Subject memory _subject = Subject("", 0);
        _tokens.push(_spo);
        _subjects.push(_subject);

        _classNames.push("");
        _classNames.push(SOUL_CLASS_NAME);
        _classIndex[SOUL_CLASS_NAME] = 1;
        _predicates.push(Predicate("", FieldType.INT));
    }

    /* ============ External Functions ============ */

    function initialize(
        address minter,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory schemaURI_,
        string[] memory classes_,
        Predicate[] memory predicates_
    ) public virtual initializer {
        require(keccak256(abi.encode(schemaURI_)) != keccak256(abi.encode("")), "SemanticSBT: schema URI cannot be empty");
        require(predicates_.length > 0, "SemanticSBT: predicate size can not be empty");
        before_init();
        _name = name_;
        _symbol = symbol_;
        _minters[minter] = true;
        _baseTokenURI = baseURI_;
        schemaURI = schemaURI_;

        SemanticSBTLogicUpgradeable.addClass(classes_, _classNames, _classIndex);
        SemanticSBTLogicUpgradeable.addPredicate(predicates_, _predicates, _predicateIndex);
        emit SetMinter(minter, true);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721Upgradeable).interfaceId ||
        interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
        interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
        interfaceId == type(ISemanticSBT).interfaceId ||
        interfaceId == type(ISemanticSBTSchema).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function minters(address account) public view returns (bool) {
        return _minters[account];
    }


    function transferable() public view returns (bool) {
        return _transferable;
    }

    function locked(uint256 tokenId) external override view returns (bool){
        if (_transferable) {
            return true;
        }
        return false;
    }

    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }


    function classIndex(string memory className_) public view returns (uint256 classIndex_) {
        classIndex_ = _classIndex[className_];
    }


    function className(uint256 cIndex) public view returns (string memory name_) {
        require(cIndex > 0 && cIndex < _classNames.length, "SemanticSBT: class not exist");
        name_ = _classNames[cIndex];
    }


    function predicateIndex(string memory predicateName_) public view returns (uint256 predicateIndex_) {
        predicateIndex_ = _predicateIndex[predicateName_];
    }


    function predicate(uint256 pIndex) public view returns (string memory name_, FieldType fieldType) {
        require(pIndex > 0 && pIndex < _predicates.length, "SemanticSBT: predicate not exist");

        Predicate memory predicate_ = _predicates[pIndex];
        name_ = predicate_.name;
        fieldType = predicate_.fieldType;
    }


    function subjectIndex(string memory subjectValue, string memory className_) public view returns (uint256){
        uint256 sIndex = _subjectIndex[_classIndex[className_]][subjectValue];
        require(sIndex > 0, "SemanticSBT: does not exist");
        return sIndex;
    }


    function subject(uint256 index) public view returns (string memory subjectValue, string memory className_){
        require(index > 0 && index < _subjects.length, "SemanticSBT: does not exist");
        subjectValue = _subjects[index].value;
        className_ = _classNames[_subjects[index].cIndex];
    }


    function rdfOf(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "SemanticSBT: SemanticSBT does not exist");
        return SemanticSBTLogicUpgradeable.buildRDF(_tokens[tokenId], _classNames, _predicates, _stringO, _subjects, _blankNodeO);
    }

    function getMinted() public view returns (uint256) {
        return _tokens.length - 1;
    }


    function isOwnerOf(address account, uint256 id)
    public
    view
    returns (bool)
    {
        address owner = ownerOf(id);
        return owner == account;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
        bytes(_baseTokenURI).length > 0
        ? string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"))
        : SemanticSBTLogicUpgradeable.getTokenURI(tokenId, _name, rdfOf(tokenId));
    }

    function totalSupply() public view override returns (uint256) {
        return getMinted() - _burnCount;
    }


    function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    returns (uint256)
    {
        uint256 currentIndex = 0;
        for (uint256 i = 1; i < _tokens.length; i++) {
            if (address(_tokens[i].owner) == owner) {
                if (currentIndex == index) {
                    return i;
                }
                currentIndex += 1;
            }
        }
        revert("ERC721Enumerable: owner index out of bounds");
    }


    function tokenByIndex(uint256 index)
    public
    view
    returns (uint256)
    {
        uint256 currentIndex = 0;
        for (uint256 i = 1; i < _tokens.length; i++) {
            if (_tokens[i].owner != 0) {
                if (currentIndex == index) {
                    return i;
                }
                currentIndex += 1;
            }
        }
        revert("ERC721Enumerable: global index out of bounds");
    }


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public onlyTransferable override(IERC721Upgradeable, ERC721Upgradeable) {
        super.transferFrom(from, to, tokenId);
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public onlyTransferable override(IERC721Upgradeable, ERC721Upgradeable) {
        super.safeTransferFrom(from, to, tokenId, "");
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public onlyTransferable override(IERC721Upgradeable, ERC721Upgradeable) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }


    function setURI(string calldata newURI) external onlyOwner {
        _baseTokenURI = newURI;
    }


    function setTransferable(bool transferable_) external onlyOwner {
        _transferable = transferable_;
    }


    function setName(string calldata newName) external virtual onlyOwner {
        _name = newName;
    }


    function setSymbol(string calldata newSymbol) external onlyOwner {
        _symbol = newSymbol;
    }


    function setMinter(address addr, bool _isMinter) external onlyOwner {
        _minters[addr] = _isMinter;
        emit SetMinter(addr, _isMinter);
    }


    /* ============ Internal Functions ============ */

    function _mint(uint256 tokenId, address account, IntPO[] memory intPOList, StringPO[] memory stringPOList,
        AddressPO[] memory addressPOList, SubjectPO[] memory subjectPOList,
        BlankNodePO[] memory blankNodePOList) internal {
        uint256[] storage pIndex = _tokens[tokenId].pIndex;
        uint256[] storage oIndex = _tokens[tokenId].oIndex;

        SemanticSBTLogicUpgradeable.mint(pIndex, oIndex, intPOList, stringPOList, addressPOList, subjectPOList, blankNodePOList, _predicates, _stringO, _subjects, _blankNodeO);
        require(pIndex.length > 0, "SemanticSBT: param error");

        super._safeMint(account, tokenId);
        emit CreateRDF(tokenId, rdfOf(tokenId));
    }

    function _mint(uint256 tokenId, address account, SubjectPO[] memory subjectPOList) internal {
        uint256[] storage pIndex = _tokens[tokenId].pIndex;
        uint256[] storage oIndex = _tokens[tokenId].oIndex;

        SemanticSBTLogicUpgradeable.addSubjectPO(pIndex, oIndex, subjectPOList, _predicates, _subjects);
        require(pIndex.length > 0, "SemanticSBT: param error");

        super._safeMint(account, tokenId);
        emit CreateRDF(tokenId, rdfOf(tokenId));
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        string memory _rdf = rdfOf(tokenId);
        _tokens[tokenId].owner = 0;
        super._burn(tokenId);
        _burnCount++;
        emit RemoveRDF(tokenId, _rdf);
    }

    function _addEmptyToken(address account, uint256 sIndex) internal returns (uint256){
        _tokens.push(SPO(uint160(account), sIndex, new uint256[](0), new uint256[](0)));
        return _tokens.length - 1;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable) virtual {
        _tokens[tokenId].owner = uint160(to);
        super._transfer(from, to, tokenId);
    }

}