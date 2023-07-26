// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/Structs.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/LibPlexusUtil.sol";
import "../libraries/LibData.sol";
import "../Helpers/Signers.sol";
import "../Helpers/VerifySigEIP712.sol";
import "hardhat/console.sol";

contract SwapFacet is Signers, VerifySigEIP712 {
    using SafeERC20 for IERC20;

    function addDex(address[] calldata _dex) public {
        require(msg.sender == LibDiamond.contractOwner());
        Dex storage s = LibPlexusUtil.getSwapStorage();

        uint256 len = _dex.length;

        for (uint256 i; i < len; ) {
            if (_dex[i] == address(0)) {
                revert();
            }
            s.allowedDex[_dex[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function removeDex(address[] calldata _dex) public {
        require(msg.sender == LibDiamond.contractOwner());
        Dex storage s = LibPlexusUtil.getSwapStorage();

        uint256 len = _dex.length;

        for (uint256 i; i < len; ) {
            if (_dex[i] == address(0)) {
                revert();
            }
            s.allowedDex[_dex[i]] = false;
            unchecked {
                ++i;
            }
        }
    }

    function setProxy(address _dex, address proxy) public {
        require(msg.sender == LibDiamond.contractOwner());
        Dex storage s = LibPlexusUtil.getSwapStorage();
        s.proxy[_dex] = proxy;
    }

    function swapRouter(SwapData calldata _swap) external payable {
        uint256 dstAmount = LibPlexusUtil._tokenDepositAndSwap(_swap);
        bool isNotNative = !LibPlexusUtil._isNative(_swap.dstToken);
        if (isNotNative) {
            IERC20(_swap.dstToken).safeTransfer(msg.sender, dstAmount);
        } else {
            LibPlexusUtil._safeNativeTransfer(msg.sender, dstAmount);
        }
    }

    function getProxy(address _dex) external view returns (address) {
        Dex storage s = LibPlexusUtil.getSwapStorage();
        address proxy = s.proxy[_dex];
        return proxy;
    }

    function viewSigner(uint256 index) external view returns (address) {
        SigData storage s = sigDataStorage();
        return s.signerList[index];
    }

    function setSigner(address[] memory _signer) public {
        SigData storage s = sigDataStorage();
        require(msg.sender == LibDiamond.contractOwner());
        for (uint256 i = 0; i < _signer.length; i++) {
            s.signerList.push(_signer[i]);
        }
    }

    function relaySwapRouter(SwapData calldata _swap, Input calldata _sigCollect, bytes[] calldata signature) external {
        address owner = LibDiamond.contractOwner();
        require(msg.sender == owner);
        require(
            _sigCollect.userAddress == _swap.user &&
                _sigCollect.amount - _sigCollect.gasFee == _swap.amount &&
                _sigCollect.toTokenAddress == _swap.dstToken
        );
        relaySig(_sigCollect, signature);
        bool isNotNative = !LibPlexusUtil._isNative(_sigCollect.fromTokenAddress);
        if (isNotNative) {
            if (_sigCollect.gasFee > 0) IERC20(_sigCollect.fromTokenAddress).safeTransfer(owner, _sigCollect.gasFee);
        } else {
            if (_sigCollect.gasFee > 0) LibPlexusUtil._safeNativeTransfer(owner, _sigCollect.gasFee);
        }
        uint256 dstAmount = LibPlexusUtil._swapStart(_swap);

        dstAmount = LibPlexusUtil._fee(_swap.dstToken, dstAmount);

        isNotNative = !LibPlexusUtil._isNative(_swap.dstToken);
        if (isNotNative) {
            IERC20(_swap.dstToken).safeTransfer(_swap.user, dstAmount);
        } else {
            LibPlexusUtil._safeNativeTransfer(_swap.user, dstAmount);
        }
        emit LibData.Relayswap(_sigCollect.userAddress, _sigCollect.toTokenAddress, dstAmount);
    }
}