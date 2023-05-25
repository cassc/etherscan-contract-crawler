// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


//         WTF Industries X nervous.eth
//  
//   ▄████████    ▄████████    ▄█   ▄█▄    ▄████████ ████████▄          ▄████████    ▄███████▄    ▄████████    ▄████████      
//  ███    ███   ███    ███   ███ ▄███▀   ███    ███ ███   ▀███        ███    ███   ███    ███   ███    ███   ███    ███      
//  ███    █▀    ███    ███   ███▐██▀     ███    █▀  ███    ███        ███    ███   ███    ███   ███    █▀    ███    █▀       
//  ███          ███    ███  ▄█████▀     ▄███▄▄▄     ███    ███        ███    ███   ███    ███  ▄███▄▄▄       ███             
//  ███        ▀███████████ ▀▀█████▄    ▀▀███▀▀▀     ███    ███      ▀███████████ ▀█████████▀  ▀▀███▀▀▀     ▀███████████      
//  ███    █▄    ███    ███   ███▐██▄     ███    █▄  ███    ███        ███    ███   ███          ███    █▄           ███      
//  ███    ███   ███    ███   ███ ▀███▄   ███    ███ ███   ▄███        ███    ███   ███          ███    ███    ▄█    ███      
//  ████████▀    ███    █▀    ███   ▀█▀   ██████████ ████████▀         ███    █▀   ▄████▀        ██████████  ▄████████▀       
//                            ▀                                                                                               
//  ▀████    ▐████▀                                                                                                           
//    ███▌   ████▀                                                                                                            
//     ███  ▐███                                                                                                              
//     ▀███▄███▀                                                                                                              
//     ████▀██▄                                                                                                               
//    ▐███  ▀███                                                                                                              
//   ▄███     ███▄                                                                                                            
//  ████       ███▄                                                                                                           
//                                                                                                                            
//  ███▄▄▄▄      ▄████████    ▄████████  ▄█    █▄   ▄██████▄  ███    █▄     ▄████████
//  ███▀▀▀██▄   ███    ███   ███    ███ ███    ███ ███    ███ ███    ███   ███    ███
//  ███   ███   ███    █▀    ███    ███ ███    ███ ███    ███ ███    ███   ███    █▀ 
//  ███   ███  ▄███▄▄▄      ▄███▄▄▄▄██▀ ███    ███ ███    ███ ███    ███   ███       
//  ███   ███ ▀▀███▀▀▀     ▀▀███▀▀▀▀▀   ███    ███ ███    ███ ███    ███ ▀███████████
//  ███   ███   ███    █▄  ▀███████████ ███    ███ ███    ███ ███    ███          ███
//  ███   ███   ███    ███   ███    ███ ███    ███ ███    ███ ███    ███    ▄█    ███
//   ▀█   █▀    ██████████   ███    ███  ▀██████▀   ▀██████▀  ████████▀   ▄████████▀ 
//                           ███    ███                                                                                    
//
//        work with us: nervous.net // [email protected] // [email protected]
//
//
// -----------------------------------------------------------------------------
//
//
//
// This is Nervous NFT V3. Gas Friendly, Feature Rich, ERC721 future compatible.
//
//                                                 .|\        .-:.
//                                                / / '._____/ /  '.     :          .
//                    .   .              ________/ /    '.__/ /     '.  :         .:'
//                 .-'-.  |  -----/_/_/_/        /'-.     ',='--.     ':        .:'
//        _ .----""""""-^-^--' ()  __     =     /    '-._   '.==='-.  :====.__.:'
//      .'_/  = _ = .-. =  /""/   /_/   /""/   /"'---._  '--u_:.===="|  __:  :'\
//    .'.'/    / / /  /   /__/       = /__/   /_/'.-.' '.  .  . -.-.:|<:::::'   \
//   ..' /     ""  '"'=        //  =         /  """----'  .  (. ' ./#|######'\   \
//  ..--/   =     =        =     =    =     /            .  __ ' /##.'#######\\   \
//  || (-----N-E-R-V-O-U-S---v3------------(--------.___._ (    ;###|#########)---->-"""" ascii art by mga
//  ''  \  _--.-..   __    =          =     \    __    ___'"""-(---"\########//   /
//   ''.-\ \ \ \  \  '\'   .-------._____.   '         \  "\\"" \\###\######//   /
//    '.'.\ \ \ \  \  '\'  \ \   \   \   \\   '   .-    ""''  "" \\.-.\---='/   /
//      '._\ \ \ \  \  '\'  \ \   \   \   \\ = '         \""'-\".-7-. "\"" /-._/
//          '-^-\_\__\  '\'  \ \   \   \   \\   '   .' .---"""""(__  "-_\__---""--.
//                    """"""""--^---^___\___\\   :._____------""""""""  "-_        "
//                                           """""
//
// Thanks to Galactic and 0x420 for their gas friendly ERC721S implementation.
//
//
//
// -----------------------------------------------------------------------------
//

