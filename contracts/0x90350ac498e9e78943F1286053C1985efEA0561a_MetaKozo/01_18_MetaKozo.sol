// SPDX-License-Identifier: MIT
// ███╗   ███╗███████╗████████╗ █████╗ ██╗  ██╗ ██████╗ ███████╗ ██████╗ 
// ████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║ ██╔╝██╔═══██╗╚══███╔╝██╔═══██╗
// ██╔████╔██║█████╗     ██║   ███████║█████╔╝ ██║   ██║  ███╔╝ ██║   ██║
// ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██╔═██╗ ██║   ██║ ███╔╝  ██║   ██║
// ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║██║  ██╗╚██████╔╝███████╗╚██████╔╝
// ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝ ╚═════╝ 

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {DefaultOperatorFilterer} from "./OperatorFilter/DefaultOperatorFilterer.sol";


contract MetaKozo is ERC721A, Pausable, Ownable, DefaultOperatorFilterer {
    // Address information
    address private team = 0xA59942593286A215c5F39F94714496608A66F5E8;

    // Collection sale information
    uint256 public collectionSize = 2222;
    uint8 public maxPerTX = 15;

    uint64 public preCost = 0.03 ether;
    uint256 public firstSaleMaxMintPerAddress = 2;
    uint256 public seondSaleMaxMintPerAddress = 3;

    uint64 public publicCost = 0.04 ether;

    // Salestart time (imestamp second) 
    uint256 public saleStartTime1st = 1669546800; // 2022/11/27 20:00:00 JST
    uint256 public saleStartTime2nd = 1669554000; // 2022/11/27 22:00:00 JST
    uint256 public saleStartTimePublic = 1669633200; // 2022/11/28 20:00:00 JST

    // Whitelist
    bytes32 public merkleRoot;
    mapping(address => uint256) public whiteListClaimed;

    // Reveal function
    bool public revealed = false;
    uint256 private premiumNo = 1;
    string private premiumBeforeRevealUri = 'ar://-vkR0fpw3z71UYhB9oE28CNoWij7LFhciDrf8pCz6P0';
    string private notRevealedUri = 'ar://H4H_TuRa6PAKx-R8ePuCQQo76jPhpFoidNf895bvSZo';
    string private BaseExtention = ".json";
    
    /**
     * Change reveal status
     */
    function setReveal(bool reveal_) public onlyOwner {
        revealed = reveal_;
    }

    /**
     * Before Reveal, static URI is returned, and after Reveal, respective URI is returned.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            if (tokenId < premiumNo) {
                return premiumBeforeRevealUri;
            }
            return notRevealedUri;
        }
        
        return string(abi.encodePacked(super.tokenURI(tokenId), BaseExtention));
    } 

    constructor (
        string memory _name,
        string memory _symbol
    ) ERC721A (_name, _symbol) {
        _baseTokenURI = "https://xxxxxxxxxx/";
        ownerMint(1);
    }

    // Modifier
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Events
    event Minted(
        address indexed _from, uint256 _tokenId
    );

    // Before reveal URI
    function setPremiumBeforeRevealUri(string calldata premiumBeforeRevealUri_) external onlyOwner {
        premiumBeforeRevealUri = premiumBeforeRevealUri_;
    }
    function setNotRevealedUri(string calldata beforeRevealURL) external onlyOwner {
        notRevealedUri = beforeRevealURL;
    }
    function setBaseExtention(string calldata BaseExtention_) external onlyOwner {
        BaseExtention = BaseExtention_;
    }
    function setPremiumNo(uint256 premiumNo_) external onlyOwner {
        premiumNo = premiumNo_;
    }

    // Sale start time
    function setSaleStartTimePublic(uint256 saleStartTimePublic_) external onlyOwner {
        saleStartTimePublic = saleStartTimePublic_;
    }
    function setSaleStartTime1st(uint256 saleStartTime1st_) external onlyOwner {
        saleStartTime1st = saleStartTime1st_;
    }
    function setSaleStartTime2nd(uint256 saleStartTime2nd_) external onlyOwner {
        saleStartTime2nd = saleStartTime2nd_;
    }

    // Contract size
    function setCollectionSize(uint256 collectionSize_) external onlyOwner {
        require(collectionSize_ >= totalSupply(), 'Collection size is too small');
        collectionSize = collectionSize_;
    }

    // Mint Cost 
    function setPreCost(uint64 preCost_) external onlyOwner {
        preCost = preCost_;
    }
    function setPublicCost(uint64 publicCost_) external onlyOwner {
        publicCost = publicCost_;
    }

    // Metadata URI
    string private _baseTokenURI;
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Whitelist
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // Owner Mint
    function ownerMint(uint256 _quantity) public callerIsUser onlyOwner {
        require((totalSupply() + _quantity) <= collectionSize, "Mint amount over");
        _safeMint(msg.sender, _quantity);
    }

    function checkMint(uint8 _wlCount, bytes32[] calldata _merkleProof) public view callerIsUser returns (bool isOk) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _wlCount));
        
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );
        return true;
    }

    // Punlic Mint
    function publicMint(uint256 quantity) public payable callerIsUser {
        commonSaleValidation(quantity, publicCost * quantity);
        require(block.timestamp >= saleStartTimePublic,"Public Sale has not started yet");
        
        _safeMint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }

    // AL 1st Sale (Only 2 Mint / AL)
    function firstMint(uint256 _quantity, uint8 _wlCount, bytes32[] calldata _merkleProof) public payable callerIsUser {
        commonSaleValidation(_quantity, preCost * _quantity);
        require(block.timestamp >= saleStartTime1st,"AL 1st Sale has not started yet");
        require(_quantity <= _wlCount * firstSaleMaxMintPerAddress, "1st sale can only 2 mint per 1AL");
        require(whiteListClaimed[msg.sender] + _quantity <= _wlCount * firstSaleMaxMintPerAddress, "Already claimed max in 1st Sale");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _wlCount));
        
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        whiteListClaimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        emit Minted(msg.sender, _quantity);
    }

    // AL 2nd Sale
    function secondMint(uint256 _quantity, uint8 _wlCount, bytes32[] calldata _merkleProof) public payable callerIsUser {
        commonSaleValidation(_quantity, preCost * _quantity);
        require(block.timestamp >= saleStartTime2nd,"AL 2nd Sale has not started yet");
        require(
            whiteListClaimed[msg.sender] + _quantity <= _wlCount * seondSaleMaxMintPerAddress,
            "Already claimed max"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _wlCount));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        whiteListClaimed[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        emit Minted(msg.sender, _quantity);
    }

    function commonSaleValidation(uint256 _quantity, uint256 _cost) private view {
        _requireNotPaused();
        require(_quantity > 0, "Mint quantity must be greater than 0");
        require(_quantity <= maxPerTX, "Mint limit exceeded for one transaction");
        require(totalSupply() + _quantity <= collectionSize, "Mint amount over");
        require(msg.value == _cost, "Mint cost is incorrect");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    // Team wallet
    function setTeam(address _teamAddress) external onlyOwner {
        team = _teamAddress;
    }

    function getTimestamp() public view returns (uint) {
        return block.timestamp;
    }
    
    // Withdraw
    function withdraw() public virtual onlyOwner {
        (bool dao, ) = payable(team).call{value: address(this).balance}("");
        require(dao);
    }

    // for Opensea Loyalty
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}