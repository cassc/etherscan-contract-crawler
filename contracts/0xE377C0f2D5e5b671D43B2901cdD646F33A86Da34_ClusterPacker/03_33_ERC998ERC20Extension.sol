// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC998TopDown.sol";
import "../interfaces/IERC998ERC20TopDown.sol";
import "../interfaces/IERC998ERC20TopDownEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

abstract contract ERC998ERC20Extension is ERC998TopDown, IERC998ERC20TopDown, IERC998ERC20TopDownEnumerable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(uint256 => EnumerableSet.AddressSet) internal erc20ChildContracts;

    mapping(uint256 => mapping(address => uint256)) internal erc20Balances;

    function balanceOfERC20(uint256 _tokenId, address _erc20Contract) external view virtual override returns (uint256) {
        return erc20Balances[_tokenId][_erc20Contract];
    }

    function erc20ContractByIndex(uint256 _tokenId, uint256 _index) external view virtual override returns (address) {
        return erc20ChildContracts[_tokenId].at(_index);
    }

    function totalERC20Contracts(uint256 _tokenId) external view virtual override returns (uint256) {
        return erc20ChildContracts[_tokenId].length();
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC998TopDown) returns (bool) {
        return
            _interfaceId == type(IERC998ERC20TopDown).interfaceId ||
            _interfaceId == type(IERC998ERC20TopDownEnumerable).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    function transferERC20(
        uint256 _tokenId,
        address _to,
        address _erc20Contract,
        uint256 _value
    ) external virtual override {
        _validateERC20Value(_value);
        _validateReceiver(_to);
        _validateERC20Transfer(_tokenId);
        _removeERC20(_tokenId, _erc20Contract, _value);

        IERC20(_erc20Contract).safeTransfer(_to, _value);
        emit TransferERC20(_tokenId, _to, _erc20Contract, _value);
    }

    function getERC20(
        address,
        uint256,
        address,
        uint256
    ) external pure override {
        revert("external calls restricted");
    }

    function transferERC223(
        uint256,
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual override {
        revert("TRANSFER_ERC223_NOT_SUPPORTED");
    }

    function tokenFallback(
        address,
        uint256,
        bytes calldata
    ) external virtual override {
        revert("TOKEN_FALLBACK_ERC223_NOT_SUPPORTED");
    }

    function _getERC20(
        address _from,
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value
    ) internal {
        _validateERC20Value(_value);
        _receiveErc20Child(_from, _tokenId, _erc20Contract, _value);
        IERC20(_erc20Contract).safeTransferFrom(_from, address(this), _value);
    }

    function _validateERC20Value(uint256 _value) internal virtual {
        require(_value > 0, "zero amount");
    }

    function _validateERC20Transfer(uint256 _fromTokenId) internal virtual {
        _validateTransferSender(_fromTokenId);
    }

    function _receiveErc20Child(
        address _from,
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value
    ) internal virtual {
        require(_exists(_tokenId), "bundle tokenId does not exist");
        uint256 erc20Balance = erc20Balances[_tokenId][_erc20Contract];
        if (erc20Balance == 0) {
            erc20ChildContracts[_tokenId].add(_erc20Contract);
        }
        erc20Balances[_tokenId][_erc20Contract] += _value;
        emit ReceivedERC20(_from, _tokenId, _erc20Contract, _value);
    }

    function _removeERC20(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value
    ) internal virtual {
        uint256 erc20Balance = erc20Balances[_tokenId][_erc20Contract];
        require(erc20Balance >= _value, "not enough token available to transfer");
        uint256 newERC20Balance = erc20Balance - _value;
        erc20Balances[_tokenId][_erc20Contract] = newERC20Balance;
        if (newERC20Balance == 0) {
            erc20ChildContracts[_tokenId].remove(_erc20Contract);
        }
    }
}