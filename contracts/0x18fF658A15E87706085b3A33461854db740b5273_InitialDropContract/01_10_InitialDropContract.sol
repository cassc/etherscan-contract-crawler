// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./interfaces/ITokenContract.sol";
import "./interfaces/IConfigContract.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract InitialDropContract is Ownable {
    event PayeeAdded(address tokenContract, address account, uint256 shares);
    event PaymentReleased(address tokenContract, address to, uint256 amount);

    uint constant totalShares = 10000;

    address private _configContract;

    mapping(string => bool) private _usedNonces;
    mapping(address => uint) private _ethValues;
    mapping(address => address[]) private _payees;
    mapping(address => mapping(address => uint16)) private _shares;

    constructor(address configContract) {
        _configContract = configContract;
    }

    function setConfigContract(address configContract) external onlyOwner {
        _configContract = configContract;
    }
    
    function buyFixPrice(address tokenContract, uint tokenId, string calldata nonce, uint maxBlock, bytes calldata signature) external payable {
        require(tokenContract != address(0), "Not a valid contract");
        require(!_usedNonces[nonce], "Nonce has already been used");
        require(maxBlock >= block.number, "Reservation expired");
        
        bytes32 generatedHash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(tokenContract, tokenId, nonce, maxBlock, msg.value)));
        address recoveredAddress = ECDSA.recover(generatedHash, signature);
        require(IConfigContract(_configContract).validateRecoveredSignatureAddress(recoveredAddress), "Signature invalid");

        _usedNonces[nonce] = true;

        ITokenContract(tokenContract).adminMint(msg.sender, tokenId);
        _ethValues[tokenContract] = _ethValues[tokenContract] + msg.value;
    }

    function release(address tokenContract) external {
        require(tokenContract != address(0), "Not a valid contract");

        uint payeesLength = _payees[tokenContract].length;
        require(payeesLength > 0, "No payees");

        uint initialBalance = _ethValues[tokenContract];
        require(initialBalance > 0, "No ETH available");

        _ethValues[tokenContract] = 0;

        uint alreadyReleased = 0;
        uint sharesToSend = 0;

        for (uint i = 0; i < payeesLength; i++) {
            address payee_ = _payees[tokenContract][i];
            if (i == payeesLength - 1) {
                sharesToSend = initialBalance - alreadyReleased;
            } else {
                sharesToSend = initialBalance * _shares[tokenContract][payee_] / totalShares;
                alreadyReleased = alreadyReleased + sharesToSend;
            }
            Address.sendValue(payable(payee_), sharesToSend);
            emit PaymentReleased(tokenContract, payee_, sharesToSend);
        }
    }

    function shares(address tokenContract, address account) external view returns (uint16) {
        return _shares[tokenContract][account];
    }

    function payee(address tokenContract, uint index) external view returns (address) {
        return _payees[tokenContract][index];
    }

    function setPayees(address tokenContract, address[] calldata payees, uint16[] calldata shares_) external onlyOwner {
        require(tokenContract != address(0), "Not a valid contract");
        require(payees.length == shares_.length, "Length of arrays differ");
        require(payees.length > 0, "No payees");

        for (uint i = 0; i < _payees[tokenContract].length; i++) {
            _shares[tokenContract][_payees[tokenContract][i]] = 0;
        }

        delete _payees[tokenContract];

        _addPayees(tokenContract, payees, shares_);
    }

    function _addPayees(address tokenContract, address[] calldata payees, uint16[] calldata shares_) private {
        uint sumOfShares = 0;

        for (uint i = 0; i < payees.length; i++) {
            _addPayee(tokenContract, payees[i], shares_[i]);
            sumOfShares = sumOfShares + shares_[i];
        }
        
        require(sumOfShares == totalShares, "Shares are not valid");
    }

    function _addPayee(address tokenContract, address payee_, uint16 shares_) private {
        require(payee_ != address(0), "Account must not be zero address");
        require(shares_ > 0, "Share must not be 0");
        require(_shares[tokenContract][payee_] == 0, "Account already has shares");

        _payees[tokenContract].push(payee_);
        _shares[tokenContract][payee_] = shares_;
        emit PayeeAdded(tokenContract, payee_, shares_);
    }
}