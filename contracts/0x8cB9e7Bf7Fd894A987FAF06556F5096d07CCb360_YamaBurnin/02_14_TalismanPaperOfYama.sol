// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import 'erc721a/contracts/ERC721A.sol';

contract TalismanPaperOfYama is ERC721A('Talisman Paper of Yama', 'TPY'), Ownable, AccessControl {
    enum Phase {
        BeforeMint,
        WLMint
    }

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');
    uint256 public constant maxSupply = 2222;
    string public constant baseExtension = '.json';

    string public baseURI = 'https://data.cryptoninjapartners.com/TalismanPaperOfYama/json/';
    uint256 public mintCost = 0;

    bytes32 public merkleRoot;
    Phase public phase = Phase.BeforeMint;

    bool public transferPaused = false;

    mapping(address => uint256) public whitelistMinted;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), 'Caller is not a minter');
        _;
    }
    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, msg.sender), 'Caller is not a burner');
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _mintCheck(uint256 _mintAmount, uint256 cost) internal view {
        require(_mintAmount > 0, 'Mint amount cannot be zero');
        require(totalSupply() + _mintAmount <= maxSupply, 'Total supply cannot exceed maxSupply');
        require(msg.value >= cost, 'Not enough funds provided for mint');
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._afterTokenTransfers(from, to, startTokenId, quantity);
        require(!transferPaused, 'token transfer while paused');
    }

    // external
    function mint(
        uint256 _mintAmount,
        uint256 _presaleMax,
        bytes32[] calldata _merkleProof
    ) external payable {
        require(phase == Phase.WLMint, 'WLMint is not active.');
        uint256 cost = mintCost * _mintAmount;
        _mintCheck(_mintAmount, cost);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _presaleMax));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid Merkle Proof');

        require(whitelistMinted[msg.sender] + _mintAmount <= _presaleMax, 'Address already claimed max amount');

        whitelistMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function minterMint(address _address, uint256 _amount) external onlyMinter {
        _safeMint(_address, _amount);
    }

    function burnerBurn(address _address, uint256[] calldata tokenIds) external onlyBurner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_address == ownerOf(tokenId));

            _burn(tokenId);
        }
    }

    function ownerMint(address to, uint256 count) external onlyOwner {
        _safeMint(to, count);
    }

    function ownerBurn(uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    function setPhase(Phase _newPhase) external onlyOwner {
        phase = _newPhase;
    }

    function setMintCost(uint256 _mintCost) external onlyOwner {
        mintCost = _mintCost;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setTransferPaused(bool _transferPaused) external onlyOwner {
        transferPaused = _transferPaused;
    }

    function withdraw(address payable withdrawAddress) external onlyOwner {
        (bool os, ) = withdrawAddress.call{value: address(this).balance}('');
        require(os);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // public
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }
}