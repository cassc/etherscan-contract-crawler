// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721Base.sol";

contract MadHoneyBears is ERC721Base, ReentrancyGuard {
    error WhitelistMintNotStarted();
    error OGMintNotStarted();
    error PublicMintNotStarted();
    error IncorrectMintAmount();
    error InsufficientFunds();
    error AlreadyClaimed();
    error ExceedsTotalMint();

    uint16 public constant MAX_MINT = 5;
    uint16 public constant MAX_SUPPLY = 3333;
    uint64 public constant SPECIAL_COST = 0.03 ether;
    uint64 public constant PUBLIC_COST = 0.04 ether;

    bytes32 public immutable ogMerkleRoot;
    bytes32 public immutable wlMerkleRoot;

    string public metaUri;

    bool public ogMintEnabled = false;
    bool public publicMintEnabled = false;
    bool public whitelistMintEnabled = false;

    mapping(address => bool) public whitelistClaimed;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address[] memory _payees,
        uint256[] memory _shares,
        bytes32 _ogMerkleRoot,
        bytes32 _wlMerkleRoot,
        string memory _metaUri
    ) ERC721Base(_tokenName, _tokenSymbol, _payees, _shares) {
        ogMerkleRoot = _ogMerkleRoot;
        wlMerkleRoot = _wlMerkleRoot;
        metaUri = _metaUri;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        if ((totalSupply() + _mintAmount) > MAX_SUPPLY) revert ExceedsTotalMint();
        if (whitelistClaimed[msg.sender]) revert AlreadyClaimed();
        if (!whitelistMintEnabled) revert WhitelistMintNotStarted();
        if (_mintAmount > MAX_MINT || _mintAmount == 0) revert IncorrectMintAmount();
        if (_mintAmount > 1 && msg.value < ((_mintAmount - 1) * SPECIAL_COST)) {
            revert InsufficientFunds();
        }

        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, wlMerkleRoot, node),
            "invalid proof"
        );

        _safeMint(_msgSender(), _mintAmount);

        whitelistClaimed[msg.sender] = true;
    }

    function ogMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        if ((totalSupply() + _mintAmount) > MAX_SUPPLY) revert ExceedsTotalMint();
        if (whitelistClaimed[msg.sender]) revert AlreadyClaimed();
        if (!ogMintEnabled) revert OGMintNotStarted();
        if (_mintAmount > MAX_MINT || _mintAmount == 0) revert IncorrectMintAmount();
        if (_mintAmount > 2 && msg.value < ((_mintAmount - 2) * SPECIAL_COST)) {
            revert InsufficientFunds();
        }

        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, ogMerkleRoot, node),
            "invalid proof"
        );

        _safeMint(_msgSender(), _mintAmount);

        whitelistClaimed[msg.sender] = true;
    }

    function publicMint(uint256 _mintAmount) public payable nonReentrant {
        if ((totalSupply() + _mintAmount) > MAX_SUPPLY) revert ExceedsTotalMint();
        if (!publicMintEnabled) revert PublicMintNotStarted();
        if (_mintAmount > MAX_MINT || _mintAmount == 0) revert IncorrectMintAmount();
        if (msg.value < _mintAmount * PUBLIC_COST) revert InsufficientFunds();

        _safeMint(_msgSender(), _mintAmount);
    }

    function mintTo(address _to, uint256 _amount) external onlyOwner {
        if ((totalSupply() + _amount) > MAX_SUPPLY) revert ExceedsTotalMint();
        _safeMint(_to, _amount);
    }

    function toggleOgMint() external onlyOwnerAdmin {
        ogMintEnabled = !ogMintEnabled;
    }

    function toggleWlMint() external onlyOwnerAdmin {
        whitelistMintEnabled = !whitelistMintEnabled;
    }

    function togglePublicMint() external onlyOwnerAdmin {
        publicMintEnabled = !publicMintEnabled;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metaUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}