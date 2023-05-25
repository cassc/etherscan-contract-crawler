// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract GasMovr is Ownable, Pausable {
    /* 
        Variables
    */
    mapping(uint256 => ChainData) public chainConfig;
    mapping(bytes32 => bool) public processedHashes;
    mapping(address => bool) public senders;

    struct ChainData {
        uint256 chainId;
        bool isEnabled;
    }

    /* 
        Events
    */
    event Deposit(
        address indexed destinationReceiver,
        uint256 amount,
        uint256 indexed destinationChainId
    );

    event Withdrawal(address indexed receiver, uint256 amount);

    event Donation(address sender, uint256 amount);

    event Send(address receiver, uint256 amount, bytes32 srcChainTxHash);

    event GrantSender(address sender);
    event RevokeSender(address sender);

    modifier onlySender() {
        require(senders[msg.sender], "Sender role required");
        _;
    }

    constructor() {
        _grantSenderRole(msg.sender);
    }

    receive() external payable {
        emit Donation(msg.sender, msg.value);
    }

    function depositNativeToken(uint256 destinationChainId, address _to)
        public
        payable
        whenNotPaused
    {
        require(
            chainConfig[destinationChainId].isEnabled,
            "Chain is currently disabled"
        );

        emit Deposit(_to, msg.value, destinationChainId);
    }

    function withdrawBalance(address _to, uint256 _amount) public onlyOwner {
        _withdrawBalance(_to, _amount);
    }

    function withdrawFullBalance(address _to) public onlyOwner {
        _withdrawBalance(_to, address(this).balance);
    }

    function _withdrawBalance(address _to, uint256 _amount) private {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");

        emit Withdrawal(_to, _amount);
    }

    function setIsEnabled(uint256 chainId, bool _isEnabled)
        public
        onlyOwner
        returns (bool)
    {
        chainConfig[chainId].isEnabled = _isEnabled;
        return chainConfig[chainId].isEnabled;
    }

    function setPause() public onlyOwner returns (bool) {
        _pause();
        return paused();
    }

    function setUnPause() public onlyOwner returns (bool) {
        _unpause();
        return paused();
    }

    function addRoutes(ChainData[] calldata _routes) external onlyOwner {
        for (uint256 i = 0; i < _routes.length; i++) {
            chainConfig[_routes[i].chainId] = _routes[i];
        }
    }

    function getChainData(uint256 chainId)
        public
        view
        returns (ChainData memory)
    {
        return (chainConfig[chainId]);
    }

    function batchSendNativeToken(
        address payable[] memory receivers,
        uint256[] memory amounts,
        bytes32[] memory srcChainTxHashes,
        uint256 perUserGasAmount,
        uint256 maxLimit
    ) public onlySender {
        require(
            receivers.length == amounts.length &&
                receivers.length == srcChainTxHashes.length,
            "Input length mismatch"
        );
        uint256 gasPrice;
        assembly {
            gasPrice := gasprice()
        }

        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 _gasFees = amounts[i] > maxLimit
                ? (amounts[i] - maxLimit + (gasPrice * perUserGasAmount))
                : gasPrice * perUserGasAmount;
            _sendNativeToken(
                receivers[i],
                amounts[i],
                srcChainTxHashes[i],
                _gasFees
            );
        }
    }

    function sendNativeToken(
        address payable receiver,
        uint256 amount,
        bytes32 srcChainTxHash,
        uint256 perUserGasAmount,
        uint256 maxLimit
    ) public onlySender {
        uint256 gasPrice;
        assembly {
            gasPrice := gasprice()
        }
        uint256 _gasFees = amount > maxLimit
            ? (amount - maxLimit + (gasPrice * perUserGasAmount))
            : gasPrice * perUserGasAmount;

        _sendNativeToken(receiver, amount, srcChainTxHash, _gasFees);
    }

    function _sendNativeToken(
        address payable receiver,
        uint256 amount,
        bytes32 srcChainTxHash,
        uint256 gasFees
    ) private {
        if (processedHashes[srcChainTxHash]) return;
        processedHashes[srcChainTxHash] = true;

        uint256 sendAmount = amount - gasFees;

        emit Send(receiver, sendAmount, srcChainTxHash);

        (bool success, ) = receiver.call{value: sendAmount, gas: 5000}("");
        require(success, "Failed to send Ether");
    }

    function grantSenderRole(address sender) public onlyOwner {
        _grantSenderRole(sender);
    }

    function revokeSenderRole(address sender) public onlyOwner {
        _revokeSenderRole(sender);
    }

    function _grantSenderRole(address sender) private {
        senders[sender] = true;
        emit GrantSender(sender);
    }

    function _revokeSenderRole(address sender) private {
        senders[sender] = false;
        emit RevokeSender(sender);
    }
}