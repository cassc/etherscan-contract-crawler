// SPDX-License-Identifier: GNU GPLv3
// @@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@%@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@&@@@@@@@@@
// @@@%/,,,,,,,,,,,,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @/,,,,,,,,,,@,,,,,,/@@@@@,,,,,,,*@@,,,,,,,,,@@@@@*,,,,,,,,,@@@,,,,,,,,,,,,,,,,,,,@@,,,,,,,,,,,,,@@@@
// @@@@@(,,,,,@@%&(,,,,,,,,,,,/,,,,,,@(,,,,,,,@@@*,,,,*@@@,,,@(,,,,(@@,,,*@,,,,,,,/@@@@/,,,,,@@@,,,*@@@
// @@@@@@,,,,,@@@%,,,,,@@,,,,/@@,,,,,@@,,,,,,,@@,,,,,@@@@*,*@,,,,,@@@@,,(@@@,,,,,@@@%@@%,,,,(@/(@*,@@@@
// @@@@@@,,,,,@@@,,,,,@@@,,,,(@@,,,,@@/,,*,,,,@,,,,,@@@@@@%@*,,,,@@@@@@@@@@@,,,,@@@@@@@@,,,,/,,,@@@%%@@
// @@@,,,,,,,,,,,,,(@@@@@,,,,,,,,,/@@(,,(@,,,,,,,,,@@@,,,,,,,,,,(@,,,,,,,,@(,,,/@@,,,,,,,,,,(,,,@@@@@@@
// @@@@@@,,,,*@@(,,,,,,**,,,,,,,,,@@(,,,,,,,,,,,,,,(@@@@,,,,,,,,,@@@@,,,,@@,,,,/@@@,,,,,,,,*@@@@@*,,(@@
// @@@@@(,,,,(@@@@,,,,,,,,,,,@@,,,,,,,,@@@(,,,,,,,,,*@@@,,,,*,,,,,@&@,,,(@(,,,,/@@(,,,(,,,,*@@&@,,,@@@&
// @@@@@*,,,,(@@@%,,,,,,,,,,,@@/,,,,,,@@@@,,,,,,,,,,,,,,,,,*@@,,,,,,,,,,@@,,,,,,**,,*@,,,,,,,,,,,,@@@@@
// @@@@@,,,,,,@@@*,,,,,,,,,,,,,/,,,,,/@@,,,,,,,,,@*,,,,,,,,*@@@@*,,,,*,,,,,,,,,,,,,@@*,,,******,,@@@@@@
// @%/,,,,,,,,,,,,,,,,,,,,/@@@@@@,,,,,(@@@@@@@@@@@@&@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@%@@@@&&&&%@@@@@@@
// @@@@@@@@@(,,,,,,,,,,,,,,,,,,,,*@*,,,,@@@%@@@@@/,,,,/%@@@@@@@@@@@*,,,,,,,,,,,@@@,,,,/@@%@@@@@@@@@@@@@
// @@@%@@@@@%@@@*,,,,,@@@@,,,,,,,,,,,,,,,/@@@%,,,,(@(,,,,@@@@,,,,*/,,,,,,,,,,,/@@/,,,,,,(@@@@@@@@@@@@@@
// @@@@@@@@@@@@@(,,,,,@@@@,,,,,@@@(,,,,*@@@@*,,,,@@@&*,,,,@*,,,,@@@*,,@@,,,,(@@(,,,@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@(,,,,*@@%,,,,,/@@@(,,,,@@%@(,,,,*@@@@@,,,,,,,,,@@@@@@@@@,,,,@*,,@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@(//*,,,,,,,,,,,(@@@&@(,,,,@@,,,,,,,@@%@@(,,,,,,,,,@@@@@&@&@,,,,,,,*@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@,,,,,,/,,,,,,@@@@%,,,,*@@(,,,,,,@@@@&*,,,,,,,,*@@@@%,,,,,,,,@(,,,,,(@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@%%,,,,,@@@%,,,,,,@@@,,,,/@@(,,,,,,@@@@@,,,,,,,,,,@@@@,,,,,,,,*@@@@,,,,,/%@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@,,,,,@@@@(,,,,,,@,,,,,/@*,,,,,,,,@@*,,,,,@,,,,,/@/,,,,,,,,,,*@@@@/,,,,*@&@@@@@@@@@@@@@@
// @@@@@@@@@@@@,,,,,,@@@%,,,,,,,,,,,,,,,,,@@@(,,,,,,,,,@@@@/,,,,,,,,/*,,,,,,,,,@@@@,,,,,,,,,,,@%@@@@@@@
// @@@@@@@@&@*,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@&@@@@@@@@@@&@@&@@@@@@@@@@@@@@@@@@@@@@@(,,,,,,,,@@@&@@@@@@
// @@@@@@@@@,,*@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,*@@@@@@@@@@@
// @@@@@@@@@@%@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@&@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@---{CC0. OWNED BY THE PUBLIC DOMAIN. 100% BRAGGLE}[email protected]@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@%@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@&@@@@@@@@@

