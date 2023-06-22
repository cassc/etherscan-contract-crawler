// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import {IAaveLendPoolAddressesProvider} from "./interfaces/IAaveLendPoolAddressesProvider.sol";
import {IAaveLendPool} from "./interfaces/IAaveLendPool.sol";
import {IAaveFlashLoanReceiver} from "./interfaces/IAaveFlashLoanReceiver.sol";
import {ILendPoolAddressesProvider} from "./interfaces/ILendPoolAddressesProvider.sol";
import {ILendPool} from "./interfaces/ILendPool.sol";
import {ILendPoolLoan} from "./interfaces/ILendPoolLoan.sol";

import {IStakedNft} from "../interfaces/IStakedNft.sol";
import {INftPool} from "../interfaces/INftPool.sol";

contract LendingMigrator is
    IAaveFlashLoanReceiver,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    event NftMigrated(address indexed borrower, address indexed nftAsset, uint256 nftTokenId, uint256 debtAmount);

    uint256 public constant PERCENTAGE_FACTOR = 1e4;
    uint256 public constant BORROW_SLIPPAGE = 10; // 0.1%

    IAaveLendPoolAddressesProvider public aaveAddressesProvider;
    IAaveLendPool public aaveLendPool;
    ILendPoolAddressesProvider public bendAddressesProvider;
    ILendPool public bendLendPool;
    ILendPoolLoan public bendLendLoan;

    INftPool public nftPool;
    IStakedNft public stBayc;
    IStakedNft public stMayc;
    IStakedNft public stBakc;

    IERC721Upgradeable public bayc;
    IERC721Upgradeable public mayc;
    IERC721Upgradeable public bakc;

    function initialize(
        address aaveAddressesProvider_,
        address bendAddressesProvider_,
        address nftPool_,
        address stBayc_,
        address stMayc_,
        address stBakc_
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        nftPool = INftPool(nftPool_);
        stBayc = IStakedNft(stBayc_);
        stMayc = IStakedNft(stMayc_);
        stBakc = IStakedNft(stBakc_);

        bayc = IERC721Upgradeable(stBayc.underlyingAsset());
        mayc = IERC721Upgradeable(stMayc.underlyingAsset());
        bakc = IERC721Upgradeable(stBakc.underlyingAsset());

        aaveAddressesProvider = IAaveLendPoolAddressesProvider(aaveAddressesProvider_);
        aaveLendPool = IAaveLendPool(aaveAddressesProvider.getLendingPool());

        bendAddressesProvider = ILendPoolAddressesProvider(bendAddressesProvider_);
        bendLendPool = ILendPool(bendAddressesProvider.getLendPool());
        bendLendLoan = ILendPoolLoan(bendAddressesProvider.getLendPoolLoan());

        IERC721Upgradeable(bayc).setApprovalForAll(address(nftPool), true);
        IERC721Upgradeable(mayc).setApprovalForAll(address(nftPool), true);
        IERC721Upgradeable(bakc).setApprovalForAll(address(nftPool), true);

        IERC721Upgradeable(address(stBayc)).setApprovalForAll(address(bendLendPool), true);
        IERC721Upgradeable(address(stMayc)).setApprovalForAll(address(bendLendPool), true);
        IERC721Upgradeable(address(stBakc)).setApprovalForAll(address(bendLendPool), true);
    }

    struct MigrateLocaVars {
        uint256 aaveFlashLoanFeeRatio;
        uint256 aaveFlashLoanPremium;
        uint256 aaveFlashLoanAllSumPremium;
        uint256 aaveFlashLoanTotalPremium;
        uint256 loanId;
        address borrower;
        address debtReserve;
        uint256 oldDebtAmount;
        uint256 bidFine;
        address paramsBorrower;
        uint256[] paramsNewDebtAmounts;
        address[] aaveAssets;
        uint256[] aaveAmounts;
        uint256[] aaveModes;
        bytes aaveParms;
    }

    function migrate(address[] calldata nftAssets, uint256[] calldata nftTokenIds) public whenNotPaused nonReentrant {
        MigrateLocaVars memory vars;

        require(nftTokenIds.length > 0, "Migrator: empty token ids");
        require(nftAssets.length == nftTokenIds.length, "Migrator: inconsistent assets and token ids");

        vars.aaveFlashLoanFeeRatio = aaveLendPool.FLASHLOAN_PREMIUM_TOTAL();

        vars.aaveAssets = new address[](1);
        vars.aaveAmounts = new uint256[](1);
        vars.aaveModes = new uint256[](1);

        vars.paramsNewDebtAmounts = new uint256[](nftTokenIds.length);

        for (uint256 i = 0; i < nftTokenIds.length; i++) {
            (, , , , vars.bidFine) = bendLendPool.getNftAuctionData(nftAssets[i], nftTokenIds[i]);
            (vars.loanId, vars.debtReserve, , vars.oldDebtAmount, , ) = bendLendPool.getNftDebtData(
                nftAssets[i],
                nftTokenIds[i]
            );
            vars.borrower = bendLendLoan.borrowerOf(vars.loanId);
            if (i == 0) {
                // check borrower must be caller
                require(vars.borrower == msg.sender, "Migrator: caller not borrower");
                vars.aaveAssets[0] = vars.debtReserve;
                vars.paramsBorrower = vars.borrower;
            } else {
                // check borrower and asset must be same
                require(vars.aaveAssets[0] == vars.debtReserve, "LendingMigrator: debt reserve not same");
                require(vars.paramsBorrower == vars.borrower, "Migrator: borrower not same");
            }

            // new debt should cover old debt + bid fine + flash loan premium
            vars.aaveFlashLoanPremium =
                ((vars.oldDebtAmount + vars.bidFine) * vars.aaveFlashLoanFeeRatio) /
                PERCENTAGE_FACTOR;
            vars.aaveFlashLoanAllSumPremium += vars.aaveFlashLoanPremium;
            vars.paramsNewDebtAmounts[i] = (vars.oldDebtAmount + vars.bidFine) + vars.aaveFlashLoanPremium;
            vars.aaveAmounts[0] += (vars.oldDebtAmount + vars.bidFine);
        }
        // because of the math rounding, we need to add delta (1) wei to the first debt amount
        vars.aaveFlashLoanTotalPremium = (vars.aaveAmounts[0] * vars.aaveFlashLoanFeeRatio) / PERCENTAGE_FACTOR;
        if (vars.aaveFlashLoanTotalPremium > vars.aaveFlashLoanAllSumPremium) {
            vars.paramsNewDebtAmounts[0] += (vars.aaveFlashLoanTotalPremium - vars.aaveFlashLoanAllSumPremium);
        }

        vars.aaveParms = abi.encode(vars.paramsBorrower, nftAssets, nftTokenIds, vars.paramsNewDebtAmounts);

        aaveLendPool.flashLoan(
            address(this),
            vars.aaveAssets,
            vars.aaveAmounts,
            vars.aaveModes,
            address(0),
            vars.aaveParms,
            0
        );
    }

    struct ExecuteOperationLocaVars {
        // fields for params
        address borrower;
        address[] nftAssets;
        uint256[] nftTokenIds;
        uint256[] newDebtAmounts;
        // fields for aave
        address flashLoanAsset;
        // fields for temp data
        uint256 repayToAave;
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        ExecuteOperationLocaVars memory execVars;

        // only aave and this contract can call this function
        require(msg.sender == address(aaveLendPool), "Migrator: caller must be aave lending pool");
        require(initiator == address(this), "Migrator: initiator must be this contract");

        // on need to check following params, because this function only allowed to calling by ourself

        execVars.flashLoanAsset = assets[0];
        (execVars.borrower, execVars.nftAssets, execVars.nftTokenIds, execVars.newDebtAmounts) = abi.decode(
            params,
            (address, address[], uint256[], uint256[])
        );

        IERC20Upgradeable(assets[0]).approve(address(bendLendPool), type(uint256).max);

        for (uint256 i = 0; i < execVars.nftTokenIds.length; i++) {
            RepayAndBorrowLocaVars memory vars;
            vars.nftAsset = execVars.nftAssets[i];
            vars.nftTokenId = execVars.nftTokenIds[i];
            vars.newDebtAmount = execVars.newDebtAmounts[i];

            _repayAndBorrowPerNft(execVars, vars);
        }

        IERC20Upgradeable(assets[0]).approve(address(bendLendPool), 0);

        execVars.repayToAave = amounts[0] + premiums[0];
        IERC20Upgradeable(assets[0]).approve(msg.sender, execVars.repayToAave);

        return true;
    }

    struct RepayAndBorrowLocaVars {
        address nftAsset;
        uint256 nftTokenId;
        uint256 newDebtAmount;
        uint256 loanId;
        address debtReserve;
        uint256 debtTotalAmount;
        uint256 debtRemainAmount;
        uint256 redeemAmount;
        uint256 bidFine;
        uint256 debtTotalAmountWithBidFine;
        uint256 balanceBeforeRepay;
        uint256[] nftTokenIds;
        uint256 balanceBeforeBorrow;
        uint256 balanceAfterBorrow;
        uint256 loanIdForStNft;
        address borrowerForStNft;
    }

    function _repayAndBorrowPerNft(
        ExecuteOperationLocaVars memory execVars,
        RepayAndBorrowLocaVars memory vars
    ) internal {
        (vars.loanId, , , , vars.bidFine) = bendLendPool.getNftAuctionData(vars.nftAsset, vars.nftTokenId);
        (, vars.debtReserve, , vars.debtTotalAmount, , ) = bendLendPool.getNftDebtData(vars.nftAsset, vars.nftTokenId);
        vars.debtTotalAmountWithBidFine = vars.debtTotalAmount + vars.bidFine;

        vars.balanceBeforeRepay = IERC20Upgradeable(vars.debtReserve).balanceOf(address(this));

        require(vars.debtReserve == execVars.flashLoanAsset, "Migrator: invalid flash loan asset");
        require(vars.debtTotalAmountWithBidFine <= vars.balanceBeforeRepay, "Migrator: insufficent to repay old debt");

        // redeem first if nft is in auction
        if (vars.bidFine > 0) {
            vars.redeemAmount = (vars.debtTotalAmount * 2) / 3;
            bendLendPool.redeem(vars.nftAsset, vars.nftTokenId, vars.redeemAmount, vars.bidFine);

            (, , , vars.debtRemainAmount, , ) = bendLendPool.getNftDebtData(vars.nftAsset, vars.nftTokenId);
        } else {
            vars.debtRemainAmount = vars.debtTotalAmount;
        }

        // repay all the old debt
        bendLendPool.repay(vars.nftAsset, vars.nftTokenId, vars.debtRemainAmount);

        // stake original nft to the staking pool
        IERC721Upgradeable(vars.nftAsset).safeTransferFrom(execVars.borrower, address(this), vars.nftTokenId);
        vars.nftTokenIds = new uint256[](1);
        vars.nftTokenIds[0] = vars.nftTokenId;
        address[] memory nfts = new address[](1);
        nfts[0] = vars.nftAsset;
        uint256[][] memory tokenIds = new uint256[][](1);
        tokenIds[0] = vars.nftTokenIds;
        nftPool.deposit(nfts, tokenIds);

        // borrow new debt with the staked nft
        vars.balanceBeforeBorrow = IERC20Upgradeable(vars.debtReserve).balanceOf(address(this));

        IStakedNft stNftAsset = getStakedNFTAsset(vars.nftAsset);

        bendLendPool.borrow(
            vars.debtReserve,
            vars.newDebtAmount,
            address(stNftAsset),
            vars.nftTokenId,
            execVars.borrower,
            0
        );

        vars.balanceAfterBorrow = IERC20Upgradeable(vars.debtReserve).balanceOf(address(this));
        require(
            vars.balanceAfterBorrow == (vars.balanceBeforeBorrow + vars.newDebtAmount),
            "Migrator: balance wrong after borrow"
        );

        vars.loanIdForStNft = bendLendLoan.getCollateralLoanId(address(stNftAsset), vars.nftTokenId);
        vars.borrowerForStNft = bendLendLoan.borrowerOf(vars.loanIdForStNft);
        require(vars.borrowerForStNft == execVars.borrower, "Migrator: stnft borrower not same");

        emit NftMigrated(execVars.borrower, vars.nftAsset, vars.nftTokenId, vars.debtTotalAmount);
    }

    function setPause(bool flag) public onlyOwner {
        if (flag) {
            _pause();
        } else {
            _unpause();
        }
    }

    function getStakedNFTAsset(address nftAsset) internal view returns (IStakedNft) {
        if (nftAsset == address(bayc)) {
            return stBayc;
        } else if (nftAsset == address(mayc)) {
            return stMayc;
        } else if (nftAsset == address(bakc)) {
            return stBakc;
        } else {
            revert("Migrator: invalid nft asset");
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}