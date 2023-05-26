// SPDX-License-Identifier: MIT

/**
* @team: Asteria Labs
* @author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC20.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IEtherErrors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/INFTSupplyErrors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ERC173.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ContractState.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/Whitelist_ECDSA.sol";

interface ICover {
  function mintTo(uint256 id_, uint256 qty_, address recipient_) external;
  function balanceOf(address owner_, uint256 id_) external view returns (uint256);
}

contract FirstCoverSale is IEtherErrors, INFTSupplyErrors, ERC173, ContractState, Whitelist_ECDSA {
  // **************************************
  // *****    BYTECODE  VARIABLES     *****
  // **************************************
    uint8 public constant KYO_CLAIM = 1;
    uint8 public constant KPJ_CLAIM = 2;
    uint8 public constant POAP_CLAIM = 3;
    uint8 public constant KYO_SALE = 4;
    uint8 public constant WL_SALE = 5;
    uint8 public constant PUBLIC_SALE = 6;
    uint256 public constant VOLUME_1 = 100;
    address public immutable ASTERIA;
  // **************************************

  // **************************************
  // *****     STORAGE VARIABLES      *****
  // **************************************
    uint256 public publicPrice = 15000000; // 15 USDC
    uint256 public discountPrice = 11500000; // 11.5 USDC
    IERC20 public usdc;
    ICover public cover;
    address public treasury;
    bool public vaultClaimed;
    uint256 public maxSupply; // 3000;
    uint256 public mintedSuply;
    mapping(uint8 => uint256) private _volume;
  // **************************************

  // **************************************
  // *****           ERROR            *****
  // **************************************
    error USDC_TRANSFER_FAIL(address sender, address recipient, uint256 amount);
    error VAULT_CLAIM_DONE();
    error VAULT_CLAIM_INVALID();
  // **************************************

  // **************************************
  // *****           EVENT            *****
  // **************************************
  // **************************************

  constructor(address asteria_, address treasury_, address signer_, address usdcAddress_, address coverAddress_, uint256 maxSupply_) {
    ASTERIA = asteria_;
    treasury = treasury_;
    usdc = IERC20(usdcAddress_);
    cover = ICover(coverAddress_);
    _setWhitelist(signer_);
    _setOwner(msg.sender);
    _volume[KYO_CLAIM] = VOLUME_1 + KYO_CLAIM;
    _volume[KPJ_CLAIM] = VOLUME_1 + KPJ_CLAIM;
    _volume[POAP_CLAIM] = VOLUME_1;
    maxSupply = maxSupply_;
  }

  // **************************************
  // *****          MODIFIER          *****
  // **************************************
  // **************************************

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
    /**
    * @dev Internal function processing an USDC payment.
    * 
    * @param sender_ the address sending the payment
    * @param recipient_ the address receiving the payment
    * @param amount_ the amount sent
    */
    function _processUSDCPayment(address sender_, address recipient_, uint256 amount_) internal {
      // solhint-disable-next-line
      bool _success_ = usdc.transferFrom(sender_, recipient_, amount_);
      if (! _success_) {
        revert USDC_TRANSFER_FAIL(sender_, recipient_, amount_);
      }
    }
  // **************************************

  // **************************************
  // *****           PUBLIC           *****
  // **************************************
    /**
    * @dev Claims a free cover.
    * 
    * @param proof_ the signature proving the wallet is allowed
    * 
    * Requirements:
    * 
    * - Contract state must be {KYO}, {KPJ}, or {POAP}
    * - Caller must be allowed to claim a cover
    */
    function claim(uint256 qty_, uint256 alloted_, Proof calldata proof_) external {
      uint8 _currentState_ = getContractState();
      if (_currentState_ == PAUSED || _currentState_ == KYO_SALE || _currentState_ == WL_SALE || _currentState_ == PUBLIC_SALE) {
        revert ContractState_INCORRECT_STATE(_currentState_);
      }
      uint256 _allowed_ = checkWhitelistAllowance(msg.sender, _currentState_, alloted_, proof_);
      if (_allowed_ < qty_) {
        revert Whitelist_FORBIDDEN(msg.sender);
      }
      _consumeWhitelist(msg.sender, _currentState_, qty_);
      if (_volume[_currentState_] == VOLUME_1) {
        uint256 _remainingSupply_;
        unchecked {
          _remainingSupply_ = maxSupply - mintedSuply;
        }
        if (qty_ > _remainingSupply_) {
          revert NFT_MAX_SUPPLY(qty_, _remainingSupply_);
        }
        unchecked {
          ++mintedSuply;
        }
      }
      try cover.mintTo(_volume[_currentState_], qty_, msg.sender) {}
      catch Error( string memory reason ) {
        revert(reason);
      }
    }
    /**
    * @dev Mints `qty_` first edition covers.
    * 
    * @param qty_ the number of covers purchased
    * @param alloted_ the max number allowed for the wallet
    * @param proof_ the signature proving the wallet is allowed
    * 
    * Requirements:
    * 
    * - Contract state must be {KYO_SALE} or {WL_SALE}
    * - Caller must have enough USDC to pay for `qty_` covers at discount price
    */
    function discountPurchase(uint256 qty_, uint256 alloted_, Proof calldata proof_) external {
      uint8 _currentState_ = getContractState();
      if (_currentState_ < KYO_SALE || _currentState_ == PUBLIC_SALE) {
        revert ContractState_INCORRECT_STATE(_currentState_);
      }
      uint256 _remainingSupply_;
      unchecked {
        _remainingSupply_ = maxSupply - mintedSuply;
      }
      if (qty_ > _remainingSupply_) {
        revert NFT_MAX_SUPPLY(qty_, _remainingSupply_);
      }
      uint256 _allowed_ = checkWhitelistAllowance(msg.sender, _currentState_, alloted_, proof_);
      if (_allowed_ < qty_) {
        revert Whitelist_FORBIDDEN(msg.sender);
      }
      unchecked {
        mintedSuply += qty_;
      }
      _consumeWhitelist(msg.sender, _currentState_, qty_);
      cover.mintTo(VOLUME_1, qty_, msg.sender);
      uint256 _totalPrice_ = discountPrice * qty_;
      uint256 _asteriaShare_ = _totalPrice_ * 5 / 100;
      _processUSDCPayment(msg.sender, ASTERIA, _asteriaShare_);
      _processUSDCPayment(msg.sender, treasury, _totalPrice_ - _asteriaShare_);
    }
    /**
    * @dev Mints `qty_` first edition covers.
    * 
    * @param qty_ the number of covers purchased
    * 
    * Requirements:
    * 
    * - Contract state must be {PUBLIC_SALE}
    * - Caller must have enough USDC to pay for `qty_` covers at full price
    */
    function purchase(uint256 qty_) external isState(PUBLIC_SALE) {
      uint256 _remainingSupply_;
      unchecked {
        _remainingSupply_ = maxSupply - mintedSuply;
      }
      if (qty_ > _remainingSupply_) {
        revert NFT_MAX_SUPPLY(qty_, _remainingSupply_);
      }
      unchecked {
        mintedSuply += qty_;
      }
      cover.mintTo(VOLUME_1, qty_, msg.sender);
      uint256 _totalPrice_ = publicPrice * qty_;
      uint256 _asteriaShare_ = _totalPrice_ * 5 / 100;
      _processUSDCPayment(msg.sender, ASTERIA, _asteriaShare_);
      _processUSDCPayment(msg.sender, treasury, _totalPrice_ - _asteriaShare_);
    }
  // **************************************

  // **************************************
  // *****       CONTRACT OWNER       *****
  // **************************************
    /**
    * @dev Mints 150 covers to project vault.
    * 
    * @param vault_ the address receiving the tokens
    * @param qty_ the number of covers minted
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - Function can only be called once.
    */
    function devMint(address vault_, uint256 qty_) external onlyOwner {
      if (vaultClaimed) {
        revert VAULT_CLAIM_DONE();
      }
      if (qty_ > 150) {
        revert VAULT_CLAIM_INVALID();
      }
      uint256 _remainingSupply_;
      unchecked {
        _remainingSupply_ = maxSupply - mintedSuply;
      }
      if (qty_ > _remainingSupply_) {
        revert NFT_MAX_SUPPLY(qty_, _remainingSupply_);
      }
      unchecked {
        mintedSuply += qty_;
      }
      vaultClaimed = true;
      cover.mintTo(VOLUME_1, qty_, vault_);
    }
    /**
    * @dev Updates the max supply for the Standard cover
    * 
    * @param newMaxSupply_ the new max supply
    *  
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function updateSupply(uint256 newMaxSupply_) external onlyOwner {
      maxSupply = newMaxSupply_;
    }
    /**
    * @dev Updates the contract state.
    * 
    * @param newState_ the new sale state
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newState_` must be a valid state.
    */
    function setContractState(uint8 newState_) external onlyOwner {
      if (newState_ > PUBLIC_SALE) {
        revert ContractState_INVALID_STATE(newState_);
      }
      _setContractState(newState_);
    }
    /**
    * @dev Sets the Cover contract address.
    * 
    * @param contractAddress_ the Cover contract address
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setCover(address contractAddress_) external onlyOwner {
      cover = ICover(contractAddress_);
    }
    /**
    * @dev Updates the price of the purchase.
    * 
    * @param newPublicPrice_ the new public price
    * @param newDiscountPrice_ the new discount price
    *  
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setPrice(uint256 newPublicPrice_, uint256 newDiscountPrice_) external onlyOwner {
      publicPrice = newPublicPrice_;
      discountPrice = newDiscountPrice_;
    }
    /**
    * @dev Updates the treasury addresses
    * 
    * @param newTreasury_ The new treasury address
    *  
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setTreasury(address newTreasury_) external onlyOwner {
      treasury = newTreasury_;
    }
    /**
    * @dev Updates the whitelist signer.
    * 
    * @param newAdminSigner_ the new whitelist signer
    *  
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setWhitelist(address newAdminSigner_) external onlyOwner {
      _setWhitelist(newAdminSigner_);
    }
  // **************************************
}