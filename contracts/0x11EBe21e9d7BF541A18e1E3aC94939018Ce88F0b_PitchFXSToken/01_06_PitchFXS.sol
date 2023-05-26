// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

// ==========================================
// |            ____  _ __       __         |
// |           / __ \(_) /______/ /_        |
// |          / /_/ / / __/ ___/ __ \       |
// |         / ____/ / /_/ /__/ / / /       |
// |        /_/   /_/\__/\___/_/ /_/        |
// |                                        |
// ==========================================
// ================= Pitch ==================
// ==========================================

// Authored by Pitch Research: [email protected]

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PitchFXSToken is ERC20, Ownable {

  address public depositor;

  constructor() ERC20("Pitch FXS", "pitchFXS") {}

  modifier onlyDepositor() {
    require(msg.sender == depositor, "pitchFXS : Depositor-only access!");
    _;
  }

  function setDepositor(address _depositor) external onlyOwner {
    depositor = _depositor;
  }

  /**
   * @notice Mints new pitchFXS token to address.
   * @param _to Address to send newly minted pitchFXS.
   * @param _amount Amount of pitchFXS to mint.
   */
  function mint(address _to, uint256 _amount) external onlyDepositor {
    _mint(_to, _amount);
  }

  /**
   * @notice Burns new pitchFXS token from address.
   * @param _from Address from which to burn pitchFXS.
   * @param _amount Amount of pitchFXS to burn.
   */
  function burn(address _from, uint256 _amount) external onlyDepositor {
    _burn(_from, _amount);
  }
}