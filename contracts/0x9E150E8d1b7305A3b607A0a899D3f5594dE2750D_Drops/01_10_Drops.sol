// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Drops is ERC1155, Ownable {
    struct dropVariables {
        uint256 price;
        uint256 maxSupply;
        uint256 supply;
        string tokenURI;
        bool saleIsActive;
    }

    mapping(uint256 => dropVariables) public dropInfo;

    constructor(address _owner) ERC1155("") {
        transferOwnership(_owner);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return (dropInfo[id].tokenURI);
    }

    function activateSale(uint256 id) public onlyOwner {
        dropInfo[id].saleIsActive = true;
    }

    function deactivateSale(uint256 id) public onlyOwner {
        dropInfo[id].saleIsActive = false;
    }

    function createDrop(
        uint256 id,
        uint256 price,
        uint256 supplyAmt,
        string memory tokenURI
    ) public onlyOwner {
        require(dropInfo[id].maxSupply == 0, "Drop already exists");
        dropInfo[id].price = price;
        dropInfo[id].maxSupply = supplyAmt;
        dropInfo[id].tokenURI = tokenURI;
    }

    function editDrop(
        uint256 id,
        uint256 price,
        uint256 supplyAmt,
        string memory tokenURI
    ) public onlyOwner {
        require(dropInfo[id].maxSupply != 0, "Drop does not exist");
        require(dropInfo[id].supply <= supplyAmt, "Supply cannot be decreased");
        dropInfo[id].price = price;
        dropInfo[id].maxSupply = supplyAmt;
        dropInfo[id].tokenURI = tokenURI;
    }

    function devMint(
        uint256 id,
        address[] calldata recipients,
        uint256[] calldata amount
    ) public onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(amount[i] <= dropInfo[id].maxSupply, "Supply exceeded");
            _mint(recipients[i], id, amount[i], "");
            dropInfo[id].supply += amount[i];
        }
    }

    function mintDrop(uint256 id, uint256 amount) public payable {
        require(dropInfo[id].saleIsActive == true, "Sale is not active");
        require(dropInfo[id].maxSupply > 0, "Drop is not yet available");
        require(
            dropInfo[id].supply + amount <= dropInfo[id].maxSupply,
            "Sold out"
        );
        require(
            msg.value / amount == dropInfo[id].price,
            "Drop price is incorrect"
        );

        _mint(msg.sender, id, amount, "");
        dropInfo[id].supply += amount;
    }

    function withdraw() public {
        require(address(this).balance >= 0, "No ether");
        payable(owner()).transfer(address(this).balance);
    }
}