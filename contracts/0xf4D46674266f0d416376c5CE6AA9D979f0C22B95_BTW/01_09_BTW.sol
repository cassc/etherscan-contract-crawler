// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ERC721A.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BTW is ERC721A, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bool public mintStarted = false;

    mapping(address => uint256) private minted;

    uint256 private constant maxNFTs = 1000;
    uint256 private batchSize = 1;
    uint256 private maxCanOwn = 1;

    string private URI = "https://api.backtowork.wtf/nft/";

    constructor() ERC721A("Back To Work", "BTW") {}

    function mint() public nonReentrant {
        require(minted[msg.sender] + batchSize <= maxCanOwn, "limit reached");
        require(msg.sender == tx.origin);
        require(mintStarted, "Not started");
        require(_totalMinted() + batchSize < maxNFTs, "Mint ended");

        minted[msg.sender] += batchSize;
        _safeMint(msg.sender, batchSize);
    }

    function mintOwner(address _oo, uint256 amount) public onlyOwner {
        require(_totalMinted() + amount < maxNFTs, "Mint ended");
        _safeMint(_oo, amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return URI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        URI = newBaseURI;
    }

    function setMaxCanOwn(uint256 _mo) external onlyOwner {
        maxCanOwn = _mo;
    }

    function setBatchSize(uint256 _bs) external onlyOwner {
        batchSize = _bs;
    }

    function mintedTotal() public view returns (uint256) {
        return _totalMinted();
    }

    function totalMintable() public pure returns (uint256) {
        return maxNFTs;
    }

    function startMint() external onlyOwner {
        mintStarted = true;
    }

    function pauseMint() external onlyOwner {
        mintStarted = false;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}