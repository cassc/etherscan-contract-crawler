// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAction {

    /**
     * @dev Emit add fund event on chain
     */
    function addFundWithAction(address _clientAddress, address _tokenAddress, uint256 _tokenValue, string memory _data) external returns(bool);

    /**
     * @dev Emit remove fund event on chain
     */
    function withdrawFund(string memory _ticketId, address _clientAddress, address _tokenAddress, uint256 _withdrawValue, uint256 _inDebtValue) external returns(bool);

    /**
     * @dev Emit queue fund event on chain
     */
    function queueWithdraw(string memory _ticketId, address _clientAddress, address _tokenAddress, uint256 _tokenValue) external returns(bool);
}