// SPDX-License-Identifier: MIT

// DropCase.sol --

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDropCase.sol";
import "../lib/RelayRecipient.sol";
import "../lib/BlackholePrevention.sol";

contract DropCase is IDropCase, ERC721, Ownable, RelayRecipient, IERC721Receiver, BlackholePrevention {
  using Counters for Counters.Counter;
  uint256 public constant INITIAL_PRICE = 0 ether;

  uint256 internal _mintPrice;

  Counters.Counter internal _tokenCount;
  mapping (uint256 => address) internal _tokenCreator;


  /***********************************|
  |          Initialization           |
  |__________________________________*/
  constructor() public ERC721("Dropcase NFT", "DropCase") {
    _mintPrice = INITIAL_PRICE;
  }

  function onERC721Received(address, address, uint256, bytes calldata) external virtual override returns (bytes4) {
    return IERC721Receiver(0).onERC721Received.selector;
  }

  function creatorOf(uint256 tokenId) external view override returns (address) {
    return _tokenCreator[tokenId];
  }

  function mintNft(address receiver, string memory tokenUri) external payable override onlyOwner returns (uint256 newTokenId) {
    require(msg.value >= _mintPrice, "Not enough ETH sent: check price.");
    return _mintNft(msg.sender, receiver, tokenUri);
  }

  function _mintNft(address creator, address receiver, string memory tokenUri) internal returns (uint256 newTokenId) {
    _tokenCount.increment();
    newTokenId = _tokenCount.current();

    _safeMint(receiver, newTokenId, "");
    _tokenCreator[newTokenId] = creator;

    _setTokenURI(newTokenId, tokenUri);
    return newTokenId;
  }

  /***********************************|
  |          GSN/MetaTx Relay         |
  |__________________________________*/

  /// @dev See {BaseRelayRecipient-_msgSender}.
  function _msgSender()
    internal
    view
    virtual
    override(BaseRelayRecipient, Context)
    returns (address payable)
  {
    return BaseRelayRecipient._msgSender();
  }

  /// @dev See {BaseRelayRecipient-_msgData}.
  function _msgData()
    internal
    view
    virtual
    override(BaseRelayRecipient, Context)
    returns (bytes memory)
  {
    return BaseRelayRecipient._msgData();
  }

  function setMintPrice(uint256 price) external onlyOwner {
    _mintPrice = price;
    emit NewMintPrice(price);
  }
  /***********************************|
  |          Only Admin/DAO           |
  |      (blackhole prevention)       |
  |__________________________________*/

  function withdrawEther(address payable receiver, uint256 amount)
      external
      onlyOwner
  {
      _withdrawEther(receiver, amount);
  }

  function withdrawERC20(
      address payable receiver,
      address tokenAddress,
      uint256 amount
  ) external onlyOwner {
      _withdrawERC20(receiver, tokenAddress, amount);
  }

  function withdrawERC721(
      address payable receiver,
      address tokenAddress,
      uint256 tokenId
  ) external onlyOwner {
      _withdrawERC721(receiver, tokenAddress, tokenId);
  }
}