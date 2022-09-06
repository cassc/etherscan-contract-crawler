// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Graffiti Wall Contract

// Twitter: @niftyscoops

// Source: https://github.com/chiru-labs/ERC721A
// npm i [email protected]
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract GraffitiWall is
    ERC721A,
    Ownable,
    Pausable
{
    struct Data {
        string message;
        string title;
        string bgColor;
        string fill;
    }

    mapping (uint => Data) public graffiti;
    uint256 public tokenPrice = 500000000000000; //0.0005 ETH

    constructor() ERC721A("Graffiti Wall", "Graffiti") {
    }

    function safeMint(address to) public onlyOwner {
        // Mint 1 token
        _safeMint(to, 1);
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner
    {
        tokenPrice=_tokenPrice;
    }

    function getSvg(uint tokenId) private view returns (string memory) {
        string memory svg = "<svg width='350px' height='350px' xmlns='http://www.w3.org/2000/svg' style='background-color: ";
        svg = string.concat(svg, graffiti[tokenId].bgColor);
        svg = string.concat(svg, ";'><style>.a { fill: ");
        svg = string.concat(svg, graffiti[tokenId].fill);
        svg = string.concat(svg, "; font-size: 18px; }</style><text x='10' y='20' class='a'>");
        svg = string.concat(svg, graffiti[tokenId].message);
        svg = string.concat(svg, "</text></svg>");
        return string(abi.encodePacked(svg));

    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory svgData = getSvg(tokenId);

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', graffiti[tokenId].title, '", "description": "", "image_data": "data:image/svg+xml;base64,', Base64.encode(bytes(svgData)), '"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function mintGraffiti(string memory _message, string memory _title, string memory _bgColor, string memory _fill) public payable whenNotPaused {
        require(msg.value >= tokenPrice, "Ether value sent is too low");
        Data memory data = Data(_message, _title, _bgColor, _fill);

        graffiti[_nextTokenId()] = data;
        _safeMint(_msgSender(), 1);
    }

    function walletOfOwner(address address_)
        external
        view
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOf(address_);
        if (_balance == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory _tokens = new uint256[](_balance);
            uint256 _index;

            uint256 tokensCount = totalSupply();

            for (uint256 i = 0; i < tokensCount; i++) {
                if (address_ == ownerOf(i)) {
                    _tokens[_index] = i;
                    _index++;
                }
            }

            return _tokens;
        }
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        //return super.supportsInterface(interfaceID);
        // Updated for ERC721A V4.x
        return ERC721A.supportsInterface(interfaceID);
    }

    function setTokenMessage(uint tokenId, string memory _message, string memory _title) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        graffiti[tokenId].message = _message;
        graffiti[tokenId].title = _title;
    }

    function getTokenMessage(uint tokenId) external view returns (string memory){
        require(_exists(tokenId), "Token does not exist");
        return(graffiti[tokenId].message);
    }

    function setPaused(bool _paused) public onlyOwner {
        _paused ? _pause() : _unpause();
    }
}