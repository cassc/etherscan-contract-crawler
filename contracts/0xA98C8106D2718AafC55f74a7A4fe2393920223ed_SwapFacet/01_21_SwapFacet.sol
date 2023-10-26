// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/Structs.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/LibPlexusUtil.sol";
import "../libraries/LibData.sol";
import "../Helpers/Signers.sol";
import "../Helpers/VerifySigEIP712.sol";
import "../Helpers/ReentrancyGuard.sol";

contract SwapFacet is Signers, VerifySigEIP712, ReentrancyGuard {
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

    function swapRouter(SwapData calldata _swap) external payable nonReentrant {
        uint256[] memory dstAmount = new uint256[](_swap.output.length);
        dstAmount = LibPlexusUtil._tokenDepositAndSwap(_swap);
        for (uint i = 0; i < _swap.output.length; i++) {
            bool isNotNative = !LibPlexusUtil._isNative(_swap.output[i].dstToken);
            if (isNotNative) {
                IERC20(_swap.output[i].dstToken).safeTransfer(_swap.user, dstAmount[i]);
            } else {
                LibPlexusUtil._safeNativeTransfer(_swap.user, dstAmount[i]);
            }
        }
        emit LibData.Swap(_swap.user, _swap.input, _swap.output, dstAmount, _swap.plexusData);
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

    function relaySwapRouter(
        RelaySwapData calldata _relay,
        Input calldata _sigCollect,
        bytes[] calldata signature,
        bytes calldata _plexusData
    ) external {
        SigData storage s = sigDataStorage();
        address owner = LibDiamond.contractOwner();
        SwapData calldata swap = _relay.swapData;
        require(msg.sender == owner);
        require(_sigCollect.userAddress == swap.user);
        relaySig(_sigCollect, signature);
        s.txHashCheck[_sigCollect.txHash] = true;
        bool isNotNative = !LibPlexusUtil._isNative(_relay.feeTokenAddress);
        if (isNotNative) {
            if (_sigCollect.gasFee > 0) IERC20(_relay.feeTokenAddress).safeTransfer(owner, _sigCollect.gasFee);
            if (_sigCollect.transferFee > 0) IERC20(_relay.feeTokenAddress).safeTransfer(owner, _sigCollect.transferFee);
        } else {
            if (_sigCollect.gasFee > 0) LibPlexusUtil._safeNativeTransfer(owner, _sigCollect.gasFee);
            if (_sigCollect.transferFee > 0) LibPlexusUtil._safeNativeTransfer(owner, _sigCollect.transferFee);
        }
        uint256[] memory dstAmount = new uint256[](swap.output.length);
        dstAmount = LibPlexusUtil._swapStart(swap);

        for (uint256 i = 0; i < swap.output.length; i++) {
            bool isNotNative = !LibPlexusUtil._isNative(swap.output[i].dstToken);
            if (isNotNative) {
                IERC20(swap.output[i].dstToken).safeTransfer(swap.user, dstAmount[i]);
            } else {
                LibPlexusUtil._safeNativeTransfer(swap.user, dstAmount[i]);
            }
        }

        for (uint256 i = 0; i < swap.dup.length; i++) {
            if (swap.dup[i].token != address(0)) {
                bool isNotNative = !LibPlexusUtil._isNative(swap.dup[i].token);
                if (isNotNative) {
                    IERC20(swap.dup[i].token).safeTransfer(swap.user, swap.dup[i].amount);
                } else {
                    LibPlexusUtil._safeNativeTransfer(swap.user, swap.dup[i].amount);
                }
            }
        }

        emit LibData.Relayswap(_sigCollect.userAddress, swap.output, dstAmount, _plexusData);
    }
}