// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 *
 * _______/\\\\\_______/\\\\\\\\\\\\\____/\\\\\\\\\\\\\\\__/\\\\\_____/\\\_____/\\\\\\\\\\__
 *  _____/\\\///\\\____\/\\\/////////\\\_\/\\\///////////__\/\\\\\\___\/\\\___/\\\///////\\\_
 *   ___/\\\/__\///\\\__\/\\\_______\/\\\_\/\\\_____________\/\\\/\\\__\/\\\__\///______/\\\__
 *    __/\\\______\//\\\_\/\\\\\\\\\\\\\/__\/\\\\\\\\\\\_____\/\\\//\\\_\/\\\_________/\\\//___
 *     _\/\\\_______\/\\\_\/\\\/////////____\/\\\///////______\/\\\\//\\\\/\\\________\////\\\__
 *      _\//\\\______/\\\__\/\\\_____________\/\\\_____________\/\\\_\//\\\/\\\___________\//\\\_
 *       __\///\\\__/\\\____\/\\\_____________\/\\\_____________\/\\\__\//\\\\\\__/\\\______/\\\__
 *        ____\///\\\\\/_____\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\___\//\\\\\_\///\\\\\\\\\/___
 *         ______\/////_______\///______________\///////////////__\///_____\/////____\/////////_____
 *          BASE_TOKEN_______________________________________________________________________________
 *
 */

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "contracts/Mixins/ActivatableV1.sol";
import "contracts/Mixins/DistributableV1.sol";
import "contracts/Mixins/ContractURIV2.sol";

contract BaseTokenV2 is ActivatableV1, ContractURIV2, ReentrancyGuard {
    event PaymentReceived(address from, uint256 amount);

    constructor(string memory contractURI_) ContractURIV2(contractURI_) {}

    /** PAYABLE **/

    /**
     * @dev Allows the contract to receive ether.
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }
}