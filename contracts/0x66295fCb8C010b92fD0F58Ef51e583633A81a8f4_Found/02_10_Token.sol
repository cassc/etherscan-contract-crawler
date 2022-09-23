// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Origin.sol";
import "./Treasury.sol";

contract Token is ERC20, Origin, Treasury {
    uint private _valueClaim;
    uint private _tokenClaim;
    uint private _totalValue;

    event ClaimValue(address indexed to, uint value, string memo);
    event ClaimToken(address indexed to, uint token, string memo);

    function tokenBalance() public view returns (uint) {
        return balanceOf(address(this));
    }

    function pushToken(address to,  uint amount) external onlyTreasurer {
        _transfer(address(this), to, amount);
    }

    function pullToken(address from, uint amount) external onlyTreasurer {
        _transfer(from, address(this), amount);
    }

    function treasuryMint(address to, uint amount) external onlyTreasurer {
        _mintToken(to, amount);
    }

    function _mintToken(address to, uint amount) internal {
        _mint(to, amount); 
        _mint(address(this), amount);
    }

    function _addValue(uint value) internal {
        _totalValue += value;
    }

    function totalValue() external view returns (uint) {
        return _totalValue;
    }

    function claimedValue() external view returns (uint) {
        return _valueClaim;
    }

    function claimedToken() external view returns (uint) {
        return _tokenClaim;
    }

    function claimValue(address to, uint value, string memory memo) external onlyOrigin {
        require(
            valueBalance() >= value, 
            "Value claim too large"
        );

        require(
            _totalValue / 10 >= value + _valueClaim, 
            "Value claim too large"
        );
        
        _valueClaim += value;
        _pushValue(to, value);
        emit ClaimValue(to, value, memo);
    }

    function claimToken(address to, uint token, string memory memo) external onlyOrigin {
        require(
            tokenBalance() >= token, 
            "Token claim too large"
        );

        require(
            totalSupply() / 20 >= token + _tokenClaim, 
            "Token claim too large"
        );
        
        _tokenClaim += token;
        _transfer(address(this), to, token);
        emit ClaimToken(to, token, memo);
    }

    constructor(string memory name_, 
                string memory symbol_, 
                address origin_) 
    ERC20(name_, symbol_) 
    Origin(origin_) {}
}