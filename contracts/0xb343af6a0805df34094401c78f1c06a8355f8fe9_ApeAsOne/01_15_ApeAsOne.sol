// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./NFTCollection/extensions/NFTCollectionRoyalties.sol";
import "./NFTCollection/extensions/NFTCollectionReservedMint.sol";
import "./NFTCollection/extensions/NFTCollectionPausableMint.sol";
import "./NFTCollection/extensions/NFTCollectionMutableParams.sol";
import "./NFTCollection/extensions/NFTCollectionLimitPerAccount.sol";

contract ApeAsOne is
    NFTCollectionRoyalties,
    NFTCollectionReservedMint,
    NFTCollectionPausableMint,
    NFTCollectionMutableParams,
    NFTCollectionLimitPerAccount
{
    constructor()
        NFTCollection(
            "APE as ONE", // Name
            "AAS1", // Symbol
            "ipfs://QmXDnfXsUEyCWRh2HrJcSaY5fBFfGEBRkJMbk8ARE5fpr2/", // Base URI
            0.01945 ether, // Cost to mint
            3999, // Max supply
            5, // Max mint amount per tx
            0x2BF55Adc508aB14E3e1936A8861D0B5cEEE83aA6 // Contract owner
        )
        NFTCollectionLimitPerAccount(5) // Total mint amount per wallet
        NFTCollectionReservedMint(100) // For the team
        NFTCollectionRoyalties(0x308b6BEF34c0b9cf147A407C7aB3249beB7837f3, 500) // 5% royalties
    {
        revealed = true; // Instant reveal
        pausedMint = true; // Delayed mint start
    }

    function _mintAmount(uint256 _amount)
        internal
        override(
            NFTCollection,
            NFTCollectionPausableMint,
            NFTCollectionLimitPerAccount,
            NFTCollectionReservedMint
        )
        whenNotPaused
        whenAccountLimitNotExceeded(_amount)
    {
        NFTCollectionReservedMint._mintAmount(_amount);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721A, NFTCollectionRoyalties)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }
}