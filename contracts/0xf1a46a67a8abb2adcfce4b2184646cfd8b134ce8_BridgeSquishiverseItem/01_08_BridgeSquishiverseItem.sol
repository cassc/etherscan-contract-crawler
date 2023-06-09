// Squishiverse by FourLeafClover (www.squishiverse.com) - Bridge Squishiverse Item

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
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {IBridgeSquishiverseItem} from "./interfaces/IBridgeSquishiverseItem.sol";
import {ISquishiverseItem} from "./interfaces/ISquishiverseItem.sol";

/// @dev The bridge is paused
error BridgeSquishiverseItem__BridgePaused();

/// @dev Signature claim is invalid
error BridgeSquishiverseItem__InvalidClaimSignature();

/// @dev The nonce specified is invalid
error BridgeSquishiverseItem__InvalidClaimNonce();

/// @dev Cancel functionality is disabled
error BridgeSquishiverseItem__CancellingDisabled();

/// @dev The id and qty do not match items
error BridgeSquishiverseItem__IdAndQtyMismatch();

contract BridgeSquishiverseItem is IBridgeSquishiverseItem, Ownable {
    using ECDSA for bytes32;

    /// @dev Oracle to sign the addresses
    address public oracleAddress;

    /// @dev 1155 Token we are bridging
    ISquishiverseItem public immutable erc1155Address;

    /// @dev Bridge pausibility
    bool public paused;

    /// @dev Claims nonces stored against addresses
    mapping(address => uint256) public claimNonce;

    /// @dev Cancellable
    bool public cancellable;

    constructor(ISquishiverseItem _erc1155Address, address _oracleAddress) {
        erc1155Address = _erc1155Address;
        oracleAddress = _oracleAddress;
    }

    modifier idAndAmountsMatch(
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) {
        if (_ids.length != _amounts.length) {
            revert BridgeSquishiverseItem__IdAndQtyMismatch();
        }
        _;
    }

    /**
     * @dev Swap a token into the the bridge
     */
    function swap(
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256 nonce
    ) external notPaused idAndAmountsMatch(ids, amounts) {
        for (uint256 id; id < ids.length; id++) {
            ISquishiverseItem(erc1155Address).burn(
                msg.sender,
                ids[id],
                amounts[id]
            );
        }
        emit BridgedTokens(msg.sender, ids, amounts, nonce);
    }

    /**
     * @dev Claim an amount from the bridge
     */
    function claim(
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256 oldBlock,
        uint256 newBlock,
        bytes calldata signature
    )
        external
        notPaused
        hasValidNonce(recipient, oldBlock, newBlock)
        idAndAmountsMatch(ids, amounts)
    {
        bytes32 data = keccak256(
            abi.encodePacked(recipient, ids, amounts, oldBlock, newBlock)
        );
        if (data.toEthSignedMessageHash().recover(signature) != oracleAddress) {
            revert BridgeSquishiverseItem__InvalidClaimSignature();
        }
        claimNonce[recipient] = newBlock;
        for (uint256 id; id < ids.length; id++) {
            ISquishiverseItem(erc1155Address).mint(
                recipient,
                ids[id],
                amounts[id]
            );
        }
    }

    modifier hasValidNonce(
        address _recipient,
        uint256 _oldBlock,
        uint256 _newBlock
    ) {
        if (
            _oldBlock != claimNonce[_recipient] ||
            _oldBlock >= block.number ||
            _newBlock <= _oldBlock
        ) {
            revert BridgeSquishiverseItem__InvalidClaimNonce();
        }
        _;
    }

    /**
     * @dev Cancels a claim for an address
     */
    function cancelClaimAdmin(
        address _address,
        uint256 oldBlock,
        uint256 newBlock
    ) external onlyOwner hasValidNonce(_address, oldBlock, newBlock) {
        claimNonce[_address] = newBlock;
        emit CancelClaim(_address, oldBlock, newBlock);
    }

    /**
     * @dev Cancel claim as a user
     */
    function cancelClaim(uint256 oldBlock, uint256 newBlock)
        external
        cancelEnabled
        hasValidNonce(msg.sender, oldBlock, newBlock)
    {
        claimNonce[msg.sender] = newBlock;
        emit CancelClaim(msg.sender, oldBlock, newBlock);
    }

    modifier cancelEnabled() {
        if (!cancellable) {
            revert BridgeSquishiverseItem__CancellingDisabled();
        }
        _;
    }

    /**
     * @dev Toggles the cancellable state
     */
    function toggleCancellable() external onlyOwner {
        cancellable = !cancellable;
    }

    /**
     * @dev Set the oracle address to verify the data
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
    }

    /**
     * @dev Set pause state of the bridge
     */
    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    modifier notPaused() {
        if (paused) revert BridgeSquishiverseItem__BridgePaused();
        _;
    }

    /**
     * @dev Destroy the smart contract
     */
    function destroySmartContract(address payable _to) external onlyOwner {
        selfdestruct(_to);
    }
}