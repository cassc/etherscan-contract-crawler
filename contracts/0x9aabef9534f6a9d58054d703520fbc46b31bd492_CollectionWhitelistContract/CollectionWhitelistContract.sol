/**
 *Submitted for verification at Etherscan.io on 2023-10-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns (address);
}

contract CollectionWhitelistContract {
    struct Options {
        uint256 whitelist_start_time;
        uint256 whitelist_amount;
        uint256 whitelist_price;
        uint256 whitelist_end_time;
        bool is_custody;
    }

    mapping(address => Options) private _whitelist_options_by_address;
    mapping(address => address[]) private _whitelist_by_address;
    mapping(address => mapping(address => bool)) private _is_whitelist_member;

    function setOptions(
        address token_address_,
        uint256 whitelist_start_time,
        uint256 whitelist_amount,
        uint256 whitelist_price,
        uint256 whitelist_end_time,
        bool is_custody
    ) public {
        require(
            msg.sender == IOwnable(token_address_).owner(),
            "Permission denied! Yor are not an owner of this collection"
        );
        _whitelist_options_by_address[token_address_] = Options(
            whitelist_start_time,
            whitelist_amount,
            whitelist_price,
            whitelist_end_time,
            is_custody
        );
    }

    function join(address token_address_) public {
        Options memory options = _whitelist_options_by_address[token_address_];
        require(
            options.whitelist_end_time >= block.timestamp,
            "Registration finished"
        );
        require(
            options.whitelist_amount >=
                _whitelist_by_address[token_address_].length + 1,
            "The whitelist is already full"
        );
        require(
            !_is_whitelist_member[token_address_][msg.sender],
            "You are already in whitelist"
        );
        _whitelist_by_address[token_address_].push(msg.sender);
        _is_whitelist_member[token_address_][msg.sender] = true;
    }

    function getList(address token_address_)
        public
        view
        returns (address[] memory whitelist)
    {
        return _whitelist_by_address[token_address_];
    }

    function isMember(address token_address, address eth_address)
        public
        view
        returns (bool)
    {
        return _is_whitelist_member[token_address][eth_address];
    }

    function getOptions(address token_address_)
        public
        view
        returns (
            uint256 whitelist_start_time,
            uint256 whitelist_amount,
            uint256 whitelist_price,
            bool is_custody
        )
    {
        return (
            _whitelist_options_by_address[token_address_].whitelist_start_time,
            _whitelist_options_by_address[token_address_].whitelist_amount,
            _whitelist_options_by_address[token_address_].whitelist_price,
            _whitelist_options_by_address[token_address_].is_custody
        );
    }
}