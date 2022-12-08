// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable2Step} from "./openzeppelin/Ownable2Step.sol";
import {IERC20} from "./openzeppelin/interfaces/IERC20.sol";
import {IERC721} from "./openzeppelin/interfaces/IERC721.sol";
import {IERC1155} from "./openzeppelin/interfaces/IERC1155.sol";
import {Sweep} from "./Structs.sol";

/// @notice Emergency functions: In case supported asset get stuck in the contract unintentionally
/// @dev Only owner can call
abstract contract Recoverable is Ownable2Step {
    /// @dev ETH
    function rescueETH(address recipient) external onlyOwner {
        assembly {
            let callStatus := call(gas(), recipient, selfbalance(), 0, 0, 0, 0)
        }
    }

    /// @dev ERC20
    function rescueERC20(address asset, address recipient) external onlyOwner {
        uint256 amount = IERC20(asset).balanceOf(address(this));
        // don't use SafeERC20, no need to check return value
        IERC20(asset).transfer(recipient, amount);
    }

    /// @dev ERC721
    function rescueERC721(
        Sweep.ERC721Detail calldata erc721Detail,
        address recipient
    ) external onlyOwner {
        for (uint256 i; i < erc721Detail.ids.length; i++) {
            IERC721(erc721Detail.tokenAddr).safeTransferFrom(
                address(this),
                recipient,
                erc721Detail.ids[i]
            );
        }
    }

    /// @dev ERC1155
    function rescueERC1155(
        Sweep.ERC1155Detail calldata erc1155Detail,
        address recipient
    ) external onlyOwner {
        for (uint256 i; i < erc1155Detail.ids.length; i++) {
            IERC1155(erc1155Detail.tokenAddr).safeTransferFrom(
                address(this),
                recipient,
                erc1155Detail.ids[i],
                erc1155Detail.amounts[i],
                ""
            );
        }
    }

    /// @dev CryptoPunksMarket
    function rescueCryptoPunk(
        address punk,
        uint256 punkIndex,
        address recipient
    ) external onlyOwner {
        punk.call(
            abi.encodeWithSignature(
                "transferPunk(address,uint256)",
                recipient,
                punkIndex
            )
        );
    }
}