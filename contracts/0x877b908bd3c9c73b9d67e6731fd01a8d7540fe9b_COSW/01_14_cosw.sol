// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// COSW by Allyson Grey
// dev by 4mat
//  ________/\\\\\\\\\_______/\\\\\__________/\\\\\\\\\\\____/\\\______________/\\\_                          
//   _____/\\\////////______/\\\///\\\______/\\\/////////\\\_\/\\\_____________\/\\\_                         
//    ___/\\\/_____________/\\\/__\///\\\___\//\\\______\///__\/\\\_____________\/\\\_                        
//     __/\\\______________/\\\______\//\\\___\////\\\_________\//\\\____/\\\____/\\\__                       
//      _\/\\\_____________\/\\\_______\/\\\______\////\\\_______\//\\\__/\\\\\__/\\\___                      
//       _\//\\\____________\//\\\______/\\\__________\////\\\_____\//\\\/\\\/\\\/\\\____                     
//        __\///\\\___________\///\\\__/\\\_____/\\\______\//\\\_____\//\\\\\\//\\\\\_____                    
//         ____\////\\\\\\\\\____\///\\\\\/_____\///\\\\\\\\\\\/_______\//\\\__\//\\\______                   
//          _______\/////////_______\/////_________\///////////__________\///____\///_______                  
//  __/\\\________________________________                                                                    
//   _\/\\\________________________________                                                                   
//    _\/\\\___________/\\\__/\\\___________                                                                  
//     _\/\\\__________\//\\\/\\\____________                                                                 
//      _\/\\\\\\\\\_____\//\\\\\_____________                                                                
//       _\/\\\////\\\_____\//\\\______________                                                               
//        _\/\\\__\/\\\__/\\_/\\\_______________                                                              
//         _\/\\\\\\\\\__\//\\\\/________________                                                             
//          _\/////////____\////__________________                                                            
//  _____/\\\\\\\\\_____/\\\\\\_____/\\\\\\___________________________________________________________        
//   ___/\\\\\\\\\\\\\__\////\\\____\////\\\___________________________________________________________       
//    __/\\\/////////\\\____\/\\\_______\/\\\_______/\\\__/\\\__________________________________________      
//     _\/\\\_______\/\\\____\/\\\_______\/\\\______\//\\\/\\\___/\\\\\\\\\\_____/\\\\\_____/\\/\\\\\\___     
//      _\/\\\\\\\\\\\\\\\____\/\\\_______\/\\\_______\//\\\\\___\/\\\//////____/\\\///\\\__\/\\\////\\\__    
//       _\/\\\/////////\\\____\/\\\_______\/\\\________\//\\\____\/\\\\\\\\\\__/\\\__\//\\\_\/\\\__\//\\\_   
//        _\/\\\_______\/\\\____\/\\\_______\/\\\_____/\\_/\\\_____\////////\\\_\//\\\__/\\\__\/\\\___\/\\\_  
//         _\/\\\_______\/\\\__/\\\\\\\\\__/\\\\\\\\\_\//\\\\/_______/\\\\\\\\\\__\///\\\\\/___\/\\\___\/\\\_ 
//          _\///________\///__\/////////__\/////////___\////________\//////////_____\/////_____\///____\///__
//  _____/\\\\\\\\\\\\____________________________________________                                            
//   ___/\\\//////////_____________________________________________                                           
//    __/\\\_____________________________________________/\\\__/\\\_                                          
//     _\/\\\____/\\\\\\\__/\\/\\\\\\\______/\\\\\\\\____\//\\\/\\\__                                         
//      _\/\\\___\/////\\\_\/\\\/////\\\___/\\\/////\\\____\//\\\\\___                                        
//       _\/\\\_______\/\\\_\/\\\___\///___/\\\\\\\\\\\______\//\\\____                                       
//        _\/\\\_______\/\\\_\/\\\_________\//\\///////____/\\_/\\\_____                                      
//         _\//\\\\\\\\\\\\/__\/\\\__________\//\\\\\\\\\\_\//\\\\/______                                     
//          __\////////////____\///____________\//////////___\////________                                    
//  _________/\\\_________________________________________                                                    
//   ________\/\\\_________________________________________                                                   
//    ________\/\\\_________________________________________                                                  
//     ________\/\\\______/\\\\\\\\___/\\\____/\\\___________                                                 
//      ___/\\\\\\\\\____/\\\/////\\\_\//\\\__/\\\____________                                                
//       __/\\\////\\\___/\\\\\\\\\\\___\//\\\/\\\_____________                                               
//        _\/\\\__\/\\\__\//\\///////_____\//\\\\\______________                                              
//         _\//\\\\\\\/\\__\//\\\\\\\\\\____\//\\\_______________                                             
//          __\///////\//____\//////////______\///________________                                            
//  __/\\\______________________                                                                              
//   _\/\\\______________________                                                                             
//    _\/\\\___________/\\\__/\\\_                                                                            
//     _\/\\\__________\//\\\/\\\__                                                                           
//      _\/\\\\\\\\\_____\//\\\\\___                                                                          
//       _\/\\\////\\\_____\//\\\____                                                                         
//        _\/\\\__\/\\\__/\\_/\\\_____                                                                        
//         _\/\\\\\\\\\__\//\\\\/______                                                                       
//          _\/////////____\////________                                                                      
//  ____________/\\\_____________________________________________________                                     
//   __________/\\\\\_____________________________________________________                                    
//    ________/\\\/\\\___________________________________________/\\\______                                   
//     ______/\\\/\/\\\_______/\\\\\__/\\\\\____/\\\\\\\\\_____/\\\\\\\\\\\_                                  
//      ____/\\\/__\/\\\_____/\\\///\\\\\///\\\_\////////\\\___\////\\\////__                                 
//       __/\\\\\\\\\\\\\\\\_\/\\\_\//\\\__\/\\\___/\\\\\\\\\\_____\/\\\______                                
//        _\///////////\\\//__\/\\\__\/\\\__\/\\\__/\\\/////\\\_____\/\\\_/\\__                               
//         ___________\/\\\____\/\\\__\/\\\__\/\\\_\//\\\\\\\\/\\____\//\\\\\___                              
//          ___________\///_____\///___\///___\///___\////////\//______\/////____                                                                                                                                                                                                                  

