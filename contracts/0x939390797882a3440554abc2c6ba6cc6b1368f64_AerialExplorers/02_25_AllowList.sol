// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../signing/SharedSigners.sol";
import "../utils/Timing.sol";

/**
 * @title AllowList
 * @dev Adds allowlist capabilities to a contract implementer.
 */
abstract contract AllowList is SharedSigners {
    using Timing for uint256;

    struct ListConfig {
        address signer;
        uint256 mintPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 maxPerWallet;
    }

    struct List {
        bool exists;
        uint256 total;
        uint256 mintPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 maxPerWallet;
    }

    mapping(address => List) public allowLists;
    mapping(bytes32 => uint256) internal usedSignatures;

    /**
     * @notice Add a list.
     */
    function _addList(
        address signer,
        uint256 mintPrice,
        uint256 startTime,
        uint256 endTime,
        uint256 maxPerWallet
    ) internal {
        allowLists[signer].exists = true;
        allowLists[signer].total = 0;
        allowLists[signer].mintPrice = mintPrice;
        allowLists[signer].startTime = startTime;
        allowLists[signer].endTime = endTime;
        allowLists[signer].maxPerWallet = maxPerWallet;
    }

    /**
     * @notice Add a list.
     */
    function _addList(AllowList.ListConfig memory _list) internal {
        _addList(
            _list.signer,
            _list.mintPrice,
            _list.startTime,
            _list.endTime,
            _list.maxPerWallet
        );
    }

    function _addLists(AllowList.ListConfig[] memory _lists) internal {
        for (uint256 i = 0; i < _lists.length; i++) {
            _addList(_lists[i]);
        }
    }

    /**
     * @notice Remove a list.
     */
    function _removeList(address signer) internal {
        allowLists[signer].exists = false;
    }

    /**
     * @notice Returns the mint count for the list.
     */
    function listTotal(address _address) external view returns (uint256) {
        return allowLists[_address].total;
    }

    /**
     * @notice Check address ability to mint, with max per wallet check
     * @param _address the address the signature was assigned to
     * @param _count how many tokens to mint
     * @param _minted how many tokens has the address minted already
     * @param _signature the signature by the allowance signer wallet
     * @param _nonce the nonce associated to this allowance
     * @return true/false if they can mint
     */
    function _validateSignature(
        address _address,
        uint256 _count,
        uint256 _minted,
        bytes calldata _signature,
        uint256 _nonce
    ) internal view returns (bool, string memory) {
        bytes32 message = _createMessage(_address, _nonce);
        address signer = _recoverSigner(_signature, _address, _nonce);
        List memory list = allowLists[signer];

        if (!list.exists) {
            return (false, "Invalid Signature");
        }

        if (
            list.startTime != 0 && // 0 is disabled
            block.timestamp.isBefore(list.startTime)
        ) {
            return (false, "Mint Not Started");
        }

        if (
            list.endTime != 0 && // 0 is disabled
            block.timestamp.isAfter(list.endTime)
        ) {
            return (false, "Mint Completed");
        }

        if (
            _nonce != 0 && // 0 is disabled
            usedSignatures[message] + _count > _nonce
        ) return (false, "Exceeds Allocation");

        if (
            list.maxPerWallet != 0 && // 0 is disabled
            (_minted + _count) > list.maxPerWallet
        ) {
            return (false, "Exceeds Max Per Wallet");
        }

        // return _validateSignature(_address, _count, _signature, _nonce);
        return (true, "");
    }

    /**
     * @notice Mark the signature as used for _count tokens
     * @dev checks msg.value for proper payment
     * @param _address the address the signature was assigned to
     * @param _count how many tokens to mint
     * @param _signature the signature by the allowance signer wallet
     * @param _nonce the nonce associated to this allowance
     */
    function _useSignature(
        address _address,
        uint256 _count,
        bytes calldata _signature,
        uint256 _nonce
    ) internal {
        bytes32 message = _createMessage(_address, _nonce);
        address signer = _recoverSigner(_signature, _address, _nonce);

        uint256 _mintPrice = allowLists[signer].mintPrice;
        require(msg.value >= _mintPrice * _count, "Insufficient Payment");

        usedSignatures[message] += _count;
        allowLists[signer].total += _count;
    }

    /**
     * @notice Create hash message from
     * @param _address the address the signature was assigned to
     * @param _nonce the corresponding nonces
     * @return message the messages to sign
     */
    function createMessage(address _address, uint256 _nonce)
        public
        pure
        returns (bytes32)
    {
        return _createMessage(_address, _nonce);
    }
}