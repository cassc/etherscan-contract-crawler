// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
SkullKids: Generations

BADFROOT x SPYR

                       ;#######m
                       @#[email protected]   1#b
                        7##`   ##
                         ^@#   @#
                           @#  @#
                     ,,,,,  ## ]#b ,,sm####me,
                ,###M%"775W### j###MT7||..`"^[email protected]##m,
             ,##M|                              `[email protected]##w
           ,##"                                    ,|%##N
          @##                     ,s###Mm"Wg        'V,"##W
         @#b   #"sm#Q           ###########Q%Q        "N @##
        ]##   #@######m       @##############j#        ^# @##
        @#b  @]#########     #################@b        jb]##p
        @#b  @]#########p  #@#################j#         #j##b
        @#b  1d#########bb]b##################]b         b]##b
        ^##   [email protected]########M~]M#################[email protected]           ###
         @#b    \#######b jb#################]b          @##
          @#Q    ^[email protected]##b     @###############;`          ###`
           %#N         ##m   7############b'          ;###
            ^@#p      %#@#M    "%######M7            @##C
              7#N                                   ###`
           ,s#####p                                @####@##g
         ,###M`   7W                              @#b    b3#b
         @##        @                            ]#      [email protected]##
         @##Jp       @            ,,,           ##       '7%###
     ,#####Q#b        |"Wm, ,,sm#####mg,    ,a##\            "##
    ]###|            '7%mm|"%@##m,|[email protected]###@###W7               .##
    @#b                   '7%WmQ%@##@m"^          ,,emeg,,,;##M
    j##,     ,,smmmg,          ,mW`.         ,e###MT|^|7j555|
      7%#####WT"^||"@###M= .*^,            mw25%########M%%@#M
         ,,ssss,sm###M".                       '    ^|      7##
       ###Q"777"7``           ,a######Mw,                    @#
      ###`                ,a###T`    '7%W###w,            ,a##b
     ]##p              ,###T`              ^"%##p        ##T~
      @#QW           @#M"                      "#W      ]#b
       '[email protected]#p        @#b                          @#Mms###"
          ##       ##b                             ^^^``
          3##,  ,a##"
            "5WW87.

---

# BADFROOT TEAM

## Badfroot (Jack Davidson)
Artist/Creator of SkullKids
* Website: https://badfroot.com
* Twitter: @theBadfroot


## Jeff Sarris
Brand/Strategy/Developer
* Website: https://SPYR.me
* Twitter: @jeffSARRIS

---

# BUILDING YOUR OWN NFT PROJECT?

## Need someone to handle the tech?
Work with Jeff at https://RYPS.co

## Need help developing your brand and business?
Work with Jeff at https://SPYR.me

---

Alpha  =^.^=

*/

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./extensions/ERC721AQueryable.sol";


