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

import "../../interfaces/IAMB.sol";
import "../../access/Operator.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";

contract AMBMediator is Initializable, Operator {
    address internal _bridgeContract;
    address internal _mediatorContractOnOtherSide;
    uint256 internal _requestGasLimit;

    modifier validAddress(address _to) {
        require(_to != address(0), 'AM01');
        /* solcov ignore next */
        _;
    }

    function setBridgeContract(address newBridgeContract) external onlyOwner {
        _setBridgeContract(newBridgeContract);
    }

    function _setBridgeContract(address newBridgeContract) internal {
        require(Address.isContract(newBridgeContract), 'AM02');
        _bridgeContract = newBridgeContract;
    }

    function bridgeContract() public view returns (IAMB) {
        return IAMB(_bridgeContract);
    }

    function setMediatorContractOnOtherSide(address newMediatorContract) external onlyOwner {
        _setMediatorContractOnOtherSide(newMediatorContract);
    }

    function _setMediatorContractOnOtherSide(address newMediatorContract) internal {
        _mediatorContractOnOtherSide = newMediatorContract;
    }

    function mediatorContractOnOtherSide() public view returns (address) {
        return _mediatorContractOnOtherSide;
    }

    function setRequestGasLimit(uint256 newRequestGasLimit) external onlyOwner {
        _setRequestGasLimit(newRequestGasLimit);
    }

    function _setRequestGasLimit(uint256 newRequestGasLimit) internal {
        require(newRequestGasLimit <= bridgeContract().maxGasPerTx(), 'AM03');
        _requestGasLimit = newRequestGasLimit;
    }

    function requestGasLimit() public view returns (uint256) {
        return _requestGasLimit;
    }

    /* Reserved slots for future use: https://docs.openzeppelin.com/sdk/2.5/writing-contracts.html#modifying-your-contracts */
    uint256[50] private ______gap;
}