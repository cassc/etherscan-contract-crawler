// SPDX-License-Identifier: MIT
//         _              _                    _              _      _              
//        /\_\           / /\                 /\ \           /\ \   /\_\            
//       / / /  _       / /  \                \ \ \          \ \ \ / / /         _  
//      / / /  /\_\    / / /\ \               /\ \_\         /\ \_\\ \ \__      /\_\
//     / / /__/ / /   / / /\ \ \             / /\/_/        / /\/_/ \ \___\    / / /
//    / /\_____/ /   / / /  \ \ \           / / /  _       / / /     \__  /   / / / 
//   / /\_______/   / / /___/ /\ \         / / /  /\ \    / / /      / / /   / / /  
//  / / /\ \ \     / / /_____/ /\ \       / / /   \ \_\  / / /      / / /   / / /   
// / / /  \ \ \   / /_________/\ \ \  ___/ / /__  / / /_/ / /      / / /___/ / /    
/// / /    \ \ \ / / /_       __\ \_\/\__\/_/___\/ / /__\/ /      / / /____\/ /     
//\/_/      \_\_\\_\___\     /____/_/\/_________/\/_______/       \/_________/      
//                                                                                 
//
//        /\_\            /\ \       /\ \     _    /\ \         /\ \       
//       / / /  _         \ \ \     /  \ \   /\_\ /  \ \       /  \ \      
//      / / /  /\_\       /\ \_\   / /\ \ \_/ / // /\ \_\   __/ /\ \ \     
//     / / /__/ / /      / /\/_/  / / /\ \___/ // / /\/_/  /___/ /\ \ \    
//    / /\_____/ /      / / /    / / /  \/____// / / ______\___\/ / / /    
//   / /\_______/      / / /    / / /    / / // / / /\_____\     / / /     
//  / / /\ \ \        / / /    / / /    / / // / /  \/____ /    / / /    _ 
// / / /  \ \ \   ___/ / /__  / / /    / / // / /_____/ / /     \ \ \__/\_\
/// / /    \ \ \ /\__\/_/___\/ / /    / / // / /______\/ /       \ \___\/ /
//\/_/      \_\_\\/_________/\/_/     \/_/ \/___________/         \/___/_/ 
//An Augminted Labs Project


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IKKold {
    function ownerOf(uint256 tokenID) external view returns(address);
} 

contract KaijuKingzERC721 is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private baseURI;

    uint256 public maxSupply;
    uint256 public maxGenCount;
    uint256 public babyCount = 0;
    uint256 public price = 0.06666 ether;

    bool public presaleActive = false;
    bool public saleActive = false;

    mapping (address => uint256) public presaleWhitelist;
    mapping (address => uint256) public balanceGenesis;

    constructor(string memory name, string memory symbol, uint256 supply, uint256 genCount) ERC721(name, symbol) {
        maxSupply = supply;
        maxGenCount = genCount;
    }
    
    IKKold public KKold;

    function airdrop(uint256[] calldata kaijuTokens) external onlyOwner {
        for (uint256 i; i < kaijuTokens.length ; i++) {
            address ownerOfKaiju;
            uint256 kaijuToken = kaijuTokens[i];
            ownerOfKaiju = KKold.ownerOf(kaijuToken);
            _safeMint(ownerOfKaiju, kaijuTokens[i]);
            balanceGenesis[ownerOfKaiju]++;
        }
    }

    function mintPresale(uint256 numberOfMints) public payable {
        uint256 supply = totalSupply();
        uint256 reserved = presaleWhitelist[msg.sender];
        require(presaleActive,                              "Presale must be active to mint");
        require(reserved > 0,                               "No tokens reserved for this address");
        require(numberOfMints <= reserved,                  "Can't mint more than reserved");
        require(supply.add(numberOfMints) <= maxGenCount,   "Purchase would exceed max supply of Genesis KaijuKingz");
        require(price.mul(numberOfMints) == msg.value,      "Ether value sent is not correct");
        presaleWhitelist[msg.sender] = reserved - numberOfMints;

        for(uint256 i; i < numberOfMints; i++){
            _safeMint(msg.sender, supply + i);
            balanceGenesis[msg.sender]++;
        }
    }

   function mint(uint256 numberOfMints) public payable {
    uint256 supply = totalSupply();
    require(saleActive,                                 "Sale must be active to mint");
    require(numberOfMints > 0 && numberOfMints < 3,     "Invalid purchase amount");
    require(supply.add(numberOfMints) <= maxGenCount,   "Purchase would exceed max supply of Genesis KaijuKingz");
    require(price.mul(numberOfMints) == msg.value,      "Ether value sent is not correct");
        
    for(uint256 i; i < numberOfMints; i++) {
        _safeMint(msg.sender, supply + i);
        balanceGenesis[msg.sender]++;
        }
    }

    function editPresale(address[] calldata presaleAddresses, uint256[] calldata amount) external onlyOwner {
        for(uint256 i; i < presaleAddresses.length; i++){
            presaleWhitelist[presaleAddresses[i]] = amount[i];
        }
    }

    function walletOfOwner(address owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setKKold(address IKKoldAddress) external onlyOwner {
        KKold = IKKold(IKKoldAddress);
    }
    
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}