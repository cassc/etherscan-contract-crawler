// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IOperatorErrors {
	error NonOperator(address _operator, address _sender);
}