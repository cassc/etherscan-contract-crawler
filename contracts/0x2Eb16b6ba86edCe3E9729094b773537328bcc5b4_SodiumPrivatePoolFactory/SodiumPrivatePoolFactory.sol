/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
pragma solidity ^0.8.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File contracts/interfaces/ISodiumPrivatePool.sol
interface ISodiumPrivatePool {
    struct BorrowingTerms {
        uint256 APR;
        uint256 LTV; // percentage which is allowed for a loan; should be expressed in thousands; if LTV - 70% => 7000 or LTV - 5% => 500
    }

    struct Message {
        bytes32 id;
        bytes payload;
        uint256 timestamp; // The UNIX timestamp when the message was signed by the oracle
        bytes signature; // ECDSA signature or EIP-2098 compact signature
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FixedValueSet(address[] collections, uint256[] values);
    event PoolLiquidityAdded(uint256 amount);
    event PoolLiquidityWithdrawn(uint256 amount);
    event PoolBorrowingTermsAdded(address[] collections, ISodiumPrivatePool.BorrowingTerms[] borrowingTerms);
    event PoolBorrowingTermsRemoved(address[] collections);

    function initialize(
        address oracle_,
        address manager721_,
        address manager1155_,
        address weth_,
        address poolOwner_,
        uint128 floorPriceLifetime_,
        address[] calldata collections_,
        BorrowingTerms[] calldata borrowingTerms_,
        uint256[] calldata fixedValues_
    ) external;

    /// @notice Borrow from pools; can be called only by erc721Manager or erc1155Manager
    /// @param collectionCollateral_ nft which will be used as a collateral
    /// @param borrower_ borrower address
    /// @param amountBorrowed_ amount which was borrowed
    /// @param loanLength_ loan length
    /// @param message_ oracle message
    function borrow(
        address collectionCollateral_,
        address borrower_,
        uint256 amount_,
        uint256 amountBorrowed_,
        uint256 loanLength_,
        Message calldata message_
    ) external returns (uint256);

    /// @notice Makes a bid through a pool to erc721 manager
    /// @param auctionId_ auction id
    /// @param amount_ bid size
    /// @param index_ index of a pool in the lender queue inside the manager; if used a bid will be boosted with liquidity added to a loan
    function bidERC721(uint256 auctionId_, uint256 amount_, uint256 index_) external;

    /// @notice Makes a bid through a pool to erc1155 manager
    /// @param auctionId_ auction id
    /// @param amount_ bid size
    /// @param index_ index of a pool in the lender queue inside the manager; if used a bid will be boosted with liquidity added to a loan
    function bidERC1155(uint256 auctionId_, uint256 amount_, uint256 index_) external;

    /// @notice Makes a purchase through a pool to erc721 manager
    /// @param auctionId_ auction id
    /// @param amount_ which will be spent
    function purchaseERC721(uint256 auctionId_, uint256 amount_) external;

    /// @notice Makes a purchase through a pool to erc1155 manager
    /// @param auctionId_ auction id
    /// @param amount_ which will be spent
    function purchaseERC1155(uint256 auctionId_, uint256 amount_) external;

    /// @notice Makes an auction resolution through a pool to erc721 manager
    /// @param auctionId_ auction id
    /// @param amount_ which will be spent
    function resolveAuctionERC721(uint256 auctionId_, uint256 amount_) external;

    /// @notice Makes an auction resolution through a pool to erc1155 manager
    /// @param auctionId_ auction id
    /// @param amount_ which will be spent
    function resolveAuctionERC1155(uint256 auctionId_, uint256 amount_) external;

    /// @notice Used to set fixed floor price for a collection
    /// @param collections_ array of collections
    /// @param fixedValues_ array of floor price values
    function setFixedValue(address[] calldata collections_, uint256[] calldata fixedValues_) external;

    /// @notice Used to set fixed floor price for a collection
    /// @param collection_ collection
    function getFixedValue(address collection_) external view returns (uint256);

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155Received(
        address operator,
        address from,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function depositETH() external payable;

    function withdrawWETH(uint256 amount_) external;

    function depositWETH(uint256 amount_) external;

    function setTermsForCollection(
        address[] calldata collectionsToRemove_,
        address[] calldata collections_,
        BorrowingTerms[] calldata borrowingTerms_
    ) external;

    function setfloorPriceLifetime(uint256 floorPriceLifetime_) external;
}

interface ISodiumPrivatePoolFactory {
    event PrivatePoolCreated(
        address indexed owner,
        address privatePool,
        address[] collections,
        ISodiumPrivatePool.BorrowingTerms[] borrowingTerms,
        uint256[] fixedValues,
        uint256 amount
    );

