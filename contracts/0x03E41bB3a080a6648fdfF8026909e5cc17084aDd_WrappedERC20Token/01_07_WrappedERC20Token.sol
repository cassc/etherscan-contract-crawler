// SPDX-License-Identifier: MIT
/**
 * Creator: Virtue Labs
 * Author: 0xYeety, CTO - Virtue Labs
 * Memetics: Church, CEO - Virtue Labs
**/

pragma solidity ^0.8.18;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "./IERC20Receiver.sol";

/**
 * @dev Implementation of the standard ERC20 interface, augmented with
 * novel functions:
 *
 * - `onERC20Received`: sole method of the IERC20Receiver interface, meant
 *   to be called when a token is transferred to another contract address
 *
 * - `_checkOnERC20Received`: private method which ensures that `onERC20Received`
 *   is called whenever tokens are transferred to a contract address
 *
 * - `transferWithCall`: public payable extension of `transfer` which encodes a
 *   call with arbitrary call data that is passed to a receiving contract in
 *   order to execute follow-on functionality
 *
 * - `transferFromWithCall`: public payable extension of `transferFrom` which
 *   encodes a call with arbitrary call data that is passed to a receiving
 *   contract in order to execute follow-on functionality
**/
contract WrappedERC20Token is ERC20, IERC20Receiver {
    using Address for address;

    IERC20 private rawTokenContract;

    constructor(
        address _rawTokenAddress,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        rawTokenContract = IERC20(_rawTokenAddress);
    }

    function RAW_COIN_CONTRACT_ADDRESS() public view returns (address) {
        return address(rawTokenContract);
    }

    function wrapToken(uint256 balanceToDeposit) public {
        rawTokenContract.transferFrom(msg.sender, address(this), balanceToDeposit);
        _mint(msg.sender, balanceToDeposit);
    }

    function unwrapToken(uint256 balanceToWithdraw) public {
        _burn(msg.sender, balanceToWithdraw);
        rawTokenContract.transfer(msg.sender, balanceToWithdraw);
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        (uint256 status, string memory statusStr) = _checkOnERC20Received(owner, to, amount, "");
        if (status > 1) {
            require(false, string(abi.encodePacked("ERC20 transfer failed: ", statusStr)));
        }
        return true;
    }

    function transferWithCall(
        address to,
        uint256 amount,
        bytes memory _data
    ) public payable returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        (uint256 status, string memory statusStr) = _checkOnERC20Received(owner, to, amount, _data);
        if (status > 1) {
            require(false, string(abi.encodePacked("ERC20 transfer failed: ", statusStr)));
        }
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        (uint256 status, string memory statusStr) = _checkOnERC20Received(from, to, amount, "");
        if (status > 1) {
            require(false, string(abi.encodePacked("ERC20 transfer failed: ", statusStr)));
        }
        return true;
    }

    function transferFromWithCall(
        address from,
        address to,
        uint256 amount,
        bytes memory _data
    ) public payable returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        (uint256 status, string memory statusStr) = _checkOnERC20Received(from, to, amount, _data);
        if (status > 1) {
            require(false, string(abi.encodePacked("ERC20 transfer failed: ", statusStr)));
        }
        return true;
    }

    function onERC20Received(
        address _operator,
        address _from,
        uint256 _amount,
        bytes memory _data
    ) external payable returns (bytes4) {
        if (msg.sender == address(this)) {
            _burn(address(this), _amount);
            rawTokenContract.transfer(_from, _amount);
            return bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"));
        }
        else {
            revert("cannot accept other ERC20 tokens");
        }
    }

    function _checkOnERC20Received(
        address from,
        address to,
        uint256 amount,
        bytes memory _data
    ) private returns (uint256, string memory) {
        uint256 toRetStatus = 0;
        string memory toRetString = "";

        if (to.isContract()) {
            try IERC20Receiver(to).onERC20Received{ value: msg.value }(msg.sender, from, amount, _data) returns (bytes4 retval) {
                if (retval != IERC20Receiver(to).onERC20Received.selector) {
                    toRetStatus = 2;
                    toRetString = "bad onERC20Received retval";
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    toRetStatus = 1;
                    toRetString = "";
                } else {
                    toRetStatus = 3;
                    toRetString = string(reason);
                }
                (bool success, ) = payable(msg.sender).call{ value: msg.value }("");
                if (!success) {
                    revert("Value transfer failed following failed external call");
                }
            }
        }
        else {
            if (msg.value > 0) {
                (bool success, ) = payable(to).call{ value: msg.value }("");
                if (!success) {
                    revert("Value transfer failed following failed external call");
                }
            }
        }

        return (toRetStatus, toRetString);
    }
}

/**************************************/