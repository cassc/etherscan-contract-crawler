// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

//  ________  ___  ___  _______   ________  ___  __    ________
// |\   ____\|\  \|\  \|\  ___ \ |\   ____\|\  \|\  \ |\   ____\
// \ \  \___|\ \  \\\  \ \   __/|\ \  \___|\ \  \/  /|\ \  \___|_
//  \ \  \    \ \   __  \ \  \_|/_\ \  \    \ \   ___  \ \_____  \
//   \ \  \____\ \  \ \  \ \  \_|\ \ \  \____\ \  \\ \  \|____|\  \
//    \ \_______\ \__\ \__\ \_______\ \_______\ \__\\ \__\____\_\  \
//     \|_______|\|__|\|__|\|_______|\|_______|\|__| \|__|\_________\
//                                                       \|_________|

//  ________  ________   ________  ___  ___  ________  ___  ________
// |\   __  \|\   ___  \|\   ____\|\  \|\  \|\   __  \|\  \|\   ___  \
// \ \  \|\  \ \  \\ \  \ \  \___|\ \  \\\  \ \  \|\  \ \  \ \  \\ \  \
//  \ \  \\\  \ \  \\ \  \ \  \    \ \   __  \ \   __  \ \  \ \  \\ \  \
//   \ \  \\\  \ \  \\ \  \ \  \____\ \  \ \  \ \  \ \  \ \  \ \  \\ \  \
//    \ \_______\ \__\\ \__\ \_______\ \__\ \__\ \__\ \__\ \__\ \__\\ \__\
//     \|_______|\|__| \|__|\|_______|\|__|\|__|\|__|\|__|\|__|\|__| \|__|

