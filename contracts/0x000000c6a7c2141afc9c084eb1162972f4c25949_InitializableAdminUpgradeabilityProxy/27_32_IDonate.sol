// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from '../dependencies/openzeppelin/contracts/IERC20.sol';

interface IDonate {
    function signer() external view returns (address);

    function donate(IERC20 _token, uint256 _amount, bytes calldata _signature) external payable;

    function withdraw(IERC20 _token, address _to, uint _amount) external;

    function refund(IERC20 _token, address _to, uint256 _amount) external;

    function setSigner(address _signer) external;
}