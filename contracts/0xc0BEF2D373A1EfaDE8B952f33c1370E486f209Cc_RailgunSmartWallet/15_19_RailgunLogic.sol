// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { StorageSlot } from "@openzeppelin/contracts/utils/StorageSlot.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { SNARK_SCALAR_FIELD, TokenType, UnshieldType, TokenData, ShieldCiphertext, CommitmentCiphertext, CommitmentPreimage, Transaction } from "./Globals.sol";

import { Verifier } from "./Verifier.sol";
import { Commitments } from "./Commitments.sol";
import { TokenBlocklist } from "./TokenBlocklist.sol";
import { PoseidonT4 } from "./Poseidon.sol";

// Core validation logic should remain here

/**
 * @title Railgun Logic
 * @author Railgun Contributors
 * @notice Logic to process transactions
 */
contract RailgunLogic is Initializable, OwnableUpgradeable, Commitments, TokenBlocklist, Verifier {
  using SafeERC20 for IERC20;

  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading

  // Treasury variables
  address payable public treasury; // Treasury contract
  uint120 private constant BASIS_POINTS = 10000; // Number of basis points that equal 100%
  // % fee in 100ths of a %. 100 = 1%.
  uint120 public shieldFee; // Previously called as depositFee
  uint120 public unshieldFee; // Previously called withdrawFee

  // Flat fee in wei that applies to NFT transactions
  // LOGIC IS NOT IMPLEMENTED
  // TODO: Revisit adapt module structure if we want to implement this
  uint256 public nftFee; // Previously called transferFee

  // Safety vectors
  mapping(uint256 => bool) public snarkSafetyVector;

  // Token ID mapping
  mapping(bytes32 => TokenData) public tokenIDMapping;

  // Last event block - to assist with scanning
  uint256 public lastEventBlock;

  // Treasury events
  event TreasuryChange(address treasury);
  event FeeChange(uint256 shieldFee, uint256 unshieldFee, uint256 nftFee);

  // Transaction events
  event Transact(
    uint256 treeNumber,
    uint256 startPosition,
    bytes32[] hash,
    CommitmentCiphertext[] ciphertext
  );

  event Shield(
    uint256 treeNumber,
    uint256 startPosition,
    CommitmentPreimage[] commitments,
    ShieldCiphertext[] shieldCiphertext,
    uint256[] fees
  );

  event Unshield(address to, TokenData token, uint256 amount, uint256 fee);

  event Nullified(uint16 treeNumber, bytes32[] nullifier);

  /**
   * @notice Initialize Railgun contract
   * @dev OpenZeppelin initializer ensures this can only be called once
   * This function also calls initializers on inherited contracts
   * @param _treasury - address to send usage fees to
   * @param _shieldFee - Shield fee
   * @param _unshieldFee - Unshield fee
   * @param _nftFee - Flat fee in wei that applies to NFT transactions
   * @param _owner - governance contract
   */
  function initializeRailgunLogic(
    address payable _treasury,
    uint120 _shieldFee,
    uint120 _unshieldFee,
    uint256 _nftFee,
    address _owner
  ) public initializer {
    // Call initializers
    OwnableUpgradeable.__Ownable_init();
    Commitments.initializeCommitments();

    // Set treasury and fee
    changeTreasury(_treasury);
    changeFee(_shieldFee, _unshieldFee, _nftFee);

    // Change Owner
    OwnableUpgradeable.transferOwnership(_owner);

    // Set safety vectors
    snarkSafetyVector[11991246288605609459798790887503763024866871101] = true;
    snarkSafetyVector[135932600361240492381964832893378343190771392134] = true;
    snarkSafetyVector[1165567609304106638376634163822860648671860889162] = true;
  }

  /**
   * @notice Change treasury address, only callable by owner (governance contract)
   * @dev This will change the address of the contract we're sending the fees to in the future
   * it won't transfer tokens already in the treasury
   * @param _treasury - Address of new treasury contract
   */
  function changeTreasury(address payable _treasury) public onlyOwner {
    // Do nothing if the new treasury address is same as the old
    if (treasury != _treasury) {
      // Change treasury
      treasury = _treasury;

      // Emit treasury change event
      emit TreasuryChange(_treasury);
    }
  }

  /**
   * @notice Change fee rate for future transactions
   * @param _shieldFee - Shield fee
   * @param _unshieldFee - Unshield fee
   * @param _nftFee - Flat fee in wei that applies to NFT transactions
   */
  function changeFee(uint120 _shieldFee, uint120 _unshieldFee, uint256 _nftFee) public onlyOwner {
    if (_shieldFee != shieldFee || _unshieldFee != unshieldFee || _nftFee != nftFee) {
      require(_shieldFee <= BASIS_POINTS / 2, "RailgunLogic: Shield Fee exceeds 50%");
      require(_unshieldFee <= BASIS_POINTS / 2, "RailgunLogic: Unshield Fee exceeds 50%");

      // Change fee
      shieldFee = _shieldFee;
      unshieldFee = _unshieldFee;
      nftFee = _nftFee;

      // Emit fee change event
      emit FeeChange(_shieldFee, _unshieldFee, _nftFee);
    }
  }

  /**
   * @notice Get base and fee amount
   * @param _amount - Amount to calculate for
   * @param _isInclusive - Whether the amount passed in is inclusive of the fee
   * @param _feeBP - Fee basis points
   */
  function getFee(
    uint136 _amount,
    bool _isInclusive,
    uint120 _feeBP
  ) public pure returns (uint120, uint120) {
    // Expand width of amount to uint136 to accommodate full size of (2**120-1)*BASIS_POINTS

    // Base is the amount sent into the railgun contract or sent to the target eth address
    // for shields and unshields respectively
    uint136 base;
    // Fee is the amount sent to the treasury
    uint136 fee;

    if (_isInclusive) {
      base = _amount - (_amount * _feeBP) / BASIS_POINTS;
      fee = _amount - base;
    } else {
      base = _amount;
      fee = (BASIS_POINTS * base) / (BASIS_POINTS - _feeBP) - base;
    }

    return (uint120(base), uint120(fee));
  }

  /**
   * @notice Gets token ID value from tokenData
   */
  function getTokenID(TokenData memory _tokenData) public pure returns (bytes32) {
    // ERC20 tokenID is just the address
    if (_tokenData.tokenType == TokenType.ERC20) {
      return bytes32(uint256(uint160(_tokenData.tokenAddress)));
    }

    // Other token types are the keccak256 hash of the token data
    return bytes32(uint256(keccak256(abi.encode(_tokenData))) % SNARK_SCALAR_FIELD);
  }

  /**
   * @notice Hashes a commitment
   */
  function hashCommitment(
    CommitmentPreimage memory _commitmentPreimage
  ) public pure returns (bytes32) {
    return
      PoseidonT4.poseidon(
        [
          _commitmentPreimage.npk,
          getTokenID(_commitmentPreimage.token),
          bytes32(uint256(_commitmentPreimage.value))
        ]
      );
  }

  /**
   * @notice Checks commitment ranges for validity
   * @return valid, reason
   */
  function validateCommitmentPreimage(
    CommitmentPreimage calldata _note
  ) public view returns (bool, string memory) {
    // Note must be more than 0
    if (_note.value == 0) return (false, "Invalid Note Value");

    // Note token must not be blocklisted
    if (TokenBlocklist.tokenBlocklist[_note.token.tokenAddress])
      return (false, "Unsupported Token");

    // Note NPK must be in field
    if (uint256(_note.npk) >= SNARK_SCALAR_FIELD) return (false, "Invalid Note NPK");

    // ERC721 notes should have a value of 1
    if (_note.token.tokenType == TokenType.ERC721 && _note.value != 1)
      return (false, "Invalid NFT Note Value");

    return (true, "");
  }

  /**
   * @notice Transfers tokens to contract and adjusts preimage with fee values
   * @param _note - note to process
   * @return adjusted note
   */
  function transferTokenIn(
    CommitmentPreimage calldata _note
  ) internal returns (CommitmentPreimage memory, uint256) {
    // validateTransaction and accumulateAndNullifyTransaction functions MUST be called
    // in that order BEFORE invoking this function to process an unshield on a transaction
    // else reentrancy attacks are possible

    CommitmentPreimage memory adjustedNote;
    uint256 treasuryFee;

    // Process shield request
    if (_note.token.tokenType == TokenType.ERC20) {
      // ERC20

      // Get ERC20 interface
      IERC20 token = IERC20(address(uint160(_note.token.tokenAddress)));

      // Get base and fee amounts
      (uint120 base, uint120 fee) = getFee(_note.value, true, RailgunLogic.shieldFee);

      // Store treasury fee
      treasuryFee = fee;

      // Set adjusted preimage
      adjustedNote = CommitmentPreimage({ npk: _note.npk, value: base, token: _note.token });

      // Get balance before
      uint256 balanceBefore = token.balanceOf(address(this));

      // Transfer base to contract address
      token.safeTransferFrom(address(msg.sender), address(this), base);

      // Get balance after
      uint256 balanceAfter = token.balanceOf(address(this));

      // Check ERC20 tokens transferred
      require(balanceAfter - balanceBefore == base, "RailgunLogic: ERC20 transfer failed");

      // Transfer fee to treasury
      token.safeTransferFrom(address(msg.sender), treasury, fee);
    } else if (_note.token.tokenType == TokenType.ERC721) {
      // ERC721 token

      // Get ERC721 interface
      IERC721 token = IERC721(address(uint160(_note.token.tokenAddress)));

      // Treasury fee will be 0
      treasuryFee = 0;

      // No need to adjust note
      adjustedNote = _note;

      // Set tokenID mapping
      tokenIDMapping[getTokenID(_note.token)] = _note.token;

      // Transfer NFT to contract address
      token.transferFrom(address(msg.sender), address(this), _note.token.tokenSubID);

      // Check ERC721 transferred
      require(
        token.ownerOf(_note.token.tokenSubID) == address(this),
        "RailgunLogic: ERC721 didn't transfer"
      );
    } else {
      // ERC1155 token
      revert("RailgunLogic: ERC1155 not yet supported");
    }

    return (adjustedNote, treasuryFee);
  }

  /**
   * @notice Transfers tokens to contract and adjusts preimage with fee values
   * @param _note - note to process
   */
  function transferTokenOut(CommitmentPreimage calldata _note) internal {
    // validateTransaction and accumulateAndNullifyTransaction functions MUST be called
    // in that order BEFORE invoking this function to process an unshield on a transaction
    // else reentrancy attacks are possible

    // Process unshield request
    if (_note.token.tokenType == TokenType.ERC20) {
      // ERC20

      // Get ERC20 interface
      IERC20 token = IERC20(address(uint160(_note.token.tokenAddress)));

      // Get base and fee amounts
      (uint120 base, uint120 fee) = getFee(_note.value, true, unshieldFee);

      // Transfer base to output address
      token.safeTransfer(address(uint160(uint256(_note.npk))), base);

      // Transfer fee to treasury
      token.safeTransfer(treasury, fee);

      // Emit unshield event
      emit Unshield(address(uint160(uint256(_note.npk))), _note.token, base, fee);
    } else if (_note.token.tokenType == TokenType.ERC721) {
      // ERC721 token

      // Get ERC721 interface
      IERC721 token = IERC721(address(uint160(_note.token.tokenAddress)));

      // Transfer NFT to output address
      token.transferFrom(
        address(this),
        address(uint160(uint256(_note.npk))),
        _note.token.tokenSubID
      );

      // Emit unshield event
      emit Unshield(address(uint160(uint256(_note.npk))), _note.token, 1, 0);
    } else {
      // ERC1155 token
      revert("RailgunLogic: ERC1155 not yet supported");
    }
  }

  /**
   * @notice Safety check for badly behaving code
   */
  function checkSafetyVectors() external {
    // Set safety bit
    StorageSlot
      .getBooleanSlot(0x8dea8703c3cf94703383ce38a9c894669dccd4ca8e65ddb43267aa0248711450)
      .value = true;

    // Setup behavior check
    bool result = false;

    // Execute behavior check
    // solhint-disable-next-line no-inline-assembly
    assembly {
      mstore(0, caller())
      mstore(32, snarkSafetyVector.slot)
      let hash := keccak256(0, 64)
      result := sload(hash)
    }

    require(result, "RailgunLogic: Unsafe vectors");
  }

  /**
   * @notice Adds safety vector
   */
  function addVector(uint256 vector) external onlyOwner {
    snarkSafetyVector[vector] = true;
  }

  /**
   * @notice Removes safety vector
   */
  function removeVector(uint256 vector) external onlyOwner {
    snarkSafetyVector[vector] = false;
  }

  /**
   * @notice Sums number commitments in transaction batch
   */
  function sumCommitments(Transaction[] calldata _transactions) public pure returns (uint256) {
    uint256 commitments = 0;

    for (
      uint256 transactionIter = 0;
      transactionIter < _transactions.length;
      transactionIter += 1
    ) {
      // The last commitment should NOT be counted if transaction includes unshield
      // The ciphertext length is validated in the transaction validity function to reflect this
      commitments += _transactions[transactionIter].boundParams.commitmentCiphertext.length;
    }

    return commitments;
  }

  /**
   * @notice Verifies transaction validity
   * @return valid, reason
   */
  function validateTransaction(
    Transaction calldata _transaction
  ) public view returns (bool, string memory) {
    // Gas price of eth transaction should be equal or greater than railgun transaction specified min gas price
    // This will only work correctly for type 0 transactions, set to 0 for EIP-1559 transactions
    if (tx.gasprice < _transaction.boundParams.minGasPrice) return (false, "Gas price too low");

    // Adapt contract must either equal 0 or msg.sender
    if (
      _transaction.boundParams.adaptContract != address(0) &&
      _transaction.boundParams.adaptContract != msg.sender
    ) return (false, "Invalid Adapt Contract as Sender");

    // ChainID should match the current EVM chainID
    if (_transaction.boundParams.chainID != block.chainid) return (false, "ChainID mismatch");

    // Merkle root must be a seen historical root
    if (!Commitments.rootHistory[_transaction.boundParams.treeNumber][_transaction.merkleRoot])
      return (false, "Invalid Merkle Root");

    if (_transaction.boundParams.unshield != UnshieldType.NONE) {
      // Ensure ciphertext length matches the commitments length (minus 1 for unshield output)
      if (
        _transaction.boundParams.commitmentCiphertext.length != _transaction.commitments.length - 1
      ) return (false, "Invalid Note Ciphertext Array Length");

      // Check unshield preimage hash is correct
      bytes32 hash;

      if (_transaction.boundParams.unshield == UnshieldType.REDIRECT) {
        // If redirect is allowed unshield MUST be submitted by original recipient
        hash = hashCommitment(
          CommitmentPreimage({
            npk: bytes32(uint256(uint160(msg.sender))),
            token: _transaction.unshieldPreimage.token,
            value: _transaction.unshieldPreimage.value
          })
        );
      } else {
        hash = hashCommitment(_transaction.unshieldPreimage);
      }

      // Check hash equals the last commitment in array
      if (hash != _transaction.commitments[_transaction.commitments.length - 1])
        return (false, "Invalid Withdraw Note");
    } else {
      // Ensure ciphertext length matches the commitments length
      if (_transaction.boundParams.commitmentCiphertext.length != _transaction.commitments.length)
        return (false, "Invalid Note Ciphertext Array Length");
    }

    // Verify SNARK proof
    if (!Verifier.verify(_transaction)) return (false, "Invalid Snark Proof");

    return (true, "");
  }

  /**
   * @notice Accumulates transaction fields and nullifies nullifiers
   * @param _transaction - transaction to process
   * @param _commitments - commitments accumulator
   * @param _commitmentsStartOffset - number of commitments already in the accumulator
   * @param _ciphertext - commitment ciphertext accumulator, count will be identical to commitments accumulator
   * @return New nullifier start offset, new commitments start offset
   */
  function accumulateAndNullifyTransaction(
    Transaction calldata _transaction,
    bytes32[] memory _commitments,
    uint256 _commitmentsStartOffset,
    CommitmentCiphertext[] memory _ciphertext
  ) internal returns (uint256) {
    // Loop through each nullifier
    for (
      uint256 nullifierIter = 0;
      nullifierIter < _transaction.nullifiers.length;
      nullifierIter += 1
    ) {
      // If nullifier has been seen before revert
      require(
        !Commitments.nullifiers[_transaction.boundParams.treeNumber][
          _transaction.nullifiers[nullifierIter]
        ],
        "RailgunLogic: Note already spent"
      );

      // Set nullifier to seen
      Commitments.nullifiers[_transaction.boundParams.treeNumber][
        _transaction.nullifiers[nullifierIter]
      ] = true;
    }

    // Emit nullifier event
    emit Nullified(_transaction.boundParams.treeNumber, _transaction.nullifiers);

    // Loop through each commitment
    for (
      uint256 commitmentsIter = 0;
      // The last commitment should NOT be accumulated if transaction includes unshield
      // The ciphertext length is validated in the transaction validity function to reflect this
      commitmentsIter < _transaction.boundParams.commitmentCiphertext.length;
      commitmentsIter += 1
    ) {
      // Push commitment to commitments accumulator
      _commitments[_commitmentsStartOffset + commitmentsIter] = _transaction.commitments[
        commitmentsIter
      ];

      // Push ciphertext to ciphertext accumulator
      _ciphertext[_commitmentsStartOffset + commitmentsIter] = _transaction
        .boundParams
        .commitmentCiphertext[commitmentsIter];
    }

    // Return new starting offset
    return _commitmentsStartOffset + _transaction.boundParams.commitmentCiphertext.length;
  }

  uint256[43] private __gap;
}