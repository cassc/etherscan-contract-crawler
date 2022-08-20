// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;
pragma abicoder v2;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/********************************************************************************************************
                                                                                                          
8 888888888o.      8 8888888888    8 8888 `8.`8888.      ,8'          .8.                                 
8 8888    `^888.   8 8888          8 8888  `8.`8888.    ,8'          .888.                                
8 8888        `88. 8 8888          8 8888   `8.`8888.  ,8'          :88888.                               
8 8888         `88 8 8888          8 8888    `8.`8888.,8'          . `88888.                              
8 8888          88 8 888888888888  8 8888     `8.`88888'          .8. `88888.                             
8 8888          88 8 8888          8 8888     .88.`8888.         .8`8. `88888.                            
8 8888         ,88 8 8888          8 8888    .8'`8.`8888.       .8' `8. `88888.                           
8 8888        ,88' 8 8888          8 8888   .8'  `8.`8888.     .8'   `8. `88888.                          
8 8888    ,o88P'   8 8888          8 8888  .8'    `8.`8888.   .888888888. `88888.                         
8 888888888P'      8 888888888888  8 8888 .8'      `8.`8888. .8'       `8. `88888.                        
                                                                                                          
`8.`8888.      ,8'          .8.            d888888o. 8888888 8888888888 8 888888888o.      ,o888888o.     
 `8.`8888.    ,8'          .888.         .`8888:' `88.     8 8888       8 8888    `88.  . 8888     `88.   
  `8.`8888.  ,8'          :88888.        8.`8888.   Y8     8 8888       8 8888     `88 ,8 8888       `8b  
   `8.`8888.,8'          . `88888.       `8.`8888.         8 8888       8 8888     ,88 88 8888        `8b 
    `8.`88888'          .8. `88888.       `8.`8888.        8 8888       8 8888.   ,88' 88 8888         88 
    .88.`8888.         .8`8. `88888.       `8.`8888.       8 8888       8 888888888P'  88 8888         88 
   .8'`8.`8888.       .8' `8. `88888.       `8.`8888.      8 8888       8 8888`8b      88 8888        ,8P 
  .8'  `8.`8888.     .8'   `8. `88888.  8b   `8.`8888.     8 8888       8 8888 `8b.    `8 8888       ,8P  
 .8'    `8.`8888.   .888888888. `88888. `8b.  ;8.`8888     8 8888       8 8888   `8b.   ` 8888     ,88'   
.8'      `8.`8888. .8'       `8. `88888. `Y8888P ,88P'     8 8888       8 8888     `88.    `8888888P'     
                                                                                                                                                                                                                                                     
*********************************************************************************************************
 DEVELOPER James Iacabucci
 ARTIST Bruce Sulzberg
********************************************************************************************************/

