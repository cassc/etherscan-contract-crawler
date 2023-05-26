// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

///@dev
// Dependencies:
// npm i --save-dev erc721a
// npm i @openzeppelin/contracts
// import "erc721a/contracts/ERC721A.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// created by: Xaikyō <> Mpdigitald
// copyright: PUML Better Health 2022

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract WearX is ERC721A, Ownable, ReentrancyGuard, Pausable{

    // public mint variables
    uint256 public maxSupply = 5000;
    uint256 public maxMint = 5;
    uint256 public mintPrice = 0.05 ether; /// @dev 10 finney = 0.01 ether

    // pre-sale mint variables
    uint256 public wlMaxMint = 5;
    uint256 public wlMintPrice = 0.05 ether;

    // token-sale mint variables
    uint256 public pumlxMaxMint = 5;
    uint256 public pumlPrice = 1535 * (10**18);
    IERC20 public tokenAddress;


    //base uri, baseextension and pre-revealUri
    string private baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;

    // booleans for reveal/all mint toggles
    bool public revealed = false;
    bool public publicMintEnabled = false;
    bool public wlMintEnabled = false;
    bool public pumlxEnabled = false;

    // keep track of # of minted tokens per user
    mapping(address => uint256) totalPublicMint;
    mapping(address => uint256) totalWlMint;
    mapping(address => uint256) totalTokenMint;


    // declare merkle root
    bytes32 public wlRoot;

    // Constructor
    // https://filesite/CID/
    // initialize cid(Pinata, ipfs etc) for baseUri and contractUri, make sure / is at end and metadata files named as "x.png" "x.json" not "name x.png" etc
    // https://gateway.pinata.cloud/ipfs/CID/
    // initialize pre-reveal cid, baseExtension has to be name.json
    // https://gateway.pinata.cloud/ipfs/CID/hidden.json

    constructor (
        address _tokenAddress,
        bytes32 _wlRoot,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
        ) ERC721A("WearX", "WRX") {
            tokenAddress = IERC20(_tokenAddress);
            wlRoot = _wlRoot;
            setBaseURI(_initBaseURI); 
            setNotRevealedURI(_initNotRevealedUri); 
    }

    // only allows msg.sender(metamask wallet) to be external tx origin 
    modifier userOnly {
        require(tx.origin == msg.sender,"Error: Cannot be called by another contract");
        _;
    }

    
    function teamMint(address _address, uint256 _amount) external userOnly onlyOwner nonReentrant {
        
        _safeMint(_address, _amount);
    }

    // PUMLx token mint 
    function pumlxMint(uint256 _quantity) external payable whenNotPaused nonReentrant {
    
        require(pumlxEnabled, "token mint is currently paused");
        require(msg.value >= 0, "Not enough ether sent");
        require(totalSupply() + _quantity <= maxSupply, "Error: max supply reached");
        require((totalTokenMint[msg.sender] + _quantity) <= pumlxMaxMint, "Error: Max per wallet reached");
        
        tokenAddress.transferFrom(msg.sender, address(this), (_quantity * pumlPrice));
        totalTokenMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // Whitelist mint that requires merkle proof
    function whitelistMint(uint256 _quantity, bytes32[] memory proof) external payable whenNotPaused nonReentrant {
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of whitelist");
        require(wlMintEnabled, "Whitelist mint is currently paused");
        require(msg.value >= (_quantity * wlMintPrice), "Not enough ether sent");
        require(totalSupply() + _quantity <= maxSupply, "Error: max supply reached");
        require((totalWlMint[msg.sender] + _quantity) <= wlMaxMint, "Error: Max per wallet reached");

        totalWlMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // Public mint

    function publicMint(uint256 _quantity) external payable whenNotPaused nonReentrant {
        require(publicMintEnabled, "Public mint is currently paused");
        require(msg.value >= (_quantity * mintPrice), "Not enough ether sent");
        require(totalSupply() + _quantity <= maxSupply, "Error: max supply reached");
        require((totalPublicMint[msg.sender] + _quantity) <= maxMint, "Error: Max per wallet reached");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    

    // verify merkle proof with a buf2hex(keccak256(address)) or keccak256(abi.encodePacked(address))
    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns(bool) {
        return MerkleProof.verify(proof, wlRoot, leaf);
    }

    // returns the baseuri of collection, private
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // override _statTokenId() from erc721a to start tokenId at 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    

    // return tokenUri given the tokenId
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    
    if(revealed == false) {
        return notRevealedUri;
    } else {
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), baseExtension))
        : "";
        }
    }

    // owner updates and functions

    // turn on/off mint phases
    function toggleWlMint() external onlyOwner {
        wlMintEnabled = !wlMintEnabled;
    }

    function togglePublicMint() external onlyOwner {
        publicMintEnabled = !publicMintEnabled;
    }

    function togglePumlxMint() external onlyOwner {
        pumlxEnabled = !pumlxEnabled;
    }
    // reveal metadata + NFT images
    function reveal() external onlyOwner {
      revealed = !revealed;
    }

    // set prices and max
    function setPrice(uint256 _mintPrice) external onlyOwner {
    mintPrice = _mintPrice;
    }

    function setWlPrice(uint256 _mintPrice) external onlyOwner {
    wlMintPrice = _mintPrice;
    }

    function setPumlPrice(uint256 _mintPrice) external onlyOwner {
        pumlPrice = _mintPrice;
    }

    function setmaxMintAmount(uint256 _maxMint) external onlyOwner {
    maxMint = _maxMint;
    }

    function setWlMax(uint256 _wlMaxMint) external onlyOwner {
        wlMaxMint = _wlMaxMint;
    }

    function setPumlMax(uint256 _pumlxMaxMint) external onlyOwner {
        pumlxMaxMint = _pumlxMaxMint;
    }
  
    function pause() public onlyOwner { 
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    // metadata set functions
    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setRoot(bytes32 _root) external onlyOwner nonReentrant {
        wlRoot = _root;
    }

    function setTokenAddress(IERC20 _tokenAddress) external onlyOwner nonReentrant {
        tokenAddress = IERC20(_tokenAddress);
    }

    // withdraw to owner(), i.e only if msg.sender is owner
    function withdraw(address _to) external onlyOwner nonReentrant userOnly{
        payable(_to).transfer(address(this).balance);
    }

    // withdraw ERC20 using tokenAddress 
    function withdrawToken(address _to) external onlyOwner nonReentrant userOnly{
        tokenAddress.transfer(_to, tokenAddress.balanceOf(address(this)));
    }

}