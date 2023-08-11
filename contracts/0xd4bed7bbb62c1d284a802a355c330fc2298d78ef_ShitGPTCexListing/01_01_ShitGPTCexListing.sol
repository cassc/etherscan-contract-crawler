// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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