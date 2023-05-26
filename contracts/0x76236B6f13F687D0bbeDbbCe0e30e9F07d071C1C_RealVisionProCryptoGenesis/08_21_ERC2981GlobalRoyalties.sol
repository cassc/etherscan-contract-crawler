// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 * Implementation based off of OpenZeppelin's ERC2981.sol, with significant customization.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 */
 
abstract contract ERC2981GlobalRoyalties is IERC2981, ERC165 {
    // The 'Global' word in the name of this contract is there to signify
    // that this contract deliberately does not implement royalties at the level of
    // each token - it only allows for royalty destination and amount to be set
    // for ALL tokens in the collection.
    // NOTE that this contract is IERC2981, and yet, it does not implement the only function
    // that is required by IERC2981: royaltyInfo(). This task is left to the descendants
    // of this contract to implement.

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

    function _setRoyaltyAmountInBips(uint16 _newRoyaltyInBips) internal {
        require(_newRoyaltyInBips <= _bipsBasedFeeDenominator, "Royalty fee will exceed salePrice");
        _royaltyInBips = _newRoyaltyInBips;
    }

    function _setRoyaltyDestination(address _newRoyaltyDestination) internal {
        _royaltyDestination = _newRoyaltyDestination;
    }

    /**
    * @dev The two functions below this comment offer the developer a choice of 
    * ways to implement the compulsory (to meet the requirements of the Interface of EIP2981) 
    * function called royaltyInfo()
    * (Both options require overriding the royaltyInfo() declaration of this contract.)
    * 1 - the first option is to override royaltyInfo() and implement the contents of the
    *     function (in the child contract) from scratch in whatever way the developer sees fit.
    * 2 - the second option is to override, but instead of implementing from scratch, 
    *     inside the override (in the child), simply call the internal function _globalRoyaltyInfo()
    *     which already has a working implementation coded below.
    */

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual
        returns (address, uint256);

    function _globalRoyaltyInfo(uint256 _salePrice)
    // Note that most implementations of 'royaltyInfo' also have a 'tokenId' parameter.
    // Because this contract is implementing royalties at the global level only, this parameter is not
    // neeeded here. Descendent contracts, can make use of this function to easily implement
    // royaltyInfo(), however, those contracts (that inherit from this contract) should make sure that
    // the 'royaltyInfo' function they implement has the 'tokenId' parameter in order to comply with
    // EIP2981
        internal
        view
        returns (address, uint256)
    {
        // To understand why the denominator is 10,000 see the definition of
        // the unambiguous financial term: 'basis points' (bips)
        uint256 royaltyAmount = (_salePrice * _royaltyInBips) / _bipsBasedFeeDenominator;
        return (_royaltyDestination, royaltyAmount);
    }
}