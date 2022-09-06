// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DatarailsExecelArtsNFT is ERC721, Ownable {
    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    bool public isPublicMintEnabled;
    string internal baseTokenUri;
    address payable public withdrawWallet;
    mapping(address => uint256) public walletMints;
    mapping(uint256 => uint256) public mintedNFTs;

    constructor() payable ERC721('DatarailsExeclArtsNFT', 'DRX'){
        mintPrice = 1 ether;
        totalSupply = 0;
        maxSupply = 5;
        maxPerWallet = 1;
        // set withdraw address
        // withdrawWallet = 0x7595C1B36110c1cddB021626d2f43E25BdF6Cd16;
    }

    function setIsPublicMintEnabled(bool isPublicMintEnabled_) external onlyOwner {
        isPublicMintEnabled = isPublicMintEnabled_;
    }

    function getCount() public view returns (uint256) {
        return totalSupply;
    }

    function isContentOwned(uint256 id_) public view returns (bool) {
        return mintedNFTs[id_] == id_;
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) { 
        require(_exists(tokenId_), 'Token does not exist!');
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), '.json'));
    }

    function withdraw() external onlyOwner {
        (bool success, ) = withdrawWallet.call{value: address(this).balance }('');
        require(success , 'withdraw faild');
    }

    function setNftPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function mint(uint tokenId_) public payable {
        require(isPublicMintEnabled, 'Minting not enabled yet.');
        require(msg.value == 1 * mintPrice , 'Wrong mint value');
        require(totalSupply + 1 <= maxSupply, 'Sold out');
        require(walletMints[msg.sender] + 1 <= maxPerWallet , 'Exceed max wallet');

            uint256 newTokenId = tokenId_;
            totalSupply++;
            mintedNFTs[newTokenId] = newTokenId;
            _safeMint(msg.sender, newTokenId);
    }
}