// SPDX-License-Identifier: CC-BY-NC-2.5
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WrappedPenguins is
  ERC721,
  IERC721Receiver,
  Pausable,
  Ownable,
  ERC721Burnable
{
  event Wrapped(uint256 indexed tokenId);
  event Unwrapped(uint256 indexed tokenId);

  IERC721 immutable pudgyPenguins;

  constructor(address pudgyPenguinsContractAddress_)
    ERC721("WrappedPenguins", "WPG")
  {
    pudgyPenguins = IERC721(pudgyPenguinsContractAddress_);
  }

  function _baseURI() internal pure override returns (string memory) {
    return "https://arweave.net/pybbuYqUiE3jd3UchCNFJ0vEUcB2Kzi-5MnT98bzlAs/";
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /// Wrap Pudgy Penguin(s) to get Wrapped Penguin(s)
  function wrap(uint256[] calldata tokenIds_) external {
    for (uint256 i = 0; i < tokenIds_.length; i++) {
      pudgyPenguins.safeTransferFrom(msg.sender, address(this), tokenIds_[i]);
    }
  }

  /// Unwrap to get Pudgy Penguin(s) back
  function unwrap(uint256[] calldata tokenIds_) external {
    for (uint256 i = 0; i < tokenIds_.length; i++) {
      _safeTransfer(msg.sender, address(this), tokenIds_[i], "");
    }
  }

  function _flip(
    address who_,
    bool isWrapping_,
    uint256 tokenId_
  ) private {
    if (isWrapping_) {
      // Mint Wrapped Penguin of same tokenID if not yet minted, otherwise swap for existing Wrapped Pudgy
      if (_exists(tokenId_) && ownerOf(tokenId_) == address(this)) {
        _safeTransfer(address(this), who_, tokenId_, "");
      } else {
        _safeMint(who_, tokenId_);
      }
      emit Wrapped(tokenId_);
    } else {
      pudgyPenguins.safeTransferFrom(address(this), who_, tokenId_);
      emit Unwrapped(tokenId_);
    }
  }

  // Notice: You must use safeTransferFrom in order to properly wrap/unwrap your penguin.
  function onERC721Received(
    address operator_,
    address from_,
    uint256 tokenId_,
    bytes memory data_
  ) external override returns (bytes4) {
    // Only supports callback from the original PudgyPenguins contract and this contract
    require(
      msg.sender == address(pudgyPenguins) || msg.sender == address(this),
      "must be PudgyPenguin or WrappedPenguin"
    );

    bool isWrapping = msg.sender == address(pudgyPenguins);
    _flip(from_, isWrapping, tokenId_);

    return this.onERC721Received.selector;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  fallback() external payable {}

  receive() external payable {}

  function withdrawETH() external onlyOwner {
    (bool success, ) = owner().call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function withdrawERC20(address token) external onlyOwner {
    bool success = IERC20(token).transfer(
      owner(),
      IERC20(token).balanceOf(address(this))
    );
    require(success, "Transfer failed");
  }

  // @notice Mints or transfers wrapped penguin to owner for users who incorrectly transfer a Pudgy Penguin or Wrapped Penguin directly to the contract without using safeTransferFrom.
  // @dev This condition will occur if onERC721Received isn't called when transferring.
  function emergencyMintWrapped(uint256 tokenId_) external onlyOwner {
    if (pudgyPenguins.ownerOf(tokenId_) == address(this)) {
      // Contract owns the Pudgy Penguin.
      if (_exists(tokenId_) && ownerOf(tokenId_) == address(this)) {
        // Wrapped Penguin is also trapped in contract.
        _safeTransfer(address(this), owner(), tokenId_, "");
        emit Wrapped(tokenId_);
      } else if (!_exists(tokenId_)) {
        // Wrapped Penguin hasn't ever been minted.
        _safeMint(owner(), tokenId_);
        emit Wrapped(tokenId_);
      } else {
        revert("Wrapped Penguin minted and distributed already");
      }
    } else {
      revert("Pudgy Penguin is not locked in contract");
    }
  }
}