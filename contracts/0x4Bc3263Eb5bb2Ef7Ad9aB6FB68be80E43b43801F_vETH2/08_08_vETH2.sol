// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import {ERC20Pausable, ERC20, Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// solhint-disable-next-line contract-name-camelcase
contract vETH2 is ERC20Pausable, Ownable {
    /* ========== STATE VARIABLES ========== */

    address public slpCore;

    /* ========== EVENTS ========== */
    event SLPCoreSet(address indexed sender, address slpCore);

    // solhint-disable-next-line no-empty-blocks
    constructor() ERC20("Voucher Ethereum 2.0", "vETH") Pausable() Ownable() {}

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint(address account, uint amount) external onlySLPCore {
        super._mint(account, amount);
    }

    function burn(address account, uint amount) external onlySLPCore {
        super._burn(account, amount);
    }

    function pause() external onlyOwner {
        super._pause();
    }

    function unpause() external onlyOwner {
        super._unpause();
    }

    function setSLPCore(address _slpCore) external onlyOwner {
        require(_slpCore != address(0), "Invalid SLP core address");
        slpCore = _slpCore;
        emit SLPCoreSet(msg.sender, _slpCore);
    }

    /* ========== MODIFIER ========== */

    modifier onlySLPCore() {
        require(msg.sender == slpCore, "Invalid SLP core address");
        _;
    }
}