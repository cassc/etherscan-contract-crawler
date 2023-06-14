// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
 *                                     _H_
 *                                    /___\
 *                                    \888/
 * ~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~U~^~^~^~^~^~^~^
 *                       ~              |
 *       ~                        o     |        ~
 *                 ___        o         |
 *        _,.--,.'`   `~'-.._    O      |
 *       /_  .-"      _   /_\'.         |   ~
 *      .-';'       (( `  \0/  `\       #
 *     /__;          ((_  ,_     |  ,   #
 *     .-;                  \_   /  #  _#,
 *    /  ;    .-' /  _.--""-.\`~`   `#(('\\        ~
 *    ;-';   /   / .'                  )) \\
 *        ; /.--'.'                   ((   ))
 *         \     |        ~            \\ ((
 *          \    |                      )) `
 *    ~      \   |                      `
 *            \  |
 *            .` `""-.
 *          .'        \         ~               ~
 *          |    |\    |
 *          \   /  '-._|
 *           \.'
 */

import {ERC721, ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IERC2981} from "openzeppelin/interfaces/IERC2981.sol";
import {Pair, ReservoirOracle} from "caviar/Pair.sol";
import {IRoyaltyRegistry} from "royalty-registry-solidity/IRoyaltyRegistry.sol";

import {PrivatePool} from "./PrivatePool.sol";
import {IStolenNftOracle} from "./interfaces/IStolenNftOracle.sol";

/// @title Eth Router
/// @author out.eth (@outdoteth)
/// @notice This contract is used to route buy, sell, and change orders to multiple pools in one transaction. It
/// will route the orders to either a private pool or a public pool. If the order goes to a public pool, then users
/// can choose whether or not they would like to pay royalties. The only base token which is supported is native ETH.
contract EthRouter is ERC721TokenReceiver {
    using SafeTransferLib for address;
    using SafeTransferLib for address payable;

    struct Buy {
        address payable pool;
        uint256[] tokenIds;
        uint256[] tokenWeights;
        PrivatePool.MerkleMultiProof proof;
        uint256 baseTokenAmount;
        bool isPublicPool;
    }

    struct Sell {
        address payable pool;
        uint256[] tokenIds;
        uint256[] tokenWeights;
        PrivatePool.MerkleMultiProof proof;
        IStolenNftOracle.Message[] stolenNftProofs;
        bool isPublicPool;
        bytes32[][] publicPoolProofs;
    }

    struct Change {
        address payable pool;
        uint256[] inputTokenIds;
        uint256[] inputTokenWeights;
        PrivatePool.MerkleMultiProof inputProof;
        IStolenNftOracle.Message[] stolenNftProofs;
        uint256[] outputTokenIds;
        uint256[] outputTokenWeights;
        PrivatePool.MerkleMultiProof outputProof;
        uint256 baseTokenAmount;
        bool isPublicPool;
    }

    error DeadlinePassed();
    error OutputAmountTooSmall();
    error PriceOutOfRange();
    error InvalidRoyaltyFee();
    error MismatchedTokenIds();

    address public immutable royaltyRegistry;

    receive() external payable {}

    constructor(address _royaltyRegistry) {
        royaltyRegistry = _royaltyRegistry;
    }

    /// @notice Executes a series of buy operations against public or private pools.
    /// @param buys The buy operations to execute.
    /// @param deadline The deadline for the transaction to be mined. Will revert if timestamp is greater than deadline.
    /// If it's set to 0 then there is no deadline.
    /// @param payRoyalties Whether to pay royalties or not.
    function buy(Buy[] calldata buys, uint256 deadline, bool payRoyalties) public payable {
        // check that the deadline has not passed (if any)
        if (block.timestamp > deadline && deadline != 0) {
            revert DeadlinePassed();
        }

        // loop through and execute the the buys
        for (uint256 i = 0; i < buys.length; i++) {
            // fetch the nft address (PrivatePool and Pair both have an nft() method)
            address nft = PrivatePool(buys[i].pool).nft();

            if (buys[i].isPublicPool) {
                // execute the buy against a public pool
                uint256 inputAmount = Pair(buys[i].pool).nftBuy{value: buys[i].baseTokenAmount}(
                    buys[i].tokenIds, buys[i].baseTokenAmount, 0
                );

                // pay the royalties if buyer has opted-in
                if (payRoyalties) {
                    uint256 salePrice = inputAmount / buys[i].tokenIds.length;
                    for (uint256 j = 0; j < buys[i].tokenIds.length; j++) {
                        // get the royalty fee and recipient
                        (uint256 royaltyFee, address royaltyRecipient) = getRoyalty(nft, buys[i].tokenIds[j], salePrice);

                        if (royaltyFee > 0 && royaltyRecipient != address(0)) {
                            // transfer the royalty fee to the royalty recipient
                            royaltyRecipient.safeTransferETH(royaltyFee);
                        }
                    }
                }
            } else {
                // execute the buy against a private pool
                PrivatePool(buys[i].pool).buy{value: buys[i].baseTokenAmount}(
                    buys[i].tokenIds, buys[i].tokenWeights, buys[i].proof
                );
            }

            for (uint256 j = 0; j < buys[i].tokenIds.length; j++) {
                // transfer the NFT to the caller
                ERC721(nft).safeTransferFrom(address(this), msg.sender, buys[i].tokenIds[j]);
            }
        }

        // refund any surplus ETH to the caller
        if (address(this).balance > 0) {
            msg.sender.safeTransferETH(address(this).balance);
        }
    }

    /// @notice Executes a series of sell operations against public or private pools.
    /// @param sells The sell operations to execute.
    /// @param minOutputAmount The minimum amount of output tokens that must be received for the transaction to succeed.
    /// @param deadline The deadline for the transaction to be mined. Will revert if timestamp is greater than deadline.
    /// Set to 0 for there to be no deadline.
    /// @param payRoyalties Whether to pay royalties or not.
    function sell(Sell[] calldata sells, uint256 minOutputAmount, uint256 deadline, bool payRoyalties) public {
        // check that the deadline has not passed (if any)
        if (block.timestamp > deadline && deadline != 0) {
            revert DeadlinePassed();
        }

        // loop through and execute the sells
        for (uint256 i = 0; i < sells.length; i++) {
            // fetch the nft address (PrivatePool and Pair both have an nft() method)
            address nft = PrivatePool(sells[i].pool).nft();

            // transfer the NFTs into the router from the caller
            for (uint256 j = 0; j < sells[i].tokenIds.length; j++) {
                ERC721(nft).safeTransferFrom(msg.sender, address(this), sells[i].tokenIds[j]);
            }

            // approve the pair to transfer NFTs from the router
            _approveNfts(nft, sells[i].pool);

            if (sells[i].isPublicPool) {
                // execute the sell against a public pool
                uint256 outputAmount = Pair(sells[i].pool).nftSell(
                    sells[i].tokenIds,
                    0,
                    0,
                    sells[i].publicPoolProofs,
                    // ReservoirOracle.Message[] is the exact same as IStolenNftOracle.Message[] and can be
                    // decoded/encoded 1-to-1.
                    abi.decode(abi.encode(sells[i].stolenNftProofs), (ReservoirOracle.Message[]))
                );

                // pay the royalties if seller has opted-in
                if (payRoyalties) {
                    uint256 salePrice = outputAmount / sells[i].tokenIds.length;
                    for (uint256 j = 0; j < sells[i].tokenIds.length; j++) {
                        // get the royalty fee and recipient
                        (uint256 royaltyFee, address royaltyRecipient) =
                            getRoyalty(nft, sells[i].tokenIds[j], salePrice);

                        if (royaltyFee > 0 && royaltyRecipient != address(0)) {
                            // transfer the royalty fee to the royalty recipient
                            royaltyRecipient.safeTransferETH(royaltyFee);
                        }
                    }
                }
            } else {
                // execute the sell against a private pool
                PrivatePool(sells[i].pool).sell(
                    sells[i].tokenIds, sells[i].tokenWeights, sells[i].proof, sells[i].stolenNftProofs
                );
            }
        }

        // check that the output amount is greater than the minimum
        if (address(this).balance < minOutputAmount) {
            revert OutputAmountTooSmall();
        }

        // transfer the output amount to the caller
        msg.sender.safeTransferETH(address(this).balance);
    }

    /// @notice Executes a deposit to a private pool (transfers NFTs and ETH to the pool).
    /// @param privatePool The private pool to deposit to.
    /// @param nft The NFT contract address.
    /// @param tokenIds The token IDs of the NFTs to deposit.
    /// @param minPrice The minimum price of the pool. Will revert if price is smaller than this.
    /// @param maxPrice The maximum price of the pool. Will revert if price is greater than this.
    /// @param deadline The deadline for the transaction to be mined. Will revert if timestamp is greater than deadline.
    /// Set to 0 for deadline to be ignored.
    function deposit(
        address payable privatePool,
        address nft,
        uint256[] calldata tokenIds,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 deadline
    ) public payable {
        // check deadline has not passed (if any)
        if (block.timestamp > deadline && deadline != 0) {
            revert DeadlinePassed();
        }

        // check pool price is in between min and max
        uint256 price = PrivatePool(privatePool).price();
        if (price > maxPrice || price < minPrice) {
            revert PriceOutOfRange();
        }

        // transfer NFTs from caller
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ERC721(nft).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }

        // approve the pair to transfer NFTs from the router
        _approveNfts(nft, privatePool);

        // execute deposit
        PrivatePool(privatePool).deposit{value: msg.value}(tokenIds, msg.value);
    }

    /// @notice Executes a series of change operations against a private pool.
    /// @param changes The change operations to execute.
    /// @param deadline The deadline for the transaction to be mined. Will revert if timestamp is greater than deadline.
    /// Set to 0 for deadline to be ignored.
    function change(Change[] calldata changes, uint256 deadline) public payable {
        // check deadline has not passed (if any)
        if (block.timestamp > deadline && deadline != 0) {
            revert DeadlinePassed();
        }

        // loop through and execute the changes
        for (uint256 i = 0; i < changes.length; i++) {
            Change memory _change = changes[i];

            // fetch the nft address (PrivatePool and Pair both have an nft() method)
            address nft = PrivatePool(_change.pool).nft();

            // transfer NFTs from caller
            for (uint256 j = 0; j < changes[i].inputTokenIds.length; j++) {
                ERC721(nft).safeTransferFrom(msg.sender, address(this), _change.inputTokenIds[j]);
            }

            // approve the pair to transfer NFTs from the router
            _approveNfts(nft, _change.pool);

            if (_change.isPublicPool) {
                // check that the input token ids length matches the output token ids length
                if (_change.inputTokenIds.length != _change.outputTokenIds.length) {
                    revert MismatchedTokenIds();
                }

                // empty proofs assumes that we only change against floor public pools
                bytes32[][] memory publicPoolProofs = new bytes32[][](0);

                // get some fractional tokens for the input tokens
                uint256 fractionalTokenAmount = Pair(_change.pool).wrap(
                    _change.inputTokenIds,
                    publicPoolProofs,
                    // ReservoirOracle.Message[] is the exact same as IStolenNftOracle.Message[] and can be
                    // decoded/encoded 1-to-1.
                    abi.decode(abi.encode(_change.stolenNftProofs), (ReservoirOracle.Message[]))
                );

                // buy the surplus fractional tokens required to pay the fee
                uint256 fractionalTokenFee = fractionalTokenAmount * 3 / 1000;
                Pair(_change.pool).buy{value: _change.baseTokenAmount}(fractionalTokenFee, _change.baseTokenAmount, 0);

                // exchange the fractional tokens for the target output tokens
                Pair(_change.pool).unwrap(_change.outputTokenIds, true);
            } else {
                // execute change
                PrivatePool(_change.pool).change{value: _change.baseTokenAmount}(
                    _change.inputTokenIds,
                    _change.inputTokenWeights,
                    _change.inputProof,
                    _change.stolenNftProofs,
                    _change.outputTokenIds,
                    _change.outputTokenWeights,
                    _change.outputProof
                );
            }

            // transfer NFTs to caller
            for (uint256 j = 0; j < changes[i].outputTokenIds.length; j++) {
                ERC721(nft).safeTransferFrom(address(this), msg.sender, _change.outputTokenIds[j]);
            }
        }

        // refund any surplus ETH to the caller
        if (address(this).balance > 0) {
            msg.sender.safeTransferETH(address(this).balance);
        }
    }

    /// @notice Gets the royalty and recipient for a given NFT and sale price. Looks up the royalty info from the
    /// manifold registry.
    /// @param nft The NFT contract address.
    /// @param tokenId The token ID of the NFT.
    /// @param salePrice The sale price of the NFT.
    /// @return royaltyFee The royalty fee to pay.
    /// @return recipient The address to pay the royalty fee to.
    function getRoyalty(address nft, uint256 tokenId, uint256 salePrice)
        public
        view
        returns (uint256 royaltyFee, address recipient)
    {
        // get the royalty lookup address
        address lookupAddress = IRoyaltyRegistry(royaltyRegistry).getRoyaltyLookupAddress(nft);

        if (IERC2981(lookupAddress).supportsInterface(type(IERC2981).interfaceId)) {
            // get the royalty fee from the registry
            (recipient, royaltyFee) = IERC2981(lookupAddress).royaltyInfo(tokenId, salePrice);

            // revert if the royalty fee is greater than the sale price
            if (royaltyFee > salePrice) revert InvalidRoyaltyFee();
        }
    }

    function _approveNfts(address nft, address target) internal {
        // check if the router is already approved to transfer NFTs from the caller
        if (ERC721(nft).isApprovedForAll(address(this), target)) return;

        // approve the target to transfer NFTs from the router
        ERC721(nft).setApprovalForAll(target, true);
    }
}