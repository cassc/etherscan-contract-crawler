// SPDX-License-Identifier: MIT
// Copyright (c) 2022-2023 Fellowship

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Delegation.sol";
import "./EarlyAccessSale.sol";
import "./MintableById.sol";
import "./Shuffler.sol";

struct AuctionStage {
    /// @notice Amount that the price drops (in wei) every slot (every 12 seconds)
    uint256 priceDropPerSlot;
    /// @notice Price where this auction stage ends (in wei)
    uint256 endPrice;
    /// @notice The duration of time that this stage will last, in seconds
    uint256 duration;
}

struct AuctionStageConfiguration {
    /// @notice Amount that the price drops (in wei) every slot (every 12 seconds)
    uint256 priceDropPerSlot;
    /// @notice Price where this auction stage ends (in wei)
    uint256 endPrice;
}

contract PPPArtworkAuction is EarlyAccessSale, Shuffler {
    string private publicLimitRevertMessage;

    /// @notice The number of mints available for each pass
    uint256 public passLimit;

    /// @notice The number of mints available without a pass (per address), after the early access period
    uint256 public publicLimit;

    /// @notice The total number of mints available until the auction is sold out
    uint256 public mintLimit;

    /// @notice ERC-721 contract whose tokens are minted by this auction
    /// @dev Must implement MintableById and allow minting out of order
    MintableById public tokenContract;

    /// @notice Starting price for the Dutch auction (in wei)
    uint256 public startPrice;

    /// @notice Lowest price at which a token was minted (in wei)
    uint256 public lowestPrice;

    /// @notice Stages for this auction, in order
    AuctionStage[] public auctionStages;

    /// @notice Number of reserveTokens that have been minted
    uint256 public reserveCount = 0;

    /// @notice Number of tokens that have been minted per address
    mapping(address => uint256) public mintCount;
    /// @notice Total amount paid to mint per address
    mapping(address => uint256) public mintPayment;

    /// @notice Number of tokens that have been minted without a pass, per address
    /// @dev May over count public mints on the final sale transaction, so not publicly exposed
    mapping(address => uint256) private publicMintCount;

    uint256 private previousPayment = 0;

    /// @notice An event emitted upon purchases
    event Purchase(address purchaser, uint256 mintId, uint256 tokenId, uint256 price, bool passMint);

    /// @notice An event emitted when reserve tokens are minted
    event Reservation(address recipient, uint256 quantity, uint256 totalReserved);

    /// @notice An event emitted when a refund is sent to a minter
    event Refund(address recipient, uint256 amount);

    /// @notice An error returned when the auction has reached its `mintLimit`
    error SoldOut();

    error FailedWithdraw(uint256 amount, bytes data);

    constructor(
        MintableById tokenContract_,
        uint256 startTime_,
        uint256 startPrice_,
        uint256 earlyPriceDrop,
        uint256 transitionPrice,
        uint256 latePriceDrop,
        uint256 restPrice,
        uint256 mintLimit_,
        uint256 publicLimit_,
        uint256 passLimit_,
        uint256 earlyAccessDuration_
    ) EarlyAccessSale(startTime_, earlyAccessDuration_) Shuffler(mintLimit_) {
        // CHECKS inputs
        require(address(tokenContract_) != address(0), "Token contract must not be the zero address");

        require(restPrice > 1e15, "Rest price too low: check that prices are in wei");
        require(startPrice_ >= transitionPrice, "Start price must not be lower than transition price");
        require(transitionPrice >= restPrice, "Transition price must not be lower than rest price");

        uint256 earlyPriceDifference;
        uint256 latePriceDifference;
        unchecked {
            earlyPriceDifference = startPrice_ - transitionPrice;
            latePriceDifference = transitionPrice - restPrice;
        }
        require(earlyPriceDrop * 25 <= earlyPriceDifference, "Initial stage must last at least 5 minutes");
        require(latePriceDrop * 25 <= latePriceDifference, "Final stage must last at least 5 minutes");
        require(earlyPriceDifference % earlyPriceDrop == 0, "Transition price must be reachable by earlyPriceDrop");
        require(latePriceDifference % latePriceDrop == 0, "Resting price must be reachable by latePriceDrop");
        require(
            earlyPriceDrop * (5 * 60 * 12) >= earlyPriceDifference,
            "Initial stage must not last longer than 12 hours"
        );
        require(latePriceDrop * (5 * 60 * 12) >= latePriceDifference, "Final stage must not last longer than 12 hours");

        require(mintLimit_ >= 10, "Mint limit too low");
        require(passLimit_ != 0, "Pass limit must not be zero");
        require(publicLimit_ != 0, "Public limit must not be zero");
        require(passLimit_ < mintLimit_, "Pass limit must be lower than mint limit");
        require(publicLimit_ < mintLimit_, "Public limit must be lower than mint limit");

        // EFFECTS
        tokenContract = tokenContract_;
        lowestPrice = startPrice = startPrice_;

        unchecked {
            AuctionStage storage earlyStage = auctionStages.push();
            earlyStage.priceDropPerSlot = earlyPriceDrop;
            earlyStage.endPrice = transitionPrice;
            earlyStage.duration = (12 * earlyPriceDifference) / earlyPriceDrop;

            AuctionStage storage lateStage = auctionStages.push();
            lateStage.priceDropPerSlot = latePriceDrop;
            lateStage.endPrice = restPrice;
            lateStage.duration = (12 * latePriceDifference) / latePriceDrop;
        }

        mintLimit = mintLimit_;
        passLimit = passLimit_;
        publicLimit = publicLimit_;

        publicLimitRevertMessage = publicLimit_ == 1
            ? "Limited to one purchase without a pass"
            : string.concat("Limited to ", Strings.toString(publicLimit_), " purchases without a pass");
    }

    // PUBLIC FUNCTIONS

    /// @notice Mint a token on the `tokenContract` contract. Must include at least `currentPrice`.
    function mint() external payable publicMint {
        // CHECKS
        require(publicMintCount[msg.sender] < publicLimit, publicLimitRevertMessage);

        // EFFECTS
        unchecked {
            // Unchecked arithmetic: publicMintCount cannot exceed publicLimit
            publicMintCount[msg.sender]++;
        }

        // Proceed to core mint logic (including all CHECKS + EFFECTS + INTERACTIONS)
        _mint(false);
    }

    /// @notice Mint multiple tokens on the `tokenContract` contract. Must pay at least `currentPrice` * `quantity`.
    /// @param quantity The number of tokens to mint: must not be greater than `publicLimit`
    function mintMultiple(uint256 quantity) public payable virtual publicMint whenNotPaused {
        // CHECKS state and inputs
        uint256 remaining = remainingValueCount;
        if (remaining == 0) revert SoldOut();
        uint256 alreadyMinted = mintCount[msg.sender];
        require(quantity > 0, "Must mint at least one token");

        uint256 publicMinted = publicMintCount[msg.sender];
        require(publicMinted < publicLimit && quantity <= publicLimit, publicLimitRevertMessage);

        uint256 price = msg.value / quantity;
        uint256 slotPrice = currentPrice();
        require(price >= slotPrice, "Insufficient payment");

        // EFFECTS
        if (quantity > remaining) {
            quantity = remaining;
        }

        unchecked {
            if (publicMinted + quantity > publicLimit) {
                quantity = publicLimit - publicMinted;
            }

            // Unchecked arithmetic: mintCount cannot exceed mintLimit
            mintCount[msg.sender] = alreadyMinted + quantity;
            // Unchecked arithmetic: publicMintCount cannot exceed publicLimit
            publicMintCount[msg.sender] += quantity;
            // Unchecked arithmetic: can't exceed total existing wei; not expected to exceed mintLimit * startPrice
            mintPayment[msg.sender] += msg.value;
        }

        if (slotPrice < lowestPrice) {
            lowestPrice = slotPrice;
        }

        // INTERACTIONS: call mint on known contract (tokenContract.mint contains no external interactions)
        unchecked {
            uint256 startMintId = mintLimit - remainingValueCount;
            for (uint256 i = 0; i < quantity; i++) {
                uint256 tokenId = drawNext();
                emit Purchase(msg.sender, startMintId + i, tokenId, price, false);
                tokenContract.mint(msg.sender, tokenId);
            }
        }
    }

    /// @notice Send any available refund to the message sender
    function refund() external returns (uint256) {
        // CHECK available refund
        uint256 refundAmount = refundAvailable(msg.sender);
        require(refundAmount > 0, "No refund available");

        // EFFECTS
        unchecked {
            // Unchecked arithmetic: refundAmount will always be less than mintPayment
            mintPayment[msg.sender] -= refundAmount;
        }

        emit Refund(msg.sender, refundAmount);

        // INTERACTIONS
        (bool refunded, ) = msg.sender.call{value: refundAmount}("");
        require(refunded, "Refund transfer was reverted");

        return refundAmount;
    }

    // PASS HOLDER FUNCTIONS

    /// @notice Mint a token on the `tokenContract` to the caller, using a pass
    /// @param passId The pass token ID: caller must be owner or operator and pass must have at least one mint remaining
    function mintFromPass(uint256 passId) external payable started {
        // CHECKS that the caller has permissions and the pass can be used
        require(passAllowance(passId) > 0, "No mints remaining for provided pass");

        // INTERACTIONS: mark the pass as used (known contract with no external interactions)
        passes.logPassUse(passId, passProjectId);

        // Proceed to core mint logic (including all CHECKS + EFFECTS + INTERACTIONS)
        _mint(true);
    }

    /// @notice Mint multiple tokens on the `tokenContract` to the caller, using passes
    /// @param passIds The pass token IDs: caller must be owner or operator and passes must have mints remaining
    function mintMultipleFromPasses(
        uint256 quantity,
        uint256[] calldata passIds
    ) external payable started whenNotPaused {
        // CHECKS state and inputs
        uint256 remaining = remainingValueCount;
        if (remaining == 0) revert SoldOut();
        require(quantity > 0, "Must mint at least one token");
        require(quantity <= mintLimit, "Quantity exceeds auction size");

        uint256 price = msg.value / quantity;
        uint256 slotPrice = currentPrice();
        require(price >= slotPrice, "Insufficient payment");

        uint256 passCount = passIds.length;
        require(passCount > 0, "Must include at least one pass");

        // EFFECTS
        if (quantity > remaining) {
            quantity = remaining;
        }

        // CHECKS: check passes and log their usages
        uint256 passUses = 0;
        for (uint256 i = 0; i < passCount; i++) {
            uint256 passId = passIds[i];

            // CHECKS
            uint256 allowance = passAllowance(passId);

            // INTERACTIONS
            for (uint256 j = 0; j < allowance && passUses < quantity; j++) {
                passes.logPassUse(passId, passProjectId);
                passUses++;
            }

            // Don't check more passes than needed
            if (passUses == quantity) break;
        }

        require(passUses > 0, "No mints remaining for provided passes");
        quantity = passUses;

        // EFFECTS
        unchecked {
            // Unchecked arithmetic: mintCount cannot exceed passLimit * number of existing passes
            mintCount[msg.sender] += quantity;
            // Unchecked arithmetic: can't exceed total existing wei; not expected to exceed mintLimit * startPrice
            mintPayment[msg.sender] += msg.value;
        }

        if (slotPrice < lowestPrice) {
            lowestPrice = slotPrice;
        }

        // INTERACTIONS: call mint on known contract (tokenContract.mint contains no external interactions)
        unchecked {
            uint256 startMintId = mintLimit - remainingValueCount;
            for (uint256 i = 0; i < quantity; i++) {
                uint256 tokenId = drawNext();
                emit Purchase(msg.sender, startMintId + i, tokenId, price, true);
                tokenContract.mint(msg.sender, tokenId);
            }
        }
    }

    // OWNER FUNCTIONS

    /// @notice Mint reserve tokens to the designated `recipient`
    /// @dev Can only be called by the contract `owner`. Reverts if the auction has already started.
    function reserve(address recipient, uint256 quantity) external unstarted onlyOwner {
        // CHECKS contract state
        uint256 remaining = remainingValueCount;
        if (remaining == 0) revert SoldOut();

        // EFFECTS
        if (quantity > remaining) {
            quantity = remaining;
        }

        unchecked {
            // Unchecked arithmetic: neither value can exceed mintLimit
            reserveCount += quantity;
        }

        emit Reservation(recipient, quantity, reserveCount);

        // INTERACTIONS
        unchecked {
            for (uint256 i = 0; i < quantity; i++) {
                tokenContract.mint(recipient, drawNext());
            }
        }
    }

    /// @notice withdraw auction proceeds
    /// @dev Can only be called by the contract `owner`. Reverts if the final price is unknown, if proceeds have already
    ///  been withdrawn, or if the fund transfer fails.
    function withdraw(address recipient) external onlyOwner {
        // CHECKS contract state
        uint256 remaining = remainingValueCount;
        bool soldOut = remaining == 0;
        uint256 finalPrice = lowestPrice;
        if (!soldOut) {
            finalPrice = auctionStages[auctionStages.length - 1].endPrice;

            // Only allow a withdraw before the auction is sold out if the price has finished falling
            require(currentPrice() == finalPrice, "Price is still falling");
        }

        uint256 totalPayment = (mintLimit - remaining - reserveCount) * finalPrice;
        require(totalPayment > previousPayment, "All funds have been withdrawn");

        // EFFECTS
        uint256 outstandingPayment = totalPayment - previousPayment;
        uint256 balance = address(this).balance;
        if (outstandingPayment > balance) {
            // Escape hatch to prevent stuck funds, but this shouldn't happen
            require(balance > 0, "All funds have been withdrawn");
            outstandingPayment = balance;
        }

        previousPayment += outstandingPayment;
        (bool success, bytes memory data) = recipient.call{value: outstandingPayment}("");
        if (!success) revert FailedWithdraw(outstandingPayment, data);
    }

    /// @notice Update the tokenContract contract address
    /// @dev Can only be called by the contract `owner`. Reverts if the auction has already started.
    function setMintable(MintableById tokenContract_) external unstarted onlyOwner {
        // CHECKS inputs
        require(address(tokenContract_) != address(0), "Token contract must not be the zero address");
        // EFFECTS
        tokenContract = tokenContract_;
    }

    /// @notice Update the auction price ranges and rates of decrease
    /// @dev Since the values are validated against each other, they are all set together. Can only be called by the
    ///  contract `owner`. Reverts if the auction has already started.
    function setPricing(
        uint256 startPrice_,
        AuctionStageConfiguration[] calldata stages_
    ) external unstarted onlyOwner {
        // CHECKS inputs
        uint256 stageCount = stages_.length;
        require(stageCount > 0, "Must specify at least one auction stage");

        // EFFECTS + additional CHECKS
        uint256 previousPrice = startPrice = startPrice_;
        delete auctionStages;

        for (uint256 i; i < stageCount; i++) {
            AuctionStageConfiguration calldata config = stages_[i];
            require(config.endPrice < previousPrice, "Each stage price must be lower than the previous price");
            require(config.endPrice > 1e15, "Stage price too low: check that prices are in wei");

            uint256 priceDifference = previousPrice - config.endPrice;
            require(config.priceDropPerSlot * 25 <= priceDifference, "Each stage must last at least 5 minutes");
            require(
                priceDifference % config.priceDropPerSlot == 0,
                "Stage end price must be reachable by slot price drop"
            );
            require(
                config.priceDropPerSlot * (5 * 60 * 12) >= priceDifference,
                "Stage must not last longer than 12 hours"
            );

            AuctionStage storage newStage = auctionStages.push();
            newStage.duration = (12 * priceDifference) / config.priceDropPerSlot;
            newStage.priceDropPerSlot = config.priceDropPerSlot;
            newStage.endPrice = previousPrice = config.endPrice;
        }
    }

    /// @notice Update the number of total mints
    function setMintLimit(uint256 mintLimit_) external unstarted onlyOwner {
        // CHECKS inputs
        require(reserveCount == 0, 'Cannot change the mint limit once tokens have been reserved');
        require(mintLimit_ >= 10, "Mint limit too low");
        require(passLimit < mintLimit_, "Mint limit must be higher than pass limit");
        require(publicLimit < mintLimit_, "Mint limit must be higher than public limit");

        // EFFECTS
        mintLimit = remainingValueCount = mintLimit_;
    }

    /// @notice Update the per-pass mint limit
    function setPassLimit(uint256 passLimit_) external onlyOwner {
        // CHECKS inputs
        require(passLimit_ != 0, "Pass limit must not be zero");
        require(passLimit_ < mintLimit, "Pass limit must be lower than mint limit");

        // EFFECTS
        passLimit = passLimit_;
    }

    /// @notice Update the public per-wallet mint limit
    function setPublicLimit(uint256 publicLimit_) external onlyOwner {
        // CHECKS inputs
        require(publicLimit_ != 0, "Public limit must not be zero");
        require(publicLimit_ < mintLimit, "Public limit must be lower than mint limit");

        // EFFECTS
        publicLimit = publicLimit_;
        publicLimitRevertMessage = publicLimit_ == 1
            ? "Limited to one purchase without a pass"
            : string.concat("Limited to ", Strings.toString(publicLimit_), " purchases without a pass");
    }

    // VIEW FUNCTIONS

    /// @notice Query the current price
    function currentPrice() public view returns (uint256 price) {
        uint256 time = timeElapsed();

        price = startPrice;
        uint256 stageCount = auctionStages.length;
        uint256 stageDuration;
        AuctionStage storage stage;
        for (uint256 i = 0; i < stageCount; i++) {
            stage = auctionStages[i];
            stageDuration = stage.duration;
            if (time < stageDuration) {
                unchecked {
                    uint256 drop = stage.priceDropPerSlot * (time / 12);
                    return price - drop;
                }
            }

            // Proceed to the next stage
            unchecked {
                time -= stageDuration;
            }
            price = auctionStages[i].endPrice;
        }

        // Auction has reached resting price
        return price;
    }

    /// @notice Query the refund available for the specified `minter`
    function refundAvailable(address minter) public view returns (uint256) {
        uint256 minted = mintCount[minter];
        if (minted == 0) return 0;

        uint256 refundPrice = remainingValueCount == 0 ? lowestPrice : currentPrice();

        uint256 payment = mintPayment[minter];
        uint256 newPayment;
        uint256 refundAmount;
        unchecked {
            // Unchecked arithmetic: newPayment cannot exceed mintLimit * startPrice
            newPayment = minted * refundPrice;
            // Unchecked arithmetic: value only used if newPayment < payment
            refundAmount = payment - newPayment;
        }

        return (newPayment < payment) ? refundAmount : 0;
    }

    // INTERNAL FUNCTIONS

    function _mint(bool passMint) internal whenNotPaused {
        // CHECKS state and inputs
        uint256 remaining = remainingValueCount;
        if (remaining == 0) revert SoldOut();
        uint256 slotPrice = currentPrice();
        require(msg.value >= slotPrice, "Insufficient payment");

        // EFFECTS
        unchecked {
            // Unchecked arithmetic: mintCount cannot exceed mintLimit
            mintCount[msg.sender]++;
            // Unchecked arithmetic: can't exceed this.balance; not expected to exceed mintLimit * startPrice
            mintPayment[msg.sender] += msg.value;
        }

        if (slotPrice < lowestPrice) {
            lowestPrice = slotPrice;
        }

        uint256 mintId = mintLimit - remainingValueCount;
        uint256 tokenId = drawNext();
        emit Purchase(msg.sender, mintId, tokenId, msg.value, passMint);

        // INTERACTIONS: call mint on known contract (tokenContract.mint contains no external interactions)
        tokenContract.mint(msg.sender, tokenId);
    }

    // INTERNAL VIEW FUNCTIONS

    function passAllowance(uint256 passId) internal view returns (uint256) {
        // Uses view functions of the passes contract
        require(Delegation.check(msg.sender, passes, passId), "Caller is not pass owner or approved");

        uint256 uses = passes.passUses(passId, passProjectId);
        unchecked {
            return uses >= passLimit ? 0 : passLimit - uses;
        }
    }
}