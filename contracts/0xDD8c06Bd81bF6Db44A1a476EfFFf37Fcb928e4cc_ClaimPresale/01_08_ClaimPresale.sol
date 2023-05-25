//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ClaimPresale is Ownable, Pausable, ReentrancyGuard {
  using SafeERC20 for IERC20;
 
  address public DEV;
  IERC20 public HORNY = IERC20(0x3d939F3aAB9aF971a9eDA1bC63A768D0DF386f66);
  address presaleAddress = address(0x00C2EdA97D336241b2aA13E3a35CC2E87cca1242);

  uint256 public startClaimTime = 1684252800;

  // Mapping addresses claims amount.
  mapping(address => uint256) public TokenClaimed;

  uint8[11] claimPercentages = [50,5,5,5,5,5,5,5,5,5,5];
  uint32[11] claimTimestamps = [1684252800, 1684339200, 1684425600, 1684512000, 1684598400, 1684684800, 1684771200, 1684857600, 1684944000, 1685030400, 1685116800];

  constructor() {
    DEV = msg.sender;
  }
  
  function claimToken() public nonReentrant {
    require(block.timestamp > startClaimTime, "Claim Not Started");

    address beneficiary = _msgSender();
    uint256 tokenAmount = getPresaleTokenBought(beneficiary) / 10;

    require(tokenAmount > 0, "Not participated in presale");
    uint256 tokens = 0;

    for (uint8 i=0; i<11; i++) {
      if (block.timestamp >= claimTimestamps[i]) tokens += claimPercentages[i] * tokenAmount / 100;
    }

    uint256 eligibleToClaim = tokens - TokenClaimed[beneficiary];

    require(eligibleToClaim > 0, "No tokens to claim");

    TokenClaimed[beneficiary] += eligibleToClaim;
    // Transfer the tokens to the beneficiary
    HORNY.safeTransfer(beneficiary, eligibleToClaim);
  }

  function getAvailableAmount(address _participantAddress) public view returns (uint256) {
    uint256 tokenAmount = getPresaleTokenBought(_participantAddress) / 10;
    uint256 tokens = 0;

    for (uint8 i=0; i<11; i++) {
      if (block.timestamp >= claimTimestamps[i]) tokens += claimPercentages[i] * tokenAmount / 100;
    }

    uint256 eligibleToClaim = tokens - TokenClaimed[_participantAddress];
    return eligibleToClaim;
  }

  function getPresaleTokenBought(address _key) internal view returns (uint256) {
    (bool success, bytes memory data) = presaleAddress.staticcall(
        abi.encodeWithSignature("TokenBought(address)", _key)
    );

    require(success, "Call to getPresaleTokenBought failed");

    uint256 value = abi.decode(data, (uint256));
    return value;
  }

  /// @dev in case of emergency
  function withdrawHORNY() external onlyOwner {
    require(HORNY.balanceOf(address(this)) > 0, "Contract has no HORNY");
    HORNY.transfer(owner(), HORNY.balanceOf(address(this)));
  }

  /// @dev in case of emergency
  function withdrawETH() external onlyOwner {
    require(address(this).balance > 0, "Contract has no ETH");
    payable(DEV).transfer(address(this).balance);
  }

  /// @dev token balance
  function tokensAvailable() public view returns (uint256) {
    return HORNY.balanceOf(address(this));
  }
}