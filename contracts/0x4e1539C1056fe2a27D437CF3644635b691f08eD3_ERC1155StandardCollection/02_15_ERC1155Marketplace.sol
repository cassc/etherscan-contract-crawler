// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IEaselyPayout.sol";
import "../token/ERC1155/ERC1155.sol";
import "../utils/ECDSA.sol";
import "../utils/IERC2981.sol";

error BeforeStartTime();
error InsufficientValue();
error InsufficientSellerBalance();
error InvalidBuyAmount();
error InvalidStartEndPrices();
error InvalidStartEndTimes();
error InvalidVersion();
error LoansInactive();
error MustHaveDualSignature();
error MustHaveOwnerSignature();
error MustHaveTokenOwnerSignature();
error MustHaveVerifiedSignature();
error NotTokenLoaner();
error OverMaxRoyalties();
error OverSignatureLimit();
error TokenOnLoan();
error WithdrawSplitsTooHigh();

/**
 * @dev Extension of the ERC1155 contract that integrates a marketplace so that simple lazy-sales
 * do not have to be done on another contract. This saves gas fees on secondary sales because
 * buyers will not have to pay a gas fee to setApprovalForAll for another marketplace contract after buying.
 *
 * Easely will help power the lazy-selling as well as lazy minting that take place on
 * directly on the collection, which is why we take a cut of these transactions. Our cut can
 * be publically seen in the connected EaselyPayout contract and cannot exceed 5%.
 *
 * Owners also set a dual signer which they can change at any time. This dual signer helps enable
 * sales for large batches of addresses without needing to manually sign hundreds or thousands of hashes.
 * It also makes phishing scams harder as both signatures need to be compromised before an unwanted sale can occur.
 */
