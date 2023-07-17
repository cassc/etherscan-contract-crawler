// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "../interfaces/IFlashLoanReceiver.sol";
import "../interfaces/IBNFT.sol";
import "../interfaces/IBNFTRegistry.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

/**
 * @title Airdrop receiver contract and implement IFlashLoanReceiver interface
 * @author BendDAO
 * @dev implement a flashloan-compatible flashLoanReceiver contract
 **/
contract AirdropFlashLoanReceiverV3 is
  IFlashLoanReceiver,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  ERC721HolderUpgradeable,
  ERC1155HolderUpgradeable
{
  address public bnftRegistry;
  mapping(bytes32 => bool) public airdropClaimRecords;
  uint256 public constant VERSION = 3;

  event ApproveERC20(address indexed token, address indexed spender, uint256 amount);
  event ApproveERC721(address indexed token, address indexed operator, uint256 amount);
  event ApproveERC721ForAll(address indexed token, address indexed operator, bool approved);
  event ApproveERC1155ForAll(address indexed token, address indexed operator, bool approved);

  function initialize(address owner_, address bnftRegistry_) public initializer {
    __ReentrancyGuard_init();
    __Ownable_init();
    __ERC721Holder_init();
    __ERC1155Holder_init();

    require(owner_ != address(0), "zero owner address");
    require(bnftRegistry_ != address(0), "zero registry address");

    bnftRegistry = bnftRegistry_;

    _transferOwnership(owner_);
  }

  struct ExecuteOperationLocalVars {
    uint256[] airdropTokenTypes;
    address[] airdropTokenAddresses;
    uint256[] airdropTokenIds;
    address airdropContract;
    bytes airdropParams;
    uint256 airdropBalance;
    uint256 airdropTokenId;
    bytes32 airdropKeyHash;
    uint256 ethValue;
  }

  /**
   * @dev Implement the flash loan receiver interface of boundNFT
   * @param nftAsset address of original NFT contract
   * @param nftTokenIds id list of original NFT token
   * @param initiator address of original msg sender (caller)
   * @param operator address of bound NFT contract
   * @param params parameters to call third party contract
   */
  function executeOperation(
    address nftAsset,
    uint256[] calldata nftTokenIds,
    address initiator,
    address operator,
    bytes calldata params
  ) external override returns (bool) {
    initiator;

    ExecuteOperationLocalVars memory vars;
    address targetOwner = owner();

    // check caller and owner
    (address bnftProxy, ) = IBNFTRegistry(bnftRegistry).getBNFTAddresses(nftAsset);
    require(bnftProxy == msg.sender, "caller not bnft");

    require(nftTokenIds.length > 0, "empty token list");

    // decode parameters
    (
      vars.airdropTokenTypes,
      vars.airdropTokenAddresses,
      vars.airdropTokenIds,
      vars.airdropContract,
      vars.airdropParams,
      vars.ethValue
    ) = abi.decode(params, (uint256[], address[], uint256[], address, bytes, uint256));

    // airdrop token list can be empty, no need transfer immediately after call method
    // require(vars.airdropTokenTypes.length > 0, "invalid airdrop token type");
    require(vars.airdropTokenAddresses.length == vars.airdropTokenTypes.length, "invalid airdrop token address length");
    require(vars.airdropTokenIds.length == vars.airdropTokenTypes.length, "invalid airdrop token id length");

    require(vars.airdropContract != address(0), "invalid airdrop contract address");
    require(vars.airdropParams.length >= 4, "invalid airdrop parameters");

    // allow operator transfer borrowed nfts back to bnft
    for (uint256 idIdx = 0; idIdx < nftTokenIds.length; idIdx++) {
      IERC721Upgradeable(nftAsset).approve(operator, nftTokenIds[idIdx]);
    }

    // call project aidrop contract
    AddressUpgradeable.functionCallWithValue(
      vars.airdropContract,
      vars.airdropParams,
      vars.ethValue,
      "call airdrop method failed"
    );

    vars.airdropKeyHash = getClaimKeyHash(targetOwner, nftAsset, nftTokenIds, params);
    airdropClaimRecords[vars.airdropKeyHash] = true;

    // transfer airdrop tokens to borrower
    for (uint256 typeIndex = 0; typeIndex < vars.airdropTokenTypes.length; typeIndex++) {
      require(vars.airdropTokenAddresses[typeIndex] != address(0), "invalid airdrop token address");

      if (vars.airdropTokenTypes[typeIndex] == 1) {
        // ERC20
        vars.airdropBalance = IERC20Upgradeable(vars.airdropTokenAddresses[typeIndex]).balanceOf(address(this));
        if (vars.airdropBalance > 0) {
          IERC20Upgradeable(vars.airdropTokenAddresses[typeIndex]).transfer(targetOwner, vars.airdropBalance);
        }
      } else if (vars.airdropTokenTypes[typeIndex] == 2) {
        // ERC721 with Enumerate
        vars.airdropBalance = IERC721Upgradeable(vars.airdropTokenAddresses[typeIndex]).balanceOf(address(this));
        for (uint256 i = 0; i < vars.airdropBalance; i++) {
          vars.airdropTokenId = IERC721EnumerableUpgradeable(vars.airdropTokenAddresses[typeIndex]).tokenOfOwnerByIndex(
            address(this),
            0
          );
          IERC721EnumerableUpgradeable(vars.airdropTokenAddresses[typeIndex]).safeTransferFrom(
            address(this),
            targetOwner,
            vars.airdropTokenId
          );
        }
      } else if (vars.airdropTokenTypes[typeIndex] == 3) {
        // ERC1155
        vars.airdropBalance = IERC1155Upgradeable(vars.airdropTokenAddresses[typeIndex]).balanceOf(
          address(this),
          vars.airdropTokenIds[typeIndex]
        );
        IERC1155Upgradeable(vars.airdropTokenAddresses[typeIndex]).safeTransferFrom(
          address(this),
          targetOwner,
          vars.airdropTokenIds[typeIndex],
          vars.airdropBalance,
          new bytes(0)
        );
      } else if (vars.airdropTokenTypes[typeIndex] == 4) {
        // ERC721 without Enumerate but can know the droped token id
        IERC721EnumerableUpgradeable(vars.airdropTokenAddresses[typeIndex]).safeTransferFrom(
          address(this),
          targetOwner,
          vars.airdropTokenIds[typeIndex]
        );
      } else if (vars.airdropTokenTypes[typeIndex] == 5) {
        // ERC721 without Enumerate and can not know the droped token id
      }
    }

    return true;
  }

  /**
   * @dev call third party contract method, etc. staking, claim...
   * @param targetContract address of target contract
   * @param callParams parameters to call target contract
   */
  function callMethod(
    address targetContract,
    bytes calldata callParams,
    uint256 ethValue
  ) external payable nonReentrant onlyOwner {
    require(targetContract != address(0), "invalid contract address");
    require(callParams.length >= 4, "invalid call parameters");

    require(address(this).balance >= ethValue, "insufficient eth");

    // call project claim contract
    AddressUpgradeable.functionCallWithValue(targetContract, callParams, ethValue, "call method failed");
  }

  function approveERC20(
    address token,
    address spender,
    uint256 amount
  ) external nonReentrant onlyOwner {
    IERC20Upgradeable(token).approve(spender, amount);
    emit ApproveERC20(token, spender, amount);
  }

  /**
   * @dev transfer ERC20 token from contract to owner
   * @param token address of ERC20 token
   * @param amount amount to send
   */
  function transferERC20(address token, uint256 amount) external nonReentrant onlyOwner {
    address to = owner();
    IERC20Upgradeable(token).transfer(to, amount);
  }

  function approveERC721(
    address token,
    address operator,
    uint256 tokenId
  ) external nonReentrant onlyOwner {
    IERC721Upgradeable(token).approve(operator, tokenId);
    emit ApproveERC721(token, operator, tokenId);
  }

  function approveERC721ForAll(
    address token,
    address operator,
    bool approved
  ) external nonReentrant onlyOwner {
    IERC721Upgradeable(token).setApprovalForAll(operator, approved);
    emit ApproveERC721ForAll(token, operator, approved);
  }

  /**
   * @dev transfer ERC721 token from contract to owner
   * @param token address of ERC721 token
   * @param id token item to send
   */
  function transferERC721(address token, uint256 id) external nonReentrant onlyOwner {
    address to = owner();
    IERC721Upgradeable(token).safeTransferFrom(address(this), to, id);
  }

  function approveERC1155ForAll(
    address token,
    address operator,
    bool approved
  ) external nonReentrant onlyOwner {
    IERC1155Upgradeable(token).setApprovalForAll(operator, approved);
    emit ApproveERC1155ForAll(token, operator, approved);
  }

  /**
   * @dev transfer ERC1155 token from contract to owner
   * @param token address of ERC1155 token
   * @param id token item to send
   * @param amount amount to send
   */
  function transferERC1155(
    address token,
    uint256 id,
    uint256 amount
  ) external nonReentrant onlyOwner {
    address to = owner();
    IERC1155Upgradeable(token).safeTransferFrom(address(this), to, id, amount, new bytes(0));
  }

  /**
   * @dev transfer native Ether from contract to owner
   * @param amount amount to send
   */
  function transferEther(uint256 amount) external nonReentrant onlyOwner {
    address to = owner();
    (bool success, ) = to.call{value: amount}(new bytes(0));
    require(success, "ETH_TRANSFER_FAILED");
  }

  /**
   * @dev query claim record
   */
  function getAirdropClaimRecord(
    address initiator,
    address nftAsset,
    uint256[] calldata nftTokenIds,
    bytes calldata params
  ) public view returns (bool) {
    bytes32 airdropKeyHash = getClaimKeyHash(initiator, nftAsset, nftTokenIds, params);
    return airdropClaimRecords[airdropKeyHash];
  }

  /**
   * @dev encode flash claim parameters
   */
  function encodeFlashLoanParams(
    uint256[] calldata airdropTokenTypes,
    address[] calldata airdropTokenAddresses,
    uint256[] calldata airdropTokenIds,
    address airdropContract,
    bytes calldata airdropParams,
    uint256 ethValue
  ) public pure returns (bytes memory) {
    return
      abi.encode(airdropTokenTypes, airdropTokenAddresses, airdropTokenIds, airdropContract, airdropParams, ethValue);
  }

  /**
   * @dev query claim key hash
   */
  function getClaimKeyHash(
    address initiator,
    address nftAsset,
    uint256[] calldata nftTokenIds,
    bytes calldata params
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(initiator, nftAsset, nftTokenIds, params));
  }

  receive() external payable {}
}