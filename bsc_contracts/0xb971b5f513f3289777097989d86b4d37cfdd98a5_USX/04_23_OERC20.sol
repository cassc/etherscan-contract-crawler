// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./NonBlockingLzApp.sol";
import "../interfaces/IOERC20.sol";
import "../introspection/ERC165.sol";
import "../token/UERC20.sol";

abstract contract OERC20 is NonBlockingLzApp, IOERC20, ERC165, UERC20 {
    uint256 public constant NO_EXTRA_GAS = 0;
    uint256 public constant FUNCTION_TYPE_SEND = 1;
    bool public useCustomAdapterParams;

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);

    function __OERC20_init(address _lzEndpoint) internal initializer {
        __OERC20_init_unchained(_lzEndpoint);
    }

    function __OERC20_init_unchained(address _lzEndpoint) internal initializer {
        __NonBlockingLzApp_init_unchained(_lzEndpoint);
    }

    function estimateSendFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _amount,
        bool _useZro,
        bytes memory _adapterParams
    ) public view virtual override returns (uint256 nativeFee, uint256 zroFee) {
        // mock the payload for send()
        bytes memory payload = abi.encode(_toAddress, _amount);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
    }

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) public payable virtual override {
        _send(_from, _dstChainId, _toAddress, _amount, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal virtual override {
        // decode and load the toAddress
        (bytes memory toAddressBytes, uint256 amount) = abi.decode(_payload, (bytes, uint256));

        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }

        _creditTo(_srcChainId, toAddress, amount);

        emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, amount);
    }

    function _send(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual {
        _debitFrom(_from, _dstChainId, _toAddress, _amount);

        bytes memory payload = abi.encode(_toAddress, _amount);
        if (useCustomAdapterParams) {
            _checkGasLimit(_dstChainId, FUNCTION_TYPE_SEND, _adapterParams, NO_EXTRA_GAS);
        } else {
            require(_adapterParams.length == 0, "LzApp: _adapterParams must be empty.");
        }
        _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParams);

        emit SendToChain(_dstChainId, _from, _toAddress, _amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                allowance[owner][spender] = currentAllowance - amount;
            }
        }
    }

    function setUseCustomAdapterParams(bool _useCustomAdapterParams) external onlyOwner {
        useCustomAdapterParams = _useCustomAdapterParams;
        emit SetUseCustomAdapterParams(_useCustomAdapterParams);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165, IERC165) returns (bool) {
        return interfaceId == type(IOERC20).interfaceId || interfaceId == type(IERC20).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function circulatingSupply() public view virtual override returns (uint256) {
        return totalSupply;
    }

    function _debitFrom(address _from, uint16, bytes memory, uint256 _amount) internal {
        address spender = _msgSender();
        if (_from != spender) {
            _spendAllowance(_from, spender, _amount);
        }
        _burn(_from, _amount);
    }

    function _creditTo(uint16, address _toAddress, uint256 _amount) internal {
        _mint(_toAddress, _amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[50] private __gap;
}