// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ProxyWithdrawal.sol";
import "./ProxyFee.sol";

/// Chainspot proxy contract
contract ChainspotProxy is Ownable, ReentrancyGuard, ProxyWithdrawal, ProxyFee {

    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    struct Client {
        bool exists;
    }

    mapping(address => Client) public clients;

    /// Constructor
    /// @param _feeBase uint  Fee base param
    /// @param _feeMul uint  Fee multiply param
    constructor(uint _feeBase, uint _feeMul) {
        setFeeParams(_feeBase, _feeMul);
    }

    /// Just for tests
    receive() external payable {}

    /// Add trusted client (only for owner)
    /// @param _clientAddress address  Client address
    function addClient(address _clientAddress) public onlyOwner {
        require(_clientAddress.isContract(), "ChainspotProxy: address is non-contract");
        clients[_clientAddress].exists = true;
    }

    /// Add multiple trusted clients (only for owner)
    /// @param  _clientAddresses address[]  Client addresses list
    function addClients(address[] calldata _clientAddresses) public onlyOwner {
        for (uint i = 0; i < _clientAddresses.length; i++) {
            addClient(_clientAddresses[i]);
        }
    }

    /// Remove trusted client (only for owner)
    /// @param  _clientAddress address  Client address
    function removeClient(address _clientAddress) public onlyOwner {
        delete clients[_clientAddress];
    }

    /// Meta proxy - transfer transaction initiation
    /// @param _token IERC20  Token address (address(0) - native coins)
    /// @param _approveTo address  Approve to address
    /// @param _callDataTo address  Calldata address
    /// @param _data bytes  Calldata
    function metaProxy(IERC20 _token, address _approveTo, address _callDataTo, bytes calldata _data) external payable nonReentrant {
        require(clients[_callDataTo].exists, "ChainspotProxy: wrong client address");

        if (address(_token) == address(0)) {
            proxyCoins(_callDataTo, _data);
        } else {
            proxyTokens(_token, _approveTo, _callDataTo, _data);
        }
    }

    /// Proxy coins
    /// @param _to address  Calldata address
    /// @param _data bytes  Calldata
    function proxyCoins(address _to, bytes calldata _data) internal {
        uint amount = msg.value;
        require(amount > 0, "ChainspotProxy: amount is too small");

        uint feeAmount = calcFee(amount);
        if (feeAmount > 0) {
            (bool successFee, ) = owner().call{value: feeAmount}("");
            require(successFee, "ChainspotProxy: fee not sent");
        }

        uint routerAmount = amount.sub(feeAmount);
        require(routerAmount > 0, "ChainspotProxy: routerAmount is too small");


        (bool success, ) = _to.call{value: routerAmount}(_data);
        require(success, "ChainspotProxy: transfer not sent");
    }

    /// Proxy tokens
    /// @param _token IERC20  Token address
    /// @param _approveTo address  Approve to address
    /// @param _callDataTo address  Calldata address
    /// @param _data bytes  Calldata
    function proxyTokens(IERC20 _token, address _approveTo, address _callDataTo, bytes calldata _data) internal {
        if (msg.value > 0) {
            (bool successTV, ) = msg.sender.call{value: msg.value}("");
            require(successTV, "ChainspotProxy: accidentally value not sent");
        }

        address selfAddress = address(this);
        address fromAddress = msg.sender;

        uint amount = _token.allowance(fromAddress, selfAddress);
        require(amount > 0, "ChainspotProxy: amount is too small");
        uint feeAmount = calcFee(amount);
        if (feeAmount > 0) {
            require(_token.transferFrom(fromAddress, owner(), feeAmount), "ChainspotProxy: fee transfer request failed");
        }

        uint routerAmount = amount.sub(feeAmount);
        require(routerAmount > 0, "ChainspotProxy: routerAmount is too small");
        require(_token.transferFrom(fromAddress, selfAddress, routerAmount), "ChainspotProxy: transferFrom request failed");

        require(_token.approve(_approveTo, routerAmount), "ChainspotProxy: approve request failed");

        (bool success, ) = _callDataTo.call(_data);
        require(success, "ChainspotProxy: call data request failed");

        if (_token.allowance(selfAddress, _approveTo) > 0) {
            require(_token.approve(_approveTo, 0), "ChainspotProxy: refert approve request failed");
        }
    }
}