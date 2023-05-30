//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// .-'''-.                                                                                                             .-'''-.                          //
// '   _    \                                                                                   _______                '   _    \                       //
// /|                 /   /` '.   \     .           __.....__        _..._                   __.....__               \  ___ `'.           /   /` '.   \ //
// ||                .   |     \  '   .'|       .-''         '.    .'     '.             .-''         '.              ' |--.\  \         .   |     \  ' //
// ||        .-,.--. |   '      |  '.'  |      /     .-''"'-.  `. .   .-.   .           /     .-''"'-.  `.            | |    \  '        |   '      |  '//
// ||  __    |  .-. |\    \     / /<    |     /     /________\   \|  '   '  |          /     /________\   \    __     | |     |  '    __ \    \     / / //
// ||/'__ '. | |  | | `.   ` ..' /  |   | ____|                  ||  |   |  |       _  |                  | .:--.'.   | |     |  | .:--.'.`.   ` ..' /  //
// |:/`  '. '| |  | |    '-...-'`   |   | \ .'\    .-------------'|  |   |  |     .' | \    .-------------'/ |   \ |  | |     ' .'/ |   \ |  '-...-'`   //
// ||     | || |  '-                |   |/  .  \    '-.____...---.|  |   |  |    .   | /\    '-.____...---.`" __ | |  | |___.' /' `" __ | |             //
// ||\    / '| |                    |    /\  \  `.             .' |  |   |  |  .'.'| |// `.             .'  .'.''| | /_______.'/   .'.''| |             //
// |/\'..' / | |                    |   |  \  \   `''-...... -'   |  |   |  |.'.'.-'  /    `''-...... -'   / /   | |_\_______|/   / /   | |_            //
// '  `'-'`  |_|                    '    \  \  \                  |  |   |  |.'   \_.'                     \ \._,\ '/             \ \._,\ '/            //
//            '------'  '---'                '--'   '--'                               `--'  `"               `--'  `"                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721B/ERC721EnumerableLite.sol";
import "./ERC721B/Delegated.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BrokenSeaDAO is ERC721EnumerableLite, Delegated {
    using Strings for uint256;

    uint256 public PRICE = 0.03 ether;
    uint256 private MAX_TOKENS_PER_TRANSACTION = 100;
    uint256 private MAX_SUPPLY = 10000;
    uint256 private freeLimit = 1001;
    bool public revealed = false;

    string private notRevealedUri = "ipfs://QmVXdgMcBQ9rYUPwFV7sFDdYkNRD9emLMShhqMXorVa8LS/1.json";

    string public _baseTokenURI = "";
    string private _baseTokenSuffix = ".json";

    address art = 0x5Ab0787A16E66A57dDa644201b253D214fA5193a;

    constructor() ERC721B("BrokenSeaDAO", "BRKN") {
    }

    function reveal() public onlyDelegates {
        revealed = true;
    }

    function mint(uint256 _count) external payable {
        require(
            _count < MAX_TOKENS_PER_TRANSACTION,
            "Count exceeded max tokens per transaction."
        );

        uint256 supply = totalSupply();
        require(supply + _count < MAX_SUPPLY, "Exceeds max BRKN token supply.");
        if (supply + _count < freeLimit) {
            for (uint256 i = 1; i <= _count; ++i) {
                _safeMint(msg.sender, supply + i, "");
            }
        } else {
            require(msg.value >= PRICE * _count, "Ether sent is not correct.");
            for (uint256 i = 1; i <= _count; ++i) {
                _safeMint(msg.sender, supply + i, "");
            }
        }
    }

    function setPrice(uint256 _newPrice) external onlyDelegates {
        PRICE = _newPrice;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyDelegates {
        _baseTokenURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "Provided token ID doesnot exist."
        );

        if (!revealed) {
            return notRevealedUri;
        }
        string memory baseURI = _baseTokenURI;
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        tokenId.toString(),
                        _baseTokenSuffix
                    )
                )
                : "";
    }

    function withdraw() public onlyDelegates {
        uint256 balance = address(this).balance;
        payable(art).transfer(balance);
    }
}