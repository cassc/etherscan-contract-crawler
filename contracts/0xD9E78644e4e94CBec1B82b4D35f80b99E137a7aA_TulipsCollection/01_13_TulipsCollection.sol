// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TulipsCollection is ERC721, Ownable {
    using Strings for uint256;
    
    uint256 public constant MAX_SUPPLY = 500;
    uint256 private constant MAX_PER_ADDRESS = 20;
    uint256 public constant COST = 0.002 ether;

    uint256 public totalSupply = 0;
    mapping(address => uint256) private mintedAmount;

    string private baseUri = "";
    string private baseExtension = ".json";

    bool private paused = false;
    
    constructor(string memory baseUri_) ERC721("TulipsCollection", "TUC") {
        transferOwnership(0x61fe35875816B489EDa32ED210156207EdD0F190);
        baseUri = baseUri_;
    }

    function mint(uint256 mintAmount) public payable {
        require(totalSupply < MAX_SUPPLY, "minting is over");
        require(!paused, "minting is stopped");
        require(msg.value == COST * mintAmount, "");
        require(mintedAmount[msg.sender] + mintAmount <= MAX_PER_ADDRESS, "too many amount");
        require(totalSupply + mintAmount <= MAX_SUPPLY, "too many amount");

        for (uint256 i = 1; i <= mintAmount; i++) {
            totalSupply++;
            _safeMint(msg.sender, totalSupply);
        }
        mintedAmount[msg.sender] += mintAmount;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "noexistent token");

        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, tokenId.toString(), baseExtension)) : "";
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public virtual onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }

    function setBaseUri(string memory newBaseUri) public onlyOwner {
        baseUri = newBaseUri;
    }

    function setBaseExtension(string memory newBaseExtension) public onlyOwner {
        baseExtension = newBaseExtension;
    }
}