contract ChecksOnChain is
    ERC721A,
    ERC2981,
    Ownable,
    Pausable,
    DefaultOperatorFilterer
{
    address public game;
    uint256 public price = 0.0042069 ether;

    mapping(string => bool) public colorsIsUsed;
    mapping(uint256 => string) public tokenColors;
    mapping(string => string) public codeToHexColor;

    constructor() ERC721A("CHECKED", "CHKD") {
        _pause();
        _setDefaultRoyalty(owner(), 250);
        codeToHexColor["1"] = "#B80000";
        codeToHexColor["2"] = "#DB3E00";
        codeToHexColor["3"] = "#FCCB00";
        codeToHexColor["4"] = "#008B02";
        codeToHexColor["5"] = "#006B76";
        codeToHexColor["6"] = "#1273DE";
        codeToHexColor["7"] = "#004DCF";
        codeToHexColor["8"] = "#5300EB";
        codeToHexColor["9"] = "#000000";
        codeToHexColor["A"] = "#B8000090";
        codeToHexColor["B"] = "#DB3E0090";
        codeToHexColor["C"] = "#FCCB0090";
        codeToHexColor["D"] = "#008B0290";
        codeToHexColor["E"] = "#006B7690";
        codeToHexColor["F"] = "#1273DE90";
        codeToHexColor["G"] = "#004DCF90";
        codeToHexColor["H"] = "#5300EB90";
        codeToHexColor["I"] = "#EEEEEE";
    }

    function setRoyalty(address _receiver, uint96 _feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeBasisPoints);
    }

    function setGame(address _game) external onlyOwner {
        game = _game;
    }

    function burn(uint256 tokenId) external {
        require(msg.sender == game, "NOT_GAME");
        require(isApprovedForAll(msg.sender, game), "NOT_AUTHORIZED");
        _burn(tokenId);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function mint(string calldata colors) external payable whenNotPaused {
        require(msg.value >= price, "INVALID_PRICE");
        require(!colorsIsUsed[colors], "COLORS_USED");

        colorsIsUsed[colors] = true;
        tokenColors[_nextTokenId()] = colors;

        _safeMint(msg.sender, 1);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw(address reciever, uint256 amount) external onlyOwner {
        payable(reciever).transfer(amount);
    }

    function tokenURI(uint256 token)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(token), "NE");
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Check #',
                                    Strings.toString(token),
                                    '", "description": "This collection may or may not be fairer than Checks - all generation stored on-chain", "image": "data:image/svg+xml;base64,',
                                    Base64.encode(bytes(image(token))),
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }

    function image(uint256 token) internal view returns (string memory) {
        string memory tokenColorsEncoded = tokenColors[token];
        bytes memory tokenColorsBytes = bytes(tokenColorsEncoded);

        uint256 offset = 10;
        string memory content = "";

        for (uint256 index = 0; index < 80; index++) {
            uint256 y = (index / 8) * 38 + offset;
            uint256 x = (index % 8) * 38 + offset;

            string memory colorCode = string(
                abi.encodePacked(tokenColorsBytes[index])
            );
            string memory color = codeToHexColor[colorCode];

            content = string(
                abi.encodePacked(
                    content,
                    '<svg viewBox="0 0 64 64" width="24" height="24" x="',
                    Strings.toString(x),
                    '" y="',
                    Strings.toString(y),
                    '"><path fill-rule="evenodd" fill="',
                    color,
                    '" d=',
                    '"m33.12,4.68c-.87-1.43-2.09-2.61-3.55-3.43-1.46-.82-3.1-1.25-4.78-1.25-3.53,0-6.62,1.87-8.33,4.68-1.63-.39-3.33-.36-4.94.09-1.61.45-3.08,1.31-4.26,2.49-1.18,1.19-2.04,2.65-2.49,4.26-.45,1.61-.48,3.31-.09,4.94-1.43.87-2.61,2.09-3.43,3.55-.82,1.46-1.25,3.1-1.25,4.78,0,3.53,1.87,6.62,4.68,8.33-.39,1.63-.36,3.33.09,4.94.45,1.61,1.31,3.08,2.49,4.26,1.19,1.18,2.65,2.04,4.26,2.49s3.31.48,4.94.09c1.21,1.99,3.09,3.48,5.3,4.2,2.21.72,4.61.63,6.76-.26,1.91-.79,3.53-2.17,4.61-3.94,1.63.4,3.33.36,4.94-.09,1.61-.45,3.08-1.31,4.26-2.49s2.04-2.65,2.5-4.27c.45-1.61.48-3.31.08-4.94,1.43-.87,2.61-2.09,3.43-3.55.82-1.46,1.25-3.1,1.25-4.78s-.43-3.32-1.25-4.78c-.82-1.46-2-2.68-3.43-3.55.39-1.63.36-3.33-.09-4.94-.45-1.61-1.31-3.08-2.5-4.26-1.18-1.18-2.65-2.04-4.26-2.5-1.61-.45-3.31-.48-4.94-.09h0Zm-9.81,29.04l11.31-16.97c1.4-2.1-1.86-4.27-3.26-2.18l-9.98,14.98-3.4-3.39c-1.78-1.79-4.55.98-2.77,2.77l5.38,5.33c.21.14.45.24.71.3.25.05.51.05.77,0,.25-.05.49-.15.71-.3.22-.14.4-.33.54-.54h0Z"/></svg>'
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    '<svg width="800" height="800" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 802 802"><rect x="0" y="0" fill="white" width="100%" height="100%"/><rect x="232" y="191" fill="white" width="400" height="400"/><svg x="247" y="206" fill="#fff" width="304" height="380" viewBox="0 0 306 382">',
                    content,
                    "</svg></svg>"
                )
            );
    }

    /**
      @notice This contract is configured to use the DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters. Adding the onlyAllowedOperator modifier to the transferFrom and both safeTransferFrom methods ensures that the msg.sender (operator) is allowed by the OperatorFilterRegistry. Adding the onlyAllowedOperatorApproval modifier to the approval methods ensures that owners do not approve operators that are not allowed.
     */

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}