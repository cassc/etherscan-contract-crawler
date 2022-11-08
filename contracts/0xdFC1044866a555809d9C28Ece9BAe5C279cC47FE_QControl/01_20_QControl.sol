// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./IQControl.sol";
import "./ISymbolControl.sol";
import "./Q.sol";

contract QControl is IQControl, ReentrancyGuard, Ownable {
    Q q;
    ISymbolControl symbolControl;
    uint256 public maxSupply = 3000;
    uint256 public maxMintsPerWallet = 2;
    uint8 public reserved = 20;
    mapping (address => uint256) public mintedTokensPerWallet;

//    uint256 public price = 0.0 ether;

    bool public started;
    bool public enabled;
    string _emoji = unicode"❓";
    mapping (uint256 => string) public _emojis;
    mapping (uint256 => string) public _names;

    string[] public images = [
unicode'<svg width="600" height="600" viewBox="0 0 270 270" fill="none" xmlns="http://www.w3.org/2000/svg"> \
<rect width="270" height="270" fill="url(#paint0_linear)"/> \
<defs><filter id="dropShadow" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"> \
<feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity="1.225" width="200%" height="200%"/></filter></defs>',

'<text x="135" y="85" font-size="70px" text-anchor="middle" fill="black" filter="url(#dropShadow)">',

'</text>',
'<text x="135" y="171" font-size="100px" text-anchor="middle" fill="white" filter="url(#dropShadow)">',

'</text>',
'</svg>'
];


    function tokenURI(uint256 tokenId) override external view returns (string memory) {
        string memory emoji;
        string memory name;
        
        emoji = abi.encodePacked(_emojis[tokenId]).length == 0
            ? _emoji
            : _emojis[tokenId];

        name = _names[tokenId];

        string memory image = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(abi.encodePacked(
            images[0],
            images[1],
            name,
            images[2],
            images[3],
            emoji,
            images[4],
            images[5]
        ))));

        string memory json = Base64.encode( abi.encodePacked(
            unicode'{"name":"',_names[tokenId],emoji,'","description":"',emoji,
            unicode'","attributes":[{ "trait_type": "Emoji", "value": "',emoji,'" }, { "trait_type": "Name", "value": "',name,'" }]',
            ',"image":"', image, '"}'
        ));

        return string(abi.encodePacked('data:application/json;base64,', json));


    }

    /**
    * @notice This sets the emoji for your Q tattoo. Once set, the token permanently etches onto your wallet - you will not be able to sell or transfer it again.
    * @notice Can only be called when enabled.  Check if enabled by checking "enabled" function
    */
    function setEmoji(uint tokenId, string memory emoji) external nonReentrant {
        require(address(symbolControl) != address(0), "zero address");
        require(enabled, 'Disabled');
        symbolControl.isValid(emoji);
        require(symbolControl.isValid(emoji), 'not valid symbol');

        require(_msgSender() == Q(q).ownerOf(tokenId), "Not yours");

        _emojis[tokenId] = emoji;
    }

    /**
    * @notice This sets the name for your Q tat. There's no limit to how many times this can be changed.
    * @notice Can only be called when enabled.  Check if enabled by checking "enabled" function
    */
    function setName(uint tokenId, string memory name) external nonReentrant {
        require(enabled, "Disabled");
        require(_msgSender() == Q(q).ownerOf(tokenId), "Not yours");

        _names[tokenId] = name;
    }

    function getNumReserved() external view returns (uint8 numReserved){
        return reserved;
    }

    function setReserved(uint8 remainder) external onlyOwner {
        reserved = remainder;
    }

    function setQ(address qAddress) external onlyOwner {
        q = Q(qAddress);
    }

    function setSymbolControl(address addr) external onlyOwner {
        symbolControl = ISymbolControl(addr);
    }

    function canMint(uint256 totalSupply, uint8 numToMint) external view {
        require(started, "Not  live");
        require(totalSupply + numToMint <= maxSupply, "Sold out");
        require(mintedTokensPerWallet[msg.sender] + numToMint <= maxMintsPerWallet, "Don't be greedy");
    }

    function setStarted(bool state) external onlyOwner {
        started = state;
    }

    function setEditable(bool state) external onlyOwner {
        enabled = state;
    }

    function setMaxSupply(uint256 max) external onlyOwner {
        maxSupply = max;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(payable(msg.sender).send(_balance));
    }

    function controlBeforeTokenTransfer(address from, address, uint256 tokenId) external view override {
        require(
            from == address(0) || abi.encodePacked(_emojis[tokenId]).length == 0,
            "Tattoos are forever"
        );
    }

    function minted(address _receiver, uint tokenId) external {
        mintedTokensPerWallet[_receiver] = tokenId;
    }

}