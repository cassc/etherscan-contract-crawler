// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "hardhat/console.sol";

import "contracts/lib/Ownable.sol";
import "contracts/lib/IMintableNft.sol";
import "contracts/lib/HasFactories.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

contract FFWARSNft is ERC721Enumerable, HasFactories, Ownable, IMintableNft {
    using PRBMathUD60x18 for uint256;
    using Strings for uint256;

    uint256 constant _maxMintCount = 3240;

    string internal _baseUri =
        "https://v7a64-nqaaa-aaaap-qbgtq-cai.raw.icp0.io/";
    uint256 _mintedCount;

    constructor() ERC721("FFWARS NFT", "FFWARS") {}

    function setBaseUrl(string calldata uri) external onlyOwner {
        _baseUri = uri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return string.concat(_baseUri, (tokenId).toString(), ".json");
    }

    function mint(address to) external onlyFactory {
        require(_mintedCount < _maxMintCount, "No tokens left to mint");
        ++_mintedCount;
        _mint(to, _mintedCount);
    }

    function mintedCount() external view returns (uint256) {
        return _mintedCount;
    }

    function maxMintCount() external pure returns (uint256) {
        return _maxMintCount;
    }

    function canFactoriesChange(
        address account
    ) internal view override returns (bool) {
        return account == _owner;
    }
}