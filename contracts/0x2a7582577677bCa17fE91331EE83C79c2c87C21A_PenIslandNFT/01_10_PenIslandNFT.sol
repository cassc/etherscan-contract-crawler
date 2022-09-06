// SPDX-License-Identifier: MIT
/*


   _______    _______  _____  ___        __      ________  ___            __      _____  ___   ________   
  |   __ "\  /"     "|(\"   \|"  \      |" \    /"       )|"  |          /""\    (\"   \|"  \ |"      "\  
  (. |__) :)(: ______)|.\\   \    |     ||  |  (:   \___/ ||  |         /    \   |.\\   \    |(.  ___  :) 
  |:  ____/  \/    |  |: \.   \\  |     |:  |   \___  \   |:  |        /' /\  \  |: \.   \\  ||: \   ) || 
  (|  /      // ___)_ |.  \    \. |     |.  |    __/  \\   \  |___    //  __'  \ |.  \    \. |(| (___\ || 
 /|__/ \    (:      "||    \    \ |     /\  |\  /" \   :) ( \_|:  \  /   /  \\  \|    \    \ ||:       :) 
(_______)    \_______) \___|\____\)    (__\_|_)(_______/   \_______)(___/    \___)\___|\____\)(________/  
                                                                                                          
                                                                                              
                                             @@@      [email protected]   @@                                       
                                           @   @        @#     @                                    
                                         @  [email protected]                   @                                  
                                        *% @                      @                                 
                                        @  @                @     @                                 
                                        @                   @     @                                 
                                       @                   @ @   @                                  
                                     @@                   @  &@@(                                   
                                   ,@  @                @     @                                     
                                   @ @                @        @                                    
                                   @     @         @(          @                                    
                                       @@@@@@@@                 @                                   
                                       @           @@           @  @@@                              
                                      @  @         @@           @  @@@                              
                                      @  @                      @                                   
                                      @  @                      @                                   
                                     @  @             @     @  @                                    
                                    @  @@              @@@@@   @                                    
                                    @ @@                       @                                    
                                   @                          @                                     
                                  @                          @                                      
                                 @                          @ @@@@@@@@                              
                                @                          @#   @@@@@@    @                         
                               @                          @              @   @                      
                             @                           @                     @                    
                            @                           @                       @                   
                          @                   @@@@    @@@@                       @                  
                        [email protected]                      @@     @@@   @                    @                 
                       @                                        @                 @                 
                    [email protected]                                           @@              @    

Come support the movement for mental health awareness!
https://www.penislandnft.com
https://twitter.com/PenIslandNFT

*/

pragma solidity ^0.8.9;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

error PenIslandNFT__InvalidMintAmount();
error PenIslandNFT__MaxSupplyExceeded();
error PenIslandNFT__InsufficientFunds();
error PenIslandNFT__AllowlistSaleClosed();
error PenIslandNFT__AddressAlreadyClaimed();
error PenIslandNFT__InvalidProof();
error PenIslandNFT__PublicSaleClosed();
error PenIslandNFT__TransferFailed();
error PenIslandNFT__NonexistentToken();

