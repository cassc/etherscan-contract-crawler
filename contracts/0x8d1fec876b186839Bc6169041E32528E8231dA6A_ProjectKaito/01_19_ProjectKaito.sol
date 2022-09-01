// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721A.sol";

contract ProjectKaito is Ownable, ReentrancyGuard, AccessControl, ERC2981, ERC721A {
    using Strings for uint256;

    bytes32 public constant MINT_SIGNER_ROLE = keccak256("MINT_SIGNER_ROLE");
    bytes32 public constant WHITELIST_MINT_TYPEHASH =
        keccak256("WhitelistMint(address user,uint256 quantity,uint256 deadline)");
    bytes32 public constant TEAM_MINT_TYPEHASH = keccak256("TeamMint(address user,uint256 quantity,uint256 deadline)");
    bytes32 public DOMAIN_SEPARATOR;

    address authorized;

    bool public teamMintEnabled;
    bool public whitelistMintEnabled;
    bool public publicMintEnabled;

    uint256 public teamMintStartTimestamp;
    uint256 public whitelistMintStartTimestamp;
    uint256 public publicMintStartTimestamp;

    uint256 public constant maxPublicMintPerWallet = 1;
    uint256 public constant maxTeamMintPerWallet = 2;
    uint256 public constant maxWhitelistMintPerWallet = 2;

    mapping(address => bool) public whitelistClaim;
    mapping(address => bool) public teamClaim;

    string private _baseTokenURI;
    string private _postfix = ".json";

    modifier isHuman() {
        require(tx.origin == msg.sender, "Only humans :)");
        _;
    }

    modifier onlyOwnerAndAuthorized() {
        require(owner() == _msgSender() || authorized == _msgSender(), "Only authorized!");
        _;
    }

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        string memory baseTokenUri_,
        uint256 teamMintStartTimestamp_,
        uint256 whitelistMintStartTimestamp_,
        uint256 publicMintStartTimestamp_,
        address owner_
    ) ERC721A("Project Kaito", "KAITO", maxBatchSize_, collectionSize_) {
        _baseTokenURI = baseTokenUri_;
        teamMintStartTimestamp = teamMintStartTimestamp_;
        whitelistMintStartTimestamp = whitelistMintStartTimestamp_;
        publicMintStartTimestamp = publicMintStartTimestamp_;
        authorized = _msgSender();
        _safeMint(owner_, maxBatchSize_);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("ProjectKaito")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        _setupRole(DEFAULT_ADMIN_ROLE, owner_);
        _setupRole(MINT_SIGNER_ROLE, _msgSender());
        _setDefaultRoyalty(owner_, 1000); // 10%
        transferOwnership(owner_);
    }

    function mintTeam(
        uint256 deadline,
        uint256 quantity,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external isHuman {
        require(teamMintEnabled, "ProjectKaito: Team mint is disabled");
        require(teamMintStartTimestamp < block.timestamp, "ProjectKaito: Minting will start soon");
        require(totalSupply() + quantity <= collectionSize, "ProjectKaito: Minting has been finished");
        require(
            _numberMinted(msg.sender) + quantity <= maxTeamMintPerWallet,
            "ProjectKaito: Cannot mint this much tokens"
        );
        require(!teamClaim[msg.sender], "ProjectKaito: Team already minted");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(TEAM_MINT_TYPEHASH, msg.sender, quantity, deadline))
            )
        );
        require(deadline >= block.timestamp, "ProjectKaito: Mint signature expired");
        address signer = ecrecover(digest, v, r, s);
        require(hasRole(MINT_SIGNER_ROLE, signer), "ProjectKaito: Invalid signature");

        teamClaim[msg.sender] = true;
        _safeMint(msg.sender, quantity);
    }

    function mintWhitelist(
        uint256 deadline,
        uint256 quantity,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external isHuman {
        require(whitelistMintEnabled, "ProjectKaito: Whitelist mint is disabled");
        require(whitelistMintStartTimestamp < block.timestamp, "ProjectKaito: Minting will start soon");
        require(totalSupply() + quantity <= collectionSize, "ProjectKaito: Minting has been finished");
        require(
            _numberMinted(msg.sender) + quantity <= maxWhitelistMintPerWallet,
            "ProjectKaito: Cannot mint this much tokens"
        );
        require(!whitelistClaim[msg.sender], "ProjectKaito: Whitelist already minted");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(WHITELIST_MINT_TYPEHASH, msg.sender, quantity, deadline))
            )
        );
        require(deadline >= block.timestamp, "ProjectKaito: Mint signature expired");
        address signer = ecrecover(digest, v, r, s);
        require(hasRole(MINT_SIGNER_ROLE, signer), "ProjectKaito: Invalid signature");

        whitelistClaim[msg.sender] = true;
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external isHuman {
        require(publicMintEnabled, "ProjectKaito: Minting is disabled at the moment");
        require(publicMintStartTimestamp < block.timestamp, "ProjectKaito: Minting will start soon");
        require(totalSupply() + quantity <= collectionSize, "ProjectKaito: Minting has been finished");
        require(
            _numberMinted(msg.sender) + quantity <= maxPublicMintPerWallet,
            "ProjectKaito: Cannot mint this much tokens"
        );
        _safeMint(msg.sender, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC2981, ERC721A)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), _postfix)) : "";
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    function setBaseURI(string calldata baseURI, string calldata postfix) external onlyOwnerAndAuthorized {
        _baseTokenURI = baseURI;
        _postfix = postfix;
    }

    function setTeamMintSettings(bool _teamMintEnabled, uint256 _teamMintStartTimestamp)
        external
        onlyOwnerAndAuthorized
    {
        teamMintEnabled = _teamMintEnabled;
        teamMintStartTimestamp = _teamMintStartTimestamp;
    }

    function setWhitelistMintSettings(bool _whitelistMintEnabled, uint256 _whitelistMintStartTimestamp)
        external
        onlyOwnerAndAuthorized
    {
        whitelistMintEnabled = _whitelistMintEnabled;
        whitelistMintStartTimestamp = _whitelistMintStartTimestamp;
    }

    function setPubilcSettings(bool _publicMintEnabled, uint256 _publicMintStartTimestamp)
        external
        onlyOwnerAndAuthorized
    {
        publicMintEnabled = _publicMintEnabled;
        publicMintStartTimestamp = _publicMintStartTimestamp;
    }

    function drainEth() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "ProjectKaito: Transfer failed.");
    }

    function drainToken(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        token.transfer(to, amount);
    }
}