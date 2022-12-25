//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/Counters.sol";

contract AsrayaGenesis is ERC721URIStorage, ERC721Royalty, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIDCounter;
    uint96 public constant royaltyFeeNumerator = 1000; // 10%
    uint256 public constant maximumSupply = 144;
    string private baseTokenURI;

    event Received(address indexed sender, uint256 amount);

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        _setDefaultRoyalty(address(this), royaltyFeeNumerator);
    }

    // This override additionally clears the royalty information for the token.
    function _burn(uint256 tokenId)
        internal
        override(ERC721URIStorage, ERC721Royalty)
    {
        super._burn(tokenId);
    }

    // Internal function to return _baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Set the base URI
    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    // Return the token URI
    function tokenURI(uint256)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return _baseURI();
    }

    // Mint the token for an address
    function mintFor(address owner) external onlyOwner {
        require(
            _tokenIDCounter.current() < maximumSupply,
            "Maximum supply minted"
        );
        _tokenIDCounter.increment();
        _mint(owner, _tokenIDCounter.current());
    }

    // Override the supportsInterface function to add ERC721Royalty support
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Withdraw ETH from royalties
    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Withdraw ERC20 tokens from royalties
    function withdrawERC20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }

    // Allow reception of ETH
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }
}