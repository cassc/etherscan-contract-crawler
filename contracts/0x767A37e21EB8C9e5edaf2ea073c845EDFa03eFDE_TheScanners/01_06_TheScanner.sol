//                                                      <SPDX-License-Identifier: MIT>
//
//           _________  ___  ___  _______           ________  ________  ________  ________   ________   _______   ________  ________      
//          |\___   ___\\  \|\  \|\  ___ \         |\   ____\|\   ____\|\   __  \|\   ___  \|\   ___  \|\  ___ \ |\   __  \|\   ____\     
//          \|___ \  \_\ \  \\\  \ \   __/|        \ \  \___|\ \  \___|\ \  \|\  \ \  \\ \  \ \  \\ \  \ \   __/|\ \  \|\  \ \  \___|_    
//               \ \  \ \ \   __  \ \  \_|/__       \ \_____  \ \  \    \ \   __  \ \  \\ \  \ \  \\ \  \ \  \_|/_\ \   _  _\ \_____  \   
//               \ \  \ \ \  \ \  \ \  \_|\ \       \|____|\  \ \  \____\ \  \ \  \ \  \\ \  \ \  \\ \  \ \  \_|\ \ \  \\  \\|____|\  \  
//                 \ \__\ \ \__\ \__\ \_______\        ____\_\  \ \_______\ \__\ \__\ \__\\ \__\ \__\\ \__\ \_______\ \__\\ _\ ____\_\  \ 
//                  \|__|  \|__|\|__|\|_______|       |\_________\|_______|\|__|\|__|\|__| \|__|\|__| \|__|\|_______|\|__|\|__|\_________\
//                                                    \|_________|                                                            \|_________|
//                                                                                                                             
//                                                                                                                              
//
//
//
//
//                                                                     [email protected]@@@@@@                     
//                                                                  @(           @@                 
//                                                                @                &@               
//                                                               @                  /@              
//                                                               @                   @              
//                                                               @                  @@              
//                                                                @,               @@               
//                                                                  @@           @@@@               
//                                                                      %@@@@@,     (@@@@           
//                                                                                    @@@@@@        
//                                                                                      @@@@@@      
//                                                                                         @@@@% 
//                                                                                           @@@)
//      
//

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC721A} from 'erc721a/contracts/ERC721A.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract TheScanners is ERC721A('TheScanners', 'SCNR'), Ownable, ReentrancyGuard {
    uint256 public maxSupply = 999;
    uint256 public mintCost = 0.005 ether;
    uint256 public maxPerTx = 1;
    uint256 public maxFreePerWallet = 1;
    uint256 public maxPerWallet = 5;
    uint256 public totalFree = 300;
    uint256 public freeMintedAmount = 0;
    bool public mintEnabled = false;

    mapping(address => uint256) public _totalFreeMintedAmount;
    mapping(address => uint256) public _totalPaidMintedAmount;

    string public baseURI = '';
    string public metadataExtentions = '';

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    modifier isMintEnabled() {
        require(mintEnabled, "Mint is not live yet");
        _;
    }

    function testMint(uint quantity, address user) public onlyOwner {
        require(quantity > 0, "Invalid mint amount");
        require(totalSupply() + quantity <= maxSupply, "Maximum supply exceeded");
        _safeMint(user, quantity);
    }

    function freeMint() external payable callerIsUser isMintEnabled {
        bool isFree = ((freeMintedAmount + 1 <= totalFree) &&
            (_totalFreeMintedAmount[msg.sender] < maxFreePerWallet));
        
        require(
            _totalPaidMintedAmount[msg.sender] + 1 <= maxPerWallet - _totalFreeMintedAmount[msg.sender],
            "Exceed maximum NFTs per wallet"
        );
        
        require(isFree, "Free amount is over.");
        require(totalSupply() + 1 <= maxSupply, "Over Max Supply");

        _totalFreeMintedAmount[msg.sender] += 1;
        freeMintedAmount += 1;
        _safeMint(msg.sender, 1);
    }

    function mint(uint256 quantity) external payable callerIsUser isMintEnabled {
        require(
            _totalPaidMintedAmount[msg.sender] + quantity <= maxPerWallet - _totalFreeMintedAmount[msg.sender],
            "Exceed maximum NFTs per wallet"
        );
        require(msg.value >= quantity * mintCost, "Please send the exact ETH amount");
        require(totalSupply() + quantity <= maxSupply, "Over Max Supply");
        require(quantity <= maxPerTx, "Max per TX reached.");

        _totalPaidMintedAmount[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function toggleMint(bool _state) public onlyOwner {
        mintEnabled = _state;
    }

    function withdraw() public payable nonReentrant onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function setMintCost(uint256 _newCost) public onlyOwner {
        mintCost = _newCost;
    }

    function setMaxFreePerWallet(uint256 _newMaxFreePerWallet) public onlyOwner {
        maxFreePerWallet = _newMaxFreePerWallet;
    }

    function setTotalFree(uint256 _newTotalFree) public onlyOwner {
        totalFree = _newTotalFree;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setMaxPerTx(uint256 _newMaxPerTx) public onlyOwner {
        maxPerTx = _newMaxPerTx;
    }

    function setMaxPerWallet(uint256 _newMaxPerWallet) public onlyOwner {
        maxPerWallet = _newMaxPerWallet;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMetadataExtentions(string memory _newMetadataExtentions) public onlyOwner {
        metadataExtentions = _newMetadataExtentions;
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), metadataExtentions));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}