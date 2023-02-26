// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WhatsTheMeme is ERC1155, Ownable {
    string public name = "WhatsTheMeme";
    string public symbol = "WTM";

    uint256 remaining = 1000;
    uint256 public updatePrice = 4206900000000000; // 0.0042069 ETH
    string public contractUriLocation = "https://arweave.net/uGZgtbVJZslIhTDWUFySeqbUGqX67tFrvU8aTSb-sHY";

    event UpdateContractURI(string oldUri, string contractUriLocation);

    constructor()
        ERC1155("https://arweave.net/O08SXje_2DOyoqRFjneIKre6Y_Ota-u6i_o_YGKPuAM")
    {}

    function contractURI() public view returns (string memory) {
        return contractUriLocation;
    }

    function updateContractURI(string memory newUri) external onlyOwner {
        string memory oldUri = contractUriLocation;
        contractUriLocation = newUri;
        emit UpdateContractURI(oldUri, contractUriLocation);
    }

    function getUpdatePrice() public view returns (uint256) {
        return updatePrice;
    }

    function getRemaining() public view returns (uint256) {
        return remaining;
    }

    function setURI(string memory newuri) public payable {
        require(balanceOf(msg.sender, 0) > 0, "Must hold a WhatsTheMeme NFT.");
        require(msg.value >= updatePrice, "Not enough ETH sent.");
        _setURI(newuri);
    }

    function mint(address account) public payable {
        require(msg.value >= 0.01 ether, "Not enough ETH sent.");
        require(remaining > 0, "Supply limit reached.");
        _mint(account, 0, 1, "");
        remaining--;
    }

    function airdrop(address account) public onlyOwner {
        require(remaining > 0, "Supply limit reached.");
        _mint(account, 0, 1, "");
        remaining--;
    }

    function setUpdatePrice(uint256 newPrice) public onlyOwner {
        updatePrice = newPrice;
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function withdraw() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}