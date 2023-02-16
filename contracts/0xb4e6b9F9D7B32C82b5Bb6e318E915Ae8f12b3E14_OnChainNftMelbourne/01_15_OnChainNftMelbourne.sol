// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

/**
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWNKkdd0NMMMMMMMMXxdddddONMNOdddddddddddddddddkXMKxddddddddddddddddddxKWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMKl..   .;dKWMMMMMx.     '0MK,                 .OWo                    oWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMO'        .:kXWMMx.     '0MK,                 .OWo                    oWMMMMMMMMMMMMM
MMMMMMMMMMMMMMM0'           .ckXd.     '0MK,      .;oooooooooxXWOc::::;.      .;::::cOWMMMMMMMMMMMMM
MMMMMMMMMMMMMMM0'              '.      '0MK,      ..;;;;;;;;:dXMMMMMMMX:      :XMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMM0'      ''              '0MK,                 ,KMMMMMMMN:      :NMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMM0'     .dXkc.           '0MK,       .loooolollkNMMMMMMMN:      :NMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMM0'     .dMMWKd;.        '0MK,       cNMMMMMMMMMMMMMMMMMX:      :NMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMM0'     .dMMMMMW0o'      ;KMK,       cNMMMMMMMMMMMMMMMMMX:      :NMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMXxlllllo0MMMMMMMMNklcox0XWMNklllllloOWMMMMMMMMMMMMMMMMMWkllllllOWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMWWWWWWMMMMMMMMWWNWWWMMMMMMMMMWWWWWWWWWWWWWWWWWWWMMMWWWWWWWWMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMWOc:;;,',dNMMMMMMWx;',,;::dXMMMWx;,,,,,;;,,,,,,,,,,oXMKl,,,,,;kWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMK,        lXMMMMNo.       .dWMMNc                  ,KMO'      oWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMWo          :KMMXc          ,KMMNc       ..'''''''''lXM0'      oWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMM0'           ;O0;           .dWMNc       'ooooooooooOWM0'      oWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMNl             ..             ;KMNc                  cNM0'      oWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMk.      ;c.          .o;      .xWNc       .:ccccccccckWM0'      cXNNNXXXXXNMMMMMMMMMMMM
MMMMMMMMMMMMX:      '0Wk'        ;0WO'      ;XNc       'cllllllllldXMO'      ..........cXMMMMMMMMMMM
MMMMMMMMMMMWd.     .dWMM0;     .cXMMWo.     .xXc                  .OMO'                ,KMMMMMMMMMMM
MMMMMMMMMMMWOl;'.  :XMMMMNOkkkk0NMMMMK;  .';lOXl............ ...  ,0M0,.............. .:KMMMMMMMMMMM
MMMMMMMMMMMMMMWNK0OKMMMMMMMMMMMMMMMMMMKk0XNWMMWX000000000000000000KWMWK0000000000000000XWMMMMMMMMMMM
MMMMMMMMMMMW0kkkkkkkkkkkOO0KNWMMMMMMMMMMWX0kdooooooodk0XWMMMMMMWKkkkkkk0WMMMMMMWXOkkkkk0WMMMMMMMMMMM
MMMMMMMMMMM0,             ..';dKWMMMMW0o;..            .;lONMMMNc      ;KMMMMMMWl      ;KMMMMMMMMMMM
MMMMMMMMMMM0'      ....        ;KMMWO:.                    ,kNMNc      ,KMMMMMMWl      ,KMMMMMMMMMMM
MMMMMMMMMMM0'     .dXXKk,      ,0MWx.       ':loollc,.      .oNNc      ,KMMMMMMWl      ,KMMMMMMMMMMM
MMMMMMMMMMM0'     .kW0oc.    .:0WMK,      .xNMMMMMMMWO,      'ONc      ,KMMMMMMWl      ,KMMMMMMMMMMM
MMMMMMMMMMM0'     .kWOlc:'    .,lKO'      ;XMMMMMMMMMX:      .kNc      '0MMMMMMNc      ,KMMMMMMMMMMM
MMMMMMMMMMM0'     .kWWWWNk'      ;Oc       ,dOKKKK0Od;       :XWo       ;x0K00xc.      :XMMMMMMMMMMM
MMMMMMMMMMM0'      .;,,,'.       ,KXl.        .....        .cKMM0;         ..         'kMMMMMMMMMMMM
MMMMMMMMMMM0'                  .:0WMW0l'                 .cONMMMMKo'                .l0WMMMMMMMMMMMM
MMMMMMMMMMMXd:::::::::::::ccldkKWMMMMMWXOdl:,''..''',:cdOXWMMMMMMMMNOdl:,'''''',;coOXWMMMMMMMMMMMMMM
MMMMMMMMMMMMMWXKKKKKKKKKKKXXNWMMMMMMMMMMMWN00XNNNNNNWMMMNKKKKKKXWMWXKKKK00OOOOO0KKKKKNWMMMMMMMMMMMMM
MMMMMMMMMMMMMX:.............';coONMMMMNxc;...,dKWMMMMMMMk'.....;KMK:.................oNMMMMMMMMMMMMM
MMMMMMMMMMMMMK,                 .;OWMMO.       .:x0XWMMWd.     '0MK,                 cNMMMMMMMMMMMMM
MMMMMMMMMMMMMK,      .clc;.       :XMMO.          ..ckXWd.     '0MK,      'cccccccccckWMMMMMMMMMMMMM
MMMMMMMMMMMMMK,      cNMMWO.      lNMMO.              'c;      '0MK,      ,cccccccccl0MMMMMMMMMMMMMM
MMMMMMMMMMMMMK,      cNXOd;.    .dXMMMO.      .                '0MK,                .dWMMMMMMMMMMMMM
MMMMMMMMMMMMMK,      cNK:.      .oXMMMO.     .okc.             '0MK,      ;oooooooood0MMMMMMMMMMMMMM
MMMMMMMMMMMMMK,      cNMNk,       'xNMO.     .xMWX0x;.         '0MK,      .,,,,,,,,,,oXMMMMMMMMMMMMM
MMMMMMMMMMMMMK,      cNMMMNx'      'xWO.     .dMMMMMW0o,       '0MK,                 ,KMMMMMMMMMMMMM
MMMMMMMMMMMMMXl''''',dWMMMMMXo'':oOXWMKc''''';OMMMMMMMMNOl'.,coONMXl'''''''''''''''''oXMMMMMMMMMMMMM
MMMMMMMMMMMMMMWNNNWWNWMMMMMMMWNNWMMMMMWWNNNNNNWMMMMMMMMMMWNNWMMMMMMWNNNNNNNNNNNNNNNNNWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

@title  NFT MELBOURNE 2023
@author marka
@notice This NFT Ticket smart contract may or may not be notable.

*/

