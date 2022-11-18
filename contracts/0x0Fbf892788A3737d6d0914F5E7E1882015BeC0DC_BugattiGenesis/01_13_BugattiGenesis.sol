// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

// ██████╗░██╗░░░██╗░██████╗░░█████╗░████████╗████████╗██╗  ░██████╗░██████╗░░█████╗░██╗░░░██╗██████╗░
// ██╔══██╗██║░░░██║██╔════╝░██╔══██╗╚══██╔══╝╚══██╔══╝██║  ██╔════╝░██╔══██╗██╔══██╗██║░░░██║██╔══██╗
// ██████╦╝██║░░░██║██║░░██╗░███████║░░░██║░░░░░░██║░░░██║  ██║░░██╗░██████╔╝██║░░██║██║░░░██║██████╔╝
// ██╔══██╗██║░░░██║██║░░╚██╗██╔══██║░░░██║░░░░░░██║░░░██║  ██║░░╚██╗██╔══██╗██║░░██║██║░░░██║██╔═══╝░
// ██████╦╝╚██████╔╝╚██████╔╝██║░░██║░░░██║░░░░░░██║░░░██║  ╚██████╔╝██║░░██║╚█████╔╝╚██████╔╝██║░░░░░
// ╚═════╝░░╚═════╝░░╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░░░░╚═╝░░░╚═╝  ░╚═════╝░╚═╝░░╚═╝░╚════╝░░╚═════╝░╚═╝░░░░░

// ██████╗░██╗░░██╗██╗░░░██╗░██████╗░██╗████████╗░█████╗░██╗░░░░░
// ██╔══██╗██║░░██║╚██╗░██╔╝██╔════╝░██║╚══██╔══╝██╔══██╗██║░░░░░
// ██████╔╝███████║░╚████╔╝░██║░░██╗░██║░░░██║░░░███████║██║░░░░░
// ██╔═══╝░██╔══██║░░╚██╔╝░░██║░░╚██╗██║░░░██║░░░██╔══██║██║░░░░░
// ██║░░░░░██║░░██║░░░██║░░░╚██████╔╝██║░░░██║░░░██║░░██║███████╗
// ╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░░╚═════╝░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝

// ░██████╗░███████╗███╗░░██╗███████╗░██████╗██╗░██████╗
// ██╔════╝░██╔════╝████╗░██║██╔════╝██╔════╝██║██╔════╝
// ██║░░██╗░█████╗░░██╔██╗██║█████╗░░╚█████╗░██║╚█████╗░
// ██║░░╚██╗██╔══╝░░██║╚████║██╔══╝░░░╚═══██╗██║░╚═══██╗
// ╚██████╔╝███████╗██║░╚███║███████╗██████╔╝██║██████╔╝
// ░╚═════╝░╚══════╝╚═╝░░╚══╝╚══════╝╚═════╝░╚═╝╚═════╝░

// Powered by https://nalikes.com

