// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './3FACEBase.sol';
import './3FACESplits.sol';

/**
 * @title THREEFACE
 *                                                                           ▄▄▀▀▀▀█
 *                                          ▄▄▄▄▄▄                 ▄▄▄▄▄▄▄▀▀      ▐▌
 *                                   ▄▄▄▄▓▀▀      █              ▄▀              ▄█▌
 *                                 ▄▀           ▄▄▀             █          ▄▄▄████
 *                                ▓      ▄██████▀              █     ▄▄██████▀▀   ▄▄█▀▀▀▀▀▓
 *                ▄▄▄▄▄▄▄▄▄▄▄▄▄   ▓     ▓██                   ▐▌    ███▀▀   ▄▄▀▀▀▀        ██
 *          ▄▄▀▀▀▀             █  ▐▌    ██▌                   ▐    ██    ▄▀              ▄█
 *       ▐▀                    ██ ▐▌    ██▌                   █   ██    ▓     ▄▄▄█████▀▀▀▀
 *       ▐         ▄▄▄█████    ██ ▐     ██▌                  ▐▌  ▐█▌    █    ▐██
 *       ▐▌   █████▀▀▀▀▀▀▀▀▌   ██ ▓     ██▌                  ▐   ██    ▐▌    ▓█▌
 *        ▌  ▓█▌           ▌   ██ ▐▌   ▐██                   █  ██     ▐▌    ██
 *         ▀▀▀▀            ▌  ▐██ ▐▌  ▐█▀  ▄▄▄▄              ▌ ▐█▌     ▐▌   ▐█▌ ▄▄▓▀▀▀▄
 *                        ▐▌  ▐██ ▐   ▀▀▀▀▀   ▌             ▐▌ ▓█      ▐     ▀▀▀     ▄▌
 *                       ▄▀   ▄█▌ █       ▄▄▄█              ▐  █▌      █   ▄▄▄▄▄▄▄████
 *            ▄▀  ▀▄ ▄▄▀▀   ▄██   ▌    ███▀▀▀ ▄▄▀▀▀▀▀▀▀▄    █  █▌     █    ██▀▀▀▀▀▀▀
 *           ▐              ▀███  ▌   ██    ▐▌   ▄▄▄   ▐   ▐  ▐█     ▐    ▐█▌
 *           █      ▄▄▄██     ██  ▌  ▐██    █   ██  █  ▐   ▌  ██     █    ▐█      ▄▄▀▀▀▀▀█
 *             ▀▀▀███▀▀ █▌   ▐██  ▌  ██▌    ▌   ▀▀▀▀▀  ▐▌ ▐▌  █▌    ▐▌     ▀▀▀▀▀▀      ▄██
 *         ▄▄▄          █    ██  ▓   ██    ▐▌  ▄█████▄ ▐  ▐   █▌    ▓             ▄████▀
 *        █  ▐      ▄▄▀▀    ██  ▐▌  ▐█▌     ▌ ▐█▌   ▐█ █  ▐   ▓▌    ▀▀████▄▄▄▄▄███▀
 *       ▐    ▀▀▀▀▀▀       ██   █   ██      █▄██     ██▌  ▐   ▐▌          ▀▀▀▀▀▀▀
 *       ▐            ▄▄▄███▀  ▓    ██                    ▐    █      ▄▄▄▄▄▄▄▄▄
 *        ▀▄▄▄▄▄██████▀▀▀     ▄▀   ▐█▌                     ▀▄   ▀▀▀▀▀▀         █▄
 *                          ▄█    ▄██                       ▀████▄▄▄▄▄▄▄▄▄▄▄▄▄██
 *                  ▄▀▀▀▀▀▀    ▄███▀                                  ▀▀▀▀▀▀▀▀
 *               ▄▓▀        ▄███▀
 *               ▌▄▄▄██████▀▀▀
 */
contract THREEFACE is THREEFACESplits, THREEFACEBase {
    constructor()
        THREEFACEBase(
            'THREEFACE',
            '3FACE',
            'https://3face.mypinata.cloud/ipfs/',
            addresses,
            splits,
            0.2 ether,
            0.1 ether,
            0.5 ether,
            0.003 ether
        )
    {
        // Implementation version: V1

        uint256[] memory natures = new uint256[](4);
        natures[0] = 100;
        natures[1] = 101;
        natures[2] = 102;
        natures[3] = 103;

        string[] memory natureFragments = new string[](4);
        natureFragments[0] = 'Qma8y8nhUJNymNd8b2w778cgGFdpsJWm6du75DSxc536BG'; // Change
        natureFragments[1] = 'QmT89zqM4SzCuow6LaZXSfs8PXMHAE88FJL2KjXQgfbDc4'; // Structure
        natureFragments[2] = 'QmTLpKhNduGRdDFhAZQJM6dP16SYabmib4YSN4tBoEuBEo'; // Belonging
        natureFragments[3] = 'QmUgGcKnGTYXEhoJx6pjTNQUDhbzQmoj1VB9fXPg7Ty5R9'; // Transcendence

        _setNatureFragments(natures, natureFragments);
    }
}