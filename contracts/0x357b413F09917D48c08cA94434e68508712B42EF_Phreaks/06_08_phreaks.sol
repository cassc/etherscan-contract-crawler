// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Phreaks is ReentrancyGuard, Ownable, ERC721A {
    uint256 public max_wallet = 10;
    uint256 public price = 0.001 ether;
    uint256 public total_supply = 10000;
    uint256 public reserve_mints = 50;
    bool public open_mint = false;
    string public metadata = "https://bafybeievckp4u4qf2apvgdpfx4kiwqcf3xxmlfmvxrp3wgodjx4bhaq57u.ipfs.nftstorage.link/";

    constructor() ERC721A("JunglePhreaks", "PHREAKS") {

    }

    function mintPhreaks(uint256 amount) external payable nonReentrant {
        require(open_mint);
        require(amount > 0);
        require(_numberMinted(msg.sender) + amount <= max_wallet);
        require(totalSupply() + amount <= total_supply);
        require(price * amount <= msg.value);

        _mint(msg.sender, amount);
    }

    function reserveForTeam() external onlyOwner {
        require(totalSupply() + reserve_mints <= total_supply);
        require(balanceOf(msg.sender) == 0);
        _mint(msg.sender, reserve_mints);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadata;
    }

    function setMetadata(string memory new_metadata) external virtual onlyOwner {
        metadata = new_metadata;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function openMint() external onlyOwner {
        open_mint = true;
    }

    function closeMint() external onlyOwner {
        open_mint = false;
    }

}