// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import 'erc721a/contracts/ERC721A.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import 'contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol';

contract WANOKUNI is
    ERC721A('WANOKUNI', 'WANOKUNI'),
    Ownable,
    DefaultOperatorFilterer,
    ERC2981,
    AccessControl
{
    using EnumerableSet for EnumerableSet.AddressSet;
    enum Phase {
        BeforeMint,
        PreMint1,
        PreMint2,
        PublicMint
    }
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');
    uint256 public constant maxSupply = 6660;

    string public constant baseExtension = '.json';

    address public constant withdrawAddress = 0x75bC2498b3Ae8021a475CAD48d5B301a637D9d53;

    string public baseURI = 'https://data.syou-nft.com/wanokuni/json/';

    IContractAllowListProxy public cal;
    EnumerableSet.AddressSet localAllowedAddresses;
    uint256 public calLevel = 1;
    bool public enableRestrict = true;
    
    Phase public phase = Phase.BeforeMint;
    uint256 public publicMaxPerTx = 10;
    uint256 public limitedPerWL = 1;
    
    mapping(address => uint256) public minted;
    mapping(Phase => uint256) public costs;
    bytes32 public merkleRoot;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), 'Caller is not a minter');
        _;
    }
    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, _msgSender()), 'Caller is not a burner');
        _;
    }

    constructor() {
        costs[Phase.PreMint1] = 0.003 ether;
        costs[Phase.PreMint2] = 0.003 ether;
        costs[Phase.PublicMint] = 0.003 ether;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _setDefaultRoyalty(withdrawAddress, 1000);
        _safeMint(0x3efe8AAFD7fDF66ABE45CA3c836FDF4AF52EC397, 110);
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

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // external
    function publicMint(
        uint256 _mintAmount
    ) external payable {
        require(tx.origin == msg.sender, "Not EOA");
        require(phase == Phase.PublicMint, 'Public mint is not active.');
        uint256 cost = costs[Phase.PublicMint] * _mintAmount;
        _mintCheck(_mintAmount, cost);

        require(_mintAmount <= publicMaxPerTx, 'Mint amount cannot exceed publicMaxPerTx per Tx.');

        _safeMint(msg.sender, _mintAmount);
    }

    function preMint2(
        uint256 _mintAmount,
        uint256 _wlCount,
        bytes32[] calldata _merkleProof
    ) external payable {
        require(
            phase == Phase.PreMint2,
            'PreMint2 is not active.'
        );
        uint256 cost = costs[phase] * _mintAmount;
        _mintCheck(_mintAmount, cost);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _wlCount));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid Merkle Proof');

        require(_mintAmount <= publicMaxPerTx, 'Mint amount cannot exceed publicMaxPerTx per Tx.');

        _safeMint(msg.sender, _mintAmount);
    }

    function preMint1(
        uint256 _mintAmount,
        uint256 _wlCount,
        bytes32[] calldata _merkleProof
    ) external payable {
        require(
            phase == Phase.PreMint1,
            'PreMint1 is not active.'
        );
        uint256 cost = costs[phase] * _mintAmount;
        _mintCheck(_mintAmount, cost);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _wlCount));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid Merkle Proof');

        require(
            minted[msg.sender] + _mintAmount <= _wlCount * limitedPerWL,
            'Address already claimed max amount'
        );

        minted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    // external (only minter)
    function minterMint(address _address, uint256 _amount) external onlyMinter {
        _safeMint(_address, _amount);
    }

    // external (only burner)
    function burnerBurn(address _address, uint256[] calldata tokenIds) external onlyBurner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_address == ownerOf(tokenId));

            _burn(tokenId);
        }
    }

    // public (only owner)
    function ownerMint(address to, uint256 count) public onlyOwner {
        _safeMint(to, count);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function addLocalContractAllowList(address transferer) external onlyOwner {
        localAllowedAddresses.add(transferer);
    }

    function removeLocalContractAllowList(address transferer) external onlyOwner {
        localAllowedAddresses.remove(transferer);
    }

    function setCAL(address value) external onlyOwner {
        cal = IContractAllowListProxy(value);
    }

    function setCALLevel(uint256 value) external onlyOwner {
        calLevel = value;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPhase(Phase _newPhase) external onlyOwner {
        phase = _newPhase;
    }

    function setPublicMaxPerTx(uint256 _publicMaxPerTx) external onlyOwner {
        publicMaxPerTx = _publicMaxPerTx;
    }

    function setLimitedPerWL(uint256 _number) external onlyOwner {
        limitedPerWL = _number;
    }

    function setCost(Phase _phase, uint256 _cost) external onlyOwner {
        costs[_phase] = _cost;
    }

    //external
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

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_isAllowed(operator) || !approved, 'RestrictApprove: Can not approve locked token');
        super.setApprovalForAll(operator, approved);
    }

    function getLocalContractAllowList() external view returns (address[] memory) {
        return localAllowedAddresses.values();
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        if (!_isAllowed(operator)) return false;
        return super.isApprovedForAll(account, operator);
    }

    function _isAllowed(address transferer) internal view virtual returns (bool) {
        if (!enableRestrict) return true;

        return localAllowedAddresses.contains(transferer) || cal.isAllowed(transferer, calLevel);
    }
}