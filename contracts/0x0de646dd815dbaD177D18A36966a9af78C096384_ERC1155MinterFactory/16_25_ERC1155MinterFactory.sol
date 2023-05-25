// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ERC1155Minter.sol";
import "./utils/ForjFactoryEvents.sol";

contract ERC1155MinterFactory is ForjFactoryEvents {
    function createTemplate(
        string memory _baseURI,
        string memory _name,
        string memory _symbol,
        address _admin,
        address _multisig,
        address _treasuryWallet
    ) external {
        ERC1155Minter clone = new ERC1155Minter();
        clone.initialise(_baseURI, _name, _symbol, _admin, _multisig, _treasuryWallet);
        clone.transferOwnership(_admin);
        emit TemplateCreated(address(clone), "ERC1155Minter");
    }
}