pragma solidity ^0.8.5;

import "./ERC721A.sol";
import "./OwnableCreator.sol";

contract Braggle is ERC721A, OwnableCreator {
  uint256 public MAX_SUPPLY = 12345;
  uint256 public MINT_LIMIT = 10;
  uint256 public PRICE = 0.02 ether;

  string public baseURI;

  uint256 public topHodlerBalance;
  uint256 public runnerUpBalance;
  uint256 public ownershipTransferredTimestamp;

  bool public hasNewOwner = false;
  bool public isMintActive = false;

  address public topHodlerAddress;
  address public runnerUpAddress;

  constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}

  function mint(uint256 qty) external payable {
    if (!isMintActive) revert MintNotYetActive();
    if (msg.sender.code.length != 0) revert NoContractMinting();
    if (_nextTokenId() - 1 + qty > MAX_SUPPLY) revert MaxSupplyReached();
    if (qty < 1 || qty > MINT_LIMIT) revert QtyTooSmallOrTooLarge();
    if (msg.value < qty * PRICE) revert NotEnoughEthSend();

    _mint(msg.sender, qty);

    _splitWithTopHodler(qty);

    if (totalSupply() == MAX_SUPPLY) {
      ownershipTransferredTimestamp = block.timestamp;

      _transferOwnership(topHodlerAddress);
    }
  }

  /**
   * @dev New owner should call this function to confirm ownership.
   * If it does not get called the contract might float in BRAGGLE SPACE forever.
   */
  function confirmOwnership() external onlyOwner {
    if (totalSupply() != MAX_SUPPLY) revert ContractNotYetSoldOut();
    if (ownershipTransferredTimestamp == 0) revert ContractNotYetTransferred();

    hasNewOwner = true;
  }

  /**
   * @dev If contract ownership does not get confirmed by the new owner,
   * the BRAGGLE SCIENTISTS have 3 days to rescue the contract and transfer ownership back to the BRAGGLE SCIENTISTS.
   */
  function rescueContract() external onlyCreator {
    if (hasNewOwner) revert ContractHasNewOwner();

    if (ownershipTransferredTimestamp > 0 && ownershipTransferredTimestamp + 3 days < block.timestamp) {
      _transferOwnership(creator());
    }
  }

  function setBaseURI(string calldata baseURI_) external onlyCreator {
    if (hasNewOwner) revert ContractHasNewOwner();

    baseURI = baseURI_;
  }

  function setIsMintActive(bool isMintActive_) external onlyCreator {
    isMintActive = isMintActive_;
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function _startTokenId() internal pure override(ERC721A) returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override(ERC721A) returns (string memory) {
    return baseURI;
  }

  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal override(ERC721A) {
    uint256 balance = balanceOf(to);

    if (topHodlerAddress != address(0) && from == topHodlerAddress) {
      topHodlerBalance = balanceOf(from);
    }

    if (runnerUpAddress != address(0) && from == runnerUpAddress) {
      runnerUpBalance = balanceOf(from);
    }

    if (balance >= topHodlerBalance) {
      topHodlerAddress = to;
      topHodlerBalance = balance;
    } else if (balance >= runnerUpBalance) {
      runnerUpAddress = to;
      runnerUpBalance = balance;
    }

    if (runnerUpBalance >= topHodlerBalance) {
      topHodlerAddress = runnerUpAddress;
      topHodlerBalance = runnerUpBalance;

      runnerUpAddress = topHodlerAddress;
      runnerUpBalance = topHodlerBalance;
    }
  }

  function _splitWithTopHodler(uint256 qty) internal {
    uint256 balance = address(this).balance;
    uint256 amount = qty * PRICE;

    if (balance >= amount) {
      payable(creator()).transfer(amount / 2);
      payable(topHodlerAddress).transfer(amount / 2);
    }
  }

  error MintNotYetActive();
  error NoContractMinting();
  error MaxSupplyReached();
  error QtyTooSmallOrTooLarge();
  error NotEnoughEthSend();
  error ContractHasNewOwner();
  error ContractNotYetSoldOut();
  error ContractNotYetTransferred();
}