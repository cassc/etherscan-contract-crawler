// SPDX-License-Identifier: MIT
// ____                            ___       ______                                           
///\  _`\   __                    /\_ \     /\__  _\   __                                     
//\ \ \L\ \/\_\    __  _     __   \//\ \    \/_/\ \/  /\_\      __        __    _ __    ____  
// \ \ ,__/\/\ \  /\ \/'\  /'__`\   \ \ \      \ \ \  \/\ \   /'_ `\    /'__`\ /\`'__\ /',__\ 
//  \ \ \/  \ \ \ \/>  </ /\  __/    \_\ \_     \ \ \  \ \ \ /\ \L\ \  /\  __/ \ \ \/ /\__, `\
//   \ \_\   \ \_\ /\_/\_\\ \____\   /\____\     \ \_\  \ \_\\ \____ \ \ \____\ \ \_\ \/\____/
//    \/_/    \/_/ \//\/_/ \/____/   \/____/      \/_/   \/_/ \/___L\ \ \/____/  \/_/  \/___/ 
//                                                              /\____/                       
//                                                              \_/__/    
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface iPixelERC20 {
    function burn(address _from, uint256 _amount) external;
    function rewardSystemUpdate(address _from, address _to) external;
    function timeStamp(address user) external;
} 

contract PixelTigers721 is ERC721, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private baseTokenURI;

    uint256 public totalMaxSupply = 13332;
    uint256 public totalAmtGenesis = 4444;
    uint256 public babyCount = 0;
    uint256 public price = 0.069 ether;
    uint256 public constant MAX_PER_MINT = 2;
    uint256 public amtReserved;

    uint256 internal currentSupply;

    bool public presaleActive = false;
    bool public publicSaleActive = false;
    bool public reserveActive = false;
    bool public breedActive = false;

    mapping (address => uint256) public presaleWhitelist;
    mapping (address => uint256) public reservedList;
    mapping (address => uint256) public ownerGenesisCount;

    mapping (uint256 => address) internal ownsThisToken;

    iPixelERC20 public Pixel;

    constructor(string memory baseURI) ERC721("PixelTigers", "PT") {
        setBaseURI(baseURI);
    }

    function presaleMint(uint256 _count) public payable {
        uint256 supply = currentSupply;
        uint256 reserved = presaleWhitelist[msg.sender];
        require(presaleActive,"Presale not active");
        require(reserved > 0,"Not whitelisted");
        require(_count <= reserved,"Can't mint more than reserved");
        require(supply.add(_count) <= totalAmtGenesis - amtReserved,"Supply exceeded"); 
        require(price.mul(_count) == msg.value,"Value sent not correct");
        presaleWhitelist[msg.sender] = reserved - _count;
        currentSupply += _count;
        Pixel.timeStamp(msg.sender);

        for(uint256 i; i < _count; i++){
            _safeMint(msg.sender, supply + i);
            ownerGenesisCount[msg.sender]++;
            ownsThisToken[supply+i] = msg.sender;
        }
    }

   function mint(uint256 _count) public payable {
        uint256 supply = currentSupply;
        require(publicSaleActive,"Mint not active");
        require(_count > 0 && _count <= MAX_PER_MINT,"Invalid purchase amount");
        require(supply.add(_count) <= totalAmtGenesis - amtReserved,"Supply exceeded");
        require(price.mul(_count) == msg.value, "Value sent not correct");
        require(msg.sender == tx.origin);
        currentSupply += _count;
        Pixel.timeStamp(msg.sender);

        for(uint256 i; i < _count; i++) {
            _safeMint(msg.sender, supply + i);
            ownerGenesisCount[msg.sender]++;
            ownsThisToken[supply+i] = msg.sender;
        }
    }

    function reserveMint(uint256 _count) public payable {
        uint256 supply = currentSupply;
        uint256 _reserved = reservedList[msg.sender];
        require(reserveActive,"Mint not active");
        require(_reserved > 0,"Not on reserved list");
        require(_count <= _reserved,"Can't mint more than reserved");
        require(supply.add(_count) <= totalAmtGenesis); 
        reservedList[msg.sender] = _reserved - _count;
        currentSupply += _count;
        Pixel.timeStamp(msg.sender);

        for(uint256 i; i < _count; i++){
            _safeMint(msg.sender, supply + i);
            ownerGenesisCount[msg.sender]++;
            ownsThisToken[supply+i] = msg.sender;
        }
    }

    function settokenERC20(address tokenERC20Address) external onlyOwner {
        Pixel = iPixelERC20(tokenERC20Address);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function totalSupply() public view returns (uint) {
        return currentSupply + babyCount;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}