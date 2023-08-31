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

contract BlotterParty is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public totalTokens = 101;
    uint256 public vaultLimit = 20;
    uint256 public vaultMinted = 0;
    uint256 public mintPrice = 0.222 ether;
    uint256 public perWallet = 1;
    uint256 public devAmt = 3 ether;

    string baseTokenURI;
    bool public tokenURIFrozen = false;

    address public payoutAddress;
    address public devAddress;

    //map preSale addys that have claimed
    mapping(address => bool) public alreadyMinted;

    bool public saleIsActive = false;
    bool public preSaleIsActive = false;
    mapping(address => bool) private presaleList;
    bool public devPaid = false;


constructor(
        address _payoutAddress
    ) ERC721("Blotter Party", "BLTRPY") {
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

    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't mint to the null address");
            presaleList[addresses[i]] = true;
        }
    }

    function withdraw() external onlyOwner {
        require(devPaid == true, "Can't Withdraw Until Dev Paid");
        payable(payoutAddress).transfer(address(this).balance);
    }

    function payDev() external onlyOwner {
        require(devAddress != address(0), "Set devAddress before payDev Will Run.");
        require(address(this).balance >= devAmt, "Not enough ETH yet to payDev");
        require(devPaid == false, "dev has already been paid");

        devPaid = true;
        payable(devAddress).transfer(devAmt);
    }    

    function mint() external payable nonReentrant {
        require(saleIsActive, "Sale not active");
        require(msg.value >= mintPrice, "More eth required");
        require(totalSupply() < totalTokens, "Sold out");
        require(!alreadyMinted[msg.sender], "Address has already minted");
        require(balanceOf(msg.sender) < perWallet, "Per wallet limit exceeded");

        alreadyMinted[msg.sender] = true;
        _safeMint(msg.sender, nextTokenId());
    }

    function mintPresale() external payable nonReentrant {
        require(preSaleIsActive, "Presale not active");
        require(msg.value >= mintPrice, "More eth required");
        require(totalSupply() < totalTokens, "Sold out");
        require(presaleList[msg.sender] == true, "Not on presale list");
        require(!alreadyMinted[msg.sender], "Address has already minted");
        require(balanceOf(msg.sender) < perWallet, "Per wallet limit exceeded");
    
        alreadyMinted[msg.sender] = true;
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

    function setVaultLimit(uint256 _newVaultLimit) public onlyOwner() {
        vaultLimit = _newVaultLimit;
    }

    function setTotalTokens(uint256 _newTotalTokens) public onlyOwner() {
        totalTokens = _newTotalTokens;
    }

    function setPayoutAddress(address _payoutAddress) public onlyOwner {
        payoutAddress = _payoutAddress;
    }

    function setDevAddress(address _devAddress) public onlyOwner {
        devAddress = _devAddress;
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

    function setPerWallet(uint256 _newPerWallet) public onlyOwner() {
        perWallet = _newPerWallet;
    }
}