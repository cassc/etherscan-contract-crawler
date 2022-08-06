// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IInterceptor, IERC721, OrderTypes} from "../interfaces/IInterceptor.sol";
import {ILendPool, ILendPoolAddressesProvider} from "./interfaces/ILendPoolAddressesProvider.sol";
import {IBNFT} from "./interfaces/IBNFT.sol";

contract RedeemNFT is IInterceptor {
    using SafeERC20 for IERC20;
    uint256 internal constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
    uint256 internal constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

    struct LocalVars {
        uint256 loanId;
        uint256 bidFine;
        uint256 totalDebt;
        address tokenRepaid;
        ILendPool lendPool;
    }

    function beforeCollectionTransfer(
        address token,
        address from,
        address,
        uint256 tokenId,
        uint256,
        bytes memory extra
    ) external override returns (bool) {
        // do nothing if own token
        if (IERC721(token).ownerOf(tokenId) == from) {
            return true;
        }
        LocalVars memory vars;
        // else redeem from bend lend pool
        vars.lendPool = ILendPool(ILendPoolAddressesProvider(abi.decode(extra, (address))).getLendPool());
        // check bnft and nft ownership
        {
            ILendPool.NftData memory nftData = vars.lendPool.getNftData(token);
            require(IERC721(token).ownerOf(tokenId) == nftData.bNftAddress, "Interceptor: no BNFT");
            require(IBNFT(nftData.bNftAddress).ownerOf(tokenId) == from, "Interceptor: not BNFT owner");
        }
        // check token repaid
        (vars.loanId, , , , vars.bidFine) = vars.lendPool.getNftAuctionData(token, tokenId);
        (, vars.tokenRepaid, , vars.totalDebt, , ) = vars.lendPool.getNftDebtData(token, tokenId);

        require(
            vars.totalDebt + vars.bidFine <= IERC20(vars.tokenRepaid).balanceOf(address(this)),
            "Interceptor: insufficent to repay debt"
        );

        // approve lend pool
        IERC20(vars.tokenRepaid).safeApprove(address(vars.lendPool), vars.totalDebt + vars.bidFine);
        // repay debt, will failed if debt greater than sell price
        if (vars.bidFine > 0) {
            // maxinmum debt repay amount 90%
            uint256 redeemAmount = (vars.totalDebt * 9000 + HALF_PERCENT) / PERCENTAGE_FACTOR;
            vars.lendPool.redeem(token, tokenId, redeemAmount, vars.bidFine);
            (, , , vars.totalDebt, , ) = vars.lendPool.getNftDebtData(token, tokenId);
        }
        vars.lendPool.repay(token, tokenId, vars.totalDebt);
        // reset approve
        IERC20(vars.tokenRepaid).safeApprove(address(vars.lendPool), 0);

        return IERC721(token).ownerOf(tokenId) == from;
    }
}