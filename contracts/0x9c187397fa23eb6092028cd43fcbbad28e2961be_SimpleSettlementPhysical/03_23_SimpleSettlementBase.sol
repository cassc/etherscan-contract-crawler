// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import {EIP712} from "openzeppelin/utils/cryptography/EIP712.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";

// interfaces
import {IMarginEngine} from "../../../interfaces/IMarginEngine.sol";

import "./types.sol";
import "./errors.sol";

abstract contract SimpleSettlementBase is EIP712, Ownable, ReentrancyGuard {
    /*///////////////////////////////////////////////////////////////
                        Constants and Immutables
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant BID_HASH = keccak256(
        "Bid(address vault,int256[] weights,uint256[] options,uint8 premiumId,int256 premium,uint256 expiry,uint256 nonce)"
    );

    /*///////////////////////////////////////////////////////////////
                        Storage
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => bool) public noncesUsed;

    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    event AuctioneerSet(address auctioneer, address newAuctioneer);

    event SettledBid(uint256 nonce, address indexed vault, address indexed counterparty);

    event SettledBids(uint256[] nonces, address[] vaults, address indexed counterparty);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _domainName, string memory _domainVersion, address _auctioneer)
        EIP712(_domainName, _domainVersion)
    {
        if (_auctioneer == address(0)) revert BadAddress();

        transferOwnership(_auctioneer);
    }

    /*///////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice bulk revoke from margin account
     * @dev revokes access to margin accounts
     * @param _marginEngine address of margin engine
     * @param _subAccounts array of sub-accounts to itself from
     */
    function revokeMarginAccountAccess(address _marginEngine, address[] calldata _subAccounts) external {
        _checkOwner();

        IMarginEngine marginEngine = IMarginEngine(_marginEngine);

        for (uint256 i; i < _subAccounts.length;) {
            marginEngine.revokeSelfAccess(_subAccounts[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Settles a single bid
     * @dev revokes access to counterparty (msg.sender) after complete
     * @param _bid is the signed data type containing bid information
     * @param _collateralIds array of grappa ids for erc20 tokens needed to collateralize options
     * @param _amounts array of (counterparty) deposit amounts for each collateral + premium (if applicable)
     */
    function settle(Bid calldata _bid, uint8[] calldata _collateralIds, uint256[] calldata _amounts) external virtual {}

    /**
     * @notice Settles a several bids
     * @dev    revokes access to counterparty (msg.sender) after settlement
     * @param _bids is array of signed data types containing bid information
     * @param _collateralIds array of asset id for erc20 tokens needed to collateralize options
     * @param _amounts array of (counterparty) deposit amounts for each collateral + premium (if applicable)
     */
    function settleBatch(Bid[] calldata _bids, uint8[] calldata _collateralIds, uint256[] calldata _amounts) external virtual {}

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Asserts signatory on the data
     */
    function _assertBidValid(Bid calldata _bid) internal {
        address signer = ECDSA.recover(_getDigest(_bid), _bid.v, _bid.r, _bid.s);

        if (signer != owner()) revert Unauthorized();
        if (noncesUsed[_bid.nonce]) revert NonceAlreadyUsed();
        if (_bid.expiry <= block.timestamp) revert ExpiredBid();

        noncesUsed[_bid.nonce] = true;
    }

    /**
     * @notice Hashes the fully encoded EIP712 message
     */
    function _getDigest(Bid calldata _bid) internal view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    BID_HASH,
                    _bid.vault,
                    keccak256(abi.encodePacked(_bid.weights)),
                    keccak256(abi.encodePacked(_bid.options)),
                    _bid.premiumId,
                    _bid.premium,
                    _bid.expiry,
                    _bid.nonce
                )
            )
        );
    }
}