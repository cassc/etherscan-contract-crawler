// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.0;

contract DeadSeal {
    function ownerOf(uint256 tokenId) public view returns (address) {}
}

contract SealsNFT is ERC721Enumerable, Ownable {
    uint256 public constant OWNER_SUPPLY = 5;
    uint256 public constant MAX_SUPPLY = 1805;

    uint256 private _launchTimeEpochSeconds = 1665085538;

    string private _baseTokenURI = "https://nft-airdrop-rho.vercel.app/meta/";
    bool private _ripCord = false;
    uint256 public PRICE = 0;

    DeadSeal private _previous;

    constructor(address _dead) ERC721("SealsNFT", "SEALSNFT") {
        _previous = DeadSeal(_dead);
    }

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

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory) {

        uint256 totalSupply = totalSupply();
        require(_tokenId < totalSupply, "That token hasn't been minted yet");
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId), ".json"));
    }

    function remintEarlyTokens(uint256 _count) public onlyOwner {
        require(block.timestamp < _launchTimeEpochSeconds, "Can only remint prior to launch");
        uint256 totalSupply = totalSupply();
        require(totalSupply + _count < 1000, "Can't remint past token 999");
        for (uint256 index; index < _count && index + totalSupply < 1000; index++) {
            uint256 tokenId = index + totalSupply;
            _safeMint(_previous.ownerOf(tokenId), tokenId);
        }
    }

    function mintOwnerTokens() public onlyOwner {
        // require(block.timestamp < _launchTimeEpochSeconds, "Can only reserve prior to launch");
        uint256 totalSupply = totalSupply();
        require(totalSupply < OWNER_SUPPLY, "Max owner tokens already minted.");
        for (uint256 index; index < 50 && index + totalSupply < OWNER_SUPPLY; index++) {
            _safeMint(msg.sender, index + totalSupply);
        }
    }

    function mint(uint256 _count) public payable {  
        uint256 totalSupply = totalSupply();

        require(totalSupply < MAX_SUPPLY, "Sold out");
        require(totalSupply + _count <= MAX_SUPPLY, "Not enough tokens left");
        require(_count <= 20, "Mint 20 or fewer, please.");
        require(msg.value >= PRICE * _count, "The value submitted with this transaction is too low.");
        require(block.timestamp >= _launchTimeEpochSeconds, "Not on sale yet.");
        require(_ripCord == false, "Sales disabled.");

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