// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./SparseERC721/SparseERC721Enumerable.sol";
import "./IERC2981.sol";

/**
 * @title Cendrillon
 */
contract Cendrillon is SparseERC721Enumerable, AccessControlEnumerable, IERC2981 {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant INFINITIZER_ROLE = keccak256("INFINITIZER_ROLE");

    string private __baseURI; // Token base URI

    string public contractURI; // OpenSea contract-level metadata uri

    uint24 royalty = 10;    // Royalty expected by the artist on secondary transfers (IERC2981)

    mapping(uint256 => string) tokenIdToIpfsCID;                 // Each minted token can be infinitized to IPFS

    constructor(string memory name, string memory symbol, string memory baseTokenURI, address _proxyRegistryAddress) SparseERC721(name, symbol) {

        __baseURI = baseTokenURI;
        proxyRegistryAddress = _proxyRegistryAddress;

        // Grant owner a reasonable set of roles by default
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(INFINITIZER_ROLE, msg.sender);

    }

    function onlyAdmin() private view {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must have admin role");
    }

    //
    // ERC165 interface implementation
    //

    function supportsInterface(bytes4 interfaceId) public view override(SparseERC721Enumerable, AccessControlEnumerable) returns (bool) {
        return SparseERC721Enumerable.supportsInterface(interfaceId)
            || AccessControlEnumerable.supportsInterface(interfaceId)
            || interfaceId == type(IERC2981).interfaceId;
    }

    // 
    // ERC721 functions
    //

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function mint(address to, uint256 tokenId) public {
        Cendrillon.mint(to, tokenId, "");
    }

    function mint(address to, uint256 tokenId, bytes memory _data) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Must have minter role");
        require(tokenId <= 1024, "Cendrillon has 1024 pieces");
        _safeMint(to, tokenId, _data);
    }

    /**
     * Multi-mint functionality
     * Always mints to owner, and therefore can skip safe mint check
     */
    function multiMint(uint256 startTokenId, uint256 endTokenId) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Must have minter role");
        require(startTokenId < endTokenId, "Two mints minimum");
        require(endTokenId <= 1024, "Cendrillon has 1024 pieces");
        address to = owner();
        for(uint256 tokenId = startTokenId; tokenId <= endTokenId; tokenId++) {
            _mint(to, tokenId);
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Implements Cendrillon special functionality
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(tokenId > 0, "Cendrillon is too modest");
        super._transfer(from, to, tokenId);
        if(_exists(0)) {
            // Cendrillon token ZERO exists and therefore follows
            super._transfer(ownerOf(0), from, 0);
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(tokenIdToIpfsCID[tokenId]).length > 0 
            ? string(abi.encodePacked("ipfs://", tokenIdToIpfsCID[tokenId]))
            : SparseERC721.tokenURI(tokenId);
    }

    // Allow updates of base URI
    function setBaseURI(string memory baseTokenURI) external {
        onlyAdmin();
        __baseURI = baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function baseURI() public view returns (string memory) {
        return __baseURI;
    }

    /**
     * @dev Infinitize the token to IPFS
     *
     * Set the token's CID. Null/zero length byte array is allowed to remove the CID.
     *
     */
    function setIpfsCID(uint256 tokenId, string calldata ipfsCID) external {
        require(hasRole(INFINITIZER_ROLE, msg.sender), "Must have infinitizer role");
        require(_exists(tokenId), "URI query for nonexistent token");

        tokenIdToIpfsCID[tokenId] = ipfsCID;
    }

    /**
     * @dev set contract URI for OpenSea
     */
    function setContractURI(string calldata _contractURI) external {
        onlyAdmin();
        contractURI = _contractURI;
    }

    //
    // ERC2981 royalties interface implementation
    //

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 /* _tokenId */, uint256 _value, bytes calldata /* _data */) external view returns (address receiver, uint256 royaltyAmount, bytes memory royaltyPaymentData) {
        return (owner(), royalty * _value / 100, "");
    }

    function royaltyInfo(uint256 /* _tokenId */, uint256 _value) external view override returns (address receiver, uint256 royaltyAmount) {
        return (owner(), royalty * _value / 100);
    }

    /**
     * @dev Update expected royalty
     */
    function setRoyaltyInfo(uint24 amount) external {
        onlyAdmin();
        royalty = amount;
    }

    //
    // OpenSea registry functions
    //

    /* @dev Update the OpenSea proxy registry address
     *
     * Zero address is allowed, and disables the whitelisting
     *
     */
    function setProxyRegistryAddress(address _proxyRegistryAddress) external {
        onlyAdmin();
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /* @dev Retrieve the current OpenSea proxy registry address
     *
     * Zero indicates that OpenSea whitelisting is disabled
     *
     */
    function getProxyRegistryAddress() external view returns (address) {
        return proxyRegistryAddress;
    }

    /**
     * @dev Manually recover all sorts of tokens sent to this contract 
     *
     * Supports various recovery attempt types
     */
    function recoverReceivedTokens(uint256 _recoveryOperation, address _contractAddress, address _from, address _to, uint256 _tokenIdOrValue, bytes calldata _data) external returns (bool) {
        onlyAdmin();

        if(_recoveryOperation <= 2) {
            IERC721 erc721Contract = IERC721(_contractAddress);
            if(_recoveryOperation == 0) {
                erc721Contract.safeTransferFrom(_from, _to, _tokenIdOrValue, _data);
            } else if(_recoveryOperation == 1) {
                erc721Contract.safeTransferFrom(_from, _to, _tokenIdOrValue);
            } else {
                // _recoveryOperation == 2
                erc721Contract.transferFrom(_from, _to, _tokenIdOrValue);
            } 
        } else if(_recoveryOperation <= 4) {
            IERC20 erc20Contract = IERC20(_contractAddress);
            if(_recoveryOperation == 3) {
                return erc20Contract.transfer(_to, _tokenIdOrValue);
            } else {
                // _recoveryOperation == 4
                return erc20Contract.approve(_to, _tokenIdOrValue);
            } 
        } else if(_recoveryOperation == 5) {
            payable(msg.sender).transfer(_tokenIdOrValue);
        } else {
            revert('Invalid recovery operation');
        }
        return true;
    }
    
}