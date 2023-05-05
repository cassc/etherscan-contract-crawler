// SPDX-License-Identifier: MIT

/**
* Team: Asteria Labs
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/INFTSupplyErrors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC165.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721Errors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721Metadata.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721Receiver.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ERC173.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ERC2981.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

contract AsteriaPass is
INFTSupplyErrors, IERC721Errors, IERC721, IERC721Metadata,
IERC165, ERC173, ERC2981, UpdatableOperatorFilterer {
  // **************************************
  // *****    BYTECODE  VARIABLES     *****
  // **************************************
    address public constant DEFAULT_SUBSCRIPTION = address( 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6 );
    address public constant DEFAULT_OPERATOR_FILTER_REGISTRY = address( 0x000000000000AAeB6D7670E522A718067333cd4E );
    string public constant name = "Asteria Founders Pass"; // solhint-disable-line
    string public constant symbol = "AFP"; // solhint-disable-line
  // **************************************

  // **************************************
  // *****     STORAGE VARIABLES      *****
  // **************************************
    address public delegate;
    bool public mintingClosed;
    uint256 public totalSupply;
    string private _baseURI = "https://afp-auction-site.vercel.app/api/meta/";
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _approvals;
    // List of owner addresses
    mapping(uint256 => address) private _owners;
    // Token owners mapped to balance
    mapping(address => uint256) private _balances;
    // Token owner mapped to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
  // **************************************

  // **************************************
  // *****           ERROR            *****
  // **************************************
    /**
    * @dev Thrown when trying to mint a token that already exists.
    * 
    * @param tokenId the token being minted
    */
    error AFP_ALREADY_EXIST(uint256 tokenId);
    /**
    * @dev Thrown when non delegated user tries to claim a token.
    */
    error AFP_NOT_DELEGATE();
    /**
    * @dev Thrown when trying to mint after closing supply.
    */
    error AFP_SUPPLY_CLOSED();
    /**
    * @dev Thrown when trying to call a non existant function or trying to send eth to the contract.
    */
    error AFP_UNKNOWN();
  // **************************************

  constructor(address royaltiesRecipient_)
  UpdatableOperatorFilterer(DEFAULT_OPERATOR_FILTER_REGISTRY, DEFAULT_SUBSCRIPTION, true) {
  	_setOwner(msg.sender);
    _setRoyaltyInfo(royaltiesRecipient_, 1000);
  }

  // **************************************
  // *****          MODIFIER          *****
  // **************************************
    /**
    * @dev Ensures the token exist. 
    * A token exists if it has been minted and is not owned by the null address.
    * 
    * @param tokenId_ identifier of the NFT being referenced
    */
    modifier exists(uint256 tokenId_) {
      if (! _exists(tokenId_)) {
        revert IERC721_NONEXISTANT_TOKEN(tokenId_);
      }
      _;
    }
  // **************************************

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
    /**
    * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
    * The call is not executed if the target address is not a contract.
    *
    * @param from_ address owning the token being transferred
    * @param to_ address the token is being transferred to
    * @param tokenId_ identifier of the NFT being referenced
    * @param data_ optional data to send along with the call
    * 
    * @return whether the call correctly returned the expected magic value
    */
    function _checkOnERC721Received(address from_, address to_, uint256 tokenId_, bytes memory data_) internal returns (bool) {
      // This method relies on extcodesize, which returns 0 for contracts in
      // construction, since the code is only stored at the end of the
      // constructor execution.
      // 
      // IMPORTANT
      // It is unsafe to assume that an address not flagged by this method
      // is an externally-owned account (EOA) and not a contract.
      //
      // Among others, the following types of addresses will not be flagged:
      //
      //  - an externally-owned account
      //  - a contract in construction
      //  - an address where a contract will be created
      //  - an address where a contract lived, but was destroyed
      uint256 _size_;
      assembly {
        _size_ := extcodesize(to_)
      }

      // If address is a contract, check that it is aware of how to handle ERC721 tokens
      if (_size_ > 0) {
        try IERC721Receiver(to_).onERC721Received(msg.sender, from_, tokenId_, data_) returns (bytes4 retval) {
          return retval == IERC721Receiver.onERC721Received.selector;
        }
        catch (bytes memory reason) {
          if (reason.length == 0) {
            revert IERC721_NON_ERC721_RECEIVER(to_);
          }
          else {
            assembly {
              revert(add(32, reason), mload(reason))
            }
          }
        }
      }
      else {
        return true;
      }
    }
    /**
    * @dev Internal function returning whether a token exists. 
    * A token exists if it has been minted and is not owned by the null address.
    * 
    * Note: this function must be overriden if tokens are burnable.
    * 
    * @param tokenId_ identifier of the NFT being referenced
    * 
    * @return whether the token exists
    */
    function _exists(uint256 tokenId_) internal view returns (bool) {
      if (tokenId_ == 0) {
        return false;
      }
      return _owners[tokenId_] != address(0);
    }
    /**
    * @dev Internal function returning whether `operator_` is allowed to handle `tokenId_`
    * 
    * Note: To avoid multiple checks for the same data, it is assumed 
    * that existence of `tokenId_` has been verified prior via {_exists}
    * If it hasn't been verified, this function might panic
    * 
    * @param operator_ address that tries to handle the token
    * @param tokenId_ identifier of the NFT being referenced
    * 
    * @return whether `operator_` is allowed to manage the token
    */
    function _isApprovedOrOwner(address tokenOwner_, address operator_, uint256 tokenId_) internal view returns (bool) {
      return 
      	operator_ == tokenOwner_ ||
        operator_ == getApproved(tokenId_) ||
        isApprovedForAll(tokenOwner_, operator_);
    }
    /**
    * @dev Mints a token and transfer it to `to_`.
    * 
    * This internal function can be used to perform token minting.
    * If the Vested Pass contract is set, it will also burn a vested pass from the token receiver
    * 
    * @param to_ address receiving the tokens
    * 
    * Emits a {Transfer} event.
    */
    function _mint(address to_, uint256 tokenId_) internal {
      unchecked {
        ++_balances[to_];
        ++totalSupply;
      }
      _owners[tokenId_] = to_;
      emit Transfer(address(0), to_, tokenId_);
    }
    /**
    * @dev Internal function returning the owner of the `tokenId_` token.
    * 
    * @param tokenId_ identifier of the NFT being referenced
    * 
    * @return address of the token owner
    */
    function _ownerOf(uint256 tokenId_) internal view returns (address) {
      return _owners[tokenId_];
    }
    /**
    * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        for { let temp := value_ } 1 {} { // solhint-disable-line
          str := sub(str, 1)
          // Write the character to the pointer.
          // The ASCII index of the '0' character is 48.
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
    /**
    * @dev Transfers `tokenId_` from `from_` to `to_`.
    *
    * This internal function can be used to implement alternative mechanisms to perform 
    * token transfer, such as signature-based, or token burning.
    * 
    * @param from_ the current owner of the NFT
    * @param to_ the new owner
    * @param tokenId_ identifier of the NFT being referenced
    * 
    * Emits a {Transfer} event.
    */
    function _transfer(address from_, address to_, uint256 tokenId_) internal {
      unchecked {
        ++_balances[to_];
        --_balances[from_];
      }
      _owners[tokenId_] = to_;
      _approvals[tokenId_] = address(0);

      emit Transfer(from_, to_, tokenId_);
    }
  // **************************************

  // **************************************
  // *****           PUBLIC           *****
  // **************************************
    // ***********
    // * IERC721 *
    // ***********
      /**
      * @dev Gives permission to `to_` to transfer the token number `tokenId_` on behalf of its owner.
      * The approval is cleared when the token is transferred.
      * 
      * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
      * 
      * @param to_ The new approved NFT controller
      * @param tokenId_ The NFT to approve
      * 
      * Requirements:
      * 
      * - The token number `tokenId_` must exist.
      * - The caller must own the token or be an approved operator.
      * - Must emit an {Approval} event.
      */
      function approve(address to_, uint256 tokenId_) public override exists(tokenId_) onlyAllowedOperatorApproval(msg.sender) {
        address _tokenOwner_ = _ownerOf(tokenId_);
        if (to_ == _tokenOwner_) {
          revert IERC721_INVALID_APPROVAL(to_);
        }

        bool _isApproved_ = _isApprovedOrOwner(_tokenOwner_, msg.sender, tokenId_);
        if (! _isApproved_) {
          revert IERC721_CALLER_NOT_APPROVED(_tokenOwner_, msg.sender, tokenId_);
        }

        _approvals[tokenId_] = to_;
        emit Approval(_tokenOwner_, to_, tokenId_);
      }

      /**
      * @dev Transfers the token number `tokenId_` from `from_` to `to_`.
      * 
      * @param from_ The current owner of the NFT
      * @param to_ The new owner
      * @param tokenId_ identifier of the NFT being referenced
      * 
      * Requirements:
      * 
      * - The token number `tokenId_` must exist.
      * - `from_` must be the token owner.
      * - The caller must own the token or be an approved operator.
      * - `to_` must not be the zero address.
      * - If `to_` is a contract, it must implement {IERC721Receiver-onERC721Received} with a return value of `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
      * - Must emit a {Transfer} event.
      */
      function safeTransferFrom(address from_, address to_, uint256 tokenId_) public override {
        safeTransferFrom(from_, to_, tokenId_, "");
      }

      /**
      * @dev Transfers the token number `tokenId_` from `from_` to `to_`.
      * 
      * @param from_ The current owner of the NFT
      * @param to_ The new owner
      * @param tokenId_ identifier of the NFT being referenced
      * @param data_ Additional data with no specified format, sent in call to `to_`
      * 
      * Requirements:
      * 
      * - The token number `tokenId_` must exist.
      * - `from_` must be the token owner.
      * - The caller must own the token or be an approved operator.
      * - `to_` must not be the zero address.
      * - If `to_` is a contract, it must implement {IERC721Receiver-onERC721Received} with a return value of `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
      * - Must emit a {Transfer} event.
      */
      function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public override {
        transferFrom(from_, to_, tokenId_);
        if (! _checkOnERC721Received(from_, to_, tokenId_, data_)) {
          revert IERC721_NON_ERC721_RECEIVER(to_);
        }
      }

      /**
      * @dev Allows or disallows `operator_` to manage the caller's tokens on their behalf.
      * 
      * @param operator_ Address to add to the set of authorized operators
      * @param approved_ True if the operator is approved, false to revoke approval
      * 
      * Requirements:
      * 
      * - Must emit an {ApprovalForAll} event.
      */
      function setApprovalForAll(address operator_, bool approved_) public override onlyAllowedOperatorApproval(msg.sender) {
        address _account_ = msg.sender;
        if (operator_ == _account_) {
          revert IERC721_INVALID_APPROVAL(operator_);
        }

        _operatorApprovals[_account_][operator_] = approved_;
        emit ApprovalForAll(_account_, operator_, approved_);
      }

      /**
      * @dev Transfers the token number `tokenId_` from `from_` to `to_`.
      * 
      * @param from_ the current owner of the NFT
      * @param to_ the new owner
      * @param tokenId_ identifier of the NFT being referenced
      * 
      * Requirements:
      * 
      * - The token number `tokenId_` must exist.
      * - `from_` must be the token owner.
      * - The caller must own the token or be an approved operator.
      * - `to_` must not be the zero address.
      * - Must emit a {Transfer} event.
      */
      function transferFrom(address from_, address to_, uint256 tokenId_) public override onlyAllowedOperator(msg.sender) {
        if (to_ == address(0)) {
          revert IERC721_INVALID_TRANSFER();
        }

        address _tokenOwner_ = ownerOf(tokenId_);
        if (from_ != _tokenOwner_) {
          revert IERC721_INVALID_TRANSFER_FROM(_tokenOwner_, from_, tokenId_);
        }

        if (! _isApprovedOrOwner(_tokenOwner_, msg.sender, tokenId_)) {
          revert IERC721_CALLER_NOT_APPROVED(_tokenOwner_, msg.sender, tokenId_);
        }

        _transfer(_tokenOwner_, to_, tokenId_);
      }
    // ***********
  // **************************************

  // **************************************
  // *****          DELEGATE          *****
  // **************************************
    /**
    * @dev Airdrops a token to `account_`.
    * 
    * @param account_ the address receiving the token
    * @param tokenId_ identifier of the NFT being airdropped
    */
    function airdrop(address account_, uint256 tokenId_) external {
      if (mintingClosed) {
        revert AFP_SUPPLY_CLOSED();
      }
      if (msg.sender != delegate) {
        revert AFP_NOT_DELEGATE();
      }
      if (_owners[tokenId_] != address(0)) {
        revert AFP_ALREADY_EXIST(tokenId_);
      }
      _mint(account_, tokenId_);
    }
  // **************************************

  // **************************************
  // *****       CONTRACT_OWNER       *****
  // **************************************
    /**
    * @dev Closes minting, locking the supply.
    */
    function closeMinting() external onlyOwner {
      mintingClosed = true;
    }
    /**
    * @dev Updates the baseURI for the tokens.
    * 
    * @param baseURI_ the new baseURI for the tokens
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setBaseURI(string memory baseURI_) external onlyOwner {
      _baseURI = baseURI_;
    }
    /**
    * @dev Updates the royalty recipient and rate.
    * 
    * @param newRoyaltyRecipient_ the new recipient of the royalties
    * @param newRoyaltyRate_ the new royalty rate
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newRoyaltyRate_` cannot be higher than 10,000.
    */
    function setRoyaltyInfo(address newRoyaltyRecipient_, uint256 newRoyaltyRate_) external onlyOwner {
      _setRoyaltyInfo(newRoyaltyRecipient_, newRoyaltyRate_);
    }
    /**
    * @dev Sets the address allowed to mint the tokens.
    * 
    * @param delegateAddress_ the address allowed to mint tokens
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setDelegate(address delegateAddress_) external onlyOwner {
      delegate = delegateAddress_;
    }
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    // ***********
    // * IERC721 *
    // ***********
      /**
      * @dev Returns the number of tokens in `tokenOwner_`'s account.
      * 
      * @param tokenOwner_ address that owns tokens
      * 
      * @return the nomber of tokens owned by `tokenOwner_`
      */
      function balanceOf(address tokenOwner_) public view override returns (uint256) {
        if (tokenOwner_ == address(0)) {
          return 0;
        }

        return _balances[tokenOwner_];
      }
      /**
      * @dev Returns the address that has been specifically allowed to manage `tokenId_` on behalf of its owner.
      * 
      * @param tokenId_ the NFT that has been approved
      * 
      * @return the address allowed to manage `tokenId_`
      * 
      * Requirements:
      * 
      * - `tokenId_` must exist.
      * 
      * Note: See {Approve}
      */
      function getApproved(uint256 tokenId_) public view override exists(tokenId_) returns (address) {
        return _approvals[tokenId_];
      }
      /**
      * @dev Returns whether `operator_` is allowed to manage tokens on behalf of `tokenOwner_`.
      * 
      * @param tokenOwner_ address that owns tokens
      * @param operator_ address that tries to manage tokens
      * 
      * @return whether `operator_` is allowed to handle `tokenOwner`'s tokens
      * 
      * Note: See {setApprovalForAll}
      */
      function isApprovedForAll(address tokenOwner_, address operator_) public view override returns (bool) {
        return _operatorApprovals[tokenOwner_][operator_];
      }
      /**
      * @dev Returns the owner of the token number `tokenId_`.
      * 
      * @param tokenId_ the NFT to verify ownership of
      * 
      * @return the owner of token number `tokenId_`
      * 
      * Requirements:
      * 
      * - `tokenId_` must exist.
      */
      function ownerOf(uint256 tokenId_) public view override exists(tokenId_) returns (address) {
        return _ownerOf(tokenId_);
      }
    // ***********

    // *******************
    // * IERC721Metadata *
    // *******************
      /**
      * @dev A distinct Uniform Resource Identifier (URI) for a given asset.
      * 
      * @param tokenId_ the NFT that has been approved
      * 
      * @return the URI of the token
      * 
      * Requirements:
      * 
      * - `tokenId_` must exist.
      */
      function tokenURI(uint256 tokenId_) public view override exists(tokenId_) returns (string memory) {
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, _toString(tokenId_))) : _toString(tokenId_);
      }
    // *******************

    // ***********
    // * IERC165 *
    // ***********
      /**
      * @dev Query if a contract implements an interface.
      * @dev see https://eips.ethereum.org/EIPS/eip-165
      * 
      * @param interfaceId_ the interface identifier, as specified in ERC-165
      * 
      * @return true if the contract implements the specified interface, false otherwise
      * 
      * Requirements:
      * 
      * - This function must use less than 30,000 gas.
      */
      function supportsInterface(bytes4 interfaceId_) public view override returns (bool) {
        return 
          interfaceId_ == type(IERC721).interfaceId ||
          interfaceId_ == type(IERC721Metadata).interfaceId ||
          interfaceId_ == type(IERC173).interfaceId ||
          interfaceId_ == type(IERC165).interfaceId ||
          interfaceId_ == type(IERC2981).interfaceId;
      }
    // ***********

    // ***********
    // * IERC173 *
    // ***********
      /**
      * @dev Returns the address of the current contract owner.
      * 
      * @return address : the current contract owner
      */
      function owner() public view override(ERC173, UpdatableOperatorFilterer) returns (address) {
        return ERC173.owner();
      }
    // ***********
  // **************************************
  // FALLBACK, can't receive eth
  fallback() external payable { revert AFP_UNKNOWN(); }
  receive() external payable { revert AFP_UNKNOWN(); }
}