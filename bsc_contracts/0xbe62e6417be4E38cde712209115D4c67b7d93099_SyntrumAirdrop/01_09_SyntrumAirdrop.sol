// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import './common/AccessControl.sol';
import './common/Utils.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @dev Sale contract,
 * functions names are self explanatory
 */
contract SyntrumAirdrop is AccessControl, Utils {
    using ECDSA for bytes32;

    event EarningsReceived(address receiver, uint256 amount);

    mapping (address => bool) internal _earningsReceived;
    // user address => is received

    bytes32 internal constant MANAGER = keccak256(abi.encode('MANAGER'));
    bytes32 internal constant SIGNER = keccak256(abi.encode('SIGNER'));

    address internal _tokenAddress;
    uint256 internal _amount;
    bool internal _airdropActive;

    /**
     * @dev constructor
     */
    constructor (
        address ownerAddress,
        address managerAddress,
        address signerAddress,
        address tokenAddress,
        uint256 amount
    ) {
        require(ownerAddress != address(0), 'ownerAddress can not be zero');
        require(managerAddress != address(0), 'managerAddress can not be zero');
        require(signerAddress != address(0), 'managerAddress can not be zero');
        require(tokenAddress != address(0), 'tokenAddress can not be zero');
        require(amount > 0, 'amount can not be zero');
        _owner = ownerAddress;
        _grantRole(MANAGER, managerAddress);
        _grantRole(SIGNER, signerAddress);
        _tokenAddress = tokenAddress;
        _amount = amount;
        _airdropActive = true;
    }

    function receiveEarnings (
        bytes memory signature
    ) external returns (bool) {
        require(_airdropActive, 'Airdrop is not active');
        require(
            verifySignature(msg.sender, signature),
                'Signature is not valid'
        );
        require(
            !_earningsReceived[msg.sender],
                'Caller already received earnings'
        );

        _earningsReceived[msg.sender] = true;
        _sendAsset(
            _tokenAddress,
            msg.sender,
            _amount
        );
        emit EarningsReceived(msg.sender, _amount);
        return true;
    }

    function tokenBalance () external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function earningsReceived (
        address userAddress
    ) external view returns (bool) {
        return _earningsReceived[userAddress];
    }

    function verifySignature (
        address sender,
        bytes memory signature
    ) public view returns (bool) {
        bytes memory message = abi.encode(sender);
        address signer = keccak256(message)
            .toEthSignedMessageHash()
            .recover(signature);
        return _checkRole(SIGNER, signer);
    }

    function getAirdropStatus () external view returns (bool) {
        return _airdropActive;
    }

    function setAirdropStatus (
        bool active
    ) external hasRole(MANAGER) returns (bool) {
        _airdropActive = active;
        return true;
    }

    function getAmount () external view returns (uint256) {
        return _amount;
    }

    function setAmount (
        uint256 amount
    ) external hasRole(MANAGER) returns (bool) {
        _amount = amount;
        return true;
    }

    function getTokenAddress () external view returns (address) {
        return _tokenAddress;
    }

    function setTokenAddress (
        address tokenAddress
    ) external hasRole(MANAGER) returns (bool) {
        _tokenAddress = tokenAddress;
        return true;
    }

    function withdraw (
        address tokenAddress,
        uint256 amount
    ) external onlyOwner returns (bool) {
        _sendAsset(tokenAddress, owner(), amount);
        return true;
    }
}