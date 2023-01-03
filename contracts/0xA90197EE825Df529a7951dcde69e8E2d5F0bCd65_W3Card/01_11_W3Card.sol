// SPDX-License-Identifier: MIT
// Name:                    W3Card Solidity Smart Contract
// Description:             An easy and unique way for you to send your friends & family a
//                          personalized greeting card that lasts forever in their wallet.
// Version:                 0.1.7
// Creator:                 Forever Frens LLC.
// Website:                 https://foreverfrens.io/

pragma solidity ^0.8.9;

import "../token/ERC721A/extensions/ERC721AURIStorage.sol";
import "../access/Ownable.sol";
import "../security/ReentrancyGuard.sol";

contract W3Card is ERC721AURIStorage, Ownable, ReentrancyGuard {    
    // URI pointing to the contract's metadata
    string private uri;

    // Address pointing to the memberships contract
    address private memberships;

    // A type for defining a delivery
    struct Delivery {
        address to;
        uint sentDate;
        uint transferDate;
        uint transferAmount;
        uint quantity;
        bool isDonation;
        bool redeemed;
    }
    // Mapping from sender address to their deliveries
    mapping(address => Delivery[]) private deliveries;

    // A blacklist of addresses
    mapping(address => bool) private _blacklist;

    // A mapping of all card tiers by name to their price
    mapping(string => uint) cardPrices;

    // A mapping of all stamp tiers by name to their price
    mapping(string => uint) stampPrices;

    modifier mintCompliance(uint quantity, uint transferDate) {
        require(!_blacklist[msg.sender], "W3Card: you are blacklisted and cannot mint");
        require(quantity >= 1, "W3Card: quantity must be at least 1");
        require(transferDate == 0 || transferDate > block.timestamp, "W3Card: we haven't quite figured out time travel yet");
        _;
    }

    function initialize() initializer public {
        __ERC721AURIStorage_init("W3Card", "FRVR");
        __Ownable_init();
        __ReentrancyGuard_init();
        uri = "https://foreverfrens.com/api/v1/tokens/";
        
        memberships = address(0);

        cardPrices["FREE"] = 0;
        cardPrices["STANDARD"] = 5000000000000000;
        cardPrices["MISSION"] = 0;
        cardPrices["PREMIUM"] = 10000000000000000;

        stampPrices["FREE"] = 0;
        stampPrices["CHARITY"] = 0;
        stampPrices["GIFT"] = 1000000000000000;
     }

    /**
     * @dev A convenient function for the owner to withdraw a
     * certain amount of ether from this contract.
     */
    function withdraw(uint amount) public onlyOwner nonReentrant {
        require(address(this).balance > 0, "W3Card: the balance is currently 0");
        require(amount <= address(this).balance, "W3Card: cannot withdraw more than the balance");

        (bool success,) = owner().call{value: amount}("");
        require(success, "W3Card: something went wrong while withdrawing");
    }

    /**
     * @dev See {ERC721A-_baseURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    /**
     * @dev Get the base URI for the metadata.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev Set a new base URI for the metadata. Only the owner has access to this function
     * @param uri_ The new base URI to be set
     */
    function setBaseURI(string memory uri_) public onlyOwner nonReentrant {
        uri = uri_;
    }

    /**
     * @dev Blacklist a user from minting cards. Only accessible to owner.
     * @param user The address of the user
     */
    function blacklist(address user) public onlyOwner nonReentrant {
        _blacklist[user] = true;
    }

    /**
     * @dev Unblacklist a user from minting cards. Only accessible to owner.
     * @param user The address of the user
     */
    function unblacklist(address user) public onlyOwner nonReentrant {
        _blacklist[user] = false;
    }

    /**
     * @dev Get whether the user address provided is blacklisted or not. Only accessible to owner.
     */
    function isBlacklisted(address user) public onlyOwner nonReentrant returns (bool) {
        return _blacklist[user];
    }

    /**
     * @dev Get all deliveries by a sender.
     * @param sender The address of the sender
     */
    function deliveriesBySender(address sender) public view returns (Delivery[] memory) {
        return deliveries[sender];
    }

    /**
     * @dev Get the card price for all cards.
     */
    function cardPrice(string memory tier) public view returns (uint) {
        return cardPrices[tier];
    }

    /**
     * @dev Set the card price for all cards. Only accessible to owner.
     * @param price The new price of the cards
     */
    function setCardPrice(string memory tier, uint price) public onlyOwner nonReentrant {
        cardPrices[tier] = price;
    }

    /**
     * @dev Get the stamp price for all stamps.
     */
    function stampPrice(string memory tier) public view returns (uint) {
        return stampPrices[tier];
    }

    /**
     * @dev Set the stamp price for all stamps. Only accessible to owner.
     * @param price The new price of the stamps
     */
    function setStampPrice(string memory tier, uint price) public onlyOwner nonReentrant {
        stampPrices[tier] = price;
    }

    /**
     * @dev Mint an asset to this contract. Returns the tokenId.
     * @param to The address of the receiver
     * @param quantity The number of cards to mint
     * @param cardTier The tier of which the card price is determined
     * @param stampTier The tier of which the stamp price is determined
     * @param transferAmount The amount of ether to send to recipient/charity
     * @param transferDate Unix timestamp (seconds) to send the transferAmount
     * @param isDonation Whether this is a donation or not
     */
    function mint(address to, uint quantity, string memory cardTier, string memory stampTier, uint transferAmount, uint transferDate, bool isDonation) public virtual payable mintCompliance(quantity, transferDate) returns (uint) {
        require(msg.value == (cardPrices[cardTier] + stampPrices[stampTier] + transferAmount) * quantity, "W3Card: insufficient funds");

        // Ensure the gift isn't sent twice
        bool redeemed = false;

        // Transfer transferAmount to receiver
        if (transferAmount > 0 && transferDate == 0 && !isDonation) {
            (bool transferToRecipientSuccessful,) = payable(to).call{value: transferAmount * quantity}("");
            require(transferToRecipientSuccessful, "W3Card: something went wrong while sending your gift to the recipient");
            redeemed = true;
        }

        // Set deliveries for sender
        deliveries[msg.sender].push(Delivery(to, block.timestamp, transferDate, transferAmount, quantity, isDonation, redeemed));

        _safeMint(to, quantity);
        return _nextTokenId() - 1;
    }

     /**
      * @dev Send a gift of ETH to anyone on the blockchain.
      * @param to The address of the person you sent a card to
      * @param index The index of the delivery that was sent
      */
    function sendEthGift(uint index, address to) public onlyOwner nonReentrant {
        require(deliveries[msg.sender].length >= index, "W3Card: index out of bounds");

        Delivery memory senderDelivery = deliveries[msg.sender][index];

        require(senderDelivery.to == to, "W3Card: no delivery was sent to this person");
        require(senderDelivery.transferDate >= block.timestamp, "W3Card: deliveries cannot be sent before their set dates");
        require(!senderDelivery.redeemed, "W3Card: this delivery was already sent");

        // Transfer gift amount
        (bool success,) = payable(to).call{value: senderDelivery.transferAmount * senderDelivery.quantity}("");
        require(success, "W3Card: something went wrong while sending your gift");

        // Make sure redeemed is set to true
        deliveries[msg.sender][index].redeemed = true;
    }
}