// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import 'erc721a/contracts/ERC721A.sol';

contract NIJI is ERC721A('NIJI', 'NIJI'), Ownable, AccessControl {
    enum Phase {
        BeforeMint,
        PreMint1,
        PreMint2,
        PublicMint
    }

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');

    address public constant withdrawAddress = 0xc067591a7cf68D6190Bd6041Fbd4d58565eAaB5d;
    uint256 public constant maxSupply = 3333;
    uint256 public constant publicMaxPerTx = 1;
    string public constant baseExtension = '.json';

    string public baseURI = 'ipfs://QmZk8ikAY16JH4NwrhvUkWKbUUhcJZuj2CYPDxy4sRCGWo/';

    bytes32 public merkleRoot;
    Phase public phase = Phase.BeforeMint;

    mapping(Phase => mapping(address => uint256)) public minted;
    mapping(Phase => uint256) public limitedPerWL;
    mapping(Phase => uint256) public costs;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), 'Caller is not a minter');
        _;
    }
    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, msg.sender), 'Caller is not a burner');
        _;
    }

    constructor() {
        limitedPerWL[Phase.PreMint1] = 2;
        limitedPerWL[Phase.PreMint2] = 3;
        costs[Phase.PreMint1] = 0.01 ether;
        costs[Phase.PreMint2] = 0.015 ether;
        costs[Phase.PublicMint] = 0.015 ether;
        _safeMint(0x7F429dc5FFDa5374bb09a1Ba390FfebdeA4797a4, 333);
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
    function mint(uint256 _mintAmount) external payable {
        require(phase == Phase.PublicMint, 'Public mint is not active.');
        uint256 cost = costs[Phase.PublicMint] * _mintAmount;
        _mintCheck(_mintAmount, cost);
        require(_mintAmount <= publicMaxPerTx, 'Mint amount cannot exceed 1 per Tx.');

        _safeMint(msg.sender, _mintAmount);
    }

    function preMint(
        uint256 _mintAmount,
        uint256 _wlCount,
        bytes32[] calldata _merkleProof
    ) external payable {
        require(phase == Phase.PreMint1 || phase == Phase.PreMint2, 'PreMint is not active.');
        uint256 cost = costs[phase] * _mintAmount;
        _mintCheck(_mintAmount, cost);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _wlCount));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid Merkle Proof');

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