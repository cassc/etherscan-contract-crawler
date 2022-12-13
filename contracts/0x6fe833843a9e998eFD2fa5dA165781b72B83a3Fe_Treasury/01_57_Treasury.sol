// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ITreasury.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../project/ICoCreateProject.sol";
import "../token/VestingWallet.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/// @title Treasury
/// @notice This contract allows receiving ETH, ERC20 and ERC721 tokens.
/// Only owner can transfer these tokens
contract Treasury is ITreasury, Ownable, ERC721Holder, ReentrancyGuard, Initializable {
  string public name;
  string public description;
  ICoCreateProject public project;

  constructor() {
    _disableInitializers();
  }

  /**
   * @dev Initialize the Treasury contract with the owner
   * @param _owner The owner of this contract
   */
  function initialize(
    string memory _name,
    string memory _description,
    address _owner,
    ICoCreateProject _project
  ) public initializer {
    require(_owner != address(0), "Cannot transfer to zero address");
    _transferOwnership(_owner);
    name = _name;
    description = _description;
    project = _project;
  }

  receive() external payable {
    emit EthReceived(msg.sender, msg.value);
  }

  /**
   * @dev See {ITreasury-transferETH}
   */
  function transferETH(uint256 amount, address payable to) external override onlyOwner nonReentrant {
    Address.sendValue(to, amount);
    emit EthSent(to, amount);
  }

  /**
   * @dev See {ITreasury-transferERC721}
   */
  function transferERC721(
    address erc721ContractAddr,
    uint256 tokenId,
    address transferTo
  ) external override onlyOwner nonReentrant {
    IERC721(erc721ContractAddr).safeTransferFrom(address(this), transferTo, tokenId);
    emit Erc721Sent(transferTo, erc721ContractAddr, tokenId);
  }

  /**
   * @dev See {ITreasury-transferERC20}
   */
  function transferERC20(
    address erc20ContractAddr,
    uint256 amount,
    address transferTo
  ) external override onlyOwner nonReentrant {
    SafeERC20.safeTransfer(IERC20(erc20ContractAddr), transferTo, amount);
    emit Erc20Sent(transferTo, erc20ContractAddr, amount);
  }

  function transferERC20ToNFTCollectorRewards(
    address erc20ContractAddr,
    INFTCollectorRewards nftCollectorRewards,
    uint256 amount
  ) external override onlyOwner nonReentrant {
    SafeERC20.safeApprove(IERC20(erc20ContractAddr), address(nftCollectorRewards), amount);
    nftCollectorRewards.depositToken(amount);
    emit Erc20Sent(address(nftCollectorRewards), erc20ContractAddr, amount);
  }

  /**
   * @dev See {ITreasury-burnProjectToken}
   */
  function burnProjectToken(ProjectToken projectToken, uint256 amount) external override onlyOwner nonReentrant {
    projectToken.burn(amount);
  }

  /**
   * @dev See {ITreasury-transferERC20BatchWithVesting}
   */
  function transferERC20BatchWithVesting(
    address erc20ContractAddr,
    uint256[] memory amount,
    address[] memory transferTo,
    uint64[] memory vestingStartTimestamps,
    uint64[] memory vestingDurationSeconds
  ) external override onlyOwner nonReentrant {
    ICoCreateLaunch coCreate = project.getCoCreate();
    address vestingWalletImpl = coCreate.getImplementationForType("VestingWallet");
    for (uint256 i = 0; i < amount.length; i++) {
      if (vestingStartTimestamps[i] > 0) {
        address vestingWallet = ClonesUpgradeable.clone(vestingWalletImpl);
        AddressUpgradeable.functionCall(
          vestingWallet,
          abi.encodeWithSelector(
            VestingWallet.initialize.selector,
            string(abi.encodePacked("Wallet ", string(abi.encodePacked(transferTo[i])))),
            "",
            transferTo[i],
            vestingStartTimestamps[i],
            vestingDurationSeconds[i]
          )
        );
        SafeERC20.safeTransfer(IERC20(erc20ContractAddr), vestingWallet, amount[i]);
        emit Erc20Sent(vestingWallet, erc20ContractAddr, amount[i]);
      } else {
        SafeERC20.safeTransfer(IERC20(erc20ContractAddr), transferTo[i], amount[i]);
        emit Erc20Sent(transferTo[i], erc20ContractAddr, amount[i]);
      }
    }
  }

  /**
   * @dev See {ITreasury-transferERC20Allowance}
   */
  function transferERC20Allowance(
    address erc20ContractAddr,
    address fromAddr,
    uint256 amount,
    address transferTo
  ) external override onlyOwner nonReentrant {
    SafeERC20.safeTransferFrom(IERC20(erc20ContractAddr), fromAddr, transferTo, amount);
    emit Erc20Sent(transferTo, erc20ContractAddr, amount);
  }
}