//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../base/ERC721.sol";

/**
 * @dev ERC721Metadata Extendable contract
 *
 * Constructor arguments take usual `name` and `symbol` arguments for the token
 * with additional extension addresses specifying where the functional logic
 * for each of the token features live which is passed to the Base ERC721 contract
 *
 * Metadata-specific extensions must be extended immediately after deployment by
 * calling the `finaliseERC721MetadataExtending` function.
 *
 */
bytes4 constant ERC721MetadataInterfaceId = 0x5b5e139f;

contract ERC721Metadata is ERC721 {
    constructor(
        string memory name_,
        string memory symbol_,
        address extendLogic,
        address approveLogic,
        address getterLogic,
        address onReceiveLogic,
        address transferLogic,
        address hooksLogic
    ) ERC721(name_, symbol_, extendLogic, approveLogic, getterLogic, onReceiveLogic, transferLogic, hooksLogic) {}

    /**
     * @dev Extends the contract with Metadata-specific functionalities
     *
     * Must be called immediately after contract deployment.
     *
     */
    function finaliseERC721MetadataExtending(
        address metadataGetterLogic,
        address setTokenURILogic,
        address mintLogic,
        address burnLogic
    ) public {
        IExtendLogic self = IExtendLogic(address(this));

        self.extend(metadataGetterLogic);
        self.extend(setTokenURILogic);
        self.extend(mintLogic);
        self.extend(burnLogic);

        IERC165Register(address(this)).registerInterface(ERC721MetadataInterfaceId);
    }
}