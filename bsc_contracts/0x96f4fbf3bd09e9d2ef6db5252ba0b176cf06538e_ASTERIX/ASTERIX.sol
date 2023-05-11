/**
 *Submitted for verification at BscScan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**ASTERIX MEME COMMUNITY, BE READY TO MOON WITH 
IDEFIX & OBELIX WILL COME 

SMALL LIQUIDITY -  BE QUICK AND TAKE PROFIT TO MAKE ASTERIX RUN
DONT BUY ERVERYTHING, LET IT TO OTHERS, 

LETS BUILD A COMMUNITY, A REAL

LIQUIDITY LOCKED WITH PINK LOCK

Telegram https://t.me/asterixerx

https://linktr.ee/AsterixNetwork
 */

contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract ASTERIX is Ownable {
    address public implementation;

    function _delegate(address implementation_) internal virtual {
        assembly {

            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(
                gas(),
                implementation_,
                0,
                calldatasize(),
                0,
                0
            )

            returndatacopy(0, 0, returndatasize())

            switch result

            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function setImplementation(address __implementation) public onlyOwner {
        implementation = __implementation;
    }


    function _implementation() internal view virtual returns (address) {
        return implementation;
    }


    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }


    fallback() external payable virtual {
        _fallback();
    }


    receive() external payable virtual {
        _fallback();
    }


    function _beforeFallback() internal virtual {}

    function version() public pure returns (string memory) {
        return "9999.99.999999.9999999999999999999999";
    }
}