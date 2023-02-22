//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error ZeroAddressError();

abstract contract ExtraordinalsAdministration {
    address public operator;
	mapping(address => bool) private _moderators;
	
    event OperatorSet(address indexed operator);
	event ModeratorSet(address indexed moderator, bool status);

	error AuthorizationError();

    constructor(address _operator) {
		if(_operator == address(0)) revert ZeroAddressError();
        operator = _operator;
    }

    // =============================================================
    //                    MODIFIERS
    // =============================================================
    modifier onlyOperator {
        if( isOperator( msg.sender ) ){
			_;
		}else{
			revert AuthorizationError();
		} 
    }
    modifier onlyModerator{
        if( isOperator( msg.sender ) || isModerator( msg.sender ) ){
			_;
		}else{
			revert AuthorizationError();
		} 
    }
	
    // =============================================================
    //                    GETTERS
    // =============================================================
	function isOperator(address account) public view returns (bool) {
		return account == operator;
	}	
	function isModerator(address account) public view returns (bool) {
		return ( _moderators[account] == true );
	}
	
    // =============================================================
    //                    SETTERS
    // =============================================================
    function setOperator(address account) external onlyOperator {
        if(account == address(0)) revert ZeroAddressError();
		operator = account;
        emit OperatorSet(account);
    }
    function setModerator(address account, bool _status) external onlyOperator{
        if(account == address(0)) revert ZeroAddressError();
		_moderators[account] = _status;
        emit ModeratorSet(account, _status);        
    }
}