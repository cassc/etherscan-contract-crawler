// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import 'erc721a/contracts/ERC721A.sol';

contract NecoGeneChristmasWreath2022 is
    ERC721A('NecoGeneChristmasWreath2022', 'NGCW'),
    Ownable,
    AccessControl,
    DefaultOperatorFilterer,
    ERC2981
{
    enum Phase {
        BeforeMint,
        PreMint1,
        PreMint2,
        PublicMint
    }

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');
    IERC721 public constant cnp = IERC721(0x845a007D9f283614f403A24E3eB3455f720559ca);
    IERC721 public constant cnpj = IERC721(0xFE5A28F19934851695783a0C8CCb25d678bB05D3);
    IERC721 public constant vlcnp = IERC721(0xCFE50e49ec3E5eb24cc5bBcE524166424563dD4E);
    IERC721 public constant cnpr = IERC721(0x836B4d9C0F01275A28085AceF53AC30460f58242);
    IERC721 public constant app = IERC721(0xC7e4D1DfB2FFdA31F27c6047479dFA7998a07d47);
    IERC721 public constant ngm = IERC721(0xc0B1a00BB0F25bbBa33B73f5fD1b3DDdb3611eBb);
    IERC721 public constant ngh = IERC721(0xCB116Ec0E27483e5eE43bCD86Edd91Cd118EFb68);
    IERC721 public constant butaversepass = IERC721(0x0bE251cB94e5ebca3615CEf74273bD121d2a8e08);

    address public constant withdrawAddress = 0x39E52A84C880A1aa5A685a91f505318052D47696;
    uint256 public constant maxSupply = 2222;
    uint256 public constant publicMaxPerTx = 1;
    string public constant baseExtension = '.json';

    string public baseURI = 'https://data.syou-nft.com/ngcw/json/';

    bytes32 public merkleRoot;
    Phase public phase = Phase.BeforeMint;

    mapping(Phase => mapping(address => uint256)) public minted;
    mapping(Phase => uint256) public limitedPerWL;
    mapping(Phase => uint256) public costs;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), 'Caller is not a minter');
        _;
    }
    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, _msgSender()), 'Caller is not a burner');
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
        limitedPerWL[Phase.PreMint1] = 3;
        limitedPerWL[Phase.PreMint2] = 2;
        costs[Phase.PreMint1] = 0.002 ether;
        costs[Phase.PreMint2] = 0.002 ether;
        costs[Phase.PublicMint] = 0.002 ether;
        _safeMint(withdrawAddress, 120);
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
    function mint(uint256 _mintAmount) public payable {
        require(phase == Phase.PublicMint, 'Public mint is not active.');
        uint256 cost = costs[Phase.PublicMint] * _mintAmount;
        _mintCheck(_mintAmount, cost);
        require(_mintAmount <= publicMaxPerTx, 'Mint amount cannot exceed 1 per Tx.');

        _safeMint(msg.sender, _mintAmount);
    }

    function canPreMint2(address _address, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        if (MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
            return true;
        }
        if (cnp.balanceOf(_address) > 0) {
            return true;
        }
        if (cnpj.balanceOf(_address) > 0) {
            return true;
        }
        if (vlcnp.balanceOf(_address) > 0) {
            return true;
        }
        if (cnpr.balanceOf(_address) > 0) {
            return true;
        }
        if (app.balanceOf(_address) > 0) {
            return true;
        }
        if (ngm.balanceOf(_address) > 0) {
            return true;
        }
        if (ngh.balanceOf(_address) > 0) {
            return true;
        }
        if (butaversepass.balanceOf(_address) > 0) {
            return true;
        }
        return false;
    }

    function preMint2(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {
        require(phase == Phase.PreMint2, 'PreMint is not active.');
        uint256 cost = costs[phase] * _mintAmount;
        _mintCheck(_mintAmount, cost);

        require(canPreMint2(msg.sender, _merkleProof), 'Cannot mint');

        require(minted[phase][msg.sender] + _mintAmount <= limitedPerWL[phase], 'Address already claimed max amount');

        minted[phase][msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function preMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {
        require(phase == Phase.PreMint1, 'PreMint is not active.');
        uint256 cost = costs[phase] * _mintAmount;
        _mintCheck(_mintAmount, cost);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid Merkle Proof');

        require(minted[phase][msg.sender] + _mintAmount <= limitedPerWL[phase], 'Address already claimed max amount');

        minted[phase][msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
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

    // public (only owner)
    function ownerMint(address to, uint256 count) public onlyOwner {
        _safeMint(to, count);
    }

    function setPhase(Phase _newPhase) public onlyOwner {
        phase = _newPhase;
    }

    function setLimitedPerWL(Phase _phase, uint256 _number) public onlyOwner {
        limitedPerWL[_phase] = _number;
    }

    function setCost(Phase _phase, uint256 _cost) public onlyOwner {
        costs[_phase] = _cost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}