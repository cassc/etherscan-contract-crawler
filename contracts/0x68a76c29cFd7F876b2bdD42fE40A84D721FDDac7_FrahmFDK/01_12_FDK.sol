// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FrahmFDK is ERC1155, Ownable, ReentrancyGuard {
    string public name;
    string public symbol;
    string public metadataUri;

    uint public currentIndex;

    constructor() ERC1155("") {
        name = "Frahm FDK Season1";
        symbol = "FRAHMFDKS1";
        metadataUri = "https://api.frahm.art/fdk/metadata/";
    }

    function mint(uint _amount) external payable callerIsUser {
        _mint(msg.sender, currentIndex, _amount, "");
        currentIndex++;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setBaseUri(string calldata baseUri) external onlyOwner {
        metadataUri = baseUri;
    }

    function uri(uint _id) public override view returns (string memory) {
        return string(abi.encodePacked(metadataUri, Strings.toString(_id)));
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}