// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title Implementation ERC2981 Ethereum NFT Royalty Standard
 * @notice Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *   Implementation based off of OpenZeppelin's ERC2981.sol, with some customization by Real Vision's web3
 *   team. (The customization primarily revolves around simplifying the contract so that royalties are only
 *   set for all tokens in the collection, rather than allowing for specific tokens to have custom royalties.)
 *   Our sincere Affen gratitude to the hard work, and collaborative spirit of both OpenZeppelin and Real Vision.
 *   IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 *   https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are
 *   expected to voluntarily pay royalties together with sales, but note that this standard is not yet
 *   widely supported.
 * @dev The 'Global' word in the name of this contract is there to signify that this contract deliberately does
 *   not implement royalties at the level of each token - it only allows for royalty destination and amount to
 *   be set for ALL tokens in the collection. ALSO NOTE that this contract is IERC2981, and yet, it does not
 *   implement the only function that is required by IERC2981: royaltyInfo(). This task is left to the descendants
 *   of this contract to implement.
 */
abstract contract ERC2981GlobalRoyalties is IERC2981, ERC165 {

    address private _royaltyDestination;
    uint16 private _royaltyInBips;
    uint16 private _bipsBasedFeeDenominator = 10000;
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Function to set the royalty amount using Basis Points.
     * @dev See OpenZeppelin's docuentation for explanation of their choice of basis points and denominator.
     * @param _newRoyaltyInBips is the amount (as basis points) that the royalty will be set to. For
     *   example, make this parameter 200, to set a royalty of 2%)
     */
    function _setRoyaltyAmountInBips(uint16 _newRoyaltyInBips) internal {
        require(_newRoyaltyInBips <= _bipsBasedFeeDenominator, "Royalty fee will exceed salePrice");
        _royaltyInBips = _newRoyaltyInBips;
    }

    /**
     * @notice Function to set the royalty destination.
     * @param _newRoyaltyDestination is the address that royalties should be sent to.
     */
    function _setRoyaltyDestination(address _newRoyaltyDestination) internal {
        _royaltyDestination = _newRoyaltyDestination;
    }


    /**
     * @notice 
     * @dev The two functions below (royaltyInfo() and _globalRoyaltyInfo() offer the developer a
     *   choice of ways to implement the compulsory (to meet the requirements of the Interface of EIP2981)
     *   function called royaltyInfo() in descendant contracts.
     *   (Both options require overriding the royaltyInfo() declaration of this contract.)
     *   1 - the first option is to override royaltyInfo() and implement the contents of the
     *       function (in the child contract) from scratch in whatever way the developer sees fit.
     *   2 - the second option is to override, but instead of implementing from scratch, 
     *       inside the override (in the child), simply call the internal function _globalRoyaltyInfo()
     *       which already has a working implementation coded below.
     *   As for the parameters and return value, please refer to the official documentation of
     *   eip-2981 for the best explanation.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual
        returns (address, uint256);

    /**
     * @notice An internal function that can optionally be used by descendant contracts as a ready-made
     *   way to implement the mandatory royaltyInfo() function. The function calculates where and how
     *   much royalty should be sent based on the current global settings of the collection.
     * @dev A descendant contract, in the implementation of royaltyInfo() can simply call this function
     *   if it suits the intended purposes. HOWEVER please NOTE those contracts
     *   (that inherit from this contract) should make sure that the 'royaltyInfo()' function they
     *   implement includes a 'tokenId' parameter in order to comply with EIP2981.
     *   To understand why (within the function) the denominator is 10,000, please see the definition of
     *   the unambiguous financial term: 'basis points' (bips)
     * @param _salePrice is the price that a token is being sold for. A tokenId is not required for this
     *   function because this implementation of eip-2981 only keeps 'global' settings of royalties
     *   for the collections as whole (rather than keeping settings for individual tokens.)
     * @return two values: 1) the royalty destination, and 2) the royalty amount, as required by eip-2981
     */
    function _globalRoyaltyInfo(uint256 _salePrice)
        internal
        view
        returns (address, uint256)
    {
        uint256 royaltyAmount = (_salePrice * _royaltyInBips) / _bipsBasedFeeDenominator;
        return (_royaltyDestination, royaltyAmount);
    }
}