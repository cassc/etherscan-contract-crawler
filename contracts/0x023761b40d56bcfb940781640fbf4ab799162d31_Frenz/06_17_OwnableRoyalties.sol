// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./protocols/IRaribleRoyalties.sol";
import "./protocols/IERC2981.sol";

/**
 * @title Royalties Contract
 * Royalties spec via IERC2981
 */
abstract contract OwnableRoyalties is Ownable, IRaribleRoyalties, IERC2981 {
    // Superplastic is the owner/recipeint of royalties
    address payable private _recipeint;

    // Royality fee BPS (1/100ths of a percent, eg 1000 = 10%)
    uint16 private immutable _feeBps = 500;

    constructor() {
        _recipeint = payable(msg.sender);
    }

    function setRoyaltyOwner(address payable _royal) public onlyOwner {
        require(
            owner() == _msgSender(),
            "You are not the owner and can't set the royalties"
        );
        _recipeint = _royal;
    }

    // rarible royalties
    function getFeeRecipients(uint256 tokenId)
        public
        view
        override
        returns (address payable[] memory)
    {
        address payable[] memory ret = new address payable[](1);
        ret[0] = payable(_recipeint);
        return ret;
    }

    // rarible royalties
    function getFeeBps(uint256 tokenId)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory ret = new uint256[](1);
        ret[0] = uint256(_feeBps);
        return ret;
    }

    // ---
    // More royalities (mintable?) / EIP-2981
    // ---
    function royaltyInfo(uint256 tokenId)
        external
        view
        override
        returns (address receiver, uint256 amount)
    {
        return (_recipeint, uint256(_feeBps) * 100);
    }

    function emitRaribleInfo(uint256 jankyId) public virtual {
        // Emit rarible royalty info
        address[] memory recipients = new address[](1);
        recipients[0] = _recipeint;
        emit SecondarySaleFees(jankyId, recipients, getFeeBps(jankyId));
    }
}