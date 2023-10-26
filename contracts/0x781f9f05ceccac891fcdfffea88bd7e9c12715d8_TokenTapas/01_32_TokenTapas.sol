// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17;

import { console2 } from "forge-std/console2.sol";
import { ERC20Votes } from "@openzeppelin/token/ERC20/extensions/ERC20Votes.sol";
import { IVotes } from "@openzeppelin/governance/utils/IVotes.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { IERC721 } from "@openzeppelin/token/ERC721/IERC721.sol";
import { EIP712 } from "@openzeppelin/utils/cryptography/EIP712.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { ERC165 } from "@openzeppelin/utils/introspection/ERC165.sol";

import { IERC20Votes } from "./interfaces/IERC20Votes.sol";
import { IMiniMeToken } from "./interfaces/IMiniMeToken.sol";

interface ICompCheckpointable {
  function balanceOf(address account) external view returns (uint256);

  function getCurrentVotes(address account) external view returns (uint256);

  function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
}

contract TokenTapas is ERC20Votes, Ownable, ERC165 {
  enum TokenType {
    Votes,
    MiniMe,
    CompCheckpointable
  }

  struct TokenData {
    address token;
    TokenType tokenType;
    uint256 weight;
  }
  uint256 public avgBlockTime = 12; // Average block time in seconds
  uint256 public referenceBlockNumber = 18200268; // Average block time in seconds
  uint256 public referenceTimestamp = 1695489712; // Average block time in seconds
  TokenData[] public tokens;

  constructor(
    TokenData[] memory _tokens,
    string memory name_,
    string memory symbol_,
    string memory version_,
    address initialOwner_
  ) ERC20(name_, symbol_) EIP712(name_, version_) Ownable(initialOwner_) {
    for (uint256 i = 0; i < _tokens.length; i++) {
      tokens.push(_tokens[i]);
    }
  }

  function totalSupply() public view override returns (uint256 _totalSupply) {
    for (uint256 i = 0; i < tokens.length; i++) {
      _totalSupply += ERC20Votes(tokens[i].token).totalSupply() * tokens[i].weight;
    }
  }

  function delegate(address account, address newDelegation) public {}

  /**
   * @dev Returns the current amount of votes that `account` has.
   */
  function getVotes(address account) public view override returns (uint256 votes) {
    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i].tokenType == TokenType.Votes) {
        votes += IVotes(tokens[i].token).getVotes(account) * tokens[i].weight;
      } else if (tokens[i].tokenType == TokenType.MiniMe) {
        votes += IMiniMeToken(tokens[i].token).balanceOf(account) * tokens[i].weight;
      } else {
        votes += ICompCheckpointable(tokens[i].token).getCurrentVotes(account) * tokens[i].weight;
      }
    }
  }

  /**
   * @dev Returns the amount of votes that `account` had at a specific moment in the past. If the `clock()` is
   * configured to use block numbers, this will return the value at the end of the corresponding block.
   */
  function getPastVotes(address account, uint256 timepoint) public view override returns (uint256 pastVotes) {
    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i].tokenType == TokenType.Votes) {
        pastVotes += IVotes(tokens[i].token).getPastVotes(account, timepoint) * tokens[i].weight;
      } else if (tokens[i].tokenType == TokenType.MiniMe) {
        pastVotes += IMiniMeToken(tokens[i].token).balanceOfAt(account, timepoint) * tokens[i].weight;
      } else {
        pastVotes +=
          ICompCheckpointable(tokens[i].token).getPriorVotes(account, estimateBlockNumber(timepoint)) *
          tokens[i].weight;
      }
    }
  }

  function balanceOf(address account) public view override returns (uint256 balance) {
    for (uint256 i = 0; i < tokens.length; i++) {
      balance += IMiniMeToken(tokens[i].token).balanceOf(account) * tokens[i].weight;
    }
  }

  function setTokens(TokenData[] memory _tokens) external onlyOwner {
    while (tokens.length > _tokens.length) {
      tokens.pop();
    }

    for (uint256 i = 0; i < _tokens.length; i++) {
      if (tokens.length < i) {
        tokens.push(_tokens[i]);
      } else {
        tokens[i] = _tokens[i];
      }
    }
  }

  /// @notice Checks if this or the parent contract supports an interface by its ID.
  /// @param _interfaceId The ID of the interface.
  /// @return Returns `true` if the interface is supported.
  function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
    return
      _interfaceId == type(IERC20).interfaceId ||
      _interfaceId == type(IERC721).interfaceId ||
      _interfaceId == type(IVotes).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  function estimateBlockNumber(uint256 targetTimestamp) public view returns (uint256) {
    uint256 blockNumber = referenceBlockNumber + ((targetTimestamp - referenceTimestamp) / avgBlockTime);
    console2.log("Block Number: ");
    console2.log(blockNumber);
    return blockNumber;
  }
}