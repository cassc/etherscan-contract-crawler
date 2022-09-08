// SPDX-License-Identifier: MIT
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

import "@openzeppelin-contracts/contracts/access/Ownable.sol";
import "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract PitchSDLToken is ERC20, Ownable {
    error NotDepositor();

    address public depositor;

    constructor() ERC20("Pitch SDL", "pitchSDL") {}

    modifier onlyDepositor() {
        if (msg.sender != depositor) revert NotDepositor();
        _;
    }

    function setDepositor(address _depositor) external onlyOwner {
        depositor = _depositor;
    }

    /**
     * @notice Mints new pitchSDL token to address.
     * @param _to Address to send newly minted pitchSDL.
     * @param _amount Amount of pitchSDL to mint.
     */
    function mint(address _to, uint256 _amount) external onlyDepositor {
        _mint(_to, _amount);
    }

    /**
     * @notice Burns new pitchSDL token from address.
     * @param _from Address from which to burn pitchSDL.
     * @param _amount Amount of pitchSDL to burn.
     */
    function burn(address _from, uint256 _amount) external onlyDepositor {
        _burn(_from, _amount);
    }
}