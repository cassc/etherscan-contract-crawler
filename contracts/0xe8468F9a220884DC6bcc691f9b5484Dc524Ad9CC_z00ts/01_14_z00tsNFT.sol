// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;
/*
                                                     
@@@@@@@@   @@@@@@@@    @@@@@@@@   @@@@@@@   @@@@@@   
@@@@@@@@  @@@@@@@@@@  @@@@@@@@@@  @@@@@@@  @@@@@@@   
     @@!  @@!   @@@@  @@!   @@@@    @@!    [email protected]@       
    [email protected]!   [email protected]!  @[email protected][email protected]  [email protected]!  @[email protected][email protected]    [email protected]!    [email protected]!       
   @!!    @[email protected] @! [email protected]!  @[email protected] @! [email protected]!    @!!    [email protected]@!!    
  !!!     [email protected]!!!  !!!  [email protected]!!!  !!!    !!!     [email protected]!!!   
 !!:      !!:!   !!!  !!:!   !!!    !!:         !:!  
:!:       :!:    !:!  :!:    !:!    :!:        !:!   
 :: ::::  ::::::: ::  ::::::: ::     ::    :::: ::   
: :: : :   : : :  :    : : :  :      :     :: : :                                                        
*/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract z00ts is
    ERC721Enumerable,
    ReentrancyGuard,
    Ownable
{
    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant MINT_PRICE = 0.033 ether;
    uint256 public constant MINT_CAP_PER_WALLET = 20;
    
    bool public saleIsActive = false;
    bool public saleCompleted = false;

    uint256 lastTokenId;
    string private _baseTokenURI;

    event Z00tMinted(address _minter, uint256 _mintAmount, uint256 lastId);
    event SaleCompleted();
    event WithdrawFinished(address _receiver, uint256 amount);

    constructor(
        string memory baseURI
    ) ERC721("z00ts NFT", "Z00T") {
        _baseTokenURI = baseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    //only call if you never want to mint anymore z000000ts
    function setSaleCompleted() public onlyOwner {
        saleCompleted = true;
        emit SaleCompleted();
    }

    modifier onlyIfSaleActive() {
        require(!saleCompleted, "SALE_NOT_ACTIVE");
        require(saleIsActive, "SALE_NOT_ACTIVE");
         _;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
    * Mints z00ts
    */
    function mint(uint256 numberOfTokens) public nonReentrant onlyIfSaleActive payable {
        require(numberOfTokens <= MINT_CAP_PER_WALLET, "OVER_MINT_CAP_PER_WALLET");
        require(lastTokenId + numberOfTokens <= MAX_SUPPLY, "OVER_SUPPLY_LIMIT");
        require(MINT_PRICE * numberOfTokens <= msg.value, "CORRECT_ETH_FEE_NOT_ATTACHED");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ++lastTokenId);
        }

        emit Z00tMinted(msg.sender, numberOfTokens, lastTokenId);
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit WithdrawFinished(msg.sender, balance);
    }
}