// SPDX-License-Identifier: MIT
// Built for Shellz Orb by megsdevs
pragma solidity ^0.8.16;

import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "operator-filter-registry/src/IOperatorFilterRegistry.sol";
import "./ShellzOrb.sol";


contract ShellzOrbV2 is ShellzOrb, DefaultOperatorFiltererUpgradeable {

    /**
     *  @notice disable initialization of the implementation contract so connot bypass the proxy.
    */  
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     *  @notice reinitializer allows initialisation on upgrade, in this case for version 2.
     */ 
    function initializeV2() public reinitializer(2) {
        __DefaultOperatorFilterer_init();
    }

    /**
     *  @notice Operator filterer requires exchanges to enforce creator royalties to not be blacklisted 
     *          for approve and transfer functions.
     *          https://github.com/ProjectOpenSea/operator-filter-registry
     */   
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ShellzOrb)
        returns (bool)
    {
        return
            interfaceId == type(IOperatorFilterRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}