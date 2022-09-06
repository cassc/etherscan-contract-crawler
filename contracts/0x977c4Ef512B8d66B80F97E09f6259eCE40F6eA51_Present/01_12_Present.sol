// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./WriteSVG.sol";

//__/\\\________/\\\__/\\\\\\\\\\\\\____/\\\\\\\\\\\\___________________/\\\\\\\\\\\________/\\\\\\\\\__/\\\________/\\\_
//__\/\\\_______\/\\\_\/\\\/////////\\\_\/\\\////////\\\________________\/////\\\///______/\\\////////__\/\\\_____/\\\//__
//___\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\______\//\\\___________________\/\\\_______/\\\/___________\/\\\__/\\\//_____
//____\/\\\\\\\\\\\\\\\_\/\\\\\\\\\\\\\\__\/\\\_______\/\\\___________________\/\\\______/\\\_____________\/\\\\\\//\\\_____
//_____\/\\\/////////\\\_\/\\\/////////\\\_\/\\\_______\/\\\___________________\/\\\_____\/\\\_____________\/\\\//_\//\\\____
//______\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\_______\/\\\___________________\/\\\_____\//\\\____________\/\\\____\//\\\___
//_______\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\_______/\\\_____________/\\\___\/\\\______\///\\\__________\/\\\_____\//\\\__
//________\/\\\_______\/\\\_\/\\\\\\\\\\\\\/__\/\\\\\\\\\\\\/_____________\//\\\\\\\\\_________\////\\\\\\\\\_\/\\\______\//\\\_
//_________\///________\///__\/////////////____\////////////________________\/////////_____________\/////////__\///________\///__

contract Present is ERC721, WriteSVG {
    string signatures = "";
    uint256 SIGN_OFFSET_Y = 70;
    uint256 CARD_HEIGHT = 102;
    mapping(address => bool) signed;

    constructor() ERC721("HBD JCK", "HBD") {
        // HBD JCK
        _safeMint(0xD1295FcBAf56BF1a6DFF3e1DF7e437f987f6feCa, 34);
    }

    /// @notice Say happy birthday to Jack!
    function signCard(string memory name) public returns (bool) {
        bytes memory byteName = bytes(name);
        require(!signed[msg.sender], "You can only sign once");
        require(!(byteName.length <= 0), "No signature");
        require(!(byteName.length >= 10), "Signature must be 10 or less characters");
        require(block.timestamp <= 1660453200, "Jacks birthday is over");
        require(!hasSpace(name), "Signatures must be without spaces");

        signatures = string(abi.encodePacked(signatures,signSVG(name)));
        signed[msg.sender] = true;
        return true;
    }

    /// @dev There can ever only be one token. HBD JCK.
    function totalSupply() public pure returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId == 34, "This isn't Jacks birthday");

        string memory present = string(abi.encodePacked("<svg viewBox='0 0 100 ",Strings.toString(CARD_HEIGHT),"' width='500' xmlns='http://www.w3.org/2000/svg'><rect x='0' y='0' width='100%' height='100%' fill='#000'/><g transform='scale(1) translate(44.5, 40)' fill='#fff' fill-rule='evenodd' clip-rule='evenodd' aria-label='HBD'><g transform='translate(0)'><path d='M0 0H1L1 2H2V0H3V2V3V5H2V3H1V5H0V0Z'/></g><g transform='translate(4)'><path d='M1 0H0V5H1H2H3V3H2V2H3V0H2H1ZM2 2H1V1H2V2ZM2 4V3H1V4H2Z'/></g><g transform='translate(8)'><path d='M0 1V4V5H1H2H3V1H2V0H1H0V1ZM2 4V1L1 1V4H2Z'/></g></g><g transform='scale(1) translate(42, 50)' fill='#fff' fill-rule='evenodd' clip-rule='evenodd' aria-label='JACK'><g transform='translate(0)'><g transform='translate(0)'><path d='M0 0H2H3V1V4V5H2H1H0V4V3H1V4H2V1L0 1V0Z'/></g><g transform='translate(4)'><path d='M0 3V5H1V3L2 3V5H3V3V2V1V0H2H1H0V1V2V3ZM1 2H2V1H1V2Z'/></g><g transform='translate(8)'><path d='M0 0H1H3V1L1 1V4H3V5H1H0V4V1V0Z'/></g><g transform='translate(12)'><path d='M1 0H0V2V3V5H1V3H2V5H3L3 3H2V2H3L3 0H2L2 2H1V0Z'/></g><g transform='translate(16)'><path d='M0 3H1L1 0H0V3ZM0 5H1L1 4H0V5Z'/></g></g></g><rect x='41' y='64' width='19' height='1' fill='#F9F9F9'/>"));
        present = string(abi.encodePacked(present,signatures,"</svg>"));
        present = string(abi.encodePacked("data:image/svg+xml;base64,",Base64.encode(bytes(present))));

        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "HBD JCK",',
                '"description": "Happy Birthday Jack - VV",',
                '"image": "', present, '"'
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    function signSVG(string memory name) private returns (string memory) {
        SIGN_OFFSET_Y += 5;
        CARD_HEIGHT += 5;
        return write(name,"#999",1,SIGN_OFFSET_Y*2);
    }

    function hasSpace(string memory name) pure internal returns (bool) {
        for(uint256 i = 0; i < bytes(name).length; i++) {
            bytes memory firstCharByte = new bytes(1);
			firstCharByte[0] = bytes(name)[i];
			uint8 decimal = uint8(firstCharByte[0]);
			if(decimal == 32) {
                return true;
            }
        }

        return false;
    }
}