// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

// OpenSea Operator Filter Registry
// https://github.com/ProjectOpenSea/operator-filter-registry
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract NFT is
    DefaultOperatorFilterer,
    AccessControl,
    ERC2981,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    event RoyaltyWalletChanged(
        address indexed previousWallet,
        address indexed newWallet
    );
    event RoyaltyFeeChanged(uint256 previousFee, uint256 newFee);
    event BaseURIChanged(string previousURI, string newURI);

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _baseTokenURI;

    bool public isArtCodeSealed;
    string public artCode;
    string public artCodeDependencies; // e.g., [email protected]
    string public artCodeDescription;

    /**
     * @param _name ERC721 token name
     * @param _symbol ERC721 token symbol
     * @param _uri Base token uri
     * @param _royaltyWallet Wallet where royalties should be sent
     * @param _royaltyFee Fee numerator to be used for fees
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _royaltyWallet,
        uint96 _royaltyFee
    ) ERC721(_name, _symbol) {
        _setBaseTokenURI(_uri);
        _setDefaultRoyalty(_royaltyWallet, _royaltyFee);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev Throws if called by any account other than owners. Implemented using the underlying AccessControl methods.
     */
    modifier onlyOwners() {
        require(
            hasRole(OWNER_ROLE, _msgSender()),
            "Caller does not have the OWNER_ROLE"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than minters. Implemented using the underlying AccessControl methods.
     */
    modifier onlyMinters() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Caller does not have the MINTER_ROLE"
        );
        _;
    }

    /**
     * @dev Mints the specified token ids to the recipient addresses
     * @param recipient Address that will receive the tokens
     * @param tokenIds Array of tokenIds to be minted
     */
    function mint(address recipient, uint256[] calldata tokenIds)
        external
        onlyMinters
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(recipient, tokenIds[i]);
        }
    }

    /**
     * @dev Mints the specified token id to the recipient addresses
     * @dev The unused string parameter exists to support the API used by ChainBridge.
     * @param recipient Address that will receive the tokens
     * @param tokenId tokenId to be minted
     */
    function mint(
        address recipient,
        uint256 tokenId,
        string calldata
    ) external onlyMinters {
        _mint(recipient, tokenId);
    }

    /**
     * @dev Pauses token transfers
     */
    function pause() external onlyOwners {
        _pause();
    }

    /**
     * @dev Unpauses token transfers
     */
    function unpause() external onlyOwners {
        _unpause();
    }

    /**
     * @dev Sets the base token URI
     * @param uri Base token URI
     */
    function setBaseTokenURI(string calldata uri) external onlyOwners {
        _setBaseTokenURI(uri);
    }

    /**
     * @dev Sets the generative art script and supporting information
     * @param _artCode The generative art script or source code
     * @param _artCodeDependencies Any information about dependencies or required tools to run the script
     * @param _artCodeDescription Description of the script
     */
    function setArtCode(
        string memory _artCode,
        string memory _artCodeDependencies,
        string memory _artCodeDescription
    ) external onlyOwners {
        require(isArtCodeSealed == false, "Art code is sealed.");
        artCode = _artCode;
        artCodeDependencies = _artCodeDependencies;
        artCodeDescription = _artCodeDescription;
    }

    /**
     * @dev Appends code chunk to the existing artCode generative art script and supporting information
     * @param _codeChunk The generative art script or source code
     */
    function concatArtCode(string memory _codeChunk) external onlyOwners {
        require(isArtCodeSealed == false, "Art code is sealed.");
        artCode = string(abi.encodePacked(artCode, _codeChunk));
    }

    /**
     * @dev Locks the already set generative art script and supporting information
     */
    function sealArtCode() external onlyOwners {
        require(isArtCodeSealed == false, "Art code is already sealed.");
        require(bytes(artCode).length != 0, "No art code set.");
        require(
            bytes(artCodeDependencies).length != 0,
            "No art code deps. set."
        );
        require(
            bytes(artCodeDescription).length != 0,
            "No art code description set."
        );
        isArtCodeSealed = true;
    }

    /**
     * @dev For each existing tokenId, it returns the URI where metadata is stored
     * @param tokenId Token id
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory uri = super.tokenURI(tokenId);
        return
            bytes(uri).length > 0 ? string(abi.encodePacked(uri, ".json")) : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC2981, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable, ERC721Pausable)  {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _setBaseTokenURI(string memory newURI) internal {
        emit BaseURIChanged(_baseTokenURI, newURI);
        _baseTokenURI = newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setApprovalForAll(address operator, bool approved) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(IERC721, ERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}