//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721M.sol";
import "./IERC721MCallback.sol";

contract ERC721MCallback is ERC721M, IERC721MCallback {
    CallbackInfo[] private _callbackInfos;
    address[] private _onMintApprovals;

    constructor(
        string memory collectionName,
        string memory collectionSymbol,
        string memory tokenURISuffix,
        uint256 maxMintableSupply,
        uint256 globalWalletLimit,
        address cosigner
    )
        ERC721M(
            collectionName,
            collectionSymbol,
            tokenURISuffix,
            maxMintableSupply,
            globalWalletLimit,
            cosigner
        )
    {}

    function getCallbackInfos() external view returns (CallbackInfo[] memory) {
        return _callbackInfos;
    }

    function getOnMintApprovals() external view returns (address[] memory) {
        return _onMintApprovals;
    }

    function setCallbackInfos(CallbackInfo[] calldata callbackInfos)
        external
        onlyOwner
    {
        uint256 length = _callbackInfos.length;
        for (uint256 i = 0; i < length; i++) {
            _callbackInfos.pop();
        }

        for (uint256 i = 0; i < callbackInfos.length; i++) {
            _callbackInfos.push(callbackInfos[i]);
        }
    }

    function setOnMintApprovals(address[] calldata onMintApprovals)
        external
        onlyOwner
    {
        _onMintApprovals = onMintApprovals;
    }

    function mintWithCallbacks(
        uint32 qty,
        bytes32[] calldata proof,
        uint64 timestamp,
        bytes calldata signature,
        bytes[] calldata callbackDatas
    ) external payable {
        uint256 start = totalSupply();
        _mintInternal(qty, msg.sender, proof, timestamp, signature);
        uint256 end = totalSupply();

        uint256[] memory tokenIds = new uint256[](end - start);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenIds[i] = start + i;
        }

        if (callbackDatas.length != _callbackInfos.length) {
            revert InvalidCallbackDatasLength(
                _callbackInfos.length,
                callbackDatas.length
            );
        }

        for (uint256 i = 0; i < _onMintApprovals.length; i++) {
            if (!isApprovedForAll(msg.sender, _onMintApprovals[i])) {
                setApprovalForAll(_onMintApprovals[i], true);
            }
        }

        for (uint256 i = 0; i < _callbackInfos.length; i++) {
            CallbackInfo memory cbInfo = _callbackInfos[i];
            (bool success, ) = cbInfo.callbackContract.call(
                abi.encodeWithSelector(
                    cbInfo.callbackFunction,
                    msg.sender,
                    tokenIds
                )
            );

            if (!success) {
                revert CallbackFailed(
                    cbInfo.callbackContract,
                    cbInfo.callbackFunction
                );
            }
        }
    }
}