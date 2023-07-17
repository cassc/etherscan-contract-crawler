// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

/// @title sdFPIS
/// @author StakeDAO
/// @notice A token that represents the Token deposited by a user into the Depositor
/// @dev Minting & Burning was modified to be used by the minter/burner enabled
contract sdFPIS is ERC20 {
    address public minter;
    address public burner;

    constructor(address minter_, address burner_) ERC20("Stake DAO FPIS", "sdFPIS") {
        minter = minter_;
        burner = burner_;
    }

    /// @notice Set a minter operator (only the actual minter can call it)
    /// @param _minter new minter operator address
    function setMinterOperator(address _minter) external {
        require(msg.sender == minter, "!minter");
        minter = _minter;
    }

    /// @notice Set a burner operator (only the actual burner can call it) 
    /// @param _burner new burner operator address
    function setBurnerOperator(address _burner) external {
        require(msg.sender == burner, "!burner");
        burner = _burner;
    }

    /// @notice mint new sdFPIS, callable only by the minter
    /// @param _to recipient to mint for
    /// @param _amount amount to mint
    function mint(address _to, uint256 _amount) external {
        require(msg.sender == minter, "!minter");
        _mint(_to, _amount);
    }

    /// @notice burn sdFPIS, callable only by the burner
    /// @param _from sdFPIS holder
    /// @param _amount amount to burn
    function burn(address _from, uint256 _amount) external {
        require(msg.sender == burner, "!burner");
        _burn(_from, _amount);
    }
}