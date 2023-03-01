// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./base/BaseCitiNFT.sol";

contract CitiCharacter is BaseCitiNFT {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(NFTContractInitializer memory _initializer) 
        initializer 
        public 
    {
        __BaseCitiNFT_init("CitiCharacter", "CTC", _initializer);
    }
}