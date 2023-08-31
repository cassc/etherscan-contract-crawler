// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

/**
 * 10000 8bit bears on eth. ʕ·ᴥ·ʔ 
 */
contract EightBitBears is ERC721A, Ownable, ReentrancyGuard {
    
    string private _baseTokenURI = "https://ipfs.io/ipfs/QmaP49q8T54wJNcuyqXaiVdgapcqQCHJiD6u6neAd5fHgM/";

    uint256 private _max_mint_per_account = 25;

    mapping(address => uint256) _account_mint_count;

    constructor() ERC721A("EightBit Bears", "EBB", 50, 10000) {}

    function mint(uint256 quantity) external {
        require(totalSupply() + quantity <= collectionSize, "already mint out");
        require(quantity <= maxBatchSize, "can only mint less than the maxBatchSize");
        address to = msg.sender;
        require(_account_mint_count[to] + quantity <= _max_mint_per_account, "over the max minting per account");
        
        _safeMint(to, quantity);
        _account_mint_count[to] += quantity;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function queryMintAmount(address owner) external view returns(uint256) {
        return _account_mint_count[owner];
    }
}