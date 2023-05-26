// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC165.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IArrayErrors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IEtherErrors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/INFTSupplyErrors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721Errors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721Receiver.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721Enumerable.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721Metadata.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ERC173.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ERC2981.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ContractState.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/Whitelist_ECDSA.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

contract CuratedBlocks is
IArrayErrors, IEtherErrors, INFTSupplyErrors, IERC721Errors,
IERC721, IERC721Enumerable, IERC721Metadata,
IERC165, ERC173, ERC2981, ContractState, Whitelist_ECDSA, UpdatableOperatorFilterer {
  // **************************************
  // *****    BYTECODE  VARIABLES     *****
  // **************************************
    address public constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    address public constant DEFAULT_OPERATOR_FILTER_REGISTRY = address(0x000000000000AAeB6D7670E522A718067333cd4E);
    uint256 public constant MAX_BATCH = 10;
  	uint8 public constant MAGMA_SALE = 1;
    uint8 public constant PRIVATE_SALE = 2;
    uint8 public constant WAITLIST_SALE = 3;
    string  public constant name = "CuratedBlocks Genesis";
    string  public constant symbol = "CBLOCKS";
  // **************************************

  // **************************************
  // *****     STORAGE VARIABLES      *****
  // **************************************
    uint256 public maxSupply;
    address public treasury;
    string  private _baseUri;
    uint256 private _nextId = 3;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _approvals;
    // List of owner addresses
    mapping(uint256 => address) private _owners;
    // Token owners mapped to balance
    mapping(address => uint256) private _balances;
    // Token owner mapped to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    // Phase mapped to sale price
    mapping(uint8 => uint256) private _salePrice;
  // **************************************

  constructor(address airdropAddress_, address royaltyRecipient_, address treasury_, address signerWallet_, uint256 maxSupply_)
  UpdatableOperatorFilterer(DEFAULT_OPERATOR_FILTER_REGISTRY, DEFAULT_SUBSCRIPTION, true) {
    maxSupply = maxSupply_;
    _salePrice[MAGMA_SALE] = 0.044 ether;
    _salePrice[PRIVATE_SALE] = 0.055 ether;
    _salePrice[WAITLIST_SALE] = 0.055 ether;
    treasury = treasury_;
    _setOwner(msg.sender);
    _setRoyaltyInfo(royaltyRecipient_, 250);
    _setWhitelist(signerWallet_);
    _owners[1] = airdropAddress_;
    _owners[2] = airdropAddress_;
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
    * @dev Internal function to process whitelist status.
    * 
    * @param account_ address minting a token
    * @param currentState_ the current contract state
    * @param whitelistType_ identifies the whitelist used
    * @param alloted_ the maximum alloted for that user
    * @param qty_ the amount of tokens to be minted
    * @param proof_ the signature to verify whitelist allocation
    */
    function _processWhitelist(address account_, uint8 currentState_, uint8 whitelistType_, uint256 alloted_, uint256 qty_, Proof memory proof_) internal {
      uint256 _allowed_;
      if (currentState_ == MAGMA_SALE) {
        _allowed_ = checkWhitelistAllowance(account_, MAGMA_SALE, alloted_, proof_);
        if (_allowed_ < qty_) {
          revert Whitelist_FORBIDDEN(account_);
        }
        _consumeWhitelist(account_, MAGMA_SALE, qty_);
      }
      else if (currentState_ == PRIVATE_SALE) {
        if (whitelistType_ == MAGMA_SALE) {
          _allowed_ = checkWhitelistAllowance(account_, MAGMA_SALE, alloted_, proof_);
          if (_allowed_ < qty_) {
            revert Whitelist_FORBIDDEN(account_);
          }
          _consumeWhitelist(account_, MAGMA_SALE, qty_);
        }
        else {
          _allowed_ = checkWhitelistAllowance(account_, PRIVATE_SALE, alloted_, proof_);
          if (_allowed_ < qty_) {
            revert Whitelist_FORBIDDEN(account_);
          }
          _consumeWhitelist(account_, PRIVATE_SALE, qty_);
        }
      }
      else {
        checkWhitelistAllowance(account_, WAITLIST_SALE, 1, proof_);
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
    * @dev Internal functions that counts the NFTs tracked by this contract.
    * 
    * @return the number of NFTs in existence
    */
    function _totalSupply() internal view virtual returns (uint256) {
      return supplyMinted();
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
    /**
    * @notice Mints `qty_` tokens and transfers them to the caller.
    * 
    * @param qty_ : the amount of tokens to be minted
    * @param alloted_ : the maximum alloted for that user
    * @param whitelistType_ : identifies the whitelist used
    * @param proof_ : the signature to verify whitelist allocation
    * 
    * Requirements:
    * 
    * - Sale state must not be {PAUSED}.
    * - Caller must send enough ether to pay for `qty_` tokens at current sale state price.
    * - Caller must be allowed to mint `qty_` tokens during `whitelistType_` sale state.
    */
    function mint(uint256 qty_, uint256 alloted_, uint8 whitelistType_, Proof calldata proof_) public payable isNotState(PAUSED) {
      uint8 _currentState_ = getContractState();

      if (qty_ > MAX_BATCH) {
        revert NFT_MAX_BATCH(qty_, MAX_BATCH);
      }

      uint256 _remainingSupply_ = maxSupply - supplyMinted();
      if (qty_ > _remainingSupply_) {
        revert NFT_MAX_SUPPLY(qty_, _remainingSupply_);
      }

      uint256 _expected_ = qty_ * _salePrice[whitelistType_];
      if (_expected_ != msg.value) {
        revert ETHER_INCORRECT_PRICE(msg.value, _expected_);
      }

      _processWhitelist(msg.sender, _currentState_, whitelistType_, alloted_, qty_, proof_);

      uint256 _firstToken_ = _nextId;
      uint256 _nextStart_ = _firstToken_ + qty_;
      unchecked {
        _balances[msg.sender] += qty_;
        _nextId += qty_;
      }
      while (_firstToken_ < _nextStart_) {
        _mint(msg.sender, _firstToken_);
        unchecked {
          _firstToken_ ++;
        }
      }
    }

    // ***********
    // * IERC721 *
    // ***********
      /**
      * @notice Gives permission to `to_` to transfer the token number `tokenId_` on behalf of its owner.
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
      * @notice Transfers the token number `tokenId_` from `from_` to `to_`.
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
      * @notice Transfers the token number `tokenId_` from `from_` to `to_`.
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
      * @notice Allows or disallows `operator_` to manage the caller's tokens on their behalf.
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
      * @notice Transfers the token number `tokenId_` from `from_` to `to_`.
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
  // *****       CONTRACT_OWNER       *****
  // **************************************
    /**
    * @notice Reduces the max supply.
    * 
    * @param newMaxSupply_ : the new max supply
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newMaxSupply_` must be lower than `maxSupply`.
    * - `newMaxSupply_` must be higher than `_nextId`.
    */
    function reduceSupply(uint256 newMaxSupply_) public onlyOwner {
      if (newMaxSupply_ > maxSupply || newMaxSupply_ < supplyMinted()) {
        revert NFT_INVALID_SUPPLY();
      }
      maxSupply = newMaxSupply_;
    }
    /**
    * @notice Updates the baseUri for the tokens.
    * 
    * @param newBaseUri_ : the new baseUri for the tokens
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setBaseUri(string memory newBaseUri_) public onlyOwner {
      _baseUri = newBaseUri_;
    }
    /**
    * @notice Updates the contract state.
    * 
    * @param newState_ : the new sale state
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newState_` must be a valid state.
    */
    function setContractState(uint8 newState_) external onlyOwner {
      if (newState_ > WAITLIST_SALE) {
        revert ContractState_INVALID_STATE(newState_);
      }
      _setContractState(newState_);
    }
    /**
    * @notice Updates the royalty recipient and rate.
    * 
    * @param newRoyaltyRecipient_ : the new recipient of the royalties
    * @param newRoyaltyRate_ : the new royalty rate
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
    * @notice Updates the royalty recipient and rate.
    * 
    * @param newMagmaPrice_ : the new magma price
    * @param newPrivatePrice_ : the new private price
    * @param newPublicPrice_ : the new public price
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setPrices(uint256 newMagmaPrice_, uint256 newPrivatePrice_, uint256 newPublicPrice_) external onlyOwner {
      _salePrice[MAGMA_SALE] = newMagmaPrice_;
      _salePrice[PRIVATE_SALE] = newPrivatePrice_;
      _salePrice[WAITLIST_SALE] = newPublicPrice_;
    }
    /**
    * @notice Updates the contract treasury.
    * 
    * @param newTreasury_ : the new trasury
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setTreasury(address newTreasury_) external onlyOwner {
      treasury = newTreasury_;
    }
    /**
    * @notice Updates the whitelist signer.
    * 
    * @param newAdminSigner_ : the new whitelist signer
    *  
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setWhitelist(address newAdminSigner_) external onlyOwner {
      _setWhitelist(newAdminSigner_);
    }
    /**
    * @notice Withdraws all the money stored in the contract and sends it to the treasury.
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `treasury` must be able to receive the funds.
    * - Contract must have a positive balance.
    */
    function withdraw() public onlyOwner {
      uint256 _balance_ = address(this).balance;
      if (_balance_ == 0) {
        revert ETHER_NO_BALANCE();
      }

      address _recipient_ = payable(treasury);
      // solhint-disable-next-line
      (bool _success_,) = _recipient_.call{ value: _balance_ }("");
      if (! _success_) {
        revert ETHER_TRANSFER_FAIL(_recipient_, _balance_);
      }
    }
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    /**
    * @notice Returns the sale price during the specified state.
    * 
    * @param contractState_ : the state of the contract to check the price at
    * 
    * @return price : uint256 => the sale price at the specified state
    */
    function salePrice(uint8 contractState_) public virtual view returns (uint256 price) {
      return _salePrice[ contractState_ ];
    }
    /**
    * @notice Returns the total number of tokens minted
    * 
    * @return uint256 the number of tokens that have been minted so far
    */
    function supplyMinted() public view virtual returns (uint256) {
      return _nextId - 1;
    }

    // ***********
    // * IERC721 *
    // ***********
      /**
      * @notice Returns the number of tokens in `tokenOwner_`'s account.
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
      * @notice Returns the address that has been specifically allowed to manage `tokenId_` on behalf of its owner.
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
      * @notice Returns whether `operator_` is allowed to manage tokens on behalf of `tokenOwner_`.
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
      * @notice Returns the owner of the token number `tokenId_`.
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
      * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
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
        return bytes(_baseUri).length > 0 ? string(abi.encodePacked(_baseUri, _toString(tokenId_))) : _toString(tokenId_);
      }
    // *******************

    // *********************
    // * IERC721Enumerable *
    // *********************
      /**
      * @notice Enumerate valid NFTs
      * @dev Throws if `index_` >= {totalSupply()}.
      * 
      * @param index_ the index requested
      * 
      * @return the identifier of the token at the specified index
      */
      function tokenByIndex(uint256 index_) public view virtual override returns (uint256) {
        if (index_ >= supplyMinted()) {
          revert IERC721Enumerable_INDEX_OUT_OF_BOUNDS(index_);
        }
        return index_ + 1;
      }
      /**
      * @notice Enumerate NFTs assigned to an owner
      * @dev Throws if `index_` >= {balanceOf(owner_)} or if `owner_` is the zero address, representing invalid NFTs.
      * 
      * @param tokenOwner_ the address requested
      * @param index_ the index requested
      * 
      * @return the identifier of the token at the specified index
      */
      function tokenOfOwnerByIndex(address tokenOwner_, uint256 index_) public view virtual override returns (uint256) {
        if (index_ >= balanceOf(tokenOwner_)) {
          revert IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS(tokenOwner_, index_);
        }

        uint256 _count_ = 0;
        uint256 _nextId_ = supplyMinted();
        for (uint256 i = 1; i < _nextId_; i++) {
          if (_exists(i) && tokenOwner_ == _ownerOf(i)) {
            if (index_ == _count_) {
              return i;
            }
            _count_++;
          }
        }
      }
      /**
      * @notice Count NFTs tracked by this contract
      * 
      * @return the number of NFTs in existence
      */
      function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply();
      }
    // *********************

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

	  // ***********
	  // * IERC165 *
	  // ***********
	    /**
	    * @notice Query if a contract implements an interface.
	    * @dev see https://eips.ethereum.org/EIPS/eip-165
	    * 
	    * @param interfaceId_ : the interface identifier, as specified in ERC-165
	    * 
	    * @return bool : true if the contract implements the specified interface, false otherwise
	    * 
	    * Requirements:
	    * 
	    * - This function must use less than 30,000 gas.
	    */
	    function supportsInterface(bytes4 interfaceId_) public pure override returns (bool) {
	      return 
	        interfaceId_ == type(IERC721).interfaceId ||
	        interfaceId_ == type(IERC721Enumerable).interfaceId ||
	        interfaceId_ == type(IERC721Metadata).interfaceId ||
	        interfaceId_ == type(IERC173).interfaceId ||
	        interfaceId_ == type(IERC165).interfaceId ||
	        interfaceId_ == type(IERC2981).interfaceId;
	    }
	  // ***********
  // **************************************
}