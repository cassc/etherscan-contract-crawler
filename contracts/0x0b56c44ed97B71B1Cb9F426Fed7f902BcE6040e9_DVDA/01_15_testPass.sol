/*

 $$$$$$\   $$$$$$\  $$$$$$$\        $$\   $$\  $$$$$$\ $$$$$$$$\ $$$$$$$$\  $$$$$$\        $$\   $$\ $$$$$$$$\ $$$$$$$$\ $$$$$$$$\ $$$$$$$$\  $$$$$$\  
$$  __$$\ $$  __$$\ $$  __$$\       $$ |  $$ |$$  __$$\\__$$  __|$$  _____|$$  __$$\       $$$\  $$ |$$  _____|\__$$  __|$$  _____|$$  _____|$$  __$$\ 
$$ /  \__|$$ /  $$ |$$ |  $$ |      $$ |  $$ |$$ /  $$ |  $$ |   $$ |      $$ /  \__|      $$$$\ $$ |$$ |         $$ |   $$ |      $$ |      $$ /  \__|
$$ |$$$$\ $$ |  $$ |$$ |  $$ |      $$$$$$$$ |$$$$$$$$ |  $$ |   $$$$$\    \$$$$$$\        $$ $$\$$ |$$$$$\       $$ |   $$$$$\    $$$$$\    \$$$$$$\  
$$ |\_$$ |$$ |  $$ |$$ |  $$ |      $$  __$$ |$$  __$$ |  $$ |   $$  __|    \____$$\       $$ \$$$$ |$$  __|      $$ |   $$  __|   $$  __|    \____$$\ 
$$ |  $$ |$$ |  $$ |$$ |  $$ |      $$ |  $$ |$$ |  $$ |  $$ |   $$ |      $$\   $$ |      $$ |\$$$ |$$ |         $$ |   $$ |      $$ |      $$\   $$ |
\$$$$$$  | $$$$$$  |$$$$$$$  |      $$ |  $$ |$$ |  $$ |  $$ |   $$$$$$$$\ \$$$$$$  |      $$ | \$$ |$$ |         $$ |   $$$$$$$$\ $$$$$$$$\ \$$$$$$  |
 \______/  \______/ \_______/       \__|  \__|\__|  \__|  \__|   \________| \______/       \__|  \__|\__|         \__|   \________|\________| \______/ 
                                                                                                                                                                                                                                                                                                          
⣿⣿⣿⣿ ⣿⣿ ⣿⣿⠟⠛⢉⢉⠉⠉⠻⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⠟⠠⡰⣕⣗⣷⣧⣀⣅⠘⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠃⣠⣳⣟⣿⣿⣷⣿⡿⣜⠄⣿⣿⣿⣿⣿
⣿⣿⣿⣿⡿⠁⠄⣳⢷⣿⣿⣿⣿⡿⣝⠖⠄⣿⣿⣿⣿⣿
⣿⣿⣿⣿⠃⠄⢢⡹⣿⢷⣯⢿⢷⡫⣗⠍⢰⣿⣿⣿⣿⣿
⣿⣿⣿⡏⢀⢄⠤⣁⠋⠿⣗⣟⡯⡏⢎⠁⢸⣿⣿⣿⣿⣿
⣿⣿⣿⠄⢔⢕⣯⣿⣿⡲⡤⡄⡤⠄⡀⢠⣿⣿⣿⣿⣿⣿
⣿⣿⠇⠠⡳⣯⣿⣿⣾⢵⣫⢎⢎⠆⢀⣿⣿⣿⣿⣿⣿⣿
⣿⣿⠄⢨⣫⣿⣿⡿⣿⣻⢎⡗⡕⡅⢸⣿⣿⣿⣿⣿⣿⣿
⣿⣿⠄⢜⢾⣾⣿⣿⣟⣗⢯⡪⡳⡀⢸⣿⣿⣿⣿⣿⣿⣿
⣿⣿⠄⢸⢽⣿⣷⣿⣻⡮⡧⡳⡱⡁⢸⣿⣿⣿⣿⣿⣿⣿
⣿⣿⡄⢨⣻⣽⣿⣟⣿⣞⣗⡽⡸⡐⢸⣿⣿⣿⣿⣿⣿⣿
⣿⣿⡇⢀⢗⣿⣿⣿⣿⡿⣞⡵⡣⣊⢸⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⡀⡣⣗⣿⣿⣿⣿⣯⡯⡺⣼⠎⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣧⠐⡵⣻⣟⣯⣿⣷⣟⣝⢞⡿⢹⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⡆⢘⡺⣽⢿⣻⣿⣗⡷⣹⢩⢃⢿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣷⠄⠪⣯⣟⣿⢯⣿⣻⣜⢎⢆⠜⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⡆⠄⢣⣻⣽⣿⣿⣟⣾⡮⡺⡸⠸⣿⣿⣿⣿
⣿⣿⡿⠛⠉⠁⠄⢕⡳⣽⡾⣿⢽⣯⡿⣮⢚⣅⠹⣿⣿⣿
⡿⠋⠄⠄⠄⠄⢀⠒⠝⣞⢿⡿⣿⣽⢿⡽⣧⣳⡅⠌⠻⣿
⠁⠄⠄⠄⠄⠄⠐⡐⠱⡱⣻⡻⣝⣮⣟⣿⣻⣟⣻⡺⣿⣿

*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/extensions/ERC721AQueryable1.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


//OG contract (GodHatesNFTees) 0xe6d48bf4ee912235398b96e16db6f310c21e82cb
abstract contract Ghnft {
    function balanceOf(address owner) public view virtual returns (uint256);
}


//APE contract (ApeHaterClub) 0x9370045CE37F381500ac7D6802513bb89871e076
abstract contract Ahc {
    function balanceOf(address owner) public view virtual returns (uint256);
}





contract DVDA is ERC721AQueryable, Ownable, ReentrancyGuard {    

    using Strings for uint256;
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public whitelistClaimed;
    mapping(address => bool) public publicClaimed;
    // Public Constants
    string public uriPrefix = "ipfs://QmbGFE1wx8fcBM6VxtWjWAayfbHH2KLUGCoPeERHLbuJWX/";
    string public uriSuffix = ".json";
    uint256 public constant MAX_SUPPLY = 1000; //TOTAL SUPPLY OF DVDAS (1000)
    uint256 public maxMintAmountPerAddress = 1;


    // Variables
    string private baseURI;
    string public hiddenMetadataUri;
    uint256 public _minted = 0;


    // Sale controllers
    bool public WhitelistMintActive  = false ; 
    bool public PublicMintActive = false ; 
    //Instant reveal
    bool public revealed = true;


    Ghnft private immutable ghnft;
    Ahc private immutable ahc;

    
    constructor(
        string memory name,
        string memory symbol,
        address ghnftAddress,
        address ahcAddress
    ) ERC721A(name, symbol) {
        ghnft = Ghnft(ghnftAddress);
        ahc = Ahc(ahcAddress);
    }
    //WHITELIST MINT (FREE)
  function whitelistMint() external nonReentrant {
    require(WhitelistMintActive, "The whitelist sale is not enabled!");
    require(isInWhiteList(msg.sender),"Not a part of Whitelist");
    require(!whitelistClaimed[msg.sender], "Address already claimed Whitelist!");
    require(_minted + maxMintAmountPerAddress <= MAX_SUPPLY, "Exceed max supply");
    _minted += maxMintAmountPerAddress;
    whitelistClaimed[msg.sender] = true;
    _safeMint(msg.sender, maxMintAmountPerAddress);
  }



    //PUBLIC MINT (REQUIRES 1 GODHATES + 2 APES) (FREE)
    function PublicMint() external nonReentrant { 
        require(PublicMintActive, "Public sale is paused"); 
        require(ghnft.balanceOf(msg.sender) > 0 && ahc.balanceOf(msg.sender) >1, "Must own at least 1 GodHates and 2 Apes to mint."); 
        require(!whitelistClaimed[msg.sender], "Address already claimed Whitelist!");
        require(!publicClaimed[msg.sender], "Address already claimed Public!");
        require(_minted + maxMintAmountPerAddress <= MAX_SUPPLY, "Exceed max supply");
        publicClaimed[msg.sender] = true;
        _minted += maxMintAmountPerAddress;
        _safeMint(msg.sender,maxMintAmountPerAddress);
    }

    //TEAM MINT
    function internalMint(uint256 amount) external onlyOwner  {
        require(_minted + amount <= MAX_SUPPLY, "Max supply exceeded!");
        _minted += amount;
        _safeMint(msg.sender, amount);
    }
    function HowManyOGs(address owner) public view returns (uint256){
        uint256 numberogs = ghnft.balanceOf(owner);
        return numberogs;
    }
    function HowManyAHCs(address owner) public view returns (uint256){
        uint256 numberahcs = ahc.balanceOf(owner);
        return numberahcs;
    }

    //SETS
    function setWhitelistMint(bool _state) public onlyOwner {
            WhitelistMintActive = _state;
        }
        function setPublicMint(bool _state) public onlyOwner {
            PublicMintActive = _state;
        }
    function addToWhiteList(address _addr) public onlyOwner {
        whitelisted[_addr] = true;
    }

    function addArrayToWhiteList(address[] memory _addrs) public onlyOwner {
        for (uint256 i=0;i< _addrs.length;i++)
            whitelisted[_addrs[i]] = true; 
    }

    function removeFromWhiteList(address _addr) public onlyOwner {
        whitelisted[_addr] = false;
    }

    function isInWhiteList(address _addr) private view returns (bool) {
        return whitelisted[_addr]  || _addr == msg.sender;
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