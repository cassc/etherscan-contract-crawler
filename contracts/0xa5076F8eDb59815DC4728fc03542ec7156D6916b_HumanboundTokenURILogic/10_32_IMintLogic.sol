//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@violetprotocol/extendable/extensions/Extension.sol";

// Functional logic extracted from openZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol

// This contract should be inherited by your own custom `mint` logic which makes a call to `_mint` or `_safeMint`
interface IMintLogic {
    /**
     * @dev Creates `tokenId` and assigns ownership to `to`.
     *
     * Emits a {Transfer} event.
     */
    function mint(address to, uint256 amount) external;
}

abstract contract MintExtension is IMintLogic, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return "function mint(address to, uint256 amount) external;\n";
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](1);
        functions[0] = IMintLogic.mint.selector;

        interfaces[0] = Interface(type(IMintLogic).interfaceId, functions);
    }
}