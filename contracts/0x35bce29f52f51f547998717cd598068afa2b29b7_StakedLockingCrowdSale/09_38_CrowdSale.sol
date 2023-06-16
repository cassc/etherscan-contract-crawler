// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";
import { IPermissioner } from "../Permissioner.sol";
import { Molecules } from "../Molecules.sol";

enum SaleState {
    UNKNOWN,
    RUNNING,
    SETTLED,
    FAILED
}

struct Sale {
    IERC20Metadata auctionToken;
    IERC20Metadata biddingToken;
    address beneficiary;
    //how many bidding tokens to collect
    uint256 fundingGoal;
    //how many auction tokens to sell
    uint256 salesAmount;
    //a timestamp
    uint64 closingTime;
    //can be address(0) if there are no rules to enforce on token actions
    IPermissioner permissioner;
}

struct SaleInfo {
    SaleState state;
    uint256 total;
    uint256 surplus;
    bool claimed;
}

error BadDecimals();
error BadSalesAmount();
error BadSaleDuration();
error SaleAlreadyActive();
error SaleClosedForBids();

error BidTooLow();
error SaleNotFund(uint256);
error SaleNotConcluded();
error BadSaleState(SaleState expected, SaleState actual);
error AlreadyClaimed();

/**
 * @title CrowdSale
 * @author molecule.to
 * @notice a fixed price sales base contract
 */
