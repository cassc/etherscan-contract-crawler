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
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";



interface IERC721 is IERC165 {

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

pragma solidity ^0.8.11;


contract SrBananos is ERC1155, Ownable {

    // Publc Constants
    uint256 public constant MAX_SUPPLY = 10044;
    uint256 public constant MAX_MINTS = 2;
    uint256 public constant BANANA_PRICE = 0.035 ether;
    string public name;
    string public symbol;

    // Variables
    string private baseURI;
    uint256 public _minted = 0;
    address SuperBanana;

    // Sale controllers
    bool public PublicPaused = true;
    bool public WhitelistPaused = true;

    // Mappings
    mapping(address => uint256) public addressPublicMintedBalance;
    mapping (uint256 => uint256) private AlreadyClaimed;

    // Instance of God Hates Nftees smart contract
    IERC721 NFTEE = IERC721(0xE6d48bF4ee912235398b96E16Db6F310c21e82CB);
    
    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
    }
  
    function MintWhitelist(uint256 amount, uint256 NfTeesId) public payable {
        require(!WhitelistPaused, "Whitelist sale is paused");
        require(amount + _minted <= MAX_SUPPLY, "Banana: Exceed max supply");
        require(amount > 0 && amount <= MAX_MINTS);
        address _owner = NFTEE.ownerOf(NfTeesId);
        require(_owner == msg.sender, "Must be Owner of OG collection to mint");
        require(msg.value == amount * BANANA_PRICE, "Invalid funds provided");
        require(AlreadyClaimed[NfTeesId] < 2 , "Bananas already claimed");
        require(AlreadyClaimed[NfTeesId] + amount <= 2, "Cannot claim too many bananas");
        _minted += amount;
        AlreadyClaimed[NfTeesId] += amount; 
        _mint(msg.sender, 0, amount, "");
        delete _owner;
    }
    
    function MintPublic(uint256 amount) public payable {
        require(!PublicPaused, "Paused");
        require(amount + _minted <= MAX_SUPPLY, "Banana: Exceed max supply");
        require(amount > 0 && amount <= MAX_MINTS, "Invalid mint amount");
        uint256 addressPublicMintedCount = addressPublicMintedBalance[msg.sender];
        require(addressPublicMintedCount + amount <= MAX_MINTS, "max NFT per address exceeded");
        require(msg.value == amount * BANANA_PRICE, "Invalid funds provided");
        addressPublicMintedBalance[msg.sender] += amount;
        _minted += amount;
        _mint(msg.sender, 0, amount, "");
        delete addressPublicMintedCount;
    }


    function setWhitelistPause(bool _state) public onlyOwner {
        WhitelistPaused = _state;
    }

    function setPublicPause(bool _state) public onlyOwner {
        PublicPaused = _state;
    }
    
    function CheckHowManyClaimed(uint256 NftID) public view returns (uint256){
        uint256 claimed = AlreadyClaimed[NftID];
        return claimed;
    }

    function burnBanana(address burnTokenAddress) external {
        require(msg.sender == SuperBanana , "Invalid caller, must be called from SuperBanana Smart Contract");
        _burn(burnTokenAddress, 0, 1);
    }

    function setSuperBananaAddress(address SuperBananaAddress) external onlyOwner {
        SuperBanana = SuperBananaAddress;
    }

    function updateUri(string memory _newUri) external onlyOwner {
        _setURI(_newUri);
    }


   function MintAdmin(uint256 amount) external onlyOwner  {
        require(amount + _minted <= MAX_SUPPLY, "Banana: Exceed max supply");
        _minted += amount;
        _mint(msg.sender, 0, amount, "");
    }

    function withdrawMoney() external onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "WITHDRAW FAILED!");
    }

}