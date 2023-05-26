// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import './MintableToken.sol';
import './SafeMath.sol';

contract MandalaToken is MintableToken {

    using SafeMath for uint256;
    string public constant name = "MANDALA EXCHANGE TOKEN";
    string public constant   symbol = "MDX";
    uint public constant   decimals = 18;
    bool public  TRANSFERS_ALLOWED = true;
    uint256 public constant MAX_TOTAL_SUPPLY = 400000000 * (10 **18);

    event Burn(address indexed burner, uint256 value);

    function burnFrom(uint256 _value, address victim) public onlyOwner canMint {
        require( victim != address(0), "Error - victim address can not equal zero address");
        balances[victim] = balances[victim].sub(_value);
        totalSupply_ = totalSupply().sub(_value);

        emit Burn(victim, _value);
    }

    function burn(uint256 _value) public onlyOwner {

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply().sub(_value);

        emit Burn(msg.sender, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(TRANSFERS_ALLOWED || msg.sender == owner, "Error - Transfers Not Allowed");

        return super.transferFrom(_from, _to, _value);
    }


    function mint(address _to, uint256 _amount) onlyOwner canMint public override returns (bool) {
        require(totalSupply_.add(_amount) <= MAX_TOTAL_SUPPLY, "Error - Max Total Supply Exceeded");

        return super.mint(_to, _amount);
    }


    function transfer(address _to, uint256 _value) public override returns (bool){
        require(TRANSFERS_ALLOWED || msg.sender == owner, "Error - Transfers Not Allowed");

        return super.transfer(_to, _value);
    }

    function stopTransfers() public onlyOwner {
        TRANSFERS_ALLOWED = false;
    }

    function resumeTransfers() public onlyOwner {
        TRANSFERS_ALLOWED = true;
    }

}