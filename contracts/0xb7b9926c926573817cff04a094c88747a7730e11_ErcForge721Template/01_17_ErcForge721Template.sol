/*
 /$$$$$$$$                     /$$$$$$$$                                          /$$          
| $$_____/                    | $$_____/                                         |__/          
| $$        /$$$$$$   /$$$$$$$| $$     /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$      /$$  /$$$$$$ 
| $$$$$    /$$__  $$ /$$_____/| $$$$$ /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$    | $$ /$$__  $$
| $$__/   | $$  \__/| $$      | $$__/| $$  \ $$| $$  \__/| $$  \ $$| $$$$$$$$    | $$| $$  \ $$
| $$      | $$      | $$      | $$   | $$  | $$| $$      | $$  | $$| $$_____/    | $$| $$  | $$
| $$$$$$$$| $$      |  $$$$$$$| $$   |  $$$$$$/| $$      |  $$$$$$$|  $$$$$$$ /$$| $$|  $$$$$$/
|________/|__/       \_______/|__/    \______/ |__/       \____  $$ \_______/|__/|__/ \______/ 
                                                          /$$  \ $$                            
                                                         |  $$$$$$/                            
                                                          \______/                             
*/
//SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IErcForgeInitiable.sol";

contract ErcForge721Template is  Context, ERC721Enumerable, ERC721Burnable, ERC721Pausable, IErcForgeInitiable  {
    address public owner;
    string public _name;
    string public _symbol;    
    string public contractUri; 
    string private _baseTokenURI;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    bool private _isInitDone = false;
    
    uint256 public maxSupply;
    uint256 public price;

    constructor() ERC721("", "") {
        _isInitDone = true;
    }

    function init(
            address newOwner, 
            string memory newName, 
            string memory newSymbol, 
            string memory newBaseTokenURI, 
            string memory newContractUri) public override {         
        require(!_isInitDone, "Init was already done");      

        _name = newName;
        _symbol = newSymbol;
        _baseTokenURI = newBaseTokenURI;
        contractUri = newContractUri;        
        owner = newOwner;
         _tokenIdTracker.increment();
        _isInitDone = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function setBaseUri(
        string memory newUri
    ) public {
        require(_msgSender() == owner, "Not owner");
        _baseTokenURI = newUri;
    }

    function setContractURI(
        string memory newUri
    ) public {
        require(_msgSender() == owner, "Not owner");
        contractUri = newUri;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function setOwner(
        address newOwner
    ) public {
        require(_msgSender() == owner, "Not owner");
        owner = newOwner;
    }

    function setTokenPriceAndSupply(
        uint256 _price,
        uint256 _maxSupply
    ) public {
        require(_msgSender() == owner, "Not owner");
        price = _price;
        maxSupply = _maxSupply;
    }




    function mint() public payable virtual {
        require(price > 0, "Minting not available");
        require(_tokenIdTracker.current() <= maxSupply, "Not enough supply");
        require(msg.value >= price, "Not enough eth");

        _mint(_msgSender(), _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function airdrop (
        address[] memory to
    ) public virtual {
        require(_msgSender() == owner, "Not owner");

        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
    }




    /**
     * @dev Pauses all token transfers.
     */
    function pause() public virtual {
        require(_msgSender() == owner, "Not owner");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     */
    function unpause() public virtual {
        require(_msgSender() == owner, "Not owner");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function withdraw() public {
        require(_msgSender() == owner, "Not owner");
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}