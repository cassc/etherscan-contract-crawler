// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contractsv4/access/Ownable.sol";
import "@openzeppelin/contractsv4/security/Pausable.sol";
import "@openzeppelin/contractsv4/token/ERC20/IERC20.sol";
import "@openzeppelin/contractsv4/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contractsv4/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contractsv4/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contractsv4/utils/Counters.sol";
import "./IRefundGateway.sol";

contract PaymentGateway is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using ECDSA for bytes32;
    using ECDSA for bytes;
    using Counters for Counters.Counter;

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;


    address public hotWallet;
    address public refundAddress;
    EnumerableSet.AddressSet private whiteListTokens;
    EnumerableSet.AddressSet private validators;
    mapping(address => Counters.Counter) private _nonces;



    //modifier
    modifier onlyWhiteListToken(address _token) {
        require(whiteListTokens.contains(_token), "PaymentGateway: token not in whitelist");
        _;
    }

    modifier checkSigner(bytes memory _signature, address _to, uint _amount, address _token) {
        bytes32 _hash = keccak256(abi.encodePacked(_to, msg.sender, address(this), _amount, _useNonce(msg.sender), _token)).toEthSignedMessageHash();
        address _validator = _hash.recover(_signature);
        require(validators.contains(_validator), "PaymentGateway: !verify");
        _;
    }

    //events
    event UpdateTokenWhiteList(address[] tokens, bool _action);
    event UpdateValidator(address[] tokens, bool _action);
    event Deposit(address _token, address _to, uint256 _amount);
    event Withdraw(address _token, address _to, uint256 _amount);
    event ChangeHotWallet(address _old, address _new);
    event ChangeRefundAddress(address _old, address _new);

    constructor(address[] memory _whiteListToken, address[] memory _validators, address _refundAddress, address _hotWallet) {
        //white list token
        _addTokenToWhiteList(_whiteListToken, true);

        // validator
        _addValidators(_validators, true);

        if(_refundAddress != address(0)) {
            refundAddress = _refundAddress;
        }
        if(_hotWallet != address(0)) {
            hotWallet = _hotWallet;
        }
    }

    //internal functions
    function _addTokenToWhiteList(address[] memory _whiteListToken, bool _action) internal {
        for (uint256 i = 0; i < _whiteListToken.length; i++) {
            if (_action) {
                require(whiteListTokens.add(_whiteListToken[i]), "PaymentGateway: token has been added");
            } else {
                require(whiteListTokens.remove(_whiteListToken[i]), "PaymentGateway: token has been removed");
            }
        }
        emit UpdateTokenWhiteList(_whiteListToken, _action);
    }

    function _addValidators(address[] memory _validators, bool _action) internal {
        for (uint256 i = 0; i < _validators.length; i++) {
            if (_action) {
                require(validators.add(_validators[i]), "PaymentGateway: validator has been added");
            } else {
                require(validators.remove(_validators[i]), "PaymentGateway: validator has been removed");
            }
        }
        emit UpdateValidator(_validators, _action);
    }

    function _deposit(address _token, address _to, uint256 _amount) internal onlyWhiteListToken(_token) {
        require(hotWallet != address(0), "PaymentGateway: hotwallet is zero address");
        if (_token == ETH) {
            (bool sent,) = _to.call{value : msg.value}("");
            require(sent, "PaymentGateway: Failed to send Ether");
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, hotWallet, _amount);
        }
        emit Deposit(_token, _to, _amount);
    }

    function _withdraw(address _token, address _to, uint256 _amount) internal onlyWhiteListToken(_token) {
        IRefundGateway(refundAddress).transfer(_token, _to, _amount);
        emit Withdraw(_token, _to, _amount);
    }

    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    //external functions
    function deposit(address _token, address _depositFor, uint256 _amount) external payable whenNotPaused {
        if (msg.value > 0) {
            _deposit(ETH, _depositFor, _amount);
        } else {
            _deposit(_token, _depositFor, _amount);
        }
    }

    function withdraw(address _token, address _to, uint256 _amount, bytes memory _signature) external checkSigner(_signature, _to, _amount, _token) whenNotPaused{
        _withdraw(_token, _to, _amount);
    }

    receive() external payable whenNotPaused{
        _deposit(ETH, msg.sender, msg.value);
    }

    // view functions
    function nonces(address owner) external view returns (uint256) {
        return _nonces[owner].current();
    }

    function isValidator(address _validator) external view returns(bool) {
        return validators.contains(_validator);
    }

    function isWhiteListToken(address _token) external view returns(bool) {
        return whiteListTokens.contains(_token);
    }

    function validator() external view returns(address[] memory) {
        return validators.values();
    }

    function whiteListToken() external view returns(address[] memory) {
        return whiteListTokens.values();
    }

    //admin functions
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function updateWhiteList(address[] memory _tokens, bool _action) external onlyOwner {
        _addTokenToWhiteList(_tokens, _action);
    }

    function updateValidators(address[] memory _validators, bool _action) external onlyOwner {
        _addValidators(_validators, _action);
    }

    function updateHotWallet(address _new) external onlyOwner {
        require(_new != address(0), "PaymentGateway: _new is zero");
        address _old = hotWallet;
        hotWallet = _new;
        emit ChangeHotWallet(_old, _new);
    }

    function updateRefundAddress(address _new) external onlyOwner {
        require(_new != address(0), "PaymentGateway: _new is zero");
        address _old = refundAddress;
        refundAddress = _new;
        emit ChangeRefundAddress(_old, _new);
    }

    function rescureFund(address _erc20, address payable _to) external payable onlyOwner {
        if (_erc20 == ETH) {
            (bool _sent,) = _to.call{value : address(this).balance}("");
            require(_sent, "RefundGateway: Failed to send BNB");
        } else {
            IERC20(_erc20).safeTransfer(_to, IERC20(_erc20).balanceOf(address(this)));
        }
    }
}