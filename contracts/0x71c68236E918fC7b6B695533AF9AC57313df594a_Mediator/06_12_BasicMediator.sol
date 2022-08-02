/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity 0.6.2;

import "./AMBMediator.sol";

abstract contract BasicMediator is AMBMediator {
    event FailedMessageFixed(bytes32 indexed messageId, address recipient, address tokenAddress, uint256 value);

    bytes32 public nonce;
    mapping(bytes32 => address) internal _messageRecipient;
    mapping(bytes32 => address) internal _messageTokenAddress;
    mapping(bytes32 => uint256) internal _messageValue;
    mapping(bytes32 => bool) internal _messageFixed;

    function initialize(
        address _bridgeContract,
        address _mediatorContract,
        uint256 _requestGasLimit,
        address _owner
    ) external returns (bool) {
        _setBridgeContract(_bridgeContract);
        _setMediatorContractOnOtherSide(_mediatorContract);
        _setRequestGasLimit(_requestGasLimit);
        Operator.initialize(_owner);
        setNonce(keccak256(abi.encodePacked(address(this))));
    }

    function getBridgeInterfacesVersion() external pure returns (uint64 major, uint64 minor, uint64 patch) {
        return (1, 0, 0);
    }

    function getBridgeMode() external pure returns (bytes4 _data) {
        return bytes4(keccak256(abi.encodePacked("erc20-to-erc20-lock-unlock-amb")));
    }

    function setNonce(bytes32 _msgId) internal {
        nonce = _msgId;
    }

    function setMessageRecipient(bytes32 _msgId, address _recipient) internal {
        _messageRecipient[_msgId] = _recipient;
    }

    function messageRecipient(bytes32 _msgId) internal view returns (address) {
        return _messageRecipient[_msgId];
    }

    function setMessageTokenAddress(bytes32 _msgId, address _tokenAddress) internal {
        _messageTokenAddress[_msgId] = _tokenAddress;
    }

    function messageTokenAddress(bytes32 _msgId) internal view returns (address) {
        return _messageTokenAddress[_msgId];
    }

    function setMessageValue(bytes32 _msgId, uint256 _value) internal {
        _messageValue[_msgId] = _value;
    }

    function messageValue(bytes32 _msgId) internal view returns (uint256) {
        return _messageValue[_msgId];
    }

    function setMessageFixed(bytes32 _msgId) internal {
        _messageFixed[_msgId] = true;
    }

    function messageFixed(bytes32 _msgId) public view returns (bool) {
        return _messageFixed[_msgId];
    }

    function requestFailedMessageFix(bytes32 _txHash) external {
        require(!bridgeContract().messageCallStatus(_txHash), 'AM04');
        require(bridgeContract().failedMessageReceiver(_txHash) == address(this), 'AM05');
        require(bridgeContract().failedMessageSender(_txHash) == mediatorContractOnOtherSide(), 'AM06');
        bytes32 msgId = bridgeContract().failedMessageDataHash(_txHash);

        bytes4 methodSelector = this.fixFailedMessage.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, msgId);
        bridgeContract().requireToPassMessage(mediatorContractOnOtherSide(), data, requestGasLimit());
    }

    function fixFailedMessage(bytes32 _msgId) external virtual;

    function passMessage(address _recipient, address _tokenAddress, uint256 _value) internal virtual;

    /* Reserved slots for future use: https://docs.openzeppelin.com/sdk/2.5/writing-contracts.html#modifying-your-contracts */
    uint256[50] private ______gap;
}