// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./base/BaseCitiNFT.sol";
import "./interfaces/IExplicitTokenIdNFT.sol";

contract FragmentsNFT is BaseCitiNFT, IExplicitTokenIdNFT {    
    uint256[1000] private _gap_;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(NFTContractInitializer memory _initializer, string memory tokenName, string memory tokenSymbol) 
        initializer 
        public 
    {
        __BaseCitiNFT_init(tokenName, tokenSymbol, _initializer);
    }

    /**
     * @dev Mints a token to `to` with explicit tokenId, requires `MINTER_ROLE`
     *
     */
    function mintWithTokenId(address to, uint256 tokenId, bool useSafeMint) 
        external
        override
        onlyRole(MINTER_ROLE) 
    {
        if (useSafeMint) {
            _safeMint(to, tokenId);
        } else {
            _mint(to, tokenId);
        }
    }

    /**
     * @dev The regular safeMint is not allowed
     *
     */
    function safeMint(address /*to*/) 
        public 
        override
        view
        onlyRole(MINTER_ROLE) 
        returns (uint256) 
    {
        revert("safeMint is not allowed");
    }
}