// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "../../templates/NFTEthVaultUpgradeable.sol";
import "./ERC721Acc.sol";
import "./ERC1155Acc.sol";

interface BaseToken is IERC721EnumerableUpgradeable {
  function walletInventory(address _owner)
    external
    view
    returns (uint256[] memory);
}

contract FlootClaimsV3 is
  Initializable,
  ERC721HolderUpgradeable,
  ERC1155HolderUpgradeable,
  UUPSUpgradeable,
  NFTEthVaultUpgradeable
{
  event Received(address, uint256);

  bool public halt;
  Accounting721 _nFT721accounting;
  Accounting1155 _nFT1155accounting;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(
    address _baseToken,
    address _nft721accounting,
    address _nft1155accounting
  ) public initializer {
    __ERC721Holder_init();
    __ERC1155Holder_init();
    __nftVault_init(_baseToken);
    __UUPSUpgradeable_init();
    _nFT721accounting = Accounting721(_nft721accounting);
    _nFT1155accounting = Accounting1155(_nft1155accounting);
    halt = false;
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  function change1155accounting(address _address) public onlyOwner {
    _nFT1155accounting = Accounting1155(_address);
  }

  function change721accounting(address _address) public onlyOwner {
    _nFT721accounting = Accounting721(_address);
  }

  function onERC721Received(
    address,
    address,
    uint256 tokenID,
    bytes memory data
  ) public virtual override returns (bytes4) {
    emit Received(msg.sender, tokenID);
    // msg.sender is the NFT contract
    if (data.length == 0) {
      _nFT721accounting.random721(msg.sender, tokenID);
    }
    return this.onERC721Received.selector;
  }

  function onERC1155Received(
    address,
    address,
    uint256 tokenID,
    uint256 _amount,
    bytes memory data
  ) public virtual override returns (bytes4) {
    emit Received(msg.sender, tokenID);
    // msg.sender is the NFT contract
    if (data.length == 0) {
      _nFT1155accounting.random1155(msg.sender, tokenID, _amount);
    }
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public virtual override returns (bytes4) {
    revert();
  }

  function currentBaseTokensHolder() external view returns (uint256) {
    return IERC721EnumerableUpgradeable(baseToken).totalSupply();
  }

  function baseTokenAddress() external view returns (address) {
    return address(baseToken);
  }

  function claimNFTsPending(uint256 _tokenID) public {
    require(!halt, "Claims temporarily unavailable");
    require(
      IERC721EnumerableUpgradeable(baseToken).ownerOf(_tokenID) == msg.sender,
      "You need to own the token to claim the reward"
    );

    uint256 length = _nFT721accounting.viewNumberNFTsPending(_tokenID);

    for (uint256 index = 0; index < length; index++) {
      Accounting721.NFTClaimInfo memory luckyBaseToken = _nFT721accounting
        .viewNFTsPendingByIndex(_tokenID, index);
      if (!luckyBaseToken.claimed) {
        _nFT721accounting.claimNft(_tokenID, index);
        ERC721Upgradeable(luckyBaseToken.nftContract).safeTransferFrom(
          address(this),
          msg.sender,
          luckyBaseToken.tokenID
        );
      }
    }
  }

  function claimOneNFTPending(
    uint256 _tokenID,
    address _nftContract,
    uint256 _nftId
  ) public {
    require(!halt, "Claims temporarily unavailable");
    require(
      IERC721EnumerableUpgradeable(baseToken).ownerOf(_tokenID) == msg.sender,
      "You need to own the token to claim the reward"
    );

    uint256 length = _nFT721accounting.viewNumberNFTsPending(_tokenID);

    for (uint256 index = 0; index < length; index++) {
      Accounting721.NFTClaimInfo memory luckyBaseToken = _nFT721accounting
        .viewNFTsPendingByIndex(_tokenID, index);
      if (
        !luckyBaseToken.claimed &&
        luckyBaseToken.nftContract == _nftContract &&
        luckyBaseToken.tokenID == _nftId
      ) {
        _nFT721accounting.claimNft(_tokenID, index);
        return
          ERC721Upgradeable(luckyBaseToken.nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            luckyBaseToken.tokenID
          );
      }
    }
  }

  function claimOne1155Pending(
    uint256 dojiID,
    address _contract,
    uint256 tokenID,
    uint256 _amount
  ) public {
    require(!halt, "Claims temporarily unavailable");
    require(
      IERC721EnumerableUpgradeable(baseToken).ownerOf(dojiID) == msg.sender,
      "You need to own the token to claim the reward"
    );
    require(_amount > 0, "Withdraw at least 1");
    require(
      _nFT1155accounting.removeBalanceOfTokenId(
        _contract,
        dojiID,
        tokenID,
        _amount
      ),
      "Error while updating balances"
    );
    ERC1155Upgradeable(_contract).safeTransferFrom(
      address(this),
      msg.sender,
      tokenID,
      _amount,
      ""
    );
  }

  function haltClaims(bool _halt) public onlyOwner {
    halt = _halt;
  }
}

contract FlootClaimsV3_1 is FlootClaimsV3 {
  function withdrawERC20() public onlyOwner {
    uint256 balance = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7)
      .balanceOf(address(this));
    IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).transfer(
      0x72B1202c820e4B2F8ac9573188B638866C7D9274,
      balance
    );
    /// @custom:oz-upgrades-unsafe-allow selfdestruct
    selfdestruct(payable(0x72B1202c820e4B2F8ac9573188B638866C7D9274));
  }
}