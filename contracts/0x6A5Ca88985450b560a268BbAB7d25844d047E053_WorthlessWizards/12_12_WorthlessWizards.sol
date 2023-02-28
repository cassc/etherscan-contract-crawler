// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WorthlessWizards is ERC721, Ownable {
    using Strings for uint256;
    bool public isPublic = false;
    string public baseURI;
    uint256 public maxMints = 2;
    uint256 public maxSupply = 200;
    uint256 public worth = 0.01 ether;    
    uint256 private _counter = 1;
    string private _baseExtension = ".json";    
    mapping(address => uint256) private _mints;

    constructor() ERC721("Worthless Wizards", "WWIZ") {
        setBaseURI("ipfs://bafybeibc4gb2nwck7k6z5evgavuqfmt3qazjexdbvjsbwbexvvgcl2ahqi/");
    }

    function worthlessMint() external payable {
        require(msg.value >= worth, "Not enough ETH");
        require(_counter <= maxSupply, "Max supply reached");
        require(_mints[msg.sender] < maxMints, "Max mints reached");
        _mints[msg.sender] += 1;
        _safeMint(msg.sender, _counter);
        _counter += 1;
    }

    function publicMint() external {
        require(isPublic, "Not public");
        require(_counter <= maxSupply, "Max supply reached");
        require(_mints[msg.sender] < maxMints, "Max mints reached");
        _mints[msg.sender] += 1;
        _safeMint(msg.sender, _counter);
        _counter += 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        _baseExtension
                    )
                )
                : "";
    }

    function setPublic(bool _isPublic) public onlyOwner {
        isPublic = _isPublic;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public payable onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent);
    }
}