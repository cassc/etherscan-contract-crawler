// SPDX-License-Identifier: AGPL-3.0
// ©2023 Ponderware Ltd

pragma solidity ^0.8.17;

import "./lib/LawlessGIF.sol";
import "../lib/TokenizedContract.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IDelegationRegistry {
    function checkDelegateForContract(address delegate, address vault, address contract_) external view returns(bool);
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId) external view returns (bool);

}

interface ICustomAttributes {
    function getCustomAttributes () external view returns (bytes memory);
}

interface ILawlessMetadata {
    function generateTokenURI (LawlessData memory) external view returns (string memory);
    function setB64EncodeURI (bool value) external;
    function addMetadataMod (address addr) external;
}

type Ex is uint256;

struct Record {
    address owner;
    uint16 index;
    uint16 version;
    uint16 style;
    uint48 details;
}

struct LawlessData {
    uint id;
    uint modelId;
    uint paletteId;
    address owner;
    uint16 version;
    uint48 details;
}

/*
 * @title Lawless
 * @author Ponderware Ltd
 * @notice chain-complete ERC-721 character contract
 */
contract Lawless is TokenizedContract, LawlessGIF {

    string public name = "lawless";
    string public symbol = unicode"🏴";

    constructor (uint256 tokenId) TokenizedContract(tokenId) {
        addRole(owner(), Role.Uploader);
        addRole(owner(), Role.Curator);
        addRole(owner(), Role.Pauser);
        addRole(0xEBFEFB02CaD474D35CabADEbddF0b32D287BE1bd, Role.CodeLawless);
    }

    /* Events */

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /* Supply */

    uint256 internal constant maxSupply = 8192;
    uint256 internal constant maxSupplyMod = 8191;
    uint256 public totalSupply = 0;

    /* Bookkeeping Data */

    Record[maxSupply] internal Records;
    mapping (address => uint16[maxSupply+1]) internal TokensByOwner; // index 0 is "length"

    modifier validLawlessId (uint id) {
        require(id < totalSupply, "unrecognized lawless");
        _;
    }

    /* Delegation */

    IDelegationRegistry constant dc = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    bool public delegationEnabled = true;

    function smashFlask () public onlyBy(Role.Ponderware) {
        delegationEnabled = false;
    }

    /* Data */

    function uploadModels (uint48 count, bytes memory data) public onlyBy(Role.Uploader) {
        _uploadModels(count, data);
    }

    function uploadPalettes (uint48 count, bytes memory data) public onlyBy(Role.Uploader) {
        _uploadPalettes(count, data);
    }

    /* Metadata */

    ILawlessMetadata Metadata;

    function setMetadata (bytes calldata metadata) public onlyBy(Role.Curator) {
        removeRole(address(Metadata), Role.Metadata);
        Metadata = ILawlessMetadata(Create2.deploy(0, 0, abi.encodePacked(metadata, abi.encode(address(this), CodexAddress))));
        addRole(address(Metadata), Role.Metadata);
    }

    function setB64EncodeURI (bool value) public onlyBy(Role.Curator) {
        Metadata.setB64EncodeURI(value);
    }

    function addMetadataMod (address addr) public onlyBy(Role.Curator) {
        Metadata.addMetadataMod(addr);
    }

    function getModel (uint id) public view onlyBy(Role.Metadata) returns (Model memory) {
        return _getModel(id);
    }

    function getPalette (uint id) public view onlyBy(Role.Metadata) returns (bytes memory) {
        return _getPalette(id);
    }

    function staticGIF (Model memory model, bytes memory palette) public view onlyBy(Role.Metadata) returns (string memory) {
        return _staticGIF(model, palette);
    }

    function animatedGIF (Model memory model, bytes memory palette) public view onlyBy(Role.Metadata) returns (string memory) {
        return _animatedGIF(model, palette);
    }

    function getModelAndPaletteIds (uint style) internal pure returns (uint, uint) {
        return (style >> 5, style & 31);
    }

    function getData (uint id) public view validLawlessId(id) returns (LawlessData memory) {
        Record storage record = Records[id];
        (uint modelId, uint paletteId) = getModelAndPaletteIds(record.style);
        return LawlessData(id, modelId, paletteId, record.owner, record.version, record.details);
    }

    /* Token URI */

    function tokenURI (Ex tokenId) public view returns (string memory) {
        uint id = Ex.unwrap(tokenId) & maxSupplyMod;
        require (Ex.unwrap(tokenId) == (id + Records[id].version * maxSupply), "invalid tokenId");
        return Metadata.generateTokenURI(getData(id));
    }

    /* View Helpers */

    function getTokenId (uint256 id) external view validLawlessId(id) returns (uint) {
        return id + Records[id].version * maxSupply;
    }

    function getLawlessId (Ex tokenId) external view returns (uint id) {
        id = Ex.unwrap(tokenId) & maxSupplyMod;
        require (id < totalSupply && Ex.unwrap(tokenId) == (id + Records[id].version * maxSupply), "invalid tokenId");
    }

    /* Immutable lawless GIF lookups */

    function lawlessGIF (uint256 id, bool base) public view validLawlessId(id) returns (string memory) {
        Record storage record = Records[id];
        (uint modelId, uint paletteId) = getModelAndPaletteIds(record.style);
        uint details = record.details;
        if (!base) {
            uint morph = details >> 24;
            if ((morph & 1024) > 0) {
                modelId = 256 + (morph & 1023);
            }
            uint shift = details >> 12;
            if ((shift & 1024) > 0) {
                paletteId = 32 + (shift & 1023);
            }
        }
        if (details >= 211106232532992 || modelId > 255) {
            return _animatedGIF(_getModel(modelId), _getPalette(paletteId));
        } else {
            return _staticGIF(_getModel(modelId), _getPalette(paletteId));
        }
    }

    function tokenGIF (Ex tokenId, bool base) external view returns (string memory) {
        uint id = Ex.unwrap(tokenId) & maxSupplyMod;
        require (Ex.unwrap(tokenId) == (id + Records[id].version * maxSupply), "invalid tokenId");
        return lawlessGIF(id, base);
    }

    /* Details */

    function _updateId (uint id, address owner) internal {
        uint currentVersion = Records[id].version++;
        uint currentExternalId = id + (currentVersion * totalSupply);
        uint nextExternalId = currentExternalId + maxSupply;
        emit Transfer(owner, address(0), currentExternalId);
        emit Transfer(address(0), owner, nextExternalId);
    }

    function _authorized (uint id, address owner, address operator) internal view returns (bool) {
        return (operator == CodexAddress
                || operator == owner
                || TokenApprovals[id] == operator
                || isApprovedForAll(owner, operator)
                || (delegationEnabled
                    && (dc.checkDelegateForContract(operator, owner, address(this))
                        || dc.checkDelegateForToken(operator, owner, address(this), id))));

    }

    function getDetails (Ex tokenId) external view returns (uint, address, uint48) {
        uint id = Ex.unwrap(tokenId) & maxSupplyMod;
        Record storage record = Records[id];
        require (id < totalSupply && Ex.unwrap(tokenId) == (id + record.version * maxSupply), "invalid tokenId");
        return (id, record.owner, record.details);
    }

    function authorized (address operator, Ex tokenId) external view returns (bool) {
        uint id = Ex.unwrap(tokenId) & maxSupplyMod;
        Record storage record = Records[id];
        require (id < totalSupply && Ex.unwrap(tokenId) == (id + record.version * maxSupply), "invalid tokenId");
        return _authorized(id, record.owner, operator);
    }

    function incrementVersion (address operator, uint id) external validLawlessId(id) onlyBy(Role.Surgeon) {
        Record storage record = Records[id];
        require(_authorized(id, record.owner, operator), "unauthorized");
        _updateId(id, record.owner);
    }

    function updateDetails (address operator, uint id, uint48 details, bool incVersion) external validLawlessId(id) onlyBy(Role.Surgeon) {
        Record storage record = Records[id];
        require(_authorized(id, record.owner, operator), "unauthorized");
        record.details = details;
        if (incVersion) _updateId(id, record.owner);
    }

    /* Minting */

    function handleMint (bytes32 seed, address to, uint48 details) internal {
        uint index = (uint256(seed) % (maxSupply - totalSupply)) + totalSupply;
        Record storage atCursor = Records[totalSupply];
        Record storage atIndex = Records[index];
        uint16 atIndexStyle = atIndex.style;
        if (atCursor.owner == address(0)) {
            atIndex.style = uint16(totalSupply);
        } else {
            atIndex.style = atCursor.style;
        }
        if (atIndex.owner == address(0)) {
            atCursor.style = uint16(index);
        } else {
            atCursor.style = atIndexStyle;
        }

        atIndex.owner = to; // used to check if value has been seen
        atCursor.owner = to;
        atCursor.details = details;

        uint16 setIndex = TokensByOwner[to][0]++;
        atCursor.index = setIndex;
        TokensByOwner[to][setIndex + 1] = uint16(totalSupply);
        emit Transfer(address(0), to, totalSupply);
        totalSupply++;
    }

    function mint (uint256 seed, address to, uint48 details) public onlyBy(Role.Minter) {
        require (totalSupply < maxSupply, "rescue complete");
        handleMint(keccak256(abi.encodePacked(to, seed, totalSupply)), to, details);
    }

    function batchMint (uint256 seed, address[] calldata to, uint48[] calldata details) public onlyBy(Role.Minter) {
        require ((totalSupply + to.length) <= maxSupply, "insufficient supply");
        for (uint i = 0; i < to.length; i++) {
            handleMint(keccak256(abi.encodePacked(to[i], seed, totalSupply, i)), to[i], details[i]);
        }
    }

    /* ERC-165 */

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {

        if (msg.sender == CodexAddress) { // workaround for ERC721 custom metadata
            return
                interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
                interfaceId == type(ICustomAttributes).interfaceId;
        } else {
            return
                interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
                interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
                interfaceId == 0x780E9D63 || // ERC165 Interface ID for ERC721Enumerable
                interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
                interfaceId == 0x2A55205A || // ERC165 Interface ID for ERC2981
                interfaceId == type(ICustomAttributes).interfaceId;
        }
    }

    /* Custom Attributes */

    function getCustomAttributes () external view returns (bytes memory) {
        string memory mintedPct = toPctString1000x(totalSupply * 1000 / maxSupply);
        return abi.encodePacked(ICodex(CodexAddress).encodeStringAttribute("token type", "ERC-721"),
                                ",",
                                ICodex(CodexAddress).encodeNumericAttribute("total supply", totalSupply),
                                ",",
                                ICodex(CodexAddress).encodeStringAttribute("minted", mintedPct));
    }

    /* ERC-721 Base */

    // Mapping from token ID to approved address
    address[maxSupply] private TokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private OperatorApprovals;

    function _transfer (address from, address to, Ex tokenId) private whenNotPaused {
        uint id = Ex.unwrap(tokenId) & maxSupplyMod;  // don't need to check if id < totalSupply because Records lookup will fail
        TokenApprovals[id] = address(0); // Clear approvals from the previous owner
        Record storage record = Records[id];
        require(record.owner == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(Ex.unwrap(tokenId) == (id + (record.version * maxSupply)), "ERC721: Nonexistent token");
        uint16 valueIndex = record.index + 1;
        uint16 lastIndex = TokensByOwner[from][0]--;
        if (lastIndex != valueIndex) {
            uint16 lastId = TokensByOwner[from][lastIndex];
            TokensByOwner[from][valueIndex] = lastId;
            Records[lastId].index = valueIndex - 1;
        }
        TokensByOwner[from][lastIndex] = 0;
        uint16 newOwnerIndex = ++TokensByOwner[to][0];
        record.index = newOwnerIndex - 1;
        TokensByOwner[to][newOwnerIndex] = uint16(id);
        record.owner = to;
        emit Transfer(from, to, Ex.unwrap(tokenId));
    }

    function tokenExists (Ex tokenId) external view returns (bool exists) {
        uint id = Ex.unwrap(tokenId) & maxSupplyMod;
        Record storage record = Records[id];
        return (id < totalSupply && Ex.unwrap(tokenId) == (id + record.version * maxSupply));
    }

    function _ownerOf (Ex tokenId) internal view returns (address, uint) {
        uint id = Ex.unwrap(tokenId) & maxSupplyMod;
        Record storage record = Records[id];
        require (id < totalSupply && Ex.unwrap(tokenId) == (id + record.version * maxSupply), "invalid tokenId");
        return (record.owner, id);
    }

    function ownerOf (Ex tokenId) external view returns (address owner) {
        (owner,) = _ownerOf(tokenId);
    }

    function balanceOf (address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return TokensByOwner[owner][0];
    }

    function approve (address to, Ex tokenId) external  {
        (address owner, uint id) = _ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
                "ERC721: approve caller is not owner nor approved for all");
        TokenApprovals[id] = to;
        emit Approval(owner, to, Ex.unwrap(tokenId));
    }

    function getApproved (Ex tokenId) external view returns (address) {
        uint id = Ex.unwrap(tokenId) & maxSupplyMod;
        require(id < totalSupply
                &&
                (Ex.unwrap(tokenId) == id + maxSupply * Records[id].version),
                "No such token");
        return TokenApprovals[id];
    }

    function isApprovedForAll (address owner, address operator) public view returns (bool) {
        return OperatorApprovals[owner][operator];
    }

    function setApprovalForAll (address operator, bool approved) external {
        require(msg.sender != operator, "ERC721: approve to caller");
        OperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function _isApprovedOrOwner (address spender, Ex tokenId) internal view returns (bool) {
        (address owner, uint id) = _ownerOf(tokenId);
        return (spender == owner || TokenApprovals[id] == spender || isApprovedForAll(owner, spender));
    }

    function _checkOnERC721Received(address from, address to, Ex tokenId, bytes memory _data) private returns (bool) {
        uint256 size;
        assembly { size := extcodesize(to) }
        if (size > 0) { // checking for contract
            try IERC721Receiver(to).onERC721Received(msg.sender, from, Ex.unwrap(tokenId), _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly { revert(add(32, reason), mload(reason)) }
                }
            }
        } else {
            return true;
        }
    }

    function _safeTransfer (address from, address to, Ex tokenId, bytes memory _data) private {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function transferFrom (address from, address to, Ex tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom (address from, address to, Ex tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom (address from, address to, Ex tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /* ERC-721 Enumerable */

    function tokenByIndex (uint256 index) external view returns (uint256) {
        require (index < totalSupply, "ERC721Enumerable: ?? LOOKUP");
        return(index + Records[index].version * maxSupply);
    }

    function tokenOfOwnerByIndex (address owner, uint256 index) external view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        uint id = TokensByOwner[owner][index + 1];
        return(id + Records[id].version * maxSupply);
    }

    /* Royalty Bullshit */

    function royaltyInfo (uint256 /*tokenId*/, uint256 /*salePrice8*/) external view returns (address, uint256) {
        return (owner(), 0);
    }

    /* Util */

    bytes10 private constant _SYMBOLS = "0123456789";
    function toPctString1000x (uint256 value) public pure returns (string memory pct) {
        //Adapted From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
        uint256 length = 1;
        uint256 v = value;
        bytes memory buffer;
        unchecked {
            if (v >= 100) {
                v /= 100;
                length += 2;
            }
            if (v >= 10) {
                length += 1;
            }
            buffer = new bytes(length);
            uint256 ptr;
            assembly {
            ptr := add(buffer, add(32, length))
                    }
            while (true) {
                ptr--;
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                        }
                value /= 10;
                if (value == 0) break;
            }
        }
        if (length == 1) {
            pct = string(abi.encodePacked("0.", buffer, "%"));
        } else if (length == 2) {
            pct = string(abi.encodePacked(buffer[0], ".", buffer[1], "%"));
        } else if (length == 3) {
            pct = string(abi.encodePacked(buffer[0], buffer[1], ".", buffer[2], "%"));
        } else {
            pct = "100%";
        }
    }
}