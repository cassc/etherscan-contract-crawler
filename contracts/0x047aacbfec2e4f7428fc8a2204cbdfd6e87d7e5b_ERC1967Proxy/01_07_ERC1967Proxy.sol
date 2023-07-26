//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//    _____/\\\\\\\\\\\____/\\\___________________/\\\\\_______/\\\\\\\\\\\__/\\\________/\\\_____/\\\\\\\\\____            //
//     ___/\\\/////////\\\_\/\\\_________________/\\\///\\\____\/////\\\///__\/\\\_____/\\\//____/\\\\\\\\\\\\\__           //
//      __\//\\\______\///__\/\\\_______________/\\\/__\///\\\______\/\\\_____\/\\\__/\\\//______/\\\/////////\\\_          //
//       ___\////\\\_________\/\\\______________/\\\______\//\\\_____\/\\\_____\/\\\\\\//\\\_____\/\\\_______\/\\\_         //
//        ______\////\\\______\/\\\_____________\/\\\_______\/\\\_____\/\\\_____\/\\\//_\//\\\____\/\\\\\\\\\\\\\\\_        //
//         _________\////\\\___\/\\\_____________\//\\\______/\\\______\/\\\_____\/\\\____\//\\\___\/\\\/////////\\\_       //
//          __/\\\______\//\\\__\/\\\______________\///\\\__/\\\________\/\\\_____\/\\\_____\//\\\__\/\\\_______\/\\\_      //
//           _\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\///\\\\\/______/\\\\\\\\\\\_\/\\\______\//\\\_\/\\\_______\/\\\_     //
//            ___\///////////_____\///////////////_______\/////_______\///////////__\///________\///__\///________\///__    //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
// sloika.xyz
// Sloika is a photo NFT marketplace dedicated to arming photographers with tools for the digital renaissance.
//
//
//
// Building with Sloika contracts? Reach out to us at: [email protected]
// Sloika is hiring: https://sloika.xyz/careers
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//
//
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}