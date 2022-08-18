// SPDX-License-Identifier: GPL-3.0
// Fantazya NFT Contract v1
// @author twitter: _syndk8

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Fantazya is ERC721A, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;
    using ECDSA for bytes;

    uint256 public MAX_SUPPLY = 3333;
    uint256 public MAX_OG = 300;
    uint256 public MAX_BATCH = 5;
    uint256 public MAX_WL = 3;
    uint256 public GIVEAWAYS = 100;
    uint256 public SALE_PRICE = 0.06 ether;
    uint16 public sale_state;
    bool public paused;
    bool public revealed;
    string public BASE_URL;
    string public PROVENANCE = "";
    bytes32 public EXTENSION = ".json";
    mapping(address => bool) private freemints;
    mapping(address => bool) private devs;
    address public PRIMARY = 0x88b01C2bB126de410b4b102F78214153B22e3cD0;
    address public PUB_KEY;

    constructor() ERC721A("Fantazya NFT", "FNFT", MAX_BATCH, MAX_SUPPLY) {
        devs[msg.sender] = true;
        devs[PRIMARY] = true;
    }

    modifier devOnly {
        require(devs[msg.sender]);
        _;
    }

    /* PUBLIC METHODS */

    function pubMint(uint256 quantity) public payable
    {
        require(!paused);
        require(totalSupply() + quantity <= MAX_SUPPLY, "All tokens have been minted");
        require(sale_state == 3, "Public sale is currently inactive");
        require(tx.origin == msg.sender, "Contracts are not allowed to mint");
        require(msg.value == SALE_PRICE * quantity, "Incorrect amount of ether");
        require(_numberMinted(msg.sender) + quantity <= MAX_BATCH, "Address is not allowed to mint more than MAX_BATCH");

        _safeMint(msg.sender, quantity);
    }

    function preMint(uint256 quantity) public onlyOwner {   // address must not be the genesis safe
        require(!paused);
        require(quantity % MAX_BATCH == 0, "Can only mint a multiple of MAX_BATCH");
        require(totalSupply() + quantity <= GIVEAWAYS, "Quantity exceeds number of reserved tokens");
         
        uint256 numBatch = quantity / MAX_BATCH;
        for(uint256 i = 0; i < numBatch; i++){
            _safeMint(msg.sender, MAX_BATCH);
        }
    }

    function presale(bytes calldata _signature, uint256 quantity) public payable { // add bytes calldata _signature
        require(!paused);
        require(totalSupply() + quantity <= MAX_SUPPLY, "All tokens have been minted");
        require(sale_state == 2, "Presale is currently inactive");
        require(isWhitelisted(_signature, msg.sender), "Address is not whitelisted");
        require(tx.origin == msg.sender, "Contracts are not allowed to mint");
        require(msg.value == SALE_PRICE * quantity, "Incorrect amount of ether");
        require(_numberMinted(msg.sender) + quantity <= MAX_WL, "Address is not allowed to mint more than MAX_WL"); // if max batch > 1, need to check uint instead of bool
        
        _safeMint(msg.sender, quantity);
    }

    function ogMint(bytes calldata _signature, uint256 quantity) public payable {  // add bytes calldata _signature
        require(!paused);
        require(totalSupply() + quantity <= MAX_OG + GIVEAWAYS, "All OG tokens have been minted");
        require(sale_state == 1, "Presale is currently inactive");
        require(isWhitelisted(_signature, msg.sender), "Address is not whitelisted");
        require(tx.origin == msg.sender, "Contracts are not allowed to mint");
        if(!freemints[msg.sender]){ // non freemint addresses must pay to mint
            require(msg.value == SALE_PRICE * quantity, "Incorrect amount of ether");
        }
        require(_numberMinted(msg.sender) + quantity <= MAX_WL, "Address is not allowed to mint more than MAX_WL"); // if max batch > 1, need to check uint instead of bool
        
        _safeMint(msg.sender, quantity);
    }

    /* OVERRIDES */

    /*
    *   @dev Returns the tokenURI to the tokens Metadata
    * Requirements:
    * - `_tokenId` Must be a valid token
    * - `BASE_URL` Must be set
    */
    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory){
        return !revealed ? BASE_URL : string(abi.encodePacked(BASE_URL, _tokenId.toString(), EXTENSION));
    }

    /* PRIVATE METHODS */

    /**
    *   @dev function to verify address is whitelisted
    *   @param _signature - used to verify address
    *   @param _user - address of connected user
    *   @return bool verification
    */
    function isWhitelisted(bytes calldata _signature, address _user) private view returns(bool) {
        return abi.encode(_user,MAX_SUPPLY).toEthSignedMessageHash().recover(_signature) == PUB_KEY;
    }

    function setFreemints(address[] calldata wallets) public devOnly {
        for(uint256 i = 0; i < wallets.length; i++){
            freemints[wallets[i]] = true;
        }
    }

    /* ADMIN ONLY METHODS */

    function addDev(address _account) public onlyOwner {
        require(!devs[_account],"Developer already exists");
        devs[_account] = true;
    }

    function removeDev(address _account) public onlyOwner {
        require(devs[_account], "Developer doesn't exist");
        devs[_account] = false;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setProvenance(string memory _provenance) public devOnly {
        PROVENANCE = _provenance;
    }

    function setSalePrice(uint256 _salePrice) public onlyOwner {
        SALE_PRICE = _salePrice;
    }

    function setPubkey(address _key) public devOnly {
        PUB_KEY = _key;
    }

    function setPrimaryAddress(address _primary) public onlyOwner {
        PRIMARY = _primary;
    }

    /*
    *   @dev Sets the state of the public sale
    * Requirements:
    * - `_sale_state` Must be an integer
    */
    function setSaleState(uint16 _sale_state) public devOnly {
        sale_state = _sale_state;
    }

    /*
    *   @dev Toggles paused state in case of emergency
    */
    function togglePaused() public devOnly {
        paused = !paused;
    }

    /*
    *   @dev Sets the BASE_URL for tokenURI
    * Requirements:
    * - `_url` Must be in the form: ipfs://${CID}/
    */
    function setBaseURL(string memory _url) public devOnly {
        BASE_URL = _url;
    }

    function setRevealed(string memory _url, bool _revealed) public devOnly {
        BASE_URL = _url;
        revealed = _revealed;
    }

    function withdraw() public payable onlyOwner {
        (bool os,)= payable(PRIMARY).call{value:address(this).balance}("");
        require(os);
    }
}