contract SkullKids is ERC721AQueryable, Ownable, ReentrancyGuard {
    string  public baseURI;
    
    address public proxyRegistryAddress;

    address public badfroot;
    address public spyr;

    bytes32 public godsMerkleRoot;
    bytes32 public immortalsMerkleRoot;
    bytes32 public frootFrensMerkleRoot;

    uint256 public constant MAX_SUPPLY = 9800;
    uint256 public constant MAX_PER_TX = 25;

    uint256 public constant godsPrice = 0.01 ether;
    uint256 public constant immortalsPrice = 0.015 ether;
    uint256 public publicPrice = 0.03 ether;

    bool public immortalsSaleActive;
    bool public frootFrensSaleActive;
    bool public publicSaleActive;

    mapping(address => bool) public projectProxy;

    constructor(string memory _setBaseURI,address _proxyRegistryAddress,address _badfroot,address _spyr)
        ERC721A("SkullKids: Generations", "SKGENS") {
        
        // Init Constants
        baseURI = _setBaseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        badfroot = _badfroot;
        spyr = _spyr;
    }
    

    // Modifiers
    modifier onlyImmortalsActive() {
        require(immortalsSaleActive, "Immortal sale is not live!");
        _;
    }

    modifier onlyFrootFrensActive() {
        require(frootFrensSaleActive, "Froot Frens sale is not live!");
        _;
    }
    
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

    function setPayoutAddresses(address _badfroot,address _spyr) external onlyOwner {
        badfroot = _badfroot;
        spyr = _spyr;
    }
    // END Set Functions


    // Merkle Functions
    function setMerkleRoots(bytes32 _godsMerkleRoot,bytes32 _immortalsMerkleRoot,bytes32 _frootFrensMerkleRoot) external onlyOwner {    
        godsMerkleRoot = _godsMerkleRoot;
        immortalsMerkleRoot = _immortalsMerkleRoot;
        frootFrensMerkleRoot = _frootFrensMerkleRoot;
    }
    
    function setGodsMerkleRoot(bytes32 _godsMerkleRoot) external onlyOwner {    
        godsMerkleRoot = _godsMerkleRoot;
    }

    function setImmortalsMerkleRoot(bytes32 _immortalsMerkleRoot) external onlyOwner {
        immortalsMerkleRoot = _immortalsMerkleRoot;
    }

    function setFrootFrensMerkleRoot(bytes32 _frootFrensMerkleRoot) external onlyOwner {
        frootFrensMerkleRoot = _frootFrensMerkleRoot;
    }
    // END Merkle Functions


    // Mint Functions
    function godsMint(uint256 _quantity, bytes32[] calldata _proof) external payable onlyImmortalsActive nonReentrant() {
        require(MerkleProof.verify(_proof, godsMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Sorry, you're not an Immortal God!");
        require(_quantity <= MAX_PER_TX, "Sorry! You can only mint a maximum of 25 SkullKids per transaction!");
        require(godsPrice * _quantity == msg.value, "Wrong amount of ETH sent");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeds maximum supply");

        _safeMint(msg.sender, _quantity);
    }


    function immortalsMint(uint256 _quantity, bytes32[] calldata _proof) external payable onlyImmortalsActive nonReentrant() {
        require(MerkleProof.verify(_proof, immortalsMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Sorry, you're not an Immortal!");
        require(_quantity <= MAX_PER_TX, "Sorry! You can only mint a maximum of 25 SkullKids per transaction!");
        require(immortalsPrice * _quantity == msg.value, "Wrong amount of ETH sent");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeds maximum supply");

        _safeMint(msg.sender, _quantity);
    }
    

    function frootFrensMint(uint256 _quantity, bytes32[] calldata _proof) external payable onlyFrootFrensActive nonReentrant() {
        require(MerkleProof.verify(_proof, frootFrensMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Sorry, you're not a Froot Fren!");
        require(_quantity <= MAX_PER_TX, "Sorry! You can only mint a maximum of 25 SkullKids per transaction!");
        require(publicPrice * _quantity == msg.value, "Wrong amount of ETH sent");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeds maximum supply");

        _safeMint(msg.sender, _quantity);
    }

    function publicMint(uint256 _quantity) external payable onlyPublicActive nonReentrant() {
        require(_quantity <= MAX_PER_TX, "Sorry! You can only mint a maximum of 25 SkullKids per transaction!");
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


    // Toggle Sales
    function toggleImmortalsSale() external onlyOwner {
        immortalsSaleActive = !immortalsSaleActive;
    }

    function toggleFrootFrensSale() external onlyOwner {
        frootFrensSaleActive = !frootFrensSaleActive;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
        
        if (publicSaleActive) {
            delete frootFrensMerkleRoot;// Tiny gas savings on transaction
            frootFrensSaleActive = false;
        }
    }
    // END Toggle Sales


    // Override start token in ERC721A
    function _startTokenId() internal view virtual override returns (uint256) {
        return 201;
    }

    // Override _baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    // Withdraw Funds to Badfroot and SPYR
    function withdraw() public payable onlyOwner {
        uint256 _balance = address(this).balance;
        uint256 percent = _balance / 100;
        
        // 75% to Badfroot (Jack Davidson)
        require(payable(badfroot).send(percent * 75));

        // 25% to SPYR (Jeff Sarris)
        require(payable(spyr).send(percent * 25));
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