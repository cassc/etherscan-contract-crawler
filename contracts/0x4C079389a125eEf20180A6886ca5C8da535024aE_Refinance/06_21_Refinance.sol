//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import './token/Base64.sol';
import './token/Proxy.sol';
import './token/ERC721Enumerable.sol';
import "./interfaces/dydx/DydxFlashloanBase.sol";
import "./interfaces/dydx/ICallee.sol";
import "./interfaces/nftfi/INftfiLoan.sol";
import "./interfaces/nftfi/LoanData.sol";
import "./interfaces/IWETH.sol";
import './utils/TokenLogic.sol';

contract Refinance is ERC721Enumerable, Vault, DydxFlashloanBase {
  using Base64 for *;
  using Strings for uint256;

  address constant NFTFiLoan = 0xf896527c49b44aAb3Cf22aE356Fa3AF8E331F280;
  address constant SOLO = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
  address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  struct RefinanceData {
    uint256 tokenId;
    uint32 loanId;
    address[4] tokens; // [0] - borrowCToken, [1] - borrowUnderlying(0x00 is eth), [2] - supplyCToken, [3] - supplyUnderlying
    uint256[] supplyTokenIds;
  }

  bool public initialized;

  mapping(uint256 => TokenLogic) public proxies;

  address public tokenLogic;
  RefinanceData refinanceData;

  function initialize(address _tokenLogic) external onlyOwner {
    require(!initialized);
    initialized = true;

    name = 'Drops Refinance';
    symbol = 'DROPSRFN';

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
              string(abi.encodePacked('Drops Refinance', ' #', tokenId.toString())),
              '","description":"',
              'This NFT represents refinancing position at Drops protocol',
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

  function refinance(
    uint256 tokenId,
    uint32 loanId,
    address[4] calldata tokens,
    uint256[] calldata supplyTokenIds
  ) external {
    require(refinanceData.tokenId == 0, 'Invalid entrance');
    require(ownerOf[tokenId] == msg.sender, 'Invalid access');
    require(refinanceData.loanId == 0, 'Invalid loanId');

    if (tokenId == 0) {
      tokenId = mint();
    } else {
      require(ownerOf[tokenId] == msg.sender, 'Invalid access');
    }

    refinanceData.tokenId = tokenId;
    refinanceData.loanId = loanId;
    refinanceData.tokens = tokens;
    refinanceData.supplyTokenIds = supplyTokenIds;

    ISoloMargin solo = ISoloMargin(SOLO);

    INftfiLoan nftfiLoan = INftfiLoan(NFTFiLoan);
    uint payOffAmount = nftfiLoan.getPayoffAmount(loanId);

    address borrowToken;
    if (refinanceData.tokens[1] == address(0)) {
      borrowToken = WETH;
    } else {
      borrowToken = refinanceData.tokens[1];
    }

    // Get marketId from token address
    /*
    0	WETH
    1	SAI
    2	USDC
    3	DAI
    */
    uint marketId = _getMarketIdFromTokenAddress(SOLO, borrowToken);

    // Calculate repay amount (_amount + (2 wei))
    uint repayAmount = _getRepaymentAmountInternal(payOffAmount);

    /*
    1. Withdraw
    2. Call callFunction()
    3. Deposit back
    */

    Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

    operations[0] = _getWithdrawAction(marketId, payOffAmount);
    operations[1] = _getCallAction(abi.encodePacked(bytes1(0x00)));
    operations[2] = _getDepositAction(marketId, repayAmount);

    Account.Info[] memory accountInfos = new Account.Info[](1);
    accountInfos[0] = _getAccountInfo();
    solo.operate(accountInfos, operations);
  }

  function callFunction(
      address sender,
      Account.Info memory account,
      bytes memory data
  ) public {
    require(msg.sender == SOLO, "!dydx solo");
    require(sender == address(this), "!this contract");

    INftfiLoan nftfiLoan = INftfiLoan(NFTFiLoan);
    uint payOffAmount = nftfiLoan.getPayoffAmount(refinanceData.loanId);

    LoanData.LoanTerms memory term = nftfiLoan.loanIdToLoan(refinanceData.loanId);
    require(address(term.loanERC20Denomination) != address(0), "invalid loan");

    IERC20(term.loanERC20Denomination).approve(NFTFiLoan, payOffAmount);

    nftfiLoan.payBackLoan(refinanceData.loanId);
    require(IERC721(term.nftCollateralContract).ownerOf(term.nftCollateralId) == term.borrower, "invalid paybackloan");

    IERC721(term.nftCollateralContract).safeTransferFrom(
        term.borrower,
        address(this),
        term.nftCollateralId
    );

    ICERC721 supplyCToken = ICERC721(refinanceData.tokens[2]);
    IToken supplyUnderlying = IToken(refinanceData.tokens[3]);

    // Check ApprovalForAll
    if (!supplyUnderlying.isApprovedForAll(address(this), refinanceData.tokens[2])) {
      supplyUnderlying.setApprovalForAll(refinanceData.tokens[2], true);
    }

    // Supply Tokens
    supplyCToken.mints(refinanceData.supplyTokenIds);

    // Transfer cTokens
    TokenLogic proxy = proxies[refinanceData.tokenId];
    proxy.enterMarkets(supplyCToken);
    for (uint256 i = 0; i < refinanceData.supplyTokenIds.length; i++) {
      supplyCToken.transfer(address(proxy), 0);
    }

    // Borrow ETH, calculate repay amount (_amount + (2 wei))
    uint repayAmount = _getRepaymentAmountInternal(payOffAmount);

    proxy.borrowETH(refinanceData.tokens[0], repayAmount);

    // no need send to dydx here, it will be repaid automatically
    // // Repay ETH
    // payable(msg.sender).transfer(repayAmount);
    IWETH(term.loanERC20Denomination).deposit{value: repayAmount}();
    IERC20(term.loanERC20Denomination).approve(SOLO, repayAmount);

    delete refinanceData.tokenId;
    delete refinanceData.loanId;
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