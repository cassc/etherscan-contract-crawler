// SPDX-License-Identifier: None
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "erc721a/contracts/ERC721A.sol";
import "./ERC2981.sol";

error AddressCannotBeZero();
error NotAuthorizedToMint();
error SupplyLimitTooLow();
error OutOfSupply();
error ZeroBalance();

contract DragonForge is Ownable, ERC721A, ERC2981, PaymentSplitter {
  mapping(address => bool) public isApprovedMinter;

  uint256 public supplyLimit = 2201;

  string public baseURI;

  address[] private _payees = [
    0x1BA6A65Ac7bc72EFCDFa8935fAFd826150013765,
    0xc0dD320CeF1f15bf60FA87dD9F80b2686E7B434F,
    0xef77Cf894ED766B233e2009658e55f49D6C3440d,
    0xc2B224996e1318641Fa6990364B94Af42A298771,
    0x13E5FBB2F32a01A15d57F5E93A75145fD6CdA982,
    0x4e1C09bC01934C11ADb6bB04D93451264FfcfAD5,
    0xB04bE01dF533EB613a0a9dDA3dBE5876797cFbd3
  ];

  uint256[] private _shares = [770, 50, 30, 15, 15, 20, 100];

  constructor(string memory baseUri_)
    ERC721A("Dragon Forge", "DF")
    PaymentSplitter(_payees, _shares)
  {
    baseURI = baseUri_;

    _setDefaultRoyalty(address(this), 750); // 7.5% royalties
    _setTokenRoyalty(0, address(this), 1000); // 10% royalties for custom dragons
  }

  modifier onlyApprovedMinter() {
    if (!isApprovedMinter[msg.sender] && msg.sender != owner())
      revert NotAuthorizedToMint();
    _;
  }

  /// @notice Allows the contract owner to approve an address to execute the mint functions
  /// @param minter The address to approve
  function approveMinter(address minter) external onlyOwner {
    isApprovedMinter[minter] = true;
  }

  /// @notice Allows the contract owner to revoke approval for an address to execute the mint functions
  /// @param minter The address to revoke
  function revokeMinter(address minter) external onlyOwner {
    isApprovedMinter[minter] = false;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }

  function updateSupplyLimit(uint256 newSupplyLimit) external onlyOwner {
    if (newSupplyLimit < totalSupply()) revert SupplyLimitTooLow();

    supplyLimit = newSupplyLimit;
  }

  function setRoyalties(address recipient, uint96 value) external onlyOwner {
    if (recipient == address(0)) revert AddressCannotBeZero();
    _setDefaultRoyalty(recipient, value);
  }

  function setCustomRoyalties(address recipient, uint96 value)
    external
    onlyOwner
  {
    if (recipient == address(0)) revert AddressCannotBeZero();
    _setTokenRoyalty(0, recipient, value);
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    public
    view
    override
    returns (address, uint256)
  {
    if (_tokenId > 200) return super.royaltyInfo(_tokenId, _salePrice);

    return super.royaltyInfo(0, _salePrice);
  }

  function mint(address to, uint256 numberOfTokens)
    external
    onlyApprovedMinter
  {
    if (totalSupply() + numberOfTokens > supplyLimit) revert OutOfSupply();

    _mint(to, numberOfTokens, "", false);
  }

  function withdrawAll() external {
    if (address(this).balance == 0) revert ZeroBalance();

    for (uint256 i = 0; i < _payees.length; i++) {
      release(payable(payee(i)));
    }
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}