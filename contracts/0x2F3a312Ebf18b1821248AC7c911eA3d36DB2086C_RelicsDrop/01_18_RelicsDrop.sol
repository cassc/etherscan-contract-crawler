// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/Administration.sol";
import "../utils/Treasury.sol";
import "../utils/AllowList.sol";

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract RelicsDrop is ERC1155Receiver, AllowList, Administration, Treasury {
    address private _relicsContract;
    uint256 private _maxPerTxn = 25;

    struct Presale {
        // The start time of the presale
        uint32 startTime;
        // The end start time of the sale
        uint32 endTime;
        // The price per item purchased
        uint128 price;
        // The presale purchase limit
        uint64 limit;
        // A unique non-reusable id
        bytes32 nonce;
    }

    struct Sale {
        // The quantity for the sale
        uint128 quantity;
        // The quantity minted
        uint128 minted;
        // The time when the sale is active
        uint32 activeFrom;
        // The start time of the public sale
        uint32 startTime;
        // The end time of the sale
        uint32 endTime;
        // The price per item purchased
        uint96 price;
        // The number of tickets pre-sold
        uint24 tickets;
        // The number of tickets used
        uint24 redeemed;
        // The purchase limit
        uint8 limit;
        // If the sale is paused
        bool paused;
    }

    struct Ticket {
        uint256 tokenId;
        uint256 saleId;
    }

    mapping(uint256 => Sale) private _sales;
    mapping(address => Ticket) private _tickets;
    mapping(bytes32 => bool) private _participated;
    mapping(address => mapping(uint256 => uint256)) private _mints;

    constructor(address relicsContract, address treasuryAddress) Administration(treasuryAddress) {
        _relicsContract = relicsContract;
        _treasury = treasuryAddress;
    }

    function hasParticipatedInPresale(bytes32 nonce) public view returns (bool participated) {
        participated = _participated[nonce];
    }

    function getMaxPerTransaction() public view returns (uint256 max) {
        max = _maxPerTxn;
    }

    function getDrop(uint256 id) public view returns (Sale memory sale) {
        sale = _sales[id];
    }

    function getAllowList(uint256 id) public view returns (AllowListData memory allowlist) {
        allowlist = _returnAllowList(bytes32(id));
    }

    function getTicket(address ticketAddress) public view returns (Ticket memory ticket) {
        ticket = _tickets[ticketAddress];
    }

    function getAvailable(uint256 id)
        public
        view
        returns (
            uint256 total,
            uint256 tickets,
            uint256 purchasable
        )
    {
        Sale memory sale = _sales[id];

        unchecked {
            total = maxSupply(id) - totalMinted(id);
            tickets = sale.tickets - sale.redeemed;
            purchasable = total - tickets;
        }
    }

    function allowListStatus(
        uint256 id,
        address from,
        Presale calldata presale,
        bytes32[] calldata merkleProof
    ) public view returns (bool allowed, bool participated) {
        participated = _participated[presale.nonce];
        allowed = verifyProof(bytes32(id), from, _hashPresaleData(presale), merkleProof);
    }

    function maxSupply(uint256 id) public view returns (uint256 supply) {
        supply = _sales[id].quantity;
    }

    function totalMinted(uint256 id) public view returns (uint256 minted) {
        minted = _sales[id].minted;
    }

    function ownerMinted(address owner, uint256 id) public view returns (uint256 minted) {
        minted = _mints[owner][id];
    }

    function setMaxPerTransaction(uint256 max) external isAdmin {
        _maxPerTxn = max;
    }

    function pauseSaleToggle(uint256 id) external isAdmin {
        Sale storage sale = _sales[id];
        sale.paused = !sale.paused;
    }

    function createDrop(
        uint256 id,
        uint32 activeFrom,
        uint32 startTime,
        uint32 endTime,
        uint64 quantity,
        uint96 price,
        uint8 limit,
        uint8 premint,
        string calldata proof
    ) external isAdmin {
        Sale storage _sale = _sales[id];

        if (_sale.startTime != 0) revert DropExists();
        if (startTime > endTime) revert InvalidDropConfig();

        (uint256 startIndex, uint256 endIndex) = IRelic721(_relicsContract).registerRange(id, quantity, proof);
        if (startIndex == 0 || endIndex == 0) revert InvalidDropConfig();

        _sale.quantity = quantity;
        _sale.activeFrom = activeFrom;
        _sale.startTime = startTime;
        _sale.endTime = endTime;
        _sale.price = price;
        _sale.limit = limit;

        if (premint > 0) {
            IRelic721(_relicsContract).mintRange(id, getTreasuryAddress(), premint);
        }
    }

    function updateDrop(
        uint256 id,
        uint32 activeFrom,
        uint32 startTime,
        uint32 endTime,
        uint96 price,
        uint8 limit
    ) external isAdmin {
        Sale storage _sale = _sales[id];

        // Note: Quantity cannot be updated
        // The drop must exist to be updated
        if (_sale.startTime == 0) revert DropDoesNotExist();
        if (startTime > endTime) revert InvalidDropConfig();

        _sale.activeFrom = activeFrom;
        _sale.startTime = startTime;
        _sale.endTime = endTime;
        _sale.price = price;
        _sale.limit = limit;
    }

    function updateDropAllowList(uint256 id, AllowListData calldata allowListData) external isAdmin {
        Sale memory _sale = _sales[id];

        // verify the drop exists
        if (_sale.quantity == 0) revert InvalidDropConfig();

        _updateAllowList(bytes32(id), allowListData);
    }

    function updateDropTicket(
        uint256 id,
        uint24 tickets,
        address ticketAddress,
        uint256 tokenId
    ) external isAdmin {
        Sale storage _sale = _sales[id];
        Ticket storage _ticket = _tickets[ticketAddress];

        if (tickets > _sale.quantity) revert InvalidDropConfig();

        _sale.tickets = tickets;
        _ticket.saleId = id;
        _ticket.tokenId = tokenId;
    }

    function presaleMint(
        uint256 id,
        uint128 quantity,
        Presale calldata presale,
        bytes32[] calldata merkleProof
    ) external payable whenNotPaused {
        Sale storage sale = _sales[id];
        uint256 userMints = _mints[_msgSender()][id];

        // verify the drop exists
        if (sale.quantity == 0) revert InvalidDropConfig();

        // Use the presale price vs the public price
        uint256 price = presale.price;

        // Verify the presale is open for requset
        _verifyIsActive(presale.startTime, presale.endTime, sale.paused);

        // Verify the transaction value is valid
        _verifyPayment(quantity, price);

        // Verify the presale data and mark nonce as used
        _verifyPresale(quantity, presale);

        // Verify the request against the allow list
        _verifyProofOrRevert(bytes32(id), _msgSender(), _hashPresaleData(presale), merkleProof);

        // Verify amount allowed to mint vs previously minted
        _verifyQuantity(quantity, sale.quantity, sale.minted, sale.tickets);

        // Verify the new quantity does not exceed mint limit
        _verifyUserLimit(userMints, quantity, sale.limit);

        // Add mint quantity to drop next index
        unchecked {
            _mints[_msgSender()][id] = userMints + quantity;
            sale.minted += quantity;
        }

        // Mint
        IRelic721(_relicsContract).mintRange(id, _msgSender(), quantity);
    }

    function publicMint(uint256 id, uint128 quantity) external payable whenNotPaused {
        Sale storage sale = _sales[id];

        uint256 price = sale.price;
        uint256 userMints = _mints[_msgSender()][id];

        // Verify the sale is open
        _verifyIsActive(sale.startTime, sale.endTime, sale.paused);

        // Verify the transaction value is valid
        _verifyPayment(quantity, price);

        // Verify amount allowed to mint vs previously minted
        _verifyQuantity(quantity, sale.quantity, sale.minted, sale.tickets);

        // Verify the new quantity does not exceed mint limit
        _verifyUserLimit(userMints, quantity, sale.limit);

        // Add mint quantity to drop next index
        // Add mint quntity to user mints
        unchecked {
            _mints[_msgSender()][id] = userMints + quantity;
            sale.minted += quantity;
        }

        // Mint
        IRelic721(_relicsContract).mintRange(id, _msgSender(), quantity);
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) public virtual whenNotPaused returns (bytes4) {
        address tokenAddress = msg.sender;

        Ticket memory ticket = _tickets[tokenAddress];
        Sale storage sale = _sales[ticket.saleId];

        // Verify the sale is active
        _verifyIsActive(sale.activeFrom, sale.endTime, sale.paused);

        // Verify amount allowed to mint vs previously minted
        // Note: Only 1 relic can be minted when an ERC721 is received
        // Note: Set the tickets to zero to ensure the pre-sold ticket can be redeemed
        _verifyQuantity(1, sale.quantity, sale.minted, 0);

        // Verify tickets remain and increment redeemed
        _verifyTicketsRedeemed(sale, 1);

        // Burn the NFTs received
        IRelic721(msg.sender).burn(tokenId);

        // Increment the drop mint quantity
        unchecked {
            sale.minted += 1;
        }

        // Mint the relics
        // Only 1 relic can be minted when an ERC721 is received
        IRelic721(_relicsContract).mintRange(ticket.saleId, from, 1);

        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes memory
    ) public override whenNotPaused returns (bytes4) {
        address tokenAddress = msg.sender;

        Ticket memory ticket = _tickets[tokenAddress];
        Sale storage sale = _sales[ticket.saleId];

        // Verify correct ticket is being redeemed
        if (id != ticket.tokenId) revert InvalidTicket(id, ticket.tokenId);

        // Verify the sale is active
        _verifyIsActive(sale.activeFrom, sale.endTime, sale.paused);

        // Verify amount allowed to mint vs previously minted
        // Note: Set the tickets to zero to ensure the pre-sold ticket can be redeemed
        _verifyQuantity(1, sale.quantity, sale.minted, 0);

        // Verify tickets remain and increment redeemed
        // We can assume value < max uint24 integer
        _verifyTicketsRedeemed(sale, uint24(value));

        // Burn the NFTs received
        IERC1155Burn(msg.sender).burn(address(this), id, value);

        // Add mint quantity to drop next index
        unchecked {
            sale.minted += uint128(value);
        }

        // Mint the relics
        IRelic721(_relicsContract).mintRange(ticket.saleId, from, value);

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory id,
        uint256[] memory value,
        bytes memory
    ) public override whenNotPaused returns (bytes4) {
        for (uint256 i = 0; i < id.length; ) {
            onERC1155Received(operator, from, id[i], value[i], "");

            unchecked {
                i++;
            }
        }

        return this.onERC1155BatchReceived.selector;
    }

    function _hashPresaleData(Presale memory presale) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                keccak256(
                    abi.encodePacked(presale.startTime, presale.endTime, presale.price, presale.limit, presale.nonce)
                )
            );
    }

    function _verifyPresale(uint256 quantity, Presale calldata presale) internal {
        // Verify quantity is not more than allowed
        if (quantity > presale.limit) revert InvalidQuantity(quantity, presale.limit);

        // Verify nonce has not been used
        if (_participated[presale.nonce] == true) revert AlreadyParticipated();

        // Prevent the nonce from being used again
        _participated[presale.nonce] = true;
    }

    function _verifyTicketsRedeemed(Sale storage sale, uint24 value) internal {
        unchecked {
            uint24 redeemed = sale.redeemed + value;
            if (redeemed > sale.tickets) revert TicketQuantityExceeded(sale.tickets);
            sale.redeemed = redeemed;
        }
    }

    function _verifyIsActive(
        uint32 startTime,
        uint32 endTime,
        bool paused
    ) internal view {
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);

        if (paused) {
            revert NotActive(blockTimestamp, startTime, endTime, true);
        }

        if (blockTimestamp < startTime || blockTimestamp > endTime) {
            // Revert if not active
            revert NotActive(blockTimestamp, startTime, endTime, false);
        }
    }

    function _verifyPayment(uint256 quantity, uint256 mintPrice) internal view {
        unchecked {
            if (msg.value != quantity * mintPrice) {
                revert InvalidPayment(msg.value, quantity * mintPrice);
            }
        }
    }

    function _verifyQuantity(
        uint256 quantity,
        uint256 supply,
        uint256 minted,
        uint256 tickets
    ) internal view {
        if (quantity > _maxPerTxn) {
            revert InvalidQuantity(quantity, _maxPerTxn);
        }

        // Calculate max supply and optionally remove tickets
        // Tickets are pre-sales and cannot be sold during a public sale
        unchecked {
            uint256 newSupply = (minted + quantity + tickets);

            if (newSupply > supply) {
                revert RequestExceedsMaxSupply(quantity, minted, supply);
            }
        }
    }

    function _verifyUserLimit(
        uint256 minted,
        uint256 requested,
        uint256 limit
    ) internal pure {
        unchecked {
            uint256 total = minted + requested;
            if (total > limit) {
                revert InvalidQuantity(total, limit);
            }
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Administration, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {}

    //////////////  ERRORS  //////////////
    error NotActive(uint32 currentTimestamp, uint32 startTimestamp, uint32 endTimestamp, bool paused);

    error InvalidPayment(uint256 received, uint256 required);
    error InvalidQuantity(uint256 requested, uint256 max);
    error RequestExceedsMaxSupply(uint256 requested, uint256 current, uint256 max);

    error InvalidTicketQuantity(uint256 requested, uint256 owned);
    error InvalidTicket(uint256 received, uint256 required);
    error TicketQuantityExceeded(uint256 tickets);
    error TicketApprovalRequired();

    error AlreadyParticipated();

    error InvalidDropConfig();
    error DropDoesNotExist();
    error DropExists();
    /////////////////////////////////////
}

interface IRelic721 {
    function burn(uint256 tokenId) external;

    function mint(address to, uint256 tokenId) external;

    function mintRange(
        uint256 range,
        address to,
        uint256 quantity
    ) external;

    function registerRange(
        uint256 range,
        uint64 quantity,
        string calldata proof
    ) external returns (uint64, uint64);
}

interface IERC1155Burn {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}