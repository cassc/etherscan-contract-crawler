// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "../token/NFT.sol";
import "../bond/CollateralizedBondGranter.sol";
import "../borrowing/LiquidityRequester.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title NFTBond
 * @dev Contains functions related to buying and liquidating bonds, and borrowing and returning funds
 * @author Ethichub
 */
abstract contract NFTBond is NFT, CollateralizedBondGranter, LiquidityRequester, PausableUpgradeable {
    function __NFTBond_init(
        string calldata _name,
        string calldata _symbol,
        string calldata _baseUri
    )
    internal initializer {
        __NFT_init(_name, _symbol, _baseUri);
    }

    /**
     * @dev Returns updated totalBorrowed
     * @param amount uint256 in wei
     */
    function returnLiquidity(uint256 amount) public payable virtual override returns (uint256) {
        _beforeReturnLiquidity();
        super.returnLiquidity(amount);
        _afterReturnLiquidity(amount);
        return totalBorrowed;
    }

    /**
     * @dev Requests totalBorrowed
     * @param destination address of recipient
     * @param amount uint256 in wei
     */
    function requestLiquidity(address destination, uint256 amount) public override whenNotPaused returns (uint256) {
        _beforeRequestLiquidity(destination, amount);
        super.requestLiquidity(destination, amount);
        return totalBorrowed;
    }

    /**
     * @dev Returns assigned tokenId of the bond
     */
    function _buyBond(
        string calldata tokenUri,
        address beneficiary,
        uint256 maturity,
        uint256 principal,
        bytes32 nftHash,
        bool setApprove,
        uint256 nonce,
        bytes memory signature
    )
    internal returns (uint256) {
        require(msg.sender == beneficiary, "NFTBond::Beneficiary != sender");
        _beforeBondPurchased(tokenUri, beneficiary, maturity, principal);
        uint256 tokenId = _safeMintBySig(tokenUri, beneficiary, nftHash, setApprove, nonce, signature);
        super._issueBond(tokenId, maturity, principal);
        _afterBondPurchased(tokenUri, beneficiary, maturity, principal, tokenId);
        return tokenId;
    }
    
    /**
     * @dev Returns the amunt that corresponds to the bond
     */
    function _redeemBond(uint256 tokenId) internal virtual override returns (uint256) {
        uint256 amount = super._redeemBond(tokenId); 
        address beneficiary = ownerOf(tokenId);
        _afterBondRedeemed(tokenId, amount, beneficiary);
        return amount;
    }
    
    function _beforeBondPurchased(
        string calldata tokenUri,
        address beneficiary,
        uint256 maturity,
        uint256 principal
    ) internal virtual {}

    function _afterBondPurchased(
        string calldata tokenUri,
        address beneficiary,
        uint256 maturity,
        uint256 principal,
        uint256 tokenId
    ) internal virtual {}

    function _beforeBondRedeemed(uint256 tokenId, uint256 value) internal virtual {}

    function _afterBondRedeemed(uint256 tokenId, uint256 value, address beneficiary) internal virtual {}

    function _beforeRequestLiquidity(address destination, uint256 amount) internal virtual {}

    function _afterRequestLiquidity(address destination) internal virtual {}

    function _beforeReturnLiquidity() internal virtual {}

    function _afterReturnLiquidity(uint256 amount) internal virtual {}

    uint256[49] private __gap;
}