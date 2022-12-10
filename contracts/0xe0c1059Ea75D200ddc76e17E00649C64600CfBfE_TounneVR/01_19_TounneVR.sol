// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';
import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import {DefaultOperatorFilterer} from "../operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TounneVR is DefaultOperatorFilterer, ERC721A, Ownable, Pausable {
    using Strings for uint256;

    string private baseURI = '';

    bool public presale = true;
    uint256 public presale_max = 1;
    bool public mintable = false;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant PRE_MAX_SUPPLY = 800;
    string private constant BASE_EXTENSION = '.json';
    uint256 private constant PUBLIC_MAX_PER_TX = 1;

    bytes32 public merkleRoot;
    mapping(address => uint256) private whiteListClaimed;

    constructor() ERC721A('TounneVR', 'TounneVR') {
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

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    modifier whenMintable() {
        require(mintable == true, 'Mintable: paused');
        _;
    }

    /**
     * @dev The modifier allowing the function access only for real humans.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller is another contract');
        _;
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(ERC721A.tokenURI(tokenId), BASE_EXTENSION));
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function publicMint(uint256 _mintAmount)
        public
        whenNotPaused
        whenMintable
        callerIsUser
    {
        mintCheck(_mintAmount, 0);
        require(!presale, 'Presale is active.');
        require(_mintAmount <= PUBLIC_MAX_PER_TX, 'Mint amount over');

        _mint(msg.sender, _mintAmount);
    }

    function preMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        whenMintable
        whenNotPaused
    {
        preMintCheck(_mintAmount, 0);
        require(presale, 'Presale is not active.');
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf),
            'Invalid Merkle Proof'
        );

        require(
            whiteListClaimed[msg.sender] + _mintAmount <= presale_max,
            'Already claimed max'
        );
        _mint(msg.sender, _mintAmount);
        whiteListClaimed[msg.sender] += _mintAmount;
    }

    function preMintCheck(uint256 _mintAmount, uint256 cost) private view {
        require(_mintAmount > 0, 'Mint amount cannot be zero');
        require(totalSupply() + _mintAmount <= PRE_MAX_SUPPLY, 'PRE MAXSUPPLY over');
        require(msg.value >= cost, 'Not enough funds');
    }

    function mintCheck(uint256 _mintAmount, uint256 cost) private view {
        require(_mintAmount > 0, 'Mint amount cannot be zero');
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, 'MAXSUPPLY over');
        require(msg.value >= cost, 'Not enough funds');
    }

    function ownerMint(address _address, uint256 count) public onlyOwner {
        _mint(_address, count);
    }

    function setPresale(bool _state) public onlyOwner {
        presale = _state;
    }

    function setMintable(bool _state) public onlyOwner {
        mintable = _state;
    }

    function setPreMax(uint256 _max) public onlyOwner {
        presale_max = _max;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId);
    }
}