contract OnChainNftMelbourne is ERC721Enumerable, Ownable {
    using Strings for uint256;

    bool public paused = false;

    uint64 constant TIER_ONE = 1;
    uint64 constant TIER_TWO = 2;
    uint64 constant TIER_THREE = 3;

    string public constant TIER_ONE_NAME = "General Admission";
    string public constant TIER_TWO_NAME = "Rare Experience";
    string public constant TIER_THREE_NAME = "Ultimate Experience";

    string constant TIER_ONE_COLOUR = "#4cd4b0";
    string constant TIER_TWO_COLOUR = "#dc3545";
    string constant TIER_THREE_COLOUR = "#2b90fd";

    string public constant EVENT_NAME = "NFT MELBOURNE";
    string public constant YEAR = "2023";

    uint256 public constant TIER_ONE_COST = 0.06 ether;
    uint256 public constant TIER_TWO_COST = 0.14 ether;
    uint256 public constant TIER_THREE_COST = 0.46 ether;

    uint256 public constant TIER_ONE_MAX_SUPPLY = 125;
    uint256 public constant TIER_TWO_MAX_SUPPLY = 50;
    uint256 public constant TIER_THREE_MAX_SUPPLY = 25;

    uint256 public constant MAX_SUPPLY = 200; // 25 + 50 + 125
    uint256 public constant MAX_MINT_AMOUNT = 20;

    uint256 public _tierOneSupply;
    uint256 public _tierTwoSupply;
    uint256 public _tierThreeSupply;

    struct Ticket {
        uint256 num;
        uint256 tier;
        uint256 gmCount;
        string tierName;
        string year;
    }

    // tokenId => Ticket
    mapping(uint256 => Ticket) public tickets;

    constructor() ERC721("NFT MELBOURNE 2023", "NFTMEL2023") {}

    // public
    function mintTierOne(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused, "Contract is paused");
        require(_mintAmount > 0, "Mint Amount must be great than 0");
        require(_mintAmount <= MAX_MINT_AMOUNT, "Max Mint Amount exceeded");
        require(_tierOneSupply + _mintAmount <= TIER_ONE_MAX_SUPPLY, "Tier One Max Supply exceeded");
        require(supply + _mintAmount <= MAX_SUPPLY, "Would exceed Max Supply");

        if (msg.sender != owner()) {
            require(
                msg.value >= TIER_ONE_COST * _mintAmount,
                "Insuffient Eth provided for number of mints requested"
            );
        }

        Ticket memory ticket;

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 tokenId = uint256(supply + i);
            ticket.num = tokenId;
            ticket.tier = TIER_ONE;
            ticket.tierName = TIER_ONE_NAME;
            ticket.gmCount = random();
            tickets[tokenId] = ticket;

            ++_tierOneSupply;
            _safeMint(msg.sender, tokenId);
        }
    }

    function mintTierTwo(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused, "Contract is paused");
        require(_mintAmount > 0, "Mint Amount must be great than 0");
        require(_mintAmount <= MAX_MINT_AMOUNT, "Max Mint Amount exceeded");
        require(_tierTwoSupply + _mintAmount <= TIER_TWO_MAX_SUPPLY, "Tier Two Max Supply exceeded");
        require(supply + _mintAmount <= MAX_SUPPLY, "Would exceed Max Supply");

        if (msg.sender != owner()) {
            require(
                msg.value >= TIER_TWO_COST * _mintAmount,
                "Insuffient Eth provided for number of mints requested"
            );
        }

        Ticket memory ticket;

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 tokenId = uint256(supply + i);
            ticket.num = tokenId;
            ticket.tier = TIER_TWO;
            ticket.tierName = TIER_TWO_NAME;
            ticket.gmCount = random();
            tickets[tokenId] = ticket;

            ++_tierTwoSupply;
            _safeMint(msg.sender, tokenId);
        }
    }

    function mintTierThree(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused, "Contract is paused");
        require(_mintAmount > 0, "Mint Amount must be great than 0");
        require(_mintAmount <= MAX_MINT_AMOUNT, "Max Mint Amount exceeded");
        require(_tierThreeSupply + _mintAmount <= TIER_THREE_MAX_SUPPLY, "Tier Two Max Supply exceeded");
        require(supply + _mintAmount <= MAX_SUPPLY, "Would exceed Max Supply");

        if (msg.sender != owner()) {
            require(
                msg.value >= TIER_THREE_COST * _mintAmount,
                "Insuffient Eth provided for number of mints requested"
            );
        }

        Ticket memory ticket;

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 tokenId = uint256(supply + i);
            ticket.num = tokenId;
            ticket.tier = TIER_THREE;
            ticket.tierName = TIER_THREE_NAME;
            ticket.gmCount = random();
            tickets[tokenId] = ticket;

            ++_tierThreeSupply;
            _safeMint(msg.sender, tokenId);
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require( _exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return buildMetadata(_tokenId);
        
    }

    //only owner
    function withdraw() public payable onlyOwner {
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function buildImage(uint256 _tokenId) public view returns (bytes memory) {
        Ticket memory currentTicket = tickets[_tokenId];

        uint256 currentTier = currentTicket.tier;
        string memory currentTierName = currentTicket.tierName;
        string memory currentNum = toString(currentTicket.num);

        string memory colourToUse = TIER_ONE_COLOUR;

        if (currentTier == TIER_TWO) {
            colourToUse = TIER_TWO_COLOUR;
        } else if (currentTier == TIER_THREE) {
            colourToUse = TIER_THREE_COLOUR;
        }

        return abi.encodePacked(
            '<svg ',
                'xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" ',
            '>',
                '<style>.st1{fill:#fff}.st2{fill:', colourToUse,'}.st3{font-family:andale mono,monospace}</style>',
                '<path d="M0 .5h1000v1000H0z" style="fill:#333"/><path d="M99.2 321.2h52.5l21.6-21.7h482.2l6.5 11.6h154.1l6.1-11.2h65.7l16 15.9v44.1l-13.6 13.7v150.6h13.6v68.3l11.5 11.3v63.3l-11.5 9.8H605.4l-16 15.9H99.2l-14.6-7.4v-48.3l10-11.4V496.2l-10-15.6V344z"/><path d="M877.4 635.7h-280V355.1l255-.7v169.9l24.9 24.9.1 86.5zM599.1 634h276.5v-84.2l-24.9-24.9V356l-251.6.8V634z" class="st1"/><path d="M882.3 313.6h-52l-6.1 11.2H653.8l-6.4-11.5H179L157.3 335h-51.2v6.4H160l21.7-21.7h462l6.4 11.5h178l6.1-11.1h45.4l6.8 6.7 4.6-4.5zM114.8 490.3l-11.9-18.5-5.4 3.5 10.8 16.8V631l-10.1 11.3v34.6l5.7 2.9 3.1-5.8-2.2-1v-28.1l10-11.4zM895.2 608.6v47.9H595.9v6.7h302.9l2.9-2.4v-52.2z" class="st2"/><path d="m577.7 661.1 3.7-2v-.3l-3.7-2v-3.1h.2l5.3 3.2v4.1l-5.3 3.2h-.2v-3.1zm5.8 0 3.7-2v-.3l-3.7-2v-3.1h.2l5.3 3.2v4.1l-5.3 3.2h-.2v-3.1z" class="st1"/><path d="M228.4 685.7h249.7v14.7H228.4z" class="st2"/><path d="M333.3 438.7v35.1l-10 3.4c-3.1-2.5-7.3-5.9-12.7-10.3-5.4-4.4-8.6-7-9.7-8l-.2.2v17.3h-14.2v-34.8l10.7-3.7c2.4 2 5.6 4.7 9.8 8.1 4.2 3.4 8.1 6.3 12 9.2h.2v-16.4h14.1v-.1zM374.3 450.4h-21v3.9h20.5v9.2h-19.9v13h-14.4V438.9H374.4l-.1 11.5zM419.7 451.6h-13.3v24.8h-14.2V451.6H379v-12.9h40.3l.4 12.9zM209 514.8l-12.7 3.6-5.1-16.1h-.2c-.3.5-1.5 2.4-3.6 5.4s-3.4 5.3-4.1 6.6h-10.2c-1.7-2.7-3.2-5.1-4.4-7-1.4-1.9-2.4-3.4-3.1-4.6h-.3c-.3.8-1.2 3.4-2.4 7.6-1.4 4.2-2.2 6.8-2.5 7.8l-12.5-3.6c1-3.6 2.5-9 4.7-16.4 2.2-7.5 3.4-11.7 3.6-12.5l13.2-1c.3.7 1.2 2.4 2.9 5.4 1.7 3.1 3.7 6.4 6.1 10.2h.2c1.5-2.5 3.4-5.8 5.6-9.5 2.2-3.7 3.6-5.8 3.7-6.3l13.7 1.2c.2.5 1 4.4 2.9 12 2 7.7 3.5 13.5 4.5 17.2zM246.2 517.5h-34.1v-32.4h33.8v9.5H225v3.1h20.4v7h-20.5v3.2H246l.2 9.6zM284.1 517.5h-32.8v-32.1H265v21.5h19l.1 10.6zM327.3 508.1c0 2.2-.8 4.1-2.5 5.6-1.7 1.7-4.2 2.7-7.5 3.2-2.2.3-5.1.5-8.5.5H286.9v-32.2h4.2c2.7 0 4.6-.2 5.9-.2 3.1 0 6.3 0 9.7.2 3.4.2 6.1.3 8.1.7 2.7.5 4.9 1.5 6.4 2.9s2.2 2.9 2.2 4.6c0 1.2-.3 2.5-1.2 3.6-.8 1.2-2.5 2.2-5.1 3.1 1.2.2 2 .3 2.9.5.8.2 1.7.5 2.5.8 1.5.7 2.5 1.5 3.4 2.9 1.1 1.4 1.4 2.6 1.4 3.8zm-13.9-2.4c0-.5-.2-1-.5-1.5-.3-.3-.8-.7-1.4-.8-.8-.2-1.7-.3-2.5-.5s-1.7-.2-2.5-.2h-1.4l-1.2-3.4c.7 0 1.4-.2 2-.2.8-.2 1.5-.3 2.2-.5s1.2-.5 1.5-1c.3-.3.5-1 .5-1.7 0-.3-.2-.8-.7-1.4s-1-.8-1.9-1.2c-.8-.3-1.7-.3-2.7-.3h-4.6V508.7h3.6c2.4 0 3.9 0 4.7-.2.8 0 1.5-.2 2-.3 1.2-.2 1.9-.5 2.4-1.2.2-.1.5-.8.5-1.3zM376.8 501.6c0 2.4-.7 4.7-1.9 6.8-1.2 2.2-3.1 4.1-5.8 5.9-1.9 1.4-4.2 2.4-7 3.1-2.9.7-5.9 1-9.3 1-3.2 0-6.1-.3-8.8-1-2.7-.7-5.1-1.7-7.3-3.1-2.5-1.9-4.6-3.7-5.8-5.9-1.4-2.2-1.9-4.4-1.9-7 0-2.5.7-4.9 1.9-7s2.9-4.1 5.1-5.6 4.7-2.7 7.5-3.6c2.7-.7 5.9-1.2 9.5-1.2s6.6.3 9.3 1c2.9.7 5.3 1.9 7.5 3.4 2.5 1.7 4.4 3.6 5.4 5.8 1.1 2.3 1.6 4.7 1.6 7.4zm-13.9-.3c0-1.4-.3-2.4-1-3.2-.7-.8-1.7-1.5-2.9-2-.8-.3-1.9-.7-2.9-.8-1-.2-2.2-.3-3.4-.3-1.4 0-2.5.2-3.6.3-1 .2-1.9.5-2.7 1-1.2.7-2 1.4-2.7 2.2-.7.8-.8 1.9-.8 3.1 0 1 .3 1.9.8 2.9s1.5 1.7 3.1 2.5c1 .5 2 .8 3.1.8 1 0 2.2.3 3.2.3 1.2 0 2.2 0 3.2-.2.8-.2 1.9-.5 3.1-1 1.4-.5 2.4-1.4 2.9-2.5.5-1.3.6-2.3.6-3.1zM423.8 485.3v17.4c0 3.4-.7 5.9-1.9 7.8-1.2 1.9-2.7 3.4-4.6 4.4-2.5 1.4-4.7 2.4-7 2.7-2.2.3-4.9.7-8.1.7-3.7 0-6.6-.3-9.2-1-2.5-.7-4.6-1.5-6.4-2.5-2-1.2-3.4-2.7-4.4-4.6-1-1.9-1.5-4.4-1.5-7.8V485h13.6v16.4c0 2.2.7 3.7 2 4.6 1.4.8 3.2 1.2 5.8 1.2s4.4-.5 5.8-1.4c1.5-1 2.2-2.4 2.2-4.2v-17h13.7v.7zM471.4 513.1l-11.7 5.3c-.8-1-2.7-3.1-5.6-6.1-2.9-3.1-5.4-5.8-7.8-8.3l.3-.8c.8 0 1.9 0 2.5-.2.8-.2 1.7-.5 2.5-1s1.2-1 1.5-1.7c.2-.7.3-1.2.3-1.5 0-.7-.3-1.4-.8-2-.5-.7-1.4-1.2-2.5-1.5-.7-.2-1.5-.3-2.4-.5-.8-.2-1.9-.2-3.1-.2h-1.5v23h-13.6V485.6H439.1c4.2 0 7.8 0 10.5.2 2.9.2 5.3.3 7.6.8 3.4.7 5.8 1.9 7.5 3.4s2.5 3.4 2.5 5.6c0 1.7-.3 3.2-1 4.6-.7 1.4-2 2.4-3.9 3.2v.2l3.6 3.6c1.5 1 3.3 3.2 5.5 5.9zM518.7 485.3v30.1l-9.3 2.9c-2.9-2-7-5.1-11.9-8.8-5.1-3.7-8-5.9-9.2-6.8h-.2v14.9h-13.4v-29.9l10-3.2c2.2 1.9 5.3 4.1 9.2 7 3.9 2.9 7.6 5.4 11.4 7.8h.2v-14.1l13.2.1zM558.6 517.5h-34.1v-32.4h33.8v9.5h-20.9v3.1h20.4v7h-20.5v3.2H558.4l.2 9.6z" class="st1"/>',
                '<text class="st1 st3" style="font-size:58px" transform="translate(622.828 423.771)">TICKET</text>',
                '<text class="st2 st3" style="font-size:22px" transform="translate(609.54 617.254)">', currentTierName,'</text>',
                '<text class="st1 st3" style="font-size:48px" transform="translate(609.54 588.877)">#', currentNum,'</text>',
                '<text class="st2 st3" style="font-size:33px" transform="translate(271.327 559.038)">23.03.23</text>',
                '<path d="M365.6 590.2c0-2.1-1.2-3.9-2.9-4.8.2-.6.3-1.2.3-1.9 0-2.9-2.3-5.3-5.1-5.3-.6 0-1.2.1-1.8.3-.8-1.8-2.6-3-4.6-3s-3.7 1.2-4.6 3c-.6-.2-1.2-.3-1.8-.3-2.8 0-5.1 2.4-5.1 5.3 0 .7.1 1.3.3 1.9-1.7.9-2.9 2.7-2.9 4.8 0 2 1 3.7 2.6 4.6v.7c0 2.9 2.3 5.3 5.1 5.3.6 0 1.2-.1 1.8-.3.8 1.8 2.6 3 4.6 3 2 0 3.7-1.2 4.6-3 .6.2 1.2.3 1.8.3 2.8 0 5.1-2.4 5.1-5.3v-.7c1.6-.8 2.6-2.6 2.6-4.6zm-8.8-4.4-5.8 8.6-.3.3c-.1.1-.2.1-.4.1h-.4c-.1 0-.3-.1-.4-.1l-.2-.1-3.2-3.2c-.1-.1-.2-.2-.2-.3-.1-.1-.1-.3-.1-.4s0-.3.1-.4c0-.1.1-.2.2-.3.1-.1.2-.2.3-.2.1 0 .3-.1.4-.1.1 0 .3 0 .4.1.1 0 .2.1.3.2l2.4 2.3 5.1-7.6c.1-.2.4-.4.6-.4h.4c.1 0 .3.1.4.1s.2.2.3.3c.1.1.1.2.1.4v.4c.2.1.1.2 0 .3z"/>'
            '</svg>'         
        );
    }

    function buildMetadata(uint256 _tokenId) public view returns (string memory) {

        Ticket memory currentTicket = tickets[_tokenId];

        bytes memory svg = buildImage(_tokenId);

        string memory name = string(
            abi.encodePacked(
                "#", toString(currentTicket.num)," ", currentTicket.tierName
            )
        );

        string memory description = string(
            abi.encodePacked(
                currentTicket.tierName, " to ", EVENT_NAME, " ", YEAR
            )
        );

        bytes memory metadata = abi.encodePacked(
            '{',
                '"name":"', name,'",', 
                '"description":"', description,'",',
                '"image": ',
                    '"data:image/svg+xml;base64,',
                    Base64.encode(svg),
                    '",',
                '"attributes": [', attributes(currentTicket), ']',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metadata)
            )
        );
    }

    /// @dev Render the JSON atributes for a given Ticket token.
    /// @param currentTicket The ticket to render.
    function attributes(Ticket memory currentTicket) public pure returns (bytes memory) {

        return abi.encodePacked(
            trait('Tier', currentTicket.tierName  , ','),
            trait('GM Count', toString(currentTicket.gmCount) , '')
        );
    }

    /// @dev Generate the XML for a single attribute.
    /// @param traitType The `trait_type` for this trait.
    /// @param traitValue The `value` for this trait.
    /// @param append Helper to append a comma.
    function trait(string memory traitType, string memory traitValue, string memory append) public pure returns (string memory) {
        return string(abi.encodePacked(
            '{',
                '"trait_type": "', traitType, '",'
                '"value": "', traitValue, '"'
            '}',
            append
        ));
    }

    /// @dev Random number between 0 10
    function random() private view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1),
            block.timestamp)));
        randomHash = randomHash % 10;
        if(randomHash == 0) randomHash = 1;
        return randomHash;
    } 

    /// from: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Strings.sol
    /// @dev Converts a `uint256` to its ASCII `string` decimal representation.
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}