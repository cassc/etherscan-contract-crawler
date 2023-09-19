/**
 *Submitted for verification at Etherscan.io on 2023-09-05
*/

pragma solidity 0.8.7;

interface WnsRegistryInterface {
    function owner() external view returns (address);
    function getWnsAddress(string memory _label) external view returns (address);
    function getRecord(uint256 _tokenId) external view returns (string memory);
    function getRecord(bytes32 _hash) external view returns (uint256);

}

pragma solidity 0.8.7;

interface WnsERC721Interface {
    function ownerOf(uint256 tokenId) external view returns (address);
}

pragma solidity 0.8.7;

interface WnsRegistrarInterface {
    function computeNamehash(string memory _name) external view returns (bytes32);
    function recoverSigner(bytes32 message, bytes memory sig) external view returns (address);
}

pragma solidity 0.8.7;

interface WnsOldResolverInterface {
    function resolveAddress(address _address) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract wnsResolverV2 {
 
    address private WnsRegistry;
    WnsRegistryInterface wnsRegistry;
    WnsOldResolverInterface wnsOldResolver = WnsOldResolverInterface(0xf56D46948ab9F850F0CdAd3D394C2751214f555F);

    constructor(address registry_) {
        WnsRegistry = registry_;
        wnsRegistry = WnsRegistryInterface(WnsRegistry);
    }

    function setRegistry(address _registry) public {
        require(msg.sender == wnsRegistry.owner(), "Not authorized.");
        WnsRegistry = _registry;
        wnsRegistry = WnsRegistryInterface(WnsRegistry);
    }

    //Primary names mapping
    mapping(address => uint256) private _primaryNames;
    mapping(uint256 => mapping(string => string)) private _txtRecords;
    
    event PrimaryNameSet(address indexed address_, uint256 indexed tokenId);

    function setPrimaryName(address _address, uint256 _tokenID) public {
        WnsERC721Interface wnsErc721 = WnsERC721Interface(wnsRegistry.getWnsAddress("_wnsErc721"));
        require((wnsErc721.ownerOf(_tokenID) == msg.sender && _address == msg.sender) || msg.sender == wnsRegistry.getWnsAddress("_wnsMigration"), "Not owned by caller.");
        _primaryNames[_address] = _tokenID + 1;
        emit PrimaryNameSet(_address, _tokenID);
    }

    function resolveAddress(address _address) public view returns (string memory) {
        uint256 _tokenId = _primaryNames[_address];

        if(_tokenId == 0) {
            (bool success, bytes memory result) = address(wnsOldResolver).staticcall(
                abi.encodeWithSignature("resolveAddress(address)", _address)
            );

            if (success) {
                string memory domain = abi.decode(result, (string));
                string memory name = extractSubdomain(domain);
                uint256 newTokenId = resolveNameToTokenId(name, "");
                WnsERC721Interface wnsErc721 = WnsERC721Interface(wnsRegistry.getWnsAddress("_wnsErc721"));
                require(wnsErc721.ownerOf(newTokenId) == _address, "Primary Name not set for the address.");
                return wnsRegistry.getRecord(newTokenId);
            } else {
                revert("Primary Name not set for the address.");
            }
        } else {
            WnsERC721Interface wnsErc721 = WnsERC721Interface(wnsRegistry.getWnsAddress("_wnsErc721"));
            require(wnsErc721.ownerOf(_tokenId - 1) == _address, "Primary Name not set for the address.");
            return wnsRegistry.getRecord(_tokenId - 1);
        }
    }

    function extractSubdomain(string memory domain) public pure returns (string memory) {
        bytes memory domainBytes = bytes(domain);
        uint256 pos = 0;
        for (uint256 i = 0; i < domainBytes.length; i++) {
            if (domainBytes[i] == ".") {
                pos = i;
                break;
            }
        }
        
        bytes memory resultBytes = new bytes(pos);
        for (uint256 i = 0; i < pos; i++) {
            resultBytes[i] = domainBytes[i];
        }
        
        return string(resultBytes);
    }

    function resolveName(string memory _name, string memory _extension) public view returns (address) {
        WnsERC721Interface wnsErc721 = WnsERC721Interface(wnsRegistry.getWnsAddress("_wnsErc721"));
        WnsRegistrarInterface wnsRegistrar = WnsRegistrarInterface(wnsRegistry.getWnsAddress("_wnsRegistrar"));
        bytes32 _hash = wnsRegistrar.computeNamehash(_name);
        uint256 _preTokenId = wnsRegistry.getRecord(_hash);
        require(_preTokenId != 0, "Name doesn't exist.");
        return wnsErc721.ownerOf(_preTokenId - 1);
    }

    function resolveTokenId(uint256 _tokenId) public view returns (string memory) {
        return wnsRegistry.getRecord(_tokenId);
    }

    function resolveNameToTokenId(string memory _name, string memory _extension) public view returns (uint256) {
        WnsRegistrarInterface wnsRegistrar = WnsRegistrarInterface(wnsRegistry.getWnsAddress("_wnsRegistrar"));
        bytes32 _hash = wnsRegistrar.computeNamehash(_name);
        uint256 _preTokenId = wnsRegistry.getRecord(_hash);
        require(_preTokenId != 0, "Name doesn't exist.");
        return _preTokenId - 1;
    }

    function setTxtRecords(string[] memory labels, string[] memory records, uint256 tokenId, bytes memory sig) public {
        WnsERC721Interface wnsErc721 = WnsERC721Interface(wnsRegistry.getWnsAddress("_wnsErc721"));
        WnsRegistrarInterface wnsRegistrar = WnsRegistrarInterface(wnsRegistry.getWnsAddress("_wnsRegistrar"));
        require(msg.sender == wnsErc721.ownerOf(tokenId), "Caller is not the Owner.");
        require(labels.length == records.length, "Invalid parameters.");
        bytes32 message = keccak256(abi.encode(labels, records, tokenId));
        require(wnsRegistrar.recoverSigner(message, sig) == wnsRegistry.getWnsAddress("_wnsSigner"), "Not authorized.");
        for(uint256 i; i<labels.length; i++) {
            string memory currentRecord = _txtRecords[tokenId][labels[i]];
            if (keccak256(bytes(currentRecord)) != keccak256(bytes(records[i]))) {
                _txtRecords[tokenId][labels[i]] = records[i];
            }
        }
    }

    function getTxtRecords(uint256 tokenId, string memory label) public view returns (string memory) {
        return _txtRecords[tokenId][label];
    }
}