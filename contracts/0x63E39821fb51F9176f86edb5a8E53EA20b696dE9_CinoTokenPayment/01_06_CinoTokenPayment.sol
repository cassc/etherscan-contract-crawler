// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract CinoTokenPayment is AccessControl {
    using SafeMath for uint256;

    string public name = "Cino Token Payment";
    address public owner;

    uint256 public decimals = 10 ** 18;
    uint256 public shares = 12;



    // list of addresses for owners and marketing wallet
    address[] private owners = [0xe10E9a58B3139Fe0EE67EbF18C27D0C41aE0668C, 0xC47644c4E388F3E714fa29C537395ed878F418fA, 0xdA3DFBb438340516AeC7E55e87Ea92b00e5290B9];

    // mapping will allow us to create a relationship of investor to their current remaining balance
    mapping( address => uint256 ) public _currentBalance;
    mapping( address => uint256 ) public _shareReference;

    event EtherReceived(address from, uint256 amount);

    bytes32 public constant OWNERS = keccak256("OWNERS");



    
    
    constructor () public {
        owner = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNERS, owners[0]);
        _setupRole(OWNERS, owners[1]);
        _setupRole(OWNERS, owners[2]);

       
        _shareReference[owners[0]] = 4;
        _shareReference[owners[1]] = 4;
        _shareReference[owners[2]] = 4;

       
    }



    receive() external payable {


        uint256 ethSent = msg.value;

        uint256 ethShare = ethSent / shares;
        
        for(uint256 i=0; i < owners.length; i++){
            _currentBalance[owners[i]] += ethShare * _shareReference[owners[i]];
        }

        emit EtherReceived(msg.sender, msg.value);

    }

    


    function withdrawBalanceOwner() public {

        if(_currentBalance[msg.sender] > 0){

            uint256 amountToPay = _currentBalance[msg.sender];
            address payable withdrawee;
            if(hasRole(OWNERS, msg.sender)){

                _currentBalance[msg.sender] = _currentBalance[msg.sender].sub(amountToPay);
                withdrawee = payable(msg.sender);

                withdrawee.transfer(amountToPay);
            }
        }


    }

    function changeShares(address addyToAlter, uint256 newShares) public {
        if(hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
            shares = shares - _shareReference[addyToAlter];
            _shareReference[addyToAlter] = newShares;
            shares = shares + newShares;
        }

    }
    

}