// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @author Asteria 🍖
 * @title New Dawn Trading Contract
 * @notice Used to buy and sell traits on the New Dawn marketplace
 */
contract NDTrading is Ownable {
    using ECDSA for bytes32;

    /// @param  'Empty'      transactionId hasn't been used yet
    /// @param  'Active'     transactionId currently ongoing
    /// @param  'Finished'   transactionId has been used
    enum TxState {
        Empty,
        Active,
        Finished
    }

    struct Transaction {
        uint256 price;
        address seller;
        address buyer;
        uint256 expireAt;
        TxState state;
    }

    event ListTrait(uint256 indexed transactionId);
    event CancelListing(uint256 indexed transactionId);
    event BuyTrait(uint256 indexed transactionId, address indexed wallet);
    event BuyingDisabled();

    /// @notice signer used for ECDSA verification
    address private signer;

    /// @notice min amount of time to keep a trait listed
    uint48 public minExpiry = 1 days;

    /// @notice max amount of time to keep a trait listed
    uint48 public maxExpiry = 180 days;

    address payable public NDRoyaltyAddress;
    uint96 public NDRoyaltyPercentage;

    /// @notice safe guard from malicious royalty setting. Set to 10%
    uint256 public constant MAX_PERCENTAGE = 1000;

    /// @notice mapping from id to 'Transaction' to hold all empty, active, or finished transactions
    mapping(uint256 txId => Transaction txInfo) public transactions;

    /// @notice safe guard against compromised owner
    bool private buyingDisabled;

    /// @param  _signer address of the expected recovered address for 'validSignature()'
    /// @param  _ndRoyaltyAddress address where royalties are sent from 'buyTrait()'
    /// @param  _ndRoyaltyPercentage percentage of royalties sent from 'buyTrait()'
    ///         (eg. 100 -> 1%)
    constructor(
        address _signer,
        address payable _ndRoyaltyAddress,
        uint256 _ndRoyaltyPercentage
    ) {
        require(
            _ndRoyaltyPercentage < MAX_PERCENTAGE,
            "ND: percentage too high"
        );

        signer = _signer;
        NDRoyaltyAddress = _ndRoyaltyAddress;
        NDRoyaltyPercentage = uint96(_ndRoyaltyPercentage);
    }

    // ---------------------------------------------------------- //
    // ------------------------ INTERNAL ------------------------ //
    // ---------------------------------------------------------- //
    function validSignature(
        uint256 price,
        uint256 expireAt,
        address buyer,
        uint256 transactionId,
        bytes memory signature
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        price,
                        expireAt,
                        buyer,
                        transactionId,
                        msg.sender
                    )
                )
            )
        );
        require(signer == hash.recover(signature), "ND: unauthorized");
    }

    function calcRoyalties(
        uint256 price
    ) internal view returns (uint256 toSeller, uint256 toRoyaltyAddr) {
        toRoyaltyAddr = (price * NDRoyaltyPercentage) / 1e4;
        toSeller = price - toRoyaltyAddr;
    }

    function transferPayments(
        address payable seller,
        uint256 toSeller,
        uint256 toRoyaltyAddr
    ) internal {
        (bool royaltySuccess, ) = NDRoyaltyAddress.call{value: toRoyaltyAddr}(
            ""
        );
        require(royaltySuccess, "ND: royalty transfer failed");

        (bool sellerSuccess, ) = seller.call{value: toSeller}("");
        require(sellerSuccess, "ND: seller transfer failed");
    }

    // ---------------------------------------------------------- //
    // ------------------------ EXTERNAL ------------------------ //
    // ---------------------------------------------------------- //
    /// @notice allows listing traits on the new dawn trait marketplace
    /// @param price amount in ETH to list the given trait for
    /// @param expireAt 'block.timestamp' of when to expire the current 'signature'
    /// @param buyer optional address of who can buy the specific trait
    /// @param transactionId specific id to be emitted and listened for off-chain
    /// @param signature bytes signature signed by 'signer'
    function listTrait(
        uint256 price,
        uint256 expireAt,
        address buyer,
        uint256 transactionId,
        bytes memory signature
    ) external {
        require(price > 0, "ND: invalid price");
        require(expireAt < block.timestamp + maxExpiry, "ND: expiry too long");
        require(expireAt > block.timestamp + minExpiry, "ND: expiry too short");

        Transaction storage transaction = transactions[transactionId];
        require(transaction.state == TxState.Empty, "ND: txId not empty");

        validSignature(price, expireAt, buyer, transactionId, signature);

        transaction.price = price;
        transaction.seller = msg.sender;
        transaction.buyer = buyer;
        transaction.expireAt = expireAt;
        transaction.state = TxState.Active;

        emit ListTrait(transactionId);
    }

    /// @notice allows cancelling a previously listed trait(s) on the new dawn trait martetplace
    /// @param transactionId specific id mapped to a specific transaction to cancel
    /// custom:reverts if state isn't active or seller doesn't equal msg.sender
    ///                it won't revert if the transaction's 'expireAt' has been met
    function cancelListing(uint256 transactionId) external {
        Transaction storage txn = transactions[transactionId];
        if (txn.expireAt > block.timestamp) {
            require(txn.state == TxState.Active, "ND: listing not active");
            require(msg.sender == txn.seller, "ND: not seller");
        }

        txn.state = TxState.Finished;
        emit CancelListing(transactionId);
    }

    /// @notice allows users to buy previously listed trait(s) on the new dawn trait martetplace
    /// @param transactionId specific id mapped to a specific transaction to buy
    function buyTrait(uint256 transactionId) external payable {
        require(!buyingDisabled, "ND: buying disabled");

        Transaction storage txn = transactions[transactionId];

        (uint256 toSeller, uint256 toRoyaltyAddr) = calcRoyalties(txn.price);

        require(txn.state == TxState.Active, "ND: listing not active");
        require(txn.expireAt > block.timestamp, "ND: transaction expired");
        require(txn.price == msg.value, "ND: invalid value");
        require(txn.seller != msg.sender, "ND: seller cannot be buyer");
        if (txn.buyer != address(0))
            require(txn.buyer == msg.sender, "ND: invalid buyer");

        address payable seller = payable(txn.seller);
        txn.state = TxState.Finished;

        transferPayments(seller, toSeller, toRoyaltyAddr);

        emit BuyTrait(transactionId, msg.sender);
    }

    // ------------------------------------------------------------ //
    // ------------------------ ONLY OWNER ------------------------ //
    // ------------------------------------------------------------ //
    /// @notice sets 'signer'
    ///         only callable by 'owner'
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /// @notice sets 'NDRoyaltyAddress' 'NDRoyaltyPercentage'
    ///         only callable by 'owner'
    function setRoyaltyInfo(
        address payable _royaltyAddress,
        uint256 _royaltyPercentage
    ) external onlyOwner {
        require(_royaltyPercentage < MAX_PERCENTAGE, "ND: percentage too high");

        NDRoyaltyAddress = _royaltyAddress;
        NDRoyaltyPercentage = uint96(_royaltyPercentage);
    }

    /// @notice sets 'transactions['transactionId']' to '_txInfo'
    ///         only callable by 'owner'
    function setTransactionDetails(
        uint256 transactionId,
        Transaction calldata _txInfo
    ) external onlyOwner {
        transactions[transactionId] = _txInfo;
    }

    /// @notice sets 'minExpiry' and 'maxExpiry
    ///         only callable by 'owner'
    function setExpiries(
        uint48 newMinExpiry,
        uint48 newMaxExpiry
    ) external onlyOwner {
        minExpiry = newMinExpiry;
        maxExpiry = newMaxExpiry;
    }

    /// @notice sets 'BuyingDisabled' to true
    ///         only callable by 'owner'
    function disableBuying() external onlyOwner {
        buyingDisabled = true;
        emit BuyingDisabled();
    }
}