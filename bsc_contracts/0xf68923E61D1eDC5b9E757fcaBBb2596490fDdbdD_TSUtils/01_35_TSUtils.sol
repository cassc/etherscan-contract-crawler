// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TSSaleFactory.sol";
import "./TSProject.sol";
import "./TSGovernor.sol";

contract TSUtils is Ownable {

    function getAmountToken(address tssaleAddress, uint256 smSaleId, address account)
        external
        view
        returns (uint256 amount)
    {
        TSSaleFactory tsSale = TSSaleFactory(payable(tssaleAddress));
        amount = tsSale.getHistoryBuy(smSaleId,account).amount;
    }

    function getTokenFee(address tssaleAddress, address token) external view returns(uint256 totalFee) {
        TSSaleFactory tsSale = TSSaleFactory(payable(tssaleAddress));
        totalFee = tsSale.getTotalFee(token);
    }
    function getClaimTokenInfo(address tsProjectAddress, address tssaleAddress, uint256 smSaleId, address account) external view returns (uint256 tokenRemaining, uint256 tokenClaimed, uint256 fee) {
        TSSaleFactory tsSale = TSSaleFactory(payable(tssaleAddress));
        TSProject tsProject = TSProject(tsProjectAddress);
        TSSaleFactory.SaleConfig memory saleConfig = tsSale.getSaleConfigByIndex(smSaleId);
        if(tsProject.userIsVc(account)) {
            if(saleConfig.status == TSSaleFactory.SaleStatus.SUCCESS) {
                tokenRemaining = tsSale.getAmountBuy(smSaleId, account).amount;
                tokenClaimed = tsSale.getHistoryBuy(smSaleId, account).amount - tokenRemaining;
            }else if(saleConfig.status == TSSaleFactory.SaleStatus.FAIL) {
                fee = (tsSale.getHistoryBuy(smSaleId,account).amountTokenBuy*tsSale.feeClaim())/tsSale.BPS();
                tokenRemaining = (tsSale.getAmountBuy(smSaleId,account).amountTokenBuy * (tsSale.BPS()-tsSale.feeClaim()))/tsSale.BPS();
                tokenClaimed =  tokenRemaining > 0 ? 0 : (tsSale.getHistoryBuy(smSaleId,account).amountTokenBuy * (tsSale.BPS()-tsSale.feeClaim()))/tsSale.BPS();
            }
        }else{
            if(saleConfig.status == TSSaleFactory.SaleStatus.FAIL) {
                tokenRemaining = tsSale.getAmountSell(smSaleId,account);
                tokenClaimed = saleConfig.totalSell-tokenRemaining;
            }else if(saleConfig.status==TSSaleFactory.SaleStatus.SUCCESS 
                && saleConfig.currentBuy < saleConfig.totalSell)
            {
                tokenRemaining = tsSale.getAmountSell(smSaleId,account)==0 ? 0 :saleConfig.totalSell - saleConfig.currentBuy;
                tokenClaimed = tsSale.getAmountSell(smSaleId,account)==0?saleConfig.totalSell - saleConfig.currentBuy:0;
            }
        }
    }
    function getBlockVoteInfo(address governor, address vesting, uint256 proposalId, address account) external view returns(uint256 blockRemainingRegister, uint256 blockRemainingVote, bool hasVoted,
        uint256 total, uint256 amountBuy, uint256 totalSell, bool registerVote) {
        TSGovernor tsGov = TSGovernor(payable(governor));
        blockRemainingRegister = tsGov.proposalSnapshot(proposalId) >= block.number ? tsGov.proposalSnapshot(proposalId) - block.number : 0;
        blockRemainingVote = tsGov.proposalDeadline(proposalId) >= block.number ? tsGov.proposalDeadline(proposalId) - block.number : 0;
        hasVoted = tsGov.hasVoted(proposalId, account);
        (uint256 amountClaim, uint256 amountClaimed,) = tsGov.getAmountTokenClaim(proposalId);
        total = amountClaim + amountClaimed;
        TSVesting tsVesting = TSVesting(vesting);
        amountBuy = tsVesting.getVotes(account);
        totalSell = tsVesting.total();
        registerVote = tsVesting.delegates(account)!=address(0)?true:false;
    }
    function getTokenVesting(address tssaleAddress, address vesting, uint256 smSaleId, address account) external view returns(uint256 tokenRemaining, uint256 tokenClaimed) {
        TSSaleFactory tsSale = TSSaleFactory(payable(tssaleAddress));
        TSVesting tsVesting = TSVesting(vesting);
        tokenRemaining = tsSale.getAmountBuy(smSaleId,account).amount;
        tokenClaimed = tsVesting.getBalanceVesting(account);
    }
    function getDisburmentInfo(address tssaleAddress, uint256 smSaleId) external view returns (uint256 totalRaise, uint256 totalDisburment) {
        TSSaleFactory tsSale = TSSaleFactory(payable(tssaleAddress));
        TSSaleFactory.SaleConfig memory slConfig = tsSale.getSaleConfigByIndex(smSaleId);
        totalRaise = slConfig.currentBuy * slConfig.price / tsSale.BPS();
        totalDisburment = TSGovernor(payable(slConfig.governance)).totalDisburment();
    }
    function getTokenLockInfo(address vesting, address account, uint64 timestamp) external view returns (uint256 total, uint256 claimable, uint256 amountReleased) {
        TSVesting tsVesting = TSVesting(vesting);
        total = tsVesting.getBalanceVesting(account);
        claimable = tsVesting.vestedAmount(account, timestamp) - tsVesting.released(account);
        amountReleased = tsVesting.released(account);
    }
}