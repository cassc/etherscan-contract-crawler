// SPDX-License-Identifier: GPL-3.0
// Fantazya NFT Contract v2.0
// @author twitter: _syndk8

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Fantazya is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 4444;
    uint256 public MAX_BATCH = 10;
    uint256 public MAX_WL = 2;
    uint16 public sale_state;
    bool public paused;
    bool public revealed;
    string public BASE_URL = "ipfs://QmTky3BcPcpsSnXvvNni4AGc6xgM3ghTTNPJhFgTbJzAuj/unrevealed.json";
    bytes32 public EXTENSION = ".json";
    mapping(address => bool) private freemints;
    address public PRIMARY = 0xEdE72391f988707daFf883E78941C4Ee13c90cAE;

    constructor() ERC721A("Fantazya NFT: The Revival", "FNFTR", MAX_BATCH, MAX_SUPPLY) {}

    /* PUBLIC METHODS */

    function pubMint(uint256 quantity) public
    {
        require(!paused);
        require(totalSupply() + quantity <= MAX_SUPPLY, "All tokens have been minted");
        require(sale_state == 2, "Public sale is currently inactive");
        require(tx.origin == msg.sender, "Contracts are not allowed to mint");
        require(_numberMinted(msg.sender) + quantity <= MAX_WL, "Address is not allowed to mint more than MAX_WL");

        _safeMint(msg.sender, quantity);
    }

    // airdrops quantity of NFTs to destination wallet
    function airdrop(address[] calldata wallets, uint256 quantity) public onlyOwner {
        require(!paused);
        for(uint256 i = 0; i < wallets.length; i++){
            _safeMint(wallets[i],quantity);
        }
    }

    // presale is free mint, no need for payable here
    function presale(uint256 quantity) public {
        require(!paused);
        require(totalSupply() + quantity <= MAX_SUPPLY, "All tokens have been minted");
        require(sale_state == 1, "Presale is currently inactive");
        require(freemints[msg.sender], "Address is not whitelisted");
        require(tx.origin == msg.sender, "Contracts are not allowed to mint");
        require(_numberMinted(msg.sender) + quantity <= MAX_WL, "Address is not allowed to mint more than MAX_WL");
        
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

    function setFreemints(address[] calldata wallets) public onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            freemints[wallets[i]] = true;
        }
    }

    /* ADMIN ONLY METHODS */

    function setMaxSupply(uint256 _supply) public onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setPrimaryAddress(address _primary) public onlyOwner {
        PRIMARY = _primary;
    }

    /*
    *   @dev Sets the state of the public sale
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

    function setRevealed(string memory _url, bool _revealed) public onlyOwner {
        BASE_URL = _url;
        revealed = _revealed;
    }

    function withdraw() public payable onlyOwner {
        (bool os,)= payable(PRIMARY).call{value:address(this).balance}("");
        require(os);
    }
}