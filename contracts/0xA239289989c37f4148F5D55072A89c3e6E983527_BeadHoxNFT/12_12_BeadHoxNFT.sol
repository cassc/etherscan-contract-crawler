// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract BeadHoxNFT is ERC721, Ownable {
    uint256 public mintPrice;
    uint256 public mintWLPrice;
    uint256 public mintFreePrice;

    uint256 public totalSupply;
    uint256 public totalSupplyWL;
    uint256 public totalSupplyFREE;

    uint256 public maxSupply;
    uint256 public maxSupplyWL;
    uint256 public maxSupplyFREE;

    uint256 public maxPerWallet;
    uint256 public maxPerWalletWL;
    uint256 public maxPerWalletFREE;

    bool public isMintEnabled;
    bool public isWLEnabled;
    bool public isFreeEnabled;

    bool public isRevealed;
    string internal baseTokenUri;
    string internal revealUrl;
    address payable public withdrawWallet;

    mapping(address => uint256) public walletMints;
    mapping(address => uint256) public walletMintsWL;
    mapping(address => uint256) public walletMintsFREE;

    mapping(address => bool) public allowList;
    mapping(address => bool) public allowListFREE;

    constructor() payable ERC721('BeadHox', 'BHX') {
        mintPrice = 0.0098 ether;
        mintWLPrice = 0.0088 ether;
        mintFreePrice = 0 ether;

        totalSupply = 0;
        totalSupplyWL = 0;
        totalSupplyFREE = 0;

        maxSupply = 1777;
        maxSupplyWL = 1777;
        maxSupplyFREE = 333;
        
        maxPerWallet = 3;
        maxPerWalletWL = 3;
        maxPerWalletFREE = 1;
    }

    function revealCollection(bool isRevealed_) external onlyOwner {
        isRevealed = isRevealed_;
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function setRevealUri(string calldata baseRevealUri_) external onlyOwner {
        revealUrl = baseRevealUri_;
    }

    function IsMintEnabledd(bool isPublicMintEnabled_) external onlyOwner {
        isMintEnabled = isPublicMintEnabled_;
    }

    function IsFreeEnabledd(bool isFreeEnabled_) external onlyOwner {
        isFreeEnabled = isFreeEnabled_;
    }

    function IsWLEnabledd(bool isWLEnabled_) external onlyOwner {
        isWLEnabled = isWLEnabled_;
    }

    function AddPersonWL(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++){
            allowList[addresses[i]] = true;
        }
    }

    function AddPersonFREE(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++){
            allowListFREE[addresses[i]] = true;
        }
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), 'Token does not exist!');
        if (isRevealed == true) {
         return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));   
        } else {
            return string(abi.encodePacked(revealUrl));
        }         
    }

    function mint(uint quantity_) public payable {        
        require(isMintEnabled, 'Minting not enabled yet');
        require(msg.value == quantity_ * mintPrice, 'Wrong mint value');
        require(totalSupply + quantity_ <= maxSupply, 'Project is Sold out');
        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, 'Exceed max wallet on mint');

        for (uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            totalSupplyWL++;
            _safeMint(msg.sender, newTokenId);
        }
        walletMints[msg.sender] += quantity_;            
    }

    function mintWl(uint quantity_) public payable {        
        require(allowList[msg.sender], "You are not in the White List");
        require(isWLEnabled, 'WL not enabled yet');
        require(msg.value == quantity_ * mintWLPrice, 'Wrong mint value');
        require(totalSupplyWL + quantity_ <= maxSupplyWL, 'White List is Sold out');
        require(walletMintsWL[msg.sender] + quantity_ <= maxPerWalletWL, 'Exceed max wallet on WL list');

        for (uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            totalSupplyWL++;
            _safeMint(msg.sender, newTokenId);
        }
        walletMintsWL[msg.sender] += quantity_;
    }

    function mintFree(uint quantity_) public payable {        
        require(allowListFREE[msg.sender], "You are not in the FREE List");
        require(msg.value == quantity_ * mintFreePrice, 'Wrong mint value');
        require(isFreeEnabled, 'FREE not enabled yet');
        require(totalSupplyFREE + quantity_ <= maxSupplyFREE, 'FREE is Sold out');
        require(walletMintsFREE[msg.sender] + quantity_ <= maxPerWalletFREE, 'Exceed max wallet on FREE mint');

        for (uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            totalSupplyWL++;
            totalSupplyFREE++;
            _safeMint(msg.sender, newTokenId);
        }
        walletMintsFREE[msg.sender] += quantity_;
    }

    function withdrawAll() external payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 balanceOne = balance * 100 / 100;
        uint256 balanceTwo = balance * 0 / 100;
        ( bool transferOne, ) = payable(0x8fC0EF2c02F8A248DD98ED26316556d8B2d65E00).call{value: balanceOne}("");
        ( bool transferTwo, ) = payable(0x8fC0EF2c02F8A248DD98ED26316556d8B2d65E00).call{value: balanceTwo}("");
        require(transferOne && transferTwo, "Transfer failed.");
    }

}