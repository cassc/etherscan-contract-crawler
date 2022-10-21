// SPDX-License-Identifier: MIT

/*                                                                                                          
                :**-               .                  ....                                
              -+*--++==.         :+*=.              .=****=.     .==.        -=-          
            .%+=-----==**+.    .+*+++*+..         .=*=----%-   .+*++#=     :*==+*.        
           .+*=-----------+++++#++*#+++**+:      ++=------:++- @*=++#*-  -++:[email protected]       
           [email protected]===---===------==+#%%%#*+++*###%%*==++++++==-+##+++*%*##::+*:[email protected]       
           [email protected]+**+..-##*+=----:-==+%%%%##*+++++=-*#####+=::=++=###%%#**#+-----=+*%#-      
           [email protected]*###--=###*+=--------::+*#%%%%*:-=+######+=::=**+:+#%%%*=:------=*#-:=%     
           [email protected]*#########*+=-------------====---=+#######***##*+---===--------=+*#*=+%     
           [email protected]*#########*+=-------------------=++############*+--------------=+*####+     
           -%=*#########*+=-+*++=-------------=++############*+--=+*=-:+--=+*++*%#@*      
             +#########*++=%#+:-*+=---=+#--=+-=+*%###########*+-=+###*+#-=+*##**%%*-      
              ##=++++++====%##**#*+---+%#***#-=+*%%###########+-=+######-=*%##%@@.        
             +##+===-----==*####*+=--=*%#####-=+*%%%##########+-=*%#####-=+####%@         
            [email protected]++***++=============---=+*##**+-==++###********+=-=+*##**+-=++++***%-       
             -*+::-=*******+++++++++++++++++++++++++++++++++++++++++++++++++#***@-.       
              #+...-=-=----*****++++++++++++++++++++++++++++++++++++++++++*[email protected]         
              :=*+-====:...====::::=---.::---=::.:---=::::=---:.::=---:.:[email protected]         
                :@#*++*=-::====...:=-=-...-=-=:...-=-=....=-=-...:=-=-...=++#*+=          
                :@###%%%#******++++****+++*****+++****++++****+++*****++####:             
               :=#==++++*%%%%%%%%%%%%@@@@@@@@%#######################%@@@-                
               =%=====--=======+====%%@@@@@#-%%*=-:.:::........::::%%%#[email protected]%=               
              -+*===---------=======***********+-.               .-******%+               
              **==-----------=============--:          .:::::::::.  :-===#+               
              **==-------------::..........           +#@@@@%####*=  .:::*+               
            [email protected]+===----------:.                        *%@@@@@@@%%#+       -*-             
            [email protected]+====-------:                            -==%%@%%%+-         .%:            
            [email protected]=-====----:.               :.               .+**:.             #=           
            [email protected]:====-:.               .-=-.               :-=:       .-     *=           
            [email protected]                         .:-:::.      :::------::::   :=-.   *=           
            :@-...    ......              .::=--------:::..   .:::-----:     #=           
          -+**+-...........       .         ::-----:.           .:-::..   .:+=:           
   ::+**#%*=:.:+*:.........    ....           ...::--------------:.      .=#.             
 -**+:...+#*:..-+#**=..............       ..     ....:::::::::...      ..=+:              
%*=::.   :-+%#==+---=*=-::===-.......   ....  .:------------:   ..:====#@-                
+=:..     :-=*##*-....+##*++++**-:.:::::::...-*#***+++*+++*%#*--+*#++++-++*+              
+-:.       .:=+%%=-:::-+=--...:-##*#######***%*=::.::.:-:.:=*#%**+--:.:-+%%+*=.           
+-::         :-=+%%%#+=====::::-++=---:.::-=***+=.:-=====:.-=+*.:[email protected]%+-.:++          
+--::.        .:-=##%@@%###====-===--:...:::-***+::::.:::..-++*::-==%@@@%*=:  :+=         
-:::-:.        .:--*#%%%%%%%%%%**++===-------**+=.:-====-::-=*#**#%%%##%#=::   :%.        
--: :::.        .---+#%%%%%###%@@%###########%*=-:-:::.::.:-*%@@@%%%###%=-:.   [email protected]       
=-:  ..::        :----+#%%%#####%%%%%%%%%%%%%%%%***+==*+=-*%@@%###%%%#*--:.   .:-%=.      
++-.    ..       .----=*#%%%#####%######%%%%%##%%%%%%%%%%%%%%%%###%%#+--..   .:--:#*                          
*/

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BlurDogs is ERC721A, Ownable, ReentrancyGuard {

    string public baseURI;

    uint256 public mintPrice = 0.005 ether;
    uint256 public maxPerTx = 5;
    uint256 public maxSupply = 3000;
    uint256 public maxPerWallet = 10;

    bool public saleActive;

    mapping (address => bool) public blacklistedMarketplaces;

    constructor() ERC721A("BlurDogs", "BlurDogs") {}

    function mint(uint256 _amount) external payable nonReentrant {

        require(msg.value == _amount * mintPrice, "Incorrect amount of ETH sent in order to mint.");
        require(totalSupply() + _amount <= maxSupply, "Sorry, sold out.");
        require(tx.origin == msg.sender, "The caller is another contract");
        require(saleActive, "Sale is not live");
        require(numberMinted(msg.sender) + _amount <= maxPerWallet, "You have minted the max amount allowed per wallet.");
        require(_amount <= maxPerTx, "You may only mint a max of 5 per transaction");

        _mint(msg.sender, _amount);
    }

    function teamMint(uint256 _amount, address _wallet) external onlyOwner {
        require(totalSupply() + _amount <= maxSupply);
        _mint(_wallet, _amount);
    }


    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setMaxPerTx(uint256 _amount) external onlyOwner {
        maxPerTx = _amount;
    }

    function setMaxSupply(uint256 _newSupply) external onlyOwner {
        // Used incase of emergency;
        maxSupply = _newSupply;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function blacklistMarketplaces(address[] calldata _marketplace) external onlyOwner {
        for (uint256 i; i < _marketplace.length;) {
            address marketplace = _marketplace[i];
            blacklistedMarketplaces[marketplace] = true;
            unchecked {
                ++i;
            }
        }
    }
 
    function approve(address to, uint256 id) public virtual override {
        require(!blacklistedMarketplaces[to], "Opensea, LooksRare and X2Y2 are not permited. Please use Blur.io");
        super.approve(to, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(!blacklistedMarketplaces[operator], "Opensea, LooksRare and X2Y2 are not permited. Please use Blur.io");
        super.setApprovalForAll(operator, approved);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}