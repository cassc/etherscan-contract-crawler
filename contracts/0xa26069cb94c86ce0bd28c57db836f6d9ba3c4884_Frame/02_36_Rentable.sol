//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interface/IRentable.sol";

abstract contract Rentable is IRentable {
    mapping(uint256 => uint256) public _rentalPrices;
    mapping(uint256 => Rental) private _renters;

    function setRenter(
        uint256 _tokenId,
        address _renter,
        uint256 _numberOfBlocks
    ) external payable virtual override;

    function _setRenter(
        uint256 _tokenId,
        address _renter,
        uint256 _numberOfBlocks
    ) internal {
        Rental storage rental = _renters[_tokenId];
        rental.renter = _renter;
        rental.rentalExpiryBlock = block.number + _numberOfBlocks;
        emit RenterSet(_tokenId, rental.renter, rental.rentalExpiryBlock);
    }

    function getRenter(uint256 _tokenId) external view override returns (Rental memory) {
        return _getRenter(_tokenId);
    }

    function _getRenter(uint256 _tokenId) internal view returns (Rental memory) {
        return _renters[_tokenId];
    }

    function isCurrentlyRented(uint256 _tokenId) external view override returns (bool) {
        return _isCurrentlyRented(_tokenId);
    }

    function _isCurrentlyRented(uint256 _tokenId) internal view returns (bool) {
        Rental memory tokenRental = _renters[_tokenId];
        return tokenRental.rentalExpiryBlock > block.number;
    }

    function tokenIsRentedByAddress(uint256 _tokenId, address _address)
        external
        view
        virtual
        override
        returns (bool)
    {
        return _tokenIsRentedByAddress(_tokenId, _address);
    }

    function _tokenIsRentedByAddress(uint256 _tokenId, address _address)
        internal
        view
        returns (bool)
    {
        Rental memory tokenRental = _getRenter(_tokenId);
        return tokenRental.renter == _address;
    }

    function setRentalPricePerBlock(uint256 _tokenId, uint256 _rentalPrice)
        external
        virtual
        override;

    function _setRentalPricePerBlock(uint256 _tokenId, uint256 _rentalPrice) internal {
        _rentalPrices[_tokenId] = _rentalPrice;
    }

    function getRentalPricePerBlock(uint256 _tokenId) external view override returns (uint256) {
        return _getRentalPricePerBlock(_tokenId);
    }

    function _getRentalPricePerBlock(uint256 _tokenId) internal view returns (uint256) {
        return _rentalPrices[_tokenId];
    }

    function calculateRentalCost(uint256 _tokenId, uint256 _numberOfBlocks)
        external
        view
        override
        returns (uint256)
    {
        return _getRentalPricePerBlock(_tokenId) * _numberOfBlocks;
    }
}