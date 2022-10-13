// SPDX-License-Identifier: GPL-3.0
// Degen Age LSOM v1.0
// @author 7938646E6B73

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LSOM is ERC721A, Ownable {
    using Strings for uint256;
    
    uint256 public MAX_SUPPLY = 252;
    uint256 public MAX_BATCH = 12;
    uint256 public MAX_PUB_BATCH = 6;
    uint256 public GIVEAWAYS = 60;
    uint16 public sale_state;
    bool public paused;
    mapping(address => bool) private whitelist;
    string public BASE_URL = "ipfs://QmaKBSnQhdMGBiELirGpTgaa8qcHE17DQb5do7Rjiqoo8F/";
    string public EXTENSION = ".json";
    
    constructor() ERC721A("Lost Shards of Midrah", "DLSOM", MAX_BATCH, MAX_SUPPLY) {}

    /* PUBLIC METHODS */

    /*
    *   @dev Allows public to mint an LSOM.  Users are only allowed to mint MAX_BATCH
    *   passes per address.
    */
    function pubMint(uint256 quantity) public
    {
        require(!paused);
        require(totalSupply() + quantity <= MAX_SUPPLY, "All shards have been minted");
        require(sale_state == 2, "Sale is currently inactive");
        require(tx.origin == msg.sender, "Contracts are not allowed to mint");
        require(_numberMinted(msg.sender) + quantity <= MAX_PUB_BATCH, "Address is not allowed to mint more than MAX_BATCH");        

        _safeMint(msg.sender, quantity);
    }

    /*
    *   @dev Allows EAP member to mint a Lost Shard.  Users are only allowed to mint MAX_BATCH
    *   passes per address.
    */
    function eapMint(uint256 quantity) public
    {
        require(!paused);
        require(totalSupply() + quantity <= MAX_SUPPLY, "All shards have been minted");
        require(sale_state == 1, "Sale is currently inactive");
        require(whitelist[msg.sender], "Address is not whitelisted");
        require(tx.origin == msg.sender, "Contracts are not allowed to mint");
        require(_numberMinted(msg.sender) + quantity <= MAX_BATCH, "Address is not allowed to mint more than MAX_BATCH");        

        _safeMint(msg.sender, quantity);
    }

    function devMint(uint256 quantity) public onlyOwner {
        require(!paused);
        require(quantity % MAX_BATCH == 0, "Can only mint a multiple of MAX_BATCH");
        require(totalSupply() + quantity <= GIVEAWAYS, "Quantity exceeds number of reserved tokens");
         
        uint256 numBatch = quantity / MAX_BATCH;
        for(uint256 i = 0; i < numBatch; i++){
            _safeMint(msg.sender, MAX_BATCH);
        }
    }

    /* OVERRIDES */

    /*
    *   @dev Returns the tokenURI to the tokens Metadata
    * Requirements:
    * - `_tokenId` Must be a valid token
    * - `BASE_URL` Must be set
    */
    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory){
        return string(abi.encodePacked(BASE_URL, _tokenId.toString(), EXTENSION));
    }

    function setWhitelist(address[] calldata wallets) public onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            whitelist[wallets[i]] = true;
        }
    }

    /*
    *   @dev Sets the state of the sale
    * Requirements:
    * - `_sale_state` Must be an integer
    */
    function setSaleState(uint16 _sale_state) public onlyOwner {
        sale_state = _sale_state;
    }

    /*
    *   @dev Toggles paused state in case of emergency
    */
    function togglePaused() public onlyOwner {
        paused = !paused;
    }

    /*
    *   @dev Sets the BASE_URL for tokenURI
    * Requirements:
    * - `_url` Must be in the form: ipfs://${CID}/
    */
    function setBaseURL(string memory _url) public onlyOwner {
        BASE_URL = _url;
    }
}