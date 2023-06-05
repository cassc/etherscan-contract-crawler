// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EveraiMemoryCore is ERC721A, ReentrancyGuard, Ownable {
    string private _baseTokenURI;

    address public authorizedBurnContractAddress;
    address public authorizedMintContractAddress;
    address public everaiBannerAddress;

    constructor() ERC721A("EveraiMemoryCore", "EveraiMemoryCore") {}

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setAuthorizedBurnContractAddress(
        address authorizedBurnContractAddress_
    ) external onlyOwner {
        authorizedBurnContractAddress = authorizedBurnContractAddress_;
    }

    function setAuthorizedMintContractAddress(
        address authorizedMintContractAddress_
    ) external onlyOwner {
        authorizedMintContractAddress = authorizedMintContractAddress_;
    }

    function setEveraiBannerAddress(address everaiBannerAddress_)
        external
        onlyOwner
    {
        everaiBannerAddress = everaiBannerAddress_;
    }

    function mint(address to, uint256 quantity) external {
        require(
            msg.sender == owner() ||
                authorizedMintContractAddress == msg.sender ||
                everaiBannerAddress == msg.sender,
            "Authorization required"
        );

        _safeMint(to, quantity);
    }

    function burn(uint256 tokenId) external {
        require(
            msg.sender == owner() ||
                authorizedBurnContractAddress == msg.sender,
            "Authorization required"
        );

        _burn(tokenId);
    }
}