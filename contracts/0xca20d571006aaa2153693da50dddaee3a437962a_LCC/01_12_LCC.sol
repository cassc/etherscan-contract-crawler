// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LCC is ERC721A, Ownable {

    // Constants
    uint256 public constant MAX_SUPPLY = 10_000;

    
    // Variables
    uint256 public MINT_PRICE = 0.07 ether;
    mapping(address => bool) whitelistedAddressesOG;
    uint256 public timestampPublicSale = 1672527599; // init to 2022-12-31 23:59:59 CET, to be set by owner
    uint256 public percentageForTrading = 80;
    uint256 public BATCH = 1;

    
    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    constructor() ERC721A("Legendary Cobra Club", "LCC", 1000, MAX_SUPPLY) {
        baseTokenURI = "https://bafybeiad2xylgb47iw2ukcvhhfmtonuarf5e7k6xh3wvk5hyddxhan2imy.ipfs.dweb.link/metadata/";
    }



    /// @dev Returns an URI for a given token ID.
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// Sets the minimum mint token price.
    function setMintPrice(uint256 _mint_price) public onlyOwner {
        MINT_PRICE = _mint_price;
    }

    /// Sets the timestamp date when everyone can mint new token.
    function setTimestampPublicSale(uint256 _timestampPublicSale) public onlyOwner {
        timestampPublicSale = _timestampPublicSale;
    }

    /// Sets the percentage for trading.
    function setPercentageForTrading(uint256 _newPercentage) public onlyOwner {
        percentageForTrading = _newPercentage;
    }

    /// Sets the mint batchs. 1 to 10
    function setBatch(uint256 _batch) public onlyOwner {
        require(_batch <=10, "batch should be < 10");
        BATCH = _batch;
    }

    /// Check if max supply is reached - use of a multiplier to avoid rounding down division issues
    modifier maxReached(uint256 _number) {
        require( (((totalSupply() + _number)*1000) / (BATCH)) <= (1000)*1000, "Max supply reached");
        _;
    }




    // Mint token if conditions are fulfilled.  
    function mint(uint256 number) public payable maxReached(number) {
        
        require(msg.value >= MINT_PRICE * number, "Transaction value is less than the min mint price");

        if( timestampPublicSale > block.timestamp ) {
            require( 
                        verifyUserOG(msg.sender) ,
                        "You need to be whitelisted to mint token or you have wait for the public sale"
                    );
            _safeMint(msg.sender, number);
        }
        else {
            _safeMint(msg.sender, number);
        }
    }

    /// Owner can mint without paying smart contract
    function mintFromOwner(uint256 number) public onlyOwner maxReached(number) {
        _safeMint(msg.sender, number);
    }




    /// Add a new address to the OG whitelist mapping.
    function addWhitelistUserOG(address[] memory newWhitelistedUserOG) public onlyOwner {
        for (uint i=0; i<newWhitelistedUserOG.length; i++) {
            require( !verifyUserOG( newWhitelistedUserOG[i] ) , "already OG" );
            whitelistedAddressesOG[ newWhitelistedUserOG[i] ] = true;
        }
    }
    /// Verify is an address is whitelisted OG. 
    function verifyUserOG(address _whitelistedAddressOG) public view returns(bool) {
        return whitelistedAddressesOG[_whitelistedAddressOG];
    }


    function getBalance() public view returns(uint) {
        return address(this).balance;
    }



    /// Withdraw money with the repartition: percentageForTrading to the LCC community wallet and the rest to the LCC team
    function withdrawMoney(address payable _to) public onlyOwner {
        uint256 balance = getBalance();
        payable(msg.sender).transfer(balance * percentageForTrading / 100);
        _to.transfer(balance * (100 - percentageForTrading) / 100);
    }
}