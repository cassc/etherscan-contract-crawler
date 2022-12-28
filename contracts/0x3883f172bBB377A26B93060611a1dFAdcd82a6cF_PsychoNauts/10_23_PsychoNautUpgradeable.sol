// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "./utils/RoyaltyUpgradeable.sol";
import "./utils/OwnableAdminUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract PsychoNautUpgradeable is
    Initializable,
    ERC721AUpgradeable,
    ERC721AQueryableUpgradeable,
    OwnableAdminUpgradeable,
    PaymentSplitterUpgradeable,
    RoyaltyUpgradeable,
    ReentrancyGuardUpgradeable
{
    error WhitelistMintNotStarted();
    error PublicMintNotStarted();
    error IncorrectMintAmount();
    error ExceedsWhitelistAllowance();
    error AlreadyClaimed();
    error ExceedsTotalMint();
    error ExceedsTeamMint();
    error InsufficientFunds();

    uint128 public maxMint;
    uint128 public maxSupply;
    uint256 public cost;

    uint128 public teamAndGiveAwayMax;
    uint128 public teamAndGiveAwayMinted;

    string public metaUri;

    bool public publicMintEnabled;
    bool public whitelistMintEnabled;

    bytes32 private merkleRoot;

    mapping(address => uint256) public whitelistClaimed;

    function __PsychoNaut_init(
        string memory _name,
        string memory _symbol,
        string memory _metaUri,
        address[] memory _payees,
        uint256[] memory _shares,
        bytes32 _merkleRoot
    ) internal onlyInitializing {
        __ERC721A_init(_name, _symbol);
        __ERC721AQueryable_init();
        __OwnableAdmin_init();
        __PaymentSplitter_init(_payees, _shares);
        __Royalty_init();
        __ReentrancyGuard_init();

        metaUri = _metaUri;
        merkleRoot = _merkleRoot;
        maxMint = 10;
        maxSupply = 7777;
        cost = 0.015 ether;
        teamAndGiveAwayMax = 200;
    }

    function whitelistMint(
        uint256 _mintAmount,
        uint256 _mintAllowance,
        bytes32[] calldata _merkleProof
    ) public nonReentrant {
        if (_mintAmount > _mintAllowance) revert ExceedsWhitelistAllowance();
        if ((totalSupply() + _mintAmount) > maxSupply)
            revert ExceedsTotalMint();
        if (whitelistClaimed[msg.sender] + _mintAmount > _mintAllowance)
            revert AlreadyClaimed();
        if (!whitelistMintEnabled) revert WhitelistMintNotStarted();

        bytes32 node = keccak256(abi.encodePacked(msg.sender, _mintAllowance));
        require(
            MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, node),
            "invalid proof"
        );

        _safeMint(_msgSender(), _mintAmount);

        whitelistClaimed[msg.sender] += _mintAmount;
    }

    function whitelistMintPurchase(
        uint256 _mintAmount,
        uint256 _mintAllowance,
        bytes32[] calldata _merkleProof
    ) public payable nonReentrant {
        if ((totalSupply() + _mintAmount) > maxSupply)
            revert ExceedsTotalMint();
        if (_mintAmount > maxMint || _mintAmount == 0)
            revert IncorrectMintAmount();
        if (!whitelistMintEnabled) revert WhitelistMintNotStarted();
        if (msg.value < _mintAmount * cost) revert InsufficientFunds();

        bytes32 node = keccak256(abi.encodePacked(msg.sender, _mintAllowance));
        require(
            MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, node),
            "invalid proof"
        );

        _safeMint(_msgSender(), _mintAmount);
    }

    function publicMint(uint256 _mintAmount) public payable nonReentrant {
        if ((totalSupply() + _mintAmount) > maxSupply)
            revert ExceedsTotalMint();
        if (!publicMintEnabled) revert PublicMintNotStarted();
        if (_mintAmount > maxMint || _mintAmount == 0)
            revert IncorrectMintAmount();
        if (msg.value < _mintAmount * cost) revert InsufficientFunds();

        _safeMint(_msgSender(), _mintAmount);
    }

    function teamGiveAwayMint(uint256 _amount) public onlyOwnerAdmin {
        if ((totalSupply() + _amount) > maxSupply) revert ExceedsTotalMint();
        if (teamAndGiveAwayMinted + _amount > teamAndGiveAwayMax) revert ExceedsTeamMint();
        _safeMint(_msgSender(), _amount);
    }

    function toggleWlMint() external onlyOwnerAdmin {
        whitelistMintEnabled = !whitelistMintEnabled;
    }

    function togglePublicMint() external onlyOwnerAdmin {
        publicMintEnabled = !publicMintEnabled;
    }

    function updateCost(uint256 _cost) external onlyOwnerAdmin {
        cost = _cost;
    }

    function updateMaxSupply(uint128 _supply) external onlyOwnerAdmin {
        require(_supply < maxSupply, "Cannot raise supply");
        maxSupply = _supply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metaUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return msg.sender == owner() || msg.sender == admin();
    }

    /// @dev See ERC165: https://eips.ethereum.org/EIPS/eip-165
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC165, IERC721AUpgradeable)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == type(IERC2981).interfaceId; // ERC165 ID for ERC2981
    }
}