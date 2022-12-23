// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * TokenFacetLib authored by Sibling Labs
 * Version 1.0.0
 * 
 * This library is designed to work in conjunction with
 * TokenFacet - it facilitates diamond storage and shared
 * functionality associated with TokenFacet.
/**************************************************************/

library TokenFacetLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("tokenfacet.storage");

    struct state {
        mapping(address => uint8) minted;
        uint256 timestamp;
    }

    /**
    * @dev Return stored state struct.
    */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }
}

/**************************************************************\
 * TokenFacet authored by Sibling Labs
 * Version 1.0.0
 * 
 * As part of KOREAN-SANTA Diamond
/**************************************************************/

import { GlobalState } from "../libraries/GlobalState.sol";
import { ERC1155, ERC1155Lib } from "../ancillary/ERC1155DiamondStorage.sol";

contract TokenFacet is ERC1155 {

    // VARIABLE GETTERS //

    function minted(address addr) external view returns (bool) {
        return TokenFacetLib.getState().minted[addr] == 1;
    }

    // SETUP & ADMIN FUNCTIONS //

    modifier restrict {
        GlobalState.requireCallerIsAdmin();
        _;
    }

    function reserve(address account, uint256 amount) external restrict {
        super._mint(account, 0, amount, "");
    }

    function setUri(string memory u) external restrict {
        ERC1155Lib.getState()._uri = u;
    }

    function beginMintingPhase() external restrict {
        TokenFacetLib.getState().timestamp = block.timestamp;
    }

    // PUBLIC FUNCTIONS //

    function mint() external {
        TokenFacetLib.state storage s = TokenFacetLib.getState();

        require(
            block.timestamp != 0 &&
            block.timestamp <= s.timestamp + 86400,
            "TokenFacet: minting is not available now"
        );
        require(
            s.minted[msg.sender] == 0,
            "TokenFacet: this address has already minted"
        );

        _mint(msg.sender, 0, 1, "");
        s.minted[msg.sender] = 1;
    }

    // METADATA & MISC FUNCTIONS //

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        if (from != address(0)) GlobalState.requireCallerIsAdmin();
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

}