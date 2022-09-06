/// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "../external/SolmateERC20.sol";

contract EaseToken is SolmateERC20 {
    /// @notice Address of easeDAO
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner!");
        _;
    }

    constructor(address _owner) SolmateERC20("Ease Token", "EASE", 18) {
        _mint(msg.sender, 750_000_000e18);
        owner = _owner;
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }

    /// @notice Allows easeDAO to remint the burned token if the vote passes
    /// in favour of reminting them.
    function mint() external onlyOwner {
        _mint(owner, 250_000_000e18);
        _renounceOwnership();
    }

    /// @notice Allows easeDAO to renounce ownership if vote fails
    function renounceOwnership() external onlyOwner {
        _renounceOwnership();
    }

    function _renounceOwnership() internal {
        owner = address(0);
    }
}