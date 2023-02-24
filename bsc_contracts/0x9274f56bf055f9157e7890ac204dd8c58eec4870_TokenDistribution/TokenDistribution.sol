/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.24;


library ERC20AsmFn {

    function isContract(address addr) internal view {
        assembly {
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    function handleReturnData() internal pure returns (bool result) {
        assembly {
            switch returndatasize()
            case 0 { // not a std erc20
                result := 1
            }
            case 32 { // std erc20
                returndatacopy(0, 0, 32)
                result := mload(0)
            }
            default { // anything else, should revert for safety
                revert(0, 0)
            }
        }
    }

    function asmTransfer(address _erc20Addr, address _to, uint256 _value) internal returns (bool result) {

        // Must be a contract addr first!
        isContract(_erc20Addr);

        // call return false when something wrong
        require(_erc20Addr.call(bytes4(keccak256("transfer(address,uint256)")), _to, _value));

        // handle returndata
        return handleReturnData();
    }

    function asmTransferFrom(address _erc20Addr, address _from, address _to, uint256 _value) internal returns (bool result) {

        // Must be a contract addr first!
        isContract(_erc20Addr);

        // call return false when something wrong
        require(_erc20Addr.call(bytes4(keccak256("transferFrom(address,address,uint256)")), _from, _to, _value));

        // handle returndata
        return handleReturnData();
    }

    function asmApprove(address _erc20Addr, address _spender, uint256 _value) internal returns (bool result) {

        // Must be a contract addr first!
        isContract(_erc20Addr);

        // call return false when something wrong
        require(_erc20Addr.call(bytes4(keccak256("approve(address,uint256)")), _spender, _value));

        // handle returndata
        return handleReturnData();
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}



interface ERC20 {
     function balanceOf(address who) external view returns (uint256);
     function transfer(address _to, uint256 _value) external returns (bool success);
     function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
     function approve(address _spender, uint256 _value) external returns (bool success);
}


contract Ownable {
    address public owner;
 
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}



/**
 * @title TokenDistribution
 * @dev Distribute tokens
 */
contract TokenDistribution is Ownable {
    using SafeMath for uint256;
    using ERC20AsmFn for ERC20;

    function() public payable {}


    /*  !!! Must approve token first !!!  */
    function multisendToken(address token, address[] _contributors, uint256[] _balances) public payable {
        uint256 total = 0;
        require(_contributors.length <= 200);
        ERC20 erc20token = ERC20(token);
        uint8 i = 0;
        for (i; i < _contributors.length; i++) {
            require(erc20token.asmTransferFrom(msg.sender,_contributors[i],_balances[i]));
            total += _balances[i];
        }
    }

    
    function multisendEther(address[] _contributors, uint256[] _balances) public payable {
        uint256 total = msg.value;
        require(_contributors.length <= 200);
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i]);
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
    }
}