// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC721A} from "ERC721A/contracts/ERC721A.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

error ExceedsMaxSupply();

contract MegaPepes is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 165;

    string public baseURI;
    string public contractURI;

    constructor(string memory _newBaseURI, string memory _contractURI) ERC721A("MegaPepes", "MPEPE") {
        baseURI = _newBaseURI;
        contractURI = _contractURI;
    }

    /// @dev See {ERC721A-_startTokenId}.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function getContractURI() public view returns (string memory) {
        return contractURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setContractURI(string memory _newContractURI) public onlyOwner {
        contractURI = _newContractURI;
    }

    function batchMint(address[] memory recipients) external onlyOwner {
        uint256 newTotalSupply = totalSupply() + recipients.length;
        require(newTotalSupply <= MAX_SUPPLY, "ExceedsMaxSupply");

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], 1);
        }
    }
}