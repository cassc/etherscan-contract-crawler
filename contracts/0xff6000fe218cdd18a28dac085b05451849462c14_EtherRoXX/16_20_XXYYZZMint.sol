// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {XXYYZZCore} from "./XXYYZZCore.sol";

/**
 * @title XXYYZZMint
 * @author emo.eth
 * @notice This contract handles minting of XXYYZZ tokens.
 *         Tokens may be minted with a pseudorandom hex value, or with a specific hex value.
 *         The "Specific" methods allow for minting tokens with specific hex values with a commit-reveal scheme.
 *         Users may protect themselves against front-running by
 */
abstract contract XXYYZZMint is XXYYZZCore {
    uint256 public immutable MAX_MINT_CLOSE_TIMESTAMP;

    constructor(address initialOwner, uint256 maxBatchSize) XXYYZZCore(initialOwner, maxBatchSize) {
        MAX_MINT_CLOSE_TIMESTAMP = block.timestamp + 14 days;
    }

    //////////
    // MINT //
    //////////

    /**
     * @notice Mint a token with a pseudorandom hex value.
     * @return The token ID
     */
    function mint() public payable returns (uint256) {
        uint256 newAmount = _checkMintAndIncrementNumMinted(1);
        // get pseudorandom hex id – doesn't need to be derived from caller
        uint256 tokenId = _findAvailableHex(newAmount);
        _mint(msg.sender, tokenId);
        return tokenId;
    }

    /**
     * @notice Mint a number of tokens with pseudorandom hex values.
     * @param quantity The number of tokens to mint
     * @return The token IDs
     */
    function mint(uint256 quantity) public payable returns (uint256[] memory) {
        return _checkMintTo(msg.sender, quantity);
    }

    function mintTo(address to, uint256 quantity) public payable returns (uint256[] memory) {
        return _checkMintTo(to, quantity);
    }

    /**
     * @notice Mint a token with a specific hex value.
     *         A user must first call commit(bytes32) or batchCommit(bytes32[]) with the result(s) of
     *         computeCommittment(address,uint256,bytes32), and wait at least one minute.
     *         When calling mintSpecific, the "salt" should be the bytes32 salt provided to `computeCommitment` when
     *         creating the commitment hash.
     *
     *         Example: To register 0x123456 with salt bytes32(0xDEADBEEF)
     *             1. Call `computeCommitment(<minting addr>, 0x123456, bytes32(0xDEADBEEF))` for `bytes32 result`
     *             2. Call `commit(result)`
     *             3. Wait at least 1 minute, but less than 1 day
     *             4. Call `mintSpecific(0x123456, bytes32(0xDEADBEEF))`
     * @param id The 6-hex-digit token ID to mint
     * @param salt The salt used in the commitment for the commitment
     */
    function mintSpecific(uint256 id, bytes32 salt) public payable {
        _checkMintAndIncrementNumMinted(1);
        _mintSpecific(id, salt);
    }

    /**
     * @notice Mint a number of tokens with specific hex values.
     *         A user must first call commit(bytes32) with the result of
     *         `computeBatchCommitment(address,uint256[],bytes32)`, and wait at least COMMITMENT_LIFESPAN seconds.
     * @param ids The 6-hex-digit token IDs to mint
     * @param salt The salt used in the batch commitment
     * @return An array of booleans indicating whether each token was minted
     */
    function batchMintSpecific(uint256[] calldata ids, bytes32 salt) public payable returns (bool[] memory) {
        _validateBatchMintAndTimestamp(ids);
        bytes32 computedCommitment = computeBatchCommitment(msg.sender, ids, salt);
        _assertCommittedReveal(computedCommitment);
        return _batchMintAndIncrementAndRefund(ids);
    }

    /////////////
    // HELPERS //
    /////////////

    /**
     * @dev Mint tokens, validate that tokens were minted, and increment the number of minted tokens
     * @param to Recipient of the tokens
     * @param quantity Number of tokens to mint
     */
    function _checkMintTo(address to, uint256 quantity) internal returns (uint256[] memory) {
        // check payment and quantity once
        uint256 newAmount = _checkMintAndIncrementNumMinted(quantity);
        return _mintTo(to, quantity, newAmount);
    }

    /**
     * @dev Mint tokens, validate that tokens were minted, and increment the number of minted tokens
     * @param to Recipient of the tokens
     * @param quantity Number of tokens to mint
     */
    function _mintTo(address to, uint256 quantity, uint256 newAmount) internal returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](quantity);
        for (uint256 i; i < quantity;) {
            // get pseudorandom hex id
            uint256 tokenId = _findAvailableHex(newAmount);
            _mint(to, tokenId);
            tokenIds[i] = tokenId;
            unchecked {
                ++i;
                ++newAmount;
            }
        }
        return tokenIds;
    }

    /**
     * @dev Mint tokens, validate that tokens were minted, increment the number of minted tokens, and refund any
     *      overpayment
     * @param ids The 6-hex-digit token IDs to mint
     */
    function _batchMintAndIncrementAndRefund(uint256[] calldata ids) internal returns (bool[] memory) {
        bool[] memory minted = new bool[](ids.length);
        uint256 quantityMinted;
        for (uint256 i; i < ids.length;) {
            if (_mintSpecificUnprotected(ids[i])) {
                minted[i] = true;
                unchecked {
                    ++quantityMinted;
                }
            }
            unchecked {
                ++i;
            }
        }
        if (quantityMinted == 0) {
            revert NoneAvailable();
        }

        _incrementNumMintedAndRefundOverpayment(quantityMinted);
        return minted;
    }

    /**
     * @dev Check payment and quantity validation – quantityRequested for payment, quantityAvailable for updating
     *      the number of minted tokens, which may be different
     * @param quantityRequested The number of tokens requested by the user, which must be paid for
     * @return The new number of minted tokens
     */
    function _checkMintAndIncrementNumMinted(uint256 quantityRequested) internal returns (uint256) {
        if (block.timestamp > MAX_MINT_CLOSE_TIMESTAMP) {
            revert MintClosed();
        }
        _validatePayment(MINT_PRICE, quantityRequested);

        // increment supply before minting
        uint128 newAmount;
        // this can be unchecked because an ID can only be minted once, and all IDs are later validated to be uint24s
        unchecked {
            newAmount = _numMinted + uint128(quantityRequested);
        }
        _numMinted = newAmount;
        return newAmount;
    }

    /**
     * @dev Increment the number of minted tokens and refund any overpayment
     * @param quantity The number of tokens actually minted
     */
    function _incrementNumMintedAndRefundOverpayment(uint256 quantity) internal returns (uint256) {
        uint256 newAmount;
        // this can be unchecked because an ID can only be minted once, and all IDs are validated to be uint24s
        // overflow here implies invalid IDs down the line, which will cause a revert when minting
        unchecked {
            newAmount = _numMinted + quantity;
        }
        _numMinted = uint32(newAmount);
        _refundOverpayment(MINT_PRICE, quantity);
        return newAmount;
    }

    /**
     * @dev Validate the timestamp and payment for a batch mint
     * @param ids The 6-hex-digit token IDs to mint
     */
    function _validateBatchMintAndTimestamp(uint256[] calldata ids) internal view {
        if (block.timestamp > MAX_MINT_CLOSE_TIMESTAMP) {
            revert MintClosed();
        }
        if (ids.length > MAX_SPECIFIC_BATCH_SIZE) {
            revert MaxBatchSizeExceeded();
        }
        _validatePayment(ids.length, MINT_PRICE);
    }
}