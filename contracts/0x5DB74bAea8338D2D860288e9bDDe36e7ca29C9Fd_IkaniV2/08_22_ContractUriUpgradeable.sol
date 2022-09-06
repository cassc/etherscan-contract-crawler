// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { Initializable } from "../../../deps/Initializable.sol";

/**
 * @title ContractUriUpgradeable
 * @author Cyborg Labs, LLC
 *
 * @dev Simple base contract supporting the contractURI() function used by OpenSea.
 */
abstract contract ContractUriUpgradeable is
    Initializable
{
    string private _CONTRACT_URI_;

    uint256[49] private __gap;

    event SetContractUri(
        string contractUri
    );

    function __ContractUri_init()
        internal
        onlyInitializing
    {}

    function __ContractUri_init_unchained()
        internal
        onlyInitializing
    {}

    function contractURI()
        external
        view
        returns (string memory)
    {
        return _CONTRACT_URI_;
    }

    function _setContractUri(
        string memory contractUri
    )
        internal
    {
        _CONTRACT_URI_ = contractUri;
        emit SetContractUri(contractUri);
    }
}