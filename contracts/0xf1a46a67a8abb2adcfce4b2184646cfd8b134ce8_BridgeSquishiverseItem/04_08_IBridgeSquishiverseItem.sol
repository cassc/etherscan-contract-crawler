// Squishiverse by FourLeafClover (www.squishiverse.com) - Bridge Squishiverse Item Interface

// MMMMMW0dxxxdkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMM0cdKNNKloXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMKolk00kloXMWNK0KKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMXkxxddkXWKdoddxxxxkOKXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMWWMMMXllO000KKKOkxxxxkkkkkkkkkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMKccO000000KKXNNNNNNNXXXK0OkkkkkkOKNMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMN0xocck0000000000KKKKXXXNNNNWWWWNX0kkkkOKWMMMMMMMMMMMMMMMMM
// MMMMMMMMWXkoodkOOO00000000000000000000KKXXNNWWWMWXOxxk0NMMMMMMMMMMMMMM
// MMMMMMWKxlokO000000000000000000000000000000KXWMMMMMMN0kxkKWMMMMMMMMMMM
// MMMMMXxlok0000000000000000000000000000000000KNMMMMMMMMMN0xxONMMMMMMMMM
// MMMW0ook0000000000000000000000000000000000000XWMMMMMMMMMMWKxdONMMMMMMM
// MMWkldO000000000000000000000000000000000000000KXNWMMWNNWMMMWKxd0WMMMMM
// MNxcx00000000000000000000000000000000000000000000KXOc,':ONWWMW0dkNMMMM
// Wkcd0000000000000000Oo;,:dO00000000000000000000000d.    .oXWWMMXxdKMMM
// KloO000000000000000k;    .:k000000000000000000000O:    ;'.dNNWWMNxoKMM
// dck000000000000000Oc    '..lO00000000000000000000O:       ;KNNWWMNxoXM
// lo0000000000000000x'   .:;.;k00000000000000000000Ol.      'ONNNWWMXdxN
// cd0000000000000000x'       ,k000000000000000000000x'      .xNNNNWWM0o0
// cd0000000000000000x'       ;O000000000000000000000Oo.     ;kXNNNNWMNdd
// cd0000000000000000k;      .lO0000000000000000000000Od:'.,ck0KXNNNWWWko
// olO0000000000000000d'     'x000000000000000O0000000000Okxk000XNNNNWMOl
// kcx00000000000000000x:...;xOOxkO00000OOxolc::cclooodolccok000KNNNNWMOl
// XolO00000000000000000OkkkO00kollccclcc:;,,;;;;,,,,,'.,lk00000KNNNNWMko
// M0loO0000000000000000000000000Oko:,''',,,,,,,,,,,;;:okO000000KNNNNWWxd
// MWOloO000000000000000000000000000OkkxdddddddoodddxkO000000000XNNNWMKoO
// MMW0lok00000000000000000000000000000000000000000000000000000KXNNWWNddN
// MMMMXdlxO000000000000000000000000000000000000000000000000000XNNNWNxdXM
// MMMMMWOolxO000000000000000000000000000000000000000000000000KNNNWKxdKMM
// MMMMMMMNOoldO000000000000000000000000000000000000000000000KNNNXkdkNMMM
// MMMMMMMMMN0dooxO00000000000000000000000000000000000000000KXKkxdkXWMMMM
// MMMMMMMMMMMWXOxdooxkO0000000000000000000000000000000Okxxdxxxk0NMMMMMMM
// MMMMMMMMMMMMMMMNKOxdddoooddxxxxkkkkkkkxxxxxddddoooodddxkOKNWMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWNKOxdollccccccccccccccccllodxk0KNWMMMMMMMMMMMMMMMM

// Development help from @lozzereth (www.allthingsweb3.com)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error BridgePaused();
error InvalidClaimSignature();
error InvalidClaimNonce();
error CancellingDisabled();

interface IBridgeSquishiverseItem {
    // Events
    event BridgedTokens(
        address from,
        uint256[] ids,
        uint256[] amounts,
        uint256 nonce
    );
    event CancelClaim(address from, uint256 oldBlock, uint256 newBlock);

    /**
     * @dev Swap tokens into the bridge
     */
    function swap(
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256 nonce
    ) external;

    /**
     * @dev Claim items from the bridge
     */
    function claim(
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256 oldBlock,
        uint256 newBlock,
        bytes calldata signature
    ) external;

    /**
     * @dev Cancels a claim for an address
     */
    function cancelClaimAdmin(
        address _address,
        uint256 oldBlock,
        uint256 newBlock
    ) external;

    /**
     * @dev Cancel claim as a user
     */
    function cancelClaim(uint256 oldBlock, uint256 newBlock) external;

    /**
     * @dev Toggles the cancellable state
     */
    function toggleCancellable() external;

    /**
     * @dev Set the oracle address to verify the data
     */
    function setOracleAddress(address _oracleAddress) external;

    /**
     * @dev Set pause state of the bridge
     */
    function togglePaused() external;
}