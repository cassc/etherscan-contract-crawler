// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOKGScholarship {
	function scholarship(
		uint256[] calldata heroIds,
		string calldata scholarshipId,
		address assignee,
		bytes calldata signature
	) external;

	function cancelScholarship(
		string calldata scholarshipId,
		bytes calldata signature
	) external;

	event NewScholarship(
		uint256[] heroIds,
		address indexed owner,
		address indexed assignee,
		string scholarId
	);

	event CancelScholarship(
		uint256[] heroIds,
		address indexed owner,
		address indexed assignee,
		string scholarId
	);
}