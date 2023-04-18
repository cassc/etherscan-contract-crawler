// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

//import "hardhat/console.sol";

import "contracts/lib/Ownable.sol";
import "contracts/lib/HasFactories.sol";
import "contracts/INftController.sol";
import "contracts/nft/IMintableNft.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BaseNft is ERC721, Ownable, HasFactories, IMintableNft {
    using Strings for uint256;
    string internal _baseUri;
    string internal _burnedUri;
    string internal _winUri;
    INftController immutable _controller;
    uint256 _mintedCount;
    mapping(uint256 => uint256) _mintPrices;

    constructor(
        address controller_,
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        _controller = INftController(controller_);
    }

    function controller() external view returns (address) {
        return address(_controller);
    }

    function canFactoriesChange(
        address account
    ) internal view virtual override returns (bool) {
        return account == _owner;
    }

    function mintedCount() external returns (uint256) {
        _mintedCount;
    }

    function mint(address to, uint256 price) external payable onlyFactory {
        _controller.checkCanMint();
        ++_mintedCount;
        _mintPrices[_mintedCount] = price;
        _mint(to, _mintedCount);
    }

    function burn(uint256 tokenId) external onlyFactory {
        _burn(tokenId);
    }

    function setBaseUrl(string calldata baseUri) external onlyOwner {
        _baseUri = baseUri;
    }

    function setBurnedUrl(string calldata uri) external onlyOwner {
        _burnedUri = uri;
    }

    function setWinUrl(string calldata uri) external onlyOwner {
        _winUri = uri;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        if (_controller.isGameOver()) {
            WinData memory data = _controller.winData();
            if (data.nftAddress == address(this) && data.tokenId == _tokenId)
                return _winUri;
        }
        
        if (
            _tokenId == 0 ||
            _ownerOf(_tokenId) == address(0) ||
            _ownerOf(_tokenId) ==
            address(0x000000000000000000000000000000000000dEaD)
        ) return string.concat(_burnedUri);

        return string.concat(_baseUri, (_tokenId).toString(), ".json");
    }
}