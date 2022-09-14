// MergeBears
// Shuffle Labs
// 2022.09.13

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// External
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// For easy linking in constructor
import "./lib_env/Mainnet.sol";

// Internal Extensions
import "./extensions/Owner.sol";

// Utilities & Constants
import "./lib_constants/TraitDefs.sol";
import "./lib_utilities/Gene.sol";

// errors
error ExceedsMaxMintQuantity();
error ExceedsMaxSupply();
error EthValueTooLow();
error TeamMintingDisabled();
error InvalidEthereumValue();
error OriginNotSender();
error QuantityExceedsMaxSupply();
error QuantityExceedsMaxPerMint();
error InvalidMerkleProof();
error MintingInProgress();
error MaximumMintedPerWallet();
error ProofModeNotPOS();
error MintModeInactive();
error MintModeBWLSingleOnly();
error MintModeBWLOnly();
error MintModeSaleComplete();
error PurgeModeInactive();
error PurgeModeComplete();
error PurgeModeNotComplete();
error InvalidQuantity();
error NotAPanda();
error UnableToSendValue();
error NotBlackAndWhite();

library GeneOptionsSpecies {
  uint16 constant BLACK = 1;
  uint16 constant POLAR = 2;
  uint16 constant PANDA = 3;
  uint16 constant REVERSE_PANDA = 4;
  uint16 constant GOLD_PANDA = 5;
}

library ProofMode {
  uint8 public constant POW = 0;
  uint8 public constant POS = 1;
}

library MintMode {
  uint8 public constant INACTIVE = 0;
  uint8 public constant SINGLE_BW_LIST = 1;
  uint8 public constant UNLTD_BW_LIST = 2;
  uint8 public constant PUBLIC_SALE = 3;
  uint8 public constant COMPLETE = 4;
}

library PurgeMode {
  uint8 public constant INACTIVE = 0;
  uint8 public constant BW_LIST_FULL = 1;
  uint8 public constant BW_PARTIAL = 2;
  uint8 public constant COMPLETE = 3;
}

library PurgeRebate {
  uint8 public constant BW_LIST_PERCENTAGE = 100;
  uint8 public constant PUBLIC_PERCENTAGE = 75;
}

library Settings {
  uint256 public constant MAX_SUPPLY = 5875;
  uint256 public constant MAX_PRICE = 0.05875 ether;
  uint256 public constant STARTING_PRICE = 0.005875 ether;
  uint256 public constant INCREMENT_PRICE = 0.0005875 ether;
  uint256 public constant BEGIN_INCREMENTS_AT = 875;
  uint256 public constant INCREMENT_STEP = 50;
  uint256 public constant MAX_TEAM_MINT = 250;
  uint256 public constant MAX_MINT_QUANTITY = 5;
}

interface IMetadataUtility {
  function getMetadataFromDNA(uint256 dna, uint256 tokenId)
    external
    view
    returns (string memory);
}

interface IContractURIUtility {
  function getContractURI() external view returns (string memory);
}

