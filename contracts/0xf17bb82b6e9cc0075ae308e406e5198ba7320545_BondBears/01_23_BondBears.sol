// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ERC721BasicMint} from "../erc721/presets/ERC721BasicMint.sol";

//=====================================================================================================================
/// 🐻 ( ♥‿♥) OOGA BOOGA BONGA BEARA ( ♥‿♥) 🐻
//=====================================================================================================================

contract BondBears is ERC721BasicMint {

    mapping(address => uint8) internal hasMinted;
    
    //=================================================================================================================
    /// Constructor
    //=================================================================================================================

    constructor(string memory baseURI_, string memory contractURI_)
        ERC721BasicMint(
            "Bond Bears",
            "BEARS",
            baseURI_,
            contractURI_
        ) {
            // Set some variables here to prevent stack too deep error.
            maxSupply = 126;
            priceInWei = uint256(694200000000000000); /* 0.6942 eth */
            maxMintPerTx = 1;
            launchTime = 0;
            publicMintingEnabled = false;
        }

    //======================== =========================================================================================
    /// Minting Functionality
    //=================================================================================================================

    /**
    * @dev Public function that mints a specified number of ERC721 tokens.
    * @param numMint uint16: The number of tokens that are going to be minted.
    */
    function mint(uint16 numMint)
        public
        payable
        virtual
        override
        nonReentrant
        limitToOneMint
        whenPublicMintingOpen
        whenNotPaused
        opensAt(launchTime, "Minting has not started yet")
        costs(numMint, priceInWei)
    {
        _mint(numMint);
    }

    /**
    * @dev Modifier to limit the number of mints to one per user.
    */
    modifier limitToOneMint() {
        require(hasMinted[_msgSender()] == 0, "Only allowed to Mint 1 Bond Bear");
        hasMinted[_msgSender()] = 1;
        _;
    }
}