/// @title An NFT collection example with ERC721A
/// @author Koji Mochizuki
/// @notice This contract reduces gas for minting NFTs
/// @dev This contract includes allowlist mint
contract PenIslandNFT is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    /// Type declarations
    enum SaleState {
        Closed,
        AllowlistOnly,
        PublicOpen
    }

    /// State variables
    SaleState private sSaleState;

    uint256 private constant START_TOKEN_ID = 1;
    uint256 private immutable iMaxSupply;
    uint256 private sMintPrice;
    uint256 private sMaxMintAmountPerTx;
    string private sHiddenMetadataUri;
    string private sBaseUri;
    bytes32 private sMerkleRoot;
    bool private sRevealed;

    address artistWallet = 0x27DA19f18bC6c73456d14BA6269803Eee3f439C2;
    address marketerWallet = 0x4b986033694dc34A44F7f104C2aF2C33A76ff680;
    address adminWallet = 0x8BAfB865846Dae412C9efafb13479fDcE5d04ab5;
    address devWallet = 0xC2603Edd7C3A8C833D539CC32B08f142B80640dd;
    address communityWallet = 0xB7e38Fc99E8cF3293cADACd286E475Fee482c4B6;
    address projectWallet = 0xB7e38Fc99E8cF3293cADACd286E475Fee482c4B6;
    uint256 addAN = 125;
    uint256 addBN = 125;
    uint256 addCN = 125;
    uint256 addDN = 125;
    uint256 addEN = 400;
    uint256 addFN = 80;

    mapping(address => bool) private sAllowlistClaimed;

    /// Events
    event Mint(address indexed minter, uint256 amount);

    constructor(
        string memory nftName,
        string memory nftSymbol,
        string memory hiddenMetadataUri,
        uint256 maxSupply,
        uint256 mintPrice,
        uint256 maxMintAmountPerTx
    ) ERC721A(nftName, nftSymbol) {
        iMaxSupply = maxSupply;
        sMintPrice = mintPrice;
        sMaxMintAmountPerTx = maxMintAmountPerTx;
        sHiddenMetadataUri = hiddenMetadataUri;
        sSaleState = SaleState.Closed;
    }

    /// Modifiers
    modifier mintCompliance(uint256 _mintAmount, uint256 _maxMintAmount) {
        if (_mintAmount < 1 || _mintAmount > _maxMintAmount)
            revert PenIslandNFT__InvalidMintAmount();

        if (totalSupply() + _mintAmount > iMaxSupply)
            revert PenIslandNFT__MaxSupplyExceeded();

        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        if (msg.value < sMintPrice * _mintAmount)
            revert PenIslandNFT__InsufficientFunds();

        _;
    }

    /// Functions
    function allowlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount, sMaxMintAmountPerTx)
        mintPriceCompliance(_mintAmount)
    {
        if (sSaleState != SaleState.AllowlistOnly)
            revert PenIslandNFT__AllowlistSaleClosed();

        if (sAllowlistClaimed[_msgSender()])
            revert PenIslandNFT__AddressAlreadyClaimed();

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        if (!MerkleProof.verify(_merkleProof, sMerkleRoot, leaf))
            revert PenIslandNFT__InvalidProof();

        sAllowlistClaimed[_msgSender()] = true;

        _safeMint(_msgSender(), _mintAmount);

        emit Mint(_msgSender(), _mintAmount);
    }

    function publicMint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount, sMaxMintAmountPerTx)
        mintPriceCompliance(_mintAmount)
    {
        if (sSaleState != SaleState.PublicOpen)
            revert PenIslandNFT__PublicSaleClosed();

        _safeMint(_msgSender(), _mintAmount);

        emit Mint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function setProjectWallet(address _address) external onlyOwner {
     projectWallet = _address;
    }

  function withdraw() public onlyOwner nonReentrant {
    uint256 contractBalance = address(this).balance;
    uint256  addANp = (contractBalance * addAN) / 1000;
    uint256  addBNp = (contractBalance * addBN) / 1000;
    uint256  addCNp = (contractBalance * addCN) / 1000;
    uint256  addDNp = (contractBalance * addDN) / 1000;
    uint256  addENp = (contractBalance * addEN) / 1000;
    uint256  addFNp = (contractBalance * addFN) / 1000;

    (bool hs, ) = payable(artistWallet).call{value: addANp}("");
    (hs, ) = payable(marketerWallet).call{value: addBNp}("");
    (hs, ) = payable(adminWallet).call{value: addCNp}("");
    (hs, ) = payable(devWallet).call{value: addDNp}("");
    (hs, ) = payable(communityWallet).call{value: addENp}("");
    (hs, ) = payable(projectWallet).call{value: addFNp}("");
    require(hs);

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);

  }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert PenIslandNFT__NonexistentToken();

        if (sRevealed == false) return sHiddenMetadataUri;

        return
            bytes(_baseURI()).length > 0
                ? string(
                    abi.encodePacked(_baseURI(), _tokenId.toString(), '.json')
                )
                : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return sBaseUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return START_TOKEN_ID;
    }

    /// Getter Functions
    function getSaleState() public view returns (SaleState) {
        return sSaleState;
    }

    function getMaxSupply() public view returns (uint256) {
        return iMaxSupply;
    }

    function getMintPrice() public view returns (uint256) {
        return sMintPrice;
    }

    function getMaxMintAmountPerTx() public view returns (uint256) {
        return sMaxMintAmountPerTx;
    }

    function getHiddenMetadataUri() public view returns (string memory) {
        return sHiddenMetadataUri;
    }

    function getBaseUri() public view returns (string memory) {
        return sBaseUri;
    }

    function getMerkleRoot() public view returns (bytes32) {
        return sMerkleRoot;
    }

    function getRevealed() public view returns (bool) {
        return sRevealed;
    }

    /// Setter Functions
    function setAllowlistOnly() public onlyOwner {
        sSaleState = SaleState.AllowlistOnly;
    }

    function setPublicOpen() public onlyOwner {
        sSaleState = SaleState.PublicOpen;
    }

    function setClosed() public onlyOwner {
        sSaleState = SaleState.Closed;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        sMintPrice = _mintPrice;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        sMaxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        sHiddenMetadataUri = _hiddenMetadataUri;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        sBaseUri = _baseUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        sMerkleRoot = _merkleRoot;
    }

    function setRevealed(bool _state) public onlyOwner {
        sRevealed = _state;
    }
}