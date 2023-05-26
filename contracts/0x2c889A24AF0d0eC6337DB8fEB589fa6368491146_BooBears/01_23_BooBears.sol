// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ERC721Essentials} from "ERC721Essentials.sol";
import {ERC721EssentialsWithdrawable} from "ERC721EssentialsWithdrawable.sol";
import {ERC721ClaimFromContracts} from "ERC721ClaimFromContracts.sol";
import {BaseErrorCodes} from "ErrorCodes.sol";

//=====================================================================================================================
/// 😈 OOGA BOOGA SPOOKY BEARA 😈
//=====================================================================================================================

contract BooBears is ERC721EssentialsWithdrawable, ERC721ClaimFromContracts {
    //=================================================================================================================
    /// State Variables
    //=================================================================================================================

    mapping(address => bool) internal hasMinted;
    string private constant kErrOnlyMintOne = "Only allowed to Mint 1 Boo Bear"; /* solhint-disable-line */

    //=================================================================================================================
    /// Constructor
    //=================================================================================================================

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256[] memory uintArgs_,
        bool publicMintingEnabled_,
        address[] memory contractAddrs_,
        uint16 maxForPurchase_,
        uint16 maxForClaim_
    )
        ERC721EssentialsWithdrawable(name_, symbol_, baseURI_, uintArgs_, publicMintingEnabled_)
        ERC721ClaimFromContracts(contractAddrs_, maxForPurchase_, maxForClaim_)
    {
        return;
    }

    //=================================================================================================================
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
        override(ERC721ClaimFromContracts, ERC721Essentials)
        limitToOneMint
    {
        super.mint(numMint); // ERC721ClaimFromContracts.sol, ERC721Essentials.sol
    }

    /**
     * @dev Modifier to limit the number of mints to one per user.
     */
    modifier limitToOneMint() {
        require(!hasMinted[_msgSender()], kErrOnlyMintOne);
        hasMinted[_msgSender()] = true;
        _;
    }
}