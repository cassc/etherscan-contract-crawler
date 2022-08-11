// SPDX-License-Identifier: GPL-3.0
// Degen Age Early Adopters Pass v1.0
// @author 7938646E6B73

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EAP is ERC721A, Ownable {
    using Strings for uint256;
    
    uint256 public MAX_SUPPLY = 3000;
    uint256 public MAX_BATCH = 5;
    uint256 public SALE_PRICE = 0.008 ether;
    uint256 public GIVEAWAYS = 15;
    uint16 public sale_state;
    bool public paused;
    string public BASE_URL = "ipfs://QmRNnsqaP2qASYWVybUGnQhnXT3qrwZU6RopsvSTXc6khz/unrevealed.json";
    bytes32 public EXTENSION = ".json";
    bool public revealed;
    address public PRIMARY = 0x103EcE5B498b9c425295F58148Aa5bdAc7575708;
    address public DEV;
    mapping(address => bool) private admins;
    mapping(address => bool) private whitelist;
    
    constructor() ERC721A("Degen Age Early Adopters Pass", "EAP", MAX_BATCH, MAX_SUPPLY) {
        admins[msg.sender] = true;
        DEV = msg.sender;
    }

    modifier adminOnly {
        require(admins[msg.sender]);
        _;
    }

    /* PUBLIC METHODS */

    /*
    *   @dev Allows public to mint an Early Adopters Pass.  Users are only allowed to mint MAX_BATCH
    *   passes per address.
    */
    function pubMint(uint256 quantity) public payable
    {
        require(!paused);
        require(totalSupply() + quantity <= MAX_SUPPLY, "All passes have been minted");
        require(sale_state == 2, "Sale is currently inactive");
        require(msg.value == SALE_PRICE * quantity, "Incorrect amount of Ether");
        require(tx.origin == msg.sender, "Contracts are not allowed to mint");
        require(_numberMinted(msg.sender) + quantity <= MAX_BATCH, "Address is not allowed to mint more than MAX_BATCH");        

        _safeMint(msg.sender, quantity);
    }

    /*
    *   @dev Allows WL member to mint an Early Adopters Pass.  Users are only allowed to mint MAX_BATCH
    *   passes per address.
    */
    function presale(uint256 quantity) public payable
    {
        require(!paused);
        require(totalSupply() + quantity <= MAX_SUPPLY, "All passes have been minted");
        require(sale_state == 1, "Sale is currently inactive");
        require(whitelist[msg.sender], "User is not whitelisted");
        require(msg.value == SALE_PRICE * quantity, "Incorrect amount of Ether");
        require(tx.origin == msg.sender, "Contracts are not allowed to mint");
        require(_numberMinted(msg.sender) + quantity <= MAX_BATCH, "Address is not allowed to mint more than MAX_BATCH");        

        _safeMint(msg.sender, quantity);
    }

    // Need to change this function
    // Address must be admin and PRIMARY address
    function devMint(uint256 quantity) public adminOnly {
        require(!paused);
        require(msg.sender == DEV, "Address is not allowed to mint.");
        require(quantity % MAX_BATCH == 0, "Can only mint a multiple of MAX_BATCH");
        require(totalSupply() + quantity <= GIVEAWAYS, "Quantity exceeds number of reserved tokens");
         
        uint256 numBatch = quantity / MAX_BATCH;
        for(uint256 i = 0; i < numBatch; i++){
            _safeMint(msg.sender, MAX_BATCH);
        }
    }

    function addAdmin(address _account) public adminOnly {
        require(!admins[_account],"Admin already exists");
        admins[_account] = true;
    }

    function removeAdmin(address _account) public adminOnly {
        require(admins[_account],"Admin does not exist");
        admins[_account] = false;
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

    function setWhitelist(address[] calldata addresses) public adminOnly {
        uint256 _length = addresses.length;
        for(uint256 i = 0; i < _length; i++){
            whitelist[addresses[i]] = true;
        }
    }

    function setPrimaryAddress(address _primary) public adminOnly {
        PRIMARY = _primary;
    }

    /*
    *   @dev Sets the state of the sale
    * Requirements:
    * - `_sale_state` Must be an integer
    */
    function setSaleState(uint16 _sale_state) public adminOnly {
        sale_state = _sale_state;
    }

    /*
    *   @dev Toggles paused state in case of emergency
    */
    function togglePaused() public adminOnly {
        paused = !paused;
    }

    function reveal(string memory _url) public adminOnly {
        BASE_URL = _url;
        revealed = true;
    }

    function setSalePrice(uint256 _price) public adminOnly {
        SALE_PRICE = _price;
    }

    /*
    *   @dev Sets the BASE_URL for tokenURI
    * Requirements:
    * - `_url` Must be in the form: ipfs://${CID}/
    */
    function setBaseURL(string memory _url) public adminOnly {
        BASE_URL = _url;
    }

    // used in case someone enters a payable amount
    // for the free mint so they may be refunded
    function withdraw() public payable adminOnly {
        (bool os,)= payable(PRIMARY).call{value:address(this).balance}("");
        require(os);
    }
}