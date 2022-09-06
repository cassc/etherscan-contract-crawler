// SPDX-License-Identifier: MIT

// NiftyMoves (Gas efficient batch ERC721 transfer)

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NiftyMoves {
    /**
     *
     * @dev constructor: no args
     *
     */
    constructor() {}

    /**
     *
     * @dev makeNiftyMoves: function call for transfers:
     *
     */
    function makeNiftyMoves(
        address contract_,
        address to_,
        uint256[] memory tokenIds_
    ) external {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            IERC721(contract_).transferFrom(msg.sender, to_, tokenIds_[i]);
        }
    }

    /**
     *
     * @dev Do not receive Eth or function calls:
     *
     */
    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }
}