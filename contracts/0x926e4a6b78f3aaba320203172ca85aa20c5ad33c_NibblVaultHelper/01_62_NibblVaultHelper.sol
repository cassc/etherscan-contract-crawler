// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {NibblVault3} from "./NibblVault3.sol";
import {ERC1155Link} from "./ERC1155Link.sol";

contract NibblVaultHelper {
    function wrapNativeToERC1155(
        address payable _vault,
        address _link,
        address _to,
        uint256 _minERC20Out,
        uint256 _amtERC1155,
        uint256 _tokenID
    ) external payable {
        uint256 _out = NibblVault3(_vault).buy{value: msg.value}(_minERC20Out, address(this));

        if (NibblVault3(_vault).allowance(address(this), _link) < _out) {
            NibblVault3(_vault).approve(_link, type(uint256).max);
        }
        ERC1155Link(_link).wrap(_amtERC1155, _tokenID, _to);
        NibblVault3(_vault).transfer(_to, NibblVault3(_vault).balanceOf(address(this)));
    }

    function unwrapERC1155ToNative(
        address payable _vault,
        address _link,
        address payable _to,
        uint256 _minNativeOut,
        uint256 _tokenID,
        uint256 _amt
    ) external {
        ERC1155Link(_link).safeTransferFrom(msg.sender, address(this), _tokenID, _amt, "0x");
        ERC1155Link(_link).unwrap(_amt, _tokenID, address(this));
        NibblVault3(_vault).sell(NibblVault3(_vault).balanceOf(address(this)), _minNativeOut, _to);
    }

    function redeemEditionForNative(ERC1155Link _link, NibblVault3 _vault, uint256 _tokenID, address payable _to)
        external
    {
        _link.safeTransferFrom(msg.sender, address(this), _tokenID, _link.balanceOf(msg.sender, _tokenID), "0x");
        _link.unwrap(_link.balanceOf(address(this), _tokenID), _tokenID, address(this));
        _vault.redeem(_to);
    }

    function redeemMultipleEditionsForNative(
        ERC1155Link _link,
        NibblVault3 _vault,
        uint256[] calldata _tokenIDs,
        address payable _to
    ) external {
        uint256 _len = _tokenIDs.length;
        for (uint256 index = 0; index < _len; index++) {
            _link.safeTransferFrom(
                msg.sender, address(this), _tokenIDs[index], _link.balanceOf(msg.sender, _tokenIDs[index]), "0x"
            );
            _link.unwrap(_link.balanceOf(address(this), _tokenIDs[index]), _tokenIDs[index], address(this));
            _vault.redeem(_to);
        }
    }

    function setMaxApproval(address payable _vault, address _link) external {
        NibblVault3(_vault).approve(_link, type(uint256).max);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}