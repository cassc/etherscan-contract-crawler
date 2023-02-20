// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

import "./interfaces/ISLERC721AUpgradeable.sol";
import "./interfaces/ISLERC721ATransferAuthorizer.sol";

/// @title SLERC721AUpgradeable
/// @author Julien Bessaguet
/// @notice NFT contract for Nifty Jitsu. Minting is delegated to another
/// comtract.
abstract contract SLERC721AUpgradeable is
  ERC721AUpgradeable,
  DefaultOperatorFiltererUpgradeable,
  OwnableUpgradeable,
  ISLERC721AUpgradeable
{
  /// @notice Royalties recipient
  address public beneficiary;
  ///@notice Starting index, pseudo randomly set
  int32 public startingIndex;
  ///@notice Provenance hash of images
  string public provenanceHash;

  /// @notice base URI for metadata
  string public baseURI;
  /// @dev Contract URI used by OpenSea to get contract details (owner, royalties...)
  string public contractURI;

  // Address allowed to mint
  address public minter;
  // Address called to check if transfer is authorized.
  ISLERC721ATransferAuthorizer public transferAuthorizer;

  function __SLERC721AUpgradeable_init(
    string memory name_,
    string memory symbol_
  ) public onlyInitializingERC721A onlyInitializing {
    __ERC721A_init(name_, symbol_);
    __Ownable_init();
    __DefaultOperatorFilterer_init();

    beneficiary = owner();
    minter = owner();
    startingIndex = -1;
  }

  modifier onlyMinter() {
    require(_msgSenderERC721A() == minter, "caller is not minter");
    _;
  }

  /// @inheritdoc ISLERC721AUpgradeable
  function mintTo(address to, uint256 quantity) external payable onlyMinter {
    _safeMint(to, quantity);
  }

  /// @inheritdoc ISLERC721AUpgradeable
  function setStartingIndex(uint256 maxSupply) external onlyMinter {
    if (startingIndex == -1) {
      uint256 predictableRandom = uint256(
        keccak256(
          abi.encodePacked(
            blockhash(block.number - 1),
            block.difficulty,
            totalSupply()
          )
        )
      );
      startingIndex = int32(uint32(predictableRandom % (maxSupply)));
    }
  }

  /// @inheritdoc ERC721AUpgradeable
  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    returns (bool)
  {
    return
      interfaceId == this.royaltyInfo.selector ||
      super.supportsInterface(interfaceId);
  }

  ////////////////////////////////////////////////////
  ///// Royalties                                   //
  ////////////////////////////////////////////////////

  /// @dev Royalties are the same for every token that's why we don't use OZ's impl.
  function royaltyInfo(
    uint256,
    uint256 amount
  ) public view returns (address, uint256) {
    // (royaltiesRecipient || owner), 7.5%
    return (beneficiary, (amount * 750) / 10000);
  }

  ////////////////////////////////////////////////////
  ///// Only Owner                                  //
  ////////////////////////////////////////////////////

  /// @notice Allow the owner to change the baseURI
  /// @param newBaseURI the new uri
  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  /// @notice Allow the owner to set the provenancehash
  /// Should be set before sales open.
  /// @param provenanceHash_ the new hash
  function setProvenanceHash(string memory provenanceHash_) external onlyOwner {
    provenanceHash = provenanceHash_;
  }

  /// @notice Allow owner to set the royalties recipient
  /// @param newBeneficiary the new contract uri
  function setBeneficiary(address newBeneficiary) external onlyOwner {
    require(
      newBeneficiary != address(0),
      "cannot set null address as beneficiary"
    );
    beneficiary = newBeneficiary;
  }

  /// @notice Allow owner to set the minter
  /// @param newMinter the new contract uri
  function setMinter(address newMinter) external onlyOwner {
    minter = newMinter;
  }

  /// @notice Allow owner to set the authorizer
  /// @param newAuthorizer the new contract uri
  function setTransferAuthorizer(
    ISLERC721ATransferAuthorizer newAuthorizer
  ) external onlyOwner {
    transferAuthorizer = newAuthorizer;
  }

  /// @notice Allow owner to set contract URI
  /// @param newContractURI the new contract URI
  function setContractURI(string calldata newContractURI) external onlyOwner {
    contractURI = newContractURI;
  }

  /// @notice Allow everyone to withdraw contract balance and send it to owner
  function withdraw() external {
    AddressUpgradeable.sendValue(payable(beneficiary), address(this).balance);
  }

  /// @notice Allow everyone to withdraw contract ERC20 balance and send it to owner
  function withdrawERC20(IERC20Upgradeable token) external {
    SafeERC20Upgradeable.safeTransfer(
      token,
      beneficiary,
      token.balanceOf(address(this))
    );
  }

  ////////////////////////////////////////////////////
  ///// External lock possibilities                 //
  ////////////////////////////////////////////////////

  /// @inheritdoc ERC721AUpgradeable
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override(ERC721AUpgradeable) {
    if (address(transferAuthorizer) != address(0)) {
      require(
        transferAuthorizer.isERC721ATransferAuthorized(
          from,
          to,
          startTokenId,
          quantity
        ),
        "transfer unauthorized"
      );
    }
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }

  ////////////////////////////////////////////////////
  ///// OpenSea royalties enforcement filters       //
  ////////////////////////////////////////////////////

  function setApprovalForAll(
    address operator,
    bool approved
  )
    public
    virtual
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  )
    public
    payable
    virtual
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
    payable
    virtual
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    onlyAllowedOperator(from)
  {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
    payable
    virtual
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  )
    public
    payable
    virtual
    override(ERC721AUpgradeable, IERC721AUpgradeable)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}