contract BugattiGenesis is ERC721AQueryable, DefaultOperatorFilterer, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => uint256) public ogMintedBalance;
    mapping(address => uint256) public allowlistMintedBalance;
    mapping(address => uint256) public publicMintedBalance;

    string public uriSuffix = "";
    string public baseURI;
    string public hiddenURI;
    string public claimedURI;

    uint256 public cost;
    uint256 public remainingTeamMints = 150;

    uint256 public maxSupply = 7780;
    uint256 public totalMinted = 0;

    uint256 public maxMintAmountPerTx = 5;
    uint256 public maxOgMint = 5; 
    uint256 public maxAllowlistMint = 5;
    uint256 public maxPublicMint = 5;

    bool public ogMintEnabled = false;
    bool public allowlistMintEnabled = false;
    bool public publicMintEnabled = false;
    bool public creditMintEnabled = false;
    
    bool public paused = false;
    bool public revealed = false;
    bool public blendsEnabled = false;
    bool public claimsEnabled = false;

    mapping(address=>bool) public authorizedCreditGateways;
    mapping(uint256 => bool) public claimed;
    // 1: Uncommon, 2: Rare, 3: Epic, 4: Legendary, 5: Mythic
    mapping(uint256 => uint256) public recipeCaps;

    address public server;

    event TokenClaimed(uint256[] _tokenIds, address _address);
    event TokenBlended(uint256 indexed _newTokenId, uint256 _newTokenType, address _address);

    constructor(string memory _hiddenURI, address _server) ERC721A("Bugatti Group Phygital Genesis", "BGPGC") {

        setHiddenUri(_hiddenURI);
        setServer(_server);
    }

    //******************************* MODIFIERS

    modifier mintCompliance(uint256 _mintAmount) {
        require(totalMinted + _mintAmount <= maxSupply - remainingTeamMints, "MINT: Max Supply Exceeded.");
        require(_mintAmount <= maxMintAmountPerTx, "MINT: Invalid Amount.");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "MINT: Insufficient funds.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract Paused.");
        _;
    }

    //******************************* MINT
 
    function ogMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable notPaused mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {

        require(ogMintEnabled, "OG Mint: Disabled.");
        uint256 ownerMintedCount = ogMintedBalance[_msgSender()];
        require(ownerMintedCount + _mintAmount <= maxOgMint, "OG Mint: Mint Allowance Exceeded.");
        
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "OG Mint: Invalid proof.");

        ogMintedBalance[_msgSender()] += _mintAmount;
        totalMinted += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }
    
    function allowlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable notPaused mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {

        require(allowlistMintEnabled, "Allowlist Mint: Disabled.");
        uint256 ownerMintedCount = allowlistMintedBalance[_msgSender()];
        require(ownerMintedCount + _mintAmount <= maxAllowlistMint, "Allowlist Mint: Mint Allowance Exceeded.");
        
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Allowlist Mint: Invalid proof.");

        allowlistMintedBalance[_msgSender()] += _mintAmount;
        totalMinted += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable notPaused mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {

        require(publicMintEnabled, "Public Mint: Disabled.");
        require(tx.origin == msg.sender, "PUBLIC Mint: Caller is another contract.");

        uint256 ownerMintedCount = publicMintedBalance[_msgSender()];
        require(ownerMintedCount + _mintAmount <= maxPublicMint, "Public Mint: Mint Allowance Exceeded.");

        publicMintedBalance[_msgSender()] += _mintAmount;
        totalMinted += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    // @dev Credit-payment provider's addresses
    function creditMint(uint256 _mintAmount) public payable notPaused mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        
        require(creditMintEnabled, "Credit Mint: Disabled.");
        require(authorizedCreditGateways[_msgSender()], "Credit Mint: Caller Address Not Authorized.");
        
        totalMinted += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    // @dev Admin mint
    function mintForAddress(address _receiver, uint256 _mintAmount) public notPaused mintCompliance(_mintAmount) onlyOwner {
        totalMinted += _mintAmount;
        _safeMint(_receiver, _mintAmount);
    }

    function mintToTeamMember(address _receiver, uint256 _mintAmount) public notPaused onlyOwner {
        require(totalMinted + _mintAmount <= maxSupply, "TEAM MINT: Max Supply Exceeded.");
        require(_mintAmount <= maxMintAmountPerTx, "TEAM MINT: Invalid Amount.");
        require(_mintAmount <= remainingTeamMints, "TEAM MINT: Exceeds reserved NFTs supply");

        remainingTeamMints -= _mintAmount;
        totalMinted += _mintAmount;
        _safeMint(_receiver, _mintAmount);
    }

    //******************************* OVERRIDES

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override (ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (revealed == false) {
            return hiddenURI;
        }

        if (claimed[_tokenId]) {
            string memory currentClaimedURI = claimedURI;
            return bytes(currentClaimedURI).length > 0 ? string(abi.encodePacked(currentClaimedURI, _tokenId.toString(), uriSuffix)) : "";        
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";    
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //******************************* CRUD

    // MERKLE ROOT

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // SERVER

    function setServer(address _server) public onlyOwner {
        server = _server;
    }

    // URI'S

    function setBaseURI(string memory _metadataURI) public onlyOwner {
        baseURI = _metadataURI;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setHiddenUri(string memory _hiddenURI) public onlyOwner {
        hiddenURI = _hiddenURI;
    }

    function setClaimedUri(string memory _claimedURI) public onlyOwner {
        claimedURI = _claimedURI;
    }

    // UINT'S

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(_newMaxSupply >= totalMinted + remainingTeamMints && _newMaxSupply <= maxSupply, "Invalid Max Supply.");
        maxSupply = _newMaxSupply;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxOgMint(uint256 _maxOgMint) public onlyOwner {
        maxOgMint = _maxOgMint;
    }

    function setMaxAllowlistMint(uint256 _maxAllowlistMint) public onlyOwner {
        maxAllowlistMint = _maxAllowlistMint;
    }

    function setMaxPublicMint(uint256 _maxPublicMint) public onlyOwner {
        maxPublicMint = _maxPublicMint;
    }

    // BOOL's

    function setOgMintEnabled(bool _state) public onlyOwner {
        ogMintEnabled = _state;
    }

    function setAllowlistMintEnabled(bool _state) public onlyOwner {
        allowlistMintEnabled = _state;
    }
    
    function setPublicMintEnabled(bool _state) public onlyOwner {
        publicMintEnabled = _state;
    }

    function setCreditMintEnabled(bool _state) public onlyOwner {
        creditMintEnabled = _state;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setBlendsEnabled(bool _state) public onlyOwner {
        blendsEnabled = _state;
    }

    function setClaimsEnabled(bool _state) public onlyOwner {
        claimsEnabled = _state;
    }

    // MINT CONTROLS

    function setCreditGateway(address _address, bool _state) public onlyOwner {
        authorizedCreditGateways[_address] = _state;
    }

    function enableOGMint(uint256 _cost, bytes32 _merkleRoot) public onlyOwner {
        setOgMintEnabled(true);
        setAllowlistMintEnabled(false);
        setPublicMintEnabled(false);
        setPaused(false);

        setCost(_cost);
        setMerkleRoot(_merkleRoot);
    }

    function enableAllowlistMint(uint256 _cost, bytes32 _merkleRoot) public onlyOwner {
        setAllowlistMintEnabled(true);
        setOgMintEnabled(false);
        setPublicMintEnabled(false);
        setPaused(false);

        setCost(_cost);
        setMerkleRoot(_merkleRoot);
    }

    function enablePublicMint(uint256 _cost) public onlyOwner {
        setPublicMintEnabled(true);
        setAllowlistMintEnabled(false);
        setOgMintEnabled(false);
        setPaused(false);

        setCost(_cost);
    }

    // SIGNATURES

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid Signature Length.");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    //******************************* BLEND

    function blend(uint256 _recipeId, uint256[] calldata _tokenIds, bytes memory _signature) external notPaused {
        require(blendsEnabled, "BLEND: Disabled.");
        require(_recipeId >= 1 && _recipeId <= 5, "BLEND: Invalid Recipe.");
        require(recipeCaps[_recipeId] > 0, "BLEND: Cap Exceeded.");

        bytes32 hashedMessage = keccak256(abi.encodePacked(_msgSender(), _recipeId, _tokenIds));
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedMessage));

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        require(ecrecover(prefixedHashMessage, v, r, s) == server, "BLEND: Invalid Signature.");

        for (uint256 i = 0; i < _tokenIds.length; i ++) {
            require(ownerOf(_tokenIds[i]) == _msgSender(), "BLEND: Caller Not Authorized.");
            _burn(_tokenIds[i]);
        }
        totalMinted += 1;
        recipeCaps[_recipeId] -= 1;
        _safeMint(_msgSender(), 1);
        emit TokenBlended(totalMinted, _recipeId, _msgSender());
    }

    function setRecipeCaps(uint256 _recipeId, uint256 _newCap) public onlyOwner {
        recipeCaps[_recipeId] = _newCap;
    }

    //******************************* CLAIM

    function claim(uint256[] calldata _tokenIds, bytes memory _signature) external notPaused {
        require(claimsEnabled, "CLAIM: Disabled.");

        bytes32 hashedMessage = keccak256(abi.encodePacked(_msgSender(), _tokenIds));
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedMessage));

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        require(ecrecover(prefixedHashMessage, v, r, s) == server, "CLAIM: Invalid Signature.");

        for (uint256 i = 0; i < _tokenIds.length; i ++) {
            require(ownerOf(_tokenIds[i]) == _msgSender(), "CLAIM: Caller Not Authorized.");
            require(!claimed[_tokenIds[i]], "CLAIM: Token Already Claimed.");

            claimed[_tokenIds[i]] = true;
        }
        emit TokenClaimed(_tokenIds, _msgSender());
    }

    //******************************* WITHDRAW

    function withdraw() public onlyOwner nonReentrant {
        
        uint256 balance = address(this).balance;

        bool success;
        (success, ) = payable(0x5999d8aB90A1C460fB63fbA06bbBbe3D6aF64183).call{value: balance}("");
        require(success, "Transaction Unsuccessful");

    }
}