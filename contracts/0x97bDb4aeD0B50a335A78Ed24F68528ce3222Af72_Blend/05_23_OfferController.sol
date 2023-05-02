// SPDX-License-Identifier: BSL 1.1 - Blend (c) Non Fungible Trading Ltd.
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";

import "./lib/Signatures.sol";
import "./interfaces/IOfferController.sol";

abstract contract OfferController is IOfferController, Signatures, Ownable2StepUpgradeable {
    mapping(address => mapping(uint256 => uint256)) public cancelledOrFulfilled;
    uint256[50] private _gap;

    /**
     * @notice Assert offer validity
     * @param offerHash Offer hash
     * @param signer Address of offer signer
     * @param oracle Address of oracle
     * @param signature Packed signature array
     * @param expirationTime Offer expiration time
     * @param salt Offer salt
     */
    function _validateOffer(
        bytes32 offerHash,
        address signer,
        address oracle,
        bytes calldata signature,
        uint256 expirationTime,
        uint256 salt
    ) internal view {
        _verifyOfferAuthorization(offerHash, signer, oracle, signature);

        if (expirationTime < block.timestamp) {
            revert OfferExpired();
        }
        if (cancelledOrFulfilled[signer][salt] == 1) {
            revert OfferUnavailable();
        }
    }

    /*/////////////////////////////////////////
                  CANCEL FUNCTIONS
    /////////////////////////////////////////*/
    /**
     * @notice Cancels offer salt for caller
     * @param salt Unique offer salt
     */
    function cancelOffer(uint256 salt) external {
        _cancelOffer(msg.sender, salt);
    }

    /**
     * @notice Cancels offers in bulk for caller
     * @param salts List of offer salts
     */
    function cancelOffers(uint256[] calldata salts) external {
        uint256 saltsLength = salts.length;
        for (uint256 i; i < saltsLength; ) {
            _cancelOffer(msg.sender, salts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Cancels all offers by incrementing caller nonce
     */
    function incrementNonce() external {
        _incrementNonce(msg.sender);
    }

    /**
     * @notice Cancel offer by user and salt
     * @param user Address of user
     * @param salt Unique offer salt
     */
    function _cancelOffer(address user, uint256 salt) private {
        cancelledOrFulfilled[user][salt] = 1;
        emit OfferCancelled(user, salt);
    }

    /**
     * @notice Cancel all orders by incrementing the user nonce
     * @param user Address of user
     */
    function _incrementNonce(address user) internal {
        emit NonceIncremented(user, ++nonces[user]);
    }

    /*/////////////////////////////////////////
                  ADMIN FUNCTIONS
    /////////////////////////////////////////*/

    /**
     * @notice Set approval for an oracle address
     * @param oracle Address of oracle
     * @param approved Whether the oracle is approved
     */
    function setOracle(address oracle, bool approved) external onlyOwner {
        if (approved) {
            oracles[oracle] = 1;
        } else {
            oracles[oracle] = 0;
        }
    }

    /**
     * @notice Set the block range expiry of oracle signatures
     * @param _blockRange Block range
     */
    function setBlockRange(uint256 _blockRange) external onlyOwner {
        blockRange = _blockRange;
    }
}