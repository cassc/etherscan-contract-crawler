// SPDX-License-Identifier: MIT

/**
* @team: Asteria Labs
* @author: Lambdalf the White
*/

pragma solidity 0.8.17;

import '@lambdalf-dev/ethereum-contracts/contracts/interfaces/IArrayErrors.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC1155Errors.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/interfaces/INFTSupplyErrors.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC165.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC1155.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC1155Receiver.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC1155MetadataURI.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/utils/ERC173.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/utils/ERC2981.sol';
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

contract Cover is 
IERC1155Errors, IArrayErrors, INFTSupplyErrors,
IERC165, IERC1155, IERC1155MetadataURI,
UpdatableOperatorFilterer, ERC2981, ERC173 {
  // **************************************
  // *****    BYTECODE  VARIABLES     *****
  // **************************************
    uint256 public constant DEFAULT_SERIES_ID = 1;
    uint256 public constant VOLUME_1 = 100;
    uint256 public constant VOLUME_2 = 200;
    uint256 public constant VOLUME_3 = 300;
    uint256 public constant VOLUME_4 = 400;
    uint256 public constant VOLUME_5 = 500;
    uint256 public constant VOLUME_6 = 600;
    uint256 public constant VOLUME_7 = 700;
    address public constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    address public constant DEFAULT_OPERATOR_FILTER_REGISTRY = address(0x000000000000AAeB6D7670E522A718067333cd4E);
    string public constant name = "Life of HEL";
    string public constant symbol = "LOH";
  // **************************************

  // **************************************
  // *****     STORAGE VARIABLES      *****
  // **************************************
    string  private _uri = "https://mint.lifeofhel.xyz/api/";
    // List of valid series
    BitMaps.BitMap private _validSeries;
    // Series ID mapped to balances
    mapping (uint256 => mapping(address => uint256)) private _balances;
    // Token owner mapped to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;
    // Series ID mapped to burner
    mapping (uint256 => address) public burners;
    // Series ID mapped to minter
    mapping (uint256 => address) public minters;
  // **************************************

  // **************************************
  // *****           ERROR            *****
  // **************************************
    /**
    * @dev Thrown when non burner tries to burn a token.
    * 
    * @param account the address trying to burn
    * @param id the series ID being burned
    */
    error NON_BURNER(address account, uint256 id);
    /**
    * @dev Thrown when non minter tries to mint a token.
    * 
    * @param account the address trying to mint
    * @param id the series ID being minted
    */
    error NON_MINTER(address account, uint256 id);
  // **************************************

  constructor(address royaltyRecipent_)
  UpdatableOperatorFilterer(DEFAULT_OPERATOR_FILTER_REGISTRY, DEFAULT_SUBSCRIPTION, true) {
    _setOwner(msg.sender);
    _setRoyaltyInfo(royaltyRecipent_, 750);
  }

  // **************************************
  // *****          MODIFIER          *****
  // **************************************
    /**
    * @dev Ensures that `id_` is a valid series
    * 
    * @param id_ the series id to validate 
    */
    modifier isValidSeries(uint256 id_) {
      if (! BitMaps.get(_validSeries, id_)) {
        revert IERC1155_NON_EXISTANT_TOKEN(id_);
      }
      _;
    }
    /**
    * @dev Ensures that `sender_` is a registered burner
    * 
    * @param sender_ the address to verify
    * @param id_ the series id to validate 
    */
    modifier isBurner(address sender_, uint256 id_) {
      if (burners[id_] != sender_) {
        revert NON_BURNER(sender_, id_);
      }
      _;
    }
    /**
    * @dev Ensures that `sender_` is a registered minter
    * 
    * @param sender_ the address to verify
    * @param id_ the series id to validate 
    */
    modifier isMinter(address sender_, uint256 id_) {
      if (minters[id_] != sender_) {
        revert NON_MINTER(sender_, id_);
      }
      _;
    }
  // **************************************

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
    /**
    * @dev Internal function that checks if the receiver address is able to handle batches of IERC1155 tokens.
    * 
    * @param operator_ address sending the transaction
    * @param from_ address from where the tokens are sent
    * @param to_ address receiving the tokens
    * @param ids_ list of token types being sent
    * @param amounts_ list of amounts of tokens being sent
    * @param data_ additional data to accompany the call
    */
    function _doSafeBatchTransferAcceptanceCheck(
      address operator_,
      address from_,
      address to_,
      uint256[] memory ids_,
      uint256[] memory amounts_,
      bytes memory data_
    ) private {
      uint256 _size_;
      assembly {
        _size_ := extcodesize(to_)
      }
      if (_size_ > 0) {
        try IERC1155Receiver(to_).onERC1155BatchReceived(operator_, from_, ids_, amounts_, data_) returns (bytes4 retval) {
          if (retval != IERC1155Receiver.onERC1155BatchReceived.selector) {
            revert IERC1155_REJECTED_TRANSFER();
          }
        }
        catch (bytes memory reason) {
          if (reason.length == 0) {
            revert IERC1155_REJECTED_TRANSFER();
          }
          else {
            assembly {
              revert(add(32, reason), mload(reason))
            }
          }
        }
      }
    }
    /**
    * @dev Internal function that checks if the receiver address is able to handle IERC1155 tokens.
    * 
    * @param operator_ address sending the transaction
    * @param from_ address from where the tokens are sent
    * @param to_ address receiving the tokens
    * @param id_ the token type being sent
    * @param amount_ the amount of tokens being sent
    * @param data_ additional data to accompany the call
    */
    function _doSafeTransferAcceptanceCheck(
      address operator_,
      address from_,
      address to_,
      uint256 id_,
      uint256 amount_,
      bytes memory data_
    ) private {
      uint256 _size_;
      assembly {
        _size_ := extcodesize(to_)
      }
      if (_size_ > 0) {
        try IERC1155Receiver(to_).onERC1155Received(operator_, from_, id_, amount_, data_) returns (bytes4 retval) {
          if (retval != IERC1155Receiver.onERC1155Received.selector) {
            revert IERC1155_REJECTED_TRANSFER();
          }
        }
        catch (bytes memory reason) {
          if (reason.length == 0) {
            revert IERC1155_REJECTED_TRANSFER();
          }
          else {
            assembly {
              revert(add(32, reason), mload(reason))
            }
          }
        }
      }
    }
    /**
    * @dev Internal function that checks if `operator_` is allowed to manage tokens on behalf of `owner_`
    * 
    * @param owner_ address owning the tokens
    * @param operator_ address to check approval for
    */
    function _isApprovedOrOwner(address owner_, address operator_) internal view returns (bool) {
      return owner_ == operator_ || isApprovedForAll(owner_, operator_);
    }
    /**
    * @dev Internal function that checks whether `id_` is an existing series.
    * 
    * @param id_ the token type being verified
    */
    function _isValidSeries(uint256 id_) internal view returns (bool) {
      return BitMaps.get(_validSeries, id_);
    }
    /**
    * @dev Internal function that mints `amount_` tokens from series `id_` into `recipient_`.
    * 
    * @param recipient_ the address receiving the tokens
    * @param id_ the token type being sent
    * @param amount_ the amount of tokens being sent
    */
    // function _mint(address recipient_, uint256 id_, uint256 amount_) internal {
    //   unchecked {
    //     _balances[id_][recipient_] += amount_;
    //   }
    //   emit TransferSingle(msg.sender, address(0), recipient_, id_, amount_);
    // }
    /**
    * @dev Converts a `uint256` to its ASCII `string` decimal representation.
    * 
    * @param value_ the value being converted to its string representation
    */
    function _toString(uint256 value_) internal pure virtual returns (string memory str) {
      assembly {
        // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
        // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
        // We will need 1 word for the trailing zeros padding, 1 word for the length,
        // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
        let m := add(mload(0x40), 0xa0)
        // Update the free memory pointer to allocate.
        mstore(0x40, m)
        // Assign the `str` to the end.
        str := sub(m, 0x20)
        // Zeroize the slot after the string.
        mstore(str, 0)

        // Cache the end of the memory to calculate the length later.
        let end := str

        // We write the string from rightmost digit to leftmost digit.
        // The following is essentially a do-while loop that also handles the zero case.
        // prettier-ignore
        // solhint-disable-next-line
        for { let temp := value_ } 1 {} {
          str := sub(str, 1)
          // Write the character to the pointer.
          // The ASCII index of the "0" character is 48.
          mstore8(str, add(48, mod(temp, 10)))
          // Keep dividing `temp` until zero.
          temp := div(temp, 10)
          // prettier-ignore
          if iszero(temp) { break }
        }

        let length := sub(end, str)
        // Move the pointer 32 bytes leftwards to make room for the length.
        str := sub(str, 0x20)
        // Store the length.
        mstore(str, length)
      }
    }
  // **************************************

  // **************************************
  // *****          DELEGATE          *****
  // **************************************
    // *********
    // * Cover *
    // *********
      /**
      * @notice Burns `qty_` amount of `id_` on behalf of `tokenOwner_`.
      * 
      * @param id_ the series id to mint 
      * @param qty_ amount of tokens to mint
      * @param tokenOwner_ address owning the tokens
      * 
      * Requirements:
      * 
      * - `id_` must be a valid series
      * - Caller must be allowed to burn tokens
      * - `tokenOwner_` must own at least `qty_` tokens of series `id_`
      */
      function burnFrom(uint256 id_, uint256 qty_, address tokenOwner_)
      external
      isValidSeries(id_)
      isBurner(msg.sender, id_) {
        uint256 _balance_ = _balances[id_][tokenOwner_];
        if (_balance_ < qty_) {
          revert IERC1155_INSUFFICIENT_BALANCE(tokenOwner_, id_, _balance_);
        }
        unchecked {
          _balances[id_][tokenOwner_] -= qty_;
        }
        emit TransferSingle(msg.sender, tokenOwner_, address(0), id_, qty_);
      }
      /**
      * @notice Mints `qty_` amount of `id_` to the `recipient_` address.
      * 
      * @param id_ the series id to mint 
      * @param qty_ amount of tokens to mint
      * @param recipient_ address receiving the tokens
      * 
      * Requirements:
      * 
      * - `id_` must be a valid series
      * - Caller must be allowed to mint tokens
      */
      function mintTo(uint256 id_, uint256 qty_, address recipient_)
      external
      isValidSeries(id_)
      isMinter(msg.sender, id_) {
        unchecked {
          _balances[id_][recipient_] += qty_;
        }
        emit TransferSingle(msg.sender, address(0), recipient_, id_, qty_);
      }
    // *********
  // **************************************

  // **************************************
  // *****           PUBLIC           *****
  // **************************************
    // ************
    // * IERC1155 *
    // ************
      /**
      * @notice Transfers `amounts_` amount(s) of `ids_` from the `from_` address to the `to_` address specified (with safety call).
      * 
      * @param from_ Source address
      * @param to_ Target address
      * @param ids_ IDs of each token type (order and length must match `amounts_` array)
      * @param amounts_ Transfer amounts per token type (order and length must match `ids_` array)
      * @param data_ Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to_`
      * 
      * Requirements:
      * 
      * - Caller must be approved to manage the tokens being transferred out of the `from_` account (see "Approval" section of the standard).
      * - MUST revert if `to_` is the zero address.
      * - MUST revert if length of `ids_` is not the same as length of `amounts_`.
      * - MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids_` is lower than the respective amount(s) in `amounts_` sent to the recipient.
      * - MUST revert on any other error.        
      * - MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
      * - Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_amounts[0] before ids_[1]/_amounts[1], etc).
      * - After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to_` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to_` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
      */
      function safeBatchTransferFrom(
        address from_,
        address to_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_,
        bytes calldata data_
      ) external override onlyAllowedOperator(msg.sender) {
        if (to_ == address(0)) {
          revert IERC1155_INVALID_TRANSFER();
        }
        uint256 _len_ = ids_.length;
        if (amounts_.length != _len_) {
          revert ARRAY_LENGTH_MISMATCH();
        }
        address _operator_ = msg.sender;
        if (! _isApprovedOrOwner(from_, _operator_)) {
          revert IERC1155_CALLER_NOT_APPROVED(from_, _operator_);
        }
        for (uint256 i; i < _len_;) {
          if (! _isValidSeries(ids_[i])) {
            revert IERC1155_NON_EXISTANT_TOKEN(ids_[i]);
          }
          uint256 _balance_ = _balances[ids_[i]][from_];
          if (_balance_ < amounts_[i]) {
            revert IERC1155_INSUFFICIENT_BALANCE(from_, ids_[i], _balance_);
          }
          unchecked {
            _balances[ids_[i]][from_] = _balance_ - amounts_[i];
          }
          _balances[ids_[i]][to_] += amounts_[i];
          unchecked {
            ++i;
          }
        }
        emit TransferBatch(_operator_, from_, to_, ids_, amounts_);

        _doSafeBatchTransferAcceptanceCheck(_operator_, from_, to_, ids_, amounts_, data_);
      }
      /**
      * @notice Transfers `amount_` amount of an `id_` from the `from_` address to the `to_` address specified (with safety call).
      * 
      * @param from_ Source address
      * @param to_ Target address
      * @param id_ ID of the token type
      * @param amount_ Transfer amount
      * @param data_ Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to_`
      * 
      * Requirements:
      * 
      * - Caller must be approved to manage the tokens being transferred out of the `from_` account (see "Approval" section of the standard).
      * - MUST revert if `to_` is the zero address.
      * - MUST revert if balance of holder for token type `id_` is lower than the `amount_` sent.
      * - MUST revert on any other error.
      * - MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
      * - After the above conditions are met, this function MUST check if `to_` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to_` and act appropriately (see "Safe Transfer Rules" section of the standard).        
      */
      function safeTransferFrom(
        address from_,
        address to_,
        uint256 id_,
        uint256 amount_,
        bytes calldata data_
      ) external override isValidSeries(id_) onlyAllowedOperator(msg.sender) {
        if (to_ == address(0)) {
          revert IERC1155_INVALID_TRANSFER();
        }
        address _operator_ = msg.sender;
        if (! _isApprovedOrOwner(from_, _operator_)) {
          revert IERC1155_CALLER_NOT_APPROVED(from_, _operator_);
        }
        uint256 _balance_ = _balances[id_][from_];
        if (_balance_ < amount_) {
          revert IERC1155_INSUFFICIENT_BALANCE(from_, id_, _balance_);
        }
        unchecked {
          _balances[id_][from_] = _balance_ - amount_;
        }
        _balances[id_][to_] += amount_;
        emit TransferSingle(_operator_, from_, to_, id_, amount_);
        _doSafeTransferAcceptanceCheck(_operator_, from_, to_, id_, amount_, data_);
      }
      /**
      * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
      * 
      * @param operator_ Address to add to the set of authorized operators
      * @param approved_ True if the operator is approved, false to revoke approval
      * 
      * Requirements:
      * 
      * - MUST emit the ApprovalForAll event on success.
      */
      function setApprovalForAll(address operator_, bool approved_)
      external
      override
      onlyAllowedOperatorApproval(msg.sender) {
        address _tokenOwner_ = msg.sender;
        if (_tokenOwner_ == operator_) {
          revert IERC1155_INVALID_CALLER_APPROVAL();
        }
        _operatorApprovals[_tokenOwner_][operator_] = approved_;
        emit ApprovalForAll(_tokenOwner_, operator_, approved_);
      }
    // ************
  // **************************************

  // **************************************
  // *****       CONTRACT OWNER       *****
  // **************************************
    // *********
    // * Cover *
    // *********
      /**
      * @notice Creates a new series
      * 
      * @param id_ the new series ID
      * @param minter_ the address allowed to mint (address zero to revoke minter status)
      * 
      * Requirements:
      * 
      * - Caller must be the contract owner
      * - `id_` must not be a valid series ID
      */
      function createSeries(uint256 id_, address minter_) external onlyOwner {
        if (BitMaps.get(_validSeries, id_)) {
          revert IERC1155_EXISTANT_TOKEN(id_);
        }
        BitMaps.set(_validSeries, id_);
        minters[id_] = minter_;
      }
      /**
      * @notice Sets the burner of an existing series
      * 
      * @param id_ the series ID
      * @param burner_ the address allowed to burn (address zero to revoke burner status)
      * 
      * Requirements:
      * 
      * - Caller must be the contract owner
      * - `id_` must be a valid series ID
      */
      function setBurner(uint256 id_, address burner_) external onlyOwner isValidSeries(id_) {
        burners[id_] = burner_;
      }
      /**
      * @notice Sets the minter of an existing series
      * 
      * @param id_ the series ID
      * @param minter_ the address allowed to mint (address zero to revoke minter status)
      * 
      * Requirements:
      * 
      * - Caller must be the contract owner
      * - `id_` must be a valid series ID
      */
      function setMinter(uint256 id_, address minter_) external onlyOwner isValidSeries(id_) {
        minters[id_] = minter_;
      }
      /**
      * @notice Updates the royalty recipient and rate.
      * 
      * @param royaltyRecipient_ the new recipient of the royalties
      * @param royaltyRate_ the new royalty rate
      * 
      * Requirements:
      * 
      * - Caller must be the contract owner
      * - `royaltyRate_` must be between 0 and 10,000
      */
      function setRoyaltyInfo(address royaltyRecipient_, uint256 royaltyRate_) external onlyOwner {
        _setRoyaltyInfo(royaltyRecipient_, royaltyRate_);
      }
      /**
      * @notice Sets the uri of the tokens.
      * 
      * @param uri_ The new uri of the tokens
      */
      function setURI(string memory uri_) external onlyOwner {
        _uri = uri_;
        emit URI(uri_, DEFAULT_SERIES_ID);
      }
    // *********
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    // *********
    // * Cover *
    // *********
      /**
      * @notice Returns whether series `id_` exists.
      * 
      * @param id_ ID of the token type
      * 
      * @return TRUE if the series exists, FALSE otherwise
      */
      function exist(uint256 id_) public view returns (bool) {
        return _isValidSeries(id_);
      }
    // *********

    // ***********
    // * IERC165 *
    // ***********
      /**
      * @notice Query if a contract implements an interface.
      * @dev Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
      * 
      * @param interfaceID_ the interface identifier, as specified in ERC-165
      * 
      * @return TRUE if the contract implements `interfaceID_` and `interfaceID_` is not 0xffffffff, FALSE otherwise
      */
      function supportsInterface(bytes4 interfaceID_) public pure override returns (bool) {
        return 
          interfaceID_ == type(IERC165).interfaceId ||
          interfaceID_ == type(IERC173).interfaceId ||
          interfaceID_ == type(IERC1155).interfaceId ||
          interfaceID_ == type(IERC1155MetadataURI).interfaceId ||
          interfaceID_ == type(IERC2981).interfaceId;
      }
    // ***********

    // ***********
    // * IERC173 *
    // ***********
      /**
      * @dev Returns the contract owner.
      */
      function owner() public view override(ERC173, UpdatableOperatorFilterer) returns (address) {
        return ERC173.owner();
      }
    // ***********

    // ************
    // * IERC1155 *
    // ************
      /**
      * @notice Get the balance of an account's tokens.
      * 
      * @param owner_ the address of the token holder
      * @param id_ ID of the token type
      * 
      * @return `owner_`'s balance of the token type requested
      */
      function balanceOf(address owner_, uint256 id_) public view override isValidSeries(id_) returns (uint256) {
        return _balances[id_][owner_];
      }
      /**
      * @notice Get the balance of multiple account/token pairs
      * 
      * @param owners_ the addresses of the token holders
      * @param ids_ ID of the token types
      * 
      * @return the `owners_`' balance of the token types requested (i.e. balance for each (owner, id) pair)
      */
      function balanceOfBatch(address[] calldata owners_, uint256[] calldata ids_)
      public
      view
      override
      returns (uint256[] memory) {
        uint256 _len_ = owners_.length;
        if (_len_ != ids_.length) {
          revert ARRAY_LENGTH_MISMATCH();
        }
        uint256[] memory _balances_ = new uint256[](_len_);
        while (_len_ > 0) {
          unchecked {
            --_len_;
          }
          if (! _isValidSeries(ids_[_len_])) {
            revert IERC1155_NON_EXISTANT_TOKEN(ids_[_len_]);
          }
          _balances_[_len_] = _balances[ids_[_len_]][owners_[_len_]];
        }
        return _balances_;
      }
      /**
      * @notice Queries the approval status of an operator for a given owner.
      * 
      * @param owner_ the owner of the tokens
      * @param operator_ address of authorized operator
      * 
      * @return TRUE if the operator is approved, FALSE if not
      */
      function isApprovedForAll(address owner_, address operator_) public view override returns (bool) {
        return _operatorApprovals[owner_][operator_];
      }
    // ************

    // ***********************
    // * IERC1155MetadataURI *
    // ***********************
      /**
      * @dev Returns the URI for token type `id`.
      */
      function uri(uint256 id_) external view isValidSeries(id_) returns (string memory) {
        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, _toString(id_))) : _toString(id_);
      }
    // ***********************
  // **************************************
}