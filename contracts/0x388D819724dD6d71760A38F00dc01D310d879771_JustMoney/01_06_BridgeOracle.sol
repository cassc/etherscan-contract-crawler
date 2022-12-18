// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface HandlerOracle {
    function approveHandlerChange() external returns (bool);
    function approveManualMint() external returns (bool);
    function isTokenContract(address tokenContract) external view returns (bool);
    function isAllowedToChangeOracle(address tokenContract) external view returns (bool);
}

import "./Ownable.sol";

abstract contract BridgeOracle is Ownable {
    HandlerOracle internal _handlerOracle;
    address private _bridgeHandler;

    event BridgeHandlerSet(address indexed added);

    /**
     * @dev Returns true if the address is a bridge handler.
     */
    function isBridgeHandler(address account) public view returns (bool) {
        return _bridgeHandler == account;
    }

    /**
     * @dev Throws if called by any account other than the oracle or a bridge handler.
     */
    modifier onlyOracleAndBridge() {
        require(_msgSender() != address(0), Errors.NOT_ZERO_ADDRESS_SENDER);
        require(isBridgeHandler(_msgSender()) || address(_handlerOracle) == _msgSender(), Errors.NOT_ORACLE_OR_HANDLER);
        _;
    }
    
    modifier onlyHandlerOracle() {
        require(_msgSender() != address(0), Errors.ORACLE_NOT_SET);
        require(_msgSender() == address(_handlerOracle), Errors.IS_NOT_ORACLE);
        _;
    }

    function approveOracleToSetHandler() public onlyOwner returns (bool) {
        require(address(_handlerOracle) != address(0), Errors.SET_HANDLER_ORACLE_FIRST);
        require(_handlerOracle.isTokenContract(address(this)) == true, Errors.TOKEN_NOT_ALLOWED_IN_BRIDGE);

        return _handlerOracle.approveHandlerChange();
    }
    
    function approveOracleToManualMint() public onlyOwner returns (bool) {
        require(address(_handlerOracle) != address(0), Errors.SET_HANDLER_ORACLE_FIRST);
        require(_handlerOracle.isTokenContract(address(this)) == true, Errors.TOKEN_NOT_ALLOWED_IN_BRIDGE);

        return _handlerOracle.approveManualMint();
    }

    /**
     * @dev Add handler address (`account`) that can mint and burn.
     * Can only be called by the 'Handler Oracle Contract' after it was approved.
     */
    function setBridgeHandler(address account) public onlyHandlerOracle {
        require(account != address(0), Errors.OWNABLE_NOT_ZERO_ADDRESS);
        require(!isBridgeHandler(account), Errors.ADDRESS_IS_HANDLER);

        emit BridgeHandlerSet(account);
        _bridgeHandler = account;
    }

    function setHandlerOracle(address newHandlerOracle) public onlyOwner {
        require(HandlerOracle(newHandlerOracle).isTokenContract(address(this)) == true, Errors.TOKEN_NOT_ALLOWED_IN_BRIDGE);

        if ( address(_handlerOracle) == address(0) ) {
            _handlerOracle = HandlerOracle(newHandlerOracle);
        } else {
            require(_handlerOracle.isAllowedToChangeOracle(address(this)) == true, Errors.NOT_ALLOWED_TO_EDIT_ORACLE);

            _handlerOracle = HandlerOracle(newHandlerOracle);
        }
    }
}
