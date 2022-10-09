// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Community {
  struct WithdrawalRequest {
    uint256 amount;
    address toAddress;
  }

  address public owner;
  address public tokenAddress;
  mapping(address => bool) public members;
  mapping(address => uint256) public withdrawalRequests;

  event TransferReceived(address _from, uint256 _amount);
  event TransferSent(address _from, address _destAddr, uint256 _amount);

  constructor(address ownerAddress) {
    owner = ownerAddress;
  }

  function balance() public view returns (uint256)  {
    uint256 erc20Balance = IERC20(tokenAddress).balanceOf(address(this));

    return erc20Balance / (10 ** ERC20(tokenAddress).decimals());
  }

  function createCommunityCurrency(address tokenAddr) external {
    require(msg.sender == owner, 'Only owner can set currency for this community');

    tokenAddress = tokenAddr;
  }

  function depositTokens(uint256 amount) external  {
    require(msg.sender == owner, 'Only owner can deposit tokens');

    uint amountInDecimals = amount * (10 ** ERC20(tokenAddress).decimals());
    IERC20(tokenAddress).transferFrom(msg.sender, address(this), amountInDecimals);

    emit TransferSent(msg.sender, address(this), amountInDecimals);
  }

  function createWithdrawalRequest(uint256 amount) external {
    require(withdrawalRequests[msg.sender] == 0, 'Must not have active request');
    require(members[msg.sender], 'Must opt in for rewards first');

    withdrawalRequests[msg.sender] = amount;
  }

  function getWithdrawalRequest(address memberAddress) external view returns (uint256) {
    require(msg.sender == owner, 'Only owner can view requests');

    return withdrawalRequests[memberAddress];
  }

  function addMember() external {
    members[msg.sender] = true;
  }

  function removeMyAddress() external {
    require(members[msg.sender], 'Address not in list. Use addMember() to add it.');

    delete members[msg.sender];
    delete withdrawalRequests[msg.sender];
  }

  function removeMember(address memberAddress) external {
    require(msg.sender == owner, 'Community owner can remove members.');

    delete members[memberAddress];
    delete withdrawalRequests[msg.sender];
  }

  receive() external payable {
    payable(owner).transfer(address(this).balance);

    emit TransferReceived(msg.sender, msg.value);
  }

  function approveWithdrawalRequest(address memberAddress, uint256 amount) public {
    require(msg.sender == owner, 'Only owner can approve requests');

    uint256 requestAmount = withdrawalRequests[memberAddress];

    require(requestAmount == amount, 'Invalid request. Smart contract not in sync with Xpand.');
    require(requestAmount <= balance(), 'Insufficient balance, please top up and try again.');

    withdraw(requestAmount, payable(memberAddress));

    delete withdrawalRequests[memberAddress];
  }

  function bulkRequestApproval(WithdrawalRequest[] memory requests) external {
    require(msg.sender == owner, 'Only owner can approve requests');

    for (uint i = 0; i < requests.length; i++) {
      uint256 requestAmount = withdrawalRequests[requests[i].toAddress];

      require(requestAmount == requests[i].amount, 'Invalid request.. try again');
      require(requestAmount <= balance(), 'Insufficient balance, please top up and try again.');

      withdraw(requestAmount, payable(requests[i].toAddress));

      delete withdrawalRequests[requests[i].toAddress];
    }
  }

  function rejectWithdrawalRequest(address memberAddress) external {
    require(msg.sender == owner);

    delete withdrawalRequests[memberAddress];
  }

  function withdraw(uint256 amount, address payable destAddress) private {
    IERC20(tokenAddress).transfer(destAddress, amount * (10 ** ERC20(tokenAddress).decimals()));

    emit TransferSent(address(this), destAddress, amount);
  }

  function withdrawERC20() external {
    require(msg.sender == owner);

    uint256 erc20Balance = IERC20(tokenAddress).balanceOf(address(this));

    IERC20(tokenAddress).transfer(owner, erc20Balance);

    emit TransferSent(msg.sender, owner, erc20Balance);
  }

  function withdrawAnyERC20(address tokenAddr) external {
    require(msg.sender == owner);

    uint256 erc20Balance = IERC20(tokenAddr).balanceOf(address(this));

    IERC20(tokenAddr).transfer(owner, erc20Balance);

    emit TransferSent(msg.sender, owner, erc20Balance);
  }

  // nft stuff
  enum TokenType { ERC721, ERC1155 }

  struct Airdrop {
    address nft;
    uint id;
    TokenType tokenType;
  }

  struct NftItem {
    address nftAddress;
    uint tokenId;
    uint price;
    TokenType tokenType;
  }

  uint public nextAirdropId;
  uint public nextClaimId;
  mapping(uint => Airdrop) public airdrops;
  mapping(uint => NftItem) public nftItems;
  mapping(address => bool) public recipients;

  function addItemForSale(NftItem memory item, uint itemId) external {
    require(msg.sender == owner, 'Only owner can add NFTS for sale');
    require(item.price > 0, 'Price must be greater than 0');
    require(nftItems[itemId].nftAddress == address(0), 'Item already added for sale');

    if (item.tokenType == TokenType.ERC721) {
      IERC721(item.nftAddress).safeTransferFrom(msg.sender, address(this), item.tokenId);
    } else {
      IERC1155(item.nftAddress).safeTransferFrom(msg.sender, address(this), item.tokenId, 1, "");
    }

    nftItems[itemId] = item;
  }

  function buyNft(uint itemId, uint tokensAmount, TokenType tokenType) external {
    NftItem memory item = nftItems[itemId];

    require(item.price == tokensAmount, 'Price does not match amount sent.');
    require(item.nftAddress != address(0), 'NFT missing or already sold.');

    uint amountInDecimals = tokensAmount * (10 ** ERC20(tokenAddress).decimals());
    IERC20(tokenAddress).transferFrom(msg.sender, address(this), amountInDecimals);

    if (tokenType == TokenType.ERC721) {
      IERC721(item.nftAddress).safeTransferFrom(address(this), msg.sender, item.tokenId);
    } else {
      IERC1155(item.nftAddress).safeTransferFrom(address(this), msg.sender, item.tokenId, 1, "");
    }

    emit TransferSent(msg.sender, address(this), amountInDecimals);

    delete nftItems[itemId];
  }

  function addAirdrops(Airdrop[] memory _airdrops) external {
    require(msg.sender == owner, 'Only owner can add NFTS for airdrop');

    uint _nextAirdropId = nextAirdropId;

    for (uint i = 0; i < _airdrops.length; i++) {
      airdrops[_nextAirdropId] = _airdrops[i];

      if (airdrops[_nextAirdropId].tokenType == TokenType.ERC721) {
        IERC721(_airdrops[i].nft).safeTransferFrom(
          msg.sender,
          address(this),
          _airdrops[i].id
        );
      } else {
        IERC1155(_airdrops[i].nft).safeTransferFrom(
          msg.sender,
          address(this),
          _airdrops[i].id,
          1,
          ""
        );
      }

      _nextAirdropId++;
    }

    nextAirdropId = _nextAirdropId;
  }

  function addRecipients(address[] memory _recipients) external {
    require(msg.sender == owner, 'Only owner can add airdrop recipients');

    for (uint i = 0; i < _recipients.length; i++) {
      recipients[_recipients[i]] = true;
    }
  }

  function removeRecipients(address[] memory _recipients) external {
    require(msg.sender == owner, 'Only owner can remove airdrop recipients');

    for (uint i = 0; i < _recipients.length; i++) {
      recipients[_recipients[i]] = false;
    }
  }

  function claim() external {
    require(recipients[msg.sender] == true, 'Recipient must be added first');
    require(nextAirdropId > nextClaimId, 'There are more recipients than NFTS. Admin must transfer more NFTS.');

    recipients[msg.sender] = false;

    Airdrop storage airdrop = airdrops[nextClaimId];

    if (airdrop.tokenType == TokenType.ERC721) {
      IERC721(airdrop.nft).safeTransferFrom(address(this), msg.sender, airdrop.id);
    } else {
      IERC1155(airdrop.nft).safeTransferFrom(address(this), msg.sender, airdrop.id, 1, "");
    }
    
    nextClaimId++;
  }

  function withdrawNFTS(Airdrop[] memory nfts) external {
    require(msg.sender == owner, 'Only owner can withdraw NFTS');
      
    for (uint i = 0; i < nfts.length; i++) {
      if (nfts[i].tokenType == TokenType.ERC721) {
        IERC721(nfts[i].nft).safeTransferFrom(address(this), msg.sender, nfts[i].id);
      } else {
        IERC1155(nfts[i].nft).safeTransferFrom(address(this), msg.sender, nfts[i].id, 1, "");
      }
    }
  }

  function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4) {
    return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
  }

  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function migrateContract(
    address _tokenAddress,
    address[] memory _recipients, 
    address[] memory _members,
    WithdrawalRequest[] memory _withdrawalRequests
  ) external {
    require(msg.sender == owner, 'Only owner can migrate existing contract');

    tokenAddress = _tokenAddress;

    for (uint i = 0; i < _recipients.length; i++) {
      recipients[_recipients[i]] = true;
    }

    for (uint i = 0; i < _members.length; i++) {
      members[_members[i]] = true;
    }

    for (uint i = 0; i < _withdrawalRequests.length; i++) {
      withdrawalRequests[_withdrawalRequests[i].toAddress] = _withdrawalRequests[i].amount;
    }
  }
}