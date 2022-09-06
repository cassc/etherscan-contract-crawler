//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./INFT.sol";

contract NFT is Initializable, OwnableUpgradeable, INFT, ERC721Upgradeable {
    address public sale;
    mapping(uint256 => mapping(uint256 => string)) public uris;

    function initialize(string memory name_, string memory symbol_) public initializer {
        __ERC721_init(name_, symbol_);
        __Ownable_init();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        string memory _tokenURI = uris[tokenId][0];
        return _tokenURI;
    }

    function tokenURIS(uint256 tokenId, uint256 i) public view returns (string memory){
        string memory _tokenURI = uris[tokenId][i];
        return _tokenURI;
    }

    function changeSale (address _sale) external onlyOwner {
        require(_sale != address(0), "Zero address is not allowed");
        sale = _sale;
    }

    function mint(address user, bytes calldata _URI, uint256 tokenId) external override {
        require(msg.sender == sale, "Only sale can mint");
        string[] memory arrayURI = abi.decode(_URI, (string[]));
        for (uint256 i = 0; i < arrayURI.length; i++) {
            uris[tokenId][i] = arrayURI[i];
        }
        _safeMint(user, tokenId);
    }
}