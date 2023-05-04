// SPDX-License-Identifier: MIT
/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity 0.7.6;


import "./ERC20.sol";
import "./SafeMathLibExt.sol";


/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {

    using SafeMathLibExt for uint256;

    /* Token supply got increased and a new owner received these tokens */
    event Minted(address receiver, uint256 amount);

    /* Actual balances of token holders */
    mapping(address => uint256) public balances;

    /* approve() allowances */
    mapping (address => mapping (address => uint256)) public allowed;

    /* Interface declaration */
    function isToken() public pure returns (bool weAre) {
        return true;
    }

    function transfer(address _to, uint256 _value) public virtual override returns (bool success) {
        balances[msg.sender] = balances[msg.sender].minus(_value);
        balances[_to] = balances[_to].plus(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool success) {
        uint256 _allowance = allowed[_from][msg.sender];

        balances[_to] = balances[_to].plus(_value);
        balances[_from] = balances[_from].minus(_value);
        allowed[_from][msg.sender] = _allowance.minus(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view virtual override returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public  virtual override returns (bool success) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        // if ((_addedValue != 0) && (allowed[msg.sender][_spender] != 0)) revert();
        if(_value == 0 ) revert("Cannot approve 0 value");
        if(_spender == address(0)) revert("Cannot approve for Null aDDRESS");
        if(allowed[msg.sender][_spender] == 0 ) revert("Spender already approved,instead increase/decrease allowance");

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
        if(_addedValue == 0 ) revert("Cannot add 0 allowance value");
        if(_spender == address(0)) revert("Cannot allow for Null address");

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].plus(allowed[msg.sender][_spender]);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender].plus(allowed[msg.sender][_spender]));
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
        if(_subtractedValue == 0 ) revert("Cannot add 0 decrease value");
        if(_spender == address(0)) revert("Cannot allow for Null address");
        require(_subtractedValue <= allowed[msg.sender][_spender], "Cannot remove more than allowance!");
        
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].minus(allowed[msg.sender][_spender]);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender].minus(allowed[msg.sender][_spender]));
        return true;
    }

    function allowance(address _owner, address _spender) public view virtual override returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}