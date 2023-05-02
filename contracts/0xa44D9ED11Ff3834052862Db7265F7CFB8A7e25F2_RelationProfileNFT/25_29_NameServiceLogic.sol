// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../core/SemanticBaseStruct.sol";
import '@openzeppelin/contracts/utils/Base64.sol';
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {StringUtils} from "./StringUtils.sol";


library NameServiceLogic {
    using StringUtils for *;
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;
    using ECDSA for bytes;
    using ECDSA for bytes32;

    uint256 constant HOLD_PREDICATE_INDEX = 1;
    uint256 constant RESOLVE_PREDICATE_INDEX = 2;
    string constant DESCRIPTION = "Name Service";
    string constant BACK_IMG = "";


    function register(address caller, address owner, uint256 sIndex, bool resolve,
        mapping(address => uint256) storage _ownedResolvedName,
        mapping(uint256 => address) storage _ownerOfResolvedName) external returns (SubjectPO[] memory) {
        SubjectPO[] memory subjectPOList = new SubjectPO[](1);
        if (resolve) {
            require(caller == owner, "NameService:can not set for others");
            setNameForAddr(owner, sIndex,
                _ownedResolvedName,
                _ownerOfResolvedName);
            subjectPOList[0] = SubjectPO(RESOLVE_PREDICATE_INDEX, sIndex);
        } else {
            subjectPOList[0] = SubjectPO(HOLD_PREDICATE_INDEX, sIndex);
        }
        return subjectPOList;
    }


    /**
     * To set a record for resolving the name, linking the name to an address.
     * @param addr : The owner of the name. If the address is zero address, then the link is canceled.
     */
    function setNameForAddr(address addr, uint256 dSIndex,
        mapping(address => uint256) storage _ownedResolvedName,
        mapping(uint256 => address) storage _ownerOfResolvedName) public {
        if (addr != address(0)) {
            require(_ownerOfResolvedName[dSIndex] == address(0), "NameService:already resolved");
            if (_ownedResolvedName[addr] != 0) {
                delete _ownerOfResolvedName[_ownedResolvedName[addr]];
            }
        } else {
            require(_ownerOfResolvedName[dSIndex] != address(0), "NameService:not resolved");
            delete _ownedResolvedName[_ownerOfResolvedName[dSIndex]];
        }
        _ownedResolvedName[addr] = dSIndex;
        _ownerOfResolvedName[dSIndex] = addr;
    }

    function updatePIndexOfToken(address addr, SPO storage spo) public {
        if (addr == address(0)) {
            spo.pIndex[0] = HOLD_PREDICATE_INDEX;
        } else {
            spo.pIndex[0] = RESOLVE_PREDICATE_INDEX;
        }
    }


    function checkValidLength(string memory name,
        uint256 _minNameLength,
        uint256 _maxNameLength,
        mapping(uint256 => uint256) storage _nameLengthControl,
        mapping(uint256 => uint256) storage _countOfNameLength) external view returns (bool){
        uint256 len = name.strlen();
        if (len < _minNameLength) {
            return false;
        }
        if (_maxNameLength > 0 && len > _maxNameLength) {
            return false;
        }
        if (_nameLengthControl[len] == 0) {
            return true;
        } else if (_nameLengthControl[len] - _countOfNameLength[len] > 0) {
            return true;
        }
        return false;
    }

    function isZeroWidth(string memory name) external pure returns (bool) {
        bytes memory nb = bytes(name);
        // zero width for /u200b /u200c /u200d and U+FEFF
        for (uint256 i; i < nb.length - 2; i++) {
            if (bytes1(nb[i]) == 0xe2 && bytes1(nb[i + 1]) == 0x80) {
                if (bytes1(nb[i + 2]) == 0x8b || bytes1(nb[i + 2]) == 0x8c || bytes1(nb[i + 2]) == 0x8d) {
                    return true;
                }
            } else if (bytes1(nb[i]) == 0xef) {
                if (bytes1(nb[i + 1]) == 0xbb && bytes1(nb[i + 2]) == 0xbf) return true;
            }
        }
        return false;
    }


    function getTokenURI(
        uint256 id,
        string calldata name,
        string calldata rdf
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
                        DESCRIPTION,
                        '","image":"data:image/svg+xml;base64,',
                        _getSVGImageBase64Encoded(name),
                        '","attributes":[{"trait_type":"id","value":"#',
                        id.toString(),
                        '"},{"trait_type":"semantic_rdf","value":"',
                        rdf,
                        '"}]}'
                    )
                )
            )
        );
    }


    function recoverAddress(address contractAddress, address caller, string calldata name, uint256 deadline, uint256 _mintCount, uint256 price, bytes memory signature) external view returns (address) {
        require(deadline > block.timestamp, "NameService:signature expired");
        bytes32 hash = keccak256(
            abi.encodePacked(
                contractAddress,
                caller,
                deadline,
                _mintCount,
                price,
                name
            )
        ).toEthSignedMessageHash();
        return hash.recover(signature);
    }


    function _getSVGImageBase64Encoded(string memory name)
    internal
    pure
    returns (string memory)
    {
        return
        Base64.encode(
            abi.encodePacked(
                '<svg  class="icon" viewBox="0 0 512 512" version="1.1" xmlns="http://www.w3.org/2000/svg" width="512" height="512" fill="white" > <defs> <pattern id="backImg" patternUnits="userSpaceOnUse" x="0" y="0" width="512" height="512"> <image width="512" height="512" preserveAspectRatio="none" href="',
                BACK_IMG,
                '"/> </pattern></defs><rect xmlns="http://www.w3.org/2000/svg" id="default-picture-background" x="0" width="512" height="512" fill="url(#backImg)"/> <text x="40" y="450" fill="#FF4F99" font-size="28" >',
                name,
                '</text></svg>'
            )
        );
    }

}