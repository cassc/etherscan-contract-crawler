// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import './ERC721Lockable.sol';

contract Metabatch is ERC721Lockable, Ownable, AccessControl, DefaultOperatorFilterer, ERC2981 {
    enum Phase {
        BeforeMint,
        PreMint1,
        PreMint2
    }

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');
    bytes32 public constant LOCKER_ROLE = keccak256('LOCKER_ROLE');

    address public constant withdrawAddress = 0x1a332905b12C896521Ef6Dc365f5BE9549AD8dd3;
    string public constant baseExtension = '.json';
    uint256 public constant maxSupply = 10000;

    string public baseURI = 'https://data.syou-nft.com/metabatch/json/';

    bytes32 public merkleRoot;
    Phase public phase = Phase.BeforeMint;

    mapping(Phase => mapping(address => uint256)) public minted;
    uint256 public costs = 0.001 ether;
    uint256 public limitedPreMint2 = 1;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), 'Caller is not a minter');
        _;
    }
    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, _msgSender()), 'Caller is not a burner');
        _;
    }
    modifier onlyLocker() {
        require(hasRole(LOCKER_ROLE, _msgSender()), 'Caller is not a locker');
        _;
    }

    constructor() ERC721A('Metabatch', 'MTB') {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
        _grantRole(LOCKER_ROLE, _msgSender());
        _safeMint(withdrawAddress, 2000);
        _setDefaultRoyalty(withdrawAddress, 1000);
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

    // public
    function preMint(uint256 _mintAmount, uint256 _wlCount, bytes32[] calldata _merkleProof) public payable {
        require(phase == Phase.PreMint1, 'PreMint is not active.');
        uint256 cost = costs * _mintAmount;
        _mintCheck(_mintAmount, cost);

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), _wlCount));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid Merkle Proof');

        require(minted[phase][_msgSender()] + _mintAmount <= _wlCount, 'Address already claimed max amount');

        minted[phase][_msgSender()] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function preMint2(uint256 _mintAmount, uint256 _wlCount, bytes32[] calldata _merkleProof) public payable {
        require(phase == Phase.PreMint2, 'PreMint2 is not active.');
        uint256 cost = costs * _mintAmount;
        _mintCheck(_mintAmount, cost);

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), _wlCount));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid Merkle Proof');

        require(minted[phase][_msgSender()] + _mintAmount <= limitedPreMint2, 'Address already claimed max amount');

        minted[phase][_msgSender()] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
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

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
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

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Lockable, AccessControl, ERC2981) returns (bool) {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721Lockable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // external (only minter)
    function minterMint(address _address, uint256 _amount) public onlyMinter {
        _safeMint(_address, _amount);
    }

    // external (only burner)
    function burnerBurn(address _address, uint256[] calldata tokenIds) public onlyBurner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_address == ownerOf(tokenId));

            _burn(tokenId);
        }
    }

    // external (only locker)
    function setTokenLock(uint256[] calldata tokenIds, LockStatus lockStatus) external override onlyLocker {
        _setTokenLock(tokenIds, lockStatus);
    }

    function setWalletLock(address to, LockStatus lockStatus) external override onlyLocker {
        _setWalletLock(to, lockStatus);
    }

    // external (only owner)
    function ownerMint(address to, uint256 count) external onlyOwner {
        _safeMint(to, count);
    }

    function setPhase(Phase _newPhase) external onlyOwner {
        phase = _newPhase;
    }

    function setLimitedPreMint2(uint256 _limitedPreMint2) external onlyOwner {
        limitedPreMint2 = _limitedPreMint2;
    }

    function setCosts(uint256 _costs) external onlyOwner {
        costs = _costs;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setContractLock(LockStatus lockStatus) external override onlyOwner {
        _setContractLock(lockStatus);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setEnableLock(bool _enableLock) external onlyOwner {
        enableLock = _enableLock;
    }
}