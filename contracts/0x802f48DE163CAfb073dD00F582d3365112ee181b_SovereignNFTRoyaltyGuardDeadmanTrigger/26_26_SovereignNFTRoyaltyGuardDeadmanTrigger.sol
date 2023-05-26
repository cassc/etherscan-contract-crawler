// contracts/token/ERC721/sovereign/SovereignNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "royalty-guard/extensions/RoyaltyGuardDeadmanTrigger.sol";

import "../SovereignNFT.sol";

contract SovereignNFTRoyaltyGuardDeadmanTrigger is
    SovereignNFT,
    RoyaltyGuardDeadmanTrigger
{
    /*//////////////////////////////////////////////////////////////////////////
                              ERC165 LOGIC
  //////////////////////////////////////////////////////////////////////////*/

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(SovereignNFT, RoyaltyGuard)
        returns (bool)
    {
        return
            RoyaltyGuard.supportsInterface(_interfaceId) ||
            SovereignNFT.supportsInterface(_interfaceId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          RoyaltyGuard LOGIC
  //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc RoyaltyGuard
    function hasAdminPermission(address _addr)
        public
        view
        virtual
        override(IRoyaltyGuard, RoyaltyGuard)
        returns (bool)
    {
        return _addr == owner();
    }

    /// @dev Guards {approve} based on the type of list and depending if {_spender} is on the list.
    function approve(address _spender, uint256 _id)
        public
        virtual
        override
        checkList(_spender)
    {
        super.approve(_spender, _id);
    }

    /// @dev Guards {setApprovalForAll} based on the type of list and depending if {_operator} is on the list.
    function setApprovalForAll(address _operator, bool _approved)
        public
        virtual
        override
        checkList(_operator)
    {
        super.setApprovalForAll(_operator, _approved);
    }
}