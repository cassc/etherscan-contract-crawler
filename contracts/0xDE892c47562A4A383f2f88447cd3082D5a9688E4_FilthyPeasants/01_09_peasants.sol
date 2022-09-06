//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// Thanks Azuki Team for the optimized contract <3
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/***************************************************************************************************

   ▄████████  ▄█   ▄█           ███        ▄█    █▄    ▄██   ▄   
  ███    ███ ███  ███       ▀█████████▄   ███    ███   ███   ██▄ 
  ███    █▀  ███▌ ███          ▀███▀▀██   ███    ███   ███▄▄▄███ 
 ▄███▄▄▄     ███▌ ███           ███   ▀  ▄███▄▄▄▄███▄▄ ▀▀▀▀▀▀███ 
▀▀███▀▀▀     ███▌ ███           ███     ▀▀███▀▀▀▀███▀  ▄██   ███ 
  ███        ███  ███           ███       ███    ███   ███   ███ 
  ███        ███  ███▌    ▄     ███       ███    ███   ███   ███ 
  ███        █▀   █████▄▄██    ▄████▀     ███    █▀     ▀█████▀  
                  ▀                                              

   ▄███████▄    ▄████████    ▄████████    ▄████████    ▄████████ ███▄▄▄▄       ███        ▄████████ 
  ███    ███   ███    ███   ███    ███   ███    ███   ███    ███ ███▀▀▀██▄ ▀█████████▄   ███    ███ 
  ███    ███   ███    █▀    ███    ███   ███    █▀    ███    ███ ███   ███    ▀███▀▀██   ███    █▀  
  ███    ███  ▄███▄▄▄       ███    ███   ███          ███    ███ ███   ███     ███   ▀   ███        
▀█████████▀  ▀▀███▀▀▀     ▀███████████ ▀███████████ ▀███████████ ███   ███     ███     ▀███████████ 
  ███          ███    █▄    ███    ███          ███   ███    ███ ███   ███     ███              ███ 
  ███          ███    ███   ███    ███    ▄█    ███   ███    ███ ███   ███     ███        ▄█    ███ 
 ▄████▀        ██████████   ███    █▀   ▄████████▀    ███    █▀   ▀█   █▀     ▄████▀    ▄████████▀  
                                                                                                                 
Collection for all folks who are grinding discord 24/7, retweeting all the tweets, tagging their
friends left, right and center and still have nothing to show for it.

Collection for all the Filthy Peasanats!

***************************************************************************************************/

contract FilthyPeasants is ERC721AQueryable, Ownable, ReentrancyGuard {

    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = '.json';

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;

    bool public paused = true;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx
    ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        maxSupply = _maxSupply;
    }

    function mint(uint256 quantity) external payable {
        require(!paused, 'The minting is paused!');
        require(quantity > 0 && quantity <= maxMintAmountPerTx, 'Invalid mint amount!');
        require(totalSupply() + quantity <= maxSupply, 'Max supply exceeded!');
        require(msg.value >= cost * quantity, 'Insufficient funds!');

        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : '';
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }
}