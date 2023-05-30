// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {IBlacklist} from "./IBlacklist.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface IKUMABondToken is IERC721 {
    event AccessControllerSet(address accesController);
    event BlacklistSet(address blacklist);
    event BondIssued(uint256 id, Bond bond);
    event BondRedeemed(uint256 id);
    event MaxCouponSet(uint256 oldMaxCoupon, uint256 newMaxCoupon);
    event TokenTncUpdated(uint256 indexed tokenId, uint256 oldTermId, uint256 newTermId);
    event TncAdded(uint256 indexed termId, string url);
    event TncUrlUpdated(uint256 indexed termId, string oldUrl, string newUrl);
    event UriSet(string oldUri, string newUri);

    /**
     * @param cusip Bond CUISP number.
     * @param isin Bond ISIN number.
     * @param currency Currency of the bond - example : USD
     * @param term Lifetime of the bond ie maturity in seconds - example : 31449600 (52 weeks)
     * @param issuance Bond issuance date - timestamp in seconds
     * @param maturity Date on which the principal amount becomes due - timestamp is seconds
     * @param coupon Annual interest rate paid on the bond per - rate per second
     * @param principal Bond face value ie redeemable amount
     * @param issuer Bond issuer - example : US
     * @param riskCategory Unique risk category identifier computed with keccack256(abi.encode(currency, issuer, term))
     */
    struct Bond {
        bytes16 cusip;
        bytes16 isin;
        bytes4 currency;
        uint64 issuance;
        uint64 maturity;
        uint64 term;
        uint32 tncId;
        uint256 coupon;
        uint256 principal;
        bytes32 issuer;
        bytes32 riskCategory;
    }

    function issueBond(address to, Bond calldata bond) external;

    function redeem(uint256 tokenId) external;

    function setUri(string memory newUri) external;

    function setMaxCoupon(uint256 newMaxCoupon) external;

    function addTnc(string memory url) external;

    function updateTncUrl(uint32 tncId, string memory newUrl) external;

    function updateTncForToken(uint256 tokenId, uint32 tncId) external;

    function pause() external;

    function unpause() external;

    function accessController() external view returns (IAccessControl);

    function blacklist() external view returns (IBlacklist);

    function getMaxCoupon() external view returns (uint256);

    function getTncCounter() external view returns (uint256);

    function getTokenIdCounter() external view returns (uint256);

    function getBaseURI() external view returns (string memory);

    function getBond(uint256) external view returns (Bond memory);

    function getTncUrl(uint256 id) external view returns (string memory);
}