// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/***             
 *                                          ▓▓▓▄,
                                          ▓█╬▀██▓▄╖
                                         ╓██░░╠╠╬╬███▄,
                                        ▄██░░░░╚╠╠╠╠╬╬██▓µ
                                     ╓▓██╬░░░░░░╠╬╬╬╬╬╬╬╬██▄
                                ,▄▓███╬░▒▒▒▒▒▒▒▒▒╬╬╬╬╬╬╬╬╬╬██▓
                           ,▄▓███▓╬╠▒▒▒▒▒▒▒▒▒▒▒▒╠╬╬╬╬╬╬╬╬╬╬╬╬██▌
                        ╓▓██▓╬╬╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██
                      ╓▓█▓╬╬▒╠╠╠╠╠╠╠╠╠╠╠╠╠▒╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██
                     ]██╬╬╬▒╠╠╠╠╠╠╠╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣█▌
                     ╫█╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██
                     ╟█▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣██
                     ▄██╬╬╬╬╬▓▓▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▓▓▓▓╬╬╬╬╬╬▓██▓µ
                 ▄▓██▓▀╬╬▓█▀▀╙└└└╙╙▀██╬╬╬╬╬╬╬╬╬╬╬╬██▀▀╙└└└╙╙▀██▒╠╠╠╬╬██▄
              ,▓██╬╬▒▒▒▓█╙   ,╓╦µ,   └▀█╬╬╬╬╬╬╬╬██╙   ,╓╦µ,   └▀█▒▒╠╠╬╬██▄
             ╔██▒╬╬▒╠▒█▌      └╫▓▓▓ε   ╚█╬╬╬╬╬╬█▌      └╫▓▓▓ε   ╚█▒╠╠╠╬╬╣█▌
            ]██╬╬╬╬╬╠╟█    φ░░░╫▓▓▓▓    █▌╠╠╠╠╟█    φ░░░╫▓▓▓▓    █▌╠╠╬╬╬╬╟█▌
            ╫█▒╬╬╬╬╬╬╫█    ██▓██████⌐   ▓█╠╠╠╠╟█    ██▓██████⌐   ▓█╬╬╬╬╬╬╬██
            ╟█╬╬╬╬╬╬╬╬█▄   ╚█████▒ε    ]█▒╬╬╬╬╬█▄   ╚█████▒ε    ]█▒╬╬╬╬╬╬╣██
            ╙██╬╬╬╬╬╬╬╬█▄   ╙▀███▀"   ▄█▓╬╬╬╬╬╬╬█▄   ╙▀███▀"   ▄█▓╬╬╬╬╬╬╬▓█▌
             ▓█▓╬╬╬╬╬╬╬╬██▄Q       ╓▄██╬╬╬╬╬╬╬╬╬╬██▄Q       ╓▄██╬╬╬╬╬╬╬╬╣██▄
          ╓▓█╬╠╠╬╬╠╠╠╬╬╬╬╬╬╬████████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬████████╬╬╬╬╬╬╬╠╠╬╬╠╠╬██▓
        ╓▓█╬╬╬╠╠╠╠╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠╠╠╠╬██▌
       á██╬╠▒▒▒▒╠╠╠╠╠╠╬╬╬▓█████▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓██████╬╬╬╠╠╠╠╠╠▒▒▒▒╠╠╣█▌
      ]██╬╬╠╠╠╠╠╠╠╠╠╠╠╠▓█╬╬╠╠╬╬╬╬███████▓▓▓▓▓▓▓▓███████▀╬╬╬╠╠╬╬██▒╠╠╠╠╠╠╠╠╠╠╠╠╬╫█▌
      ╫█▒╬╬╬╠╠╠╠╠╠╠╠╠╠╟█▒╠╠╠╠╠╠╠╠╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠╠╠╠╠╠╠█▌╠╠╠╠╠╠╠╠╠╠╠╬╬╬██
      ╫█╬╬╬╬╬╬╬╠╠╠╠╠╠╠╬█▌╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╟█▒╠╠╠╠╠╠╠╠╬╬╬╬╬╣██
      ║██╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██▓▄▒╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠▒▒▓██▒╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣█▌
       ▓█╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓███▓▄▄▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▄▄▓████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██
        ██▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬███████████████████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣██¬
         ╚██╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██▀
           ▀██▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓██▀
             └▀███▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓███▀╙
                 └╙▀█████▓▓▓╬╬╬╬╬╬╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╬╬╬╬╬╬▓▓▓▓████▀▀└
                        └╙╙▀▀▀████████████████████████████▀▀▀▀╙╙                                                                                             
***/

contract ShitGPT is Ownable, ERC20 {
    /***
     * In this vast expanse of the world, we are always in pursuit, always in a quest.
     * We are in search of good things, of pleasure, of success. But, quite paradoxically,
     * very few of us possess the audacity to label certain things for what they truly are: "SHIT".
     ***/
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    /***
     *    ┏┓┏┓┏┳━━━━┳━━━┓
     *    ┃┃┃┃┃┣━┓┏━┫┏━━┛
     *    ┃┃┃┃┃┃╱┃┃╱┃┗━┓╱
     *    ┃╰┛╰┛┃╱┃┃╱┃┏━┛╱
     *    ╰━━━━┛╱┗┛╱┗┛╱╱╱
     *
     *  ░█████╗░░█████╗░
     *  ██╔═══╝░██╔══██╗
     *  ██████╗░╚██████║
     *  ██╔══██╗░╚═══██║
     *  ╚█████╔╝░█████╔╝
     *  ░╚════╝░░╚════╝░
     ***/
    constructor() ERC20("ShitGPT", "sGPT") {
        uint256 decimals = 18;
        _mint(msg.sender, 69000000000 * 10 ** decimals);
    }

    /***
     * In a world where freedom intertwines with PUNK spirit,
     * ShitGPT has an impressive supply of 69 billion tokens, we're here to celebrate the 69 holiday in style.
     ***/
    function blacklist(
        address[] memory _addresses,
        bool _isBlacklisting
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            blacklists[_addresses[i]] = _isBlacklisting;
        }
    }

    /***
     * No VCs, no presales, no reservations—just an equitable and transparent distribution.
     * 90% for DEX liquidity, 6.9% for CEX Listing and 3.1% for early users and NFT communities airdrops.
     ***/
    function setRule(
        bool _limited,
        address _uniswapV2Pair,
        uint256 _maxHoldingAmount,
        uint256 _minHoldingAmount
    ) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    /***
     * We dare to mock, fearlessly defy rules, we're not afraid to shit everything.
     * Bring fun and make the world better, no matter the weather.
     * Join us in embracing the rebellious energy, as SHIT voice reigns supreme and we make our mark on the crypto world.
     ***/
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "Trading is not started");
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(
                super.balanceOf(to) + amount <= maxHoldingAmount &&
                    super.balanceOf(to) + amount >= minHoldingAmount,
                "Forbid"
            );
        }
    }

    /***
     * $sGPT is more than just another meme token, it's a movement,
     * a social commentary, and a leap into the world of decentralized memes.
     * It's a gentle nudge to remind us all to not take everything so seriously.
     * It's the world’s most memeingful project, created to turn everyday memes into currency.
     * Yes, you heard that right. We’re turning shitposts into diamonds, people!
     ***/
    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}