// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './ERC721A.sol';
import './MerkleProof.sol';

contract Marion is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_PRESALE_MINT = 2;
    uint256 public constant MAX_SUPER_PRESALE_MINT = 3;
    uint256 public constant MAX_PUBLIC_SALE_PER_TX = 1;
    uint256 public constant MAX_PUBLIC_SALE_PER_WALLET = 1;
    uint256 public constant MAX_RESERVE_MINT = 333;
    uint256 public constant MAX_RESERVE_MINT_PER_TX = 10;
    uint256 private _reserved = 0;
    bytes32 private whitelist_merkleRoot;
    bytes32 private superwhitelist_merkleRoot;
    bool public presaleOnlyActive = true;
    bool public publicSaleOnlyActive = false;
    bool public paused = true;
    bool public revealed = false;
    string baseTokenURI;

    mapping(address => bool) private shareholder;
    mapping(address => uint256) public whitelistAddressMintedBalance; // 2 Mintable
    mapping(address => uint256) public superWhitelistAddressMintedBalance; // 3 Mintable
    mapping(address => uint256) public publicAddressMintedBalance; // 1 Mintable

    event Received(address, uint);
    
    // Team addresses
    address t1 = 0x7Bf8F2E3e9E005003fba50e779a0700691220943; // Founder
    address t2 = 0x028cC31c9F2be3B7E2c87319CabeF09Eae328307; // Community
    address t3 = 0x2d99Cb3a32Ec2664e8973744AFA4492b1BE75B86; // Marketing Manager
    address t4 = 0xc7D3d07c6356Ea55775f917157CC95B5595C38a4; // Investor
    address t5 = 0xDeB34F38Ba2d81685a3744c6a728EAF5C8bd07dE; // Developer
    address t6 = 0x37c11B5fFFF83e4Be790F23C3Ebf0770e57cD235; // Developer
    address t7 = 0x77235220ee150AC8c1239b0B98697154907c1689; // Digital Artist
    address t8 = 0x296488ca00240dC20d6d7E9798c630d62Cb503Cc; // Investor
    
    constructor(string memory _baseURI, bytes32 _whitelistMerkleRoot, bytes32 _superwhitelistMerkleRoot) ERC721A("MarionLab", "MARION", MAX_RESERVE_MINT_PER_TX, MAX_SUPPLY) {
        setBaseURI(_baseURI);
        whitelist_merkleRoot = _whitelistMerkleRoot;
        superwhitelist_merkleRoot= _superwhitelistMerkleRoot;
        shareholder[t1] = true;
        shareholder[t2] = true;
        shareholder[t3] = true;
        shareholder[t4] = true;
        shareholder[t5] = true;
        shareholder[t6] = true;
        shareholder[t7] = true;
        shareholder[t8] = true;

    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier mintCheck(uint256 _mintAmount) {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Mint amt must be greater than 0");
        require(supply + _mintAmount + MAX_RESERVE_MINT < MAX_SUPPLY + 1, "Mint amt exceeds max supply");
        _;
    }

    modifier shareHolderOnly() {
        require(
            shareholder[msg.sender] || owner() == _msgSender(),
            "not shareholder/owner"
        );
        _;
    }

    //---------------- Internal ----------------
    function _leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verifyLeaf(bytes32 _leafNode, bytes32 _merkleRoot, bytes32[] memory _proof) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _merkleRoot, _leafNode);
    }

    function _doMint(address _receiver, uint256 _mintAmount) internal {
        _safeMint(_receiver, _mintAmount);
    }

    //---------------- Public/External ----------------
    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _proof) external mintCheck(_mintAmount) {
        require(presaleOnlyActive && !paused, "Presale is currently not active");
        require(_verifyLeaf(_leaf(msg.sender), whitelist_merkleRoot, _proof), "Invalid whitelist proof");

        uint256 senderMintedCount = whitelistAddressMintedBalance[msg.sender];
        require(senderMintedCount + _mintAmount <= MAX_PRESALE_MINT, "Exceeds max 2 mints for this address");
        whitelistAddressMintedBalance[msg.sender] += _mintAmount;
        
        _doMint(msg.sender, _mintAmount);
    }

    function superWhitelistMint(uint256 _mintAmount, bytes32[] calldata _proof) external mintCheck(_mintAmount) {
        require(presaleOnlyActive && !paused, "Presale is currently not active");
        require(_verifyLeaf(_leaf(msg.sender), superwhitelist_merkleRoot, _proof), "Invalid superwhitelist proof");

        uint256 senderMintedCount = superWhitelistAddressMintedBalance[msg.sender];
        require(senderMintedCount + _mintAmount <= MAX_SUPER_PRESALE_MINT, "Exceeds max 3 mints for this address");
        superWhitelistAddressMintedBalance[msg.sender] += _mintAmount;
        
        _doMint(msg.sender, _mintAmount);
    }

    function publicMint(uint256 _mintAmount) external payable mintCheck(_mintAmount) {
        require(publicSaleOnlyActive && !paused, "Public sale is not active");
        require(msg.sender == tx.origin, "Sender must be origin wallet");
        require(_mintAmount <= MAX_PUBLIC_SALE_PER_TX, "Mint amt greater than max per tx");
        
        uint256 senderMintedCount = publicAddressMintedBalance[msg.sender]; 
        require(senderMintedCount + _mintAmount <= MAX_PUBLIC_SALE_PER_WALLET, "Exceeds max 1 mints for this address.");
        publicAddressMintedBalance[msg.sender] += _mintAmount;

        _doMint(msg.sender, _mintAmount);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: TokenID does not exist.");
        return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, _tokenId.toString())) : "";
    }

    //---------------- Only Share Holder ----------------
    function teamReserveMint(uint256 _mintAmount, address _receiver) public shareHolderOnly {
        require(_mintAmount + _reserved <= MAX_RESERVE_MINT, "Mint amt exceeds max supply");
        _reserved += _mintAmount;
        _doMint(_receiver, _mintAmount);
    }

    function teamReserveMintedAmount() public shareHolderOnly view returns (uint256)  {
        return _reserved;
    }

    function setBaseURI(string memory baseURI) public shareHolderOnly {
        baseTokenURI = baseURI;
    }

    function pause(bool _state) public shareHolderOnly {
        paused = _state;
    }

    function reveal(bool _state) public shareHolderOnly {
        revealed = _state;
    }

    function publicSaleOnly(bool _state) public shareHolderOnly {
        publicSaleOnlyActive = _state;
    }

    function whitelistMintOnly(bool _state) public shareHolderOnly {
        presaleOnlyActive = _state;
    }

    function setWhitelistMerkleRoot(bytes32 _root) public shareHolderOnly {
        whitelist_merkleRoot = _root;
    }

    function setSuperWhitelistMerkleRoot(bytes32 _root) public shareHolderOnly {
        superwhitelist_merkleRoot = _root;
    }

    function withdrawAll() public payable shareHolderOnly {
        uint256 _each = address(this).balance / 1000;
        require(payable(t8).send(_each*15));
        require(payable(t7).send(_each*185));
        require(payable(t6).send(_each*150));
        require(payable(t5).send(_each*150));
        require(payable(t4).send(_each*10));
        require(payable(t3).send(_each*145));
        require(payable(t2).send(_each*145));
        require(payable(t1).send(address(this).balance));
    }
}