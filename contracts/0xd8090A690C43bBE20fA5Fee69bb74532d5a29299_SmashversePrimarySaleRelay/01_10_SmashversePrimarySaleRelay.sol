// SPDX-License-Identifier: BUSL 1.0
// Metadrop Contracts (v1)

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// EPS implementation
import "./EPS/IEPS_DR.sol";

interface ISublists {
  struct Sublist {
    uint256 sublistInteger;
    uint256 sublistPosition;
  }
}

interface ITitanMinting is ISublists {
  /**
   *
   * @dev listMint: mint from any of the lists
   *
   */
  function listMint(
    Sublist memory sublist_,
    uint256 quantityEligible_,
    uint256 quantityToMint_,
    uint256 unitPrice_,
    uint256 vestingInDays_,
    bytes32[] calldata proof_
  ) external payable;
}

interface ITitan is IERC721 {
  /**
   * @dev Returns the total number of tokens ever minted
   */
  function totalMinted() external view returns (uint256);
}

contract SmashversePrimarySaleRelay is Pausable, Ownable, ISublists {
  using Strings for uint256;

  // The current status of the mint:
  //   - notEnabled: This type of mint is not part of this drop
  //   - notYetOpen: This type of mint is part of the drop, but it hasn't started yet
  //   - open: it's ready for ya, get in there.
  //   - finished: been and gone.
  //   - unknown: theoretically impossible.
  enum MintStatus {
    notEnabled,
    notYetOpen,
    open,
    finished,
    unknown
  }

  enum AllocationCheck {
    invalidListType,
    hasAllocation,
    invalidProof,
    allocationExhausted
  }

  enum MintingType {
    publicMint,
    allowlistMint,
    mintPassMint
  }

  struct SubListConfig {
    uint256 start;
    uint256 end;
    uint256 phaseMaxSupply;
  }

  struct PublicMintConfig {
    uint256 price;
    uint256 maxPerAddress;
    uint32 start;
    uint32 end;
  }

  address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  // =======================================
  // CONFIG
  // =======================================

  // Pause cutoff
  uint256 public immutable pauseCutOffInDays;

  // The merkleroot for the list
  bytes32 public listMerkleRoot;

  // Config for the list mints
  SubListConfig[] public subListConfig;

  // The NFT contract
  ITitan immutable smashverseTitansContract;

  // V1 sale contract
  ITitanMinting immutable smashverseSaleContract;

  IERC721 immutable mintPassContract;

  bytes32[] private mintPassProof;

  bytes32[] private freeMintProof;

  uint256 private totalMintPassMintQuantity;

  uint256 private totalFreeMintQuantity;

  uint32 public publicMintStart;
  uint32 public publicMintEnd;
  bool public publicMintingClosedForever;

  bool public listDetailsLocked;

  IEPS_DR public epsDeligateRegister;

  address public beneficiary;

  // Track publicMint minting allocations:
  mapping(address => uint256) public publicMintAllocationMinted;

  // Track list minting allocations:
  mapping(address => mapping(uint256 => uint256))
    public listMintAllocationMinted;

  error MintingIsClosedForever();
  error TransferFailed();
  error MaxPublicMintAllowanceExceeded(
    uint256 requested,
    uint256 alreadyMinted,
    uint256 maxAllowance
  );
  error ProofInvalid();
  error RequestingMoreThanRemainingAllocation(
    uint256 requested,
    uint256 remainingAllocation
  );
  error IncorrectConfirmationValue();
  error ThisListMintIsClosed();
  error PublicMintClosed();
  error ListDetailsLocked();
  error InvalidMintPass();

  event EPSDelegateRegisterUpdated(address epsDelegateRegisterAddress);
  event MerkleRootSet(bytes32 merkleRoot);
  event SmashMint(
    address indexed minter,
    MintingType mintType,
    uint256 subListInteger,
    uint256 quantityMinted
  );
  event SublistConfigSet(
    uint256 sublistInteger,
    uint256 start,
    uint256 end,
    uint256 supply
  );

  event MintPassRedeemed(
    address indexed receiver,
    uint256 indexed mintPassTokenId
  );

  constructor(
    PublicMintConfig memory publicMintConfig_,
    bytes32 listMerkleRoot_,
    address epsDeligateRegister_,
    uint256 pauseCutOffInDays_,
    address beneficiary_,
    SubListConfig[] memory subListParams,
    address smashverseTitansContract_,
    address smashverseSaleContract_,
    address mintPassContract_
  ) {
    listMerkleRoot = listMerkleRoot_;
    publicMintStart = uint32(publicMintConfig_.start);
    publicMintEnd = uint32(publicMintConfig_.end);
    epsDeligateRegister = IEPS_DR(epsDeligateRegister_);
    pauseCutOffInDays = pauseCutOffInDays_;
    beneficiary = beneficiary_;
    _loadSubListDetails(subListParams);
    smashverseTitansContract = ITitan(smashverseTitansContract_);
    smashverseSaleContract = ITitanMinting(smashverseSaleContract_);
    mintPassContract = IERC721(mintPassContract_);
  }

  function onERC721Received(
    address,
    address from_,
    uint256 tokenId_,
    bytes memory
  ) external returns (bytes4) {
    // Allow mints from the Smashverse Titans NFT contract to be sent to this contract
    if (
      msg.sender == address(smashverseTitansContract) && from_ == address(0)
    ) {
      return this.onERC721Received.selector;
    } else {
      // Revert if the sender is not the mint pass contract, since this is a callback from a contract.
      if (msg.sender != address(mintPassContract)) {
        revert InvalidMintPass();
      }

      _performMintPassMinting(tokenId_, from_, address(this));

      return this.onERC721Received.selector;
    }
  }

  function mintPassMint(uint256[] memory mintPassTokenIds_) external {
    for (uint256 i = 0; i < mintPassTokenIds_.length; i++) {
      _performMintPassMinting(mintPassTokenIds_[i], msg.sender, msg.sender);
    }
  }

  function _performMintPassMinting(
    uint256 mintPassTokenId_,
    address receiver_,
    address currentPassHolder_
  ) internal whenNotPaused {
    // safeTransferFrom will revert if the sender does not own the token or does not have approval to transfer it.
    // Burn the mint pass. Since we can't burn NFTs, we transfer it to 0xdEaD.
    mintPassContract.safeTransferFrom(
      currentPassHolder_,
      DEAD_ADDRESS,
      mintPassTokenId_
    );

    // Cache the next tokenId from the NFT:
    uint256 nextTokenId = smashverseTitansContract.totalMinted();

    smashverseSaleContract.listMint(
      Sublist(0, 0),
      totalMintPassMintQuantity,
      2,
      0,
      0,
      mintPassProof
    );

    smashverseTitansContract.safeTransferFrom(
      address(this),
      receiver_,
      nextTokenId,
      ""
    );

    smashverseTitansContract.safeTransferFrom(
      address(this),
      receiver_,
      nextTokenId + 1,
      ""
    );

    emit MintPassRedeemed(receiver_, mintPassTokenId_);
  }

  // =======================================
  // MINTING
  // =======================================

  /**
   *
   * @dev _loadSubListDetails
   *
   */
  function _loadSubListDetails(SubListConfig[] memory config_) internal {
    for (uint256 i = 0; i < config_.length; i++) {
      subListConfig.push(config_[i]);
    }
  }

  /**
   *
   * @dev listMintStatus: View of a list mint status
   *
   */
  function listMintStatus(uint256 listInteger)
    public
    view
    returns (
      MintStatus status,
      uint256 start,
      uint256 end
    )
  {
    return (
      _mintTypeStatus(
        subListConfig[listInteger].start,
        subListConfig[listInteger].end
      ),
      subListConfig[listInteger].start,
      subListConfig[listInteger].end
    );
  }

  /**
   *
   * @dev _mintTypeStatus: return the status of the mint type
   *
   */
  function _mintTypeStatus(uint256 start_, uint256 end_)
    internal
    view
    returns (MintStatus)
  {
    // Explicitly check for open before anything else. This is the only valid path to making a
    // state change, so keep the gas as low as possible for the code path through 'open'
    if (block.timestamp >= (start_) && block.timestamp <= (end_)) {
      return (MintStatus.open);
    }

    if ((start_ + end_) == 0) {
      return (MintStatus.notEnabled);
    }

    if (block.timestamp > end_) {
      return (MintStatus.finished);
    }

    if (block.timestamp < start_) {
      return (MintStatus.notYetOpen);
    }

    return (MintStatus.unknown);
  }

  /**
   *
   * @dev publicMintStatus: View of public mint status
   *
   */
  function publicMintStatus() public view returns (MintStatus) {
    return _mintTypeStatus(publicMintStart, publicMintEnd);
  }

  /**
   *
   * @dev allowlistFreeMint one free mint per address on the allowlist
   *
   */
  function listMint(
    Sublist memory sublist_,
    uint256, // ignored but kept for consistency with ABI
    uint256, // ignored but kept for consistency with ABI
    uint256 unitPrice_,
    uint256 vestingInDays_,
    bytes32[] calldata proof_
  ) public payable whenNotPaused {
    _allowlistFreeMint(sublist_, 1, 1, unitPrice_, vestingInDays_, proof_);
  }

  /**
   *
   * @dev publicMint
   *
   */
  function publicMint(uint256) external payable whenNotPaused {
    _publicMint();
  }

  function _publicMint() internal {
    if (publicMintStatus() != MintStatus.open) revert PublicMintClosed();

    uint256 publicMintsForAddress = publicMintAllocationMinted[msg.sender];

    if (publicMintsForAddress != 0) {
      revert MaxPublicMintAllowanceExceeded({
        requested: 1,
        alreadyMinted: 1,
        maxAllowance: 1
      });
    }
    publicMintAllocationMinted[msg.sender] += 1;

    // Cache the next tokenId from the NFT:
    uint256 nextTokenId = smashverseTitansContract.totalMinted();

    smashverseSaleContract.listMint(
      Sublist(0, 0),
      totalFreeMintQuantity,
      1,
      0,
      0,
      freeMintProof
    );

    smashverseTitansContract.safeTransferFrom(
      address(this),
      msg.sender,
      nextTokenId,
      ""
    );

    emit SmashMint(msg.sender, MintingType.publicMint, 0, 1);
  }

  /**
   *
   * @dev _allowlistFreeMint:
   *
   */
  function _allowlistFreeMint(
    Sublist memory sublist_,
    uint256 quantityEligible_,
    uint256 quantityToMint_,
    uint256 unitPrice_,
    uint256 vestingInDays_,
    bytes32[] calldata proof_
  ) internal {
    (address minter, bool valid) = merkleListValid(
      msg.sender,
      sublist_,
      quantityEligible_,
      proof_,
      unitPrice_,
      vestingInDays_,
      listMerkleRoot
    );

    MintStatus status;
    (status, , ) = listMintStatus(sublist_.sublistInteger);
    if (status != MintStatus.open) revert ThisListMintIsClosed();

    if (!valid) revert ProofInvalid();
    // See if this address has already minted its full allocation:

    if (listMintAllocationMinted[minter][sublist_.sublistInteger] != 0)
      revert RequestingMoreThanRemainingAllocation({
        requested: quantityToMint_,
        remainingAllocation: 0
      });

    listMintAllocationMinted[minter][
      sublist_.sublistInteger
    ] += quantityToMint_;

    // Cache the next tokenId from the NFT:
    uint256 nextTokenId = smashverseTitansContract.totalMinted();

    smashverseSaleContract.listMint(
      Sublist(0, 0),
      totalFreeMintQuantity,
      1,
      0,
      0,
      freeMintProof
    );

    smashverseTitansContract.safeTransferFrom(
      address(this),
      msg.sender,
      nextTokenId,
      ""
    );

    emit SmashMint(
      msg.sender,
      MintingType.allowlistMint,
      sublist_.sublistInteger,
      quantityToMint_
    );
  }

  /**
   *
   * @dev merkleListValid: Eligibility check for the merkleroot controlled minting. This can be called from front-end (for example to control
   * screen components that indicate if the connected address is eligible) as well as from within the contract.
   *
   * Function flow is as follows:
   * (1) Check that the address and eligible quantity are in the rafflelist.
   *   -> (1a) If NOT then go to (2),
   *   -> (1b) if it IS go to (4).
   * (2) If (1) is false, check if the sender address is a proxy for a nominator,
   *   -> (2a) If there is NO nominator exit with false eligibility and reason "Mint proof invalid"
   *   -> (2b) if there IS a nominator go to (3)
   * (3) Check if the nominator is in the rafflelist.
   *   -> (3a) if NOT then exit with false eligibility and reason "Mint proof invalid"
   *   -> (3b) if it IS then go to (4), having set the minter to the nominator which is the eligible address for this mint.
   * (4) Check if this minter address has already minted. If so, exit with false eligibility and reason "Requesting more than remaining allocation"
   * (5) All checks passed, return elibility = true, the delivery address and valid minter adress.
   *
   */
  function merkleListValid(
    address addressToCheck_,
    Sublist memory sublist_,
    uint256 quantityEligible_,
    bytes32[] calldata proof_,
    uint256 unitPrice_,
    uint256 vestingInDays_,
    bytes32 root_
  ) public view returns (address minter, bool success) {
    // Default delivery and minter address are the addresses passed in, which from the contract will be the msg.sender:
    minter = addressToCheck_;

    bytes32 leaf = _getListHash(
      addressToCheck_,
      sublist_,
      quantityEligible_,
      unitPrice_,
      vestingInDays_
    );

    // (1) Check rafflelist for addressToCheck_:
    if (MerkleProof.verify(proof_, root_, leaf) == false) {
      // (2) addressToCheck_ is not on the list. Check if they are a cold EPS address for a hot EPS address:
      if (address(epsDeligateRegister) != address(0)) {
        address epsCold;
        address[] memory epsAddresses;
        (epsAddresses, ) = epsDeligateRegister.getAllAddresses(
          addressToCheck_,
          1
        );

        if (epsAddresses.length > 1) {
          epsCold = epsAddresses[1];
        } else {
          return (minter, false);
        }

        // (3) If this matches a proxy record and the nominator isn't the addressToCheck_ we have a nominator to check
        if (epsCold != addressToCheck_) {
          leaf = _getListHash(
            epsCold,
            sublist_,
            quantityEligible_,
            unitPrice_,
            vestingInDays_
          );

          if (MerkleProof.verify(proof_, root_, leaf) == false) {
            // (3a) Not valid at either address. Say so and return
            return (minter, false);
          } else {
            // (3b) There is a value at the nominator. The nominator is the minter, use it to check and track allowance.
            minter = epsCold;
          }
        } else {
          // (2a) Sender isn't on the list, and there is no proxy to consider:
          return (minter, false);
        }
      }
    }

    // (5) Can only reach here for a valid address and quantity:
    return (minter, true);
  }

  /**
   *
   * @dev _getListHash: Get hash of information for the rafflelist mint.
   *
   */
  function _getListHash(
    address minter_,
    Sublist memory sublist_,
    uint256 quantity_,
    uint256 unitPrice_,
    uint256 vestingInDays_
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          minter_,
          sublist_.sublistPosition,
          quantity_,
          unitPrice_,
          vestingInDays_,
          sublist_.sublistInteger
        )
      );
  }

  /**
   *
   * @dev checkAllocation: Eligibility check for all lists. Will return a count of remaining allocation (if any) and an optional
   * status code.
   */
  function checkAllocation(
    Sublist memory sublist_,
    uint256 quantityEligible_,
    uint256 unitPrice_,
    uint256 vestingInDays_,
    bytes32[] calldata proof_,
    address addressToCheck_
  ) external view returns (uint256 allocation, AllocationCheck statusCode) {
    (address minter, bool valid) = merkleListValid(
      addressToCheck_,
      sublist_,
      quantityEligible_,
      proof_,
      unitPrice_,
      vestingInDays_,
      listMerkleRoot
    );

    if (!valid) {
      return (0, AllocationCheck.invalidProof);
    } else {
      allocation =
        quantityEligible_ -
        listMintAllocationMinted[minter][sublist_.sublistInteger];
      if (allocation > 0) {
        return (allocation, AllocationCheck.hasAllocation);
      } else {
        return (allocation, AllocationCheck.allocationExhausted);
      }
    }
  }

  // =======================================
  // ADMINISTRATION
  // =======================================

  /**
   *
   * @dev setSublistConfig:
   *
   */
  function setSublistConfig(
    uint256 sublistInteger_,
    uint256 start_,
    uint256 end_,
    uint256 supply_
  ) external onlyOwner {
    if (listDetailsLocked) {
      revert ListDetailsLocked();
    }

    subListConfig[sublistInteger_].start = start_;
    subListConfig[sublistInteger_].end = end_;
    subListConfig[sublistInteger_].phaseMaxSupply = supply_;

    emit SublistConfigSet(sublistInteger_, start_, end_, supply_);
  }

  /**
   *
   * @dev setList: Set the merkleroot
   *
   */
  function setList(bytes32 merkleRoot_) external onlyOwner {
    if (listDetailsLocked) {
      revert ListDetailsLocked();
    }

    listMerkleRoot = merkleRoot_;

    emit MerkleRootSet(merkleRoot_);
  }

  /**
   *
   *
   * @dev setpublicMintStart: Allow owner to set minting open time.
   *
   *
   */
  function setpublicMintStart(uint32 time_) external onlyOwner {
    if (publicMintingClosedForever) {
      revert MintingIsClosedForever();
    }
    publicMintStart = time_;
  }

  /**
   *
   *
   * @dev setpublicMintEnd: Allow owner to set minting closed time.
   *
   *
   */
  function setpublicMintEnd(uint32 time_) external onlyOwner {
    if (publicMintingClosedForever) {
      revert MintingIsClosedForever();
    }
    publicMintEnd = time_;
  }

  /**
   *
   *
   * @dev setPublicMintingClosedForeverCannotBeUndone: Allow owner to set minting complete
   * Enter confirmation value of "SmashversePrimarySale" to confirm that you are closing
   * this mint forever.
   *
   *
   */
  function setPublicMintingClosedForeverCannotBeUndone(
    string memory confirmation_
  ) external onlyOwner {
    string memory expectedValue = "SmashversePrimarySale";
    if (
      keccak256(abi.encodePacked(confirmation_)) ==
      keccak256(abi.encodePacked(expectedValue))
    ) {
      publicMintEnd = uint32(block.timestamp);
      publicMintingClosedForever = true;
    } else {
      revert IncorrectConfirmationValue();
    }
  }

  /**
   *
   *
   * @dev setListDetailsLockedForeverCannotBeUndone: Allow owner to set minting complete
   * Enter confirmation value of "SmashversePrimarySale" to confirm that you are closing
   * this mint forever.
   *
   *
   */
  function setListDetailsLockedForeverCannotBeUndone(
    string memory confirmation_
  ) external onlyOwner {
    string memory expectedValue = "SmashversePrimarySale";
    if (
      keccak256(abi.encodePacked(confirmation_)) ==
      keccak256(abi.encodePacked(expectedValue))
    ) {
      listDetailsLocked = true;
    } else {
      revert IncorrectConfirmationValue();
    }
  }

  /**
   *
   *
   * @dev pause: Allow owner to pause.
   *
   *
   */
  function pause() external onlyOwner {
    require(
      publicMintStart == 0 ||
        block.timestamp < (publicMintStart + pauseCutOffInDays * 1 days),
      "Pause cutoff passed"
    );
    _pause();
  }

  /**
   *
   *
   * @dev unpause: Allow owner to unpause.
   *
   *
   */
  function unpause() external onlyOwner {
    _unpause();
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
   * @dev setProofsAndTotalQuantities
   *
   */
  function setProofsAndTotalQuantities(
    bytes32[] calldata mintPassProof_,
    uint256 totalMintPassMintQuantity_,
    bytes32[] calldata freeMintProof_,
    uint256 totalFreeMintQuantity_
  ) external onlyOwner {
    mintPassProof = mintPassProof_;
    totalMintPassMintQuantity = totalMintPassMintQuantity_;
    freeMintProof = freeMintProof_;
    totalFreeMintQuantity = totalFreeMintQuantity_;
  }

  // =======================================
  // FINANCE
  // =======================================

  /**
   *
   *
   * @dev withdrawETH: A withdraw function to allow ETH to be withdrawn to the vesting contract.
   * Note that this can be performed by anyone, as all funds flow to the vesting contract only.
   *
   *
   */
  function withdrawETH(uint256 amount) external {
    (bool success, ) = beneficiary.call{value: amount}("");
    if (!success) revert TransferFailed();
  }

  /**
   *
   *
   * @dev withdrawERC20: A withdraw function to allow ERC20s to be withdrawn to the vesting contract.
   * Note that this can be performed by anyone, as all funds flow to the vesting contract only.
   *
   *
   */
  function withdrawERC20(IERC20 token, uint256 amount) external {
    token.transfer(beneficiary, amount);
  }

  /**
   *
   * @dev Revert unexpected ETH and function calls
   *
   */
  receive() external payable {
    require(msg.sender == owner(), "Only owner can fund contract");
  }

  fallback() external payable {
    revert();
  }
}