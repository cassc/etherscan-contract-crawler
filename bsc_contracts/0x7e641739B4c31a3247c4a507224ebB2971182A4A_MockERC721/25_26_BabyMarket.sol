// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import '../interfaces/IWETH.sol';
import '../interfaces/IMintable.sol';
import '@openzeppelin/contracts/access/Ownable2Step.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

contract BabyMarket is IERC721Receiver, IERC1155Receiver, ReentrancyGuard, Ownable2Step, Pausable {
    using SafeERC20 for IERC20;

    uint8 public constant KIND_SELL = 1;
    uint8 public constant KIND_BUY = 2;
    uint8 public constant KIND_AUCTION = 3;

    uint8 public constant STATUS_OPEN = 0;
    uint8 public constant STATUS_DONE = 1;
    uint8 public constant STATUS_CANCELLED = 2;

    uint8 public constant OP_MIN = 0; // invalid, for checks only
    uint8 public constant OP_COMPLETE_SELL = 1; // complete sell (off-chain)
    uint8 public constant OP_COMPLETE_BUY = 2; // complete buy (off-chain)
    uint8 public constant OP_BUY = 3; // create KIND_BUY
    uint8 public constant OP_ACCEPT_BUY = 4; // complete KIND_BUY
    uint8 public constant OP_CANCEL_BUY = 5; // cancel KIND_BUY
    uint8 public constant OP_REJECT_BUY = 6; // reject KIND_BUY
    uint8 public constant OP_BID = 7; // bid (create or update KIND_AUCTION)
    uint8 public constant OP_COMPLETE_AUCTION = 8; // complete auction (by anyone)
    uint8 public constant OP_ACCEPT_AUCTION = 9; // accept auction in an early stage (by seller)
    uint8 public constant OP_MAX = 10;

    uint8 public constant TOKEN_MINT = 0; // mint token (do anything)
    uint8 public constant TOKEN_721 = 1; // 721 token
    uint8 public constant TOKEN_1155 = 2; // 1155 token

    uint256 public constant RATE_BASE = 1e6;

    struct Pair721 {
        // swap only
        IERC721 token;
        uint256 tokenId;
    }

    struct TokenPair {
        address token; // token contract address
        uint256 tokenId; // token id (if applicable)
        uint256 amount; // token amount (if applicable)
        uint8 kind; // token kind (721/1151/mint)
        bytes mintData; // mint data (if applicable)
    }

    struct Inventory {
        address seller;
        address buyer;
        IERC20 currency;
        uint256 price; // display price
        uint256 netPrice; // actual price (auction: minus incentive)
        uint256 deadline; // deadline for the inventory
        uint8 kind;
        uint8 status;
    }

    struct Intention {
        address user;
        TokenPair[] bundle;
        IERC20 currency;
        uint256 price;
        uint256 deadline;
        bytes32 salt;
        uint8 kind;
    }

    struct Detail {
        bytes32 intentionHash;
        address signer;
        uint256 txDeadline; // deadline for the transaction
        bytes32 salt;
        uint256 id; // inventory id
        uint8 opcode; // OP_*
        address caller;
        IERC20 currency;
        uint256 price;
        uint256 incentiveRate;
        Settlement settlement;
        TokenPair[] bundle;
        uint256 deadline; // deadline for buy offer
    }

    struct Settlement {
        uint256[] coupons;
        uint256 feeRate;
        uint256 royaltyRate;
        uint256 buyerCashbackRate;
        address feeAddress;
        address royaltyAddress;
    }

    struct Swap {
        bytes32 salt;
        address creator;
        uint256 deadline;
        Pair721[] has;
        Pair721[] wants;
    }

    // events

    event EvCouponSpent(uint256 indexed id, uint256 indexed couponId);
    event EvInventoryUpdate(uint256 indexed id, Inventory inventory);
    event EvInventoryBundle(uint256 indexed id, TokenPair[] bundle);
    event EvAuctionRefund(uint256 indexed id, address bidder, uint256 refund);
    event EvSettingsUpdated();
    event EvMarketSignerUpdate(address addr, bool isRemoval);
    event EvSwapped(Swap req, bytes signature, address swapper);

    // vars

    IWETH public immutable weth;

    mapping(uint256 => Inventory) public inventories;
    mapping(uint256 => bool) public couponSpent;
    mapping(uint256 => mapping(uint256 => TokenPair)) public inventoryTokens;
    mapping(uint256 => uint256) public inventoryTokenCounts;
    mapping(address => bool) public marketSigners;

    // initialized with default value
    uint256 public minAuctionIncrement = (5 * RATE_BASE) / 100;
    uint256 public minAuctionDuration = 10 * 60;

    // internal vars
    bool internal _canReceive = false;
    bool internal _canSkipDetailSignerCheck = false;
    Settlement public _defaultSettlement;

    // constructor

    constructor(IWETH weth_) {
        weth = weth_;
    }

    function updateSettings(uint256 minAuctionIncrement_, uint256 minAuctionDuration_)
        public
        onlyOwner
    {
        minAuctionDuration = minAuctionDuration_;
        minAuctionIncrement = minAuctionIncrement_;
        emit EvSettingsUpdated();
    }

    function updateCanSkipDetailSignerCheck(bool _value) external onlyOwner {
        _canSkipDetailSignerCheck = _value;
    }

    function updateDefaultSettlement(Settlement memory _value) external onlyOwner {
        _defaultSettlement = _value; 
    }

    function updateSigner(address addr, bool remove) public onlyOwner {
        if (remove) {
            delete marketSigners[addr];
        } else {
            marketSigners[addr] = true;
        }
        emit EvMarketSignerUpdate(addr, remove);
    }

    // impls

    receive() external payable {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view override _onTransferOnly returns (bytes4) {
        (operator);
        (from);
        (tokenId);
        (data);
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external view override _onTransferOnly returns (bytes4) {
        (operator);
        (from);
        (id);
        (value);
        (data);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external view override _onTransferOnly returns (bytes4) {
        (operator);
        (from);
        (ids);
        (values);
        (data);
        return this.onERC1155BatchReceived.selector;
    }

    modifier _onTransferOnly() {
        require(_canReceive, 'ERR01');
        _;
    }

    modifier _allowTransfer() {
        _canReceive = true;
        _;
        _canReceive = false;
    }

    // public

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            (interfaceId == type(IERC721Receiver).interfaceId) ||
            (interfaceId == type(IERC1155Receiver).interfaceId);
    }

    function _checkDetailSignature(Detail memory detail, bytes calldata sigDetail) internal view {
        if (sigDetail.length == 0) {
            require(_canSkipDetailSignerCheck, "ERR02");
            require(detail.opcode == OP_BUY || detail.opcode == OP_ACCEPT_BUY || detail.opcode == OP_CANCEL_BUY, "ERR03");
            require(detail.caller == tx.origin, "ERR04");
            if (detail.opcode == OP_ACCEPT_BUY) {
                detail.settlement = _defaultSettlement;
            }
        } else {
            require(marketSigners[detail.signer], 'ERR05');
            require(
                isSignatureValid(sigDetail, keccak256(abi.encode(detail)), detail.signer),
                'ERR06'
            );
        }
    }

    function run(
        Intention calldata intent,
        Detail calldata detail,
        bytes calldata sigIntent,
        bytes calldata sigDetail
    ) public payable nonReentrant whenNotPaused {
        require(detail.txDeadline > block.timestamp, 'ERR07');
        _validateOpCode(detail.opcode);
        _checkDetailSignature(detail, sigDetail);

        if (hasSignedIntention(detail.opcode)) {
            bytes32 intentionHash = keccak256(abi.encode(intent));
            require(intentionHash == detail.intentionHash, 'ERR08');
            require(
                isSignatureValid(sigIntent, intentionHash, intent.user),
                'ERR09'
            );
        }

        if (detail.opcode == OP_COMPLETE_SELL) {
            _assertSender(detail.caller);
            require(intent.kind == KIND_SELL, 'ERR10');
            _newSellDeal(
                detail.id,
                intent.user,
                intent.bundle,
                intent.currency,
                intent.price,
                intent.deadline,
                detail.caller,
                detail.settlement
            );
        } else if (detail.opcode == OP_COMPLETE_BUY) {
            _assertSender(detail.caller);
            require(intent.kind == KIND_BUY, 'ERR11');
            _newBuyDeal(
                detail.id,
                intent.user, // buyer
                detail.caller, // seller
                intent.bundle,
                intent.currency,
                intent.price,
                intent.deadline,
                detail.settlement
            );
        } else if (detail.opcode == OP_BUY) {
            _assertSender(detail.caller);
            _newBuy(
                detail.id,
                detail.caller,
                detail.currency,
                detail.price,
                detail.bundle,
                detail.deadline
            );
            if (sigDetail.length == 0) {
                emit EvInventoryBundle(detail.id, detail.bundle);
            }
        } else if (detail.opcode == OP_ACCEPT_BUY) {
            _assertSender(detail.caller);
            _acceptBuy(detail.id, detail.caller, detail.settlement);
        } else if (detail.opcode == OP_CANCEL_BUY) {
            _cancelBuyAnyway(detail.id);
        } else if (detail.opcode == OP_REJECT_BUY) {
            _rejectBuy(detail.id);
        } else if (detail.opcode == OP_BID) {
            _assertSender(detail.caller);
            require(intent.kind == KIND_AUCTION, 'ERR12');
            _bid(
                detail.id,
                intent.user,
                intent.bundle,
                intent.currency,
                intent.price,
                intent.deadline,
                detail.caller,
                detail.price,
                detail.incentiveRate
            );
        } else if (detail.opcode == OP_COMPLETE_AUCTION) {
            _completeAuction(detail.id, detail.settlement);
        } else if (detail.opcode == OP_ACCEPT_AUCTION) {
            _assertSender(detail.caller);
            require(detail.caller == intent.user, 'ERR13');
            _acceptAuction(detail.id, detail.settlement);
        } else {
            revert('impossible');
        }
    }

    function cancelBuys(uint256[] calldata ids) public nonReentrant whenNotPaused {
        for (uint256 i = 0; i < ids.length; i++) {
            _cancelBuy(ids[i]);
        }
    }

    function inCaseMoneyGetsStuck(address to, IERC20 currency, uint256 amount) public onlyOwner {
        _transfer(currency, to, amount);
    }

    // emergency method for flaky contracts
    function emergencyCancelAuction(uint256 id, bool noBundle) public onlyOwner {
        require(isAuction(id), 'ERR14');
        require(isStatusOpen(id), 'ERR15');
        Inventory storage inv = inventories[id];

        if (!noBundle) {
            _transferBundle(id, address(this), inv.seller, false);
        }
        _transfer(inv.currency, inv.buyer, inv.netPrice);

        inv.status = STATUS_CANCELLED;
        emit EvInventoryUpdate(id, inv);
    }

    function swap(Swap memory req, bytes memory signature) public nonReentrant whenNotPaused {
        require(req.deadline > block.timestamp, 'ERR16');
        require(
            isSignatureValid(signature, keccak256(abi.encode(req)), req.creator),
            'ERR17'
        );

        for (uint256 i = 0; i < req.wants.length; i++) {
            req.wants[i].token.safeTransferFrom(msg.sender, req.creator, req.wants[i].tokenId);
        }

        for (uint256 i = 0; i < req.has.length; i++) {
            req.has[i].token.safeTransferFrom(req.creator, msg.sender, req.has[i].tokenId);
        }

        emit EvSwapped(req, signature, msg.sender);
    }

    function send(address to, Pair721[] memory tokens) public nonReentrant whenNotPaused {
        for (uint256 i = 0; i < tokens.length; i++) {
            Pair721 memory p = tokens[i];
            p.token.safeTransferFrom(msg.sender, to, p.tokenId);
        }
    }

    // internal

    function _assertSender(address sender) internal view {
        require(sender == msg.sender, 'ERR18');
    }

    function _validateOpCode(uint8 opCode) internal pure {
        require(opCode > OP_MIN && opCode < OP_MAX, 'ERR19');
    }

    function _saveBundle(uint256 invId, TokenPair[] calldata bundle) internal {
        require(bundle.length > 0, 'ERR20');
        inventoryTokenCounts[invId] = bundle.length;
        for (uint256 i = 0; i < bundle.length; i++) {
            inventoryTokens[invId][i] = bundle[i];
        }
    }

    // buyer create
    function _newBuy(
        uint256 id,
        address buyer,
        IERC20 currency,
        uint256 price,
        TokenPair[] calldata bundle,
        uint256 deadline
    ) internal {
        require(!hasInv(id), 'ERR21');
        require(deadline > block.timestamp, 'ERR22');
        _saveBundle(id, bundle);

        if (_isNative(currency)) {
            require(price == msg.value, 'ERR23');
            weth.deposit{value: price}(); // convert to erc20 (weth)
        } else {
            currency.safeTransferFrom(buyer, address(this), price);
        }

        inventories[id] = Inventory({
            seller: address(0),
            buyer: buyer,
            currency: currency,
            price: price,
            netPrice: price,
            kind: KIND_BUY,
            status: STATUS_OPEN,
            deadline: deadline
        });
        emit EvInventoryUpdate(id, inventories[id]);
    }

    // buyer cancel/expired
    function _cancelBuy(uint256 id) internal {
        Inventory storage inv = inventories[id];
        require(inv.buyer == msg.sender || isExpired(id), 'ERR24');
        _cancelBuyAnyway(id);
    }

    // cancel without checking caller
    function _cancelBuyAnyway(uint256 id) internal {
        require(isBuy(id) && isStatusOpen(id), 'ERR25');
        Inventory storage inv = inventories[id];

        inv.status = STATUS_CANCELLED;
        _transfer(inv.currency, inv.buyer, inv.netPrice);

        emit EvInventoryUpdate(id, inventories[id]);
    }

    function _rejectBuy(uint256 id) internal {
        address caller = msg.sender;
        require(isBuy(id) && isStatusOpen(id), 'ERR26');

        for (uint256 i = 0; i < inventoryTokenCounts[id]; i++) {
            TokenPair storage p = inventoryTokens[id][i];
            if (p.kind == TOKEN_721) {
                IERC721 t = IERC721(p.token);
                require(t.ownerOf(p.tokenId) == caller, 'ERR27');
            } else {
                revert('cannot reject non-721 token');
            }
        }

        _cancelBuyAnyway(id);
    }

    // seller call
    function _acceptBuy(
        uint256 id,
        address seller,
        Settlement calldata settlement
    ) internal {
        require(isBuy(id), 'ERR28');
        Inventory storage inv = inventories[id];
        require(isStatusOpen(id), 'ERR29');
        require(isBundleApproved(id, seller), 'ERR30');
        require(!isExpired(id), 'ERR31');

        inv.status = STATUS_DONE;
        inv.seller = seller;
        _transferBundle(id, seller, inv.buyer, true);

        emit EvInventoryUpdate(id, inventories[id]);
        _completeTransaction(id, settlement);
    }

    function _newBuyDeal(
        uint256 id,
        address buyer,
        address seller,
        TokenPair[] calldata bundle,
        IERC20 currency,
        uint256 price,
        uint256 deadline,
        Settlement calldata settlement
    ) internal {
        require(!hasInv(id), 'ERR32');
        require(deadline > block.timestamp, 'ERR33');
        require(!_isNative(currency), 'ERR34');

        _saveBundle(id, bundle);
        _transferBundle(id, seller, buyer, true);
        currency.safeTransferFrom(buyer, address(this), price);

        inventories[id] = Inventory({
            seller: seller,
            buyer: buyer,
            currency: currency,
            price: price,
            netPrice: price,
            kind: KIND_BUY,
            status: STATUS_DONE,
            deadline: deadline
        });
        emit EvInventoryUpdate(id, inventories[id]);

        _completeTransaction(id, settlement);
    }

    // new sell deal / new auction direct buy
    function _newSellDeal(
        uint256 id,
        address seller,
        TokenPair[] calldata bundle,
        IERC20 currency,
        uint256 price,
        uint256 deadline,
        address buyer,
        Settlement calldata settlement
    ) internal {
        require(!hasInv(id), 'ERR35');
        require(deadline > block.timestamp, 'ERR36');

        _saveBundle(id, bundle);
        _transferBundle(id, seller, buyer, true);

        if (_isNative(currency)) {
            require(price == msg.value, 'ERR37');
            weth.deposit{value: price}(); // convert to erc20 (weth)
        } else {
            currency.safeTransferFrom(buyer, address(this), price);
        }

        inventories[id] = Inventory({
            seller: seller,
            buyer: buyer,
            currency: currency,
            price: price,
            netPrice: price,
            kind: KIND_SELL,
            status: STATUS_DONE,
            deadline: deadline
        });
        emit EvInventoryUpdate(id, inventories[id]);

        _completeTransaction(id, settlement);
    }

    function _bid(
        uint256 id,
        address seller,
        TokenPair[] calldata bundle,
        IERC20 currency,
        uint256 startPrice,
        uint256 deadline,
        address buyer,
        uint256 price,
        uint256 incentiveRate
    ) internal _allowTransfer {
        require(incentiveRate < RATE_BASE, 'ERR38');

        if (_isNative(currency)) {
            require(price == msg.value, 'ERR39');
            weth.deposit{value: price}(); // convert to erc20 (weth)
        } else {
            currency.safeTransferFrom(buyer, address(this), price);
        }

        if (isAuction(id)) {
            Inventory storage auc = inventories[id];
            require(auc.seller == seller, 'ERR40'); // TODO check more
            require(auc.status == STATUS_OPEN, 'ERR41');
            require(auc.deadline > block.timestamp, 'ERR42');

            require(
                price >= auc.price + ((auc.price * minAuctionIncrement) / RATE_BASE),
                'ERR43'
            );

            uint256 incentive = (price * incentiveRate) / RATE_BASE;
            _transfer(currency, auc.buyer, auc.netPrice + incentive);
            emit EvAuctionRefund(id, auc.buyer, auc.netPrice + incentive);

            auc.buyer = buyer;
            auc.price = price;
            auc.netPrice = price - incentive;

            if (block.timestamp + minAuctionDuration >= auc.deadline) {
                auc.deadline += minAuctionDuration;
            }
        } else {
            require(!hasInv(id), 'ERR44');
            require(price >= startPrice, 'ERR45');
            require(deadline > block.timestamp, 'ERR46');

            uint256 deadline0 = deadline;
            if (block.timestamp + minAuctionDuration >= deadline) {
                deadline0 += minAuctionDuration;
            }

            inventories[id] = Inventory({
                seller: seller,
                buyer: buyer,
                currency: currency,
                price: price,
                netPrice: price,
                deadline: deadline0,
                status: STATUS_OPEN,
                kind: KIND_AUCTION
            });
            _saveBundle(id, bundle);
            _transferBundle(id, seller, address(this), false);
        }
        emit EvInventoryUpdate(id, inventories[id]);
    }

    function _completeAuction(uint256 id, Settlement calldata settlement) internal {
        require(inventories[id].deadline < block.timestamp, 'ERR47');
        _acceptAuction(id, settlement);
    }

    function _acceptAuction(uint256 id, Settlement calldata settlement) internal {
        require(isAuction(id), 'ERR48');
        require(isStatusOpen(id), 'ERR49');
        Inventory storage auc = inventories[id];

        auc.status = STATUS_DONE;
        emit EvInventoryUpdate(id, inventories[id]);
        _transferBundle(id, address(this), auc.buyer, true);
        _completeTransaction(id, settlement);
    }

    function _completeTransaction(uint256 id, Settlement calldata settlement) internal {
        Inventory storage inv = inventories[id];
        require(hasInv(id) && inv.status == STATUS_DONE, 'ERR50'); // sanity

        _markCoupon(id, settlement.coupons);

        uint256 price = inv.price;
        uint256 fee = (price * settlement.feeRate) / RATE_BASE;
        uint256 royalty = (price * settlement.royaltyRate) / RATE_BASE;
        uint256 buyerAmount = (price * settlement.buyerCashbackRate) / RATE_BASE;
        uint256 sellerAmount = inv.netPrice - fee - royalty - buyerAmount;

        _transfer(inv.currency, inv.seller, sellerAmount);
        _transfer(inv.currency, inv.buyer, buyerAmount);
        _transfer(inv.currency, settlement.feeAddress, fee);
        _transfer(inv.currency, settlement.royaltyAddress, royalty);
    }

    function _markCoupon(uint256 invId, uint256[] calldata coupons) internal {
        for (uint256 i = 0; i < coupons.length; i++) {
            uint256 id = coupons[i];
            require(!couponSpent[id], 'ERR51');
            couponSpent[id] = true;
            emit EvCouponSpent(invId, id);
        }
    }

    function _isNative(IERC20 currency) internal pure returns (bool) {
        return address(currency) == address(0);
    }

    function _transfer(
        IERC20 currency,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }
        require(to != address(0), 'ERR52');
        if (_isNative(currency)) {
            weth.withdraw(amount);
            payable(to).transfer(amount);
        } else {
            currency.safeTransfer(to, amount);
        }
    }

    function _transferBundle(
        uint256 invId,
        address from,
        address to,
        bool doMint
    ) internal {
        uint256 tokenCount = inventoryTokenCounts[invId];
        for (uint256 i = 0; i < tokenCount; i++) {
            TokenPair storage p = inventoryTokens[invId][i];
            if (p.kind == TOKEN_MINT) {
                if (doMint) {
                    // sanity check
                    require(
                        to != address(0) && to != address(this),
                        'ERR53'
                    );
                    IMintable(p.token).mint(to, p.mintData);
                }
            } else if (p.kind == TOKEN_721) {
                IERC721(p.token).safeTransferFrom(from, to, p.tokenId);
            } else if (p.kind == TOKEN_1155) {
                IERC1155(p.token).safeTransferFrom(from, to, p.tokenId, p.amount, '');
            } else {
                revert('unsupported token');
            }
        }
    }

    // public helpers

    // also checks the right owner
    function isBundleApproved(uint256 invId, address owner) public view returns (bool) {
        require(hasInv(invId), 'ERR54');

        for (uint256 i = 0; i < inventoryTokenCounts[invId]; i++) {
            TokenPair storage p = inventoryTokens[invId][i];
            if (p.kind == TOKEN_MINT) {
                // pass
            } else if (p.kind == TOKEN_721) {
                IERC721 t = IERC721(p.token);
                if (
                    t.ownerOf(p.tokenId) == owner &&
                    (t.getApproved(p.tokenId) == address(this) ||
                        t.isApprovedForAll(owner, address(this)))
                ) {
                    // pass
                } else {
                    return false;
                }
            } else if (p.kind == TOKEN_1155) {
                IERC1155 t = IERC1155(p.token);
                if (
                    t.balanceOf(owner, p.tokenId) >= p.amount &&
                    t.isApprovedForAll(owner, address(this))
                ) {
                    // pass
                } else {
                    return false;
                }
            } else {
                revert('unsupported token');
            }
        }
        return true;
    }

    function isAuctionOpen(uint256 id) public view returns (bool) {
        return
            isAuction(id) &&
            inventories[id].status == STATUS_OPEN &&
            inventories[id].deadline > block.timestamp;
    }

    function isBuyOpen(uint256 id) public view returns (bool) {
        return
            isBuy(id) &&
            inventories[id].status == STATUS_OPEN &&
            inventories[id].deadline > block.timestamp;
    }

    function isAuction(uint256 id) public view returns (bool) {
        return inventories[id].kind == KIND_AUCTION;
    }

    function isBuy(uint256 id) public view returns (bool) {
        return inventories[id].kind == KIND_BUY;
    }

    function isSell(uint256 id) public view returns (bool) {
        return inventories[id].kind == KIND_SELL;
    }

    function hasInv(uint256 id) public view returns (bool) {
        return inventories[id].kind != 0;
    }

    function isStatusOpen(uint256 id) public view returns (bool) {
        return inventories[id].status == STATUS_OPEN;
    }

    function isExpired(uint256 id) public view returns (bool) {
        return block.timestamp >= inventories[id].deadline;
    }

    function isSignatureValid(
        bytes memory signature,
        bytes32 hash,
        address signer
    ) public pure returns (bool) {
        // verify hash signed via `personal_sign`
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature) == signer;
    }

    function hasSignedIntention(uint8 op) public pure returns (bool) {
        return op != OP_BUY && op != OP_CANCEL_BUY && op != OP_ACCEPT_BUY && op != OP_REJECT_BUY;
    }
}