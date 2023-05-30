// Copyright (C) 2018 Alon Bukai This program is free software: you
// can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details. You should have received a copy of the GNU General Public
// License along with this program. If not, see http://www.gnu.org/licenses/
// Original ideas here https://github.com/Alonski/MultiSendEthereum/blob/master/contracts/MultiSend.sol

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice `MultiSend` is a contract for sending multiple ETH/ERC20 Tokens to
///  multiple addresses. In addition this contract can call multiple contracts
///  with multiple amounts. There are also TightlyPacked functions which in
///  some situations allow for gas savings. TightlyPacked is cheaper if you
///  need to store input data and if amount is less than 12 bytes. Normal is
///  cheaper if you don't need to store input data or if amounts are greater
///  than 12 bytes. 12 bytes allows for sends of up to 2^96-1 units, 79 billion
///  ETH, so tightly packed functions will work for any ETH send but may not
///  work for token sends when the token has a high number of decimals or a
///  very large total supply. Supports deterministic deployment. As explained
///  here: https://github.com/ethereum/EIPs/issues/777#issuecomment-356103528
contract MultiSend is Ownable {
    address internal constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Send {
        address token;
        address to;
        uint256 amount;
    }

    event Call(address indexed _from, address indexed _to, uint256 _amount);

    constructor() public {}

    function multiSend(Send[] calldata sends) external payable returns (bool) {
        uint256 sentAmount = 0;
        for (uint256 i = 0; i < sends.length; i++) {
            if (sends[i].token == NATIVE_TOKEN) {
                _safeCall(sends[i].to, sends[i].amount);
                sentAmount = sentAmount.add(sends[i].amount);
            } else {
                IERC20(sends[i].token).safeTransferFrom(msg.sender, sends[i].to, sends[i].amount);
            }
        }
        require(sentAmount == msg.value, "mismatch send amount");
        return true;
    }

    /// @notice Call to multiple contracts using a byte32 array which
    ///  includes the contract address and the amount.
    ///  Addresses and amounts are stored in a packed bytes32 array.
    ///  Address is stored in the 20 most significant bytes.
    ///  The address is retrieved by bitshifting 96 bits to the right
    ///  Amount is stored in the 12 least significant bytes.
    ///  The amount is retrieved by taking the 96 least significant bytes
    ///  and converting them into an unsigned integer.
    ///  Payable
    /// @param _addressesAndAmounts Bitwise packed array of contract
    ///  addresses and amounts
    function multiCallTightlyPacked(bytes32[] calldata _addressesAndAmounts)
        external
        payable
        returns (bool)
    {
        uint256 sentAmount = 0;
        for (uint256 i = 0; i < _addressesAndAmounts.length; i++) {
            address to = address(bytes20(_addressesAndAmounts[i]));
            uint256 amount = uint256(uint96(uint256(_addressesAndAmounts[i])));

            _safeCall(to, amount);
            sentAmount = sentAmount.add(amount);
        }
        require(sentAmount == msg.value, "mismatch send amount");
        return true;
    }

    /// @notice Call to multiple contracts using two arrays which
    ///  includes the contract address and the amount.
    /// @param _addresses Array of contract addresses to call
    /// @param _amounts Array of amounts to send
    function multiCall(address[] calldata _addresses, uint256[] calldata _amounts)
        external
        payable
        returns (bool)
    {
        uint256 sentAmount = 0;
        for (uint256 i = 0; i < _addresses.length; i++) {
            _safeCall(_addresses[i], _amounts[i]);
            sentAmount = sentAmount.add(_amounts[i]);
        }
        require(sentAmount == msg.value, "mismatch send amount");
        return true;
    }

    /// @notice Send ERC20 tokens to multiple contracts
    ///  using a byte32 array which includes the address and the amount.
    ///  Addresses and amounts are stored in a packed bytes32 array.
    ///  Address is stored in the 20 most significant bytes.
    ///  The address is retrieved by bitshifting 96 bits to the right
    ///  Amount is stored in the 12 least significant bytes.
    ///  The amount is retrieved by taking the 96 least significant bytes
    ///  and converting them into an unsigned integer.
    /// @param _token The token to send
    /// @param _addressesAndAmounts Bitwise packed array of addresses
    ///  and token amounts
    function multiERC20TransferTightlyPacked(
        address _token,
        bytes32[] calldata _addressesAndAmounts
    ) external {
        for (uint256 i = 0; i < _addressesAndAmounts.length; i++) {
            address to = address(bytes20(_addressesAndAmounts[i]));
            uint256 amount = uint256(uint96(uint256(_addressesAndAmounts[i])));
            IERC20(_token).safeTransferFrom(msg.sender, to, amount);
        }
    }

    /// @notice Send ERC20 tokens to multiple contracts
    ///  using two arrays which includes the address and the amount.
    /// @param _token The token to send
    /// @param _addresses Array of addresses to send to
    /// @param _amounts Array of token amounts to send
    function multiERC20Transfer(
        address _token,
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external {
        for (uint256 i = 0; i < _addresses.length; i++) {
            IERC20(_token).safeTransferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
    }

    function withdraw(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        if (token == NATIVE_TOKEN) {
            _safeCall(to, amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    receive() external payable {}

    function _safeCall(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "transfer eth failed");
        emit Call(msg.sender, to, amount);
    }
}