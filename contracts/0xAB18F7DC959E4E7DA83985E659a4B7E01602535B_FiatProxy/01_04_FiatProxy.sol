//  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄
// ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
// ▐░█▀▀▀▀▀▀▀▀▀  ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌ ▀▀▀▀█░█▀▀▀▀
// ▐░▌               ▐░▌     ▐░▌       ▐░▌     ▐░▌
// ▐░█▄▄▄▄▄▄▄▄▄      ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌     ▐░▌
// ▐░░░░░░░░░░░▌     ▐░▌     ▐░░░░░░░░░░░▌     ▐░▌
// ▐░█▀▀▀▀▀▀▀▀▀      ▐░▌     ▐░█▀▀▀▀▀▀▀█░▌     ▐░▌
// ▐░▌               ▐░▌     ▐░▌       ▐░▌     ▐░▌
// ▐░▌           ▄▄▄▄█░█▄▄▄▄ ▐░▌       ▐░▌     ▐░▌
// ▐░▌          ▐░░░░░░░░░░░▌▐░▌       ▐░▌     ▐░▌
//  ▀            ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀       ▀

//  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄       ▄  ▄         ▄
// ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌     ▐░▌▐░▌       ▐░▌
// ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌ ▐░▌   ▐░▌ ▐░▌       ▐░▌
// ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌  ▐░▌ ▐░▌  ▐░▌       ▐░▌
// ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌   ▐░▐░▌   ▐░█▄▄▄▄▄▄▄█░▌
// ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌    ▐░▌    ▐░░░░░░░░░░░▌
// ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀█░█▀▀ ▐░▌       ▐░▌   ▐░▌░▌    ▀▀▀▀█░█▀▀▀▀
// ▐░▌          ▐░▌     ▐░▌  ▐░▌       ▐░▌  ▐░▌ ▐░▌       ▐░▌
// ▐░▌          ▐░▌      ▐░▌ ▐░█▄▄▄▄▄▄▄█░▌ ▐░▌   ▐░▌      ▐░▌
// ▐░▌          ▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░▌     ▐░▌     ▐░▌
//  ▀            ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀       ▀       ▀
// Authors: @fallanic
// Reviewer: @flockonus

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// exposing the methods we care about
interface IMaruBandNFT {
  function publicSaleMint(uint256 quantity) external payable;

  function totalSupply() external returns (uint256);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

contract FiatProxy is Ownable, IERC721Receiver {
  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // bytes4(150b7a023d4804d13e8c85fb27262cb750cf6ba9f9dd3bb30d90f482ceeb4b1f)
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  address public maruNFTContract;
  uint256 public numberOfburntNFTs;
  uint256 public constant PUBLIC_SALE_PRICE = 0.1 ether;

  event MintAndTransferProxy(
    address indexed minter,
    address indexed receiver,
    uint256 quantity,
    uint256 fromIndex
  );

  event WithdrawETH(address indexed receiver, uint256 amount);

  constructor(address _maruNFTContract) {
    maruNFTContract = _maruNFTContract;
    numberOfburntNFTs = 0;
  }

  receive() external payable {}

  function setMaruNFTContract(address _maruNFTContract) public onlyOwner {
    maruNFTContract = _maruNFTContract;
  }

  function setNumberOfburntNFTs(uint256 _numberOfburntNFTs) public onlyOwner {
    numberOfburntNFTs = _numberOfburntNFTs;
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4) {
    // necessary when using safeMint from a contract, otherwise the transaction will revert
    // https://ethereum.stackexchange.com/questions/68461/onerc721recieved-implementation
    return _ERC721_RECEIVED;
  }

  function publicMintAndTransfer(address _to, uint256 _amount)
    external
    payable
  {
    // https://www.quicknode.com/guides/solidity/how-to-call-another-smart-contract-from-your-solidity-code
    // minting the tokens
    IMaruBandNFT(maruNFTContract).publicSaleMint{
      value: _amount * PUBLIC_SALE_PRICE
    }(_amount);
    // note: the Maru contract emits an event but doesn't return the tokenIds minted, so we have to use getTotalSupply() + numberOfburntNFTs guess the tokenIds
    uint256 _lastTokenId = IMaruBandNFT(maruNFTContract).totalSupply() +
      numberOfburntNFTs;

    // transferring the tokens which were just minted
    uint256 j;
    for (j = 0; j != _amount; j++) {
      IMaruBandNFT(maruNFTContract).transferFrom(
        address(this),
        _to,
        _lastTokenId - j
      );
    }

    // emit event success transfered tokens
    emit MintAndTransferProxy(
      msg.sender,
      _to,
      _amount,
      _lastTokenId - _amount + 1
    );
  }

  function withdrawETH() external onlyOwner {
    emit WithdrawETH(msg.sender, address(this).balance);
    payable(msg.sender).transfer(address(this).balance);
  }
}