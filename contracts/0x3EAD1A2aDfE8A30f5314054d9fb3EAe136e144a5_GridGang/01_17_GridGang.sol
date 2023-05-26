//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
                                      .J5:                                      
                                     7GJ?B?                                     
                                   ^PP:  :5G!                                   
                                 .YG!      ~GP:                                 
                                ?B?          ?BJ.                               
                              ~G5:            .YB!                              
                            :5G~                ^GP^                            
                          .JB?                    7BY.                          
                         !GY.                      .YB7                         
                       ^PP^                          ^PG^                       
                     .YB!                              !BY.                     
                    7BJ.^~~~~~~~~~.          .~~~~~~~~~^.JB?                    
                  ~GP^ ^G!!!!!!!!P7          7P!!!!!!!!G^ :PG~                  
                :5B!   :J77777777J^          ^J77777777J:   !G5:                
               ?BJ      .!~~!!~~!:     ~7     :!~~!!~~!.      ?B?               
             ~G5:       .^~B?!B!^:     :P     :^!B!?B~^.       :5G~             
           :PG~         :~!GYJG7~:.     5~   .:~7GJYG!~:         ~G5:           
         .JB?         ^J?!^:::.^~7J!    !Y  !J7~^.:::^!?J^         ?BJ.         
       .7G5.          .            .     P. .            .          .5G!.       
       [email protected]                               J7                           [email protected]
        ~GP^                 ^7.         ^P     .7^                  7#G~       
          7BY.            :7J?^           5^     ^?J7:             ^G#7         
           .YB?        .!J?~.       ..... 7Y       .~?J!.        .5&J.          
             ^PG~      !!.    ^!7?????????J5???7!^.   .!!       ?#P:            
               ~GP^        :?J7~:.  .^7JJ7^   .:~7J?^         ~BB~              
                 ?BY.    .?J^   .^!?J7^  ^7J?!^.   :?J:     :5#7                
                  .YB7  :G577????7~.  .::.  .~7????7!YG:   ?#Y.                 
                    ^PG~ .:::..    .?J7777J?.    ..:::.  !BP^                   
                      !B5:          .      .           :PB!                     
                        ?BJ.                         .JB?                       
                         :5B7                       7BY.                        
                           ~GG~                   ~GP^                          
                             7#5:               :5B!                            
                              .Y#J.            JBJ                              
                                ^P#7         !B5:                               
                                  !BG^     ^PG~                                 
                                    J&5: .YB7                                   
                                     :P#5BJ.                                    
                                       ~Y:                           
  ________      .__    .___   ________                       
 /  _____/______|__| __| _/  /  _____/_____    ____    ____  
/   \  __\_  __ \  |/ __ |  /   \  ___\__  \  /    \  / ___\ 
\    \_\  \  | \/  / /_/ |  \    \_\  \/ __ \|   |  \/ /_/  >
 \______  /__|  |__\____ |   \______  (____  /___|  /\___  / 
        \/              \/          \/     \/     \//_____/  
*/

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import './SignedAllowance.sol';

interface InfiniteGrid {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract GridGang is ERC721A, Ownable, ERC2981, SignedAllowance {
    using Strings for uint256;

    string private baseURI = 'https://www.infinitegrid.art/api/gang';
    
    bool public isPublicSaleActive = false;
    bool public isSignedSaleActive = false;
    bool public isGridSaleActive = false;
    
    uint256 public MAX_SUPPLY = 3333; 
    uint256 public MAX_PER_WALLET = 10;
    uint256 public PUBLIC_SALE_PRICE = 0.05 ether;
    uint256 public PRESALE_SALE_PRICE = 0.04 ether;
    uint256 public GRID_SALE_PRICE = 0.03 ether;

    address public GRID_ADDRESS = 0x78898ffA059D170F887555d8Fd6443D2ABe4E548; // Infinite Grid

    uint96 public royaltyFraction = 750;

    // Modifiers

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier signedSaleActive() {
        require(isSignedSaleActive, "Presale is not open");
        _;
    }

    modifier gridSaleActive() {
        require(isGridSaleActive, "Grid sale is not open");
        _;
    }

    modifier canMintGang(uint256 numberOfTokens) {
        require(
            _currentIndex + numberOfTokens <= MAX_SUPPLY, 
            "There's not enough gangs left"
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

    modifier hasMinted() {
        require(
            balanceOf(msg.sender) < MAX_PER_WALLET,
            "This address has already minted too many gangs."
        );
        _;
    }

    modifier hasGrid() {
        require(
            InfiniteGrid(GRID_ADDRESS).balanceOf(msg.sender) > 0,
            "You must hold an Infinte Grid to purchase a Gang at this price."
        );
        _;
    }

    constructor() ERC721A("Grid Gang", "GRIDGANG") {
        setRoyaltyInfo(payable(msg.sender), royaltyFraction);
        mintOwner(33);
    }

    function mint(uint256 numberOfTokens)
        external
        payable
        isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
        canMintGang(numberOfTokens)
        publicSaleActive
    {
        _safeMint(msg.sender, numberOfTokens);
    }

    function mintPresale(uint256 numberOfTokens, uint256 nonce, bytes memory signature)
        external
        payable
        isCorrectPayment(PRESALE_SALE_PRICE, numberOfTokens)
        canMintGang(numberOfTokens)
        signedSaleActive
        hasMinted
    {
        _useAllowance(msg.sender, nonce, signature);
        _safeMint(msg.sender, numberOfTokens);
    }

    function mintGrid(uint256 numberOfTokens)
        external
        payable
        isCorrectPayment(GRID_SALE_PRICE, numberOfTokens)
        canMintGang(numberOfTokens)
        gridSaleActive
        hasGrid
        hasMinted
    {
        _safeMint(msg.sender, numberOfTokens);
    }

    function mintOwner(uint256 numberOfTokens) public onlyOwner {
        _safeMint(msg.sender, numberOfTokens);
    }

    function gift(address to, uint256 numberOfTokens) public onlyOwner {
        require(
            _currentIndex + numberOfTokens <= MAX_SUPPLY, 
            "There's not enough gangs left"
        );
        _safeMint(to, numberOfTokens);
    }

    // Public
    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getLastTokenId() external view returns (uint256) {
        return _currentIndex;
    }

    // Admin
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PUBLIC_SALE_PRICE = _price;
    }

    function setPresalePrice(uint256 _price) external onlyOwner {
        PRESALE_SALE_PRICE = _price;
    }

    function setGridPrice(uint256 _price) external onlyOwner {
        GRID_SALE_PRICE = _price;
    }

    function setMaxPerWallet(uint256 _max) external onlyOwner {
        MAX_PER_WALLET = _max;
    }

    function setGridAddress(address _address) external onlyOwner {
        GRID_ADDRESS = _address;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive) external onlyOwner {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setIsSignedSaleActive(bool _isSignedSaleActive) external onlyOwner {
        isSignedSaleActive = _isSignedSaleActive;
    }

    function setIsGridSaleActive(bool _isGridSaleActive) external onlyOwner {
        isGridSaleActive = _isGridSaleActive;
    }

    // signature stuff

    function setAllowancesSigner(address newSigner) external onlyOwner {
        _setAllowancesSigner(newSigner);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString()));
    }

    // override
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //royalties
    // IERC2981
    function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

  // ERC165

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, ERC2981)
    returns (bool)
  {
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }
}