// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import {ERCBase, ERC721Partial, ERC1155Partial} from "./INFT.sol";

error InvalidLength();
error InsufficientValue();
error NotApproved();
error WithdrawFailed();

contract BulkSender is Ownable {
    using SafeMath for uint256;

    bytes4 _ERC721 = 0x80ac58cd;
    bytes4 _ERC1155 = 0xd9b67a26;

    constructor() {}

    receive() external payable {}

    /*
        Send ether with the same value by a explicit call method
    */
    function sendEth(address[] calldata _to, uint256 _value) external payable {
        ethSendSameValue(_to, _value);
    }

    /*
        Send ether with the different value by a explicit call method
    */
    function bulksend(address[] calldata _to, uint256[] calldata _value)
        external
        payable
    {
        ethSendDifferentValue(_to, _value);
    }

    function nftSendSameReceiver(
        address[] calldata _tokenContracts,
        uint256[] calldata _tokenIds,
        uint256[] calldata _counts,
        address _to
    ) external {
        if (_tokenContracts.length == 0) revert InvalidLength();
        if (
            _tokenContracts.length != _tokenIds.length ||
            _tokenIds.length != _counts.length
        ) revert InvalidLength();

        ERCBase tokenContract;

        for (uint256 i = 0; i < _tokenContracts.length; i++) {
            tokenContract = ERCBase(_tokenContracts[i]);
            if (!tokenContract.isApprovedForAll(msg.sender, address(this)))
                revert NotApproved();

            if (tokenContract.supportsInterface(_ERC721)) {
                ERC721Partial(_tokenContracts[i]).transferFrom(
                    msg.sender,
                    _to,
                    _tokenIds[i]
                );
            } else {
                ERC1155Partial(_tokenContracts[i]).safeTransferFrom(
                    msg.sender,
                    _to,
                    _tokenIds[i],
                    _counts[i],
                    ""
                );
            }
        }
    }

    function withdraw(address payable _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _receiver.call{value: balance}("");
        if (!success) revert WithdrawFailed();
    }

    function withdrawNft(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] calldata _counts,
        address payable _receiver
    ) external onlyOwner {
        ERCBase tokenContract;

        for (uint256 i = 0; i < _tokenContracts.length; i++) {
            tokenContract = ERCBase(_tokenContracts[i]);

            if (tokenContract.supportsInterface(_ERC721)) {
                ERC721Partial(_tokenContracts[i]).transferFrom(
                    address(this),
                    _receiver,
                    _tokenIds[i]
                );
            } else {
                ERC1155Partial(_tokenContracts[i]).safeTransferFrom(
                    address(this),
                    _receiver,
                    _tokenIds[i],
                    _counts[i],
                    ""
                );
            }
        }
    }

    function nftCheckAllApproval(
        address _from,
        address[] calldata _tokenContracts
    ) external view returns (address[] memory) {
        if (_tokenContracts.length == 0) revert InvalidLength();

        ERCBase tokenContract;
        address[] memory response = new address[](_tokenContracts.length);
        for (uint256 i = 0; i < _tokenContracts.length; i++) {
            tokenContract = ERCBase(_tokenContracts[i]);
            bool isApproved = tokenContract.isApprovedForAll(
                _from,
                address(this)
            );
            if (isApproved == false) {
                response[i] = _tokenContracts[i];
            }
        }
        return response;
    }

    function ethSendSameValue(address[] calldata _to, uint256 _value) internal {
        uint256 sendAmount = _to.length.mul(_value);
        uint256 remainingValue = msg.value;

        if (remainingValue < sendAmount) revert InsufficientValue();
        if (_to.length > 255) revert InvalidLength();

        for (uint8 i = 0; i < _to.length; i++) {
            remainingValue = remainingValue.sub(_value);
            payable(_to[i]).transfer(_value);
        }
    }

    function ethSendDifferentValue(
        address[] calldata _to,
        uint256[] calldata _value
    ) internal {
        uint256 remainingValue = msg.value;

        if (_to.length != _value.length) revert InvalidLength();
        if (_to.length > 255) revert InvalidLength();

        for (uint8 i = 0; i < _to.length; i++) {
            remainingValue = remainingValue.sub(_value[i]);
            payable(_to[i]).transfer(_value[i]);
        }
    }
}