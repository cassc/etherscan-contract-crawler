// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NFT2XA2Coin is ERC721, ERC721Enumerable, IERC721Receiver, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    event Received(address, uint);
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("NFT2XA2", "NFT2XA2") { }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    
    // Contract Receives NFT
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public override returns(bytes4) {
        return this.onERC721Received.selector;
    }

    // Transfer Out ETH Tokens
    function withdraw(address payable _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid address");
        require(address(this).balance >= _amount, "Not enough funds");
        _to.transfer(_amount);
    }

    // Receive ERC20 Tokens.
    function depositERC20(IERC20 _token, uint256 amount) external {
        _token.transferFrom(msg.sender, address(this), amount);
    }

    // Handling of standard, non-standard ERC-20 tokens
    function withdrawERC20(IERC20 _token, address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid address");
        _token.safeTransfer(_to, _amount);
    }

    // Transfer NFT
    function withdrawNFT(uint256 tokenId, address to) external onlyOwner {
         require(_exists(tokenId), "NFT does not exist");
         _safeTransfer(address(this), to, tokenId, "");
    }
    
    // Transfer Authorized NFT
    function transferNFT(uint256 tokenId, address from, address to) public onlyOwner {
    // Assume this contract has been approved to control the NFT with the given tokenId
     _safeTransfer(from, to, tokenId, '');
   }

    function safeMint(address to, string memory uri, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, ERC721URIStorage)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}