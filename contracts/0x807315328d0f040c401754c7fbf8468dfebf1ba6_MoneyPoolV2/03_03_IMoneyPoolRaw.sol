// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Interface of the money pool functions
 */

interface IMoneyPoolRaw {
    /**
     * @dev Returns client's withdraw nonce.
     */
    function clientNonce(address _clientAddress) external view returns(uint256);

    /**
     * @dev Returns contract total assets of the type.
     */
    function totalLockedAssets(address _tokenAddress) external view returns(uint256);

    /**
     * @dev Returns total SATIS token in the contract.
     */
    function satisTokenBalance(address _tokenAddress) external view returns(uint256);

    /**
     * @dev Get queued value for the list of clients
     */
    function getClientQueueValue(address[] memory _clientAddressList, address _tokenAddress) external view returns(uint256[] memory);

    /**
     * @dev Get reserved value for the list of clients
     */
    function getInstantWithdrawReserve(string[] memory _ticketIdList, address _tokenAddress) external view returns(uint256[] memory);

    /**
     * @dev Returns pool's owner address.
     */
    function owner() external view returns(address);

    /**
     * @dev Verify if an address is a worker.
     */
    function verifyWorker(address _workerAddress) external view returns(bool);

    /**
     * @dev Add and lock fund.
     */
    function addFundWithAction(address _clientAddress, address _tokenAddress, uint256 _addValue) external returns(bool);

    /**
     * @dev Verify and withdraw fund.
     */
    function verifyAndWithdrawFund(bytes memory _targetSignature, address _clientAddress, address _tokenAddress, uint256 _withdrawValue, uint256 _inDebtValue, uint256 _tier, uint256 _chainId, address _poolAddress, uint256 _expBlockNo, string memory _ticketId, uint256 _nonce) external returns(bool _isDone);

    /**
     * @dev Verify and queue.
     */
    function verifyAndQueue(bytes memory _targetSignature, address _clientAddress, address _tokenAddress, uint256 _withdrawValue, uint256 _inDebtValue, uint256 _tier, uint256 _chainId, address _poolAddress, uint256 _expBlockNo, string memory _ticketId, uint256 _nonce) external returns(bool _isDone);

    /**
     * @dev Verify and redeem SATIS token in Sigma Mining.
     */
    function verifyAndRedeemToken(bytes memory _targetSignature, address _clientAddress, address _tokenAddress, uint256 _redeemValue, uint256 _inDebtValue, uint256 _tier, uint256 _chainId, address _poolAddress, uint256 _expBlockNo, string memory _ticketId, uint256 _nonce) external returns(bool _isDone);
}