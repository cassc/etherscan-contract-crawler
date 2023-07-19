// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/***             
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::^~^:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::^!J?^:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::~J5YJ~:::::::::::::::^^^^^^^^^^^:::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::^J5PP5Y7~~^^^~~!!7??JJYYYYY55YYYYJ?7~^::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::~PGBBBGGGPPPPPPPPPPPPPPPP555YYJJJYY55Y7^::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::!PB###BBBBBGGGGPPPP5555555YYJJ??????J5P5?^::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::~5G#####BBBGGGGPPPPP5555YYJYJYYYY55YYYY5P5!^::::::::::::::::::::::::::::::::
::::::::::::::::::::::::^?GB######BBBGGGPPPPPPPPPPPGGBBBGP55YJJJJY5?^:::::::::::::::::::::::::::::::
:::::::::::::::::::::::::^JB##&&&&####BBBBBBBB##&&&&##BGGPPPPP555YYY?~::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::7G#&&&&&&&&&&&&&&&@@@&&&#BGGG####BGBBGGP55J~:::::::::::::::::::::::::::::
::::::::::::::::::::::::::::^75B#&&@@@@@@@@@@&&#BGP55G&@#GG5JYPY5PBBGP57^:::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::^~?B&@@@@&&&&###BP5YJJY#@#G#B###BG5YB#PPPJ^::::::::::::::::::::::::::
::::::::::::::::::::::::::::::^~JG#&&&&&&####&&#PYJ??7?B#BB###&&@@&#B5YPG5~:::::::::::::::::::::::::
:::::::::::::::::::::::::::::~?5B&&&&&&&&&&&&##BGJ???JJJY55PGGGGGB##5?JYPGP~::::::::::::::::::::::::
::::::::::::::::::::::::::::!JPB&&&&&&&##BBBB&#BGYJJJYY55PGGPPPGBBBP5YJJYPB5~:::::::::::::::::::::::
:::::::::::::::::::::::::::!JPB#&&@&&&#GGB#&#&&G5JJJJJJYPGG5J?7JY5G#BPYJY5GGJ^::::::::::::::::::::::
::::::::::::::::::::::::::!JPB#&&@@@@&&&&&&&&BPY?777?7?YG#BPJ7!7?JJPBG5JJYPGGY7^::::::::::::::::::::
:::::::::::::::::::::::::~J5G##&&@@@&&&&&&##BPYJ?7??77!JG##GY7~!?JYYGB5J?JYPBBGPJ!^:::::::::::::::::
:::::::::::::::::::::::::75PB#&&&&&&###&&##BG5J?77YJ?7!7G&&BPYJJY5Y5#B5J??JYPGB##BP?^:::::::::::::::
::::::::::::::::::::::::^J5GB#&&&&###B#&&&#BGP5JY5GB5?!!Y&@@@@@G:::~#G5J77??YPGBB##BP7::::::::::::::
::::::::::::::::::::::^~7YPB#&&&###BBGP&@&&&&@@@@~?&GY?!!JPB#&#7 .:YB5J?777??J5PGBB##B?:::::::::::::
::::::::::::::::::::^!?Y5PB##&&##BBGGP5Y&&5?&&&@&^5#G5J7!!?JJ?!^~75PYJ??777777JY5GBB##B7::::::::::::
::::::::::::::::::^!?Y5PGB######BBGGP55YYGGJ7J5YJP&BP5YJ????JJJYYYYJ???7!!!!!!7?YPGB##B5^:::::::::::
:::::::::::::::::^7J5PGBB######BBGGPPP5555PGGPPGB#GP555555YYJ?????77777!!!!!!!7?YPGB###G~:::::::::::
::::::::::::::::^?5PPGBB#####BBGGPPP5555Y555PPGGGGPPPP555555YYJ?77777!!!!!!!777J5GB####G~:::::::::::
:::::::::::::::^JPPGGBB#####BBGGPPPPPPGB#BGPP55555555555555YYJ?7777777!!77777?JYPB#####5^:::::::::::
:::::::::::::::!PGGBBB##&&&##BBGGPGGGGGB#&@@&&&#BGGGP55YJJ?????777?7????777?JJ5PG#####B!::::::::::::
:::::::::::::::7BB####&&&&&&##BBGGGGGGGGGB#&@&##BGGP55YYJJ??77???YB&G5YJJJJY5PGB##&&#B7:::::::::::::
:::::::::::::::!B###&&&&&&&&&&###BBBGGPPPGBB#&#G5J7~^::........:7GG555YYY55PGB###&&#P!::::::::::::::
:::::::::::::::^Y&&&&&&&&&&&&&&&&##BBBGGGGB####BPY?7!~^^::..:^?GBPPGPP55PGBB##&&&#G7^:::::::::::::::
::::::::::::::::^J#&&&&&&&&&&&&&&&&###BBBBB##&&&#BG5JJ?7777?YPGGGBBGGGGBB##&&&&#P7^:::::::::::::::::
::::::::::::::::::~5#&@@&&&@@@&&&&&&&&#######&&&&&&#BGGGGGBBBBB#BBBBB###&&&&&BY!::::::::::::::::::::
::::::::::::::::::::^?P#&@@@@@@@@&&&&&&&&&&&&PJ5G#&&&&&&&#57~:~B#B###&&&&&B57^::::::::::::::::::::::
:::::::::::::::::::::::^!JG#&@@@@@@@@@@@&@@@G:...^?PGGPGY^....:&&&&&&&#P?~^:::::::::::::::::::::::::
::::::::::::::::::::::::::::^!?Y5G##&@@@@@@@#J!^::^~^::^:::^7PGBBGP#&G?^::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::7#&Y75B#BB#BY7!Y&G5P&G~!?#@@#P7::~JG#P!::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::!B&5^::YB#&#&P?!~&&^:[email protected]:^~7#@@&G!77JYPP7::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::[email protected]#?77??J5#BG7^::[email protected]::[email protected]::::^5PY??77!~^::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::7555555YY?7!^::::5&7::J&J:::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::^#B^::P&7:::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::?&Y:::B&!:::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::P#7::^##~:::::::::::::::::::::::::::::::::::::::::::                                                                                                      
***/

