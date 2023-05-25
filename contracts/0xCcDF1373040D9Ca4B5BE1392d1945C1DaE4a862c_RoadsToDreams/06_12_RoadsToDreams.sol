// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./TimeLock.sol";
import "./WhitelistAble.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

/// @title The final contract for the roads2Dreams drop
contract RoadsToDreams is ERC721AQueryable, Ownable, TimeLock, WhitelistAble {
  using ECDSA for bytes32;

  // counter
  /// @dev Counter for the amount of NFTs minted by the owner by executing the ownerMint function
  uint16 private _ownerMinted = 0;

  // variables
  /// @dev The base toke URI
  string private _baseTokenURI;
  /// @dev The mint price in WEI
  uint256 private _mintPrice;
  /// @dev The maximum token supply
  uint16 private _maxSupply;
  /// @dev The maximum numbers of NFTs a user can mint per TX
  uint16 private _maxPublicNftMintsAtOnce;
  /// @dev The number of reserved owner mints
  uint16 private _ownerReservedMintingAmount;
  /// @dev The public key of the signer to allow participation in the public mint
  address private _allowListSigner;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI,
    uint256 mintPrice,
    uint256 mintStart,
    uint256 mintEnd,
    uint16 maxSupply,
    uint16 maxPublicNftMintsAtOnce,
    uint16 ownerReservedMintingAmount,
    address allowListSigner
  ) ERC721A(name, symbol) TimeLock(mintStart, mintEnd) {
    _baseTokenURI = baseURI;
    _mintPrice = mintPrice;
    _maxSupply = maxSupply;
    _maxPublicNftMintsAtOnce = maxPublicNftMintsAtOnce;
    _ownerReservedMintingAmount = ownerReservedMintingAmount;
    _allowListSigner = allowListSigner;
  }

  function contractURI() public view returns (string memory) {
    string memory baseURI = _baseURI();
    return
    bytes(baseURI).length > 0
    ? string(abi.encodePacked(baseURI, "contractMetadata"))
    : "";
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  /// @notice Returns the basic stats of the contract
  function stats() public view virtual returns (uint256[] memory) {
    uint256[] memory res = new uint256[](10);
    res[0] = _mintPrice;
    res[1] = uint256(_maxSupply);
    res[2] = uint256(_maxPublicNftMintsAtOnce);
    res[3] = totalSupply();
    res[4] = startTimestamp();
    res[5] = _ownerReservedMintingAmount - _ownerMinted;
    res[6] = endTimestamp();
    res[7] = getWhitelistStart();
    res[8] = getWhitelistEnd();
    res[9] = uint256(getWhitelistMaxMint());
    return res;
  }

  /// @notice This function allows owner to change the base token uri
  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  /// @notice This function allows owner to change the time lock data
  function setMintTimeLockData(uint256 start, uint256 end) public onlyOwner {
    _setTimeLockData(start, end);
  }

  /// @notice This function allows owner to change the allowlist signer
  function setAllowlistSigner(address allowListSigner) public onlyOwner {
    _allowListSigner = allowListSigner;
  }

  /// @notice This function allows owner to change the whitelist data
  function setWhitelistMintData(bytes32 whitelistMerkleRoot, uint256 whitelistStart, uint256 whitelistEnd, uint16 maxWhitelistNftMintsPerWallet) public onlyOwner {
    _setWhitelistData(whitelistMerkleRoot, whitelistStart, whitelistEnd, maxWhitelistNftMintsPerWallet);
  }

  /// @notice This function allows users to participate in the public mint
  function mint(uint16 amount, bytes calldata signature)
  public
  payable
  virtual
  onlyMintRunning
  {
    require(recoverSigner(msg.sender, signature) == _allowListSigner, "M7");
    _userMint(msg.sender, amount);
  }

  /// @notice This function allows users to participate in a whitelist wave mint
  function mintWhitelist(uint16 amount, bytes32[] calldata merkleProof)
  public
  payable
  {
    _checkAndFlagWhitelist(msg.sender, merkleProof, amount);
    _userMint(msg.sender, amount);
  }

  function _userMint(address newOwner, uint16 amount) internal {
    require(_totalMinted() - _ownerMinted + amount <= _maxSupply - _ownerReservedMintingAmount, "M2");
    require(amount > 0, "M3");
    require(amount <= _maxPublicNftMintsAtOnce, "M4");
    require(msg.value >= _mintPrice * amount, "M5");
    _safeMint(newOwner, amount);
  }

  /// @notice This function allows the owner to mint the reserved amount of NFTs
  function ownerMint(address newOwner, uint16 amount) external onlyOwner {
    require(_totalMinted() + amount <= _maxSupply, "M2");
    require(_ownerMinted + amount <= _ownerReservedMintingAmount, "M6");
    require(amount > 0, "M3");
    require(amount <= _maxPublicNftMintsAtOnce, "M4");
    _safeMint(newOwner, amount);
    _ownerMinted += amount;
  }

  /// @dev Returns the signer of the allow message
  function recoverSigner(address minter, bytes calldata signature) private view returns (address) {
    return keccak256(abi.encodePacked(minter, address(this))).toEthSignedMessageHash().recover(signature);
  }

  function payout(address payable receiver, uint256 amount)
  external
  onlyOwner
  {
    require(address(this).balance >= amount, "M0");
    (bool payoutSuccess,) = receiver.call{value : amount}("");
    require(payoutSuccess, "M1");
  }
}