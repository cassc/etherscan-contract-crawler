pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Cobee is
    AccessControl,
    ERC721Enumerable,
    ERC2981,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    bool private initialized;
    string private baseURI;

    uint256 private _tokenId;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    string constant ROLE_MINTER_STR = "ROLE_MINTER";

    bytes32 constant ROLE_MINTER = keccak256(bytes(ROLE_MINTER_STR));

    string constant ROLE_MINTER_ADMIN_STR = "ROLE_MINTER_ADMIN";

    bytes32 constant ROLE_MINTER_ADMIN =
        keccak256(bytes(ROLE_MINTER_ADMIN_STR));

    event eveMint(address indexed account, uint256 indexed tokenId);

    event eveBaseURI(string indexed baseURI);

    event SetMinterAdmin(bytes32 role, bytes32 adminRole, address admin);

    event RevokeMinterAdmin(bytes32 adminRole, address admin);

    event DefaultRoyalty(address indexed receiver, uint96 indexed feeNumerator);

    event UpdateTokenRoyalty(
        uint256 indexed tokenId,
        address receiver,
        uint96 feeNumerator
    );

    event SetTokenURI(uint256 indexed tokenId, string uri);

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    function initialize(address _owner) external {
        require(!initialized, "initialize: Already initialized!");

        _setRoleAdmin(ROLE_MINTER, ROLE_MINTER_ADMIN);
        _setupRole(ROLE_MINTER_ADMIN, _owner);

        _transferOwnership(_owner);
        baseURI = "https://combonetwork.io/nft/info/";
        initialized = true;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC2981, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setMinterAdmin(address minterAdmin) external onlyOwner {
        _setupRole(ROLE_MINTER_ADMIN, minterAdmin);
        emit SetMinterAdmin(ROLE_MINTER, ROLE_MINTER_ADMIN, minterAdmin);
    }

    function revokeMinterAdmin(address minterAdmin) external onlyOwner {
        _revokeRole(ROLE_MINTER_ADMIN, minterAdmin);
        emit RevokeMinterAdmin(ROLE_MINTER_ADMIN, minterAdmin);
    }

    function mint(address to) external nonReentrant returns (uint256) {
        require(
            hasRole(ROLE_MINTER, msg.sender),
            "Cobee: Caller is not a minter"
        );

        _tokenId++;
        _mint(to, _tokenId);

        emit eveMint(to, _tokenId);

        return _tokenId;
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
        emit DefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
        emit DefaultRoyalty(address(0), 0);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external {
        require(
            (owner() == _msgSender() || hasRole(ROLE_MINTER, _msgSender())),
            "Cobee: caller no permission!!!"
        );
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
        emit UpdateTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
        emit UpdateTokenRoyalty(tokenId, address(0), 0);
    }

    function updateBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit eveBaseURI(baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function updateTokenURI(
        uint256 tokenId,
        string memory _uri
    ) public onlyOwner {
        _setTokenURI(tokenId, _uri);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
        emit SetTokenURI(tokenId, _tokenURI);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "Cobee: URI query for nonexistent token");
        string memory baseURI_ = _baseURI();
        // return string(abi.encodePacked(baseURI_, tokenId.toString()));

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(baseURI_).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(baseURI_, tokenId.toString()));
    }

    function name() public view virtual override returns (string memory) {
        return "Cobee.Combo";
    }

    function symbol() public view virtual override returns (string memory) {
        return "COBEE";
    }
}