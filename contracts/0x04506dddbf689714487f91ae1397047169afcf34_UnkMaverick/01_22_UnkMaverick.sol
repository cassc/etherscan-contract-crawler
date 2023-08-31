// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Address} from "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {OFT} from "lib/solidity-examples/contracts/token/oft/OFT.sol";



/**
 * @title   unkMaverick Token
 * @author  Unlock
 * @notice  OFT Token that allows the operator (mavDepositor) to mint and burn tokens
 */
contract UnkMaverick is OFT {
    using SafeERC20 for IERC20;
    using Address for address;


    address public operator;

    /// @notice Throws if not operator.
    error NO_OPERATOR();

    modifier onlyOperator(){
        if (msg.sender != operator) revert NO_OPERATOR();
        _;
    }
    

    constructor(string memory _nameArg, string memory _symbolArg, address _layerZeroEndpoint) OFT(_nameArg, _symbolArg, _layerZeroEndpoint)
    {
        operator = msg.sender;
    }
    /**
     * @notice Allows the initial operator (deployer) to set the operator.
     *         Note - mavDepositor has no way to change this back, so it's effectively immutable
     */
    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    /**
     * @notice Allows the mavDepositor to mint
     */
    function mint(address _to, uint256 _amount) external onlyOperator {
        
        _mint(_to, _amount);
    }

    /**
     * @notice Allows the mavDepositor to burn
     */
    function burn(address _from, uint256 _amount) external onlyOperator {        
        _burn(_from, _amount);
    }

}