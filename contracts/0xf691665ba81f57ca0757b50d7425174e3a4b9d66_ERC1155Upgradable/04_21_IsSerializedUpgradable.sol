// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;
import "./HasRegistration.sol";

contract IsSerializedUpgradable is HasRegistration {
    bool internal serialized;
    bool internal hasSerialized;
    bool internal overloadSerial;
    uint256 serialCount;
    mapping(uint256 => uint256[]) internal tokenIdToSerials;
    mapping(uint256 => uint256) internal serialToTokenId;
    mapping(uint256 => address) internal serialToOwner;
    // mapping(address => uint256) public ownerSerialCount;

    function isSerialized() public view returns (bool) {
        return serialized;
    }

    function isOverloadSerial() public view returns (bool) {
        return overloadSerial;
    }

    function toggleSerialization() public onlyOwner {
        require(!hasSerialized, "Already has serialized items");
        serialized = !serialized;
    }

    function toggleOverloadSerial() public onlyOwner {
        overloadSerial = !overloadSerial;
    }

    function mintSerial(uint256 tokenId, address _owner) internal onlyOwner {
        uint256 serialNumber = uint256(keccak256(abi.encode(tokenId, _owner, serialCount)));
        _mintSerial(serialNumber, _owner, tokenId);
    }

    function mintSerial(uint256 serialNumber, address _owner, uint256 tokenId) internal onlyOwner {
        _mintSerial(serialNumber, _owner, tokenId);
    }

    function _mintSerial(uint256 serialNumber, address _owner, uint256 tokenId)internal onlyOwner {
        require(serialToTokenId[serialNumber] == 0 && serialToOwner[serialNumber] == address(0), "Serial number already used");
        tokenIdToSerials[tokenId].push(serialNumber);
        serialToTokenId[serialNumber] = tokenId;
        serialToOwner[serialNumber] = _owner;
        // ownerSerialCount[_owner]++;
        // if (!hasSerialized) {
        //     hasSerialized = true;
        // }
        hasSerialized = true;
        serialCount++;
    }

    function transferSerial(uint256 serialNumber, address from, address to) internal {
        require(serialToOwner[serialNumber] == from, 'Not correct owner of serialnumber');
        serialToOwner[serialNumber] = to;
        // ownerSerialCount[to]++;
        // ownerSerialCount[from]--;
        // if (to == address(0)) {
        // serialToTokenId[serialNumber] = 0;
        //     uint256 tokenId = serialToTokenId[serialNumber];
        //     serialToTokenId[serialNumber] = 0;
        //     for(uint i=0; i<tokenIdToSerials[tokenId].length; i++) {
        //         if (tokenIdToSerials[tokenId][i] == serialNumber) {
        //             tokenIdToSerials[tokenId][i] = tokenIdToSerials[tokenId][tokenIdToSerials[tokenId].length - 1];
        //             tokenIdToSerials[tokenId].pop();
        //         }
        //     }
        // }
    }

function burnSerial(uint256 serialNumber) internal {
    uint256 tokenId = serialToTokenId[serialNumber];
    // serialToTokenId[serialNumber] = 0;
    serialToOwner[serialNumber] = address(0);
    // serialCount--;
    for(uint i=0; i<tokenIdToSerials[tokenId].length; i++) {
        if (tokenIdToSerials[tokenId][i] == serialNumber) {
            tokenIdToSerials[tokenId][i] = tokenIdToSerials[tokenId][tokenIdToSerials[tokenId].length - 1];
            tokenIdToSerials[tokenId].pop();
        }
    }
}


    function getSerial(uint256 tokenId, uint256 index) public view returns (uint256) {
        if(tokenIdToSerials[tokenId].length == 0) {
            return 0;
        } else {
            return tokenIdToSerials[tokenId][index];
        }
    }

    function getFirstSerialByOwner(address _owner, uint256 tokenId) public view returns (uint256) {
        for (uint256 i = 0; i < tokenIdToSerials[tokenId].length; ++i) {
           uint256 serialNumber = tokenIdToSerials[tokenId][i];
           if (serialToOwner[serialNumber] == _owner) {
               return serialNumber;
           }
        }
        return 0;
    }

    function getSerialByOwnerAtIndex(address _owner, uint256 tokenId, uint256 index) public view returns (uint256) {
        uint seen = 0;
        for (uint256 i = 0; i < tokenIdToSerials[tokenId].length; ++i) {
            uint256 serialNumber = tokenIdToSerials[tokenId][i];
            if (serialToOwner[serialNumber] == _owner) {
                if (seen == index) {
                    return serialNumber;
                } else {
                    seen++;
                }
            }
        }
        return 0;
    }

    function getOwnerOfSerial(uint256 serialNumber) public view returns (address) {
        return serialToOwner[serialNumber];
    }

    function getTokenIdForSerialNumber(uint256 serialNumber) public view returns (uint256) {
        return serialToTokenId[serialNumber];
    }

    function decodeUintArray(bytes memory encoded) internal pure returns(uint256[] memory ids){
        ids = abi.decode(encoded, (uint256[]));
    }

    function decodeSingle(bytes memory encoded) internal pure returns(uint256 id) {
        id = abi.decode(encoded, (uint));
    }
}