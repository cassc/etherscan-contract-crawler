// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ForjERC1155} from "contracts/utils/ForjERC1155.sol";

contract ERC1155Minter is ForjERC1155 {

    function initialise(
        string memory _baseURI,
        string memory _name,
        string memory _symbol,
        address _admin,
        address _multisig,
        address _treasuryWallet
    ) public onlyAdminOrOwner(msg.sender){
        _erc1155Initializer(_baseURI, _name, _symbol);
        _treasuryInitialize(_admin, _multisig, _treasuryWallet);
    }

    function bulkMint(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address[] memory mintAddresses
    )
    external
    onlyAdminOrOwner(msg.sender)
    {
        require(
            amounts.length == mintAddresses.length,
            "Exception: argument array count mismatch"
        );
        require(
            amounts.length == tokenIds.length,
            "Exception: argument array count mismatch"
        );
        for (uint256 i = 0; i < mintAddresses.length; i++) {
            address addr = mintAddresses[i];
            _mint(addr, tokenIds[i], amounts[i], "");
        }
    }
}