    /// @dev to avoid the stack is too deep error
    struct CollectionsFixedValuesAndDeposit {
        address[] collections;
        uint256[] fixedValues;
        bool isWETHdeposit;
        uint256 amount;
    }

    /// @notice Used  to create a private pool
    /// @param oracle_ oracle which is used to determine nft floor price
    /// @param floorPriceLifetime_ time after which floor price is considered to be expired
    /// @param collections_ array of collections which will be supported after a pool creation
    /// @param borrowingTerms_ array of terms which will be used for a corresponding collections in the collections_ array
    /// @param fixedValues_ array of fixed values which will be assigned after pool creation
    function createPrivatePool(
        address oracle_,
        uint128 floorPriceLifetime_,
        address[] calldata collections_,
        ISodiumPrivatePool.BorrowingTerms[] calldata borrowingTerms_,
        uint256[] calldata fixedValues_
    ) external returns (address);

    /// @notice Used  to create a private pool
    /// @param oracle_ oracle which is used to determine nft floor price
    /// @param floorPriceLifetime_ time after which floor price is considered to be expired
    /// @param collectionsFixedValuesAndDeposit_ array of collections with fixed values which will be supported after a pool creation
    /// @param borrowingTerms_ array of terms which will be used for a corresponding collections in the collections_ array
    function createPrivatePoolWithDeposit(
        address oracle_,
        uint128 floorPriceLifetime_,
        CollectionsFixedValuesAndDeposit calldata collectionsFixedValuesAndDeposit_,
        ISodiumPrivatePool.BorrowingTerms[] calldata borrowingTerms_
    ) external payable returns (address);
}

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

contract SodiumPrivatePoolFactory is ISodiumPrivatePoolFactory {
    address public implementation;
    address private weth;
    address public sodiumManagerERC721;
    address public sodiumManagerERC1155;

    constructor(address implementation_, address manager721_, address manager1155_, address weth_) {
        implementation = implementation_;
        sodiumManagerERC721 = manager721_;
        sodiumManagerERC1155 = manager1155_;
        weth = weth_;
    }

    function createPrivatePool(
        address oracle_,
        uint128 floorPriceLifetime_,
        address[] calldata collections_,
        ISodiumPrivatePool.BorrowingTerms[] calldata borrowingTerms_,
        uint256[] calldata fixedValues_
    ) external returns (address) {
        address privatePool = Clones.clone(implementation);
        ISodiumPrivatePool(privatePool).initialize(
            oracle_,
            sodiumManagerERC721,
            sodiumManagerERC1155,
            weth,
            msg.sender,
            floorPriceLifetime_,
            collections_,
            borrowingTerms_,
            fixedValues_
        );

        emit PrivatePoolCreated(msg.sender, privatePool, collections_, borrowingTerms_, fixedValues_, 0);
        return privatePool;
    }

    function createPrivatePoolWithDeposit(
        address oracle_,
        uint128 floorPriceLifetime_,
        CollectionsFixedValuesAndDeposit calldata collectionsFixedValuesAndDeposit_,
        ISodiumPrivatePool.BorrowingTerms[] memory borrowingTerms_
    ) external payable returns (address) {
        address privatePool = Clones.clone(implementation);

        ISodiumPrivatePool(privatePool).initialize(
            oracle_,
            sodiumManagerERC721,
            sodiumManagerERC1155,
            weth,
            msg.sender,
            floorPriceLifetime_,
            collectionsFixedValuesAndDeposit_.collections,
            borrowingTerms_,
            collectionsFixedValuesAndDeposit_.fixedValues
        );

        if (collectionsFixedValuesAndDeposit_.isWETHdeposit) {
            bool sent = IERC20(weth).transferFrom(msg.sender, privatePool, collectionsFixedValuesAndDeposit_.amount);
            require(sent, "Sodium: failed to send");
        } else {
            require(collectionsFixedValuesAndDeposit_.amount == msg.value, "Sodium: amount differs from msg.value");

            (bool sent, ) = address(weth).call{value: collectionsFixedValuesAndDeposit_.amount}(
                abi.encodeWithSignature("deposit()")
            );
            require(sent, "Sodium: failed to send");

            sent = IERC20(weth).transfer(privatePool, collectionsFixedValuesAndDeposit_.amount);
            require(sent, "Sodium: failed to send");
        }

        emit PrivatePoolCreated(
            msg.sender,
            privatePool,
            collectionsFixedValuesAndDeposit_.collections,
            borrowingTerms_,
            collectionsFixedValuesAndDeposit_.fixedValues,
            collectionsFixedValuesAndDeposit_.amount
        );
        return privatePool;
    }
}