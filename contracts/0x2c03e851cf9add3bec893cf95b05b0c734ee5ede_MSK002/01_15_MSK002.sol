// contracts/MSK002.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title MaskDAO Word on the Street, codename MSK002
 *
 * Authors: s.imo(at)etherealstudios(dot)io
 * Created: 19.09.2021
 */
contract MSK002 is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    // the maximum number of payable tokens
    uint256 public MAX_PAYABLE_SUPPLY = 512;
    // the mint price in ether for people not owning a gt
    uint256 public constant MINT_PRICE = 0.1024 ether;
    // metadata root uri
    string private _rootURI;
    // the golden ticket pointer
    IERC721Enumerable private _gt;
    // flag to activate the claiming and minting of tokens
    bool private _salesActivated;
    // number of payed tokens
    Counters.Counter private _payedTokens;
    // map of golden tickets that already claimed a token
    mapping(uint256 => bool) private _usedGts;

    /**
     * @dev Constructor
     */
    constructor(address gtAddress)
        ERC721("MaskDAO Word on the Street", "MDWS")
    {
        _salesActivated = false;
        _gt = IERC721Enumerable(gtAddress);
    }

    /**
    * @dev Check if the GT can claim a free token
    */
    function canGoldenTicketClaim(uint256 ticketId) public view returns (bool) {
        return ! _usedGts[ticketId];
    }

    /**
    * @dev Returns true if the caller can claim.
    * In this case the second returned parameter contains a valid GT token ID
    */
    function canClaim() public view returns (bool, uint256) {
        uint256 ticketId  = 0;
        bool    claimFlag = false;
        uint256 numTokens = _salesActivated
                          ? _gt.balanceOf(_msgSender())
                          : 0;

        for(uint256 i = 0; (!claimFlag) && (i < numTokens); i++){
            ticketId  = _gt.tokenOfOwnerByIndex(_msgSender(), i);
            claimFlag = ! _usedGts[ticketId];
        }

        return (claimFlag, ticketId);
    }

    /**
     * @dev Mint a new ticket by providing the token ID
     */
    function claim(uint256 ticketId) public {
        require(_salesActivated,                       "Mint not enabled");
        require(_gt.ownerOf(ticketId) == _msgSender(), "Caller not ticketId owner");
        require(!_usedGts[ticketId],                   "GT already used");

        _usedGts[ticketId] = true;
        _safeMint(_msgSender(), totalSupply());
    }

    /**
    * @dev Mint 'numberOfNfts' new tokens
    */
    function mint() public payable {
        require(_salesActivated,                             "Mint not enabled");
        require(_payedTokens.current() < MAX_PAYABLE_SUPPLY, "Sale has already ended");
        require(MINT_PRICE == msg.value,                     "Ether value sent is not correct");

        _payedTokens.increment();
        _safeMint(_msgSender(), totalSupply());
    }

    /**
    * @dev Function for the DAO to help free minting for a GT owner
    */
    function claimForDAO(address destination, uint256 ticketId) public onlyOwner() {
        require(_gt.ownerOf(ticketId) == destination, "Destination not GT owner");
        require(!_usedGts[ticketId],                  "GT already used");

        _usedGts[ticketId] = true;
        _safeMint(destination, totalSupply());
    }

    /**
     * @dev Toggle the mint activation flag
     */
    function toggleSalesState() public onlyOwner() {
        _salesActivated = !_salesActivated;
    }


    function payedTokens() public view returns (uint256) {
        return _payedTokens.current();
    }

    /**
     * @dev Returns true if the mint has been activated
     */
    function isMintEnabled() public view returns (bool) {
       return _salesActivated && (_payedTokens.current() < MAX_PAYABLE_SUPPLY);
    }

    /**
    * @dev Returns true if the claim has been activated
    */
    function isClaimEnabled() public view returns (bool) {
        return _salesActivated;
    }


    function setBaseURI(string memory uri) external onlyOwner() {
        _rootURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(bytes(_rootURI).length > 0, "Base URI not yet set");
        require(_exists(tokenId),           "Token ID not valid");

        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _rootURI;
    }

    /**
     * @dev Withdraw contract balance to a specific destination
     */
    function withdraw(address _destination) onlyOwner() public returns (bool) {
        uint balance = address(this).balance;
        (bool success, ) = _destination.call{value:balance}("");
        // no need to call throw here or handle double entry attack
        // since only the owner is withdrawing all the balance
        return success;
    }

}