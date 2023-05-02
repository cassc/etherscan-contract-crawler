// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import '@openzeppelin/contracts/utils/Base64.sol';
import "../core/SemanticBaseStruct.sol";

library SemanticSBTLogicUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for uint160;
    using StringsUpgradeable for address;


    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    struct SemanticStorage {
        string[] _classNames;
        Predicate[] _predicates;
        string[] _stringO;
        Subject[] _subjects;
        BlankNodeO[] _blankNodeO;
    }

    string  constant TURTLE_LINE_SUFFIX = ";";
    string  constant TURTLE_END_SUFFIX = " . ";
    string  constant SOUL_CLASS_NAME = "Soul";

    string  constant public ENTITY_PREFIX = ":";
    string  constant public PROPERTY_PREFIX = "p:";

    string  constant CONCATENATION_CHARACTER = "_";
    string  constant BLANK_NODE_START_CHARACTER = "[";
    string  constant BLANK_NODE_END_CHARACTER = "]";
    string  constant BLANK_SPACE = " ";

    bytes32 internal constant EIP712_REVISION_HASH = keccak256('1');
    bytes32 internal constant EIP712_DOMAIN_TYPE_HASH = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');


    function addClass(string[] calldata classList, string[] storage _classNames, mapping(string => uint256) storage _classIndex) external {
        uint256 len = classList.length;
        for (uint256 i; i < len;) {
            string memory className_ = classList[i];
            require(
                keccak256(abi.encode(className_)) != keccak256(abi.encode("")),
                "SemanticSBT: Class cannot be empty"
            );
            require(_classIndex[className_] == 0, "SemanticSBT: class already added");
            _classNames.push(className_);
            _classIndex[className_] = _classNames.length - 1;
            unchecked{
                ++i;
            }
        }
    }


    function addPredicate(Predicate[] calldata predicates, Predicate[] storage _predicates, mapping(string => uint256) storage _predicateIndex) external {
        uint256 len = predicates.length;
        for (uint256 i; i < len; ) {
            Predicate memory predicate_ = predicates[i];
            require(
                keccak256(abi.encode(predicate_.name)) !=
                keccak256(abi.encode("")),
                "SemanticSBT: Predicate cannot be empty"
            );
            require(_predicateIndex[predicate_.name] == 0, "SemanticSBT: predicate already added");
            _predicates.push(predicate_);
            _predicateIndex[predicate_.name] = _predicates.length - 1;
            unchecked{
                ++i;
            }
        }
    }


    function addSubject(string calldata value, string calldata className_,
        Subject[] storage _subjects,
        mapping(uint256 => mapping(string => uint256)) storage _subjectIndex,
        mapping(string => uint256) storage _classIndex) external returns (uint256 sIndex) {
        uint256 cIndex = _classIndex[className_];
        require(cIndex > 0, "SemanticSBT: param error");
        require(_subjectIndex[cIndex][value] == 0, "SemanticSBT: subject already added");
        sIndex = _addSubject(value, cIndex, _subjects, _subjectIndex);
    }

    function mint(uint256[] storage pIndex, uint256[] storage oIndex,
        IntPO[] memory intPOList, StringPO[] memory stringPOList, AddressPO[] memory addressPOList, SubjectPO[] memory subjectPOList,
        BlankNodePO[] memory blankNodePOList, Predicate[] storage _predicates, string[] storage _stringO, Subject[] storage _subjects, BlankNodeO[] storage _blankNodeO) external {

        addIntPO(pIndex, oIndex, intPOList, _predicates);
        addStringPO(pIndex, oIndex, stringPOList, _predicates, _stringO);
        addAddressPO(pIndex, oIndex, addressPOList, _predicates);
        addSubjectPO(pIndex, oIndex, subjectPOList, _predicates, _subjects);
        addBlankNodePO(pIndex, oIndex, blankNodePOList, _predicates, _stringO, _subjects, _blankNodeO);

    }


    function addIntPO(uint256[] storage pIndex, uint256[] storage oIndex, IntPO[] memory intPOList, Predicate[] storage _predicates) internal {
        uint256 len = intPOList.length;
        for (uint256 i; i < len; ) {
            IntPO memory intPO = intPOList[i];
            checkPredicate(intPO.pIndex, FieldType.INT, _predicates);
            pIndex.push(intPO.pIndex);
            oIndex.push(intPO.o);
            unchecked{
                ++i;
            }
        }
    }

    function addStringPO(uint256[] storage pIndex, uint256[] storage oIndex, StringPO[] memory stringPOList, Predicate[] storage _predicates, string[] storage _stringO) internal {
        uint256 len = stringPOList.length;
        for (uint256 i; i < len; ) {
            StringPO memory stringPO = stringPOList[i];
            checkPredicate(stringPO.pIndex, FieldType.STRING, _predicates);
            uint256 _oIndex = _stringO.length;
            _stringO.push(stringPO.o);
            pIndex.push(stringPO.pIndex);
            oIndex.push(_oIndex);
            unchecked{
                ++i;
            }
        }
    }

    function addAddressPO(uint256[] storage pIndex, uint256[] storage oIndex, AddressPO[] memory addressPOList, Predicate[] storage _predicates) internal {
        uint256 len = addressPOList.length;
        for (uint256 i; i < len;) {
            AddressPO memory addressPO = addressPOList[i];
            checkPredicate(addressPO.pIndex, FieldType.ADDRESS, _predicates);
            pIndex.push(addressPO.pIndex);
            oIndex.push(uint160(addressPO.o));
            unchecked{
                ++i;
            }
        }
    }

    function addSubjectPO(uint256[] storage pIndex, uint256[] storage oIndex, SubjectPO[] memory subjectPOList, Predicate[] storage _predicates, Subject[] storage _subjects) internal {
        uint256 len = subjectPOList.length;
        for (uint256 i; i < len;) {
            SubjectPO memory subjectPO = subjectPOList[i];
            checkPredicate(subjectPO.pIndex, FieldType.SUBJECT, _predicates);
            require(subjectPO.oIndex > 0 && subjectPO.oIndex < _subjects.length, "SemanticSBT: subject not exist");
            pIndex.push(subjectPO.pIndex);
            oIndex.push(subjectPO.oIndex);
            unchecked{
                ++i;
            }
        }
    }

    function addBlankNodePO(uint256[] storage pIndex, uint256[] storage oIndex, BlankNodePO[] memory blankNodePOList, Predicate[] storage _predicates, string[] storage _stringO, Subject[] storage _subjects, BlankNodeO[] storage _blankNodeO) internal {
        uint256 len = blankNodePOList.length;
        for (uint256 i; i < len;) {
            BlankNodePO memory blankNodePO = blankNodePOList[i];
            require(blankNodePO.pIndex < _predicates.length, "SemanticSBT: predicate not exist");

            uint256 _blankNodeOIndex = _blankNodeO.length;
            _blankNodeO.push(BlankNodeO(new uint256[](0), new uint256[](0)));
            uint256[] storage blankNodePIndex = _blankNodeO[_blankNodeOIndex].pIndex;
            uint256[] storage blankNodeOIndex = _blankNodeO[_blankNodeOIndex].oIndex;

            addIntPO(blankNodePIndex, blankNodeOIndex, blankNodePO.intO, _predicates);
            addStringPO(blankNodePIndex, blankNodeOIndex, blankNodePO.stringO, _predicates, _stringO);
            addAddressPO(blankNodePIndex, blankNodeOIndex, blankNodePO.addressO, _predicates);
            addSubjectPO(blankNodePIndex, blankNodeOIndex, blankNodePO.subjectO, _predicates, _subjects);

            pIndex.push(blankNodePO.pIndex);
            oIndex.push(_blankNodeOIndex);
            unchecked{
                ++i;
            }
        }
    }



    function buildRDF(SPO storage spo, string[] storage _classNames, Predicate[] storage _predicates, string[] storage _stringO, Subject[] storage _subjects, BlankNodeO[] storage _blankNodeO) external view returns (string memory _rdf){
        _rdf = buildS(spo, _classNames, _subjects);

        uint256 len = spo.pIndex.length;
        for (uint256 i; i < len;) {
            uint256 pIndex = spo.pIndex[i];
            uint256 oIndex = spo.oIndex[i];
            FieldType fieldType = _predicates[pIndex].fieldType;
            if (FieldType.INT == fieldType) {
                _rdf = string.concat(_rdf, buildIntRDF(oIndex, _predicates[pIndex].name));
            } else if (FieldType.STRING == fieldType) {
                _rdf = string.concat(_rdf, buildStringRDF(_predicates[pIndex].name, _stringO[oIndex]));
            } else if (FieldType.ADDRESS == fieldType) {
                _rdf = string.concat(_rdf, buildAddressRDF(oIndex, _predicates[pIndex].name));
            } else if (FieldType.SUBJECT == fieldType) {
                _rdf = string.concat(_rdf, buildSubjectRDF(_classNames[_subjects[oIndex].cIndex], _predicates[pIndex].name, _subjects[oIndex].value));
            } else if (FieldType.BLANKNODE == fieldType) {
                _rdf = string.concat(_rdf, buildBlankNodeRDF(pIndex, oIndex, _classNames, _predicates, _stringO, _subjects, _blankNodeO));
            }
            string memory suffix = i == len - 1 ? TURTLE_END_SUFFIX : TURTLE_LINE_SUFFIX;
            _rdf = string.concat(_rdf, suffix);
            unchecked{
                ++i;
            }
        }
    }

    function buildS(SPO storage spo, string[] storage _classNames, Subject[] storage _subjects) public view returns (string memory){
        uint256 sIndex = spo.sIndex;
        string memory _className = sIndex == 0 ? SOUL_CLASS_NAME : _classNames[_subjects[sIndex].cIndex];
        string memory subjectValue = sIndex == 0 ? address(spo.owner).toHexString() : _subjects[sIndex].value;
        return string.concat(ENTITY_PREFIX, _className, CONCATENATION_CHARACTER, subjectValue, BLANK_SPACE);
    }

    function buildIntRDF(uint256 oIndex, string storage name) internal view returns (string memory){
        string memory p = string.concat(PROPERTY_PREFIX, name);
        string memory o = oIndex.toString();
        return string.concat(p, BLANK_SPACE, o);
    }

    function buildStringRDF(string storage name, string storage _stringO) internal view returns (string memory){
        string memory p = string.concat(PROPERTY_PREFIX, name);
        string memory o = string.concat('"', _stringO, '"');
        return string.concat(p, BLANK_SPACE, o);
    }

    function buildAddressRDF(uint256 oIndex, string storage name) internal view returns (string memory){
        string memory p = string.concat(PROPERTY_PREFIX, name);
        string memory o = string.concat(ENTITY_PREFIX, SOUL_CLASS_NAME, CONCATENATION_CHARACTER, address(uint160(oIndex)).toHexString());
        return string.concat(p, BLANK_SPACE, o);
    }


    function buildSubjectRDF(string storage _className, string storage name, string storage value) internal view returns (string memory){
        string memory p = string.concat(PROPERTY_PREFIX, name);
        string memory o = string.concat(ENTITY_PREFIX, _className, CONCATENATION_CHARACTER, value);
        return string.concat(p, BLANK_SPACE, o);
    }


    function buildBlankNodeRDF(uint256 pIndex, uint256 oIndex, string[] storage _classNames, Predicate[] storage _predicates, string[] storage _stringO, Subject[] storage _subjects, BlankNodeO[] storage _blankNodeO) internal view returns (string memory){
        string memory p = string.concat(PROPERTY_PREFIX, _predicates[pIndex].name);

        uint256[] memory blankPList = _blankNodeO[oIndex].pIndex;
        uint256[] memory blankOList = _blankNodeO[oIndex].oIndex;

        string memory _rdf = "";
        for (uint256 i; i < blankPList.length;) {
            FieldType fieldType = _predicates[blankPList[i]].fieldType;
            if (FieldType.INT == fieldType) {
                _rdf = string.concat(_rdf, buildIntRDF(blankOList[i], _predicates[blankPList[i]].name));
            } else if (FieldType.STRING == fieldType) {
                _rdf = string.concat(_rdf, buildStringRDF(_predicates[blankPList[i]].name, _stringO[blankOList[i]]));
            } else if (FieldType.ADDRESS == fieldType) {
                _rdf = string.concat(_rdf, buildAddressRDF(blankOList[i], _predicates[blankPList[i]].name));
            } else if (FieldType.SUBJECT == fieldType) {
                _rdf = string.concat(_rdf, buildSubjectRDF(_classNames[_subjects[blankOList[i]].cIndex], _predicates[blankPList[i]].name, _subjects[blankOList[i]].value));
            }
            if (i < blankPList.length - 1) {
                _rdf = string.concat(_rdf, TURTLE_LINE_SUFFIX);
            }
            unchecked{
                ++i;
            }
        }

        return string.concat(p, BLANK_SPACE, BLANK_NODE_START_CHARACTER, _rdf, BLANK_NODE_END_CHARACTER);
    }

    function buildStringRDFCustom(string calldata class, string calldata entityValue, string calldata predicate, string calldata o) external pure returns (string memory){
        string memory s = string.concat(ENTITY_PREFIX, class, CONCATENATION_CHARACTER, entityValue, BLANK_SPACE);
        string memory p = string.concat(PROPERTY_PREFIX, predicate, BLANK_SPACE);
        return string.concat(s, p, o, TURTLE_END_SUFFIX);
    }

    function getTokenURI(
        uint256 id,
        string memory description,
        string memory rdf
    ) external pure returns (string memory) {
        return
        string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        id.toString(),
                        '","description":"',
                        description,
                        '","image":"data:image/svg+xml;base64,',
                        _getSVGImageBase64Encoded(getText(10, 150, rdf)),
                        '"}'
                    )
                )
            )
        );
    }


    function _getSVGImageBase64Encoded(string memory text)
    internal
    pure
    returns (string memory)
    {
        return
        Base64.encode(
            abi.encodePacked(
                '<svg  class="icon" viewBox="0 0 1200 450" version="1.1" xmlns="http://www.w3.org/2000/svg" width="1200" height="450" fill="white" > <rect xmlns="http://www.w3.org/2000/svg" x="0" width="1200" height="450" fill="white"/>',
                text,
                '</svg>'
            )
        );
    }


    function getText(uint256 x, uint256 y, string memory content) public pure returns (string memory){
        return string.concat(
            '<text x="',
            x.toString(),
            '" y="',
            y.toString(),
            '" fill="black" font-size="20" >',
            content,
            '</text>');
    }


    function recoverSignerFromSignature(string calldata name, address contractAddress, bytes32 hashedMessage, address expectedAddress, Signature calldata sig) external view returns (address){
        require(sig.deadline > block.timestamp, "SemanticSBT: signature expired");
        address signer = ecrecover(_calculateDigest(name, contractAddress, hashedMessage),
            sig.v,
            sig.r,
            sig.s);
        require(expectedAddress == signer, "SemanticSBT: signature invalid");
        return signer;
    }


    function _calculateDigest(string memory name, address contractAddress, bytes32 hashedMessage) internal view returns (bytes32) {
        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked('\x19\x01', _calculateDomainSeparator(name, contractAddress), hashedMessage)
            );
        }
        return digest;
    }

    function _calculateDomainSeparator(string memory name, address contractAddress) internal view returns (bytes32){
        return
        keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPE_HASH,
                keccak256(bytes(name)),
                EIP712_REVISION_HASH,
                block.chainid,
                contractAddress
            )
        );
    }


    function checkPredicate(uint256 pIndex, FieldType fieldType, Predicate[] storage _predicates) public view {
        require(pIndex > 0 && pIndex < _predicates.length, "SemanticSBT: predicate not exist");
        require(_predicates[pIndex].fieldType == fieldType, "SemanticSBT: predicate type error");
    }


    function _addSubject(string memory value, uint256 cIndex,
        Subject[] storage _subjects,
        mapping(uint256 => mapping(string => uint256)) storage _subjectIndex) public returns (uint256 sIndex){
        sIndex = _subjects.length;
        _subjectIndex[cIndex][value] = sIndex;
        _subjects.push(Subject(value, cIndex));
    }
}