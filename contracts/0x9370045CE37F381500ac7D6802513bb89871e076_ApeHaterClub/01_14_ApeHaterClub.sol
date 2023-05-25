/*


 $$$$$$\   $$$$$$\  $$$$$$$\        $$\   $$\  $$$$$$\ $$$$$$$$\ $$$$$$$$\  $$$$$$\        $$\   $$\ $$$$$$$$\ $$$$$$$$\ $$$$$$$$\ $$$$$$$$\  $$$$$$\  
$$  __$$\ $$  __$$\ $$  __$$\       $$ |  $$ |$$  __$$\\__$$  __|$$  _____|$$  __$$\       $$$\  $$ |$$  _____|\__$$  __|$$  _____|$$  _____|$$  __$$\ 
$$ /  \__|$$ /  $$ |$$ |  $$ |      $$ |  $$ |$$ /  $$ |  $$ |   $$ |      $$ /  \__|      $$$$\ $$ |$$ |         $$ |   $$ |      $$ |      $$ /  \__|
$$ |$$$$\ $$ |  $$ |$$ |  $$ |      $$$$$$$$ |$$$$$$$$ |  $$ |   $$$$$\    \$$$$$$\        $$ $$\$$ |$$$$$\       $$ |   $$$$$\    $$$$$\    \$$$$$$\  
$$ |\_$$ |$$ |  $$ |$$ |  $$ |      $$  __$$ |$$  __$$ |  $$ |   $$  __|    \____$$\       $$ \$$$$ |$$  __|      $$ |   $$  __|   $$  __|    \____$$\ 
$$ |  $$ |$$ |  $$ |$$ |  $$ |      $$ |  $$ |$$ |  $$ |  $$ |   $$ |      $$\   $$ |      $$ |\$$$ |$$ |         $$ |   $$ |      $$ |      $$\   $$ |
\$$$$$$  | $$$$$$  |$$$$$$$  |      $$ |  $$ |$$ |  $$ |  $$ |   $$$$$$$$\ \$$$$$$  |      $$ | \$$ |$$ |         $$ |   $$$$$$$$\ $$$$$$$$\ \$$$$$$  |
 \______/  \______/ \_______/       \__|  \__|\__|  \__|  \__|   \________| \______/       \__|  \__|\__|         \__|   \________|\________| \______/ 
                                                                                                                                                       
                                                                                                                                                       
                                                                                                                                                

*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/extensions/ERC721AQueryable1.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


//BANANO contract
abstract contract Bnno {
    function burnBanana(address burnTokenAddress) external virtual;

    function balanceOf(address account, uint256 id) public view virtual
        returns (uint256);
}


//OG contract (GodHatesNFTees)
abstract contract Ghnft {
    function balanceOf(address owner) public view virtual returns (uint256);
}


contract ApeHaterClub is ERC721AQueryable, Ownable, ReentrancyGuard {    

    using Strings for uint256;
    // Public Constants
    uint256 public constant MAX_SUPPLY = 12222; //TOTAL SUPPLY OF APES (12222)
    uint256 public constant MAX_SUPPLY_PUBLIC_MINT = 2178; //PHASE 1 (2178)
    uint256 public constant MAX_MINTS_PUBLIC = 3;
    uint256 public constant PUBLIC_PRICE = 0.25 ether; 
    string public uriPrefix = "";
    string public uriSuffix = ".json";

    // Variables
    string private baseURI;
    string public hiddenMetadataUri;
    uint256 public _minted = 0;


    // Sale controllers
    bool public FreeMutation = false ; 
    bool public PublicActive  = false ; 
    //Instant reveal
    bool public revealed = true;


    Ghnft private immutable ghnft;
    Bnno private immutable bnno;

    constructor(
        string memory name,
        string memory symbol,
        address ghnftAddress,
        address bnnoAddress
    ) ERC721A(name, symbol) {
        ghnft = Ghnft(ghnftAddress);
        bnno = Bnno(bnnoAddress);
    }
    //PUBLIC MINT (PHASE 1)
    function MintPublic(uint256 amount) external payable nonReentrant { 
        require(PublicActive, "Public sale is paused"); 
        require(_minted + amount <= MAX_SUPPLY_PUBLIC_MINT, "Exceed max supply");
        require(amount > 0 && amount <= MAX_MINTS_PUBLIC,"Must mint between the min and max.");
        require(msg.value == amount * PUBLIC_PRICE, "Invalid funds provided");
        _minted += amount;
        _safeMint(msg.sender,amount);
    }


    //FREE MUTATION MINT (PHASE 2)
    function MintFreeMutation(uint256 amount) external  {
        require(FreeMutation, "Free Mutation is not active");
        require(_minted + amount <= MAX_SUPPLY, "Exceed max supply");
        require(ghnft.balanceOf(msg.sender) > 0, "Must own at least 1 GodHatesNFTees");
        require(bnno.balanceOf(msg.sender, 0) > 0 && bnno.balanceOf(msg.sender, 0) >= amount, "Must own at least 1 Banano to mutate, or max bananas."); 
        for (uint256 i = 0; i < amount; i++) { 
            bnno.burnBanana(msg.sender);
        }
        _minted += amount;
        _safeMint(msg.sender,amount);
    }
    //TEAM MINT (PHASE 3) 
    function internalMint(uint256 amount) external onlyOwner  {
        require(_minted + amount <= MAX_SUPPLY, "Max supply exceeded!");
        _minted += amount;
        _safeMint(msg.sender, amount);
    }
    function HowManyOGs(address owner) public view returns (uint256){
        uint256 numberogs = ghnft.balanceOf(owner);
        return numberogs;
    }
    function HowManyBananos(address account) public view returns (uint256){
        uint256 numberbananos = bnno.balanceOf(account, 0);
        return numberbananos;
    }
    //SETS
    function setFreeMutationMint(bool _state) public onlyOwner {
        FreeMutation = _state;
    }
    function setPublicMint(bool _state) public onlyOwner {
            PublicActive = _state;
        }
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : '';
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

   function withdrawMoney() external onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "WITHDRAW FAILED!");
    }

}