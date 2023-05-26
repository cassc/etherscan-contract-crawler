// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// Contract imports

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Contract Constructor Variables

contract StreetParkGraffiti is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public cost = 300000000000000000;
    uint256 public maxSupply = 1877;

    string baseURI;
    string public baseExtension = ".json";

    address public artist;
    uint256 public royalityFee;

    uint256 public nextTokenId = 1; 

    event Sale(address from, address to, uint256 value);

    bool public mintIsActive = false;

    // Constructor Variables

    constructor(
        string memory _initBaseURI,
        uint256 _royalityFee,
        address _artist
    ) ERC721("StreetParkGraffiti", "SPG") {
        setBaseURI(_initBaseURI);
        royalityFee = _royalityFee;
        artist = _artist;
    }

    // Public functions

    function mint(uint numberOfTokens) public payable {
        uint256 supply = totalSupply();

        // Mint Tokens functions
        
        require(supply < maxSupply, "Currently sold out");
        require(mintIsActive, "Sale must be active to mint tokens");
        require(msg.value >= cost * numberOfTokens, "Didn't send enough ETH");
        require(supply + numberOfTokens <= maxSupply, "Purchase would exceed max tokens");

        if (msg.sender != owner()) {
            require(msg.value >= cost);

            // Pay royality to artist, the deployer of contract

            uint256 royality = (msg.value * royalityFee) / 100;
            _payRoyality(royality);

            (bool success2, ) = payable(owner()).call{value: (msg.value - royality)}("");
            require(success2);
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId);
            nextTokenId++;
        }
    }

    // Token URI Functions

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    // Transfer From functions

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        if (msg.value > 0) {
            uint256 royality = (msg.value * royalityFee) / 100;
            _payRoyality(royality);

            (bool success2, ) = payable(from).call{value: msg.value - royality}(
                ""
            );
            require(success2);

            emit Sale(from, to, msg.value);
        }

        _transfer(from, to, tokenId);
    }

    // Safe Transfer From functions

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override {
        if (msg.value > 0) {
            uint256 royality = (msg.value * royalityFee) / 100;
            _payRoyality(royality);

            (bool success2, ) = payable(from).call{value: msg.value - royality}(
                ""
            );
            require(success2);

            emit Sale(from, to, msg.value);
        }

        safeTransferFrom(from, to, tokenId, "");
    }

    // Secondary Safe Transfer From functions

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        if (msg.value > 0) {
            uint256 royality = (msg.value * royalityFee) / 100;
            _payRoyality(royality);

            (bool success2, ) = payable(from).call{value: msg.value - royality}(
                ""
            );
            require(success2);

            emit Sale(from, to, msg.value);
        }

        _safeTransfer(from, to, tokenId, _data);
    }

    // Internal Contract functions

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _payRoyality(uint256 _royalityFee) internal {
        (bool success1, ) = payable(artist).call{value: _royalityFee}("");
        require(success1);
    }

    // Owner functions

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function ownerMint(uint256 numberForMint) public onlyOwner {
        uint256 supply = totalSupply();
        require(nextTokenId >= 1, "Owner minting is started");
        require(supply < maxSupply, "Currently sold out");
        
        for (uint256 i = 0; i < numberForMint; i++) {
            _safeMint(msg.sender, nextTokenId);
            nextTokenId++;
        }
    }

    function setMintIsActive(bool newState) public onlyOwner {
        mintIsActive = newState;
    }

    function setRoyalityFee(uint256 _royalityFee) public onlyOwner {
        royalityFee = _royalityFee;
    }

    function setRoyalityAddress(address _artist) public onlyOwner {
        artist = _artist;
    }

    function setMintFee(uint256 _mintFee) public onlyOwner {
        require(_mintFee > 0, "The cost of minting a token should be greater than 0");
        cost = _mintFee;
    }

    function release(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, 'Insufficient balance');
        payable(msg.sender).transfer(amount);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}