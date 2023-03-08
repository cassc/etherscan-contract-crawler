// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ISodiumFreePool.sol";
import "./interfaces/ISodiumManager.sol";
import "./interfaces/IWETH.sol";

contract SodiumFreePool is ISodiumFreePool, Initializable, Pausable {
    // LTV = 0 indicates collection is not supported
    mapping(address => BorrowingTerms) private borrowingTermsForCollection;
    mapping(address => uint256) private fixedFloorPrice;

    address private sodiumPass;
    address private sodiumManagerERC721;
    address private sodiumManagerERC1155;
    address private owner;
    address private weth;
    address public oracle;
    uint128 public maxLoanLength;
    uint256 public floorPriceLifetime;
    uint256 public twap = 86400;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor(
        InitializeStruct memory initializeStruct_,
        uint128 floorPriceLifetime_,
        address[] memory collections_,
        BorrowingTerms[] memory borrowingTerms_,
        uint256[] memory fixedValues_
    ) {
        sodiumPass = initializeStruct_.sodiumPass;
        weth = initializeStruct_.weth;
        oracle = initializeStruct_.oracle;
        sodiumManagerERC721 = initializeStruct_.manager721;
        sodiumManagerERC1155 = initializeStruct_.manager1155;
        owner = msg.sender;
        maxLoanLength = 30 days;
        floorPriceLifetime = floorPriceLifetime_;

        uint256 i = 0;
        for (; i < collections_.length; ) {
            require(borrowingTerms_[i].LTV < 10000, "Sodium: APR is more than 10000");
            require(collections_[i] != address(0), "Sodium: address is zero");
            borrowingTermsForCollection[collections_[i]] = borrowingTerms_[i];
            if (0 != fixedValues_[i]) {
                fixedFloorPrice[collections_[i]] = fixedValues_[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    function borrow(
        address collectionCollateral_,
        address borrower_,
        uint256 amount_,
        uint256 amountBorrowed_,
        uint256 loanLength_,
        Message calldata message_
    ) external whenNotPaused returns (uint256) {
        require(sodiumManagerERC1155 == msg.sender || sodiumManagerERC721 == msg.sender, "Sodium: manager only");
        require(maxLoanLength >= loanLength_, "Sodium: length is too long");

        BorrowingTerms storage bt = borrowingTermsForCollection[collectionCollateral_];
        require(bt.LTV != 0, "Sodium: collection is not supported");

        uint256 price = _getPriceAndVerify(collectionCollateral_, message_);
        uint256 allowedToBorrow = _ltvByPrice(bt.LTV, price);

        require(amount_ <= allowedToBorrow, "Sodium: liquidity limit passed");
        _transferWETH(address(this), borrower_, amount_);

        amountBorrowed_ += amount_;
        require(amountBorrowed_ <= allowedToBorrow, "Sodium: pool ltv exceeded");

        if (IERC721(sodiumPass).balanceOf(tx.origin) == 1) {
            return 0;
        } else {
            return bt.APR;
        }
    }

    function bidERC721(
        uint256 auctionId_,
        uint256 amount_,
        uint256 index_
    ) external onlyOwner {
        _updateAllowanceERC721(amount_);
        ISodiumManager(sodiumManagerERC721).bid(auctionId_, amount_, index_);
    }

    function bidERC1155(
        uint256 auctionId_,
        uint256 amount_,
        uint256 index_
    ) external onlyOwner {
        _updateAllowanceERC1155(amount_);
        ISodiumManager(sodiumManagerERC1155).bid(auctionId_, amount_, index_);
    }

    function purchaseERC721(uint256 auctionId_, uint256 amount_) external onlyOwner {
        _updateAllowanceERC721(amount_);
        ISodiumManager(sodiumManagerERC721).purchase(auctionId_);
    }

    function purchaseERC1155(uint256 auctionId_, uint256 amount_) external onlyOwner {
        _updateAllowanceERC1155(amount_);
        ISodiumManager(sodiumManagerERC1155).purchase(auctionId_);
    }

    function resolveAuctionERC721(uint256 auctionId_, uint256 amount_) external onlyOwner {
        _updateAllowanceERC721(amount_);
        ISodiumManager(sodiumManagerERC721).resolveAuction(auctionId_);
    }

    function resolveAuctionERC1155(uint256 auctionId_, uint256 amount_) external onlyOwner {
        _updateAllowanceERC1155(amount_);
        ISodiumManager(sodiumManagerERC1155).resolveAuction(auctionId_);
    }

    function depositETH() external payable onlyOwner {
        (bool sent, ) = address(weth).call{value: msg.value}(abi.encodeWithSignature("deposit()"));
        require(sent, "Sodium: failed to send");
        emit PoolLiquidityAdded(msg.value);
    }

    function depositWETH(uint256 amount_) external onlyOwner {
        _transferWETH(msg.sender, address(this), amount_);
        emit PoolLiquidityAdded(amount_);
    }

    function withdrawWETH(uint256 amount_) external onlyOwner {
        _transferWETH(address(this), msg.sender, amount_);
        emit PoolLiquidityWithdrawn(amount_);
    }

    function setFixedValue(address[] calldata collections_, uint256[] calldata fixedValues_) external onlyOwner {
        require(collections_.length == fixedValues_.length, "Sodium: length is different");

        uint256 i = 0;
        for (; i < collections_.length; ) {
            require(collections_[i] != address(0), "Sodium: address is zero");

            fixedFloorPrice[collections_[i]] = fixedValues_[i];
            unchecked {
                ++i;
            }
        }

        emit FixedValueSet(collections_, fixedValues_);
    }

    function getFixedValue(address collection_) external view returns (uint256) {
        return fixedFloorPrice[collection_];
    }

    function setTermsForCollection(
        address[] calldata collectionsToRemove_,
        address[] calldata collections_,
        BorrowingTerms[] calldata borrowingTerms_
    ) external onlyOwner {
        uint256 i = 0;
        for (; i < collections_.length; ) {
            require(borrowingTerms_[i].LTV <= 10000, "Sodium: LTV is more than 10000");
            require(borrowingTerms_[i].APR <= 10000, "Sodium: APR is more than 10000");
            borrowingTermsForCollection[collections_[i]] = borrowingTerms_[i];

            unchecked {
                ++i;
            }
        }

        i = 0;
        for (; i < collectionsToRemove_.length; ) {
            delete borrowingTermsForCollection[collectionsToRemove_[i]];

            unchecked {
                ++i;
            }
        }

        emit PoolBorrowingTermsAdded(collections_, borrowingTerms_);
        emit PoolBorrowingTermsRemoved(collectionsToRemove_);
    }

    function setfloorPriceLifetime(uint256 floorPriceLifetime_) external onlyOwner {
        floorPriceLifetime = floorPriceLifetime_;
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        IERC721(msg.sender).safeTransferFrom(address(this), owner, tokenId, data);
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        IERC1155(msg.sender).safeTransferFrom(address(this), owner, tokenId, value, data);
        return this.onERC1155Received.selector;
    }

    function _getPriceAndVerify(address collectionCollateral_, Message calldata message_)
        internal
        view
        returns (uint256)
    {
        if (fixedFloorPrice[collectionCollateral_] != 0) {
            return fixedFloorPrice[collectionCollateral_];
        }

        bytes32 id = keccak256(
            abi.encode(
                keccak256("ContractWideCollectionPrice(uint8 kind,uint256 twapSeconds,address contract)"),
                1,
                twap,
                collectionCollateral_
            )
        );

        require(_verifyMessage(id, message_), "Sodium: payload is not signed by oracle");

        (address currency, uint256 price) = abi.decode(message_.payload, (address, uint256));

        require(address(0) == currency, "Sodium: currency should be ETH");
        return price;
    }

    function _verifyMessage(bytes32 id, Message memory message) internal view virtual returns (bool success) {
        // Ensure the message matches the requested id
        if (id != message.id) {
            return false;
        }

        // Ensure the message timestamp is valid
        if (message.timestamp > block.timestamp || message.timestamp + floorPriceLifetime < block.timestamp) {
            return false;
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract the individual signature fields from the signature
        bytes memory signature = message.signature;
        if (signature.length == 64) {
            // EIP-2098 compact signature
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else if (signature.length == 65) {
            // ECDSA signature
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else {
            return false;
        }

        address signerAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    // EIP-712 structured-data hash
                    keccak256(
                        abi.encode(
                            keccak256("Message(bytes32 id,bytes payload,uint256 timestamp)"),
                            message.id,
                            keccak256(message.payload),
                            message.timestamp
                        )
                    )
                )
            ),
            v,
            r,
            s
        );

        // Ensure the signer matches the designated oracle address
        return signerAddress == oracle;
    }

    function _ltvByPrice(uint256 ltv, uint256 price) internal pure returns (uint256) {
        return (price * ltv) / 10000;
    }

    function _updateAllowanceERC1155(uint256 amount_) internal {
        require(IWETH(weth).approve(sodiumManagerERC1155, amount_), "Sodium: failed to set allowance");
    }

    function _updateAllowanceERC721(uint256 amount_) internal {
        require(IWETH(weth).approve(sodiumManagerERC721, amount_), "Sodium: failed to set allowance");
    }

    function _transferWETH(
        address from_,
        address to_,
        uint256 amount_
    ) internal {
        bool sent;

        if (from_ == address(this)) {
            sent = IERC20(weth).transfer(to_, amount_);
        } else {
            sent = IERC20(weth).transferFrom(from_, to_, amount_);
        }

        require(sent, "Sodium: failed to send");
    }

    function pause() external onlyOwner {
        Pausable._pause();
    }

    function unpause() external onlyOwner {
        Pausable._unpause();
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}