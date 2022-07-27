// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "../token/Asset.sol";
import "../lib/Operatorable.sol";
import "../lib/Signer.sol";
import "../Error.sol";

contract Sale is Operatorable, Signer {
  using Address for address;

  enum Step {
    NONE,
    PRESALE,
    SALE
  }

  Step public step;

  // Gaming asset contract
  Asset public immutable asset;

  // Token price in Wei
  uint256 public price;

  // Minting cap in pre-sale and public sale
  uint256 public immutable mintingCap;

  // Maximum mint amount in pre-sale and public sale
  uint256 public maxMintable;

  // Totally minted amount in pre-sale and public sale
  uint256 public totalMinted;

  // Maximum mint amount per one transaction
  uint256 public maxMintPerTx = 3;

  // Maximum mint amount per one wallet
  uint256 public maxMintPerAddress = 3;

  // wallet address => minted amount
  mapping(address => uint256) public minted;

  // whitelist wallet address => minted amount (pre-sale)
  mapping(address => uint256) public mintedPresale;

  event LogMaxMintPerTxSet(uint256 maxMintPerTx);

  event LogMaxMintPerAddressSet(uint256 maxMintPerAddress);

  event LogSaleStarted(address indexed operator);

  event LogPresaleStarted(address indexed operator);

  event LogSaleEnded(address indexed operator);

  event LogAssetSet(Asset indexed asset);

  event LogMintingCapSet(uint256 mintingCap);

  event LogEthSent(
    address indexed account, 
    uint256 amount
  );

  event LogPurchased(
    address indexed account, 
    uint256 amount
  );

  event LogPriceSet(uint256 price);

  event LogMaxMintableSet(uint256 maxMintable);

  event LogUnsoldTokensMinted(
    address indexed account,
    uint256 amount
  );

  /**
   * @param _signer signer wallet
   * @param _asset Asset contract address; must be contract address
   * @param _mintingCap minting cap; must not be zero
   */
  constructor(
    address _signer,
    Asset _asset,
    uint256 _mintingCap
  ) Signer(_signer) { 
    if (!address(_asset).isContract()) revert NotContract();
    if (_mintingCap == 0) revert InvalidMintingCap();

    asset = _asset;
    mintingCap = _mintingCap;
    emit LogAssetSet(_asset);
    emit LogMintingCapSet(_mintingCap);
  }

  /**
   * @dev Disable Eth receive with no data
   */
  receive() external payable {
    revert EthReceived();
  }

  /**
   * @dev Start presale step
   *
   * Requirements:
   * - Only operator can call
   */
  function startPresale() external onlyOperator {
    if (step == Step.PRESALE) revert NoChangeToTheState();

    step = Step.PRESALE;
    emit LogPresaleStarted(msg.sender);
  }

  /**
   * @dev End presale/sale
   *
   * Requirements:
   * - Only operator can call
   */
  function endSale() external onlyOperator {
    if (step == Step.NONE) revert NoChangeToTheState();

    step = Step.NONE;
    emit LogSaleEnded(msg.sender);
  }

  /**
   * @dev Start public sale step
   *
   * Requirements:
   * - Only operator can call
   */
  function startSale() external onlyOperator {
    if (step == Step.SALE) revert NoChangeToTheState();

    step = Step.SALE;
    emit LogSaleStarted(msg.sender);
  }

  /**
   * @dev Set NFT price
   *
   * Requirements:
   * - Only operator can call
   * @param _price NFT price; zero possible; must not be same as before
   */
  function setPrice(uint256 _price) external onlyOperator {
    if (_price == price) revert NoChangeToTheState();
    
    price = _price;
    emit LogPriceSet(_price);
  }

  /**
   * @dev Set max mint per tx
   *
   * Requirements:
   * - Only operator can call
   * @param _maxMintPerTx max mint limit per tx; must not be zero; must not be same as before
   */
  function setMaxMintPerTx(uint256 _maxMintPerTx) external onlyOperator {
    if (_maxMintPerTx == 0) revert InvalidMaxMintPerTx();
    if (_maxMintPerTx == maxMintPerTx) revert NoChangeToTheState();

    maxMintPerTx = _maxMintPerTx;
    emit LogMaxMintPerTxSet(_maxMintPerTx);
  }

  /**
   * @dev Set max mint per wallet
   *
   * Requirements:
   * - Only operator can call
   * @param _maxMintPerAddress max mint limit per wallet; must not be zero; must not be same as before
   */
  function setMaxMintPerAddress(uint256 _maxMintPerAddress) external onlyOperator {
    if (_maxMintPerAddress == 0) revert InvalidMaxMintPerAddress();
    if (_maxMintPerAddress == maxMintPerAddress) revert NoChangeToTheState();
    
    maxMintPerAddress = _maxMintPerAddress;
    emit LogMaxMintPerAddressSet(_maxMintPerAddress);
  }

  /**
   * @dev Increase max mint amount
   *
   * Requirements:
   * - Only operator can call
   * - Increased max mint must not exceed cap
   * @param _amount increase amount; must not be zero
   */
  function increaseMaxMintable(uint256 _amount) external onlyOperator {
    if (_amount == 0) revert InvalidAmount();

    uint256 _maxMintableIncreased = maxMintable + _amount;

    if (_maxMintableIncreased > mintingCap) revert ExceedCap();

    maxMintable = _maxMintableIncreased;
    emit LogMaxMintableSet(_maxMintableIncreased);
  }

  /**
   * @dev Mint unsold tokens; amount = total cap - total minted amount
   *
   * Requirements:
   * - Only operator can call
   * - Sale must be ended
   * - NFTs must not be sold out
   * @param _to receiver wallet; must not be zero address
   */
  function mintUnsoldTokens(address _to) external onlyOperator {
    if (step != Step.NONE) revert SaleNotEnded();
    if (totalMinted == mintingCap) revert NFTSoldOut();

    uint256 _amount;

    unchecked {
      // we will not underflow `_amount` because of above check
      _amount = mintingCap - totalMinted;
    }

    asset.mintBatch(_to, _amount);
    totalMinted = mintingCap;
    emit LogUnsoldTokensMinted(_to, _amount);
  }

  /**
   * @dev Withdraw Eth
   *
   * Requirements:
   * - Only `owner` can call
   * @param _to receiver wallet; must not be zero address
   */
  function withdrawEth(address _to) external onlyOwner {
    if (_to == address(0)) revert InvalidAddress();

    uint256 balance = address(this).balance;
    payable(_to).transfer(balance);
    emit LogEthSent(_to, balance);
  }

  /**
   * @dev Purchase tokens
   *
   * Requirements:
   * - Sale must be ongoing
   * - Caller must not be contract address
   * - Enough Eth must be received
   * @param _amount buy amount; must not be zero; must not exceed max mint per tx
   */
  function purchase(
    uint256 _amount,
    bytes calldata _sig
  ) external payable {
    if (msg.sender.isContract()) revert InvalidAddress();
    if (_amount == 0) revert InvalidAmount();
    if (_amount > maxMintPerTx) revert ExceedMaxMintPerTx();

    if (step == Step.PRESALE) {
      bytes32 msgHash = keccak256(abi.encodePacked(
        super._chainId(), 
        address(asset), 
        _amount, 
        msg.sender,
        ++nonces[msg.sender]
      ));

      if (!super._verify(msgHash, _sig)) revert InvalidSignature();

      _updateMintedAmount(mintedPresale, _amount);
    } else if (step == Step.SALE) {
      _updateMintedAmount(minted, _amount);
    } else {
      revert SaleNotGoing();
    }

    uint256 _totalMinted = totalMinted + _amount;
    uint256 totalPrice = _amount * price;

    if (_totalMinted > maxMintable) revert ExceedMaxMintable();
    if (msg.value < totalPrice) revert InsufficientEth();

    asset.mintBatch(msg.sender, _amount);
    totalMinted = _totalMinted;
    uint256 change = msg.value - totalPrice;

    if (change != 0) {
      payable(msg.sender).transfer(change);
    }

    emit LogPurchased(msg.sender, _amount);
  }

  /**
   * Override {Operatorable-transferOwnership}
   */
  function transferOwnership(address _newOwner) public virtual override(Ownable, Operatorable) {
    Operatorable.transferOwnership(_newOwner);
  }

  /**
   * @dev Update minted amount
   * @param _storage mintedPresale or minted
   * @param _amount purchase amount
   */
  function _updateMintedAmount(
    mapping(address => uint256) storage _storage, 
    uint256 _amount
  ) private {
    uint256 _minted = _storage[msg.sender] + _amount;

    if (_minted > maxMintPerAddress) revert ExceedMaxMintPerAddress();

    _storage[msg.sender] = _minted;
  }
}