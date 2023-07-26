// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

/*

 ▄▄▄▄    █    ██ ▓█████▄   ██████     ██▓ ███▄    █      ██████  ██▓███   ▄▄▄       ▄████▄  ▓█████ 
▓█████▄  ██  ▓██▒▒██▀ ██▌▒██    ▒    ▓██▒ ██ ▀█   █    ▒██    ▒ ▓██░  ██▒▒████▄    ▒██▀ ▀█  ▓█   ▀ 
▒██▒ ▄██▓██  ▒██░░██   █▌░ ▓██▄      ▒██▒▓██  ▀█ ██▒   ░ ▓██▄   ▓██░ ██▓▒▒██  ▀█▄  ▒▓█    ▄ ▒███   
▒██░█▀  ▓▓█  ░██░░▓█▄   ▌  ▒   ██▒   ░██░▓██▒  ▐▌██▒     ▒   ██▒▒██▄█▓▒ ▒░██▄▄▄▄██ ▒▓▓▄ ▄██▒▒▓█  ▄ 
░▓█  ▀█▓▒▒█████▓ ░▒████▓ ▒██████▒▒   ░██░▒██░   ▓██░   ▒██████▒▒▒██▒ ░  ░ ▓█   ▓██▒▒ ▓███▀ ░░▒████▒
░▒▓███▀▒░▒▓▒ ▒ ▒  ▒▒▓  ▒ ▒ ▒▓▒ ▒ ░   ░▓  ░ ▒░   ▒ ▒    ▒ ▒▓▒ ▒ ░▒▓▒░ ░  ░ ▒▒   ▓▒█░░ ░▒ ▒  ░░░ ▒░ ░
▒░▒   ░ ░░▒░ ░ ░  ░ ▒  ▒ ░ ░▒  ░ ░    ▒ ░░ ░░   ░ ▒░   ░ ░▒  ░ ░░▒ ░       ▒   ▒▒ ░  ░  ▒    ░ ░  ░
 ░    ░  ░░░ ░ ░  ░ ░  ░ ░  ░  ░      ▒ ░   ░   ░ ░    ░  ░  ░  ░░         ░   ▒   ░           ░   
 ░         ░        ░          ░      ░           ░          ░                 ░  ░░ ░         ░  ░
      ░           ░                                                                ░                    
                  
 */

contract BudsInSpace is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public _metadata;
    bool public minting = false;
    uint256 public buds = 3333;
    uint256 public walletMaximum = 2;
    mapping(address => uint256) public budsPerWallet;

    constructor() ERC721A("Buds in Space", "SPUDS") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _metadata;
    }

    function mint(uint256 amount) external nonReentrant {
        uint256 supply = totalSupply();
        require(minting);
        require(supply + amount < buds + 1);
        require(msg.sender == tx.origin);
        require(budsPerWallet[msg.sender] + amount < walletMaximum + 1);
        _safeMint(msg.sender, amount);
        budsPerWallet[msg.sender] += amount;
    }

    function flipMintable() external onlyOwner {
        minting = !minting;
    }

    function changeWalletMax(uint256 _walletMaximum) external onlyOwner {
        walletMaximum = _walletMaximum;
    }

    function setMetadata(string memory metadata) external onlyOwner {
        _metadata = metadata;
    }

    function godMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity < buds + 1);
        _safeMint(msg.sender, quantity);
    } // hehe nice (〃 ω 〃)

    function withdrawFunds() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}