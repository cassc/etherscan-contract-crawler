// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "ERC721xyz.sol";
import "Ownable.sol";

contract ExtendedCollectionMH is ERC721xyz, Ownable {
    string private baseURI;
    string public contractURI;
    bool internal isLockedURI;

    constructor(string memory name_, string memory symbol_,
                string memory contractURI_, string memory baseURI_,
                uint256 tokensCount_, address receiver_) ERC721xyz(name_, symbol_) {
        baseURI = baseURI_;
        contractURI = contractURI_;
        // Instant airdrop
        _mint(receiver_, tokensCount_);
    }

    // return Base URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Lock metadata forever
    function lockURI() external virtual onlyOwner {
        isLockedURI = true;
    }

    // modify the base URI
    function changeBaseURI(string memory newBaseURI) onlyOwner public {
        require(!isLockedURI, "URI change has been locked");
        baseURI = newBaseURI;
    }

    // modify the contract URI
    function changeContractURI(string memory newContractURI) onlyOwner public {
        require(!isLockedURI, "URI change has been locked");
        contractURI = newContractURI;
    }
}