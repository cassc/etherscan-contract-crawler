// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Rocketeer
 * Rocketeer - a contract for my non-fungible rocketeers
 */
contract Rocketeer is ERC721Tradable {

    // ///////////////////////////////
    // Globals
    // ///////////////////////////////

    // Max supply is the diameter of the moon in KM
    uint256 private ROCKETEER_MAX_SUPPLY = 3475;

    // Construct as Opensea tradable item
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Rocketeer", "RCT", _proxyRegistryAddress)
    {

        // Birth the genesis Rocketeers
        spawnRocketeer( owner() );
        
    }

    // ///////////////////////////////
    // Oracles
    // ///////////////////////////////

    // TODO: add Api data
    // https://docs.opensea.io/docs/metadata-standards
    function baseTokenURI() override public pure returns (string memory) {
        // return "https://rocketeer.fans/testnetapi/rocketeer/";
        return "https://rocketeer.fans/api/rocketeer/";
    }

    // TODO: add API link
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public pure returns (string memory) {
        // return "https://rocketeer.fans/testnetapi/collection/";
        return "https://rocketeer.fans/api/rocketeer/";
    }

    // ///////////////////////////////
    // Minting
    // ///////////////////////////////

    function spawnRocketeer( address _to ) public {

        uint256 nextTokenId = _getNextTokenId();

        // Every 42nd unit becomes a special edition, gas fees paid for but not owned by the minter
        if( nextTokenId % 42 == 0 ) {
            mintTo( owner() );
        }

        // No more than max supply
        require( nextTokenId <= ROCKETEER_MAX_SUPPLY, "Maximum Rocketeer supply reached" );

        mintTo( _to );
    }

}