abstract contract ERC1155Marketplace is ERC1155, IERC2981 {
    using ECDSA for bytes32;
    using Strings for uint256;

    // Allows token owners to loan tokens to other addresses.
    // bool public loaningActive;

    /* see {IEaselyPayout} for more */
    address public constant PAYOUT_CONTRACT_ADDRESS =
        0xa95850bB73459ADB9587A97F103a4A7CCe59B56E;
    uint256 internal constant TIME_PER_DECREMENT = 300;

    /* Basis points or BPS are 1/100th of a percent, so 10000 basis points accounts for 100% */
    uint256 internal constant BPS_TOTAL = 10000;
    /* Max basis points for the owner for secondary sales of this collection */
    uint256 internal constant MAX_SECONDARY_BPS = 1000;
    /* Default payout percent if there is no signature set */
    uint256 internal constant DEFAULT_PAYOUT_BPS = 500;
    /* Signer for initializing splits to ensure splits were agreed upon by both parties */
    address internal constant VERIFIED_CONTRACT_SIGNER =
        0x1BAAd9BFa20Eb279d2E3f3e859e3ae9ddE666c52;

    /*
     * Optional addresses to distribute referral commission for this collection
     *
     * Referral commission is taken from easely's cut
     */
    address public referralAddress;
    /*
     * Optional addresses to distribute partnership comission for this collection
     *
     * Partnership commission is taken in addition to easely's cut
     */
    address public partnershipAddress;
    /* Optional addresses to distribute revenue of primary sales of this collection */
    address public revenueShareAddress;

    /* Enables dual address signatures to lazy mint */
    address public dualSignerAddress;

    uint256 internal ownerVersion;
    /* Constant used to help calculate royalties */
    uint256 private constant MAX_BPS = 10000;

    /* Address royalties get sent to for marketplaces that honor EIP-2981. Owner can change this at any time */
    address private royaltyAddress;

    struct WithdrawSplits {
        /* Optional basis points for the owner for secondary sales of this collection */
        uint64 ownerRoyaltyBPS;
        /* Basis points for easely's payout contract */
        uint64 payoutBPS;
        /* Optional basis points for revenue sharing the owner wants to set up */
        uint64 revenueShareBPS;
        /*
         * Optional basis points for collections that have been referred.
         *
         * Contracts with this will have a reduced easely's payout cut so that
         * the creator's cut is unaffected
         */
        uint32 referralBPS;
        /*
         * Optional basis points for collections that require partnerships
         *
         * Contracts with this will have this fee on top of easely's payout cut because the partnership
         * will offer advanced web3 integration of this contract in some form beyond what easely provides.
         */
        uint32 partnershipBPS;
    }

    WithdrawSplits public splits;

    /* Mapping to the active version for all signed transactions */
    mapping(address => uint256) internal _addressToActiveVersion;
    /* To allow signatures to be limited to certain number of times */
    mapping(bytes32 => uint256) internal hashCount;

    // Events related to lazy selling
    event SaleCancelled(address indexed seller, bytes32 hash);
    event SaleCompleted(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 totalPrice,
        bytes32 hash
    );

    // Miscellaneous events
    event VersionChanged(address indexed seller, uint256 version);
    event DualSignerChanged(address newSigner);
    event BalanceWithdrawn(uint256 balance);
    event RoyaltyUpdated(uint256 bps);
    event WithdrawSplitsSet(
        address indexed revenueShareAddress,
        address indexed referralAddress,
        address indexed partnershipAddress,
        uint256 payoutBPS,
        uint256 revenueShareBPS,
        uint256 referralBPS,
        uint256 partnershipBPS
    );

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev initializes all of the addresses and percentage of withdrawn funds that
     * each address will get. These addresses and BPS splits must be signed by both the
     * verified easely wallet and the creator of the contract. If a signature is missing
     * the contract has a default of 5% to the easely payout wallet.
     */
    function _initWithdrawSplits(
        address royaltyAddress_,
        address revenueShareAddress_,
        address referralAddress_,
        address partnershipAddress_,
        uint256 payoutBPS_,
        uint256 ownerRoyaltyBPS_,
        uint256 revenueShareBPS_,
        uint256 referralBPS_,
        uint256 partnershipBPS_,
        bytes[2] memory signatures
    ) internal virtual {
        royaltyAddress = royaltyAddress_;
        revenueShareAddress = revenueShareAddress_;
        if (ownerRoyaltyBPS_ > MAX_SECONDARY_BPS) revert OverMaxRoyalties();
        if (signatures[1].length == 0) {
            if (DEFAULT_PAYOUT_BPS + revenueShareBPS_ > BPS_TOTAL) {
                revert WithdrawSplitsTooHigh();
            }
            splits = WithdrawSplits(
                uint64(ownerRoyaltyBPS_),
                uint64(DEFAULT_PAYOUT_BPS),
                uint64(revenueShareBPS_),
                uint32(0),
                uint32(0)
            );
            emit WithdrawSplitsSet(
                revenueShareAddress_,
                address(0),
                address(0),
                DEFAULT_PAYOUT_BPS,
                revenueShareBPS_,
                0,
                0
            );
        } else {
            if (
                payoutBPS_ + referralBPS_ + partnershipBPS_ + revenueShareBPS_ >
                BPS_TOTAL
            ) {
                revert WithdrawSplitsTooHigh();
            }
            bytes memory encoded = abi.encode(
                "InitializeSplits",
                royaltyAddress_,
                revenueShareAddress_,
                referralAddress_,
                partnershipAddress_,
                payoutBPS_,
                revenueShareBPS_,
                referralBPS_,
                partnershipBPS_
            );
            bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(encoded));
            if (hash.recover(signatures[0]) != _owner) {
                revert MustHaveOwnerSignature();
            }
            if (hash.recover(signatures[1]) != VERIFIED_CONTRACT_SIGNER) {
                revert MustHaveVerifiedSignature();
            }
            referralAddress = referralAddress_;
            partnershipAddress = partnershipAddress_;
            splits = WithdrawSplits(
                uint64(ownerRoyaltyBPS_),
                uint64(payoutBPS_),
                uint64(revenueShareBPS_),
                uint32(referralBPS_),
                uint32(partnershipBPS_)
            );
            emit WithdrawSplitsSet(
                revenueShareAddress_,
                referralAddress_,
                partnershipAddress_,
                payoutBPS_,
                revenueShareBPS_,
                referralBPS_,
                partnershipBPS_
            );
        }
        emit RoyaltyUpdated(ownerRoyaltyBPS_);
    }

    /**
     * @dev see {IERC2981-supportsInterface}
     */
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 royalty = (_salePrice * splits.ownerRoyaltyBPS) / MAX_BPS;
        return (royaltyAddress, royalty);
    }

    /**
     * @dev Updates the address royalties get sent to for marketplaces that honor EIP-2981.
     */
    function setRoyaltyAddress(address wallet) external onlyOwner {
        royaltyAddress = wallet;
    }

    /**
     * @dev see {_setSecondary}
     */
    function setRoyaltiesBPS(uint256 newBPS) external onlyOwner {
        if (newBPS > MAX_SECONDARY_BPS) revert OverMaxRoyalties();
        splits.ownerRoyaltyBPS = uint64(newBPS);
        emit RoyaltyUpdated(newBPS);
    }

    /**
     * @dev See {_currentPrice}
     */
    function getCurrentPrice(uint256[4] memory pricesAndTimestamps)
        external
        view
        returns (uint256)
    {
        return _currentPrice(pricesAndTimestamps);
    }

    /**
     * @dev Returns the current activeVersion of an address both used to create signatures
     * and to verify signatures of {buyToken} and {buyNewToken}
     */
    function getActiveVersion(address address_)
        external
        view
        returns (uint256)
    {
        if (address_ == owner()) {
            return ownerVersion;
        }
        return _addressToActiveVersion[address_];
    }

    /**
     * This function, while callable by anybody will always ONLY withdraw the
     * contract's balance to:
     *
     * the owner's account
     * the addresses the owner has set up for revenue share
     * the easely payout contract cut - capped at 5% but can be lower for some users
     *
     * This is callable by anybody so that Easely can set up automatic payouts
     * after a contract has reached a certain minimum to save creators the gas fees
     * involved in withdrawing balances.
     */
    function withdrawBalance(uint256 withdrawAmount) external {
        if (withdrawAmount > address(this).balance) {
            withdrawAmount = address(this).balance;
        }

        uint256 payoutBasis = withdrawAmount / BPS_TOTAL;
        if (splits.revenueShareBPS > 0) {
            payable(revenueShareAddress).transfer(
                payoutBasis * splits.revenueShareBPS
            );
        }
        if (splits.referralBPS > 0) {
            payable(referralAddress).transfer(payoutBasis * splits.referralBPS);
        }
        if (splits.partnershipBPS > 0) {
            payable(partnershipAddress).transfer(
                payoutBasis * splits.partnershipBPS
            );
        }
        payable(PAYOUT_CONTRACT_ADDRESS).transfer(
            payoutBasis * splits.payoutBPS
        );

        uint256 remainingAmount = withdrawAmount -
            payoutBasis *
            (splits.revenueShareBPS +
                splits.partnershipBPS +
                splits.referralBPS +
                splits.payoutBPS);
        payable(owner()).transfer(remainingAmount);
        emit BalanceWithdrawn(withdrawAmount);
    }

    /**
     * @dev Allows the owner to change who the dual signer is
     */
    function setDualSigner(address alt) external onlyOwner {
        dualSignerAddress = alt;
        emit DualSignerChanged(alt);
    }

    /**
     * @dev Usable by any user to update the version that they want their signatures to check. This is helpful if
     * an address wants to mass invalidate their signatures without having to call cancelSale on each one.
     */
    function updateVersion(uint256 version) external {
        if (_msgSender() == owner()) {
            ownerVersion = version;
        } else {
            _addressToActiveVersion[_msgSender()] = version;
        }
        emit VersionChanged(_msgSender(), version);
    }

    /**
     * @dev helper method get ownerRoyalties into an array form
     */
    function _royalties() internal view returns (address[] memory) {
        address[] memory royalties = new address[](1);
        royalties[0] = royaltyAddress;
        return royalties;
    }

    /**
     * @dev helper method get secondary BPS into array form
     */
    function _royaltyBPS() internal view returns (uint256[] memory) {
        uint256[] memory ownerBPS = new uint256[](1);
        ownerBPS[0] = splits.ownerRoyaltyBPS;
        return ownerBPS;
    }

    /**
     * @dev Checks if an address is either the owner, or the approved alternate signer.
     */
    function _checkValidSigner(address signer) internal view {
        if (signer == owner()) return;
        if (dualSignerAddress == address(0)) revert MustHaveOwnerSignature();
        if (signer != dualSignerAddress) revert MustHaveDualSignature();
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function _hashForSale(
        address owner,
        uint256 version,
        uint256 nonce,
        uint256 tokenId,
        uint256 amount,
        uint256[4] memory pricesAndTimestamps
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    address(this),
                    block.chainid,
                    owner,
                    version,
                    nonce,
                    tokenId,
                    amount,
                    pricesAndTimestamps
                )
            );
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function _hashToCheckForSale(
        address owner,
        uint256 version,
        uint256 nonce,
        uint256 tokenId,
        uint256 amount,
        uint256[4] memory pricesAndTimestamps
    ) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                _hashForSale(
                    owner,
                    version,
                    nonce,
                    tokenId,
                    amount,
                    pricesAndTimestamps
                )
            );
    }

    /**
     * @dev Current price for a sale which is calculated for the case of a descending sale. So
     * the ending price must be less than the starting price and the timestamp is active.
     * Standard single fare sales will have a matching starting and ending price.
     */
    function _currentPrice(uint256[4] memory pricesAndTimestamps)
        internal
        view
        returns (uint256)
    {
        uint256 startingPrice = pricesAndTimestamps[0];
        uint256 endingPrice = pricesAndTimestamps[1];
        uint256 startingTimestamp = pricesAndTimestamps[2];
        uint256 endingTimestamp = pricesAndTimestamps[3];

        uint256 currTime = block.timestamp;
        if (currTime < startingTimestamp) revert BeforeStartTime();
        if (startingTimestamp >= endingTimestamp) revert InvalidStartEndTimes();
        if (startingPrice < endingPrice) revert InvalidStartEndPrices();

        if (startingPrice == endingPrice || currTime > endingTimestamp) {
            return endingPrice;
        }

        uint256 diff = startingPrice - endingPrice;
        uint256 decrements = (currTime - startingTimestamp) /
            TIME_PER_DECREMENT;
        if (decrements == 0) {
            return startingPrice;
        }

        // decrements will equal 0 before totalDecrements does so we will not divide by 0
        uint256 totalDecrements = (endingTimestamp - startingTimestamp) /
            TIME_PER_DECREMENT;

        return startingPrice - (diff / totalDecrements) * decrements;
    }

    /**
     * @dev Verifies that both the signer and the dual signer (if exists) have signed the hash
     * to allow a sale of a token of a certain amount. Also verifies if the buyAmount that is 
     * requested is not over the total hashAmount that the signer has put on sale for this signature.
     */
    function _verifySignaturesAndUpdateHash(
        bytes32 hash,
        address signer,
        uint256 hashAmount,
        uint256 buyAmount,
        bytes memory signature,
        bytes memory dualSignature
    ) internal {
        if (hashAmount != 0) {
            if (hashCount[hash] + buyAmount > hashAmount) {
                revert OverSignatureLimit();
            }
            hashCount[hash] += buyAmount;
        }

        if (hash.recover(signature) != signer) revert MustHaveOwnerSignature();
        if (
            dualSignerAddress != address(0) &&
            hash.recover(dualSignature) != dualSignerAddress
        ) revert MustHaveDualSignature();
    }

    /**
     * @dev Usable by the owner of any token initiate a sale for their token. This does not
     * lock the tokenId and the owner can freely trade their token, but doing so will
     * invalidate the ability for others to buy.
     */
    function hashToSignToSellToken(
        uint256 version,
        uint256 nonce,
        uint256 tokenId,
        uint256 amount,
        uint256[4] memory pricesAndTimestamps
    ) external view returns (bytes32) {
        return
            _hashForSale(
                _msgSender(),
                version,
                nonce,
                tokenId,
                amount,
                pricesAndTimestamps
            );
    }

    /**
     * @dev Usable to cancel hashes generated from {hashToSignToSellToken}
     */
    function cancelSale(
        uint256 version,
        uint256 nonce,
        uint256 tokenId,
        uint256 amount,
        uint256[4] memory pricesAndTimestamps
    ) external {
        bytes32 hash = _hashToCheckForSale(
            _msgSender(),
            version,
            nonce,
            tokenId,
            amount,
            pricesAndTimestamps
        );
        hashCount[hash] = 2**256 - 1;
        emit SaleCancelled(_msgSender(), hash);
    }

    /**
     * @dev With a hash signed by the method {hashToSignToSellToken} any user sending enough value can buy
     * the token from the seller. Tokens not owned by the contract owner are all considered secondary sales and
     * will give a cut to the owner of the contract based on the secondaryOwnerBPS.
     */
    function buyToken(
        address seller,
        uint256 version,
        uint256 nonce,
        uint256 tokenId,
        uint256 amount,
        uint256 buyAmount,
        uint256[4] memory pricesAndTimestamps,
        bytes memory signature,
        bytes memory dualSignature
    ) external payable {
        uint256 balance = balanceOf(seller, tokenId);
        if (balance < buyAmount) revert InsufficientSellerBalance();
        if (amount < buyAmount) revert InvalidBuyAmount();

        uint256 totalPrice = _currentPrice(pricesAndTimestamps) * buyAmount;
        if (_addressToActiveVersion[seller] != version) revert InvalidVersion();
        if (msg.value < totalPrice) revert InsufficientValue();

        bytes32 hash = _hashToCheckForSale(
            seller,
            version,
            nonce,
            tokenId,
            amount,
            pricesAndTimestamps
        );
        _verifySignaturesAndUpdateHash(
            hash,
            seller,
            amount,
            buyAmount,
            signature,
            dualSignature
        );

        _safeTransferFrom(seller, _msgSender(), tokenId, amount, "");
        emit SaleCompleted(
            seller,
            _msgSender(),
            tokenId,
            buyAmount,
            totalPrice,
            hash
        );

        if (seller != owner()) {
            IEaselyPayout(PAYOUT_CONTRACT_ADDRESS).splitPayable{
                value: totalPrice
            }(seller, _royalties(), _royaltyBPS());
        }
        payable(_msgSender()).transfer(msg.value - totalPrice);
    }
}