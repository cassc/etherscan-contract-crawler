// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Portal is Ownable, ERC721, IERC721Receiver {
    /// @notice Total number of NFTs.
    uint256 private _totalSupply = 0;

    /// @notice URI
    string private _uri = "";

    /// @notice NFT
    IERC721 private _nft;

    /// @notice Events
    event ERC721Received(address operator, address _from, uint256 tokenId);

    /// @notice Initializes the contract by setting a `name` and a `symbol` to the token collection.
    constructor(string memory name_, string memory symbol_, address nft_) ERC721(name_, symbol_) {
        _nft = IERC721(nft_);
    }

    /// @notice Get the total number of NFTs.
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Mint NFTs.
    function mint(uint256 index) public {
        _nft.safeTransferFrom(msg.sender, address(this), index);

        _safeMint(msg.sender, index);
        _totalSupply += 1;
    }

    /// @notice Burn NFTs.
    function burn(uint256 index) public {
        _nft.safeTransferFrom(address(this), msg.sender, index);

        _burn(index);
        _totalSupply -= 1;
    }

    /// @notice set base URI
    function setBaseURI(string memory uri) external onlyOwner {
        _uri = uri;
    }

    /// @notice URL where the metadata are located.
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external override returns (bytes4) {
        _data;
        emit ERC721Received(_operator, _from, _tokenId);
        // TODO
        // return 0x5175f878;
        return 0x150b7a02;
    }
}