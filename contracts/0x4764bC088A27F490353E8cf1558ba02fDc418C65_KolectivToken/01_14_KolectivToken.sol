pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract KolectivToken is ERC721, ERC721Pausable, Ownable {
    event TokenCreated(string uuid, address to);
    event BaseURISet(string uri);

    address public proxyMinter; // only account that can call mintFor()
    string private _baseTokenURI;
    mapping (uint256 => bytes32) private tokenIdToUuid;  // Maps token id to UUID
    mapping (bytes32 => uint256) private uuidToTokenId;  // Maps UUID to token id


    constructor(string memory baseTokenURI) ERC721("Kolectiv", "KOLECTIV") {
        _baseTokenURI = baseTokenURI;
        proxyMinter = _msgSender();
    }

    function createToken(uint256 tokenId, string memory uuid, address to) public onlyOwner {
        bytes32 uuidBytes32 = UUIDStringToBytes32(uuid);
        createTokenWithId(tokenId, uuidBytes32, to);
    }

    function mintFor(address to, uint256 amount, bytes memory mintingBlob) public {
        require(proxyMinter == _msgSender(), "Caller is not the proxy minter.");
        (uint256[] memory tokenIds, bytes32[] memory uuids) = parseMintingBlob(mintingBlob, amount);
        for (uint i; i < tokenIds.length; i++) {
            createTokenWithId(tokenIds[i], uuids[i], to);
        }
    }

    function getTokenIdOfUUID(string memory uuid) public view returns (uint256) {
        bytes32 uuid32 = UUIDStringToBytes32(uuid);
        require(uuidExists(uuid32), "UUID does not exist.");
        return uuidToTokenId[uuid32];
    }

    function getUUIDOfTokenId(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        return bytes32ToUUIDString(tokenIdToUuid[tokenId]);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory uuid = bytes32ToUUIDString(tokenIdToUuid[tokenId]);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, uuid)) : '';
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
        emit BaseURISet(uri);
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function setProxyMinter(address proxy) public onlyOwner {
        proxyMinter = proxy;
    }

    // ------- Internal functions below here:
    function createTokenWithId(uint256 tokenId, bytes32 uuid, address to) internal {
        require(!_exists(tokenId), "Token already exists.");
        _safeMint(to, tokenId);

        uuidToTokenId[uuid] = tokenId;
        tokenIdToUuid[tokenId] = uuid;
        emit TokenCreated(bytes32ToUUIDString(uuid), to);
    }

    // Parses a mintingBlob with {tokenId1}:{uuid1}{tokenId2}:{uuid2} and then returns them
    // Example: {1}:{e9071858-e63b-4f27-92d7-0603235c0b8c}{2}:{f23a1b52-e63b-3f77-42d7-3603235c1b42}
    function parseMintingBlob(bytes memory mintingBlob, uint256 amount) internal pure returns (uint256[] memory, bytes32[] memory) {
        uint256 offset = 0;
        uint256[] memory tokenIds = new uint256[](amount);
        bytes32[] memory uuids = new bytes32[](amount);
        bool isTokenId = true;
        for (uint i; i < mintingBlob.length; i++) {
            if (mintingBlob[i] == "{") {
                if (isTokenId) {
                    (uint256 tokenId, uint256 nextItem) = parseMintingBlobTokenId(mintingBlob, i + 1);
                    tokenIds[offset] = tokenId;
                    isTokenId = false;
                    i = nextItem;
                } else {
                    (bytes32 uuid, uint256 nextItem) = parseMintingBlobUUID(mintingBlob, i + 1);
                    uuids[offset] = uuid;
                    isTokenId = true;
                    offset++;
                    i = nextItem;
                }
            }
        }
        return (tokenIds, uuids);
    }

    function parseMintingBlobTokenId(bytes memory mintingBlob, uint start) internal pure returns (uint256, uint256) {
        uint256 result = 0;
        for (uint256 i = start; i < mintingBlob.length; i++) {
            if (mintingBlob[i] == "}") {
                return (result, i);
            }
            result = (result * 10) + (uint8(mintingBlob[i]) - 48);
        }
        return (result, mintingBlob.length);
    }

    function parseMintingBlobUUID(bytes memory mintingBlob, uint start) internal pure returns (bytes32, uint256) {
        bytes memory temp = new bytes(32);
        bytes32 result;
        uint32 index;
        for (uint i = start; i < mintingBlob.length; i++) {
            if (mintingBlob[i] == "}") {
                assembly {
                    result := mload(add(temp, 32))
                }
                return (result, i);
            }
            if (mintingBlob[i] == "-") {
                continue;
            }
            temp[index] = mintingBlob[i];
            index++;
        }
        assembly {
            result := mload(add(temp, 32))
        }
        return (result, mintingBlob.length);
    }

    function uuidExists(bytes32 uuid) internal view returns (bool) {
        return uuidToTokenId[uuid] != 0;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Converts a bytes32 UUID to a UUID string with dashes
    // e9071858e63b4f2792d70603235c0b8c => e9071858-e63b-4f27-92d7-0603235c0b8c
    function bytes32ToUUIDString(bytes32 b) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(36);
        uint j;
        for (uint256 i; i < 32; i++) {
            bytesArray[j] = b[i];
            // Add back in dashes at correct positions
            if (i == 7 || i == 11 || i == 15 || i == 19) {
                j++;
                bytesArray[j] = "-";
            }
            j++;
        }
        return string(bytesArray);
    }

    // Converts a UUID string with dashes into a bytes32 UUID without dashes
    // e9071858-e63b-4f27-92d7-0603235c0b8c => e9071858e63b4f2792d70603235c0b8c
    function UUIDStringToBytes32(string memory s) internal pure returns (bytes32) {
        bytes memory bytesArray = bytes(s);
        bytes memory noDashes = new bytes(32);
        uint index;
        for (uint256 i; i < bytesArray.length; i++) {
            if (bytesArray[i] == "-") {
                continue;
            }
            noDashes[index] = bytesArray[i];
            index++;
        }
        bytes32 result;
        assembly {
            result := mload(add(noDashes, 32))
        }
        return result;
    }
}