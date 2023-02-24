/*
------------   --------   -----------     ------    
************  **********  ***********    ********   
----         ----    ---- ----    ---   ----------  
************ ***      *** *********    ****    **** 
------------ ---      --- ---------    ------------ 
****         ****    **** ****  ****   ************ 
----          ----------  ----   ----  ----    ---- 
****           ********   ****    **** ****    **** 
                                                                                                                             
                                                                                          
                                                   
*/
// SPDX-License-Identifier: MIT
// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract FORAtpsNFT is ERC721URIStorage, Ownable, ReentrancyGuard{
    string private _collectionURI;
    string public baseURI;

  
    bool public pausedwl = true;
    bool public pausedgift = false;
    bool public pausedpublic = false;

 
    uint256 public maxGiftMintId = 22;
    uint256 public giftMintId = 1;


    uint256 public maxWhitelistId = 5000;
    uint256 public whitelistId = 23;
    uint256 public constant WHITELIST_SALE_PRICE = 0.045 ether;

    uint256 public maxPublicMint = 5000;
    uint256 public publicMintId = 23;
    uint256 public constant PUBLIC_SALE_PRICE = 0.045 ether;

    // used to validate whitelists
    bytes32 public giftMerkleRoot;
    bytes32 public whitelistMerkleRoot;

    // keep track of those on whitelist who have claimed their NFT
    mapping(address => bool) public giftclaimed;
    mapping(address => bool) public wlclaimed;

    constructor(string memory _baseURI, string memory collectionURI) ERC721("FORA", "FORAtps") {
        setBaseURI(_baseURI);
        setCollectionURI(collectionURI);
    }

    /**
     * @dev validates merkleProof
     */
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier canMint(uint256 numberOfTokens) {
        require(
            publicMintId + numberOfTokens <= maxPublicMint,
            "Not enough tokens remaining to mint"
        );
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    /**
    * @dev 
    */
    function mintGift(
        bytes32[] calldata merkleProof
    )
        public
        isValidMerkleProof(merkleProof, giftMerkleRoot)
        nonReentrant
    {
      require(!pausedgift);  
      require(giftMintId <= maxGiftMintId);
      require(!giftclaimed[msg.sender], "NFT is already claimed by this wallet");
      _mint(msg.sender, giftMintId);
      giftMintId++;
      giftclaimed[msg.sender] = true;
    }

    /**
    * @dev 
    */
    function mintWhitelist(
      bytes32[] calldata merkleProof,
      uint256 numberOfTokens
    )
        public
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(WHITELIST_SALE_PRICE, numberOfTokens)
        nonReentrant
    {
        require(!pausedwl);
        require(numberOfTokens <= 5);
        require(whitelistId <= maxWhitelistId, "minted the maximum # of whitelist tokens");
        require(!wlclaimed[msg.sender], "NFT is already claimed by this wallet"); 
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mint(msg.sender, whitelistId);
            whitelistId++;
        }
        wlclaimed[msg.sender] = true;
    }

    /**
    * @dev 
    */
    function publicMint(
      uint256 numberOfTokens
    )
        public
        payable
        isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
        canMint(numberOfTokens)
        nonReentrant
    {
       require(!pausedpublic);
       for (uint256 i = 0; i < numberOfTokens; i++) {
            _mint(msg.sender, publicMintId);
            publicMintId++;
        }

    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============
    function tokenURI(uint256 tokenId)
      public
      view
      virtual
      override
      returns (string memory)
    {
      require(_exists(tokenId), "ERC721Metadata: query for nonexistent token");
      return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    /**
    * @dev collection URI for marketplace display
    */
    function contractURI() public view returns (string memory) {
        return _collectionURI;
    }


    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function setBaseURI(string memory _baseURI) public onlyOwner {
      baseURI = _baseURI;
    }

    /**
    * @dev set collection URI for marketplace display
    */
    function setCollectionURI(string memory collectionURI) public onlyOwner {
        _collectionURI = collectionURI;
    }

    function setGiftMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        giftMerkleRoot = merkleRoot;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    /**
     * @dev withdraw funds for to specified account
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function pausepublic(bool _state) public onlyOwner {
        pausedpublic = _state;
    }

    function pausewl(bool _state) public onlyOwner {
        pausedwl = _state;
    }

    function pausegift(bool _state) public onlyOwner {
        pausedgift = _state;
    }

     function setwlId(uint256 _newmaxMintAmount) public onlyOwner {
        whitelistId = _newmaxMintAmount;
    }

      function setMaxWlId(uint256 _newmaxMintAmount) public onlyOwner {
        maxWhitelistId = _newmaxMintAmount;
    }
    
    function setpublicId(uint256 _newmaxMintAmount) public onlyOwner {
        publicMintId = _newmaxMintAmount;
    }

    function setMaxPublicId(uint256 _newmaxMintAmount) public onlyOwner {
        maxPublicMint = _newmaxMintAmount;
    }

}