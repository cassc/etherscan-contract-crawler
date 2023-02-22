//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ITPLRevealedParts} from "../TPLRevealedParts/ITPLRevealedParts.sol";

import {FisherYatesBucket} from "../../utils/FisherYatesBucket.sol";
import {SSTORE2} from "../../utils/SSTORE2/SSTORE2.sol";

/// @title PrettysLuckyLoot
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice Contract allowing to sell TPLRevealedParts as Bundles
contract PrettysLuckyLoot is Ownable, FisherYatesBucket {
    using EnumerableSet for EnumerableSet.AddressSet;

    error PrettysShopClosed();
    error TooLate();
    error Disabled();
    error BundleSupplyExceeded();
    error AlreadyPickedWinners();
    error WinnerNotPicked();

    error InvalidAccount();

    error TransferPaymentError();

    error SaleAlreadyStarted();

    error InvalidSignature();

    error InvalidPayment();

    error QuotaExceeded();

    error PublicSaleNotEnded();
    error SaleEnded();

    error SaleNotPublic();

    struct BuyData {
        address account;
        uint96 maxBuy;
    }

    address public immutable TPL_REVEALED;

    address public immutable CB_WALLET;

    address public immutable CYBERBROKERS;

    /// @dev contains bundles data from 1 to 500
    address internal _bundlesDataStart;

    /// @dev contains bundles data from 501 to 1000
    address internal _bundlesDataEnd;

    /// @notice address used to sign the authorizations to mint
    address public signer;

    /// @notice address receiving the fees when a buy happens
    address public saleRecipient;

    /// @notice bundle price in wei
    uint256 public bundlePrice = 0.15 ether;

    /// @notice when does the sale start
    uint256 public startsAt;

    /// @notice until when the sale is limited
    uint256 public limitedUntil;

    /// @notice how many are publicly available for sale
    uint256 public availableForSale;

    /// @notice if a user already bought
    mapping(address => uint256) public accountBought;

    /// @notice addresses of loots buyers
    address[] public looters;

    /// @notice seed for luckyDraw
    uint256 public luckySeed;

    /// @notice ids to win
    uint256[] public luckyPrices;

    bool public isOpenToAll;

    constructor(
        address revealed,
        address cbWallet,
        address newSigner,
        address newSaleRecipient,
        address cyberBrokers
    ) {
        TPL_REVEALED = revealed;
        CB_WALLET = cbWallet;

        bucketSize = _startBucketSize();
        signer = newSigner;
        saleRecipient = newSaleRecipient;

        CYBERBROKERS = cyberBrokers;
    }

    // =============================================================
    //                       	   Interactions
    // =============================================================

    function canPurchase(address to, uint256 amount) public view returns (bool) {
        bool temp = isSaleActive();
        if (block.timestamp < limitedUntil) {
            temp = temp && accountBought[to] + amount <= 2;
        }

        return temp;
    }

    function isSaleActive() public view returns (bool) {
        return startsAt != 0 && block.timestamp >= startsAt;
    }

    function getWinners() public view returns (address[] memory) {
        uint256 seed = luckySeed;
        if (seed == 0) {
            revert WinnerNotPicked();
        }

        uint256 howMany = luckyPrices.length;

        address[] memory winners = new address[](howMany);

        address[] memory looters_ = looters;
        uint256 lootersLength = looters_.length;

        uint256 index;
        for (uint256 i; i < howMany; i++) {
            seed = uint256(keccak256(abi.encode(seed, i)));
            index = seed % lootersLength;

            // pick address at index
            winners[i] = looters_[index];

            // swap last item with item at index
            looters_[index] = looters_[lootersLength - 1];

            lootersLength--;
        }

        return winners;
    }

    // =============================================================
    //                       	   Interactions
    // =============================================================

    function purchase(
        address to,
        uint256 amount,
        bytes calldata proof
    ) external payable {
        if (to == address(0)) {
            to = msg.sender;
        }

        uint256 startsAt_ = startsAt;
        uint256 limitedUntil_ = limitedUntil;

        if (block.timestamp < startsAt_) {
            revert PrettysShopClosed();
        } else if (block.timestamp < limitedUntil_) {
            // here we verify they don't ask for more than the limit
            uint256 bought = accountBought[to] + amount;
            if (bought > 2) {
                revert QuotaExceeded();
            }

            accountBought[to] = bought;
        }

        // check signature if only allowlist has the right to mint
        if (!isOpenToAll) {
            _checkSignature(keccak256(abi.encode(to)), proof);
        }

        // verify there is enough supply
        uint256 availableForSale_ = availableForSale;
        if (availableForSale_ < amount) {
            revert BundleSupplyExceeded();
        }

        availableForSale = availableForSale_ - amount;

        // we add {amount} times in the `looters`
        for (uint256 i; i < amount; i++) {
            looters.push(to);
        }

        _purchase(to, amount);
    }

    function teamPurchase(
        address to,
        uint256 amount,
        bytes calldata proof
    ) external payable {
        if (availableForSale != 0) {
            revert PublicSaleNotEnded();
        }

        if (bucketSize == 0) {
            revert SaleEnded();
        }

        // check signature for team purchase
        _checkSignature(keccak256(abi.encode(to, amount)), proof);

        _purchase(to, amount);
    }

    // =============================================================
    //                       	   Owner
    // =============================================================
    function config(
        uint256 availableForSale_,
        uint256 startsAt_,
        uint256 limitedDuration
    ) external onlyOwner {
        availableForSale = availableForSale_;
        startsAt = startsAt_;
        limitedUntil = startsAt_ + limitedDuration;
    }

    /// @notice allows owner to select the winners using the beacon chain randomness
    function luckyDraw() external onlyOwner {
        if (availableForSale != 0) {
            revert PublicSaleNotEnded();
        }

        if (luckySeed != 0) {
            revert AlreadyPickedWinners();
        }

        luckySeed = block.difficulty;
    }

    /// @notice allows owner to send the prizes to the winners
    function sendPrizes() external onlyOwner {
        // we use a public function so anyone can chheck later that the algorithm
        // always return the same addresses once luckySeed has been set
        address[] memory winners = getWinners();

        uint256[] memory prices = luckyPrices;

        uint256 length = winners.length;
        for (uint256 i = 0; i < length; i++) {
            IERC721(CYBERBROKERS).transferFrom(CB_WALLET, winners[i], prices[i]);
        }
    }

    /// @notice allows owner to set isOpenToAll
    function setIsOpenToAll(bool newIsOpenToAll) external onlyOwner {
        isOpenToAll = newIsOpenToAll;
    }

    function setLuckyPrizes(uint256[] memory newPrices) external onlyOwner {
        luckyPrices = newPrices;
    }

    /// @notice allows owner to set the signer address to allow buys
    /// @param newSigner the new signer address
    function setSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }

    /// @notice allows owner to set the bundle price
    /// @param newPrice the new price
    function setBundlePrice(uint256 newPrice) external onlyOwner {
        bundlePrice = newPrice;
    }

    function setBucketSize(uint256 newBucketSize) external onlyOwner {
        bucketSize = newBucketSize;
    }

    /// @notice allows owner to set first half of the bundle data
    /// @param start the first half of the bundle data
    function setStartBundlesData(bytes memory start) external onlyOwner {
        if (bucketSize != _startBucketSize()) {
            revert SaleAlreadyStarted();
        }

        _bundlesDataStart = SSTORE2.write(start);
    }

    /// @notice allows owner to set second half of the bundle data
    /// @param end the second half of the bundle data
    function setEndBundlesData(bytes memory end) external onlyOwner {
        if (bucketSize != _startBucketSize()) {
            revert SaleAlreadyStarted();
        }

        _bundlesDataEnd = SSTORE2.write(end);
    }

    /// @notice allows owner to set the sale recipient address
    /// @param newSaleRecipient the new sale recipient
    function setSaleRecipient(address newSaleRecipient) external onlyOwner {
        saleRecipient = newSaleRecipient;
    }

    // =============================================================
    //                       	   Internals
    // =============================================================

    function _checkSignature(bytes32 message, bytes memory proof) internal {
        // verifies the signature
        if (signer != ECDSA.recover(ECDSA.toEthSignedMessageHash(message), proof)) {
            revert InvalidSignature();
        }
    }

    function _purchase(address to, uint256 amount) internal {
        // verifies the value sent is the right one
        if (msg.value != amount * bundlePrice) {
            revert InvalidPayment();
        }
        // we transfer the {value} to the saleRecipient
        (bool success, ) = saleRecipient.call{value: msg.value}("");
        if (!success) {
            revert TransferPaymentError();
        }

        // and we process at sending the nfts
        _processPick(to, amount);
    }

    function _processPick(address to, uint256 amount) internal {
        for (uint256 i; i < amount; i++) {
            ITPLRevealedParts(TPL_REVEALED).batchTransferFrom(CB_WALLET, to, _pickIds());
        }
    }

    function _pickIds() internal returns (uint256[] memory) {
        // first pick next index
        return _pickAtIndex(_pickNextIndex());
    }

    function _pickAtIndex(uint256 index) internal view returns (uint256[] memory) {
        address dataHolder;
        if (index <= 500) {
            dataHolder = _bundlesDataStart;
        } else {
            dataHolder = _bundlesDataEnd;
            // dataEnd holds 501 - 1000, so we need to remove 500 to get the right index
            index -= 500;
        }

        // where we start to read data in dataHolder
        index = (index - 1) * 20;

        bytes memory data = SSTORE2.read(dataHolder, index, index + 20);
        uint256[] memory ids = new uint256[](10);
        for (uint256 i = 0; i < 20; i += 2) {
            ids[i / 2] = (uint256(uint8(data[i])) << 8) + uint256(uint8(data[i + 1]));
        }

        return ids;
    }

    function _startBucketSize() internal returns (uint256) {
        return 1000;
    }
}