// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @entity: Pinaverse
/// @author: Wizard

import "../utils/Administration.sol";

error MaxJuiceSupplyReached();
error MergeNotPermitted();
error MustSetPinaverse();
error NotEnoughofTier();
error TranfserFailed();
error InvalidRequest();

contract JuiceBlenderTier3 is Administration {
    IERC1155 private _juice;

    address private _pinaverse;
    bool private _allowMerge = false;

    constructor(address pinaverse, address juice) Administration(_msgSender()) {
        _pinaverse = pinaverse;
        _juice = IERC1155(juice);
    }

    function getPinaverseAddress() public view returns (address) {
        return _pinaverse;
    }

    function setPinaverse(address pinaverse) external isAdmin {
        _pinaverse = pinaverse;
    }

    function toggleAllowMerge() external isAdmin {
        _allowMerge = !_allowMerge;
    }

    function allowMerge() public view returns (bool) {
        return _allowMerge;
    }

    function mergeTier3(address account, uint256 value) public whenNotPaused {
        if (!_allowMerge) revert MergeNotPermitted();
        if (_pinaverse == address(0)) revert MustSetPinaverse();

        uint256 preBalance = _juice.balanceOf(account, 2);
        uint256 eligibleToMint = value / 3;
        uint256 amountToTransfer = eligibleToMint * 3;

        // Verify balance
        if (preBalance < value) revert NotEnoughofTier();

        // Verify user can mint at least 1
        if (eligibleToMint == 0) revert InvalidRequest();

        unchecked {
            // Verify Tier 4 is still mintable
            if (_juice.totalMinted(3) + eligibleToMint > 3) {
                revert MaxJuiceSupplyReached();
            }
        }

        // Transfer Tier 3 NFTs to Pinaverse
        _juice.safeTransferFrom(account, _pinaverse, 2, amountToTransfer, "");

        unchecked {
            // Verify balance after transfer is less value
            if (_juice.balanceOf(account, 2) != preBalance - amountToTransfer) {
                revert TranfserFailed();
            }
        }

        // Mint eligible Tier 4 NFTs
        _juice.mint(account, 3, eligibleToMint);
    }

    function withdraw() external isAdmin {
        if (_pinaverse == address(0)) revert MustSetPinaverse();
        payable(_pinaverse).transfer(address(this).balance);
    }

    function withdrawToken(address token) external isAdmin {
        if (_pinaverse == address(0)) revert MustSetPinaverse();
        IERC20 erc20 = IERC20(token);
        erc20.transfer(_pinaverse, erc20.balanceOf(address(this)));
    }
}

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function totalMinted(uint256 id) external view returns (uint256);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}