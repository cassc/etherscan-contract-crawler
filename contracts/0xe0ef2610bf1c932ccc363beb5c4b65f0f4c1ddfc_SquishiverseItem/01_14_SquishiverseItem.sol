// Squishiverse by FourLeafClover (www.squishiverse.com) - Squishiverse Item

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

pragma solidity ^0.8;

import {FiniteBurnableERC1155} from "./abstract/FiniteBurnableERC1155.sol";

/// @dev The maximum minting supply has been hit
error SquishiverseItem__HitMaximumSupply();

/// @dev The caller is not the owner or the bridge contract
error SquishiverseItem__NotOwnerOrBridge();

contract SquishiverseItem is FiniteBurnableERC1155 {
    /// @dev Bridge contract
    address public bridgeContract;

    /// @dev Token maximum supply (only decreasable)
    mapping(uint256 => uint256) public tokenMaxSupply;

    constructor(string memory _metadataUri)
        FiniteBurnableERC1155("Squishiverse Item", "SVITEM", _metadataUri)
    {
        tokenMaxSupply[0] = 2050; // Dungeon Pass
        tokenMaxSupply[1] = 2800; // Lootbox
        tokenMaxSupply[2] = 500; // Guild Creation Pass
        tokenMaxSupply[3] = 400; // Aurian Loyalty Badge
        tokenMaxSupply[4] = 400; // Aurian Crown Supremacy
        tokenMaxSupply[5] = 700; // Maxi Bag
        tokenMaxSupply[6] = 200; // Dionysus Eye
        tokenMaxSupply[7] = 200; // Dionysus Tooth
        tokenMaxSupply[8] = 200; // Dionysus Scale
        tokenMaxSupply[9] = 150; // Blessing Seasons
        tokenMaxSupply[10] = 20; // Genesis Dragon Red
        tokenMaxSupply[11] = 10; // Genesis Dragon Blue
        tokenMaxSupply[12] = 6; // Genesis Dragon Green
        tokenMaxSupply[13] = 10; // Genesis Dragon Pink
        tokenMaxSupply[14] = 4; // Genesis Dragon Purple
    }

    modifier withinMaximumSupply(uint256 _tokenId, uint256 _quantity) {
        if (totalSupply(_tokenId) + _quantity > tokenMaxSupply[_tokenId]) {
            revert SquishiverseItem__HitMaximumSupply();
        }
        _;
    }

    /**
     * @dev Mint as bridge (only within limits)
     */
    function mint(
        address account,
        uint256 id,
        uint256 value
    ) public onlyOwnerOrBridge withinMaximumSupply(id, value) {
        _mint(account, id, value, "");
    }

    /**
     * @dev Reverts if called by any account other than the owner/bridge
     */
    modifier onlyOwnerOrBridge() {
        if (owner() != _msgSender() && bridgeContract != _msgSender()) {
            revert SquishiverseItem__NotOwnerOrBridge();
        }
        _;
    }

    /**
     * @dev Mutable token supply (can only be decreased after)
     */
    function setTokenMaxSupply(uint256 _tokenId, uint256 _supply)
        external
        onlyOwner
    {
        if (tokenMaxSupply[_tokenId] != 0) {
            require(
                _supply <= tokenMaxSupply[_tokenId],
                "Cannot Increase Supply"
            );
            require(
                _supply >= totalSupply(_tokenId),
                "Must Be Above Minted Amount"
            );
        }
        tokenMaxSupply[_tokenId] = _supply;
    }

    /**
     * @dev Airdrop to a bunch of addresses
     */
    function airdrop(
        address[] memory accounts,
        uint256 id,
        uint256 value
    ) external onlyOwner withinMaximumSupply(id, value * accounts.length) {
        for (uint256 i; i < accounts.length; i++) {
            _mint(accounts[i], id, value, "");
        }
    }

    /**
     * @dev Set the Bridge Address
     */
    function setBridgeContract(address _bridgeContract) external onlyOwner {
        bridgeContract = _bridgeContract;
    }
}