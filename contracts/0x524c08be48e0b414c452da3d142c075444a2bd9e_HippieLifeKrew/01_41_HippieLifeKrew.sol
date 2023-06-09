/**
 * SPDX-License-Identifier: Apache-2.0
 * @title: Hippie Life Krew: The Cloudalia Story
 * @author: BankkRoll - https://twitter.com/bankkroll_eth
 * @founder: Visto - https://twitter.com/VistoHLK
 * @artist : Taylor - https://twitter.com/TheEmperorTay
 *
 *                                                              ▒▒████████▒▒░░
 *                                ░░                      ▒▒▓▓░░            ░░▒▒██
 *                      ▒▒██▓▓▒▒░░░░▒▒▓▓▓▓            ░░██                        ▒▒▓▓
 *                      ░░▓▓░░            ▒▒██      ▒▒▒▒                              ▓▓
 *                    ▓▓▓▓                    ██  ░░▓▓                                ░░▓▓
 *                  ▒▒▒▒                      ░░████                                    ▓▓
 *                ▒▒▒▒                          ░░▓▓                                      ██
 *               ▓▓                                                                       ▒▒  ▒▒
 *              ▒▒     ██     ██ ███████ ██       ██████  ██████  ███    ███ ███████      ▓▓██▒▒░░▓▓▒▒
 *            ▒▒░░     ██     ██ ██      ██      ██      ██    ██ ████  ████ ██           ▓▓        ░░▓▓
 *            ▒▒       ██  █  ██ █████   ██      ██      ██    ██ ██ ████ ██ █████        ░░           ▓▓
 *            ░░░░     ██ ███ ██ ██      ██      ██      ██    ██ ██  ██  ██ ██                      ▒▒░░
 *           ▒█         ███ ███  ███████ ███████  ██████  ██████  ██      ██ ███████                  ▓▓
 *        ▒▒██                                                                                        ▒▒
 *      ██░░                   ██   ██ ██ ██████  ██████  ██ ███████ ███████                         ████
 *    ██                       ██   ██ ██ ██   ██ ██   ██ ██ ██      ██                               ▒ ▒
 *    ░░                       ███████ ██ ██████  ██████  ██ █████   ███████                           ░░
 *   ▒▒                        ██   ██ ██ ██      ██      ██ ██           ██                           ░░██
 *   ▓▓                        ██   ██ ██ ██      ██      ██ ███████ ███████                              ██
 *   ▓▓                                                                                                    ▓▓
 *  ▓▓▓▓                                      ▄▄▄██████████▄▄▄                                              ░░
 *  ▓▓                                      ▄██████▀████▀██████▄                                           ▓▓
 *   ▓▓                                   ▄████▀    ████    ▀████▄                                         ▓▓
 *  ▒▒                                   ████▀      ████     ▄█████                                        ░░░░
 *  ▓▓                                  ████        ████  ▄█████▀███                                       ▓▓░░
 *  ▓▓                                 ▐███         █████████▀   ████                                       ▓▓
 *  ▓▓                                 ██████████████████████████████                                      ▓▓
 *  ▒▒                                 ████▀▀▀▀▀▀▀▀▀████████▀▀▀▀▀████                                     ▒▒▒▒
 *  ▓▓                                 ▐███         ████▀█████▄  ███▌                                     ██
 *   ▓▓▒                                ▀███        ████   ▀████████                                     ▒██
 *  ▒▒▓▓                                 ▀███▄      ████      ████▀                                        ▒▒
 *     ▓▓                                  ▀████▄▄  ████   ▄█████                                         ▓▓
 *      ▒▒                                   ▀▀███████████████▀                                          ▒▒
 *      ▒▒▓▓                                     ▀▀▀▀▀▀▀▀▀▀▀                                           ▒▒█
 *        ░█▓▓▒▒░░░░▒▒▓█▓▓▓                                                                ██░░░█▓▒░▒▒▓█
 *                     ▒██▒▒▒▒████░░█▓▓▒▒░░░░▒▒▓█▓▓▒▒░░░░▒▒▓░▒▒▓▓███▓▓▒▒░░░░▒▒▓░▓▓██▓▓▒▒▒▒▓▓▓▓▓▓▓
 */
pragma solidity ^0.8.0;

//  @author thirdweb
import "@thirdweb-dev/contracts/base/ERC721Drop.sol";

contract HippieLifeKrew is ERC721Drop {
    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    )
        ERC721Drop(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {}

    /**
    *  @dev Overrides '_startTokenId()' from ERC721Drop.
    *  Starts token ID count from 1 instead of 0.
    *  @return uint256 - The initial token ID.
    */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}