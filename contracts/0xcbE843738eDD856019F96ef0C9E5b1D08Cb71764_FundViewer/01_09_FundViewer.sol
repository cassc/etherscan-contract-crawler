// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFundAccount} from "../interfaces/fund/IFundAccount.sol";
import {TokenBalance, FundAccountData, LpDetailInfo, LPToken} from "../interfaces/external/IFundViewer.sol";
import {IFundManager} from "../interfaces/fund/IFundManager.sol";
import {IPriceOracle} from "../interfaces/fund/IPriceOracle.sol";
import {IPositionViewer} from "../interfaces/fund/IPositionViewer.sol";

contract FundViewer {
    IFundManager public fundManager;

    // Contract version
    uint256 public constant version = 1;

    constructor(address _fundManager) {
        fundManager = IFundManager(_fundManager);
    }

    function getFundAccountsData(address addr, bool extend) public view returns (FundAccountData[] memory) {
        address[] memory accounts = fundManager.getAccounts(addr);
        FundAccountData[] memory result = new FundAccountData[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            result[i] = getFundAccountData(accounts[i], extend);
        }
        return result;
    }

    function getFundAccountData(address account, bool extend) public view returns (FundAccountData memory data) {
        IFundAccount fundAccount = IFundAccount(account);
        data.since = fundAccount.since();
        data.name = fundAccount.name();
        data.gp = fundAccount.gp();
        data.managementFee = fundAccount.managementFee();
        data.carriedInterest = fundAccount.carriedInterest();
        data.underlyingToken = fundAccount.underlyingToken();
        data.initiator = fundAccount.initiator();
        data.initiatorAmount = fundAccount.initiatorAmount();
        data.recipient = fundAccount.recipient();
        data.recipientMinAmount = fundAccount.recipientMinAmount();
        data.allowedProtocols = fundAccount.allowedProtocols();
        data.allowedTokens = fundAccount.allowedTokens();
        data.totalUnit = fundAccount.totalUnit();
        data.totalManagementFeeAmount = fundAccount.totalManagementFeeAmount();
        data.totalCarryInterestAmount = fundAccount.totalCarryInterestAmount();
        data.ethBalance = fundAccount.ethBalance();
        data.totalUnit = fundAccount.totalUnit();
        data.closed = fundAccount.closed();

        data.addr = account;

        data.totalValue = fundManager.calcTotalValue(account);

        if (extend) {
            data.tokenBalances = getFundAccountTokenBalances(data);
            data.lpDetailInfos = getFundAccountLpDetailInfos(fundAccount);
            data.lpTokens = getFundAccountLpTokens(data);
        }
    }

    function getFundAccountTokenBalances(FundAccountData memory data)
        internal
        view
        returns (TokenBalance[] memory tokenBalances)
    {
        IPriceOracle priceOracle = IPriceOracle(fundManager.fundFilter().priceOracle());

        address[] memory allowedTokens = data.allowedTokens;
        tokenBalances = new TokenBalance[](allowedTokens.length + 1);

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            tokenBalances[i].token = allowedTokens[i];
            tokenBalances[i].balance = IERC20(allowedTokens[i]).balanceOf(data.addr);
            tokenBalances[i].value = priceOracle.convert(
                tokenBalances[i].token,
                data.underlyingToken,
                tokenBalances[i].balance
            );
        }
        tokenBalances[allowedTokens.length] = TokenBalance({
            token: address(0),
            balance: address(data.addr).balance,
            value: priceOracle.convert(fundManager.weth9(), data.underlyingToken, address(data.addr).balance)
        });
    }

    function getFundAccountLpDetailInfos(IFundAccount fundAccount)
        internal
        view
        returns (LpDetailInfo[] memory details)
    {
        address[] memory lps = fundAccount.lpList();
        details = new LpDetailInfo[](lps.length);

        for (uint256 i = 0; i < lps.length; i++) {
            details[i].lpAddr = lps[i];
            details[i].detail = fundAccount.lpDetailInfo(lps[i]);
        }
    }

    function getFundAccountLpTokens(FundAccountData memory data) internal view returns (LPToken[] memory lpTokens) {
        IPriceOracle priceOracle = IPriceOracle(fundManager.fundFilter().priceOracle());
        IPositionViewer positionViewer = IPositionViewer(fundManager.fundFilter().positionViewer());

        uint256[] memory tokenIds = fundManager.lpTokensOfAccount(data.addr);

        lpTokens = new LPToken[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            lpTokens[i].tokenId = tokenId;
            (
                lpTokens[i].token0,
                lpTokens[i].token1,
                lpTokens[i].fee,
                lpTokens[i].amount0,
                lpTokens[i].amount1,
                lpTokens[i].fee0,
                lpTokens[i].fee1
            ) = positionViewer.query(tokenId);

            lpTokens[i].amountValue0 = priceOracle.convert(
                lpTokens[i].token0,
                data.underlyingToken,
                lpTokens[i].amount0
            );
            lpTokens[i].amountValue1 = priceOracle.convert(
                lpTokens[i].token1,
                data.underlyingToken,
                lpTokens[i].amount1
            );
            lpTokens[i].feeValue0 = priceOracle.convert(lpTokens[i].token0, data.underlyingToken, lpTokens[i].fee0);
            lpTokens[i].feeValue1 = priceOracle.convert(lpTokens[i].token1, data.underlyingToken, lpTokens[i].fee1);
        }
    }
}