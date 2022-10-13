// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/erc721extendable/contracts/extensions/base/mint/Mint.sol";

interface IHumanboundMintLogic {
    event Minted(address indexed to, uint256 indexed tokenId);

    function mint(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry,
        address to,
        uint256 tokenId,
        string calldata tokenURI
    ) external;
}

abstract contract HumanboundMintExtension is IHumanboundMintLogic, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return "function mint(uint8 v, bytes32 r, bytes32 s, uint256 expiry, address to, uint256 tokenId) external;\n";
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](1);
        functions[0] = IHumanboundMintLogic.mint.selector;

        interfaces[0] = Interface(type(IHumanboundMintLogic).interfaceId, functions);
    }
}