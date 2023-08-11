// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "../libraries/BitMaps/BitMaps.sol";
import "../platform/royalties/IRoyaltiesRegistry.sol";

library ERC721State {
    using BitMaps for BitMaps.BitMap;

    struct Edition {
        // Max. number of token mintable per edition
        uint24 maxSupply;
        // Currently minted token coutner
        uint24 currentSupply;
        // Burned token counter
        uint24 burnedSupply;
        // Public mint price
        uint24 publicMintPriceInFinney;
        // Public mint start time in seconds
        uint32 publicMintStartTS;
        // Public mint ending time in seconds
        uint32 publicMintEndTS;
        // Max mint per wallet. If 0, no limit
        uint8 maxMintPerWallet;
        // If perTokenMetadata == false, all tokens in this edition will have the same metadata
        bool perTokenMetadata;
        // An edition Id associated with this collection that is approved to be burned in order to mint on the current edition.
        uint24 burnableEditionId;
        // Amount to burn
        uint24 amountToBurn;
    }

    struct EditionWithURI {
        Edition data;
        string baseURI;
    }

    /**
     * @dev Storage layout
     * This pattern allow us to extend current contract using DELETGATE_CALL
     * without worrying about storage slot conflicts
     */
    struct ERC721LAState {
        // The number of edition created, indexed from 1
        uint64 _editionCounter;
        // Max token by edition. Defines the number of 0 in token Id (see editions)
        uint24 _edition_max_tokens;
        // Contract Name
        string _name;
        // Ticker
        string _symbol;
        // Edtion by editionId
        mapping(uint256 => Edition) _editions;
        // Owner by tokenId
        mapping(uint256 => address) _owners;
        // Token Id to operator address
        mapping(uint256 => address) _tokenApprovals;
        // Owned token count by address
        mapping(address => uint256) _balances;
        // Allower to allowee
        mapping(address => mapping(address => bool)) _operatorApprovals;
        // Tracking of batch heads
        BitMaps.BitMap _batchHead;
        // LiveArt global royalty registry address
        IRoyaltiesRegistry _royaltyRegistry;
        // Amount of ETH withdrawn by edition
        mapping(uint256 => uint256) _withdrawnBalancesByEdition;
        // EditionID => Base URI
        mapping(uint256 => string) _baseURIByEdition;
        // Minted counter per wallet/edition. hash(address, editionId) => counter
        mapping(uint256 => uint256) _mintedPerWallet;
        // xCardContract Address
        address _xCardContractAddress;
    }

    /**
     * @dev Get storage data from dedicated slot.
     * This pattern avoids storage conflict during proxy upgrades
     * and give more flexibility when creating extensions
     */
    function _getERC721LAState()
        internal
        pure
        returns (ERC721LAState storage state)
    {
        bytes32 storageSlot = keccak256("liveart.ERC721LA");
        assembly {
            state.slot := storageSlot
        }
    }
}