contract MergeBears is ERC721A, Owner {
  using Strings for uint256;

  // !!! IMPORTANT STATE MODES !!!
  uint8 public proofMode = ProofMode.POW;
  uint8 public mintMode = MintMode.INACTIVE;
  uint8 public purgeMode = PurgeMode.INACTIVE;

  // !!! IMPORTANT STATE VARIABLES !!!
  uint256 public numMintedByTeam = 0;
  // Mark the last token id that was minted as white/black bear
  uint256 public lastPOWTokenId = Settings.MAX_SUPPLY;

  // Pseudo Randomness
  uint256 public randomNumber =
    112251241738492409971660691241763937113569996400635104450295902338183133602781; // default random

  // DNA container
  mapping(uint256 => uint256) public tokenIdToDNA;
  mapping(uint256 => uint32) public forebears;

  // Metadata Resolver Contract
  address metadataUtility;
  address contractUtility;

  // Merkle / BW List
  bytes32 public merkleRoot;

  constructor() ERC721A("Merge Bears", "MRGBEARS") {
    _owner = msg.sender;

    metadataUtility = Mainnet.Metadata;
  }

  // OWNER ONLY METHODS
  function setMetadataUtility(address metadataContract) external onlyOwner {
    metadataUtility = metadataContract;
  }

  function setContractURI(address contractURIUtility_) external onlyOwner {
    contractUtility = contractURIUtility_;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setProofMode(uint8 mode) external onlyOwner {
    if (mode == ProofMode.POW) {
      proofMode = ProofMode.POW;
    } else if (mode == ProofMode.POS) {
      // DISABLE ALL MINTING
      mintMode = MintMode.COMPLETE;
      lastPOWTokenId = totalSupply();
      proofMode = ProofMode.POS;
    }
  }

  function setMintMode(uint8 mode) external onlyOwner {
    if (mode == MintMode.INACTIVE) {
      mintMode = MintMode.INACTIVE;
    } else if (mode == MintMode.SINGLE_BW_LIST) {
      mintMode = MintMode.SINGLE_BW_LIST;
    } else if (mode == MintMode.UNLTD_BW_LIST) {
      mintMode = MintMode.UNLTD_BW_LIST;
    } else if (mode == MintMode.PUBLIC_SALE) {
      mintMode = MintMode.PUBLIC_SALE;
    } else if (mode == MintMode.COMPLETE) {
      mintMode = MintMode.COMPLETE;
    }
  }

  function setPurgeMode(uint8 mode) external onlyOwner {
    if (mode == PurgeMode.INACTIVE) {
      purgeMode = PurgeMode.INACTIVE;
    } else if (mode == PurgeMode.BW_LIST_FULL) {
      purgeMode = PurgeMode.BW_LIST_FULL;
    } else if (mode == PurgeMode.BW_PARTIAL) {
      purgeMode = PurgeMode.BW_PARTIAL;
    } else if (mode == PurgeMode.COMPLETE) {
      purgeMode = PurgeMode.COMPLETE;
    }
  }

  // Price Check Aisle 3!
  function getPriceById(uint256 id) public view returns (uint256) {
    // free mints
    if (id <= numMintedByTeam) {
      return 0;
    }

    // mints after move to POS are not redeemable
    if (id > lastPOWTokenId) {
      return 0;
    }

    // first BEGIN_INCREMENTS_AT are STARTING_PRICe
    if (id < Settings.BEGIN_INCREMENTS_AT) {
      return Settings.STARTING_PRICE;
    }

    uint256 beginIncrementsDifference = id - Settings.BEGIN_INCREMENTS_AT;

    uint256 calculatedPrice = Settings.STARTING_PRICE +
      Settings.INCREMENT_PRICE *
      (beginIncrementsDifference / Settings.INCREMENT_STEP);

    if (calculatedPrice > Settings.MAX_PRICE) {
      return Settings.MAX_PRICE;
    }

    return calculatedPrice;
  }

  // PUBLIC MINT METHODS
  function whitelistMint(uint64 quantity, bytes32[] calldata merkleProof)
    external
    payable
  {
    // VALIDATE SALE HAS STARTED
    if (mintMode == MintMode.INACTIVE) {
      revert MintModeInactive();
    }
    if (mintMode == MintMode.COMPLETE) {
      revert MintModeSaleComplete();
    }
    if (mintMode == MintMode.SINGLE_BW_LIST && quantity > 1) {
      revert MintModeBWLSingleOnly();
    }
    if (mintMode == MintMode.SINGLE_BW_LIST && _numberMinted(msg.sender) > 0) {
      revert MintModeBWLSingleOnly();
    }
    if (quantity > Settings.MAX_MINT_QUANTITY) {
      revert QuantityExceedsMaxPerMint(); // 5
    }

    if (
      !MerkleProof.verify(
        merkleProof,
        merkleRoot,
        keccak256(abi.encodePacked(msg.sender))
      )
    ) {
      revert InvalidMerkleProof();
    }

    // check price of max token given quantity
    uint256 highestId = _nextTokenId() + (quantity - 1);
    uint256 price = getPriceById(highestId);

    if (msg.value < price * quantity) {
      revert EthValueTooLow();
    }

    internalMint(quantity);
  }

  function mint(uint256 quantity) external payable {
    if (mintMode != MintMode.PUBLIC_SALE) {
      revert MintModeInactive();
    }

    if (quantity > Settings.MAX_MINT_QUANTITY) {
      revert QuantityExceedsMaxPerMint(); // 5
    }

    // check price of max token given quantity
    uint256 highestId = _nextTokenId() + (quantity - 1);
    uint256 price = getPriceById(highestId);

    if (msg.value < price * quantity) {
      revert EthValueTooLow();
    }

    internalMint(quantity);
  }

  function teamMint(uint256 quantity) external onlyOwner {
    if (quantity + numMintedByTeam > Settings.MAX_TEAM_MINT) {
      revert TeamMintingDisabled();
    }
    // team can only mint initially
    if (mintMode != MintMode.INACTIVE) {
      revert TeamMintingDisabled();
    }

    numMintedByTeam += quantity;

    internalMint(quantity);
  }

  function rollForDNA(uint256 offset) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encode(
            msg.sender,
            randomNumber,
            _nextTokenId(),
            offset,
            block.number,
            block.timestamp
          )
        )
      );
  }

  function rollForBlackOrPolar(uint256 offset) internal view returns (uint16) {
    // flip a coin for black or polar, return the correct gene
    uint256 roll = uint256(
      keccak256(
        abi.encode(
          randomNumber,
          totalSupply(),
          offset,
          block.number,
          msg.sender,
          block.timestamp
        )
      )
    );

    if (roll % 2 == 0) {
      return GeneOptionsSpecies.BLACK;
    }

    return GeneOptionsSpecies.POLAR;
  }

  function rollForPandaSpecies() internal view returns (uint16) {
    // run the odds for gold, reverse, or regular panda
    uint256 roll = uint256(
      keccak256(
        abi.encode(
          randomNumber,
          totalSupply(),
          block.number,
          msg.sender,
          block.timestamp
        )
      )
    );

    if (roll % 111 == 0) {
      return GeneOptionsSpecies.GOLD_PANDA;
    } else if (roll % 111 < 11) {
      return GeneOptionsSpecies.REVERSE_PANDA;
    }

    return GeneOptionsSpecies.PANDA;
  }

  function internalMint(uint256 quantity) internal {
    if (quantity == 0) {
      revert InvalidQuantity();
    }
    if (tx.origin != msg.sender) {
      revert OriginNotSender();
    }
    if (_totalMinted() + quantity > Settings.MAX_SUPPLY) {
      revert QuantityExceedsMaxSupply();
    }

    // set DNA for each mint
    for (uint i = 0; i < quantity; i++) {
      uint256 dna = rollForDNA(i);
      uint16 species = rollForBlackOrPolar(i);
      uint256 normalizedDNA = Gene.setSpecies(species, dna);

      tokenIdToDNA[_nextTokenId() + i] = normalizedDNA;
    }

    _mint(msg.sender, quantity);
  }

  function merge(uint256 blackForebear, uint256 polarForebear) external {
    if (tx.origin != msg.sender) {
      revert OriginNotSender();
    }

    if (_totalMinted() + 1 > Settings.MAX_SUPPLY) {
      revert QuantityExceedsMaxSupply();
    }

    if (proofMode != ProofMode.POS) {
      revert ProofModeNotPOS();
    }

    if (mintMode != MintMode.COMPLETE) {
      revert MintingInProgress();
    }

    uint256 blackForebearDNA = tokenIdToDNA[blackForebear];
    uint256 polarForebearDNA = tokenIdToDNA[polarForebear];

    if (
      Gene.getSpeciesGene(blackForebearDNA) != GeneOptionsSpecies.BLACK ||
      Gene.getSpeciesGene(polarForebearDNA) != GeneOptionsSpecies.POLAR
    ) {
      revert NotBlackAndWhite();
    }

    // burn forebearA
    _burn(blackForebear, true);
    // burn forebearB
    _burn(polarForebear, true);

    forebears[_nextTokenId()] = getCompressedForebearIds(
      blackForebear,
      polarForebear
    );

    // _mint a panda
    // set DNA for panda
    uint256 dna = rollForDNA(5785);
    uint16 species = rollForPandaSpecies();
    uint256 normalizedDNA = Gene.setSpecies(species, dna);

    tokenIdToDNA[_nextTokenId()] = normalizedDNA;
    _mint(msg.sender, 1);
  }

  function purge(
    uint256 tokenId,
    bool isBWListMember,
    bytes32[] calldata merkleProof
  ) external {
    uint256 redemptionValue = 0;

    if (tx.origin != msg.sender) {
      revert OriginNotSender();
    }

    if (proofMode != ProofMode.POS) {
      revert ProofModeNotPOS();
    }

    if (purgeMode == PurgeMode.INACTIVE) {
      revert PurgeModeInactive();
    }

    if (purgeMode == PurgeMode.COMPLETE) {
      revert PurgeModeComplete();
    }

    if (forebears[tokenId] == 0) {
      revert NotAPanda(); // no forebears
    }

    (uint256 forebearAId, uint256 forebearBId) = getForebearTokenIds(
      forebears[tokenId]
    );

    // get redemption value
    uint256 valueOfA = getPriceById(forebearAId);
    uint256 valueOfB = getPriceById(forebearBId);
    redemptionValue = valueOfA + valueOfB;

    // redeem 100% if caller is BW_List user
    if (purgeMode == PurgeMode.BW_LIST_FULL && isBWListMember) {
      if (
        !MerkleProof.verify(
          merkleProof,
          merkleRoot,
          keccak256(abi.encodePacked(msg.sender))
        )
      ) {
        revert InvalidMerkleProof();
      }
    } else {
      redemptionValue = (redemptionValue * PurgeRebate.PUBLIC_PERCENTAGE) / 100;
    }

    // burn the panda, make sure its the owner
    _burn(tokenId, true);

    forebears[tokenId] = 0;

    // then send ETH to user
    (bool success, ) = msg.sender.call{value: redemptionValue}("");
    if (!success) {
      revert UnableToSendValue();
    }
  }

  function contractURI() public view returns (string memory) {
    return IContractURIUtility(contractUtility).getContractURI();
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    uint256 dna = tokenIdToDNA[tokenId];
    require(dna != 0, "Not found");

    return IMetadataUtility(metadataUtility).getMetadataFromDNA(dna, tokenId);
  }

  function getCompressedForebearIds(uint256 forebearA, uint256 forebearB)
    internal
    pure
    returns (uint32)
  {
    uint32 compressed = 0;
    compressed = compressed | uint32(forebearA);
    compressed = (uint32(forebearB) << 16) | compressed;
    return compressed;
  }

  function getForebearTokenIds(uint32 forebears_)
    internal
    pure
    returns (uint256, uint256)
  {
    uint256 forebearA = uint256((forebears_ << 16) >> 16); // first 16 bits
    uint256 forebearB = uint256(forebears_ >> 16); // second 16 bits

    return (forebearA, forebearB);
  }

  function getForebearsForTokenId(uint256 tokenId)
    external
    view
    returns (uint256, uint256)
  {
    return getForebearTokenIds(forebears[tokenId]);
  }

  // OVERRIDES
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  // WITHDRAW ONLY OWNER
  function withdraw() external onlyOwner {
    if (purgeMode != PurgeMode.COMPLETE) {
      revert PurgeModeNotComplete();
    }

    (bool success, ) = address(msg.sender).call{value: address(this).balance}(
      ""
    );

    if (!success) {
      revert UnableToSendValue();
    }
  }
}