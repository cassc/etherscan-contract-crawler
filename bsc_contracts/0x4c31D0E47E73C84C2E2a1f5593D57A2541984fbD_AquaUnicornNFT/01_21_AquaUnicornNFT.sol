// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/GeneScienceInterface.sol";
import "./libraries/UniswapV2Library.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


/*          :~^             .^^^^:.         ^^:     :^^          ^~:         :~:     .^^.     ^^.     ^^:     :^^         .:^^~^.         :^~~^:         .^~~~~~^:.      .~^.    .~^.            
                  ?B##5         ^YGB#####G5!.     Y###^   :B##5       .5##B7       7###7   .B##G.   Y##BJ   J###^   ^B##5     .7PB#####B:     ~5GB####BG5~     .G#######BB5:   .G##G~  .G##G.           
                 ?#BBB#Y       Y#B#BY?7JPBB#G^    5BB#~   ~BBBP      .P#BBBB7      J#B#J   :BBBG.   PBBB#G^ YBB#!   ~BBBG    ^G#BB5J???~    .P#B#GY??YG#B#5.   .BBBBJ!!?BB#P   :BBBBBY..BBBG.           
                ?#BBPBB#J     J#BBY. .^: ~BBBG.   5BB#~   ^BBBP     .PBBGPBBB~     JBB#J   :BBBG.   5BBBBBB?5BB#!   ~BBBG   .GBBB^          P#BBJ.    .YBB#5   .BBBB:.:!BB#Y   .BBBBB#G7BBBG.           
               ?#BB5:YBB#?    5#B#! .G#BP7GBBB.   5BB#~   ^BBBP    .PBBB?:GBBB^    JBB#?   :BBBG.   5BBBPBBBBBB#!   ~BBBG   :BBBG          .GBBB~      !BBBG   .BBBB!B#BBP~    .BBBGGBBBBBBG.           
              ?#BB#BBB#BBB?   ^B#BB?:^YBB#BBB?    J#BB5:.:YBB#Y   .P#BB#BBBBBBB^   !#BBP^.:?BBBG    5BBB^^G#BBB#!   ~BBBG    Y#BBP~:...     !BBBB?^::^?BBBB!   .BBBB:~BBBG^    .BBBP.?BBBBBG.           
             ?#B#P~^^^~G#B#!   .YB###BBB###B#J    .5####B####P.   P#B#Y^^^^7BB#B.   YB###B####G^    P#B#^ .JB#B#!   ~#B#G     ?G####BBBG.    ^5B###B####B5^    .B#B#: ^G###?   :BB#G  ^P#B#B.           
             ^Y5J.     :Y5J:     .~?Y55YJ~~Y5!      :7Y5555?^     !557      !557.    :7J555Y?~.     ^Y5?    ^Y5?.   .?5Y~      .^7Y5555?       :!JY55YJ~.       755?   .J5Y^    755~   .755!      
*/
contract AquaUnicornNFT is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint;
    using Strings for uint;
    uint256 nextTokenId;
    uint256 public priceOnBUSD = 50 * 10**18;
    address constant busdAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    uint8 public devReserved = 0 ;

    event Birth(address owner, uint256[] unicornId, bytes32[] genes);
    mapping (uint=>Unicorn) public UnicornInfo;
    mapping (address => uint8) public mintedCount;
    string public baseURI;
    struct Unicorn {
        bytes32 genes;
        uint64 birthTime;
        uint32 matronId;
        uint32 sireId;
        uint16 generation;
    }
    GeneScienceInterface public geneScience;
    address public poolAddress;
    IERC20 auniToken;

    enum Rare {
        COMMON,
        RARE,
        SUPERRARE,
        EPIC,
        SUPEREPIC,
        LEGEND,
        SLEGEND,
        SUPREME
    }

    constructor(address _auniToken, address _poolAddress ,address _geneScience) ERC721('AquaUnicornNFT','AUNINFT') Ownable(){
        auniToken = IERC20(_auniToken);
        poolAddress = _poolAddress;
        geneScience = GeneScienceInterface(_geneScience);
    }

    function getRareByGenes(bytes32 gens) public view returns (Rare){
        uint8 tempInt = uint8(geneScience._parseBytes32(gens, 0));
        if(0<tempInt && tempInt<=153){
            return Rare.COMMON;
        } else if(tempInt<153 && tempInt<= 204){
            return Rare.RARE;
        } else if(tempInt<204 && tempInt<= 229){
            return Rare.SUPERRARE;
        } else if(tempInt<229 && tempInt<= 239){
            return Rare.EPIC;
        } else if(tempInt<239 && tempInt<= 246){
            return Rare.SUPEREPIC;
        } else if(tempInt<246 && tempInt<= 252){
            return Rare.LEGEND;
        } else if(tempInt<252 && tempInt<= 255){
            return Rare.SLEGEND;
        } else {
            return Rare.SUPREME;
        }
    }

    function getRare(uint tokenId) public view returns (Rare){
        Unicorn storage unicorn = UnicornInfo[tokenId];
        return getRareByGenes(unicorn.genes);
    }

     function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function devReserve(uint8 amount) external onlyOwner{
        require(devReserved+amount <100 , "reached mint limit");
        uint[] memory tokenIds = new uint[](amount);
        bytes32[] memory genes = new bytes32[](amount);
        for(uint i =0; i<amount ;i ++) {
            uint256 tokenId  = nextTokenId;
            _safeMint(msg.sender, tokenId);
            bytes32 gens = geneScience.randomGenes(block.timestamp*i);
            Unicorn memory unicornInfo;
            unicornInfo.genes = gens;
            unicornInfo.birthTime = uint64(block.timestamp);
            unicornInfo.generation = 0;
            unicornInfo.matronId = 0;
            UnicornInfo[tokenId] = unicornInfo;
            tokenIds[i] = tokenId;
            genes[i] = gens;
            nextTokenId++;
        }
        mintedCount[msg.sender] = mintedCount[msg.sender] + amount;
        emit Birth(msg.sender, tokenIds, genes);
    }


    function mint(uint8 amount) external {
        require(mintedCount[msg.sender]+amount <10 , "User reached mint limit");
        uint256 auniTokenRequire = estimateAUNI(amount);
        auniToken.transferFrom(msg.sender, poolAddress, auniTokenRequire);
        uint[] memory tokenIds = new uint[](amount);
        bytes32[] memory genes = new bytes32[](amount);
        for(uint i =0; i<amount ;i ++) {
            uint256 tokenId  = nextTokenId;
            _safeMint(msg.sender, tokenId);
            bytes32 gens = geneScience.randomGenes(block.timestamp*i);
            Unicorn memory unicornInfo;
            unicornInfo.genes = gens;
            unicornInfo.birthTime = uint64(block.timestamp);
            unicornInfo.generation = 0;
            unicornInfo.matronId = 0;
            UnicornInfo[tokenId] = unicornInfo;
            tokenIds[i] = tokenId;
            genes[i] = gens;
            nextTokenId++;
        }
        mintedCount[msg.sender] = mintedCount[msg.sender] + amount;
        emit Birth(msg.sender, tokenIds, genes);
    }

    function updateGeneScience(address _geneScience) public onlyOwner{
        geneScience = GeneScienceInterface(_geneScience);
    }

    function updateBaseURI(string memory _baseURI) public onlyOwner{
        baseURI = _baseURI;
    }

    function updatePrice(uint _priceOnBUSD) public onlyOwner{
        priceOnBUSD = _priceOnBUSD;
    }

    function updatePoolAddress(address _poolAddress) public onlyOwner{
        poolAddress = _poolAddress;
    }

    function estimateAUNI(uint256 quantity) public view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        path[1] = address(auniToken);

        uint256 auniPerBNB = UniswapV2Library.getAmountsOut(
            0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73,
            10**18,
            path
        )[1];

        path[0] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        path[1] = busdAddress;

        uint256 busdPerBNB = UniswapV2Library.getAmountsOut(
            0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73,
            10**18,
            path
        )[1];
        uint256 auniAmount = priceOnBUSD.mul((auniPerBNB.div(busdPerBNB)));
        return quantity.mul(auniAmount);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721,ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721,ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

}