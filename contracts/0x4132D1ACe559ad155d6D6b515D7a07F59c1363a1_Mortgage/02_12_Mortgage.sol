//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import './token/ERC721Enumerable.sol';
import './token/Base64.sol';
import './token/Proxy.sol';
import './utils/Vault.sol';
import './utils/TokenLogic.sol';
import './interfaces/IFlashLoan.sol';
import './interfaces/ICToken.sol';

contract Mortgage is ERC721Enumerable, Vault, IFlashLoanReceiver {
  using Base64 for *;
  using Strings for uint256;

  struct Data {
    uint256 tokenId;
    address[3] tokens; // [0] - borrowCToken, [1] - supplyCToken, [2] - supplyUnderlying
    uint256[] supplyTokenIds;
    uint256 ethValue;
  }

  bool public initialized;

  mapping(uint256 => TokenLogic) public proxies;

  IFlashLoanProvider public provider;
  address public tokenLogic;
  Data data;

  function initialize(IFlashLoanProvider _provider, address _tokenLogic) external onlyOwner {
    require(!initialized);
    initialized = true;

    name = 'Drops Mortgage';
    symbol = 'DROPSMTG';

    provider = _provider;
    tokenLogic = _tokenLogic;
  }

  function setTokenLogic(address _tokenLogic) external onlyOwner {
    tokenLogic = _tokenLogic;
  }

  function mint() public returns(uint256) {
    uint256 tokenId = totalSupply + 1;
    Proxy proxy = new Proxy();
    proxy.setImplementation(tokenLogic);
    proxies[tokenId] = TokenLogic(payable(proxy));
    _mint(msg.sender, tokenId);
    return tokenId;
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(ownerOf[tokenId] != address(0), 'tokenURI: Non-existent token');

    string memory attributes = string(
      abi.encodePacked('[{"trait_type":"Author","value":"Drops DAO"}]')
    );

    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            abi.encodePacked(
              '{"name":"',
              string(abi.encodePacked('Drops Mortgage', ' #', tokenId.toString())),
              '","description":"',
              'NFT Mortgage provided by Drops DAO',
              '","image":"',
              'https://ambassador.mypinata.cloud/ipfs/Qmf1z56YX8dPJKmC6VfQioxJrBFKPX3x9aMC2bbSqTcar5',
              '","attributes":',
              attributes,
              '}'
            )
          )
        )
      );
  }

  function mortgage(
    uint256 tokenId,
    address[3] calldata tokens,
    uint256[] calldata supplyTokenIds,
    address aggregator,
    uint256 value,
    bytes calldata trades
  ) external payable {
    require(data.tokenId == 0, 'Invalid entrance');
    if (tokenId == 0) {
      mint();
      tokenId = totalSupply;
    } else {
      require(ownerOf[tokenId] == msg.sender, 'Invalid access');
    }

    data.tokenId = tokenId;
    data.tokens = tokens;
    data.supplyTokenIds = supplyTokenIds;
    data.ethValue = msg.value;
    provider.flashLoan(aggregator, value - msg.value, trades);
  }

  function onFlashLoanReceived(
    address aggregator,
    uint256 value,
    uint256 fee,
    bytes calldata trades
  ) external override {
    (bool success, ) = aggregator.call{value: (value + data.ethValue)}(trades);
    require(success, 'Invalid trades');

    ICERC721 supplyCToken = ICERC721(data.tokens[1]);
    IToken supplyUnderlying = IToken(data.tokens[2]);

    // Check ApprovalForAll
    if (!supplyUnderlying.isApprovedForAll(address(this), data.tokens[1])) {
      supplyUnderlying.setApprovalForAll(data.tokens[1], true);
    }

    // Supply Tokens
    supplyCToken.mints(data.supplyTokenIds);

    // Transfer cTokens
    TokenLogic proxy = proxies[data.tokenId];
    proxy.enterMarkets(supplyCToken);
    for (uint256 i = 0; i < data.supplyTokenIds.length; i++) {
      supplyCToken.transfer(address(proxy), 0);
    }

    // Borrow ETH
    uint256 repayAmount = value + fee;
    proxy.borrowETH(data.tokens[0], repayAmount);

    // Repay ETH
    payable(msg.sender).transfer(repayAmount);

    // return remaining ETH (if any)
    assembly {
      if gt(selfbalance(), 0) {
        let callStatus := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
      }
    }

    delete data.tokenId;
  }

  function claimNFTs(
    uint256 tokenId,
    address cToken,
    uint256[] calldata redeemTokenIndexes
  ) external {
    require(ownerOf[tokenId] == msg.sender, 'Invalid access');

    TokenLogic proxy = proxies[tokenId];
    proxy.claimNFTs(cToken, redeemTokenIndexes, msg.sender);
  }

  function claimCTokens(
    uint256 tokenId,
    address cToken,
    uint256 amount
  ) external {
    require(ownerOf[tokenId] == msg.sender, 'Invalid access');

    TokenLogic proxy = proxies[tokenId];
    proxy.claimCTokens(cToken, amount, msg.sender);
  }
}