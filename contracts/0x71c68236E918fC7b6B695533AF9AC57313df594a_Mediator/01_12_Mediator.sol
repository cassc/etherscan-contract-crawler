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

import "./abstract/BasicMediator.sol";
import "../interfaces/IERC20ToERC20Mediator.sol";
import "../interfaces/IERC20Detailed.sol";

contract Mediator is BasicMediator {
    uint256 public constant VERSION = 1;

    mapping(address => address) internal tokenMapping;

    function transferToken(address _recipient, address _tokenAddress, uint256 _value) external {
        passMessage(_recipient, _tokenAddress, _value);
    }

    function passMessage(
        address _recipient, 
        address _tokenAddress, 
        uint256 _value
    ) internal override {
        require(tokenMapping[_tokenAddress] != address(0), 'AM01');
        bytes4 methodSelector = IERC20ToERC20Mediator(0).handleBridgedTokens.selector;
        bytes memory data = abi.encodeWithSelector(
            methodSelector, 
            _recipient, 
            tokenMapping[_tokenAddress],
             _value, 
             nonce
        );

        IERC20Detailed token = IERC20Detailed(_tokenAddress);
        token.transferFrom(_msgSender(), address(this), _value);

        bytes32 msgId = bridgeContract().requireToPassMessage(
            mediatorContractOnOtherSide(), 
            data, 
            requestGasLimit()
        );
        setMessageRecipient(msgId, _recipient);
        setMessageTokenAddress(msgId, _tokenAddress);
        setMessageValue(msgId, _value);
        setNonce(msgId);
    }

    function handleBridgedTokens(
        address _recipient,
        address _tokenAddress,
        uint256 _value,
        bytes32 /* nonce */
    ) external {
        require(_msgSender() == address(bridgeContract()), 'AM05');
        require(bridgeContract().messageSender() == mediatorContractOnOtherSide(), 'AM06');

        unlockToken(_recipient, _tokenAddress, _value);
    }

    function unlockToken(address _recipient, address _tokenAddress, uint256 _value) internal {
        IERC20Detailed token = IERC20Detailed(_tokenAddress);
        token.transfer(_recipient, _value);
    }

    function claimTokens(address _tokenAddress, address _to) public onlyOwner validAddress(_to) {
        IERC20Detailed token = IERC20Detailed(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        unlockToken(_to, _tokenAddress, balance);
    }

    function fixFailedMessage(bytes32 _messageId) external override {
        require(_msgSender() == address(bridgeContract()), 'AM05');
        require(bridgeContract().messageSender() == mediatorContractOnOtherSide(), 'AM06');
        require(!messageFixed(_messageId), 'AM07');

        address recipient = messageRecipient(_messageId);
        address tokenAddress = messageTokenAddress(_messageId);
        uint256 value = messageValue(_messageId);

        setMessageFixed(_messageId);
        unlockToken(recipient, tokenAddress, value);

        emit FailedMessageFixed(_messageId, recipient, tokenAddress, value);
    }

    function setTokenMapping(
        address _localTokenAddress, 
        address _remoteTokenAddress
    ) public onlyOperator validAddress(_remoteTokenAddress) validAddress(_localTokenAddress) {
        tokenMapping[_localTokenAddress] = _remoteTokenAddress;
    }

    function getTokenMapping(address _localTokenAddress) public view returns (address) {
        return tokenMapping[_localTokenAddress];
    }

    /* Reserved slots for future use: https://docs.openzeppelin.com/sdk/2.5/writing-contracts.html#modifying-your-contracts */
    uint256[50] private ______gap;
}