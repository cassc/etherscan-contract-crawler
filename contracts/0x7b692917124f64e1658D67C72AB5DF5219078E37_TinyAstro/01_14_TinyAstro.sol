// SPDX-License-Identifier: MIT
//.___________. __  .__   __. ____    ____      ___           _______..___________..______        ______
//|           ||  | |  \ |  | \   \  /   /     /   \         /       ||           ||   _  \      /  __  \
//`---|  |----`|  | |   \|  |  \   \/   /     /  ^  \       |   (----``---|  |----`|  |_)  |    |  |  |  |
//    |  |     |  | |  . `  |   \_    _/     /  /_\  \       \   \        |  |     |      /     |  |  |  |
//    |  |     |  | |  |\   |     |  |      /  _____  \  .----)   |       |  |     |  |\  \----.|  `--'  |
//    |__|     |__| |__| \__|     |__|     /__/     \__\ |_______/        |__|     | _| `._____| \______/

pragma solidity 0.8.15;

import "./erc721a/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ILeaseController.sol";

error MintingNotStarted();
error IncorrectTierAttempt();
error MaxSupplyExceeded();
error MaxMintTransactionExceeded();
error InvalidMintAmount();
error CallerIsAContract();
error IncorrectFundsAmount();
error PublicMintIsNotActivated();
error IncorrectAddress();
error InvalidCoupon();
error PriceIsTooLow();
error TokenIsStaked();
error InvalidTierNumber();

