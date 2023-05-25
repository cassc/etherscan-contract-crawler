// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC721A, ERC721A, ERC721ABurnable} from 'erc721a/contracts/extensions/ERC721ABurnable.sol';

/// @title EtherealStatesCore
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
/// @notice EtherealStates Core Logic
contract EtherealStatesCore is
    ERC721A('Ethereal States', 'ESTS'),
    ERC721ABurnable,
    Ownable
{
    error WithdrawError();

    /////////////////////////////////////////////////////////
    // Royalties                                           //
    /////////////////////////////////////////////////////////

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC721A)
        returns (bool)
    {
        return
            interfaceId == this.royaltyInfo.selector ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Royalties - ERC2981
    /// @param tokenId the tokenId
    /// @param amount the amount it's sold for
    /// @return the recipient and amount to send to it
    function royaltyInfo(uint256 tokenId, uint256 amount)
        external
        view
        returns (address, uint256)
    {
        return (owner(), (amount * 5) / 100);
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    /// @notice allows owner to withdraw funds from the contract
    function withdraw(address token) external onlyOwner {
        if (address(0) != token) {
            IERC20(token).transfer(
                msg.sender,
                IERC20(token).balanceOf(address(this))
            );
        } else {
            uint256 balance = address(this).balance;
            if (balance > 0) {
                //solhint-disable-next-line avoid-low-level-calls
                (bool success, ) = msg.sender.call{value: balance}('');
                if (!success) revert WithdrawError();
            }
        }
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}