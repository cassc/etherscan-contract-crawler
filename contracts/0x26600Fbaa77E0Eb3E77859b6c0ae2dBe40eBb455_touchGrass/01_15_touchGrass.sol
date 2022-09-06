// SPDX-License-Identifier: MIT

/*
,---------.    ,-----.      ___    _     _______   .---.  .---.           .-_'''-.   .-------.       ____       .-'''-.    .-'''-.  
\          \ .'  .-,  '.  .'   |  | |   /   __  \  |   |  |_ _|          '_( )_   \  |  _ _   \    .'  __ `.   / _     \  / _     \ 
 `--.  ,---'/ ,-.|  \ _ \ |   .'  | |  | ,_/  \__) |   |  ( ' )         |(_ o _)|  ' | ( ' )  |   /   '  \  \ (`' )/`--' (`' )/`--' 
    |   \  ;  \  '_ /  | :.'  '_  | |,-./  )       |   '-(_{;}_)        . (_,_)/___| |(_ o _) /   |___|  /  |(_ o _).   (_ o _).    
    :_ _:  |  _`,/ \ _/  |'   ( \.-.|\  '_ '`)     |      (_,_)         |  |  .-----.| (_,_).' __    _.-`   | (_,_). '.  (_,_). '.  
    (_I_)  : (  '\_/ \   ;' (`. _` /| > (_)  )  __ | _ _--.   |         '  \  '-   .'|  |\ \  |  |.'   _    |.---.  \  :.---.  \  : 
   (_(=)_)  \ `"/  \  ) / | (_ (_) _)(  .  .-'_/  )|( ' ) |   |          \  `-'`   | |  | \ `'   /|  _( )_  |\    `-'  |\    `-'  | 
    (_I_)    '. \_/``".'   \ /  . \ / `-'`-'     / (_{;}_)|   |           \        / |  |  \    / \ (_ o _) / \       /  \       /  
    '---'      '-----'      ``-'`-''    `._____.'  '(_,_) '---'            `'-...-'  ''-'   `'-'   '.(_,_).'   `-...-'    `-...-'                                                                                                                                    
*/


pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract touchGrass is ERC721A, Ownable, PaymentSplitter {

    string public baseURI;

    uint256 public price = 0.02 ether;
    uint256 public maxPerTx = 5;
    uint256 public maxPerWallet = 10;
    uint256 public maxSupply = 5500;
    uint256 public maxFree = 500;

    bool public publicSaleIsLive;

    mapping (address => uint256) public claimAvailable;
    mapping (address => bool) public snapshot;

    constructor(address[] memory payees, uint256[] memory shares) ERC721A("Touch Grass", "TG") PaymentSplitter(payees, shares) {}

    function mint(uint256 amount) external payable {
        uint256 cost = price;

        uint256 genesisBalance = checkElyGenesisBalance(msg.sender);

       if (totalSupply() + amount <= maxFree) {
            cost = 0;
        }
        else {
            if(!snapshot[msg.sender] && genesisBalance  > 0) {
                claimAvailable[msg.sender] = genesisBalance;
                snapshot[msg.sender] = true;
            }
            if(snapshot[msg.sender] && amount <= claimAvailable[msg.sender]) {
                cost = 0.01 ether;
            }
        }
        require(msg.sender == tx.origin, "You can't mint from a contract.");
        require(msg.value == amount * cost, "Please send the exact amount in order to mint.");
        require(totalSupply() + amount <= maxSupply, "Better Luck next time, Sold out.");
        require(publicSaleIsLive, "Public sale is not live yet.");
        require(numberMinted(msg.sender) + amount <= maxPerWallet, "You have exceeded the mint limit per wallet.");
        require(amount <= maxPerTx, "You have exceeded the mint limit per transaction.");

        _safeMint(msg.sender, amount);

        if(snapshot[msg.sender] && claimAvailable[msg.sender] > 0) {
            claimAvailable[msg.sender]-=amount;
        } else {
            claimAvailable[msg.sender] = claimAvailable[msg.sender];
        }
    }

    function toggleSaleState() external onlyOwner {
        publicSaleIsLive = !publicSaleIsLive;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }


    function setPrice(uint256 price_) external onlyOwner {
      price = price_;
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
      maxPerTx = maxPerTx_;
    } 

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
      maxPerWallet = maxPerWallet_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
    }

    function checkElyGenesisBalance(address owner) public view returns (uint256) {
         return IERC1155(0x6FF0dB1BDe0763dB159619c55BFf809f21Bdb667).balanceOf(owner, 0) +
                IERC1155(0x6FF0dB1BDe0763dB159619c55BFf809f21Bdb667).balanceOf(owner, 1) +
                IERC1155(0x6FF0dB1BDe0763dB159619c55BFf809f21Bdb667).balanceOf(owner, 2) +
                IERC1155(0x6FF0dB1BDe0763dB159619c55BFf809f21Bdb667).balanceOf(owner, 3) +
                IERC1155(0x6FF0dB1BDe0763dB159619c55BFf809f21Bdb667).balanceOf(owner, 4);
    }
}