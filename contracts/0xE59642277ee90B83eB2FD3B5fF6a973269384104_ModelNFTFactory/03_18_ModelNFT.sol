// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./interfaces/IRoyaltyRegistry.sol";

// @author DeDe
contract ModelNFT is ERC2981, ERC721A {
    using ECDSA for bytes32;

    /// @notice max limit of minting.
    uint256 public mintLimit;

    // Override the base token URI
    string private _baseURIPrefix;

    /// @notice the attached designer address to this collection.
    address public designer;

    /// @dev royalty registry address that store the royalty info.
    IRoyaltyRegistry public royaltyRegistry;

    /// @dev dedicated to restrict one time minting per address.
    mapping(address => bool) public isAddressMinted;

    /// @dev dedicated to store the token URI if base URI is not defined.
    mapping(uint256 => string) public tokenURIs;

    event RoyaltyRegistryUpdated(address indexed _sender, address _oldAddress, address _newAddress);
    event BaseUriUpdated(address indexed _sender, string _oldURI, string _newURI);
    event DesignerUpdated(address indexed _oldAddress, address _newAddress);

    modifier onlyDesigner() {
        require(msg.sender == designer, "Unauthorized");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager(), "Unauthorized");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return royaltyRegistry.collectionOwner();
    }

    function manager() public view returns (address) {
        return royaltyRegistry.collectionManager();
    }

    function authorizedSignerAddress() public view returns (address) {
        return royaltyRegistry.collectionAuthorizedSignerAddress();
    }

    function contractURI() public view returns (string memory) {
        return royaltyRegistry.getContractURIForToken();
    }

    /**
     * @dev _rate is put in the 4th position to optimize the gas limit, as in its slot will be packed to the _designer address'
     *
     * @param _name token Name.
     * @param _symbol token Symbol.
     * @param _limit max mint limit.
     * @param _designer designer address.
     * @param _royaltyRegistry royalty receiver address.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _limit,
        address _designer,
        address _royaltyRegistry
    ) ERC721A(_name, _symbol) {
        require(Address.isContract(_royaltyRegistry), "Invalid royalty registry address");

        mintLimit = _limit;
        designer = _designer;
        royaltyRegistry = IRoyaltyRegistry(_royaltyRegistry);
    }

    /**
     * @dev override ERC721A tokenURI() function.
     *
     * @param _tokenId token id.
     *
     * @return uri string.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");

        string memory _tokenURI = tokenURIs[_tokenId];
        string memory _base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(_base).length == 0) {
            return _tokenURI;
        }

        // If both are set, concatenate the baseURI and associated tokenURI.
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_base, _tokenURI));
        }

        return super.tokenURI(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev override function for royaltyInfo ERC2981.
     * @dev Will read the royalty rate from registry.
     * Current flow does not support for token id unit royalty. Every token id will have the same royalty rate.
     * So first param is commented out.
     *
     * @param _salePrice sale price.
     *
     * @return receiver address.
     * @return royalty amount.
     */
    function royaltyInfo(
        uint256, /*_tokenId*/
        uint256 _salePrice
    ) public view override returns (address, uint256) {
        (address _receiver, uint96 royaltyRate) = royaltyRegistry.getRoyaltyInfo(address(this));

        uint256 royaltyAmount = (_salePrice * royaltyRate) / _feeDenominator();

        return (_receiver, royaltyAmount);
    }

    /**
     * @dev Getter for the base URI.
     *
     * @return base URI of the NFT.
     */
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev Only owner can migrate base URI
     *
     * @param _newBaseURI new base URi
     */
    function setBaseURI(string memory _newBaseURI) external onlyManager {
        string memory _oldUri = _baseURIPrefix;
        _baseURIPrefix = _newBaseURI;
        emit BaseUriUpdated(msg.sender, _oldUri, _baseURIPrefix);
    }

    /**
     * @dev Update the royalty registry address.
     *
     * @param _royaltyRegistry new royalty registry address.
     */
    function changeRoyaltyRegistry(address _royaltyRegistry) external onlyManager {
        require(Address.isContract(_royaltyRegistry), "Invalid address");
        address oldRoyaltyRegistry = address(royaltyRegistry);
        royaltyRegistry = IRoyaltyRegistry(_royaltyRegistry);
        emit RoyaltyRegistryUpdated(msg.sender, oldRoyaltyRegistry, address(royaltyRegistry));
    }

    /**
     * @dev Everybody who has the match salt & signature from signer address, can mint the NFT.
     *
     * @param _to receiver address of minted token.
     * @param _uri uri that will be associated to the minted token id.
     * @param _signature signature from authorized signer address.
     */
    function mint(
        address _to,
        string memory _uri,
        bytes calldata _signature
    ) external {
        require(!isAddressMinted[msg.sender], "Address has been used");

        require(
            _isValidSignature(keccak256(abi.encodePacked(msg.sender, _uri, address(this))), _signature),
            "Invalid signature"
        );

        uint256 _totalSupply = totalSupply();

        // check if minting is possible
        require(_totalSupply < mintLimit, "Maximum limit has been reached");

        // Mark address for minting
        isAddressMinted[msg.sender] = true;

        // mint a token using erc721a
        _safeMint(_to, 1);

        // set token uri
        _setTokenURI(_totalSupply, _uri);
    }

    /**
     * @notice Setter for designer address.
     * @dev Can be called only by the current designer.
     *
     * @param _designer new designer address.
     */
    function setDesigner(address _designer) external onlyDesigner {
        require(_designer != address(0), "Invalid address");
        address oldDesignerAddress = designer;
        designer = _designer;

        emit DesignerUpdated(oldDesignerAddress, designer);
    }

    /**
     * @dev Verify hashed data.
     * @param _hash Hashed data bundle
     * @param _signature Signature to check hash against
     * @return bool Is signature valid or not
     */
    function _isValidSignature(bytes32 _hash, bytes memory _signature) internal view returns (bool) {
        bytes32 signedHash = _hash.toEthSignedMessageHash();
        return signedHash.recover(_signature) == authorizedSignerAddress();
    }

    /**
     * @return base uri that is set in the storage.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    /**
     * @dev Define _setTokenURI() function similar to ERC721URIStorage
     *
     * @param _tokenId token id.
     * @param _tokenURI token uri that will be associated to the token id.
     */
    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) private {
        tokenURIs[_tokenId] = _tokenURI;
    }
}