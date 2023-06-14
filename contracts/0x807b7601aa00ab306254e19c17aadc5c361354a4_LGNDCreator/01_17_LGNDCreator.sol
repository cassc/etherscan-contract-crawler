// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./access/AdminControl.sol";
import "./core/CreatorCore.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @dev LGNDCreator implementation
 */
contract LGNDCreator is AdminControl, ERC721, CreatorCore {
    address private _proxyRegistryAddress;
    bool private _bridgeEnabled;
    string private _contractURI;

    uint256 private _supply;
    uint256 private _burns;
    uint256 public imports;
    uint256 public exports;

    mapping(address => string) private _linkedAccounts;
    mapping(uint256 => bool) private _creatorBridgeEnabled;

    constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    }

    function setProxy(address proxyRegistryAddress) external adminRequired {
        _proxyRegistryAddress = proxyRegistryAddress;
    }

    function setCreator(uint256 creatorId, address creator) external adminRequired {
        _setCreator(creatorId, creator);
    }

    function setBridge(bool enabled) external adminRequired {
        _bridgeEnabled = enabled;
    }

    function getBridge() public view returns (bool enabled) {
        return _bridgeEnabled;
    }

    function setCreatorBridge(uint256 creatorId, bool enabled) external adminRequired {
        _creatorBridgeEnabled[creatorId] = enabled;
    }

    function getCreatorBridge(uint256 creatorId) public view returns (bool enabled) {
        return _creatorBridgeEnabled[creatorId];
    }

    function getCreator(uint256 creatorId) public view returns (address creator) {
        return _creatorAddresses[creatorId];
    }

    function getTokenCreator(uint256 tokenId) public view returns (address creator) {
        require(_exists(tokenId), "Nonexistent token");
        uint256 creatorId;
        if(tokenId > MAX_TOKEN_ID) {
            creatorId = _creatorTokens[tokenId];
        } else {
            creatorId = tokenId / CREATOR_SCALE;
        }
        return _creatorAddresses[creatorId];
    }

    function setContractURI(string memory uri) external adminRequired {        
        _contractURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setLinkedAccount(string memory account) external {
        _linkedAccounts[msg.sender] = account;
    }

    function getLinkedAccount(address owner) public view returns (string memory account) {
        return _linkedAccounts[owner];
    }

    function totalSupply() public view returns (uint256 supply) {
        return _supply;
    }

    function creatorSupply(uint256 creatorId, uint256 templateId) public view returns (uint256 supply) {
        return _creatorTokenCount[creatorId][templateId];
    }

    function totalBurns() public view returns (uint256 burns) {
        return _burns;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, CreatorCore, AdminControl) returns (bool) {
        return CreatorCore.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }    

    /**
     * @dev See {ICreatorCore-setBaseTokenURICreator}.
     */
    function setBaseTokenURICreator(uint256 creatorId, string calldata uri) external override adminRequired {
        _setBaseTokenURICreator(creatorId, uri);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata uri) external override adminRequired {
        _setBaseTokenURI(uri);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external override adminRequired {
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external override adminRequired {
        require(tokenIds.length == uris.length, "LGNDToken: Invalid input");
        for (uint i = 0; i < tokenIds.length; i++) {
            _setTokenURI(tokenIds[i], uris[i]);            
        }
    }


    function mintCreator(address to, uint256 creatorId, uint256 templateId) external override returns (uint256) {
        return _mintCreator(to,creatorId,templateId,"");
    }
    function mintCreatorURI(address to, uint256 creatorId, uint256 templateId, string calldata uri ) external override returns (uint256) {
        return _mintCreator(to,creatorId,templateId,uri);
    }
    function mintBridge(address to, uint256 creatorId, uint256 tokenId, string calldata linkedAccount) external override returns (uint256) {
        return _mintBridge(to, creatorId, tokenId, linkedAccount, "");
    }
    function mintBridgeURI(address to, uint256 creatorId, uint256 tokenId, string calldata linkedAccount, string calldata uri) external override returns (uint256) {
        return _mintBridge(to, creatorId, tokenId, linkedAccount, uri);
    }

    function mintCreatorBatch(address to, uint256 creatorId, uint256 templateId, uint256 count) external override returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            tokenIds[i] = _mintCreator(to,creatorId,templateId,"");
        }
        return tokenIds;
    }
    function mintCreatorBatchURI(address to, uint256 creatorId, uint256 templateId, string[] calldata uris) external override returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](uris.length);
        for (uint256 i = 0; i < uris.length; i++) {
            tokenIds[i] = _mintCreator(to,creatorId,templateId,uris[i]);
        }
        return tokenIds;
    }
    function mintBridgeBatch(address to, uint256 creatorId, uint256[] memory tokenIds, string calldata linkedAccount) external override returns (uint256[] memory) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mintBridge(to,creatorId,tokenIds[i],linkedAccount,"");
        }
        return tokenIds;

    }
    function mintBridgeBatchURI(address to, uint256 creatorId, uint256[] memory tokenIds, string calldata linkedAccount, string[] calldata uris) external override returns (uint256[] memory) {
        require(tokenIds.length == uris.length, "LGNDToken: Invalid Input");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mintBridge(to,creatorId,tokenIds[i],linkedAccount,uris[i]);
        }
        return tokenIds;
    }

    /**
     * @dev Mint token
     */
    function _mintCreator(address to, uint256 creatorId, uint256 templateId, string memory uri) internal virtual returns(uint256 tokenId) {
        require(_creatorAddresses[creatorId] == msg.sender, "LGNDToken: Must be creator");
        require(templateId <= MAX_TEMPLATE_ID, "LGNDToken: templateId exceeds maximum");

        uint256 mintId = _creatorTokenCount[creatorId][templateId] + 1;
        require(mintId <= MAX_MINT_ID, "LGNDToken: no remaining mints available");
        _creatorTokenCount[creatorId][templateId] = mintId;

        tokenId = (creatorId * CREATOR_SCALE) + (templateId * TEMPLATE_SCALE) + mintId;

        _supply++;
        _safeMint(to, tokenId);

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }

        return tokenId;
    }

    /**
     * @dev Mint token
     */
    function _mintBridge(address to, uint256 creatorId, uint256 tokenId, string memory linkedAccount, string memory uri) internal virtual returns(uint256) {
        require(_creatorAddresses[creatorId] == msg.sender, "LGNDToken: Must be creator");
        require(!_exists(tokenId), "Pre-existing token");

        _supply++;
        _safeMint(to, tokenId);

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }

        emit ImportedToken(to, imports++, tokenId, linkedAccount);

        return tokenId;
    }

    /**
     * @dev See {IERC721CreatorCore-burn}.
     */
    function burn(uint256 tokenId) external override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "LGNDToken: caller is not owner nor approved");
        address owner = ERC721.ownerOf(tokenId);
        require(bytes(_linkedAccounts[owner]).length != 0, "LGNDToken: Must link account with setLinkedAccount");

        if(tokenId > MAX_TOKEN_ID) {
            require(_bridgeEnabled, "LGNDToken: Bridge has not been enabled for this token");            
            // Delete token origin extension tracking
            delete _creatorTokens[tokenId]; 
        } else {
            require(_creatorBridgeEnabled[tokenId / CREATOR_SCALE], "LGNDToken: Bridge has not been enabled for this token");
        }

        _burns++;
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }    

        emit ExportedToken(owner, exports++, tokenId, _linkedAccounts[owner]);

        _burn(tokenId);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesCreator(0, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        require(_exists(tokenId), "Nonexistent token");
        _setRoyalties(tokenId, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyaltiesExtension}.
     */
    function setRoyaltiesCreator(uint256 creatorId, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesCreator(creatorId, receivers, basisPoints);
    }

    /**
     * @dev {See ICreatorCore-getRoyalties}.
     */
    function getRoyalties(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyalties(tokenId);
    }

    /**
     * @dev {See ICreatorCore-getFees}.
     */
    function getFees(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyalties(tokenId);
    }

    /**
     * @dev {See ICreatorCore-getFeeRecipients}.
     */
    function getFeeRecipients(uint256 tokenId) external view virtual override returns (address payable[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyReceivers(tokenId);
    }

    /**
     * @dev {See ICreatorCore-getFeeBps}.
     */
    function getFeeBps(uint256 tokenId) external view virtual override returns (uint[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyBPS(tokenId);
    }
    
    /**
     * @dev {See ICreatorCore-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 value, bytes calldata) external view virtual override returns (address, uint256, bytes memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyInfo(tokenId, value);
    } 

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _tokenURI(tokenId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        if(_proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }
    
}