contract TinyAstro is ERC721AQueryable, Ownable, ReentrancyGuard {
  uint8 public constant INACTIVE_TIER = 0;
  uint8 public constant PUBLIC_SALE_TIER = 64;

  string public baseURI;
  string public hiddenMetadataURI = "ipfs://QmQjUV3JiCPxVmwcHmY5RF7VZbyrFPbUE2pvDAmY6ongxt";

  uint256 public price = 0.095 ether;
  uint256 public constant maxSupply = 5888;

  // on deploy make it private;
  address public pubSigner = 0xE3d258D0c901C9b9aC2dcC4B34bd6c91304078FD;

  // Supporting tiers ( 0 - paused; 64 - public sale tier; 1 ~ 63 - private whitelisted tiers )
  struct Config {
    uint8 tierNumber; // Current tier
    uint8 maxAmount;  // Max tokens per mint transaction
    uint16 maxMintTx; // Max mint transactions per tier
  }
  Config public mintConfig;

  address private leaseController;

  // Number of mint transactions per tier
  mapping(uint8 => uint16) numberMintTx;

  constructor() ERC721A("TinyAstro", "TA") { }

  // ==== MODIFIERS ==== //
  modifier mintGeneralCompliance(uint256 _mintAmount, uint8 _tierNumber) {
    // validate contract is active
    // isActive is true
    if (mintConfig.tierNumber == INACTIVE_TIER) {
      revert MintingNotStarted();
    }

    // validate user tier number
    // tier should be equal to current config tier
    if (_tierNumber != mintConfig.tierNumber) {
      revert IncorrectTierAttempt();
    }

    // caller is user
    if (tx.origin != msg.sender) {
      revert CallerIsAContract();
    }

    // validate totalSupply
    // mintAmount + all minted tokens should be less or equal than maxSupply
    if (_totalMinted() + _mintAmount > maxSupply) {
      revert MaxSupplyExceeded();
    }

    // validate wallet for previous purchases
    // we allow to mint only once per tier
    uint64 tierMintedMask = uint64(1 << (_tierNumber - 1));
    uint64 aux = _getAux(msg.sender);
    if (aux & tierMintedMask > 0) {
      revert InvalidMintAmount();
    }

    if (msg.value < (price * _mintAmount)) {
      revert IncorrectFundsAmount();
    }

    if (numberMintTx[_tierNumber] >= mintConfig.maxMintTx) {
      revert MaxMintTransactionExceeded();
    }

    _;

    _setAux(msg.sender, aux | tierMintedMask);
    numberMintTx[_tierNumber]++;
  }

  // ==== MAIN FUNCTIONS ==== //
  // Mint Functions //

  function mintTier(
    uint256 _mintAmount,
    bytes32 _r,
    bytes32 _s,
    uint8 _v,
    uint8 _tierNumber,
    uint8 _maxAmount
  ) external payable mintGeneralCompliance(_mintAmount, _tierNumber) nonReentrant {
    // validate couponCode with assigned tier number and max mint amount
    bytes32 digest = keccak256(abi.encode(_tierNumber, _maxAmount, msg.sender));
    if (!_isCouponValid(digest, _r, _s, _v)) {
      revert InvalidCoupon();
    }

    if (_mintAmount > _maxAmount) {
      revert InvalidMintAmount();
    }

    _mint(msg.sender, _mintAmount, '', false);
  }

  function mintPublic(uint8 _mintAmount) external payable mintGeneralCompliance(_mintAmount, PUBLIC_SALE_TIER) nonReentrant {
    // validate mintAmount
    // should not exceed max allowed mint amount from config per msg sender tier
    // also validating here that maxAmount from configs for current tier > 0
    if (_mintAmount > mintConfig.maxAmount) {
      revert InvalidMintAmount();
    }

    _mint(msg.sender, _mintAmount, '', false);
  }

  function burn(uint256 _tokenId) external {
    _burn(_tokenId, true);
  }

  // Public View Functions //

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A) returns (string memory) {
    string memory _tokenURI = super.tokenURI(_tokenId);
    return bytes(_tokenURI).length != 0 ? _tokenURI : hiddenMetadataURI;
  }

  function getMintData(address _owner)
    public
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (numberMinted(_owner), totalSupply(), mintConfig.tierNumber);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  //override renounceOwnership
  function renounceOwnership() public override onlyOwner {}

  // Setters Only Owner //
  function airdrop(uint256 _mintAmount, address _receiver) external onlyOwner {
    // validate totalSupply
    // mintAmount + all minted tokens should be less or equal than maxSupply
    if (_totalMinted() + _mintAmount > maxSupply) {
      revert MaxSupplyExceeded();
    }

    // validate mintAmount
    // should be > 0
    // should not exceed 50 tokens
    if (_mintAmount == 0 || _mintAmount > 50) {
      revert InvalidMintAmount();
    }

    _mint(_receiver, _mintAmount, '', false);
  }

  function setBaseURI(string memory _baseURIPrefix) external onlyOwner {
    baseURI = _baseURIPrefix;
  }

  function setPrice(uint256 _price) external onlyOwner {
    //validate price to make sure its not less than 0.01 eth
    if (_price < 0.01 ether) {
      revert PriceIsTooLow();
    }
    price = _price;
  }

  function setHiddenMetadataURI(string calldata _hiddenMetadataURI) external onlyOwner {
    hiddenMetadataURI = _hiddenMetadataURI;
  }

  function pauseContract() external onlyOwner {
    _setMintConfig(0, 0, 0);
  }

  function setActiveTier(uint8 _tierNumber, uint8 _maxAmount, uint16 _maxMintTx) external onlyOwner {
    if (_tierNumber == 0) {
      revert InvalidTierNumber();
    }
    _setMintConfig(_tierNumber, _maxAmount, _maxMintTx);
  }

  function setPubSigner(address _pubSigner) external onlyOwner {
    pubSigner = _pubSigner;
  }

  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
    return _ownershipOf(tokenId);
  }

  // Internal Functions //
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _setMintConfig(
    uint8 _tierNumber,
    uint8 _maxAmount,
    uint16 _maxMintTx
  ) internal {
    mintConfig.tierNumber = _tierNumber;
    mintConfig.maxAmount = _maxAmount;
    mintConfig.maxMintTx = _maxMintTx;
  }

  function _isCouponValid(
    bytes32 digest,
    bytes32 _r,
    bytes32 _s,
    uint8 _v
  ) internal view returns (bool) {
    address signer = ecrecover(digest, _v, _r, _s);
    if (signer == address(0)) {
      revert IncorrectAddress();
    }
    return signer == pubSigner;
  }

  function _beforeTokenTransfers(
    address from,
    address, /* to */
    uint256 startTokenId,
    uint256 quantity
  ) internal view override {
    if (from != address(0) && quantity == 1) {
      // Before transfer or burn, verify the token is not staked.
      if (leaseController != address(0) && ILeaseController(leaseController).isTokenStaked(startTokenId)) {
        revert TokenIsStaked();
      }
    }
  }

  // Lease //

  function setLeaseController(address _leaseController) external onlyOwner {
    leaseController = _leaseController;
  }
}