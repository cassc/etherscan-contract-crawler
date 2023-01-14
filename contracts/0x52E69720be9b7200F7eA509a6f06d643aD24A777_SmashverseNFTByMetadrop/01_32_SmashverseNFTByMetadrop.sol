// SPDX-License-Identifier: BUSL 1.0
// Metadrop Contracts (v1)

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
// Use of ERC721M which contains staking, vesting, and gas improvements for batch minting:
import "./ERC721M/ERC721M.sol";
// Layer Zero support for multi-chain freedom:
import "./LayerZero/onft/IONFT721.sol";
import "./LayerZero/onft/ONFT721Core.sol";
// Operator Filter
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
// Metadrop NFT interface
import "./INFTByMetadrop.sol";

contract SmashverseNFTByMetadrop is
  INFTByMetadrop,
  ONFT721Core,
  ERC721M,
  IONFT721,
  DefaultOperatorFilterer,
  VRFConsumerBaseV2
{
  using Strings for uint256;

  // Base chain for this collection (used with layer zero):
  uint256 immutable baseChain;
  address public immutable primarySaleContract;

  // Which metadata source are we using:
  bool public useArweave = true;
  // Are we pre-reveal:
  bool public preReveal = true;
  // Is metadata locked?:
  bool public metadataLocked = false;
  // Use the EPS composition service?
  bool public useEPS_CT = true;
  // Minting complete confirmation
  bool public mintingComplete;

  // Max duration for staking
  uint256 public maxStakingDurationInDays;

  uint256 public recordedRandomWord;
  uint256 public vrfStartPosition;

  address public baseContract;
  string public preRevealURI;
  string public arweaveURI;
  string public ipfsURI;

  /**
   * @dev Chainlink config.
   */
  // Mainnet: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
  // Goerli: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
  VRFCoordinatorV2Interface vrfCoordinator;
  uint64 vrfSubscriptionId;
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  // Mainnet 200 gwei: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef
  // Goerli 150 gwei 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15
  bytes32 vrfKeyHash;
  uint32 vrfCallbackGasLimit = 150000;
  uint16 vrfRequestConfirmations = 3;
  uint32 vrfNumWords = 1;

  bytes32 public positionProof;

  // Track tokens off-chain
  mapping(uint256 => address) public offChainOwner;

  error IncorrectConfirmationValue();
  error VRFAlreadySet();
  error PositionProofAlreadySet();

  event RandomNumberReceived(uint256 indexed requestId, uint256 randomNumber);
  event VRFPositionSet(uint256 VRFPosition);

  constructor(
    address primarySaleContract_,
    uint256 supply_,
    uint256 baseChain_,
    address epsDelegateRegister_,
    address epsComposeThis_,
    address vrfCoordinator_,
    bytes32 vrfKeyHash_,
    uint64 vrfSubscriptionId_,
    address royaltyReceipientAddress_,
    uint96 royaltyPercentageBasisPoints_
  )
    ERC721M(
      "Smashverse",
      "SMASH",
      supply_,
      epsDelegateRegister_,
      epsComposeThis_
    )
    ONFT721Core(_getLzEndPoint())
    VRFConsumerBaseV2(vrfCoordinator_)
  {
    primarySaleContract = primarySaleContract_;
    baseChain = baseChain_;
    vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
    vrfKeyHash = vrfKeyHash_;
    setVRFSubscriptionId(vrfSubscriptionId_);
    setDefaultRoyalty(royaltyReceipientAddress_, royaltyPercentageBasisPoints_);
  }

  // =======================================
  // OPERATOR FILTER REGISTER
  // =======================================

  function setApprovalForAll(address operator, bool approved)
    public
    override(ERC721M, IERC721)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public
    override(ERC721M, IERC721)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721M, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721M, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override(ERC721M, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  /**
   * @dev Burns `tokenId`. See {ERC721-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId) public virtual {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approved");
    _burn(tokenId);
  }

  // =======================================
  // MINTING
  // =======================================

  /**
   *
   *
   * @dev mint: mint items
   *
   *
   */
  function mint(
    uint256 quantityToMint_,
    address to_,
    uint256 vestingInDays_
  ) external {
    if (mintingComplete) {
      revert MintingIsClosedForever();
    }

    if (msg.sender != primarySaleContract) revert InvalidAddress();

    if (block.chainid != baseChain) {
      revert baseChainOnly();
    }

    _mintSequential(to_, quantityToMint_, vestingInDays_);
  }

  // =======================================
  // VRF
  // =======================================

  /**
   *
   *
   * @dev getStartPosition
   *
   *
   */
  function getStartPosition() external onlyOwner returns (uint256) {
    if (recordedRandomWord != 0) {
      revert VRFAlreadySet();
    }
    return
      vrfCoordinator.requestRandomWords(
        vrfKeyHash,
        vrfSubscriptionId,
        vrfRequestConfirmations,
        vrfCallbackGasLimit,
        vrfNumWords
      );
  }

  /**
   *
   *
   * @dev fulfillRandomWords: Callback from the chainlinkv2 oracle with randomness.
   *
   *
   */
  function fulfillRandomWords(uint256 requestId_, uint256[] memory randomWords_)
    internal
    override
  {
    recordedRandomWord = randomWords_[0];
    vrfStartPosition = (randomWords_[0] % maxSupply) + 1;
    emit RandomNumberReceived(requestId_, randomWords_[0]);
    emit VRFPositionSet(vrfStartPosition);
  }

  // =======================================
  // ADMINISTRATION
  // =======================================
  /**
   *
   *
   * @dev setDefaultRoyalty: Set the royalty percentage claimed
   * by the project owner for the collection.
   *
   * Note - we have specifically NOT implemented the ability to have different
   * royalties on a token by token basis. This reduces the complexity of processing on
   * multi-buys, and also avoids challenges to decentralisation (e.g. the project targetting
   * one users tokens with larger royalties)
   *
   *
   */
  function setDefaultRoyalty(address recipient, uint96 fraction)
    public
    onlyOwner
  {
    _setDefaultRoyalty(recipient, fraction);
  }

  /**
   *
   *
   * @dev deleteDefaultRoyalty: Delete the royalty percentage claimed
   * by the project owner for the collection.
   *
   *
   */
  function deleteDefaultRoyalty() public onlyOwner {
    _deleteDefaultRoyalty();
  }

  /**
   *
   *
   * @dev lockURIs: lock the URI data for this contract
   *
   *
   */
  function lockURIs() external onlyOwner {
    metadataLocked = true;
  }

  /**
   *
   *
   * @dev setURIs: Set the URI data for this contract
   *
   *
   */
  function setURIs(
    string memory preRevealURI_,
    string memory arweaveURI_,
    string memory ipfsURI_
  ) external onlyOwner {
    if (metadataLocked) {
      revert MetadataIsLocked();
    }

    preRevealURI = preRevealURI_;
    arweaveURI = arweaveURI_;
    ipfsURI = ipfsURI_;
  }

  /**
   *
   *
   * @dev switchImageSource (guards against either arweave or IPFS being no more)
   *
   *
   */
  function switchImageSource(bool useArweave_) external onlyOwner {
    useArweave = useArweave_;
  }

  /**
   *
   *
   * @dev setMaxStakingPeriod
   *
   *
   */
  function setMaxStakingPeriod(uint16 maxStakingDurationInDays_)
    external
    onlyOwner
  {
    maxStakingDurationInDays = maxStakingDurationInDays_;
    emit MaxStakingDurationSet(maxStakingDurationInDays_);
  }

  /**
   *
   *
   * @dev setEPSComposeThisAddress. Owner can update the EPS ComposeThis address
   *
   *
   */
  function setEPSComposeThisAddress(address epsComposeThis_)
    external
    onlyOwner
  {
    epsComposeThis = IEPS_CT(epsComposeThis_);
    emit EPSComposeThisUpdated(epsComposeThis_);
  }

  /**
   *
   *
   * @dev setEPSDelegateRegisterAddress. Owner can update the EPS DelegateRegister address
   *
   *
   */
  function setEPSDelegateRegisterAddress(address epsDelegateRegister_)
    external
    onlyOwner
  {
    epsDeligateRegister = IEPS_DR(epsDelegateRegister_);
    emit EPSDelegateRegisterUpdated(epsDelegateRegister_);
  }

  /**
   *
   *
   * @dev reveal. Owner can reveal
   *
   *
   */
  function reveal() external onlyOwner {
    preReveal = false;
    emit Revealed();
  }

  /**
   *
   *
   * @dev setMintingCompleteForeverCannotBeUndone: Allow owner to set minting complete
   * Enter confirmation value of "SmashverseMintingComplete" to confirm that you are closing
   * this mint forever.
   *
   *
   */
  function setMintingCompleteForeverCannotBeUndone(string memory confirmation_)
    external
    onlyOwner
  {
    string memory expectedValue = "SmashverseMintingComplete";
    if (
      keccak256(abi.encodePacked(confirmation_)) ==
      keccak256(abi.encodePacked(expectedValue))
    ) {
      mintingComplete = true;
    } else {
      revert IncorrectConfirmationValue();
    }
  }

  /**
   *
   *
   * @dev setBaseContract. Owner can set base contract
   *
   *
   */
  function setBaseContract(address baseContract_) external onlyOwner {
    if (block.chainid == baseChain) {
      revert ThisIsTheBaseContract();
    }

    baseContract = baseContract_;

    emit BaseContractSet(baseContract_);
  }

  /**
   *
   *
   * @dev setEPS_CTOn. Owner can turn EPS CT on
   *
   *
   */
  function setEPS_CTOn() external onlyOwner {
    useEPS_CT = true;
    emit EPS_CTTurnedOn();
  }

  /**
   *
   *
   * @dev setEPS_CTOff. Owner can turn EPS CT off
   *
   *
   */
  function setEPS_CTOff() external onlyOwner {
    useEPS_CT = false;
    emit EPS_CTTurnedOff();
  }

  /**
   *
   * @dev setPositionProof
   *
   */
  function setPositionProof(bytes32 positionProof_) external onlyOwner {
    if (positionProof != "") {
      revert PositionProofAlreadySet();
    }
    positionProof = positionProof_;

    emit MerkleRootSet(positionProof_);
  }

  /**
   *
   * @dev chainlink configuration setters:
   *
   */

  /**
   *
   * @dev setVRFSubscriptionId: Set the chainlink subscription id.
   *
   */
  function setVRFSubscriptionId(uint64 vrfSubscriptionId_) public onlyOwner {
    vrfSubscriptionId = vrfSubscriptionId_;
  }

  /**
   *
   * @dev setVRFKeyHash: Set the chainlink keyhash (gas lane).
   *
   */
  function setVRFKeyHash(bytes32 vrfKeyHash_) external onlyOwner {
    vrfKeyHash = vrfKeyHash_;
  }

  /**
   *
   * @dev setVRFCallbackGasLimit: Set the chainlink callback gas limit.
   *
   */
  function setVRFCallbackGasLimit(uint32 vrfCallbackGasLimit_)
    external
    onlyOwner
  {
    vrfCallbackGasLimit = vrfCallbackGasLimit_;
  }

  /**
   *
   * @dev set: Set the chainlink number of confirmations.
   *
   */
  function setVRFRequestConfirmations(uint16 vrfRequestConfirmations_)
    external
    onlyOwner
  {
    vrfRequestConfirmations = vrfRequestConfirmations_;
  }

  // =======================================
  // STAKING AND VESTING
  // =======================================

  /**
   *
   *
   * @dev beneficiaryOf
   *
   *
   */
  function beneficiaryOf(uint256 tokenId_)
    external
    view
    returns (address beneficiary_, BeneficiaryType beneficiaryType_)
  {
    beneficiary_ = epsDeligateRegister.beneficiaryOf(
      address(this),
      tokenId_,
      1
    );

    if (beneficiary_ == address(this)) {
      // If this token is owned by this contract we need to determine if it is vested,
      // staked, or currently off-chain
      address stakedOwner = stakedOwnerOf(tokenId_);
      if (stakedOwner != address(0)) {
        beneficiary_ = stakedOwner;
        beneficiaryType_ = BeneficiaryType.stakedOwner;
      } else {
        address vestedOwner = vestedOwnerOf(tokenId_);
        if (vestedOwner != address(0)) {
          beneficiary_ = vestedOwner;
          beneficiaryType_ = BeneficiaryType.vestedOwner;
        } else {
          // Not vested or staked, must be off-chain:
          address otherChainOwner = offChainOwner[tokenId_];
          if (otherChainOwner != address(0)) {
            beneficiary_ = otherChainOwner;
            beneficiaryType_ = BeneficiaryType.offChainOwner;
          }
        }
      }
    } else {
      if (beneficiary_ != ownerOf(tokenId_)) {
        beneficiaryType_ = BeneficiaryType.epsDelegate;
      }
    }

    if (beneficiary_ == address(0)) {
      revert InvalidToken();
    }

    return (beneficiary_, beneficiaryType_);
  }

  /**
   *
   *
   * @dev inVestingPeriod: return if the token is in a vesting period
   *
   *
   */
  function inVestingPeriod(uint256 tokenId) external view returns (bool) {
    return (vestingEndDateForToken[tokenId] >= block.timestamp);
  }

  /**
   *
   *
   * @dev inStakedPeriod: return if the token is staked
   *
   *
   */
  function inStakedPeriod(uint256 tokenId) external view returns (bool) {
    return (stakingEndDateForToken[tokenId] >= block.timestamp);
  }

  /**
   *
   *
   * @dev stake: stake items
   *
   *
   */
  function stake(uint256[] memory tokenIds_, uint256 stakingInDays_) external {
    if (stakingInDays_ > maxStakingDurationInDays) {
      revert StakingDurationExceedsMaximum(
        stakingInDays_,
        maxStakingDurationInDays
      );
    }

    for (uint256 i = 0; i < tokenIds_.length; ) {
      _setTokenStakingDate(tokenIds_[i], stakingInDays_);
      unchecked {
        i++;
      }
    }
  }

  /**
   *
   *
   * @dev tokenURI. Includes layer zero satellite chain support
   * and staking / vesting display using EPS_CT
   *
   *
   */
  function tokenURI(uint256 tokenId_)
    public
    view
    override
    returns (string memory)
  {
    _requireMinted(tokenId_);

    // If we are using the EPS_CT service we can apply additional
    // details to metadata:

    if (useEPS_CT && address(epsComposeThis) != address(0)) {
      // Check for staking:
      if (stakingEndDateForToken[tokenId_] > block.timestamp) {
        AddedTrait[] memory addedTraits = new AddedTrait[](2);

        addedTraits[0] = AddedTrait(
          "Staked Until",
          ValueType.date,
          stakingEndDateForToken[tokenId_],
          "",
          address(0)
        );

        addedTraits[1] = AddedTrait(
          "Staked",
          ValueType.characterString,
          0,
          "true",
          address(0)
        );

        string[] memory addedImages = new string[](1);

        addedImages[0] = "staked";

        return
          epsComposeThis.composeURIFromBaseURI(
            _baseTokenURI(tokenId_),
            addedTraits,
            1,
            addedImages
          );
      }

      // Check for vesting:
      if (vestingEndDateForToken[tokenId_] > block.timestamp) {
        AddedTrait[] memory addedTraits = new AddedTrait[](2);

        addedTraits[0] = AddedTrait(
          "Vested Until",
          ValueType.date,
          vestingEndDateForToken[tokenId_],
          "",
          address(0)
        );

        addedTraits[1] = AddedTrait(
          "Vested",
          ValueType.characterString,
          0,
          "true",
          address(0)
        );

        string[] memory addedImages = new string[](1);

        addedImages[0] = "vested";

        return
          epsComposeThis.composeURIFromBaseURI(
            _baseTokenURI(tokenId_),
            addedTraits,
            1,
            addedImages
          );
      }

      // If on a satellite chain get the URI from the base chain:
      if (block.chainid != baseChain) {
        return
          epsComposeThis.composeURIFromLookup(
            baseChain,
            _baseContract(),
            tokenId_,
            new AddedTrait[](0),
            0,
            new string[](0)
          );
      }

      // Finally, if on the base chain, owned by the token contract and NOT staked
      // or vested we must be off-chain through LayerZero:
      if (ownerOf(tokenId_) == address(this)) {
        AddedTrait[] memory addedTraits = new AddedTrait[](1);

        addedTraits[0] = AddedTrait(
          "Off-chain",
          ValueType.characterString,
          0,
          "true",
          address(0)
        );

        string[] memory addedImages = new string[](1);

        addedImages[0] = "off-chain";

        return
          epsComposeThis.composeURIFromBaseURI(
            _baseTokenURI(tokenId_),
            addedTraits,
            1,
            addedImages
          );
      }

      return (_baseTokenURI(tokenId_));
    } else {
      return (_baseTokenURI(tokenId_));
    }
  }

  /**
   *
   *
   * @dev _baseTokenURI.
   *
   *
   */
  function _baseTokenURI(uint256 tokenId_)
    internal
    view
    returns (string memory)
  {
    if (preReveal) {
      return
        bytes(preRevealURI).length > 0
          ? string(abi.encodePacked(preRevealURI, tokenId_.toString(), ".json"))
          : "";
    } else {
      if (useArweave) {
        return
          bytes(arweaveURI).length > 0
            ? string(abi.encodePacked(arweaveURI, tokenId_.toString(), ".json"))
            : "";
      } else {
        return
          bytes(ipfsURI).length > 0
            ? string(abi.encodePacked(ipfsURI, tokenId_.toString(), ".json"))
            : "";
      }
    }
  }

  // =======================================
  // LAYER ZERO
  // =======================================

  /**
   *
   *
   * @dev supportsInterface. Include Layer Zero support.
   *
   *
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ONFT721Core, ERC721M, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IONFT721).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   *
   *
   * @dev _baseContract. Return the base contract address
   *
   *
   */
  function _baseContract() internal view returns (address) {
    if (block.chainid == baseChain) {
      return (address(this));
    }

    if (baseContract == address(0)) {
      return (address(this));
    } else {
      return baseContract;
    }
  }

  /**
   *
   *
   * @dev _isBaseChain. Return if this is the base chain
   *
   *
   */
  function _isBaseChain() internal view returns (bool) {
    return (block.chainid == baseChain);
  }

  /**
   *
   *
   * @dev _getLzEndPoint. Internal function to get the LZ endpoint
   * for this chain. This means we don't need to pass this in, allowing
   * for identical bytecode between chains, which enables the creation
   * of identical contract addresses using CREATE2
   *
   * Need a chain not listed? No problem, but you will need to alter the contract
   * to receive the LZ endpoint prior to deploy (this will change the bytecode
   * and mean you won't be able to deploy using the same contract ID without
   * using a create3 factory, and we haven't finished building that yet).
   *
   *
   */
  function _getLzEndPoint() internal view returns (address) {
    uint256 chainId = block.chainid;

    if (chainId == 1) return 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675; // Ethereum mainnet
    if (chainId == 5) return 0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23; // Goerli testnet
    if (chainId == 80001) return 0xf69186dfBa60DdB133E91E9A4B5673624293d8F8; // Mumbai (polygon testnet)
    if (chainId == 137) return 0x3c2269811836af69497E5F486A85D7316753cf62; // Polygon mainnet
    if (chainId == 56) return 0x3c2269811836af69497E5F486A85D7316753cf62; // BSC mainnet
    if (chainId == 43114) return 0x3c2269811836af69497E5F486A85D7316753cf62; // Avalanche mainnet
    if (chainId == 42161) return 0x3c2269811836af69497E5F486A85D7316753cf62; // Arbitrum
    if (chainId == 10) return 0x3c2269811836af69497E5F486A85D7316753cf62; // Optimism
    if (chainId == 250) return 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7; // Fantom
    if (chainId == 73772) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Swimmer
    if (chainId == 53935) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // DFK
    if (chainId == 1666600000)
      return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Harmony
    if (chainId == 1284) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Moonbeam
    if (chainId == 42220) return 0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9; // Celo
    if (chainId == 432204) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Dexalot
    if (chainId == 122) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Fuse
    if (chainId == 100) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Gnosis
    if (chainId == 8217) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Kaytn
    if (chainId == 1088) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Metis

    return (address(0));
  }

  /**
   *
   *
   * @dev _debitFrom. Internal function called on a layer zero
   * transfer FROM this chain.
   *
   *
   */
  function _debitFrom(
    address _from,
    uint16,
    bytes memory,
    uint256 _tokenId
  ) internal virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), _tokenId),
      "Not owner nor approved"
    );
    require(ERC721M.ownerOf(_tokenId) == _from, "Not owner");
    offChainOwner[_tokenId] = _from;
    _transfer(_from, address(this), _tokenId);
  }

  /**
   *
   *
   * @dev _creditTo. Internal function called on a layer zero
   * transfer TO this chain.
   *
   *
   */
  function _creditTo(
    uint16,
    address _toAddress,
    uint256 _tokenId
  ) internal virtual override {
    // Different behaviour depending on whether this has been deployed on
    // the base chain or a satellite chain:
    if (block.chainid == baseChain) {
      // Base chain. For us to be crediting the owner this token MUST be
      // owned by the contract, as they can only be minted on the base chain
      require(
        (_exists(_tokenId) && ERC721M.ownerOf(_tokenId) == address(this))
      );

      _transfer(address(this), _toAddress, _tokenId);
    } else {
      // Satellite chain. We can be crediting the user as a result of this reaching
      // this chain for the first time (mint) OR from a token that has been minted
      // here previously and is currently custodied by the contract.
      require(
        !_exists(_tokenId) ||
          (_exists(_tokenId) && ERC721M.ownerOf(_tokenId) == address(this))
      );
      if (!_exists(_tokenId)) {
        _safeMint(_toAddress, _tokenId);
      } else {
        _transfer(address(this), _toAddress, _tokenId);
      }
    }

    delete offChainOwner[_tokenId];
  }
}