import "./ERC721S.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract NervousNFT is
    ERC721Sequential,
    ReentrancyGuard,
    PaymentSplitter,
    Ownable
{
    using Strings for uint256;
    using ECDSA for bytes32;
    mapping(bytes => uint256) private usedTickets;

    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant MINT_PRICE = 0.069 ether;

    string public baseURI;

    bool public mintingEnabled = true;

    uint256 public startPresaleDate = 1641855600; // January 10, 6 pm EST
    uint256 public endPresaleDate = 1641916800; // January 11, 11 am EST

    uint256 public startFreeSaleDate = 1641834000; // January 10, 12 pm EST
    uint256 public endFreeSaleDate = 1641848400; // January 10,  4 pm EST

    uint256 public startPublicMintDate = 1641963600; // January 11, 12 pm EST

    uint256 public constant MAX_GIFTS = 350;
    uint256 public numberOfGifts;

    uint256 public constant MAX_PRESALE_MINTS = 3;
    uint256 public constant MAX_FREE_MINTS = 1;
    uint256 public constant MAX_MINTS = 10;

    address public preSaleSigner;
    address public freeSaleSigner;


    string public constant R =
        "We are Nervous. Are you? Let us help you with your next NFT Project -> [email protected]";

    constructor(
        string memory name,
        string memory symbol,
        string memory _initBaseURI,
        address _preSaleSigner,
        address _freeSaleSigner,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721Sequential(name, symbol) PaymentSplitter(payees, shares) {
       
        baseURI = _initBaseURI;

        preSaleSigner = _preSaleSigner;
        freeSaleSigner = _freeSaleSigner;
    }

    /* Minting */

    function calculatePrice() public view returns (uint256) {
        if (hasFreeSaleStarted()) {
            return 0;
        } else {
            return MINT_PRICE;
        }
    }

    function toggleMinting() public onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function mint(uint256 numTokens, bytes memory pass)
        public
        payable
        nonReentrant
    {
        require(mintingEnabled == true, "Minting isn't enabled");
        
        uint256 price = MINT_PRICE;

        if (hasPreSaleStarted() || hasFreeSaleStarted()) {
            bytes memory ticket = pass;
            
            uint256 mintablePresale;

            (mintablePresale, price) = validateTicket(ticket);

            require(numTokens <= mintablePresale, "Minting Too Many Presale");
            useTicket(ticket, numTokens);
        } else {
            
            require(hasPublicSaleStarted(), "Sale hasn't started");
            require(
                numTokens > 0 && numTokens <= MAX_MINTS,
                "Machine can dispense a minimum of 1, maximum of 10 tokens"
            );
        }

        require(totalMinted() + numTokens <= MAX_SUPPLY, "Sold Out");

        require(
            msg.value >= numTokens * price,
            "Insufficient Payment: Amount of Ether sent is not correct. "
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    /* Ticket Handling */

    // Thanks for 0x420 and their solid implementation of tickets in the OG:DG drop.

    function getHash() internal view returns (bytes32) {
        return keccak256(abi.encodePacked("NERVOUS", msg.sender));
    }

    function  recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function validateTicket(bytes memory pass)
        internal
        view
        returns (uint256, uint256)
    {
        bytes32 hash = getHash();
        
        address signer = recover(hash, pass);
       
        uint256 mintablePresale;
        uint256 price = MINT_PRICE;
        if (signer == freeSaleSigner) {
            
            require(hasFreeSaleStarted(), "Freesale isn't active");
            mintablePresale = 1;
            price = 0;
        } else if (signer == preSaleSigner) {
            require(hasPreSaleStarted(), "Presale isn't active");
            mintablePresale = MAX_PRESALE_MINTS;
        } else {
            revert("Invalid ticket. Not on any presale lists");
        }
        require(usedTickets[pass] < mintablePresale, "Ticket already used");
        return (mintablePresale - usedTickets[pass], price);
    }

    function useTicket(bytes memory pass, uint256 quantity) internal {
        usedTickets[pass] += quantity;
    }

    /* Sale state */

    function hasPublicSaleStarted() public view returns (bool) {
        if (startPublicMintDate <= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    function hasPreSaleStarted() public view returns (bool) {
        if (
            startPresaleDate <= block.timestamp &&
            endPresaleDate >= block.timestamp
        ) {
            return true;
        } else {
            return false;
        }
    }

    function hasFreeSaleStarted() public view returns (bool) {
        if (
            startFreeSaleDate <= block.timestamp &&
            endFreeSaleDate >= block.timestamp
        ) {
            return true;
        } else {
            return false;
        }
    }

    /* set the dates */

    function setFreesaleDate(
        uint256 _startFreeSaleDate,
        uint256 _endFreeSaleDate
    ) external onlyOwner {
        startFreeSaleDate = _startFreeSaleDate;
        endFreeSaleDate = _endFreeSaleDate;
    }

    function setPresaleDate(uint256 _startPresaleDate, uint256 _endPresaleDate)
        external
        onlyOwner
    {
        startPresaleDate = _startPresaleDate;
        endPresaleDate = _endPresaleDate;
    }

    function setPublicSaleDate(uint256 _startPublicMintDate)
        external
        onlyOwner
    {
        startPublicMintDate = _startPublicMintDate;
    }

    /* set signers */

    function setPreSaleSigner(address _preSaleSigner) public onlyOwner {
        preSaleSigner = _preSaleSigner;
    }

    function setFreeSaleSigner(address _FreeSaleSigner) public onlyOwner {
        freeSaleSigner = _FreeSaleSigner;
    }

    // /* Magic */

    function magicMint(uint256 numTokens) external onlyOwner {
        require(
            totalMinted() + numTokens <= MAX_SUPPLY,
            "Exceeds maximum token supply."
        );

        require(
            numberOfGifts + numTokens <= MAX_GIFTS,
            "Exceeds maximum allowed gifts"
        );

        require(
            numTokens > 0 && numTokens <= 100,
            "Machine can dispense a minimum of 1, maximum of 100 tokens"
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    /* Utility */

    /* URL Utility */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    /* eth handlers */

    function withdraw(address payable account) public virtual {
        release(account);
    }

    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }
}