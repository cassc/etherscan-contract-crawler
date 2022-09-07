// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ApyTopPriorityPass is ERC721A, ERC721ABurnable, Ownable {
    string public metadataURI = "https://api.apy.top/pass/priorityPass/";

    address public contractReceiver;

    constructor() ERC721A("ApyTopPriorityPass", "ATPP") {
        contractReceiver = msg.sender;
    }

    // metadata uri

    function _baseURI() internal view override returns (string memory) {
        return metadataURI;
    }

    function setBaseURI(string calldata _uri) public onlyOwner {
        metadataURI = _uri;
    }

    // receiver

    function setContractReceiver(address _receiver) external onlyOwner {
        contractReceiver = _receiver;
    }

    // pass management

    function mint() external {
        _mint(msg.sender, 1);
    }

    function mintByOwner(uint256 quantity) external onlyOwner {
        _mint(msg.sender, quantity);
    }

    function airdropByOwner(
        address[] calldata _addresses,
        uint8[] calldata _counts
    ) external onlyOwner {
        for (uint32 i = 0; i < _addresses.length; ++i) {
            _mint(_addresses[i], _counts[i]);
        }
    }
}