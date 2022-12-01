pragma solidity ^0.8.4;

import "openzeppelin-4/token/ERC721/ERC721.sol";
import "openzeppelin-4/access/Ownable.sol";
import "openzeppelin-4/access/AccessControl.sol";
import "erc721a/contracts/ERC721A.sol";

contract CyberchadsV2 is ERC721A, Ownable {
    // Base URI
    string private _baseUriExtended;
    bool public saleActive = false;
    
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public maxTx = 150;

    constructor(string memory name, string memory symbol, string memory baseURI) public ERC721A(name, symbol) {
        setBaseURI(baseURI);
        // Mint 5 special legendary Chads to deployer.
        _mint(msg.sender, 5);
    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function giveaway(address to, uint256 qty) external onlyOwner {
        require(qty > 0, "Qty of mints not allowed");
        require(qty + totalSupply() <= MAX_SUPPLY, "Value exceeds total supply");    

        _mint(to, qty);              
    }

    function mint(uint256 qty) public payable {
        require(saleActive, "Sale isn't active");
        if (qty + totalSupply() > MAX_SUPPLY) {
            qty = MAX_SUPPLY - totalSupply();
        }
        require(qty <= maxTx && qty > 0, "Qty of mints not allowed");
        require(qty + totalSupply() <= MAX_SUPPLY, "Value exceeds total supply");  

        _mint(msg.sender, qty);
    }

    /**
    * @dev Withdraw ether from this contract (Callable by owner only)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUriExtended;
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI();
    }


    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function setBaseURI(string memory baseURIExtended) onlyOwner public {
       _baseUriExtended = baseURIExtended;
    }
}