// SPDX-License-Identifier: MIT
/** 
    )                                             (                                  
 ( /(                                    (        )\ )             )                 
 )\())          (           (            )\ )    (()/(      )   ( /(      )          
((_)\    (     ))\   (     ))\      (   (()/(     /(_))  ( /(   )\())  ( /(    (     
 _((_)   )\   /((_)  )\   /((_)     )\   /(_))   (_))    )(_)) (_))/   )(_))   )\ )  
| || |  ((_) (_))(  ((_) (_))      ((_) (_) _|   / __|  ((_)_  | |_   ((_)_   _(_/(  
| __ | / _ \ | || | (_-< / -_)    / _ \  |  _|   \__ \  / _` | |  _|  / _` | | ' \)) 
|_||_| \___/  \_,_| /__/ \___|    \___/  |_|     |___/  \__,_|  \__|  \__,_| |_||_| 
*/

pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title HouseOfSatanNFT contracts
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract HouseOfSatanNFT is ERC721, ERC721Enumerable, Ownable, AccessControl, ReentrancyGuard {
    // Using Statements
    using Counters for Counters.Counter;

    // Constants
    uint256 public constant MAX_ADMIN_PREMINT_AMOUNT = 100; // The max that can be minted by admin for promos
    uint256 public constant MAX_TOKEN_PURCHASE = 40; // Max tokens per tx
    bytes32 public constant COUNCIL_ROLE = keccak256("COUNCIL_ROLE"); // Council role for council functions

    // Variables
    uint256 public tokenPrice = 0.0666 ether; // Token Price
    uint256 public maxTokens = 6666; // Max supply
    bool public saleIsActive = false; // Is the sale active?
    string private _baseTokenURI; // The baseURI for tokens
    Counters.Counter public currentAdminPremintedAmount; // The current minted admin premint amount

    /**
     * @dev Constructor for HouseOfSatanNFT contract
     * @param baseURI The initial baseURI used for all tokens
     * @param councilAddress The address the satanic council multisig
     */
    constructor(string memory baseURI, address councilAddress) ERC721("House of Satan", "HOS") {
        _setupRole(DEFAULT_ADMIN_ROLE, councilAddress); // This allows the council address to assign new roles
        _setupRole(COUNCIL_ROLE, councilAddress); // This grants the council address the COUNCIL_ROLE
        _baseTokenURI = baseURI; // Set the initial baseURI
    }

    ////////////////////////////
    /// Overridden Functions ///
    ////////////////////////////

    /**
     * @dev Overrides _beforeTokenTransfer from ERC721, ERC721Enumerable
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Overrides supportsInterface from ERC721, ERC721Enumerable, AccessControl
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Used by the contract to retrieve current baseURI
     * @return string
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //////////////////////////
    /// End User Functions ///
    //////////////////////////

    /**
     * @notice Used to mint Satans
     * @param numberOfTokens The number of tokens to mint
     */
    function mintSatan(uint256 numberOfTokens) external payable nonReentrant {
        uint256 totalSupply = totalSupply();

        require(saleIsActive, "The sale has not started");
        require(numberOfTokens <= MAX_TOKEN_PURCHASE, "Max purchase exceeded");
        require(totalSupply + numberOfTokens <= maxTokens, "Maximum supply has been reached");
        require(tokenPrice * numberOfTokens <= msg.value, "Not enough Eth");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply);
            totalSupply++;
        }
    }

    /////////////////////
    /// Dev Functions ///
    /////////////////////
    
    /**
     * @notice Used to change the price of the token
     * @param newPrice The new price
     */
    function setNewTokenPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    /**
     * @notice Used to increase max tokens
     * @param newMax The new maximum amount of tokens
     */
    function setMaxTokens(uint256 newMax) external onlyOwner {
        require(newMax > totalSupply(), "New maximum cannot be less than current supply!");
        maxTokens = newMax;
    }

    /**
     * @notice Sets the base URI for the token collection
     * @param newBaseURI The new baseURI
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /**
     * @notice Used to enable/disable the token sale
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * @notice Used for minting the initial 100 tokens for promos / giveaways etc
     * @param numberOfTokens How many tokens to mint
     */
    function reserveSatan(uint256 numberOfTokens) external onlyOwner {
        uint256 totalSupply = totalSupply();

        require(
            currentAdminPremintedAmount.current() + numberOfTokens <= MAX_ADMIN_PREMINT_AMOUNT,
            "Cannot pre-mint more"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply);
            currentAdminPremintedAmount.increment();
            totalSupply++;
        }
    }

    /////////////////////////
    /// Council Functions ///
    /////////////////////////

    /**
     * @notice Allows council multisig to withdraw funds from the contract
     */
    function withdraw() external onlyRole(COUNCIL_ROLE) {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}