contract COSW is ERC721Enumerable, ReentrancyGuard, Ownable {
    string baseTokenURI;
    bool public tokenURIFrozen = false;
    address public payoutAddress;
    uint256 public totalTokens;

    uint256 public mintPrice = 0.111 ether;
    // ======== Provenance =========
    string public provenanceHash = "";

    //map whitelist addys that have claimed
    mapping(address => bool) public whitelistMinted;

    bool public saleIsActive = false;
    bool public preSaleIsActive = false;
    mapping(address => bool) private presaleList;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _totalTokens,
        address _payoutAddress
    ) ERC721(name, symbol) {
        baseTokenURI;
        totalTokens = _totalTokens;
        payoutAddress = _payoutAddress;
        for (uint256 i = 0; i < 33; i++) {
            _safeMint(payoutAddress, nextTokenId());
        }
    }

    function nextTokenId() internal view returns (uint256) {
        return totalSupply() + 1;
    }

    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't mint to the null address");
            presaleList[addresses[i]] = true;
        }
    }

    function withdraw() external onlyOwner {
        payable(payoutAddress).transfer(address(this).balance);
    }

    function mint() external payable nonReentrant {
        require(saleIsActive, "Sale not active");
        require(msg.value >= mintPrice, "More eth required");
        require(totalSupply() < totalTokens, "Sold out");
        require(!whitelistMinted[msg.sender], "Address has already minted.");

        whitelistMinted[msg.sender] = true;
        _safeMint(msg.sender, nextTokenId());
    }

    function mintPresale() external payable nonReentrant {
        require(preSaleIsActive, "Presale not active");
        require(msg.value >= mintPrice, "More eth required");
        require(totalSupply() < totalTokens, "Sold out");
        require(presaleList[msg.sender] == true, "Not on presale list");
        require(!whitelistMinted[msg.sender], "Address has already minted.");
    
        whitelistMinted[msg.sender] = true;
        _safeMint(msg.sender, nextTokenId());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(tokenURIFrozen == false, 'Token URIs are Frozen');
        baseTokenURI = baseURI;
    }

    function setPayoutAddress(address _payoutAddress) public onlyOwner {
        payoutAddress = _payoutAddress;
    }


    // ======== Provenance =========
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        mintPrice = _newPrice;
    }
}