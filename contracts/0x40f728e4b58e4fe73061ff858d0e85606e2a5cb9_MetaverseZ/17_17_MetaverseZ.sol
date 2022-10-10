// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";

contract MetaverseZ is AccessControlEnumerable, ERC1155Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public uriPrefix;
    string public uriSuffix = ".json";
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => bool) private _tokenIds;

    modifier onlyMinterRole {
        require(hasRole(MINTER_ROLE, _msgSender()), "MetaverseZToken: must have minter role");
        _;
    }

    modifier onlyAdminRole {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MetaverseZToken: must have admin role");
        _;
    }

    constructor(string memory prefix) ERC1155("") {
        uriPrefix = prefix;
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];
        string memory baseURI = bytes(tokenURI).length > 0 ? tokenURI : Strings.toString(tokenId);
        return string(abi.encodePacked(uriPrefix, baseURI, uriSuffix));
    }

    function mint(address to, uint256 id, uint256 amount) public virtual onlyMinterRole {
        require(!_tokenIds[id], "MetaverseZToken: token id already exists!");
        _mint(to, id, amount, "");
        _tokenIds[id] = true;
    }

    function mintExisting(address to, uint256 id, uint256 amount) public virtual onlyMinterRole {
        require(_tokenIds[id], "MetaverseZToken: token id does not exist!");
        _mint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public virtual onlyMinterRole {
        for (uint256 i = 0; i < ids.length; i++) {
            require(!_tokenIds[ids[i]], "MetaverseZToken: token id already exists!");
        }
        _mintBatch(to, ids, amounts, "");
        for (uint256 i = 0; i < ids.length; i++) {
            _tokenIds[ids[i]] = true;
        }
    }

    function mintBatchExisting(address to, uint256[] memory ids, uint256[] memory amounts) public virtual onlyMinterRole {
        for (uint256 i = 0; i < ids.length; i++) {
            require(_tokenIds[ids[i]], "MetaverseZToken: token id does not exist!");
        }
        _mintBatch(to, ids, amounts, "");
    }

    function setUriPrefix(string memory prefix) public virtual onlyAdminRole {
        uriPrefix = prefix;
    }

    function setUriSuffix(string memory suffix) public virtual onlyAdminRole {
        uriSuffix = suffix;
    }

    function setURI(uint256 tokenId, string memory tokenURI) public virtual onlyAdminRole {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    function pause() public virtual onlyAdminRole {
        _pause();
    }

    function unpause() public virtual onlyAdminRole {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}