interface IShitGPTCexListing {
    function transfer(address recipient, uint256 amount) external;

    function burn(uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}

contract ShitGPTCexListing {
    mapping(address => bool) public cexAddresses;
    address public tokenAddress;
    address public contractOwner;

    modifier onlyOwner() {
        require(
            msg.sender == contractOwner,
            "Only the contract owner can call this function"
        );
        _;
    }

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        // Hardcode the initial list of allowed addresses here
        cexAddresses[0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE] = true; //binance
        cexAddresses[0xd24400ae8BfEBb18cA49Be86258a3C749cf46853] = true; //gemini
        cexAddresses[0x2B5634C42055806a59e9107ED44D43c426E58258] = true; //kucoin
        cexAddresses[0xf89d7b9c864f589bbF53a82105107622B35EaA40] = true; //bybit
        cexAddresses[0x1151314c646Ce4E0eFD76d1aF4760aE66a9Fe30F] = true; //bitfinex
        cexAddresses[0x6cC5F688a315f3dC28A7781717a9A798a59fDA7b] = true; //okx
        cexAddresses[0x71660c4005BA85c37ccec55d0C4493E66Fe775d3] = true; //coinbase
        cexAddresses[0x2910543Af39abA0Cd09dBb2D50200b3E800A63D2] = true; //kraken
        cexAddresses[0xe79eeF9b9388A4fF70ed7ec5Bccd5B928ebB8Bd1] = true; //bitmart
        cexAddresses[0x00BDb5699745f5b860228c8f939ABF1b9Ae374eD] = true; //bitstamp
        cexAddresses[0x0D0707963952f2fBA59dD06f2b425ace40b492Fe] = true; //gate.io
        cexAddresses[0xaB5C66752a9e8167967685F1450532fB96d5d24f] = true; //huobi
        cexAddresses[0xe80623a9d41f2f05780D9cD9cea0F797Fd53062A] = true; //bitget

        contractOwner = msg.sender;
    }

    function sendMoney(
        address payable recipient,
        uint256 amount
    ) external onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        require(
            cexAddresses[recipient],
            "Recipient is not in the allowed CEX addresses"
        );

        IShitGPTCexListing token = IShitGPTCexListing(tokenAddress);
        token.transfer(recipient, amount);
    }

    function burnAllTokens() external onlyOwner {
        IShitGPTCexListing token = IShitGPTCexListing(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.burn(balance);
    }

    function addAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Invalid address");
        cexAddresses[newAddress] = true;
    }

    function removeAddress(address existingAddress) external onlyOwner {
        cexAddresses[existingAddress] = false;
    }
}