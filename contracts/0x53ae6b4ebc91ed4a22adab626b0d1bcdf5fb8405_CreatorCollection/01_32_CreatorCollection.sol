// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "../royalties/Royalties.sol";

// Version: 5.0
contract CreatorCollection is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    AccessControlEnumerableUpgradeable,
    Royalties
{
    bytes32 private constant _DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
        );

    bytes32 private constant _MINT_SIGNED_TYPEHASH =
        keccak256(
            "MintNFT(address sender,address to,string tokenURI,bytes32 tokenNonce,"
            "address[] royaltyReceivers,uint256[] royaltyBasisPoints)"
        );

    bytes32 private constant _MINT_EDITIONS_SIGNED_TYPEHASH =
        keccak256(
            "MintNFTEditions(address sender,address to,string[] tokenURIs,bytes32 tokenNonce,"
            "address[] royaltyReceivers,uint256[] royaltyBasisPoints)"
        );

    bytes32 private _eip712DomainSeparator;

    function initialize(
        string calldata baseURI,
        string calldata contractName,
        string calldata tokenSymbol,
        address _owner
    ) public initializer {
        __ERC721_init(contractName, tokenSymbol);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __AccessControlEnumerable_init();

        _baseURIValue = baseURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(MINTER_ROLE, _owner);

        _eip712DomainSeparator = keccak256(
            abi.encode(
                _DOMAIN_TYPEHASH,
                keccak256("Verisart"),
                keccak256("1"),
                block.chainid,
                address(this),
                0x44e13add1946dd1b4565b9603989e9703cc27e2501bfaf4720de9b71b4fd81de
            )
        );

        _allowSignedMinting = true;
    }

    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    CountersUpgradeable.Counter private _editionCounter;
    string private _baseURIValue;
    uint256 private constant _MAX_SINGLES = 100000000;
    mapping(bytes32 => bool) private _signedMints;

    /*
     * @dev allows the owner (and potentially other 3rd parties) permission to mint
     * on behalf of the owner
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Allows minting via signed mint (an off-chain signature from a `MINTER_ROLE` user is still required).
     *      This is defaulted to true on deployment, but can be disabled by the contract admin.
     */
    bool private _allowSignedMinting;

    function allowSignedMinting() external view returns (bool) {
        return _allowSignedMinting;
    }

    function setAllowSignedMinting(bool val) external onlyAdmin {
        _allowSignedMinting = val;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    /**
     * Required to allow the owner to administrate the contract on OpenSea.
     * Note if there are many addresses with the DEFAULT_ADMIN_ROLE, the one which is returned may be arbitrary.
     */
    function owner() public view virtual returns (address) {
        return _getPrimaryAdmin();
    }

    function _getPrimaryAdmin() internal view virtual returns (address) {
        if (getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 0) {
            return address(0x0);
        }
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    /**
     * @dev Throws if called by any account other than an approved minter.
     */
    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "Restricted to approved minters"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Restricted to admins"
        );
        _;
    }

    function mintAndTransfer(
        address to,
        string calldata _tokenURI,
        address payable[] calldata royaltyReceivers,
        uint256[] calldata royaltyBasisPoints
    ) external onlyMinter {
        uint256 newestToken = getNextTokenId();
        _mintNoPermission(
            msg.sender,
            _tokenURI,
            royaltyReceivers,
            royaltyBasisPoints
        );
        safeTransferFrom(msg.sender, to, newestToken);
    }

    function _mintNoPermission(
        address to,
        string calldata _tokenURI,
        address payable[] calldata royaltyReceivers,
        uint256[] calldata royaltyBasisPoints
    ) private {
        uint256 tokenId = getNextTokenId();
        require(
            tokenId < _MAX_SINGLES,
            "Maximum number of single tokens exceeded"
        );

        _mintSingle(
            to,
            tokenId,
            _tokenURI,
            royaltyReceivers,
            royaltyBasisPoints
        );
        _tokenIdCounter.increment();
    }

    function mint(
        address to,
        string calldata _tokenURI,
        address payable[] calldata royaltyReceivers,
        uint256[] calldata royaltyBasisPoints
    ) external onlyMinter {
        _mintNoPermission(to, _tokenURI, royaltyReceivers, royaltyBasisPoints);
    }

    function mintSigned(
        address to,
        string calldata _tokenURI,
        bytes32 tokenNonce,
        address payable[] calldata royaltyReceivers,
        uint256[] calldata royaltyBasisPoints,
        bytes calldata signature
    ) external {
        bytes memory args = abi.encode(
            _MINT_SIGNED_TYPEHASH,
            msg.sender,
            to,
            keccak256(abi.encodePacked(_tokenURI)),
            tokenNonce,
            keccak256(abi.encodePacked(royaltyReceivers)),
            keccak256(abi.encodePacked(royaltyBasisPoints))
        );
        _checkSigned(args, tokenNonce, signature);
        _mintNoPermission(to, _tokenURI, royaltyReceivers, royaltyBasisPoints);
    }

    function _mintEditionsNoPermission(
        address to,
        string[] calldata _tokenURIs,
        address payable[] calldata royaltyReceivers,
        uint256[] calldata royaltyBasisPoints
    ) private {
        require(_tokenURIs.length > 1, "Must be more than 1 token per edition");

        uint256 tokenId = getNextEditionId();
        _mintEditions(
            to,
            tokenId,
            _tokenURIs,
            royaltyReceivers,
            royaltyBasisPoints
        );
        _editionCounter.increment();
    }

    function mintEditions(
        address to,
        string[] calldata _tokenURIs,
        address payable[] calldata royaltyReceivers,
        uint256[] calldata royaltyBasisPoints
    ) external onlyMinter {
        _mintEditionsNoPermission(
            to,
            _tokenURIs,
            royaltyReceivers,
            royaltyBasisPoints
        );
    }

    function mintEditionsSigned(
        address to,
        string[] calldata _tokenURIs,
        bytes32 tokenNonce,
        address payable[] calldata royaltyReceivers,
        uint256[] calldata royaltyBasisPoints,
        bytes calldata signature
    ) external {
        bytes memory args = abi.encode(
            _MINT_EDITIONS_SIGNED_TYPEHASH,
            msg.sender,
            to,
            keccak256(abi.encodePacked(_hashStringArray(_tokenURIs))),
            tokenNonce,
            keccak256(abi.encodePacked(royaltyReceivers)),
            keccak256(abi.encodePacked(royaltyBasisPoints))
        );
        _checkSigned(args, tokenNonce, signature);
        _mintEditionsNoPermission(
            to,
            _tokenURIs,
            royaltyReceivers,
            royaltyBasisPoints
        );
    }

    function _mintEditions(
        address to,
        uint256 tokenId,
        string[] calldata _tokenURIs,
        address payable[] calldata royaltyReceivers,
        uint256[] calldata royaltyBasisPoints
    ) private {
        for (uint256 i = 0; i < _tokenURIs.length; i++) {
            _mintSingle(
                to,
                tokenId + i,
                _tokenURIs[i],
                royaltyReceivers,
                royaltyBasisPoints
            );
        }
    }

    function _mintSingle(
        address to,
        uint256 tokenId,
        string calldata _tokenURI,
        address payable[] calldata royaltyReceivers,
        uint256[] calldata royaltyBasisPoints
    ) private {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        _setTokenRoyaltiesOnMint(tokenId, royaltyReceivers, royaltyBasisPoints);
    }

    function setTokenRoyalties(
        uint256 tokenId,
        address payable[] calldata royaltyReceivers,
        uint256[] calldata royaltyBasisPoints
    ) external onlyAdmin {
        _setTokenRoyaltiesAfterMint(
            tokenId,
            royaltyReceivers,
            royaltyBasisPoints
        );
    }

    function setDefaultRoyalties(
        address payable[] calldata royaltyReceivers,
        uint256[] calldata royaltyBasisPoints
    ) external onlyAdmin {
        _setDefaultRoyalties(royaltyReceivers, royaltyBasisPoints);
    }

    function _checkSigned(
        bytes memory args,
        bytes32 tokenNonce,
        bytes calldata signature
    ) private {
        // Check global flag
        require(
            _allowSignedMinting == true,
            "Global signed minting must be turned on"
        );

        // Recover signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _eip712DomainSeparator,
                keccak256(args)
            )
        );
        address authorizer = ECDSAUpgradeable.recover(digest, signature);

        // Check signer can mint on this contract
        require(
            hasRole(MINTER_ROLE, authorizer),
            "Signature doesn't match minter"
        );

        // Check nonce hasn't been redeemed already
        require(
            _signedMints[tokenNonce] == false,
            "Signed mint already redeemed"
        );

        // Mark the nonce as redeemed
        _signedMints[tokenNonce] = true;
    }

    // In EIP-712 arrays of dynamically-sized types need each element hashed first
    function _hashStringArray(
        string[] calldata data
    ) private pure returns (bytes32[] memory) {
        bytes32[] memory keccakData = new bytes32[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            keccakData[i] = keccak256(bytes(data[i]));
        }
        return keccakData;
    }

    function getNextTokenId() public view returns (uint256) {
        return _tokenIdCounter.current() + 1;
    }

    function getNextEditionId() public view returns (uint256) {
        return ((_editionCounter.current() + 1) * _MAX_SINGLES) + 1;
    }

    function isTokenNonceRedeemed(
        bytes32 tokenNonce
    ) external view returns (bool) {
        return _signedMints[tokenNonce];
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _existsRoyalties(
        uint256 tokenId
    ) internal view virtual override(Royalties) returns (bool) {
        return super._exists(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            _supportsRoyaltyInterfaces(interfaceId);
    }
}