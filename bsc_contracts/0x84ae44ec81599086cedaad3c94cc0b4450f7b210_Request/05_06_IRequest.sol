// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRequest {

	event RequestEvent(uint256 indexed id, address indexed from, bytes request, bytes response);
	 
    function add(uint256 id, bytes memory req, bytes memory response) external;
	function get(uint256 id) external view returns (bool);
}