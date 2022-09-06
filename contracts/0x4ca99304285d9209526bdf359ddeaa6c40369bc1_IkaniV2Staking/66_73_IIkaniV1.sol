// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IIkaniV1
 * @author Cyborg Labs, LLC
 *
 * @notice Interface for the IkaniV1 ERC-721 NFT contract.
 */
interface IIkaniV1 {

    //---------------- Enums ----------------//

    enum Theme {
        NULL,
        SKY,
        OCEAN,
        MOUNTAIN,
        FLOWERS,
        TBA_THEME_5,
        TBA_THEME_6,
        TBA_THEME_7,
        TBA_THEME_8
    }

    enum Season {
        NONE,
        SPRING,
        SUMMER,
        AUTUMN,
        WINTER
    }

    enum Fabric {
        NULL,
        KOYAMAKI,
        SEIGAIHA,
        NAMI,
        KUMO,
        TBA_FABRIC_5,
        TBA_FABRIC_6,
        TBA_FABRIC_7,
        TBA_FABRIC_8
    }

    enum Foil {
        NONE,
        GOLD,
        PLATINUM,
        SUI_GENERIS
    }

    //---------------- Structs ----------------//

    /**
     * @notice The poem text and metadata traits.
     */
    // TODO: Make sure these fields are packed efficiently.
    struct Poem {
        string poemText;
        Theme theme;
        Season season;
        Fabric fabric;
        Foil foil;
    }

    /**
     * @notice Information about a series within the collection.
     */
    struct Series {
        string name;
        bytes32 provenanceHash;
        uint256 poemCreationDeadline;
        uint256 maxTokenIdExclusive;
        uint256 startingIndexBlockNumber;
        uint256 startingIndex;
        bool startingIndexWasSet;
    }

    /**
     * @notice Arguments to be signed by the mint authority to authorize a mint.
     */
    struct MintArgs {
        uint256 seriesIndex;
        uint256 mintPrice;
        uint256 maxTokenIdExclusive;
        uint256 nonce;
    }

    //---------------- Events ----------------//

    event SetSeriesInfo(
        uint256 indexed seriesIndex,
        string name,
        bytes32 provenanceHash
    );

    event EndedSeries(
        uint256 indexed seriesIndex,
        uint256 poemCreationDeadline,
        uint256 maxTokenIdExclusive,
        uint256 startingIndexBlockNumber
    );

    event AdvancedPoemCreationDeadline(
        uint256 indexed seriesIndex,
        uint256 poemCreationDeadline
    );

    event ResetSeriesStartingIndexBlockNumber(
        uint256 indexed seriesIndex,
        uint256 startingIndexBlockNumber
    );

    event SetSeriesStartingIndex(
        uint256 indexed seriesIndex,
        uint256 startingIndex
    );
}