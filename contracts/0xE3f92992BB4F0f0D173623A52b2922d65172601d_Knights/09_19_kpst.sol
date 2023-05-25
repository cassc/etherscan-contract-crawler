// SPDX-License-Identifier: MIT

// Knights Presale Ticket 
pragma solidity ^0.8.6;

abstract contract Kpst {
    function balanceOf(address account)
        public
        view
        virtual
        returns (uint256);
    
    function burnForRedemption(uint256 tokenId) external virtual;

    function walletOfOwner(address _owner)
        external
        view
        virtual
        returns (uint256[] memory);
}