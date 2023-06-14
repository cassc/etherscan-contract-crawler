// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {PageToken} from "src/PageToken.sol";
import {FrontPageERC721} from "src/FrontPageERC721.sol";

contract FrontPage is PageToken {
    using SafeTransferLib for address payable;

    struct Listing {
        // Seller address
        address payable seller;
        // Adequate for 79m ether
        uint96 price;
    }

    // NFT collection deployed by this contract
    FrontPageERC721 public immutable collection;

    // NFT creator, has permission to update the NFT collection and receive funds
    address payable public immutable creator;

    // Maximum NFT supply
    uint256 public immutable maxSupply;

    // NFT mint price
    uint256 public immutable mintPrice;

    // Non-reentrancy lock
    uint256 private _locked = 1;

    // Next NFT ID to be minted
    uint256 public nextId = 1;

    mapping(uint256 => Listing) public listings;

    mapping(address => mapping(uint256 => uint256)) public offers;

    event Mint();
    event List(uint256 id);
    event Edit(uint256 id);
    event Cancel(uint256 id);
    event Buy(uint256 id);
    event BatchMint();
    event BatchList(uint256[] ids);
    event BatchEdit(uint256[] ids);
    event BatchCancel(uint256[] ids);
    event BatchBuy(uint256[] ids);
    event MakeOffer(address maker);
    event CancelOffer(address maker);
    event TakeOffer(address taker);

    error Zero();
    error Soldout();
    error InvalidMsgValue();
    error Unauthorized();
    error Invalid();
    error MulticallError(uint256 callIndex);

    constructor(
        string memory _name,
        string memory _symbol,
        address payable _creator,
        uint256 _maxSupply,
        uint256 _mintPrice
    ) payable {
        if (_creator == address(0)) revert Zero();
        if (_maxSupply == 0) revert Zero();

        // Deploy the associated NFT collection
        collection = new FrontPageERC721(_name, _symbol, _creator, _maxSupply);

        creator = _creator;
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
    }

    modifier nonReentrant() {
        require(_locked == 1, "REENTRANCY");

        _locked = 2;

        _;

        _locked = 1;
    }

    function name() external view override returns (string memory) {
        return collection.name();
    }

    function symbol() external view override returns (string memory) {
        return collection.symbol();
    }

    function tokenURI(
        uint256 _tokenId
    ) external view override returns (string memory) {
        return collection.tokenURI(_tokenId);
    }

    /**
     * @notice Withdraw mint proceeds to the designated recipient (i.e. creator)
     */
    function withdraw() external payable {
        creator.safeTransferETH(address(this).balance);
    }

    /**
     * @notice Mint the FrontPage token representing the redeemable NFT
     */
    function mint() external payable {
        uint256 _nextId = nextId;

        // Revert if the max NFT supply has already been minted
        if (_nextId > maxSupply) revert Soldout();

        // Revert if the value sent does not equal the mint price
        if (msg.value != mintPrice) revert InvalidMsgValue();

        // Set the owner of the token ID to the minter
        ownerOf[_nextId] = msg.sender;

        // Will not overflow since nextId is less than or equal to maxSupply
        unchecked {
            // Increment nextId to the next NFT ID to be minted
            ++nextId;
        }

        emit Mint();
    }

    /**
     * @notice Mint multiple FrontPage tokens representing the redeemable NFTs
     * @param  quantity  uint256  Number of FPTs to mint
     */
    function batchMint(uint256 quantity) external payable {
        // Revert if the value sent does not equal the mint price
        if (msg.value != mintPrice * quantity) revert InvalidMsgValue();

        unchecked {
            // Update nextId to reflect the additional tokens to be minted
            // Virtually impossible to overflow due to the msg.value check above
            uint256 _nextId = (nextId += quantity);

            // Revert if the max NFT supply has been or will be exceeded post-mint
            if (_nextId > maxSupply) revert Soldout();

            // If quantity is zero, the loop logic will never be executed
            for (uint256 i = quantity; i > 0; --i) {
                // Set the owner of the token ID to the minter
                ownerOf[_nextId - i] = msg.sender;
            }
        }

        emit BatchMint();
    }

    /**
     * @notice Redeem the FrontPage token for the underlying NFT
     * @param  id  uint256  FrontPage token ID
     */
    function redeem(uint256 id) external {
        if (ownerOf[id] != msg.sender) revert Unauthorized();

        // Burn the token to prevent the double-spending
        delete ownerOf[id];

        // Mint the NFT for msg.sender with the same ID as the FrontPage token
        collection.mint(msg.sender, id);
    }

    /**
     * @notice Redeem the FrontPage tokens for the underlying NFTs
     * @param  ids  uint256[]  FrontPage token IDs
     */
    function batchRedeem(uint256[] calldata ids) external {
        uint256 id;
        uint256 idsLength = ids.length;

        for (uint256 i = 0; i < idsLength; ) {
            id = ids[i];

            if (ownerOf[id] != msg.sender) revert Unauthorized();

            // Burn the token to prevent the double-spending
            delete ownerOf[id];

            unchecked {
                ++i;
            }
        }

        // Mint the NFTs for msg.sender with the same IDs as the FrontPage tokens
        collection.batchMint(msg.sender, ids);
    }

    /**
     * @notice Create a listing
     * @param  id     uint256  Token ID
     * @param  price  uint96   Price
     */
    function _list(uint256 id, uint96 price) private {
        // Reverts if msg.sender does not have the token
        if (ownerOf[id] != msg.sender) revert Unauthorized();

        // Revert if the price is zero
        if (price == 0) revert Invalid();

        // Update token owner to this contract to prevent double-listing
        ownerOf[id] = address(this);

        // Set the listing
        listings[id] = Listing(payable(msg.sender), price);
    }

    /**
     * @notice Edit a listing
     * @param  id        uint256  Token ID
     * @param  newPrice  uint96   New price
     */
    function _edit(uint256 id, uint96 newPrice) private {
        // Revert if the new price is zero
        if (newPrice == 0) revert Invalid();

        Listing storage listing = listings[id];

        // Reverts if msg.sender is not the seller or listing does not exist
        if (listing.seller != msg.sender) revert Unauthorized();

        listing.price = newPrice;
    }

    /**
     * @notice Cancel a listing
     * @param  id  uint256  Token ID
     */
    function _cancel(uint256 id) private {
        // Reverts if msg.sender is not the seller
        if (listings[id].seller != msg.sender) revert Unauthorized();

        // Delete listing prior to returning the token
        delete listings[id];

        ownerOf[id] = msg.sender;
    }

    /**
     * @notice Create a listing
     * @param  id     uint256  Token ID
     * @param  price  uint96   Price
     */
    function list(uint256 id, uint96 price) external {
        _list(id, price);

        emit List(id);
    }

    /**
     * @notice Edit a listing
     * @param  id        uint256  Token ID
     * @param  newPrice  uint96   New price
     */
    function edit(uint256 id, uint96 newPrice) external {
        _edit(id, newPrice);

        emit Edit(id);
    }

    /**
     * @notice Cancel a listing
     * @param  id  uint256  Token ID
     */
    function cancel(uint256 id) external {
        _cancel(id);

        emit Cancel(id);
    }

    /**
     * @notice Fulfill a listing
     * @param  id  uint256  Token ID
     */
    function buy(uint256 id) external payable {
        Listing memory listing = listings[id];

        // Revert if the listing does not exist (price cannot be zero)
        if (listing.price == 0) revert Invalid();

        // Reverts if the msg.value does not cover the listing price
        if (msg.value != listing.price) revert InvalidMsgValue();

        // Delete listing prior to setting the token to the buyer
        delete listings[id];

        // Set the new token owner to the buyer
        ownerOf[id] = msg.sender;

        // Transfer the sales proceeds to the seller
        listing.seller.safeTransferETH(msg.value);

        emit Buy(id);
    }

    /**
     * @notice Create a batch of listings
     * @param  ids     uint256[]  Token IDs
     * @param  prices  uint96[]   Prices
     */
    function batchList(
        uint256[] calldata ids,
        uint96[] calldata prices
    ) external {
        uint256 idsLength = ids.length;

        for (uint256 i = 0; i < idsLength; ) {
            // Set each listing - reverts if the `prices` or `tips` arrays are
            // not equal in length to the `ids` array (indexOOB error)
            _list(ids[i], prices[i]);

            unchecked {
                ++i;
            }
        }

        emit BatchList(ids);
    }

    /**
     * @notice Edit a batch of listings
     * @param  ids        uint256[]  Token IDs
     * @param  newPrices  uint96[]   New prices
     */
    function batchEdit(
        uint256[] calldata ids,
        uint96[] calldata newPrices
    ) external {
        uint256 idsLength = ids.length;

        for (uint256 i = 0; i < idsLength; ) {
            // Reverts with indexOOB if `newPrices`'s length is not equal to `ids`'s
            _edit(ids[i], newPrices[i]);

            unchecked {
                ++i;
            }
        }

        emit BatchEdit(ids);
    }

    /**
     * @notice Cancel a batch of listings
     * @param  ids  uint256[]  Token IDs
     */
    function batchCancel(uint256[] calldata ids) external {
        uint256 idsLength = ids.length;

        for (uint256 i = 0; i < idsLength; ) {
            _cancel(ids[i]);

            unchecked {
                ++i;
            }
        }

        emit BatchCancel(ids);
    }

    /**
     * @notice Fulfill a batch of listings
     * @param  ids  uint256[]  Token IDs
     */
    function batchBuy(uint256[] calldata ids) external payable nonReentrant {
        uint256 id;
        uint256 idsLength = ids.length;

        // Used for checking that msg.value is enough to cover the purchase price - buyer must send GTE the total ETH of all listings
        // Any leftover ETH is returned at the end *after* the listing sale prices have been deducted from `availableETH`
        uint256 availableETH = msg.value;

        for (uint256 i = 0; i < idsLength; ) {
            id = ids[i];

            // Increment iterator variable since we are conditionally skipping (i.e. listing does not exist)
            unchecked {
                ++i;
            }

            Listing memory listing = listings[id];

            // Continue to the next id if the listing does not exist (e.g. listing canceled or purchased before this call executes)
            if (listing.price == 0) continue;

            // Deduct the listing price from the available ETH sent by the buyer (reverts with arithmetic underflow if insufficient)
            availableETH -= listing.price;

            // Delete listing prior to setting the token to the buyer
            delete listings[id];

            // Set the new token owner to the buyer
            ownerOf[id] = msg.sender;

            // Transfer the sales proceeds to the seller - reverts if the contract does not have enough ETH due to msg.value
            // not being sufficient to cover the purchase. If the contract does have enough ETH - due to offer makers depositing
            // ETH (even if the caller did not include a sufficient amount) - then the post-loop check will revert
            listing.seller.safeTransferETH(listing.price);
        }

        // If there is available ETH remaining after the purchases (i.e. too much ETH was sent), return it to the buyer
        if (availableETH != 0) {
            payable(msg.sender).safeTransferETH(availableETH);
        }

        emit BatchBuy(ids);
    }

    /**
     * @notice Make/increase a global offer
     * @param  offer     uint256  Offer in ETH
     * @param  quantity  uint256  Offer quantity to make
     */
    function makeOffer(uint256 offer, uint256 quantity) external payable {
        // Reverts if msg.value does not equal the necessary amount
        // If msg.value, and offer and/or quantity are zero then the caller
        // wastes gas since their offer value will be zero (no one will take
        // the offer) or their quantity will not increase. Since this is the
        // assumption, we do not need to validate offer and quantity.
        if (msg.value != offer * quantity) revert Invalid();

        // Increase offer quantity
        // Cannot realistically overflow due to the msg.value check above
        // Even if it did overflow, the maker would be the one harmed (i.e.
        // ETH sent more than the offer quantity reflected in the contract),
        // making this an unlikely attack vector
        unchecked {
            offers[msg.sender][offer] += quantity;
        }

        emit MakeOffer(msg.sender);
    }

    /**
     * @notice Cancel/reduce a global offer
     * @param  offer     uint256  Offer in ETH
     * @param  quantity  uint256  Offer quantity to cancel
     */
    function cancelOffer(uint256 offer, uint256 quantity) external {
        // Deduct quantity from the user's offers - reverts if `quantity`
        // exceeds the actual amount of offers that the user has made
        // If offer and/or quantity are zero then the amount of ETH returned
        // will be zero (if no arithmetic underflow), resulting in gas wasted
        // (making this an unlikely attack vector)
        offers[msg.sender][offer] -= quantity;

        // Cannot realistically overflow if the above does not underflow
        // The reason being that the amount returned to the maker/msg.sender
        // is always less than or equal to the amount they've deposited
        unchecked {
            // Transfer the offer value back to the user
            payable(msg.sender).safeTransferETH(offer * quantity);
        }

        emit CancelOffer(msg.sender);
    }

    /**
     * @notice Take global offers
     * @param  ids    uint256[]  Token IDs exchanged between taker and maker
     * @param  maker  address    Maker address
     * @param  offer  uint256    Offer in ETH
     */
    function takeOffer(
        uint256[] calldata ids,
        address maker,
        uint256 offer
    ) external {
        // Reduce maker's offer quantity by the taken amount (i.e. token quantity)
        // Reverts if the taker quantity exceeds the maker offer quantity, if the maker
        // is the zero address, or if the offer is zero with arithmetic underflow err
        // If `ids.length` is 0, then the offer quantity will be deducted by zero, the
        // loop will not execute, and zero ETH will be sent to the taker, resulting in
        // the caller wasting gas and making this an infeasible attack vector
        uint256 idsLength = ids.length;
        offers[maker][offer] -= idsLength;

        uint256 id;

        for (uint256 i = 0; i < idsLength; ) {
            id = ids[i];

            // Revert if msg.sender/taker is not the owner of the derivative token
            if (ownerOf[id] != msg.sender) revert Unauthorized();

            // Set maker as the new owner of the token
            ownerOf[id] = maker;

            unchecked {
                ++i;
            }
        }

        // Will not overflow since the check above verifies that there was a
        // sufficient offer quantity (and ETH) to cover the transfer
        unchecked {
            // Send maker's funds to the offer taker
            payable(msg.sender).safeTransferETH(offer * idsLength);
        }

        emit TakeOffer(msg.sender);
    }

    /**
     * @notice Receives and executes a batch of function calls on this contract
     * @notice Non-payable to avoid reuse of msg.value across calls (thank you Solady)
     * @notice See: https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong
     * @param  data       bytes[]  Encoded function selectors with optional data
     */
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results) {
        uint256 dataLength = data.length;
        results = new bytes[](dataLength);

        for (uint256 i = 0; i < dataLength; ) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );

            if (!success) revert MulticallError(i);

            results[i] = result;

            unchecked {
                ++i;
            }
        }
    }
}