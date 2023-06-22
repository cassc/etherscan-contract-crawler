// SPDX-License-Identifier: GPL-3.0

/**
 * @title NFTRefund
 * @dev NFTRefund & redeem ETH in the contract
 */
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTRefund is Ownable, ReentrancyGuard {
  IERC721 public nft;
  uint256 public price;

  mapping(uint256 => bool) public refundedNFTs;
  mapping(address => uint256) public balances;

  event Refund(address indexed user, uint256[] tokenIds);
  event Depoist(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event WithdrawNFt(address indexed user, uint256 tokenId);

  constructor(address _nftAddress, uint256 _price) {
    nft = IERC721(_nftAddress);
    price = _price;
  }

  // receive() 나 fallback()대신 deposit함수를 만든 이유:
  // 일반적인 transfer 이 아닌 deposit 함수로만 예치하게 함으로서
  // 타인이 쉽게 돈을 예치하지 못하게 함
  function deposit() public payable onlyOwner {
    balances[msg.sender] += msg.value;

    emit Depoist(msg.sender, msg.value);
  }

  function withdraw(uint256 amount) public onlyOwner {
    require(amount <= address(this).balance, "CRT-01 : Insufficient balance");
    balances[msg.sender] -= amount;
    payable(msg.sender).transfer(amount);

    emit Withdraw(msg.sender, amount);
  }

  function setNFTPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setNFContract(address _nftAddress) public onlyOwner {
    nft = IERC721(_nftAddress);
  }

  function refund(uint256[] calldata _tokenIds) external nonReentrant {
    require(
      _tokenIds.length * price <= address(this).balance,
      "CRT-01 : Insufficient balance"
    );

    uint256 totalAmount = 0;

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      uint256 tokenId = _tokenIds[i];
      require(
        nft.ownerOf(tokenId) == msg.sender,
        "CRT-02 : Sender does not own NFT"
      );
      require(!refundedNFTs[tokenId], "CRT-03 : NFT has already been refunded");
      require(
        nft.isApprovedForAll(msg.sender, address(this)),
        "CRT-04 : Contract is not approved to transfer NFT"
      );
      nft.transferFrom(msg.sender, address(this), tokenId);
      refundedNFTs[tokenId] = true;
      totalAmount += price;
    }

    require(totalAmount > 0, "CRT-05 : No valid NFTs provided");

    payable(msg.sender).transfer(totalAmount);

    emit Refund(msg.sender, _tokenIds);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function withdrawNFT(address _to, uint256 _tokenId) external onlyOwner {
    nft.transferFrom(address(this), _to, _tokenId);

    emit WithdrawNFt(msg.sender, _tokenId);
  }
}