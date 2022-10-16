// SPDX-License-Identifier: UNLICENSED
//
//         ,----,
//       ,/   .`|       ,--,                            ____      ,----..                       ,----,
//     ,`   .'  :     ,--.'|    ,---,.                ,'  , `.   /   /   \      ,---,         .'   .`|
//   ;    ;     /  ,--,  | :  ,'  .' |             ,-+-,.' _ |  /   .     :   .'  .' `\    .'   .'   ;
// .'___,/    ,',---.'|  : ',---.'   |          ,-+-. ;   , || .   /   ;.  \,---.'     \ ,---, '    .'
// |    :     | |   | : _' ||   |   .'         ,--.'|'   |  ;|.   ;   /  ` ;|   |  .`\  ||   :     ./
// ;    |.';  ; :   : |.'  |:   :  |-,        |   |  ,', |  ':;   |  ; \ ; |:   : |  '  |;   | .'  /
// `----'  |  | |   ' '  ; ::   |  ;/|        |   | /  | |  |||   :  | ; | '|   ' '  ;  :`---' /  ;
//     '   :  ; '   |  .'. ||   :   .'        '   | :  | :  |,.   |  ' ' ' :'   | ;  .  |  /  ;  /
//     |   |  ' |   | :  | '|   |  |-,        ;   . |  ; |--' '   ;  \; /  ||   | :  |  ' ;  /  /--,
//     '   :  | '   : |  : ;'   :  ;/|        |   : |  | ,     \   \  ',  / '   : | /  ; /  /  / .`|
//     ;   |.'  |   | '  ,/ |   |    \        |   : '  |/       ;   :    /  |   | '` ,/./__;       :
//     '---'    ;   : ;--'  |   :   .'        ;   | |`-'         \   \ .'   ;   :  .'  |   :     .'
//              |   ,/      |   | ,'          |   ;/              `---`     |   ,.'    ;   |  .'
//              '---'       `----'            '---'                         '---'      `---'
//
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ModzKidsWearables.sol";

contract ModzKidsWearablesNonFungibleSale is
    Ownable,
    PaymentSplitter,
    ReentrancyGuard
{
    ModzKidsWearables wearables;

    using Counters for Counters.Counter;
    Counters.Counter public _tokenIdCounter;

    bool public mintActive = false;
    bool public mintEnded = false;

    uint256 public mintPrice;
    uint256 public maxTokens;
    uint256 public mintLimit;
    uint256 public startingTokenID;

    constructor(
        uint256 _mintPrice,
        uint256 _maxTokens,
        uint256 _mintLimit,
        uint256 _startingTokenID,
        uint256[] memory _royalteeShares,
        address[] memory _royalteePayees,
        address _wearablesContract
    ) PaymentSplitter(_royalteePayees, _royalteeShares) {
        wearables = ModzKidsWearables(_wearablesContract);
        mintPrice = _mintPrice;
        maxTokens = _maxTokens;
        mintLimit = _mintLimit;
        startingTokenID = _startingTokenID;
    }

    function toggleMintActive() external onlyOwner {
        mintActive = !mintActive;
    }

    function mint(uint256 _mintAmount) external payable nonReentrant {
        require(!mintEnded, "Mint has ended");
        require(mintActive, "Mint is not active");

        require(msg.value == _mintAmount * mintPrice, "Invalid payment amount");

        require(
            _mintAmount > 0 && _mintAmount <= mintLimit,
            "Invalid mint amount"
        );

        require(
            _tokenIdCounter.current() + _mintAmount <= maxTokens,
            "Mint goes over max supply"
        );

        for (uint256 i = 0; i < _mintAmount; i++) {
            _tokenIdCounter.increment();
            wearables.mint(
                msg.sender,
                _tokenIdCounter.current() + startingTokenID,
                1
            );
        }

        if (_tokenIdCounter.current() == maxTokens) {
            mintEnded = true;
            mintActive = false;
        }
    }
}