// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17 <0.9.0;
//*********************************************************************************************************************//
//********************************************************************************************************************//
//████████╗ ██║   ██║  ███████╗    ██████╗  ███████╗  █████╗  ████████╗██║   ██║    ███████╗ ██║  ██╗  ██║   ██║ ██║       ██║
//╚══██╔══╝ ██║   ██║  ██╔════╝    ██╔══██╗ ██╔════╝ ██╔══██╗ ╚══██╔══╝██║   ██║    ██╔════╝ ██║ ██═╝  ██║   ██║ ██║       ██║
//   ██║    ██║██║██║  █████╗      ██║  ██║ █████╗   ███████║    ██║   ██║██║██║    ███████╗ ████╗     ██║   ██║ ██║       ██║
//   ██║    ██║   ██║  ██╔══╝      ██║  ██║ ██╔══╝   ██╔══██║    ██║   ██║   ██║    ╚════██║ ██║ ██╗   ██║   ██║ ██║       ██║
//   ██║    ██║   ██║  ███████╗    ██████╔╝ ███████╗ ██║  ██║    ██║   ██║   ██║    ███████║ ██║   ██╗ ████████║ ████████╗ ████████╗
//   ╚═╝    ╚═╝   ╚═╝  ╚══════╝    ╚═════╝  ╚══════╝ ╚═╝  ╚═╝    ╚═╝   ╚═╝   ╚═╝    ╚══════╝ ╚═╝   ╚═╝ ╚═══════╝ ╚═══════╝ ╚═══════╝
//***************************************************************************************************************//
//**************************************************************************************************************//

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './DefaultOperatorFilterer.sol';
//CREATORS: ENGL-LABS Studio
//THE DEATH SKULL the mint gives the right to participate in the extraction of 100 winners among all holders with a prize worth 30% of the total 
//Each month 100 winners will be drawn with rich prizes that can be decided through the DAO and an erc20 token will be created for Staking
//The royalty on the second market will be 10% and a part of this proceeds will be put into play for the holders
contract TheDeathSkullNft is DefaultOperatorFilterer, ERC721A,ERC2981, Ownable, ReentrancyGuard  {
    uint256 tokenCount;
    using Strings for uint256;
    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    string public uriPrefix = '';
    string public uriSuffix = '.json';
    string public hiddenMetadataUri;
    uint256 public cost;
    bool public paused = true;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    bool public whitelistMintEnabled = false;
    bool public preMintEnabled = false;
    bool public openForPublic= false;
    bool public revealed = false;
    uint96 royaltyFeesInBips = 1000;
    constructor(string memory _tokenName,
    string memory _tokenSymbol, 
     uint256 _cost,
     uint256 _maxSupply, 
     uint256 _maxMintAmountPerTx,
     string memory _hiddenMetadataUri, uint96 _royaltyFeesInBips) ERC721A(_tokenName, _tokenSymbol)
    {  
        _setDefaultRoyalty(msg.sender,_royaltyFeesInBips);
        setCost(_cost);
        maxSupply = _maxSupply;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }
    //Mint NFTs
    function airdropNfts(uint256 _mintAmount, address[] calldata wAddresses) public mintCompliance(_mintAmount) onlyOwner {
        require(!paused, "The contract is paused!");
        require(totalSupply() + _mintAmount <= maxSupply, "Cannot exceed max supply");
        for (uint i = 0; i < wAddresses.length; i++) {
            _mintSingleNFT(_mintAmount,wAddresses[i]);
        }
    }
    function _mintSingleNFT(uint256 _mintAmount,address wAddress) private {
        _safeMint(wAddress, _mintAmount);
    }
    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        _;
    }
    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
        _;
    }
    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        // Verify whitelist requirements
        require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
        require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }
    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(!paused, "The contract is paused!");
        require(openForPublic, "The contract is not open to the public!");
        _safeMint(_msgSender(), _mintAmount);
    }
    function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A,ERC2981)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
  //ROYALTY INFO FOR MARKETPLACE
     function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
      _setDefaultRoyalty(_receiver,_royaltyFeesInBips);
    }


    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
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
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        if (revealed == false) {
        return hiddenMetadataUri;
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : '';
    }
    //Enable Presale function
    function setPreMintEnabled(bool _state) public onlyOwner {  
        preMintEnabled = _state;
    }
    //Enable Open Public sell function
    function setOpenPublic(bool _state) public onlyOwner {  
        openForPublic = _state;
    }
    //Enable Whitelist sell function
    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }
    //Set nft reveal
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }
     function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }
    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }
    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }  
    ///sets merkle tree root which determines the whitelisted addresses
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
    
    function _baseURI() internal view override returns (string memory) {
       return uriPrefix;
    }
    
    function withdraw() public onlyOwner  {
        //GRAPHIC ART PERCENTAGE
        (bool hs, ) = payable(0xd31d27D5465C603B58aE8320B643F41ad98d65cE).call{value: address(this).balance * 5 / 100}('');
        require(hs);
        
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
        // =============================================================================
    }

        /// Fallbacks 
    receive() external payable { }
    fallback() external payable { }

}