// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import 'lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import 'lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol';

import './interfaces/IERC1155Token.sol';

contract Treasury is Initializable, OwnableUpgradeable {
  using SafeMath for uint256;

  address public tokenAddress;
  uint256 private assetPrice;
  address payable private accountsReceivable;

  event PurchasedNFT(address buyer, uint256 amount);
  event MintedNFT(address to, uint256[] tokenIds);

  function initialize() public initializer {
    __Ownable_init();

    accountsReceivable = payable(msg.sender);
    assetPrice = (5 ether);
  }

  function setAccountsReceivable(address payable newAccountsReceivable)
    public
    onlyOwner
  {
    require(
      newAccountsReceivable != address(0),
      'Treasury: newAccountsReceivable is the zero address'
    );
    accountsReceivable = newAccountsReceivable;
  }

  function getAccountsReceivable() public view returns (address) {
    return accountsReceivable;
  }

  function setTokenAddr(address _tokenAddress) public onlyOwner {
    require(
      _tokenAddress != address(0),
      'Treasury: tokenAddress is zero address'
    );
    tokenAddress = _tokenAddress;
  }

  function getTokenAddr() public view returns (address) {
    return tokenAddress;
  }

  function setAssetPrice(uint256 _assetPrice) public onlyOwner {
    assetPrice = _assetPrice;
  }

  function getAssetPrice() public view returns (uint256) {
    return assetPrice;
  }

  function purchaseNFT(uint256[] memory ids, uint256[] memory amounts)
    external
    payable
  {
    require(
      ids.length == amounts.length,
      'Treasury: Ids and Amounts are not same length'
    );

    for (uint256 i = 0; i < ids.length; ++i) {
      require(
        IERC1155Token(tokenAddress).balanceOf(owner(), ids[i]) == 1,
        'Treasury: Owner does not own specified token id(s)'
      );
      require(
        amounts[i] == 1,
        'Treasury: Amount value(s) are not equal to one'
      );
      require(
        ids[i] <= IERC1155Token(tokenAddress).totalSupply(),
        'Treasury: Total supply reached'
      );
    }

    require(
      address(msg.sender) != address(0),
      'Treasury: sender is zero address'
    );

    uint256 price = getAssetPrice() * ids.length;
    require(msg.value >= price, 'Treasury: Not enough funds to purchase');

    uint256 change = msg.value.sub(price);

    (bool sentOwner, ) = accountsReceivable.call{
      value: (msg.value.sub(change))
    }('');
    require(sentOwner, 'To owner: Failed to send BNB');

    (bool sentMsgSender, ) = msg.sender.call{value: change}('');
    require(sentMsgSender, 'To msg.sender: Failed to send BNB');

    emit PurchasedNFT(msg.sender, msg.value);
    IERC1155Token(tokenAddress).safeBatchTransferFrom(
      owner(),
      msg.sender,
      ids,
      amounts,
      ''
    );
    emit MintedNFT(msg.sender, ids);
  }

  // child contract methods
  function transferTokenContractOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), 'Treasury: new owner is the zero address');
    IERC1155Token(tokenAddress).transferOwnership(newOwner);
  }

  function setURITokenContract(string memory newuri) public onlyOwner {
    IERC1155Token(tokenAddress).setURI(newuri);
  }

  function pauseTokenContract() public onlyOwner {
    IERC1155Token(tokenAddress).pause();
  }

  function unpauseTokenContract() public onlyOwner {
    IERC1155Token(tokenAddress).unpause();
  }

  function mintBatchTokenContract(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public onlyOwner {
    IERC1155Token(tokenAddress).mintBatch(to, ids, amounts, data);
  }

  function safeBatchTransferFromTokenContract(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public onlyOwner {
    IERC1155Token(tokenAddress).safeBatchTransferFrom(
      from,
      to,
      ids,
      amounts,
      data
    );
  }
}