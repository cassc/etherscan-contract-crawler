// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Limitbreak/IQuestStaking.sol";
import "./utils/Ownable.sol";
import "./utils/IERC721A.sol";
import "./SpiritSocks.sol";
import "./utils/FixedPointMathLib.sol";
/*
An example implementation of a contract that uses the IQuestStaking implementation provided by Limitbreak.
Uses the concept of Questing, and time on a quest, to gate access to a free NFT mint.
Made with Love by Arianna - Recognise the name?
*/
contract SpiritSockQuest is Ownable {
    using FixedPointMathLib for uint256;

    // Cost to mint a pair of socks in the Sock Quest.
    uint public SOCK_MINT_PRICE = 0.01 ether;
    // Amount of time in seconds on the quest to mint a pair of socks.
    uint public SOCK_MINT_DELAY = 3600;

    IQuestStaking public digidaigakuSpirits;
    SpiritSocks public socks;

    mapping(uint256 => uint256) private tokenMintCount;

    // We take the contract of Digidaigaku Spirits, which implements IQuestStaking
    // The contract for socks of destiny.
    constructor(IQuestStaking _digidaigakuSpirits, SpiritSocks _socks) payable {
        digidaigakuSpirits = _digidaigakuSpirits;
        socks = _socks;
    }

    // Enter the quest, every 1 hour you can mint some socks up to 8888 max supply.
    function enterQuest(uint tokenId) public 
    {
        require(_ownerOf(tokenId) == _msgSender(), "Not your Spirit, not your socks.");
        // Send the Spirit on a quest, we are just a simple factory, so have only the one QuestId, kek. 
        digidaigakuSpirits.enterQuest(tokenId, 1);
        tokenMintCount[tokenId] = 0;
    }

    // Leave the quest, if you've made 10 or more socks, you get a bonus prize of an extra pair of socks for free, assuming not at max supply.
    function exitQuest(uint tokenId) public 
    {
        require(_ownerOf(tokenId) == _msgSender(), "Not your Spirit, not your socks.");
        if(tokenMintCount[tokenId] >= 10)
        {
            // Mint a special bonus sock.
            if(socks.totalSupply() + 1 <= socks.MAX_SUPPLY())
            {
                socks.mint(_msgSender(), 1);
            }
        }
        digidaigakuSpirits.exitQuest(tokenId, 1);
    }

    // You can perform actions whilst on this quest!
    // Here you are minting socks (of course, you don't want your Spirits having cold feet do you?)
    function mintSocks(uint tokenId, uint quantity) public {
        require(_ownerOf(tokenId) == _msgSender(), "Not your Spirit, not your socks.");

        // We check that you've actually been questing long enough to craft up all these lovely socks!
        uint timeOnQuest = digidaigakuSpirits.getTimeOnQuest(tokenId, address(this), 1);
        uint maxQty = (timeOnQuest / SOCK_MINT_DELAY) - tokenMintCount[tokenId];
        require(maxQty >= quantity, "You've not been questing long enough to create this many socks!");

        // We store how many socks you've minted on this quest, I know some of you cheeky Spirits will try anything! Lmeow
        tokenMintCount[tokenId] = tokenMintCount[tokenId] + quantity;

        // Create the socks of doooom!!!
        socks.mint(_msgSender(), quantity);
    }

    // Helper function, to check ownership of the Spirit, I've seen what you cheeky degens do on chain.
    function _ownerOf(uint tokenId) private view returns (address) {
        return IERC721A(address(digidaigakuSpirits)).ownerOf(tokenId);
    }
}