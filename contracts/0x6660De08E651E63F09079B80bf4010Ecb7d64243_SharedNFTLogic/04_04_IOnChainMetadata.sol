// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOnChainMetadata {
  /// @notice Lyrics updated for this edition
  event SongUpdated(
    address target,
    address sender,
    SongMetadata songMetadata,
    ProjectMetadata projectMetadata,
    string[] tags,
    Credit[] credits
  );

  /// @notice AudioQuantitativeUpdated updated for this edition
  /// @dev admin function indexer feedback
  event AudioQuantitativeUpdated(
    address indexed target,
    address sender,
    string key,
    uint256 bpm,
    uint256 duration,
    string audioMimeType,
    uint256 trackNumber
  );

  /// @notice AudioQualitative updated for this edition
  /// @dev admin function indexer feedback
  event AudioQualitativeUpdated(
    address indexed target,
    address sender,
    string license,
    string externalUrl,
    string isrc,
    string genre
  );

  /// @notice Lyrics updated for this edition
  event LyricsUpdated(
    address target,
    address sender,
    string lyrics,
    string lyricsNft
  );

  /// @notice Artwork updated for this edition
  /// @dev admin function indexer feedback
  event ArtworkUpdated(
    address indexed target,
    address sender,
    string artworkUri,
    string artworkMimeType,
    string artworkNft
  );

  /// @notice Visualizer updated for this edition
  /// @dev admin function indexer feedback
  event VisualizerUpdated(
    address indexed target,
    address sender,
    string artworkUri,
    string artworkMimeType,
    string artworkNft
  );

  /// @notice ProjectMetadata updated for this edition
  /// @dev admin function indexer feedback
  event ProjectArtworkUpdated(
    address indexed target,
    address sender,
    string artworkUri,
    string artworkMimeType,
    string artworkNft
  );

  /// @notice Tags updated for this edition
  /// @dev admin function indexer feedback
  event TagsUpdated(address indexed target, address sender, string[] tags);

  /// @notice Credit updated for this edition
  /// @dev admin function indexer feedback
  event CreditsUpdated(
    address indexed target,
    address sender,
    Credit[] credits
  );

  /// @notice ProjectMetadata updated for this edition
  /// @dev admin function indexer feedback
  event ProjectPublishingDataUpdated(
    address indexed target,
    address sender,
    string title,
    string description,
    string recordLabel,
    string publisher,
    string locationCreated,
    string releaseDate,
    string projectType,
    string upc
  );

  /// @notice PublishingData updated for this edition
  /// @dev admin function indexer feedback
  event PublishingDataUpdated(
    address indexed target,
    address sender,
    string title,
    string description,
    string recordLabel,
    string publisher,
    string locationCreated,
    string releaseDate
  );

  /// @notice losslessAudio updated for this edition
  /// @dev admin function indexer feedback
  event LosslessAudioUpdated(
    address indexed target,
    address sender,
    string losslessAudio
  );

  /// @notice Description updated for this edition
  /// @dev admin function indexer feedback
  event DescriptionUpdated(
    address indexed target,
    address sender,
    string newDescription
  );

  /// @notice Artist updated for this edition
  /// @dev admin function indexer feedback
  event ArtistUpdated(address indexed target, address sender, string newArtist);

  /// @notice Event for updated Media URIs
  event MediaURIsUpdated(
    address indexed target,
    address sender,
    string imageURI,
    string animationURI
  );

  /// @notice Event for a new edition initialized
  /// @dev admin function indexer feedback
  event EditionInitialized(
    address indexed target,
    string description,
    string imageURI,
    string animationURI
  );

  /// @notice Storage for SongMetadata
  struct SongMetadata {
    SongContent song;
    PublishingData songPublishingData;
  }

  /// @notice Storage for SongContent
  struct SongContent {
    Audio audio;
    Artwork artwork;
    Artwork visualizer;
  }

  /// @notice Storage for SongDetails
  struct SongDetails {
    string artistName;
    AudioQuantitative audioQuantitative;
    AudioQualitative audioQualitative;
  }

  /// @notice Storage for Audio
  struct Audio {
    string losslessAudio; // ipfs://{cid} or arweave
    SongDetails songDetails;
    Lyrics lyrics;
  }

  /// @notice Storage for AudioQuantitative
  struct AudioQuantitative {
    string key; // C / A# / etc
    uint256 bpm; // 120 / 60 / 100
    uint256 duration; // 240 / 60 / 120
    string audioMimeType; // audio/wav
    uint256 trackNumber; // 1
  }

  /// @notice Storage for AudioQualitative
  struct AudioQualitative {
    string license; // CC0
    string externalUrl; // Link to your project website
    string isrc; // CC-XXX-YY-NNNNN
    string genre; // Rock / Pop / Metal / Hip-Hop / Electronic / Classical / Jazz / Folk / Reggae / Other
  }

  /// @notice Storage for Artwork
  struct Artwork {
    string artworkUri; // The uri of the artwork (ipfs://<CID>)
    string artworkMimeType; // The mime type of the artwork
    string artworkNft; // The NFT of the artwork (caip19)
  }

  /// @notice Storage for Lyrics
  struct Lyrics {
    string lyrics;
    string lyricsNft;
  }

  /// @notice Storage for PublishingData
  struct PublishingData {
    string title;
    string description;
    string recordLabel; // Sony / Universal / etc
    string publisher; // Sony / Universal / etc
    string locationCreated;
    string releaseDate; // 2020-01-01
  }

  /// @notice Storage for ProjectMetadata
  struct ProjectMetadata {
    PublishingData publishingData;
    Artwork artwork;
    string projectType; // Single / EP / Album
    string upc; // 03600029145
  }

  /// @notice Storage for Credit
  struct Credit {
    string name;
    string collaboratorType;
  }
}