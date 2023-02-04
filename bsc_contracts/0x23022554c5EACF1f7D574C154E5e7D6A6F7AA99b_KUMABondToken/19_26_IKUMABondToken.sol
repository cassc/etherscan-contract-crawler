// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {IBlacklist} from "./IBlacklist.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface IKUMABondToken is IERC721 {
    event BondIssued(bytes4 indexed currency, bytes4 indexed country, uint96 indexed term, uint256 id);
    event BondRedeemed(bytes4 indexed currency, bytes4 indexed country, uint96 indexed term, uint256 id);
    event UriSet(string oldUri, string newUri);

    /**
     * @param cusip Bond CUISP number.
     * @param isin Bond ISIN number.
     * @param currency Currency of the bond - example : USD
     * @param country Treasury issuer - example : US
     * @param term Lifetime of the bond ie maturity in seconds - issuance date - example : 10 years
     * @param issuance Bond issuance date - timestamp in seconds
     * @param maturity Date on which the principal amount becomes due - timestamp is seconds
     * @param coupon Annual interest rate paid on the bond per - rate per second
     * @param principal Bond face value ie redeemable amount
     * @param riskCategory Unique risk category identifier computed with keccack256(abi.encode(currency, country, term))
     */
    struct Bond {
        bytes16 cusip;
        bytes16 isin;
        bytes4 currency;
        bytes4 country;
        uint64 term;
        uint64 issuance;
        uint64 maturity;
        uint256 coupon;
        uint256 principal;
        bytes32 riskCategory;
    }

    function issueBond(address to, Bond calldata bond) external;

    function redeem(uint256 tokenId) external;

    function setUri(string memory newUri) external;

    function pause() external;

    function unpause() external;

    function accessController() external view returns (IAccessControl);

    function blacklist() external view returns (IBlacklist);

    function getTokenIdCounter() external view returns (uint256);

    function getBond(uint256) external view returns (Bond memory);
}