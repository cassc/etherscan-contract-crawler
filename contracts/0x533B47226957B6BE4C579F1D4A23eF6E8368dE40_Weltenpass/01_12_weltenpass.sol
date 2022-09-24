// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
@author smashice.eth
@checkout dtech.vision and hupfmedia.de
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░▒▓▒▓░░▒█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░▓▒▓▒█▒▓▒█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░▒▓░▓▒▓▒▓░▓░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░▒▓░▓▒▓▒▓░▓░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░▓░▓▒▓▒▒▓▓▒▓░▓███████████████░░░▓█████████████▒░░▓█████████████▓░░██░░░░░░░░░░░░█▓░░░
░░░░░░▓░▒░▒░▒██▒▓░░░░░░░░▓█░░░░░░░░░██░░░░░░░░░░░░░░░▒█▒░░░░░░░░░░░░░░░██░░░░░░░░░░░░█▓░░░
░░░░░▒▓████████▒▓░░░░░░░░▓█░░░░░░░░░██▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒█▒░░░░░░░░░░░░░░░██▒▒▒▒▒▒▒▒▒▒▒▒█▓░░░
░░░░▒██▒▒▓▒▒▒██▒▓░░░░░░░░▓█░░░░░░░░░██▓▓▓▓▓▓▓▓▓▓▓▓▓░░▒█▒░░░░░░░░░░░░░░░██▓▓▓▓▓▓▓▓▓▓▓▓█▓░░░
░░░▒▒██▒▓░▒▓░██▒▒░░░░░░░░▓█░░░░░░░░░██░░░░░░░░░░░░░░░▒█▒░░░░░░░░░░░░░░░██░░░░░░░░░░░░█▓░░░
░░░▒▒▓█████████▒░░░░░░░░░▓█░░░░░░░░░▒█▓▓▓▓▓▓▓▓▓▓▓▓▓░░░██▓▓▓▓▓▓▓▓▓▓▓▓▒░░██░░░░░░░░░░░░█▓░░░
░░░▒▓░▒░▒░▒░▒░▒░░░░░░░░░░▒▒░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒░░░░░░░░░░░░▒░░░░
░░░▒▓░▓░▓▒▓▒▓░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░▒░▓░▓▒▓▒▓░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░▓░▓▒▓░░░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░▓▒▓░░░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*/

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721-templates/chirulabsERC721A.sol";

contract Weltenpass is chirulabsERC721A { 
    using SafeMath for uint256;
    using Strings for uint;
    /**
     * @param name The NFT collection name
     * @param symbol The NFT collection symbol
     * @param receiver The wallet address to recieve the royalties
     * @param feeNumerator Numerator of royalty % where Denominator default is 10000
     */
    constructor (
        string memory name, 
        string memory symbol,
        address receiver,
        uint96 feeNumerator
        ) 
    chirulabsERC721A(name, symbol, receiver, feeNumerator)
    {
        fundReciever = receiver;
        _safeMint(0x7Fdd26B919b651054f475E2c995720808B4cB6D7, 5);
        _safeMint(0x745Eb80612B49B22e4244aB06eaE0b37Efb39907, 5);
        _safeMint(0xcEf8F25ac9B5Dc6d889a720bb542B733e91CAfBd, 20);
    }

    address internal fundReciever;
    string public baseURI = "ar://BIQurjAZ3aquMP-0pcxO8vNGLihygNaOlxaDIHvYp_k";

    uint256 constant public MAX_SUPPLY = 500; 
    uint256 public mintPrice = 0.5 ether; 
    bool public mintActive = false;

    /**
     * Allows owner to send aribitrary amounts of tokens to arbitrary adresses
     * Used to get offchain PreSale buyers their tokens
     * @param recipient Array of addresses of which recipient[i] will recieve amount [i]
     * @param amount Array of integers of which amount[i] will be airdropped to recipient[i]
     */
    function airdrop(
        address[] memory recipient,
        uint256[] memory amount
    )
    public onlyOwner
    {
        for(uint i = 0; i < recipient.length; ++i)
        {
            require(totalSupply().add(amount[i]) <= MAX_SUPPLY, "705 no more token available");
            _safeMint(recipient[i], amount[i]);
        }
    }

    /**
     * If mint is active, set it to not active.
     * If mint is not active, set it to active.
     */
    function flipMintState() 
    public onlyOwner
    {
        mintActive = !mintActive;
    }

    /**
     * Allows you to buy tokens
     * @param amount_ amount of tokens to get
     */
    function mint(
        uint256 amount_
    ) 
    public payable 
    {
        require(mintActive, "702 Feature disabled/not active"); 
        require(totalSupply().add(amount_) <= MAX_SUPPLY, "705 no more token available"); 
        require(mintPrice.mul(amount_) <= msg.value, "703 Not enough currency sent"); 

        _safeMint(msg.sender, amount_); 
    }

    /**
     * Allows owner to withdraw all ETH
     */
    function withdraw()
    public onlyOwner 
    {
        payable(fundReciever).transfer(address(this).balance); 
    }

    /**
     * Allows owner to set reciever of withdrawl
     * @param reciever who to recieve the balance of the contract
     */
    function setReciever(address reciever)
    public onlyOwner
    {
        fundReciever = reciever;
    }

    /**
     * Allows owner to set baseURI for all tokens
     * @param newBaseURI_ new baseURI to be used in tokenURI generation
     */
    function setBaseURI(
        string calldata newBaseURI_
    ) external onlyOwner 
    {
        baseURI = newBaseURI_;
    }

    /**
     * Allows owner to set a new mintPrice
     * @param mintPrice_ new mintPrice to be used
     */
    function setMintPrice(
        uint256 mintPrice_
    ) public onlyOwner
    {
        mintPrice = mintPrice_;
    }

    /**
     * Allows owner to set new EIP2981 Royalty share and/or reciever for the whole collection
     * @param reciever_ new royalty reciever to be used
     * @param feeNumerator_ new royalty share in basis points to be used e.g. 100 = 1%
     */
    function setRoyalty(
        address reciever_,
        uint96 feeNumerator_
    ) public onlyOwner
    {
        _setDefaultRoyalty(reciever_, feeNumerator_);
    }

    /**
     * Returns the URI (Link) to the given tokenId
     * @param tokenId_ tokenId of which to get the URI
     */
    function tokenURI(
        uint tokenId_
    ) public override view
    returns (string memory)
    {
        require(_exists(tokenId_), "704 Query for nonexistent token");

        string memory _baseURI = baseURI;
        return bytes(_baseURI).length > 0 ? _baseURI : "https://dtech.vision";
    }

}