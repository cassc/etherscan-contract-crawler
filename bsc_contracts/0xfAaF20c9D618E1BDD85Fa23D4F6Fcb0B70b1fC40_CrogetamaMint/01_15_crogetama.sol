// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CrogetamaMint is ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    uint256 public totalMintAmount = 1000;
    uint256 public pricePerNft = 0.05 ether;
    string public baseTokenURI =
        "https://ipfs.io/ipfs/QmZHxgKKZjokJJTn7fospxxJF2wQkkEMdTsU6KguNH7Mk1/";
    mapping(address => uint256) mintedTokens; //  userAddress => tokenId
    address[] keysOfMintedTokens; //  keys of mintedTokens
    address[] whitelist; //  whitelist for private sale
    bool useWhitelist = false;
    address public withdrawRecipient;

    constructor(address withdrawRecipient_) ERC721("Crogetama NFTs", "CROGETAMA") {
        withdrawRecipient = withdrawRecipient_;
    }

    function mint(address recipient, string memory tokenURI)
        public payable 
        returns (uint256)
    {
        require(msg.value >= pricePerNft, "Incorrect price!");
        require(msg.sender == tx.origin, "Mint directly from contract not allowed. Use the website.");

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

     function setWithdrawRecipient(
        address _withdrawRecipient
    ) external onlyOwner {
        withdrawRecipient = _withdrawRecipient;
    }

    function clearData() external onlyOwner {
        delete totalMintAmount;
        delete pricePerNft;
        delete baseTokenURI;

        for (uint256 i = 0; i < keysOfMintedTokens.length; i++) {
            delete mintedTokens[keysOfMintedTokens[i]];
        }
        
        delete keysOfMintedTokens;
        delete whitelist;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setTotalMintAmount(uint256 _totalMintAmount) external onlyOwner {
        totalMintAmount = _totalMintAmount;
    }

    function setPricePerNft(uint256 _pricePerNft) external onlyOwner {
        pricePerNft = _pricePerNft;
    }

    function withdraw() external {
        payable(withdrawRecipient).transfer(address(this).balance);
    }
}