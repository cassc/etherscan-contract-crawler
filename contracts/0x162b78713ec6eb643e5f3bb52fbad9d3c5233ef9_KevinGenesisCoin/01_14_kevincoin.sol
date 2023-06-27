// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// dev by 4mat and g3nr8r


//  ██████  ███████ ██    ██                           
//  ██   ██ ██      ██    ██                           
//  ██   ██ █████   ██    ██                           
//  ██   ██ ██       ██  ██                            
//  ██████  ███████   ████                             
//                                                     
//                                                     
//  ██████  ██    ██                                   
//  ██   ██  ██  ██                                    
//  ██████    ████                                     
//  ██   ██    ██                                      
//  ██████     ██                                      
//                                                     
//                                                     
//  ██   ██ ███    ███  █████  ████████                
//  ██   ██ ████  ████ ██   ██    ██                   
//  ███████ ██ ████ ██ ███████    ██                   
//       ██ ██  ██  ██ ██   ██    ██                   
//       ██ ██      ██ ██   ██    ██                   
//                                                     
//                                                     
//   █████  ███    ██ ██████                           
//  ██   ██ ████   ██ ██   ██                          
//  ███████ ██ ██  ██ ██   ██                          
//  ██   ██ ██  ██ ██ ██   ██                          
//  ██   ██ ██   ████ ██████                           
//                                                     
//                                                     
//   ██████  ██████  ███    ██ ██████   █████  ██████  
//  ██            ██ ████   ██ ██   ██ ██   ██ ██   ██ 
//  ██   ███  █████  ██ ██  ██ ██████   █████  ██████  
//  ██    ██      ██ ██  ██ ██ ██   ██ ██   ██ ██   ██ 
//   ██████  ██████  ██   ████ ██   ██  █████  ██   ██ 
//                                                     
                                                                                                                                                                                                              
contract KevinGenesisCoin is ERC721Enumerable, ReentrancyGuard, Ownable {
    string baseTokenURI;
    bool public tokenURIFrozen = false;
    address public payoutAddress;
    uint256 public totalTokens = 1250;
    uint256 public vaultLimit = 250;
    uint256 public mintPrice = 0 ether;
    uint256 public perWallet = 1;
    bool public saleIsActive = false;
    uint256 public vaultMinted = 0;


    constructor(
        address _payoutAddress
    ) ERC721("Kevin Genesis Coin", "KEVIN") {
        payoutAddress = _payoutAddress;
    }

     function mintVault(uint256 _vaultMintQuantity, address _vaultMintAddress) 
        external 
        nonReentrant 
        onlyOwner {
        require(vaultMinted < vaultLimit, "Vault Minted"); 
        for (uint256 i = 0; i < _vaultMintQuantity; i++) {
            if (vaultMinted < vaultLimit) {
                _safeMint(_vaultMintAddress, nextTokenId());
                vaultMinted++;
            }  
        }
    }

    function nextTokenId() internal view returns (uint256) {
        return totalSupply() + 1;
    }

    function withdraw() external onlyOwner {
        payable(payoutAddress).transfer(address(this).balance);
    }

    function mint() external payable nonReentrant {
        require(saleIsActive, "Sale not active");
        require(msg.value >= mintPrice, "More eth required");
        require(totalSupply() < totalTokens, "Sold out");
        require(balanceOf(msg.sender) < perWallet, "Per wallet limit exceeded");

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

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setPerWallet(uint256 _newPerWallet) public onlyOwner() {
        perWallet = _newPerWallet;
    }

    function setVaultLimit(uint256 _newVaultLimit) public onlyOwner() {
        vaultLimit = _newVaultLimit;
    }

    function setTotalTokens(uint256 _newTotalTokens) public onlyOwner() {
        totalTokens = _newTotalTokens;
    }
}