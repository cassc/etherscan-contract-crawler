// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.0;

contract AlphaBettyDoodles is ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 10000;

    uint256 private _launchTimeEpochSeconds = 1628283600;

    string private _baseTokenURI = "https://d7wwabszc3xro.cloudfront.net/";
    bool private _ripCord = false;

    constructor() ERC721("AlphaBetty Doodles", "ALPHABETTY") {}

    function setLaunchTime(uint256 time) public onlyOwner {
        _launchTimeEpochSeconds = time;
    }
    
    function setRipCord(bool val) public onlyOwner {
        _ripCord = val;
    }

    function getLaunchTime() public view returns (uint256) {
        return _launchTimeEpochSeconds;
    }

    function isLaunched() public view returns (bool) {
        return block.timestamp >= _launchTimeEpochSeconds && !_ripCord;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory) {

        uint256 totalSupply = totalSupply();
        require(_tokenId < totalSupply, "That token hasn't been minted yet");
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    function mintOwnerTokens() public onlyOwner {
        require(block.timestamp < _launchTimeEpochSeconds, "Can only reserve prior to launch");
        uint256 totalSupply = totalSupply();
        require(totalSupply < 200, "200 tokens already minted.");
        for (uint256 index; index < 50 && index + totalSupply < 200; index++) {
            _safeMint(owner(), index + totalSupply);
        }
    }

    function mint(uint256 _count) public payable {  
        uint256 price = 30000000000000000; // 0.03 eth in wei
        uint256 totalSupply = totalSupply();

        require(totalSupply < MAX_SUPPLY, "Sold out");
        require(totalSupply + _count <= MAX_SUPPLY, "Not enough tokens left");
        require(_count <= 20, "Mint 20 or fewer, please.");
        require(msg.value >= price * _count, "The value submitted with this transaction is too low.");
        require(block.timestamp >= _launchTimeEpochSeconds, "Not on sale yet.");
        require(_ripCord == false, "Sales temporarily disabled. Check back soon");

        for (uint256 i; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}