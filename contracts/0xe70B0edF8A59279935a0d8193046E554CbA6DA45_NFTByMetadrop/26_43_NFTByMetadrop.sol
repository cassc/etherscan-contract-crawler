// SPDX-License-Identifier: BUSL 1.0
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title NFTByMetadrop.sol. This contract is the clonable template contract for
 * all metadrop NFT deployments.
 *
 * @author metadrop https://metadrop.com/
 *
 * @notice This contract does not include logic associated with the primary
 * sale of the NFT, that functionality being provided by other contracts within
 * the metadrop platform (e.g. an auction, or a public and list based sale) that
 * form a suite of primary sale modules.
 *
 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./ERC721M.sol";
import "./INFTByMetadrop.sol";
import "../DropFactory/IDropFactory.sol";
import "../Global/AuthorityModel.sol";

/**
 *
 * @dev Inheritance details:
 *      ERC721M                 ERC721Metadrop token standard, based on openzeppelin ERC721
 *      INFTMetadrop            Interface definition for the metadrop NFT
 *      DefaultOperatorFilterer Implemented for royalty compliant filtering
 *      Pausable                Allow contract to be paused by an authorised user
 *
 */

contract NFTByMetadrop is
  ERC721M,
  INFTByMetadrop,
  DefaultOperatorFilterer,
  Pausable,
  AuthorityModel
{
  using Strings for uint256;

  // Which metadata source are we using:
  bool public useArweave;

  // Is metadata locked?:
  bool public metadataLocked;

  // Minting complete confirmation
  bool public mintingComplete;

  // Are we revealed:
  bool public collectionRevealed;

  // Bool that controls initialisation and only allows it to occur ONCE. This is
  // needed as this contract is clonable, threfore the constructor is not called
  // on cloned instances. We setup state of this contract through the initialise
  // function.
  bool public initialised;

  uint8 public pauseCutOffInDays;

  uint32 private deployTimeStamp;

  // URI details:
  string public preRevealURI;
  string public arweaveURI;
  string public ipfsURI;

  // Proof and VRF results for metadata reveal:
  bytes32 public positionProof;
  uint256 public recordedRandomWord;
  uint256 public vrfStartPosition;

  // Valid primary market addresses
  mapping(address => bool) public validPrimaryMarketAddress;

  /** ====================================================================================================================
   *                                              CONSTRUCTOR AND INTIIALISE
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                        -->CONSTRUCTOR
   * @dev constructor           The constructor is not called when the contract is cloned. In this
   *                            constructor we just setup default values and set the template contract to initialised.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param epsRegister_        The EPS register address (0x888888888888660F286A7C06cfa3407d09af44B2 on most chains)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param lzEndpoint_         The LZ endpoint for this chain
   *                            (see https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param layerZeroBase_      If this contract is the base layerZero contract. For this ONFT implementation the base
   *                            contract is where intial minting can occue. NFTs can then be sent to any supporting chain
   *                            but cannot be 'freshly' minted on other chains and sent to the base contract.
   * _____________________________________________________________________________________________________________________
   */
  constructor(
    address epsRegister_,
    address lzEndpoint_,
    bool layerZeroBase_
  ) ERC721M(epsRegister_, lzEndpoint_, layerZeroBase_) {
    // Initialise this template instance:
    _initialiseERC721M("NFT", "NFT", 0, msg.sender);

    initialised = true;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialiseNFT  Load configuration into storage for a new instance.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param superAdmin_              The super admin for this contract. A super admin can manage roles
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformAdmins_          An array of platform admin addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_            The project owner for this drop. Sets the project admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModules_      The primary sale modules for this drop. These are the contract addresses that are
   *                                 authorised to call mint on this contract.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_               The drop specific configuration for this NFT. This is decoded and used to set
   *                                 configuration for this metadrop drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitter_  The address of the deployed royalty payment splitted for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyFromSalesInBasisPoints_  The royalty basis points for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param collectionURIs_          The URIs for this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param pauseCutOffInDays_       The number of days from deployment that this contract can be paused
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function initialiseNFT(
    address superAdmin_,
    address[] memory platformAdmins_,
    address projectOwner_,
    PrimarySaleModuleInstance[] calldata primarySaleModules_,
    NFTModuleConfig calldata nftModule_,
    address royaltyPaymentSplitter_,
    uint96 royaltyFromSalesInBasisPoints_,
    string[3] calldata collectionURIs_,
    uint8 pauseCutOffInDays_
  ) public {
    // This clone instance can only be initialised ONCE
    if (initialised) revert AlreadyInitialised();

    // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
    // will not revert, but the contract will need to be registered with the registry once it is deployed in
    // order for the modifier to filter addresses.
    if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
      OPERATOR_FILTER_REGISTRY.registerAndSubscribe(
        address(this),
        CANONICAL_CORI_SUBSCRIPTION
      );
    }

    _decodeAndSetParams(projectOwner_, nftModule_);

    _initialiseAuthorityModel(superAdmin_, platformAdmins_, projectOwner_);

    // Load the primary sale modules to the mappings
    for (uint256 i = 0; i < primarySaleModules_.length; ) {
      validPrimaryMarketAddress[primarySaleModules_[i].instanceAddress] = true;
      unchecked {
        i++;
      }
    }

    // Royalty setup
    // If the royalty contract is address(0) then the royalty module
    // has been flagged as not required for this drop.
    // To avoid any possible loss of funds from incorrect configuation we don't
    // set the royalty receiver address to address(0), but rather to the first
    // platform admin
    if (royaltyPaymentSplitter_ == address(0)) {
      _setDefaultRoyalty(platformAdmins_[0], royaltyFromSalesInBasisPoints_);
    } else {
      _setDefaultRoyalty(
        royaltyPaymentSplitter_,
        royaltyFromSalesInBasisPoints_
      );
    }

    useArweave = false;
    metadataLocked = false;
    mintingComplete = false;
    collectionRevealed = false;

    preRevealURI = collectionURIs_[0];
    ipfsURI = collectionURIs_[1];
    arweaveURI = collectionURIs_[2];

    factory = msg.sender;

    pauseCutOffInDays = pauseCutOffInDays_;
    deployTimeStamp = uint32(block.timestamp);

    // Set this clone to initialised
    initialised = true;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) _decodeAndSetParams  Decode NFT Parameters
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_     The project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_        NFT module data
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _decodeAndSetParams(
    address projectOwner_,
    NFTModuleConfig calldata nftModule_
  ) internal {
    // Decode the config
    (
      uint256 decodedSupply,
      ,
      string memory decodedName,
      string memory decodedSymbol,
      bytes32 decodedPositionProof
    ) = abi.decode(
        nftModule_.configData,
        (uint256, uint256, string, string, bytes32)
      );

    // Initialise values on ERC721M
    _initialiseERC721M(
      decodedName,
      decodedSymbol,
      decodedSupply,
      projectOwner_
    );

    positionProof = decodedPositionProof;
  }

  /** ====================================================================================================================
   *                                            OPERATOR FILTER REGISTRY
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                    -->OPERATOR FILTER
   * @dev (function) setApprovalForAll  Operator filter registry override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param operator            The operator for the approval
   * ---------------------------------------------------------------------------------------------------------------------
   * @param approved            If the operator is approved
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setApprovalForAll(
    address operator,
    bool approved
  ) public override onlyAllowedOperatorApproval(operator) whenNotPaused {
    super.setApprovalForAll(operator, approved);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                    -->OPERATOR FILTER
   * @dev (function) approve  Operator filter registry override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param operator            The operator for the approval
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId             The tokenId for this approval
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function approve(
    address operator,
    uint256 tokenId
  ) public override onlyAllowedOperatorApproval(operator) whenNotPaused {
    super.approve(operator, tokenId);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                    -->OPERATOR FILTER
   * @dev (function) transferFrom  Operator filter registry override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param from                The sender of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param to                  The recipient of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId             The tokenId for this approval
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) whenNotPaused {
    super.transferFrom(from, to, tokenId);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                    -->OPERATOR FILTER
   * @dev (function) safeTransferFrom  Operator filter registry override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param from                The sender of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param to                  The recipient of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId             The tokenId for this approval
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) whenNotPaused {
    super.safeTransferFrom(from, to, tokenId);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                    -->OPERATOR FILTER
   * @dev (function) safeTransferFrom  Operator filter registry override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param from                The sender of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param to                  The recipient of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId             The tokenId for this approval
   * ---------------------------------------------------------------------------------------------------------------------
   * @param data                bytes data accompanying this transfer operation
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) whenNotPaused {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  /** ====================================================================================================================
   *                                                 PRIVILEGED ACCESS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->PAUSE
   * @dev (function) pause    Allow platform admin to pause
   * _____________________________________________________________________________________________________________________
   */
  function pause() external onlyPlatformAdminOrProjectOwner {
    unchecked {
      if (block.timestamp > (deployTimeStamp + pauseCutOffInDays * 1 days)) {
        revert PauseCutOffHasPassed();
      }
    }
    _pause();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->PAUSE
   * @dev (function) unpause    Allow platform admin to unpause
   *
   * _____________________________________________________________________________________________________________________
   */
  function unpause() external onlyPlatformAdminOrProjectOwner {
    _unpause();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                       -->LOCK MINTING
   * @dev (function) setMintingCompleteForeverCannotBeUndone  Allow project owner OR platform admin to set minting
   *                                                          complete
   *
   * @notice Enter confirmation value of "done" to confirm that you are closing minting.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param confirmation_  Confirmation string
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMintingCompleteForeverCannotBeUndone(
    string calldata confirmation_
  ) external onlyPlatformAdminOrProjectOwner {
    if (
      keccak256(abi.encodePacked(confirmation_)) ==
      keccak256(abi.encodePacked("done"))
    ) {
      mintingComplete = true;
    } else {
      revert IncorrectConfirmationValue();
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) revealCollection  Set the collection to revealed
   *
   * _____________________________________________________________________________________________________________________
   */
  function revealCollection() external onlyPlatformAdminOrProjectOwner {
    collectionRevealed = true;

    emit Revealed();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) setPositionProof  Set the metadata position proof
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param positionProof_  The metadata proof
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPositionProof(bytes32 positionProof_) external onlyPlatformAdmin {
    positionProof = positionProof_;

    emit PositionProofSet(positionProof_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) setStartPosition  Get the metadata start position for use on reveal of this collection
   * _____________________________________________________________________________________________________________________
   */
  function setStartPosition() external onlyPlatformAdminOrProjectOwner {
    if (recordedRandomWord != 0) {
      revert VRFAlreadySet();
    }
    IDropFactory(factory).requestVRFRandomness();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) fulfillRandomWords  Callback from the chainlinkv2 oracle (on factory) with randomness
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param requestId_      The Id of this request (this contract will submit a single request)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param randomWords_   The random words returned from chainlink
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function fulfillRandomWords(
    uint256 requestId_,
    uint256[] memory randomWords_
  ) external {
    if (msg.sender == factory) {
      recordedRandomWord = randomWords_[0];
      unchecked {
        vrfStartPosition = (randomWords_[0] % maxSupply) + 1;
      }
      emit RandomNumberReceived(requestId_, randomWords_[0]);
      emit VRFPositionSet(vrfStartPosition);
    } else {
      revert MetadropFactoryOnly();
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) setURIs  Set the URI data for this contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param preRevealURI_   The URI to use pre-reveal
   * ---------------------------------------------------------------------------------------------------------------------
   * @param arweaveURI_     The URI for arweave
   * ---------------------------------------------------------------------------------------------------------------------
   * @param ipfsURI_     The URI for IPFS
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setURIs(
    string calldata preRevealURI_,
    string calldata arweaveURI_,
    string calldata ipfsURI_
  ) external onlyPlatformAdmin {
    if (metadataLocked) {
      revert MetadataIsLocked();
    }

    preRevealURI = preRevealURI_;
    arweaveURI = arweaveURI_;
    ipfsURI = ipfsURI_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) lockURIsCannotBeUndone  Lock the URI data for this contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param confirmation_   The confirmation string
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function lockURIsCannotBeUndone(
    string calldata confirmation_
  ) external onlyPlatformAdmin {
    if (
      keccak256(abi.encodePacked(confirmation_)) ==
      keccak256(abi.encodePacked("lock"))
    ) {
      metadataLocked = true;
    } else {
      revert IncorrectConfirmationValue();
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) setUseArweave  Guards against either arweave or IPFS being no more
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param useArweave_   Boolean to indicate whether arweave should be used or not (true = use arweave, false = use IPFS)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setUseArweave(
    bool useArweave_
  ) external onlyPlatformAdminOrProjectOwner {
    useArweave = useArweave_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) setDefaultRoyalty  Set the royalty percentage
   *
   * @notice - we have specifically NOT implemented the ability to have different royalties on a token by token basis.
   * This reduces the complexity of processing on multi-buys, and also avoids challenges to decentralisation (e.g. the
   * project targetting one users tokens with larger royalties)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_   Royalty receiver
   * ---------------------------------------------------------------------------------------------------------------------
   * @param fraction_   Royalty fraction
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDefaultRoyalty(
    address recipient_,
    uint96 fraction_
  ) public onlyPlatformAdminOrProjectOwner {
    _setDefaultRoyalty(recipient_, fraction_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) deleteDefaultRoyalty  Delete the royalty percentage claimed
   *
   * _____________________________________________________________________________________________________________________
   */
  function deleteDefaultRoyalty() public onlyPlatformAdminOrProjectOwner {
    _deleteDefaultRoyalty();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) receive  This contract does not handle ETH. Explicitly revert on receive()
   *
   * _____________________________________________________________________________________________________________________
   */
  receive() external payable {
    revert();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) fallback  Explicitly revert on fallback()
   *
   * _____________________________________________________________________________________________________________________
   */
  fallback() external payable {
    revert();
  }

  /** ====================================================================================================================
   *                                             COLLECTION INFORMATION GETTERS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) metadropCustom  Returns if this contract is a custom NFT (true) or is a standard metadrop
   *                                 ERC721M (false)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isMetadropCustom_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropCustom() external pure returns (bool isMetadropCustom_) {
    return (false);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalSupply  Returns total supply (minted - burned)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalSupply_   The total supply of this collection (minted - burned)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalSupply()
    external
    view
    override(ERC721M, INFTByMetadrop)
    returns (uint256 totalSupply_)
  {
    return totalMinted() - totalBurned();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalUnminted  Returns the remaining unminted supply
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalUnminted_   The total unminted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalUnminted()
    public
    view
    override(ERC721M, INFTByMetadrop)
    returns (uint256 totalUnminted_)
  {
    return remainingSupply;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalMinted  Returns the total number of tokens ever minted
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalMinted_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalMinted()
    public
    view
    override(ERC721M, INFTByMetadrop)
    returns (uint256 totalMinted_)
  {
    return (maxSupply - remainingSupply);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalBurned  Returns the count of tokens sent to the burn address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalBurned_   The total burned supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalBurned()
    public
    view
    override(ERC721M, INFTByMetadrop)
    returns (uint256 totalBurned_)
  {
    return ERC721M.balanceOf(BURN_ADDRESS);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) tokenURI  Returns the URI for the passed token
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return tokenURI_   The token URI
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory tokenURI_) {
    _requireMinted(tokenId);

    unchecked {
      if (!collectionRevealed) {
        return
          bytes(preRevealURI).length > 0
            ? string(abi.encodePacked(preRevealURI))
            : "";
      } else {
        if (useArweave) {
          return
            bytes(arweaveURI).length > 0
              ? string(
                abi.encodePacked(
                  arweaveURI,
                  ((tokenId + vrfStartPosition) % maxSupply).toString(),
                  ".json"
                )
              )
              : "";
        } else {
          return
            bytes(ipfsURI).length > 0
              ? string(
                abi.encodePacked(
                  ipfsURI,
                  ((tokenId + vrfStartPosition) % maxSupply).toString(),
                  ".json"
                )
              )
              : "";
        }
      }
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) supportsInterface   Override is required by Solidity.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return bool    If the interface is supported
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view override(AccessControl, ERC721M) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /** ====================================================================================================================
   *                                                    MINTING
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) metadropMint  Mint tokens. Can only be called from a valid primary market contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param caller_                The address that has called mint through the primary sale module.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_             The address that will receive new assets.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param allowanceAddress_      The address that has an allowance being used in this mint. This will be the same as the
   *                               calling address in almost all cases. An example of when they may differ is in a list
   *                               mint where the caller is a delegate of another address with an allowance in the list.
   *                               The caller is performing the mint, but it is the allowance for the allowance address
   *                               that is being checked and decremented in this mint.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityToMint_        The quantity of tokens to be minted
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_             The unit price for each token
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropMint(
    address caller_,
    address recipient_,
    address allowanceAddress_,
    uint256 quantityToMint_,
    uint256 unitPrice_
  ) external {
    if (recipient_ == address(0) || recipient_ == BURN_ADDRESS) {
      revert InvalidRecipient();
    }

    if (mintingComplete) {
      revert MintingIsClosedForever();
    }

    if (!validPrimaryMarketAddress[msg.sender]) revert InvalidAddress();

    uint256[] memory tokenIds = _mintSequential(recipient_, quantityToMint_);

    emit MetadropMint(
      allowanceAddress_,
      recipient_,
      caller_,
      msg.sender,
      unitPrice_,
      tokenIds
    );
  }
  /** ====================================================================================================================
   */
}