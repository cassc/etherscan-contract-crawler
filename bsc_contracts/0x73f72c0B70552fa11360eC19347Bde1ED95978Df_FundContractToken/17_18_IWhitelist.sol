// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IWhitelist {
    struct WhitelistStruct
	{
		address contractAddress; // 160
		bytes4 method; // 32
		uint8 role; // 8
        bool useWhitelist;
	}
    function whitelisted(address member) external view returns(bool);
}