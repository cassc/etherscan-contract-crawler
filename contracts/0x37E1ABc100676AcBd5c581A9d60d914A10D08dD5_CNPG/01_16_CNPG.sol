// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import 'erc721a/contracts/ERC721A.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract CNPG is ERC721A('CNP Gotouchi', 'CNPG'), Ownable, AccessControl, DefaultOperatorFilterer, ERC2981 {
    enum Phase {
        BeforeMint,
        PrivateMint,
        PreMint1,
        PreMint2,
        PublicMint
    }

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');

    address public constant withdrawAddress = 0x953Ee986bC71a97f25d4963C86B09fd26e60D7F6;
    uint256 public constant maxSupply = 16500;
    string public constant baseExtension = '.json';

    string public baseURI = 'https://data.syou-nft.com/cnpg/json/';

    Phase public phase = Phase.BeforeMint;
    uint256 public publicMaxPerTx = 5;

    mapping(Phase => mapping(address => uint256)) public minted;
    mapping(Phase => uint256) public limitedPerWL;
    mapping(Phase => uint256) public costs;
    mapping(Phase => bytes32) public merkleRoots;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), 'Caller is not a minter');
        _;
    }
    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, msg.sender), 'Caller is not a burner');
        _;
    }

    constructor() {
        limitedPerWL[Phase.PrivateMint] = 1;
        limitedPerWL[Phase.PreMint1] = 1;
        limitedPerWL[Phase.PreMint2] = 1;
        costs[Phase.PrivateMint] = 0.005 ether;
        costs[Phase.PreMint1] = 0.005 ether;
        costs[Phase.PreMint2] = 0.005 ether;
        costs[Phase.PublicMint] = 0.005 ether;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
        _safeMint(0x2A0522e7f9FD372e6fe320bFBe230F62964f5c9c, 1);
        _setDefaultRoyalty(0x0AB10c7d3f097d45D086cEA54b20D9bF763580e6, 1000);
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

    // external
    function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable {
        require(phase == Phase.PublicMint, 'Public mint is not active.');
        uint256 cost = costs[Phase.PublicMint] * _mintAmount;
        _mintCheck(_mintAmount, cost);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoots[phase], leaf), 'Invalid Merkle Proof');

        require(_mintAmount <= publicMaxPerTx, 'Mint amount cannot exceed 1 per Tx.');

        _safeMint(msg.sender, _mintAmount);
    }

    function mint(
        uint256 _mintAmount,
        uint256 _wlCount,
        bytes32[] calldata _merkleProof
    ) external payable {
        require(
            phase == Phase.PrivateMint || phase == Phase.PreMint1 || phase == Phase.PreMint2,
            'mint is not active.'
        );
        uint256 cost = costs[phase] * _mintAmount;
        _mintCheck(_mintAmount, cost);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _wlCount));
        require(MerkleProof.verify(_merkleProof, merkleRoots[phase], leaf), 'Invalid Merkle Proof');

        require(
            minted[phase][msg.sender] + _mintAmount <= _wlCount * limitedPerWL[phase],
            'Address already claimed max amount'
        );

        minted[phase][msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    // external (only minter)
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

    // external (only owner)
    function ownerMint(address to, uint256 count) external onlyOwner {
        _safeMint(to, count);
    }

    function setPhase(Phase _newPhase) external onlyOwner {
        phase = _newPhase;
    }

    function setPublicMaxPerTx(uint256 _publicMaxPerTx) external onlyOwner {
        publicMaxPerTx = _publicMaxPerTx;
    }

    function setLimitedPerWL(Phase _phase, uint256 _number) external onlyOwner {
        limitedPerWL[_phase] = _number;
    }

    function setCost(Phase _phase, uint256 _cost) external onlyOwner {
        costs[_phase] = _cost;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    function setMerkleRoot(Phase _phase, bytes32 _merkleRoot) external onlyOwner {
        merkleRoots[_phase] = _merkleRoot;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // public
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl, ERC2981)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}