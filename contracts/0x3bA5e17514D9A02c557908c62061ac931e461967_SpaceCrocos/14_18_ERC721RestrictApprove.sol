// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "ERC721A/ERC721A.sol";
import "./IERC721RestrictApprove.sol";
import "./IContractAllowListProxy.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

/// @title AntiScam機能付きERC721トークン

abstract contract ERC721RestrictApprove is ERC721A, IERC721RestrictApprove {
    using EnumerableSet for EnumerableSet.AddressSet;

    IContractAllowListProxy public CAL;
    EnumerableSet.AddressSet localAllowedAddresses;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) {}

    // contract lock
    uint256 public CALLevel = 1;

    /*///////////////////////////////////////////////////////////////
    Approve抑制機能ロジック
    //////////////////////////////////////////////////////////////*/
    function _addLocalContractAllowList(address transferer) internal virtual {
        localAllowedAddresses.add(transferer);
        emit LocalCalAdded(msg.sender, transferer);
    }

    function _removeLocalContractAllowList(
        address transferer
    ) internal virtual {
        localAllowedAddresses.remove(transferer);
        emit LocalCalRemoved(msg.sender, transferer);
    }

    function _getLocalContractAllowList()
        internal
        view
        virtual
        returns (address[] memory)
    {
        return localAllowedAddresses.values();
    }

    function _isLocalAllowed(
        address transferer
    ) internal view virtual returns (bool) {
        return localAllowedAddresses.contains(transferer);
    }

    function _isAllowed(
        address transferer,
        uint256 level
    ) internal view virtual returns (bool) {
        if (address(CAL).code.length > 0) {
            return
                _isLocalAllowed(transferer) || CAL.isAllowed(transferer, level);
        } else {
            return true;
        }
    }

    function _setCAL(address _cal) internal virtual {
        CAL = IContractAllowListProxy(_cal);
    }

    /*///////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _beforeApprove(operator);
        super.setApprovalForAll(operator, approved);
    }

    function _beforeApprove(address to) internal virtual {
        if (to != address(0)) {
            require(
                _isAllowed(to, CALLevel),
                "RestrictApprove: The contract is not allowed."
            );
        }
    }

    function approve(
        address to,
        uint256 tokenId
    ) public payable virtual override {
        _beforeApprove(to);
        super.approve(to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721RestrictApprove).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}