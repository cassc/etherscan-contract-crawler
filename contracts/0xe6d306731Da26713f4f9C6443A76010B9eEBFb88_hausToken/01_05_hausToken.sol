/* SPDX-License-Identifier: MIT

// hausToken Contract
// Dev: @redsh4de
// Post deployment instructions:
// 1. Add staking contract as approved minter
// 2. Add conversion contact as approved minter
// 3. Unpause contract
*/

pragma solidity 0.8.17;

import { ERC20 } from "./lib/solmate/tokens/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

contract hausToken is ERC20, Ownable, Pausable {
    constructor(uint _amount) ERC20("hausToken", "HT", 18) {
        _mint(msg.sender, _amount * 1e18);
        _pause();
    }

    /////////////////////////////////////////////////////////
    /// Global variables
    /////////////////////////////////////////////////////////
    mapping (address => bool) isMinter;

    /////////////////////////////////////////////////////////
    /// Modifiers
    /////////////////////////////////////////////////////////
    modifier onlyMinters {
        require(isMinter[msg.sender], "Not a minter");
        _;
    }

    /////////////////////////////////////////////////////////
    /// Global functions
    /////////////////////////////////////////////////////////
    function mint(address _to, uint _amount) public onlyMinters whenNotPaused {
        _mint(_to, _amount);
    }

    function burn(uint _amount) public {
        _burn(msg.sender, _amount);
    }

    /////////////////////////////////////////////////////////
    /// SET Functions
    /////////////////////////////////////////////////////////
    function setMinters(address _minter, bool _status) external onlyOwner {
        isMinter[_minter] = _status;
    }

    /// @notice     Pause/unpause the contract
    /// @param _state           True/false
    function pause(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }
    
    /////////////////////////////////////////////////////////
    /// GET Functions
    /////////////////////////////////////////////////////////
}