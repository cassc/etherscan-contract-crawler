// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*

AMARA ANDREW PRESENTS

                          '``^^^^^^^;^^^". "^^^1"^^^^^^"i                                                                                             
       .^^^^^^^^^^^^^'    _.       .#   ,,.~  .u   ^""";f"                                                                                            
    ^^^'             .`^^"I:?l   ))/|   l/l`  "?   >it}[]'                                                                                            
  ,".                  .1+'`I>  `z?,i         ?,  .^^\;                                                                                               
 i.                   .(u1  `^  :v"^^  'vul   v'  ^?_+).                                                                                              
l'           `[ft[;' .|u]   I.  -u'l.  ;v\`..`v  .....1l                                                                                              
{            nxI`'^i_fu~    !">+nu.:,(/uu'`tvvc_ccccc|_l^^^^^^^.          '^^^^^^^^^^^'     :^^^^^^^^`'       .       ''..                            
[            `_.     ^i   `l^`''''''`^,i+^ ..   ';;`           `,^     .,"'           .",.  <         .`""^  +``^^^^^f,.'``^^^^^^^^^^`                
':             ^"^.       ':             .^:   "".               .;`  ,^                 "".;      `'     .",_      .M'             .}'^^^^^^^^^^^"   
 `:               `""'    .<      [(~'     .~ i.      ':>~!".      ;`+.      ^>[{]!`      `{^     .*xt`     `\      ^W.     '`''..  `c"          `(`  
  .;,.               '""'  [      {}^].     1j'     '\vn{>Ii}"      v.     'tur_:",><      {'     `z:.?     .}      lv      1vvvvcvnu^      .I<I:vn"  
    '+]:'               ';.{      -{'i      r)      )ul.     +      [      {u:      -.     }.     `{;".     ++      })      .''`}...;`      `n{;!]`   
       ^+t[,.             >/      '^'      Iv|      i[      ""     `u      `/     .,^     'c              .+cl      n<          -f   ;`      .""'     
          ."?{'           .W.            `}vf>`      ^"^^^^".     .jv!      .^^^^^^      'xf      .   .'"+nur,     .#,     ./{->fn    `+,.      '"".  
       .l:`   _            W'     .^^";_fvx>. :`                 :uu:';.               .ivu{      tvuvcvx)i`^^     `#`     .~+?}))`'    `-{:.      "" 
      'I  '"^^^           ,*`     `c||{_;`     'l`            'lru/`   ,~^.         .,{cu['~      v}....    ,`     ;#.            .].   .,`^]       +`
     ^,                  `vc"     'z'            ")?;"````";-fvu{^       ,|/]~i!>_1xvu\l'  ;I?-_+_c>        ",:,,"^(v`''..        'z:  ," .`.      .j|
    ,`                 .!vx,+":I!<?c^              ."i[|tt\1_;`.           .`":I!I:"`.      `,,,:::`          i~_?]}_./jxuccurf/(1|v` +".        .;xuI
    `:i^.           .`~uu('  :]_<!;:'                                                                                       ...'``^".  .(r)-<>~]/cu|^ 
     .`l|r1+!;::;>?\vux_`                                                                                                                 '^:l!l:^.   


A FUTURE GHOST SOCIETY PRODUCTION

https://spoopies.com

---

# FUTURE GHOST SOCIETY
https://futureghost.co


## Amara Andrew (Artist)
* Website: https://byamara.com
* Twitter: @AmaraAndrew


## Jeff Sarris (Brand/Dev)
* Website: https://SPYR.me
* Twitter: @jeffSARRIS

---

# BUILDING YOUR OWN NFT PROJECT?

## Need someone to handle development and tech?
Work with Jeff at https://RYPS.co

## Need help building your brand and/or business?
Work with Jeff at https://SPYR.me

---

Alpha  =^.^=

*/
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./extensions/ERC721AQueryable.sol";


contract TheSpoopies is ERC721AQueryable, Ownable, ReentrancyGuard {
    string  public baseURI;
    
    address public proxyRegistryAddress;

    address public amara;

    uint256 public constant MAX_SUPPLY = 999;
    uint256 public constant MAX_PER_TX = 25;

    uint256 public publicPrice = 0.0031 ether;

    bool public publicSaleActive;

    mapping(address => bool) public projectProxy;

    constructor(string memory _setBaseURI,address _proxyRegistryAddress,address _amara)
        ERC721A("The Spoopies", "SPOOPY") {
        
        // Init Constants
        baseURI = _setBaseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        amara = _amara;
    }
    

    // Modifiers
    modifier onlyPublicActive() {
        require(publicSaleActive, "Public sale is not live!");
        _;
    }
    // END Modifiers


    // Set Functions
    function setBaseURI(string memory _setBaseURI) public onlyOwner {
        baseURI = _setBaseURI;
    }

    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    function setPayoutAddress(address _amara) external onlyOwner {
        amara = _amara;
    }
    // END Set Functions


    // Mint Functions
    function publicMint(uint256 _quantity) external payable onlyPublicActive nonReentrant() {
        require(_quantity <= MAX_PER_TX, "Sorry! You can only mint a maximum of 25 Spoopies per transaction!");
        require(publicPrice * _quantity == msg.value, "Wrong amount of ETH sent");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeds maximum supply");

        _safeMint( msg.sender, _quantity);
    } 

    // Dev minting function 
    function devMint(address _to, uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeds maximum supply");
        _safeMint(_to, _quantity);
    }
    // END Mint Functions


    // Toggle Sale
    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }
    // END Toggle Sale


    // Override start token in ERC721A
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    // Override _baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    // Withdraw Funds to Amara
    function withdraw() public payable onlyOwner {
        uint256 _balance = address(this).balance;
        
        require(payable(amara).send(_balance));
    }


    // Proxy Functions
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address _proxyAddress) public onlyOwner {
        projectProxy[_proxyAddress] = !projectProxy[_proxyAddress];
    }

    // OpenSea Secondary Contract Approval - Removes initial approval gas fee from sellers
    // Allow future contract approval
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator || projectProxy[_operator]) return true;
        return super.isApprovedForAll(_owner, _operator);
    }
    // END Proxy Functions

}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}