contract DeixaXastroCollection is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public goldListMerkleRoot;
    mapping(address => bool) public goldListClaimed;

    bytes32 public freeListMerkleRoot;
    mapping(address => bool) public freeListClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    string public contractMetadataUri;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public mintLimit;
    uint256 public maxMintAmountPerTx;

    bool public paused = true;
    bool public revealed = false;
    bool public released = false;

    bool public freeListMintEnabled = false;
    bool public goldListMintEnabled = true;
    bool public preSaleMintEnabled = false;

    string[] public promotionCodes;
    mapping(string => uint256) public promotionCodeToSales;
    mapping(string => bool) private promotionCodeRegistered;

    address public daoWallet;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _mintLimit,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri,
        string memory _contractMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        maxSupply = _maxSupply;
        mintLimit = _mintLimit;
        daoWallet = owner();
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
        setContractMetadataUri(_contractMetadataUri);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        uint256 newSupply = totalSupply() + _mintAmount;
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "You can not mint this many items");
        require(newSupply <= maxSupply && newSupply <= mintLimit, "This purchase exceeds the maximum number of NFTS allowed for this sale");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "You did not send enough ETH to complete this purchase");
        _;
    }

    function recordPromotedSale(string memory _promotionCode, uint256 _saleAmount) internal {
        if (promotionCodeRegistered[_promotionCode] == false) {
            promotionCodes.push(_promotionCode);
            promotionCodeRegistered[_promotionCode] = true;
        }
        promotionCodeToSales[_promotionCode] += _saleAmount;
    }

    function promotionCodeCount() external view returns (uint256) {
        return promotionCodes.length;
    }

    function freeListMint(
        uint256 _mintAmount,
        string memory _promotionCode,
        bytes32[] calldata _merkleProof
    ) public payable mintCompliance(_mintAmount) {
        // Verify Free List requirements
        require(freeListMintEnabled, "The Free Mint sale is not open!");
        require(!freeListClaimed[_msgSender()], "Your address has already claimed its Free List NFT!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, freeListMerkleRoot, leaf), "This is an invalid Free List proof!");

        freeListClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
        recordPromotedSale(_promotionCode, msg.value);
    }

    function goldListMint(
        uint256 _mintAmount,
        string memory _promotionCode,
        bytes32[] calldata _merkleProof
    ) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        // Verify Gold List requirements
        require(goldListMintEnabled, "The Gold List sale is not active!");
        require(!goldListClaimed[_msgSender()], "Your address has already claimed its Gold List NFT!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, goldListMerkleRoot, leaf), "This is an invalid Gold List proof!");

        goldListClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
        recordPromotedSale(_promotionCode, msg.value);
    }

    function mint(uint256 _mintAmount, string memory _promotionCode) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(!paused, "The sale is paused!");
        _safeMint(_msgSender(), _mintAmount);
        recordPromotedSale(_promotionCode, msg.value);
    }

    function crossmint(
        address _to,
        uint256 _mintAmount,
        string memory _promotionCode
    ) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(!paused, "The sale is paused!");
        require(msg.sender == 0xdAb1a1854214684acE522439684a145E62505233, "This function is for Crossmint only.");
        _safeMint(_to, _mintAmount);
        recordPromotedSale(_promotionCode, msg.value);
    }

    /*
     * @desc batch miniting facilitates distributions to founders and partners
     * only by Owner, gas fees only
     */
    function mintBatch(
        address[] memory addresses,
        uint256[] memory amounts,
        string[] memory promocodes
    ) public onlyOwner {
        require(!paused, "The sale is paused!");
        require(addresses.length == amounts.length, "Address, Amount and PromoCode list lengths do not match");

        uint256 newSupply = totalSupply();
        for (uint256 i = 0; i < addresses.length; i++) {
            newSupply += amounts[i];
        }
        require(newSupply <= maxSupply && newSupply <= mintLimit, "This batch exceeds the maximum number of NFTS allowed for this sale");

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amounts[i]);
            recordPromotedSale(promocodes[i], amounts[i] * cost);
        }
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    latestOwnerAddress = ownership.addr;
                }

                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;
                    ownedTokenIndex++;
                }
            }
            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: the token specified does not exist");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";
    }

    function contractURI() public view returns (string memory) {
        return contractMetadataUri;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMintLimit(uint256 _mintLimit) public onlyOwner {
        mintLimit = _mintLimit;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setSaleParameters(
        uint256 _cost,
        uint256 _maxMintAmountPerTx,
        uint256 _mintLimit
    ) public onlyOwner {
        cost = _cost;
        mintLimit = _mintLimit;
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setContractMetadataUri(string memory _contractMetadataUri) public onlyOwner {
        contractMetadataUri = _contractMetadataUri;
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

    function setReleased(bool _state) public onlyOwner {
        released = _state;
    }

    function setFreeListMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        freeListMerkleRoot = _merkleRoot;
    }

    function setFreeListMintEnabled(bool _state) public onlyOwner {
        freeListMintEnabled = _state;
    }

    function setGoldListMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        goldListMerkleRoot = _merkleRoot;
    }

    function setGoldListMintEnabled(bool _state) public onlyOwner {
        goldListMintEnabled = _state;
    }

    function setPreSaleMintEnabled(bool _state) public onlyOwner {
        preSaleMintEnabled = _state;
    }

    function setDaoWallet(address _walletAddress) public onlyOwner {
        daoWallet = _walletAddress;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(daoWallet).call{value: address(this).balance}("");
        require(os, "Withdraw Failed!");
    }
}