// SPDX-License-Identifier: MIT
//                                                        .=+-                     
//                                             .:       .+#**%+*####*              
//                                           =###+    :+##*#%#***##*=              
//                                      .:=*##*#%==+*##**###**#*=:                 
//                                 :=*####***####*******##*##+.                    
//                               =##*****++*##***++====***#+.                      
//                             :##****#%*=+***++====++**##.                        
//                            :%*****+#***+========+***#+                          
//                            *#***++#*+=+*+=======***#-                           
//       -*##**-              %*****#**+=++*+=====***#:               =****=       
//      #%+++++*%=            ##**%#***+=++=**==+***#:              :%*++++#*      
//     *%++++++++*%*:         :#*%%%#**+==+==*#****#:             .*%++++++##      
//     @*[email protected]         :%%%%%%#*++****#%##*.             -%++++++++##      
//     @#+++++++++++#*         *##%%%%%#**###*###+              [email protected]+++++++++#%      
//     =%+++++++++++%=        #@%#***###*****+=-=%#             [email protected][email protected]     
//      %#++++++++++%-.+=   .%@%%%####*+--=++++++#@:            %*++++++++++%+     
//      :@*++%#*%*++%=+%*%. .#@**######*===+++**%%.            :@+++++***[email protected]     
//       =%+*@+ [email protected]*+#*[email protected]+##   [email protected]*++++*##*==++*#@+        .**-  [email protected]*+++%%[email protected]*+%+     
//        ##+#@- -%#%--%++##.  [email protected]%+++#%+*@++#%+%=       .%*[email protected]   +%++*@*  *%+##     
//        [email protected]*+*@=  .  +%+++*%-  %#@##%+++###%[email protected]       %#[email protected]=   @*++*@.  +##:     
//         [email protected]*++%#.   =%++++#%  **+++++++*%%++*#    =+.:@*+*%+   =%*++*%+.         
//    *%%+  *%*++*%-  :@++++##  ##+*+++++++++##*   ##%+ %*%*.     -%#*++*%#+-      
//    @**%*  @#**+*%+ :@++++#*  %*+*#+++++++%#%:   @*%+ @*%=        -%#*****#%.    
//    #%**@: [email protected]%****@==%++++##  +%*#%++++++%#-    [email protected]*%=:@[email protected]+*=  .==   *%##***%+    
//    [email protected]**#%. @%****#%[email protected]*+++##   :=%*+++++*@.=#@# [email protected][email protected]:[email protected]+###@  %#%#   :*@#++%*    
//    [email protected]****%%%*****## *%***##     ##+++++*%:@**@-+%*@[email protected]***#%  @#*%#+:  #%**%#    
//    [email protected]**++********%= [email protected]***%#     %#******@[email protected]**@@%**@:[email protected]#**#@  ##****%*+%#**#%    
//    *%#***********@  @#***## .:  -%@#**#*%=#%**#***@-=%*#%-   =%***********#@.   
//    #%*+****=****#% [email protected]*****%%%%%  =%*#*@*@-:@#*****%[email protected]##@.   :@*+*******#%@@:   
//    [email protected]####*******#%  @#********@. :@***@#%+ @#**+#*## [email protected]*%#%@=:@*****+**#@#[email protected]   
//     -#%@%#*****#%#*=%#********@. :@%***#@- @#%**@#*@[email protected]****%*#@**+####*@%*+*%   
//       [email protected]#**#%#%#-=+#%*****=**%@%[email protected]#**=*%# @#@@%@%+%*[email protected]#++*%@#@####%##@+%***.   
//        [email protected]####@%@@+=+*@#******%@#%@%#**+*%%#@##@:[email protected]##@*#@###@%#@####@#=. .*-     
//         [email protected]##%%: .+%#%@%#%%#%%=%%%@%%#*#%*#*%##@= -%%@#%@%#[email protected]###%            
//          .=+=.     :+:   %%%+ .*[email protected]@#*@=  -+*##.     ..:.      #%##@            
//                          .++      [email protected]##%*                       +%%%*            
//                                   .%%#%#                        =*+             
//                                     =*+.                                        
//
//  SLIMES are Silly Little Infected Magical Energy Superstars
//  https://slimes.fun/

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Slimes is ERC721A, ERC721ABurnable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _reserveMinted;

    // Sales
    bool public saleStart = false;
    uint256 public price = .04 ether;
    uint256 public constant maxSupply = 9888;
    uint256 public maxTotalFreeMint = 3000;
    uint256 private constant maxReserved = 300;
    uint256 public constant maxPaidMint = 10;
    uint256 public constant maxFreeMint = 3;
    uint256 public freeMinted;
    mapping(address => uint256) public freeClaimsBy;

    // Settings
    string public provenance = "50b68b8c43bc02d8ca6c72411edcd02b1bbcdb1bea2033c73dc4c767635f779f";
    string public baseUri = "https://api.slimes.fun/slime/";
    bool public sealContract;

    // Team
    address cyrus     = 0xdB95df498cCA3be226e20b28a146a638845552CB;
    address ardie     = 0x2Da0831D81c0626B028516CAAD41b6FDc26F272B;
    address eugene    = 0x714E6A851aBA9F597dB2096C19C6b25cbf235d3C;
    address slimesDAO = 0xa9ede628eAF89589c8bf98c11456484591D4D57e;
    address slimes    = 0x1026fF2706385D7f56205489e8aB37C8Ba43299d;


    constructor() ERC721A("SLIMES", "SLIMES") { }

    /**
    *   Public function for minting.
    */
    function mint(uint256 amount) public payable {
        require(saleStart, "SALE PAUSED");
        require((_currentIndex.add(amount) - _reserveMinted.current()) <= (maxSupply - maxReserved), "Sold Out");
        require(msg.sender.code.length == 0, "_");
        if (freeMinted.add(amount) <= maxTotalFreeMint) {
            require(amount <= maxFreeMint, "Max 3 per transaction");
            require(msg.value == 0, "No ETH required");
            require(freeClaimsBy[msg.sender] + amount <= 6, "Max 6 per address");
            freeMinted = freeMinted.add(amount);
            freeClaimsBy[msg.sender] += amount;
        } else {
            require(amount <= maxPaidMint, "Max 10 per transaction");
            require(msg.value >= amount*price, "Value too low");
        }
        _safeMint(msg.sender, amount);
    }

    function mintReserved(uint256 amount, address receiver) public onlyOwner {
        require(_currentIndex.add(amount) <= maxSupply);
        require(_reserveMinted.current().add(amount) <= maxReserved);
        for (uint256 i=0; i<amount; i++) {
            _reserveMinted.increment();
        }
        _safeMint(receiver, amount);
    }

    /*
    *   Getters.
    */
    function exists(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }

    function getByOwner(address _owner) view public returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = _currentIndex;
            uint256 resultIndex;
            for (uint256 t = 1; t <= totalTokens; t++) {
                if (_exists(t) && ownerOf(t) == _owner) {
                    result[resultIndex] = t;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    /*
    *   Owner setters.
    */
    function setBaseUri(string memory _baseUri) public onlyOwner {
        require(!sealContract, "Contract must not be sealed.");
        baseUri = _baseUri;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setSaleStart(bool _saleStart) public onlyOwner {
        saleStart = _saleStart;
    }

    function setTotalFreeMint(uint256 _maxTotalFreeMint) public onlyOwner {
        maxTotalFreeMint = _maxTotalFreeMint;
    }

    function setSealContract() public onlyOwner {
        sealContract = true;
    }

    /*
    *   Money management.
    */
    function withdraw() public payable onlyOwner {
        uint256 each = address(this).balance;
        require(payable(cyrus).send(each.mul(1557).div(10000)));
        require(payable(ardie).send(each.mul(1557).div(10000)));
        require(payable(eugene).send(each.mul(1557).div(10000)));
        require(payable(slimesDAO).send(each.mul(780).div(10000)));
        require(payable(slimes).send(address(this).balance));
    }

    function forwardERC20s(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    /*
    *   Overrides.
    */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    receive () external payable virtual {}
}