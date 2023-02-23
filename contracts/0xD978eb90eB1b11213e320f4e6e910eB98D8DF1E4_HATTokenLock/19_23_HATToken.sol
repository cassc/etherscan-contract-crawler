// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IHATToken.sol";

contract HATToken is IHATToken, ERC20Votes, ERC20Capped, Ownable {

    /// @notice Address which may mint new tokens
    /// minter -> minting seedAmount
    mapping (address => uint256) public minters;

    /// @notice Whether the token is transferable or not
    /// @dev Set to false on deployment, and can only be set to true by the owner and cannot be set back to false
    bool public transferable;

    /**
     * @notice Construct a new HAT token
     * @param _governance The owner of the token
     */
    constructor(address _governance) 
        ERC20("hats.finance", "HAT") 
        ERC20Capped(100000000e18) 
        ERC20Permit("hats.finance")
    {
        _transferOwnership(_governance);
    }

    function setMinter(address _minter, uint256 _seedAmount) external onlyOwner {
        minters[_minter] = _seedAmount;
        emit MinterSet(_minter, _seedAmount);
    }

    function setTransferable() external onlyOwner {
        transferable = true;
        emit TransferableSet();
    }

    function burn(uint256 _amount) external {
        if (_amount == 0) revert ZeroAmount();
        _burn(msg.sender, _amount);
    }

    function mint(address _account, uint256 _amount) external {
        if (_amount == 0) revert ZeroAmount();
        minters[msg.sender] -= _amount;
        _mint(_account, _amount);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (!transferable) revert TransfersDisabled();
        super._transfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    function _mint(address account, uint256 amount) internal override(ERC20Votes, ERC20Capped) {
        super._mint(account, amount);
    }

}