contract CrowdSale is ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;
    using FixedPointMathLib for uint256;

    mapping(uint256 => Sale) internal _sales;
    mapping(uint256 => SaleInfo) internal _saleInfo;

    mapping(uint256 => mapping(address => uint256)) internal _contributions;

    event Started(uint256 indexed saleId, address indexed issuer, Sale sale);
    event Settled(uint256 indexed saleId, uint256 totalBids, uint256 surplus);
    /// @notice emitted when participants of the sale claim their tokens
    event Claimed(uint256 indexed saleId, address indexed claimer, uint256 claimed, uint256 refunded);
    event Bid(uint256 indexed saleId, address indexed bidder, uint256 amount);
    event Failed(uint256 indexed saleId);

    /// @notice emitted when sales owner / beneficiary claims `fundingGoal` `biddingTokens` after a successful sale
    event ClaimedFundingGoal(uint256 indexed saleId);

    /// @notice emitted when sales owner / beneficiary claims `salesAmount` `auctionTokens` after a non successful sale
    event ClaimedAuctionTokens(uint256 indexed saleId);

    /**
     * @notice bidding tokens can have arbitrary decimals, auctionTokens must be 18 decimals
     *         if no beneficiary is provided, the beneficiary will be set to msg.sender
     *         caller must approve `sale.fundingGoal` auctionTokens before calling this.
     * @param sale the sale's base configuration.
     * @return saleId
     */
    function startSale(Sale calldata sale) public virtual returns (uint256 saleId) {
        //[M-02]
        if (sale.closingTime < block.timestamp || sale.closingTime > block.timestamp + 180 days) {
            revert BadSaleDuration();
        }

        if (sale.auctionToken.decimals() != 18) {
            revert BadDecimals();
        }

        //close to 0 cases lead to precision issues.Using 0.01 bidding tokens as minimium funding goal
        if (sale.fundingGoal < 10 ** (sale.biddingToken.decimals() - 2) || sale.salesAmount < 0.5 ether) {
            revert BadSalesAmount();
        }

        saleId = uint256(keccak256(abi.encode(sale)));
        if (address(_sales[saleId].auctionToken) != address(0)) {
            revert SaleAlreadyActive();
        }

        _sales[saleId] = sale;
        _saleInfo[saleId] = SaleInfo(SaleState.RUNNING, 0, 0, false);

        sale.auctionToken.safeTransferFrom(msg.sender, address(this), sale.salesAmount);
        _afterSaleStarted(saleId);
    }

    /**
     * @return SaleInfo information about the sale
     */
    function getSaleInfo(uint256 saleId) external view returns (SaleInfo memory) {
        return _saleInfo[saleId];
    }

    /**
     * @param saleId sale id
     * @param contributor address
     * @return uint256 the amount of bidding tokens `contributor` has bid into the sale
     */
    function contribution(uint256 saleId, address contributor) external view returns (uint256) {
        return _contributions[saleId][contributor];
    }

    /**
     * @dev even though `auctionToken` is casted to `Molecules` this should still work with IPNFT agnostic tokens
     * @param saleId the sale id
     * @param biddingTokenAmount the amount of bidding tokens
     * @param permission bytes are handed over to a configured permissioner contract. Set to 0x0 / "" / [] if not needed
     */
    function placeBid(uint256 saleId, uint256 biddingTokenAmount, bytes calldata permission) public {
        if (biddingTokenAmount == 0) {
            revert BidTooLow();
        }

        Sale storage sale = _sales[saleId];
        if (sale.fundingGoal == 0) {
            revert SaleNotFund(saleId);
        }

        // @notice: while the general rule is that no bids aren't accepted past the sale's closing time
        //          it's still possible for derived contracts to fail a sale early by changing the sale's state
        if (block.timestamp > sale.closingTime || _saleInfo[saleId].state != SaleState.RUNNING) {
            revert SaleClosedForBids();
        }

        if (address(sale.permissioner) != address(0)) {
            sale.permissioner.accept(Molecules(address(sale.auctionToken)), msg.sender, permission);
        }

        _bid(saleId, biddingTokenAmount);
    }

    /**
     * @notice anyone can call this for the beneficiary.
     *         beneficiary must claim their respective proceeds by calling `claimResults` afterwards
     * @param saleId the sale id
     */
    function settle(uint256 saleId) public virtual nonReentrant {
        Sale storage sale = _sales[saleId];
        SaleInfo storage saleInfo = _saleInfo[saleId];

        if (block.timestamp < sale.closingTime) {
            revert SaleNotConcluded();
        }

        if (saleInfo.state != SaleState.RUNNING) {
            revert BadSaleState(SaleState.RUNNING, saleInfo.state);
        }

        if (saleInfo.total < sale.fundingGoal) {
            saleInfo.state = SaleState.FAILED;
            emit Failed(saleId);
            return;
        }
        saleInfo.state = SaleState.SETTLED;
        saleInfo.surplus = saleInfo.total - sale.fundingGoal;

        emit Settled(saleId, saleInfo.total, saleInfo.surplus);
        _afterSaleSettled(saleId);
    }

    /**
     * @notice [L-02] lets the auctioneer pull the results of a succeeded / failed crowdsale
     *         only callable once after the sale was settled
     *         this is callable by anonye
     * @param saleId the sale id
     */
    function claimResults(uint256 saleId) external virtual {
        SaleInfo storage saleInfo = _saleInfo[saleId];
        if (saleInfo.claimed) {
            revert AlreadyClaimed();
        }
        saleInfo.claimed = true;

        Sale storage sale = _sales[saleId];
        if (saleInfo.state == SaleState.SETTLED) {
            //transfer funds to issuer / beneficiary
            emit ClaimedFundingGoal(saleId);
            sale.biddingToken.safeTransfer(sale.beneficiary, sale.fundingGoal);
        } else if (saleInfo.state == SaleState.FAILED) {
            //return auction tokens
            emit ClaimedAuctionTokens(saleId);
            sale.auctionToken.safeTransfer(sale.beneficiary, sale.salesAmount);
        } else {
            revert BadSaleState(SaleState.SETTLED, saleInfo.state);
        }
    }

    function _afterSaleSettled(uint256 saleId) internal virtual { }

    /**
     * @dev computes commitment ratio of bidder
     *
     * @param saleId sale id
     * @param bidder bidder
     * @return auctionTokens wei value of auction tokens to return
     * @return refunds wei value of bidding tokens to return
     */
    function getClaimableAmounts(uint256 saleId, address bidder) public view virtual returns (uint256 auctionTokens, uint256 refunds) {
        SaleInfo storage saleInfo = _saleInfo[saleId];
        uint256 biddingRatio = (saleInfo.total == 0) ? 0 : _contributions[saleId][bidder].divWadDown(saleInfo.total);
        auctionTokens = biddingRatio.mulWadDown(_sales[saleId].salesAmount);

        if (saleInfo.surplus != 0) {
            refunds = biddingRatio.mulWadDown(saleInfo.surplus);
        }
    }

    /**
     * @dev even though `auctionToken` is casted to `Molecules` this should still work with IPNFT agnostic tokens
     * @notice public method that refunds and lets user redeem their sales shares
     * @param saleId the sale id
     * @param permission. bytes are handed over to a configured permissioner contract
     */
    function claim(uint256 saleId, bytes memory permission) external nonReentrant returns (uint256 auctionTokens, uint256 refunds) {
        SaleState currentState = _saleInfo[saleId].state;
        if (currentState == SaleState.FAILED) {
            return claimFailed(saleId);
        }
        //[L-05]
        if (currentState != SaleState.SETTLED) {
            revert BadSaleState(SaleState.SETTLED, currentState);
        }

        Sale storage sales = _sales[saleId];
        //we're not querying the permissioner if the sale has failed.
        if (address(sales.permissioner) != address(0)) {
            sales.permissioner.accept(Molecules(address(sales.auctionToken)), msg.sender, permission);
        }
        (auctionTokens, refunds) = getClaimableAmounts(saleId, msg.sender);
        //a reentrancy won't have any effect after setting this to 0.
        _contributions[saleId][msg.sender] = 0;
        claim(saleId, auctionTokens, refunds);
    }

    /**
     * @dev will send `tokenAmount` auction tokens and `refunds` bidding tokens to msg.sender
     *      This trusts the caller to have checked the amount
     *
     * @param saleId sale id
     * @param tokenAmount amount of tokens to claim.
     * @param refunds biddingTokens to refund
     */
    function claim(uint256 saleId, uint256 tokenAmount, uint256 refunds) internal virtual {
        //the sender has claimed already
        if (tokenAmount == 0) {
            return;
        }
        emit Claimed(saleId, msg.sender, tokenAmount, refunds);

        if (refunds != 0) {
            _sales[saleId].biddingToken.safeTransfer(msg.sender, refunds);
        }
        _claimAuctionTokens(saleId, tokenAmount);
    }

    /**
     * @dev lets users claim back refunds when the sale has failed
     *
     * @param saleId sale id
     * @return auctionTokens the amount of auction tokens claimed (0)
     * @return refunds the amount of bidding tokens refunded
     */
    function claimFailed(uint256 saleId) internal virtual returns (uint256 auctionTokens, uint256 refunds) {
        uint256 _contribution = _contributions[saleId][msg.sender];
        _contributions[saleId][msg.sender] = 0;
        emit Claimed(saleId, msg.sender, 0, _contribution);
        _sales[saleId].biddingToken.safeTransfer(msg.sender, _contribution);
        return (0, _contribution);
    }

    /**
     * @dev internal bid method
     * increases bidder's contribution balance
     * increases sale's bid total
     *
     * @param saleId sale id
     * @param biddingTokenAmount the amount of tokens bid to the sale
     */
    function _bid(uint256 saleId, uint256 biddingTokenAmount) internal virtual {
        _saleInfo[saleId].total += biddingTokenAmount;
        _contributions[saleId][msg.sender] += biddingTokenAmount;
        _sales[saleId].biddingToken.safeTransferFrom(msg.sender, address(this), biddingTokenAmount);
        emit Bid(saleId, msg.sender, biddingTokenAmount);
    }

    /**
     * @dev overridden in LockingCrowdSale (will lock auction tokens in vested contract)
     */
    function _claimAuctionTokens(uint256 saleId, uint256 tokenAmount) internal virtual {
        _sales[saleId].auctionToken.safeTransfer(msg.sender, tokenAmount);
    }

    /**
     * @dev allows us to emit different events per derived contract
     */
    function _afterSaleStarted(uint256 saleId) internal virtual {
        emit Started(saleId, msg.sender, _sales[saleId]);
    }
}