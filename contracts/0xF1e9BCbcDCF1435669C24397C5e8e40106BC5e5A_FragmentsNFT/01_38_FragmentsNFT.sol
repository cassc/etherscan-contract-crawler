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
    
    function batchMintWithTokenIds(address[] calldata accounts, uint256[] calldata tokenIds, bool useSafeMint) 
        external
        onlyRole(MINTER_ROLE)
    {
        require(accounts.length == tokenIds.length, "mismatched length");
        if (useSafeMint) {
            for (uint256 index = 0; index < accounts.length; index++) {
                _safeMint(accounts[index], tokenIds[index]);
            }
        } else {
            for (uint256 index = 0; index < accounts.length; index++) {
                _mint(accounts[index], tokenIds[index]);
            }
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