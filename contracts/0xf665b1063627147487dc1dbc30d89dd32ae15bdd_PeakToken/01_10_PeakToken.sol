// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./common/BlackList.sol";

contract PeakToken is ERC20Burnable, BlackList, ReentrancyGuard {
  uint256 private constant INITIAL_TOKEN_AMOUNT = 400000000000 * 10**18; // 400 billion tokens with 18 decimals

  mapping(address => bool) public excludedFromPause;
  bool private _paused = false;

  constructor(address _masterTokenVault) ERC20("Peak Token", "PEAK") {
    _mint(_masterTokenVault, INITIAL_TOKEN_AMOUNT); // Mint the initial token supply to the contract deployer
  }

  event Received(address, uint);

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  modifier noBalanceInContract() {
    require(address(this).balance > 0, "No ETH balance in the contract");
    _;
  }

  modifier whenNotPaused() {
    require(!_paused || excludedFromPause[msg.sender], "Token transfers are paused");
    _;
  }

  modifier whenPaused() {
    require(_paused, "Token transfers are not paused");
    _;
  }

  function pause() external onlyOwner whenNotPaused {
    _paused = true;
  }

  function unpause() external onlyOwner whenPaused {
    _paused = false;
  }

  function isPaused() public view returns (bool) {
    return _paused;
  }

  function setPauseExclusion(address _address, bool excluded) external onlyOwner {
    excludedFromPause[_address] = excluded;
  }

  // Allows owner to withdraw any stray ETH from the contract
  function withdraw() external onlyOwner nonReentrant noBalanceInContract {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "ETH Withdraw failed");
  }

  function _beforeTokenTransfer(
    address sender,
    address receiver,
    uint256 amount
  ) internal virtual override whenNotPaused {
    require(!isBlacklisted[sender], "Recipient is backlisted");
    super._beforeTokenTransfer(sender, receiver, amount);
  }
}