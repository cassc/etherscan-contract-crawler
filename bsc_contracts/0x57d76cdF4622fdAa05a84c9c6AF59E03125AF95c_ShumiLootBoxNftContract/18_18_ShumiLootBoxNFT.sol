// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ShumiLootBoxNftContract is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    address public freeMintAddress;
    uint256 private freeMintCount;
    uint256 public tokenPrice = 8000000 * 1 * 10 ** 18 ;
    IERC20 public shumiTokenAddress;
    address public farmAddress;

    constructor(address tokenAddress) ERC721("ShumiLootBoxNftContract", "MTK") {
        shumiTokenAddress = IERC20(tokenAddress);
        freeMintCount = 500;
    }

    function setFarmingAddress(address farmingAddress) public onlyOwner {
        farmAddress = farmingAddress;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return "https://ipfs.filebase.io/ipfs/QmbjyY2fAy3mHJzvKyXidrNk8x4bvgouktsMqvANR8QZ8J";
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setFreeMintAddress(address mintAddress) public onlyOwner {
        freeMintAddress = mintAddress;
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function mint() public {
        uint256 tokenId = _tokenIdCounter.current();
        if (msg.sender != freeMintAddress || tokenId >= freeMintCount) {
            require(farmAddress != address(0));
            shumiTokenAddress.transferFrom(msg.sender, farmAddress, tokenPrice);
        }
        _mint(msg.sender, tokenId);
        _tokenIdCounter.increment();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    whenNotPaused
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}