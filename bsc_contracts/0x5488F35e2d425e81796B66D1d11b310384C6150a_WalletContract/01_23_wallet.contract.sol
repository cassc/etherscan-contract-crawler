// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./nft.contract.sol";
import "./erc20.contract.sol";

contract WalletContract is Context, Ownable {

  using SafeERC20 for ERC20;
  using SafeMath for uint256;
  using ECDSA for bytes32;

  // Mapping from token ID to owner address for deposited tokens
  mapping(uint256 => address) private _owners;
  // Address of NFT smart contract to interact with
  address private _nftContractAddress;
  // Address of ERC20 RCT smart contract to interact with
  address private _rctContractAddress;
  // Address of stable coin smart contracts to iterate
  address[] private _stableCoinContractAddresses;
  // Global buys lock
  bool public allBuysLocked = false;
  // Global sells lock
  bool public allSellsLocked = false;
  // Address who signing all permit strings parameters
  address public signatory;
  // Mapping for current address signature nonces
  mapping (address => uint) public nonces;
  // Name for ip712 contract domain
  string public constant name = "WalletContract";
  // Rate precision
  uint public constant _precisionRate = 100;
  // The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
  // The EIP-712 typehash for the permit struct used by the contract
  bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address participant,address contract,uint256 value,uint256 nonce,uint256 deadline)");
  // Structure for store stable coin data
  struct StableCoin {
    ERC20 contractInterface;
    uint256 rate;
    bool buyLocked;
    bool sellLocked;
  }
  // Mapping for stable coin contracts
  mapping(address => StableCoin) private _stableCoins;

  /**
    * @notice Emitted when somebody bought RCT
    */
  event tokenBought(address buyerAddress, address stableCoinContract, uint256 amount);

  /**
    * @notice Emitted when somebody sold RCT
    */
  event tokenSold(address sellerAddress, address stableCoinContract, uint256 amount);

  /**
    * @notice Emitted when `tokenId` token is deposited to wallet.
    */
  event Deposit(address indexed owner, uint256 indexed tokenId);

  /**
    * @notice Emitted when `tokenId` token is withdrew from wallet.
    */
  event Withdraw(address indexed owner, uint256 indexed tokenId);

  /**
    * @notice Initializes the contract by setting a `nftContractAddress` which wallet interact with.
    */
  constructor(address nftContractAddress_, address rctContractAddress_, address signatory_, address[] memory stableCoins_, uint[] memory rates_) {
    _setNftContractAddress(nftContractAddress_);
    _setRctContractAddress(rctContractAddress_);

    uint256 stableCoinsLenght = stableCoins_.length;
    for(uint i = 0 ; i < stableCoinsLenght; i++) {
      require(stableCoins_[i] != address(0), "Wallet: contract address is the zero address");
      require(rates_[i] > 0, "Wallet: rate must be greater than 0");
      require(_stableCoins[stableCoins_[i]].rate == 0, "Wallet: given stable coin already added");

      _stableCoins[stableCoins_[i]] = StableCoin(ERC20(stableCoins_[i]), rates_[i], false, false);
      _stableCoinContractAddresses.push(stableCoins_[i]);
    }

    signatory = signatory_;
  }

  /**
    * @notice Add stable coin contract
    * @param stableCoinContractAddress Address of stable coin contract
    * @param stableCoinRate Rate of stable coin. If 1 RCT cost 0.2 of some stable coin than rate is equal 20
    */
  function addStableCoin(address stableCoinContractAddress, uint stableCoinRate) public onlyOwner returns(bool)  {
    require(stableCoinContractAddress != address(0), "Wallet: contract address is the zero address");
    require(stableCoinRate > 0, "Wallet: rate must be greater than 0");
    require(_stableCoins[stableCoinContractAddress].rate == 0, "Wallet: given stable coin already added");

    _stableCoins[stableCoinContractAddress] = StableCoin(ERC20(stableCoinContractAddress), stableCoinRate, false, false);
    _stableCoinContractAddresses.push(stableCoinContractAddress);
    return true;
  }

  /**
    * @notice Returns stable coins data.
    */
  function getStableCoins() public view returns (StableCoin[] memory) {
    uint length = _stableCoinContractAddresses.length;
    StableCoin[] memory coins = new StableCoin[](length);
    for (uint i = 0; i < length; i++) {
      coins[i] = _stableCoins[_stableCoinContractAddresses[i]];
    }
    return coins;
  }

  /**
    * @notice Updates rates of stable coins
    * @param stableCoins Addresses of stable coin contracts
    * @param rates New rates values with order preservation
    */
  function updateRates(address[] memory stableCoins, uint[] memory rates) public onlyOwner returns(bool){
    uint256 stableCoinsLenght = stableCoins.length;
    for(uint i = 0 ; i < stableCoinsLenght; i++) {
      require(stableCoins[i] != address(0), "Wallet: one of the contract addresses is the zero address");
      require(rates[i] > 0, "Wallet: rate must be greater than 0");
      require(_stableCoins[stableCoins[i]].rate != 0, "Wallet: one of the contract addresses not found");

      _stableCoins[stableCoins[i]].rate = rates[i];
    }
    return true;
  }

  /**
    * @notice Lock or unlock buying with given stable coin
    * @param locked Lock state
    * @param stableCoinContractAddress Address of stable coin contract
    */
  function setBuysLocker(bool locked, address stableCoinContractAddress) public onlyOwner {
    StableCoin memory stableCoin = _stableCoins[stableCoinContractAddress];
    require(stableCoin.rate != 0, "Wallet: one of the contract addresses not found");
    stableCoin.buyLocked = locked;
    _stableCoins[stableCoinContractAddress] = stableCoin;
  }

  /**
    * @notice Lock or unlock buying for all stable coins
    * @param locked Lock state
    */
  function setBuysLocker(bool locked) public onlyOwner {
    allBuysLocked = locked;
  }

  /**
    * @notice Lock or unlock selling with given stable coin
    * @param stableCoinContractAddress Address of stable coin contract
    */
  function setSellsLocker(bool locked, address stableCoinContractAddress) public onlyOwner {
    StableCoin memory stableCoin = _stableCoins[stableCoinContractAddress];
    stableCoin.sellLocked = locked;
    _stableCoins[stableCoinContractAddress] = stableCoin;
  }

  /**
    * @notice Lock or unlock selling for all stable coins
    * @param locked Lock state
    */
  function setSellsLocker(bool locked) public onlyOwner {
    allSellsLocked = locked;
  }

  /**
    * @notice Buy RCT token with stable coin
    * @param stableCoinContractAddress Address of stable coin contract
    * @param stableCoinAmount Number of stable coins to convert to RCT
    * @param nonce Signatory nonce
    * @param deadline Signature expiring time
    * @param v Recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    *
    * Emits a {tokenBought} event.
    */
  function buyToken(address stableCoinContractAddress, uint stableCoinAmount, uint nonce, uint deadline, uint8 v, bytes32 r, bytes32 s) public {
    require(allBuysLocked == false, "Wallet: buy locked for all coins");
    StableCoin memory stableCoin = _stableCoins[stableCoinContractAddress];
    require(stableCoin.buyLocked == false, "Wallet: buy locked for this stable coin");

    bool accept = checkPermitSignature(msg.sender, stableCoinContractAddress, stableCoinAmount, nonce, deadline, v, r, s);
    require(accept == true, "Wallet: invalid signature");

    stableCoin.contractInterface.safeTransferFrom(address(msg.sender), address(this), stableCoinAmount);
    Erc20Contract rctContract = Erc20Contract(getRctContractAddress());

    uint decimalsStable = stableCoin.contractInterface.decimals();
    uint decimalsRct = rctContract.decimals();

    uint amount = getExchangedAmount(stableCoinAmount, stableCoin.rate, decimalsStable, decimalsRct, true);
    rctContract.mint(msg.sender, amount);

    emit tokenBought(msg.sender, stableCoinContractAddress, stableCoinAmount);
  }

  /**
    * @notice Sell RCT token for stable coin
    * @param stableCoinContractAddress Address of stable coin contract
    * @param tokenAmount Number of RCT to convert to stable
    * @param nonce Signatory nonce
    * @param deadline Signature expiring time
    * @param v Recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    *
     * Emits a {tokenSold} event.
    */
  function sellToken(address stableCoinContractAddress, uint tokenAmount, uint nonce, uint deadline, uint8 v, bytes32 r, bytes32 s) public {
    require(allSellsLocked == false, "Wallet: sell locked for all coins");
    StableCoin memory stableCoin = _stableCoins[stableCoinContractAddress];
    require(stableCoin.sellLocked == false, "Wallet: sell locked for this stable coin");

    bool accept = checkPermitSignature(msg.sender, stableCoinContractAddress, tokenAmount, nonce, deadline, v, r, s);
    require(accept == true, "Wallet: invalid signature");

    Erc20Contract rctContract = Erc20Contract(getRctContractAddress());
    rctContract.burn(msg.sender, tokenAmount);

    uint decimalsStable = stableCoin.contractInterface.decimals();
    uint decimalsRct = rctContract.decimals();

    uint amount = getExchangedAmount(tokenAmount, stableCoin.rate, decimalsStable, decimalsRct, false);
    stableCoin.contractInterface.safeTransfer(address(msg.sender), amount);

    emit tokenSold(msg.sender, stableCoinContractAddress, tokenAmount);
  }

  /**
   * @notice Returns converted amount for sell or buy operation
    * Result is rounded floor to closest integer value
    * @param amount Amount of currency to convert
    * @param rate of currency in percent for RCT to stable coin
    * @param decimalsStable Decimals of stable coin
    * @param decimalsRct Decimals of RCT
    * @param buyOperation Is operation buy or sell
    */
  function getExchangedAmount(uint amount, uint rate, uint decimalsStable, uint decimalsRct, bool buyOperation ) public pure returns (uint) {
    if(buyOperation) {
      return (amount).mul(_precisionRate).mul(10**decimalsRct).div(rate).div(10**decimalsStable);
    }
    return (amount).mul(rate).mul(10**decimalsStable).div(_precisionRate).div(10**decimalsRct);
  }

  /**
    * @notice Check permit signature
    * @param participant Address to be approved
    * @param rawAmount Number of tokens that are approved (2^256-1 means infinite)
    * @param nonce Contract state required to match the signature
    * @param deadline Time at which to expire the signature
    * @param v Recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    */
  function checkPermitSignature(address participant, address stableCoinContract, uint rawAmount, uint nonce, uint deadline, uint8 v, bytes32 r, bytes32 s) internal returns (bool) {
    uint96 amount;
    if (rawAmount == type(uint).max) {
      amount = type(uint96).max;
    } else {
      amount = safe96(rawAmount, "Wallet: amount exceeds 96 bits");
    }

    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
    bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, participant, stableCoinContract, rawAmount, nonce, deadline));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    address _signatory = ecrecover(digest, v, r, s);

    require(_signatory != address(0), "Wallet: invalid signature");
    require(signatory == _signatory, "Wallet: unauthorized");
    require(block.timestamp <= deadline, "Wallet: signature expired");
    nonces[_signatory] = nonce;

    return true;
  }

  /**
    * @notice Returns chain id
    * @return chainId
    */
  function getChainId() internal view returns (uint) {
    uint256 chainId;
    assembly { chainId := chainid() }

    return chainId;
  }

  /**
    * @notice Check uint is safe96
    *
    */
  function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
    require(n < 2**96, errorMessage);

    return uint96(n);
  }

  /**
    * @dev Transfer `tokenId` from owner to wallet. Create record to mapping _owners
    *
    * Requirements:
    *
    * - `tokenId` token must be approved by owner to wallet contract address in advice.
    * - the caller must be owner of `tokenId`.
    * - the NFT contract must not be paused.
    *
    * Emits a {Deposit} event.
    */
  function deposit(uint256 tokenId) public {
    require(
      _isApprovedOrOwnerAndApprovedToWallet(_msgSender(), tokenId),
      "Wallet: transfer caller is not owner nor approved or token not approved for wallet contract"
    );
    NftContract nftContract = NftContract(getNftContractAddress());
    address tokenOwner = nftContract.ownerOf(tokenId);
    nftContract.transferFrom(tokenOwner, address(this), tokenId);
    _owners[tokenId] = tokenOwner;
    emit Deposit(tokenOwner, tokenId);
  }

  /**
    * @dev Withdraw `tokenId` from wallet to owner. Delete record from mapping _owners
    *
    * Requirements:
    *
    * - the caller must be owner who deposited `tokenId` token to wallet.
    * - the NFT contract must not be paused.
    *
    * Emits a {Withdraw} event.
    */
  function withdraw(uint256 tokenId) public {
    address msgSender = _msgSender();
    NftContract nftContract = NftContract(getNftContractAddress());
    require(ownerOf(tokenId) == msgSender, "Wallet: only owner of token can withdraw it");
    delete _owners[tokenId];
    nftContract.transferFrom(address(this), msgSender, tokenId);
    emit Withdraw(msgSender, tokenId);
  }

  /**
    * @dev Create token deposited to wallet contract, 'to' is address of real owner who will be able to withdraw token.
    * Returns tokenId of created token.
    *
    * Requirements:
    *
    * - the caller must be contract owner.
    * - the contract must not be paused.
    * - `to` cannot be the zero address.
    *
    * Emits a {Transfer} event.
    */
  function createItem(address to) public onlyOwner returns (uint256) {
    require(to != address(0), "Wallet: to address can't be zero address");

    NftContract nftContract = NftContract(getNftContractAddress());

    uint256 newItemId = nftContract.createItem(address(this));
    _owners[newItemId] = to;

    return newItemId;
  }

  /**
    * @dev Returns the owner of the `tokenId` token if it was deposited to wallet.
    *
    * Requirements:
    *
    * - `tokenId` must be deposited to wallet.
    */
  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "Wallet: owner query for nonexistent token");
    return owner;
  }

  /**
    * @dev Returns the address of the NFT smart contract.
    */
  function getNftContractAddress() public view returns (address) {
    return _nftContractAddress;
  }

  /**
    * @dev See {Wallet-_setNftContractAddress}.
    */
  function setNftContractAddress(address newAddress) public onlyOwner {
    _setNftContractAddress(newAddress);
  }

  /**
    * @dev Set new NFT smart contract address.
    *
    * Requirements:
    *
    * - the caller must be wallet contract owner.
    * - `newAddress` cannot be the zero address.
    */
  function _setNftContractAddress(address newAddress) private {
    require(newAddress != address(0), "Wallet: new NFT smart contract address can't be zero address");
    _nftContractAddress = newAddress;
  }

  /**
    * @dev Returns the address of the ERC20 RCT smart contract.
    */
  function getRctContractAddress() public view returns (address) {
    return _rctContractAddress;
  }

  /**
    * @dev See {Wallet-_setRctContractAddress}.
    */
  function setRctContractAddress(address newAddress) public onlyOwner {
    _setRctContractAddress(newAddress);
  }

  /**
    * @dev Set new ERC20 RCT smart contract address.
    *
    * Requirements:
    *
    * - the caller must be wallet contract owner.
    * - `newAddress` cannot be the zero address.
    */
  function _setRctContractAddress(address newAddress) private {
    require(newAddress != address(0), "Wallet: new ERC20 RCT smart contract address can't be zero address");
    _rctContractAddress = newAddress;
  }

  /**
    * @notice Returns whether `spender` is allowed to manage `tokenId` and token was approved for manage by wallet contract
    * @param spender Address of spender
    * @param tokenId Id token to check
    * @return true if allowed and token approved
    */
  function _isApprovedOrOwnerAndApprovedToWallet(address spender, uint256 tokenId) internal view virtual returns (bool) {
    NftContract nftContract = NftContract(getNftContractAddress());
    address owner = nftContract.ownerOf(tokenId);
    return (
      (spender == owner || nftContract.getApproved(tokenId) == spender || nftContract.isApprovedForAll(owner, spender))
      && (nftContract.getApproved(tokenId) == address(this) || nftContract.isApprovedForAll(owner, address(this)))
    );
  }

  /**
     * @notice Check permit signature
     * @param participant The address to be approved
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @param nonce The contract state required to match the signature
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
  function checkSignature(address participant, address stableCoinContract, uint rawAmount, uint nonce, uint deadline, uint8 v, bytes32 r, bytes32 s) external view returns (bool) {
    uint96 amount;

    if (rawAmount == type(uint).max) {
      amount = type(uint96).max;
    } else {
      amount = safe96(rawAmount, "Wallet: amount exceeds 96 bits");
    }

    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
    bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, participant, stableCoinContract, rawAmount, nonce, deadline));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    address _signatory = ecrecover(digest, v, r, s);

    require(_signatory != address(0), "Wallet: invalid signature");
    require(signatory == _signatory, "Wallet: unauthorized");
    require(block.timestamp <= deadline, "Wallet: signature expired");

    return true;
  }
}