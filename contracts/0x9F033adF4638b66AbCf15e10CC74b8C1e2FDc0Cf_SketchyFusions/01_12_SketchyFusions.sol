// SPDX-License-Identifier: MIT

/*
    ███████ ███████ ███    ██ 
    ██      ██      ████   ██ 
    ███████ █████   ██ ██  ██ 
         ██ ██      ██  ██ ██ 
    ███████ ██      ██   ████
**/

// Sketchy Fusions

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SketchyFusions is ERC721, Ownable {
    using Strings for uint256;

    bool public revealed = false;
    bool public paused = true;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    IERC721 public comicPower;
    IERC721 public sabc;

    uint256 public requiredComicPower = 3;

    constructor() ERC721("Sketchy Fusions", "SFN") {
        setHiddenMetadataUri(
            "ipfs://QmeR9Z8XYyEtFyUsymUw46URVNCEBtWAAzKSvAMkcypmYi/hidden.json"
        );
    }

    function fuse(uint256 tokenId) public {
        require(!paused, "The contract is paused!");
        require(
            comicPower.balanceOf(msg.sender) >= requiredComicPower,
            "Not enough comic power"
        );
        require(
            sabc.ownerOf(tokenId) == msg.sender,
            "Not the owner of this SABC"
        );
        _mintFusion(msg.sender, tokenId);
    }

    function fuseMultiple(uint256[] memory tokenIds) public {
        require(!paused, "The contract is paused!");
        require(
            comicPower.balanceOf(msg.sender) >= requiredComicPower,
            "Not enough comic power"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                sabc.ownerOf(tokenIds[i]) == msg.sender,
                "Not the owner of this SABC"
            );
            _mintFusion(msg.sender, tokenIds[i]);
        }
    }

    function _mintFusion(address to, uint256 tokenId) private {
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function walletOfOwner(
        address _owner,
        uint256 _startId,
        uint256 _endId
    ) public view returns (uint256[] memory) {
        uint256 ownerBalance = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerBalance);
        uint256 currentResultIndex = 0;

        for (
            uint256 i = _startId;
            currentResultIndex < ownerBalance && i <= _endId;
            i++
        ) {
            if (_exists(i)) {
                address currentTokenOwner = ownerOf(i);

                if (currentTokenOwner == _owner) {
                    tokenIds[currentResultIndex] = i;
                }

                currentResultIndex++;
            }
        }

        return tokenIds;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setComicPower(address _address) public onlyOwner {
        comicPower = IERC721(_address);
    }

    function setSabc(address _address) public onlyOwner {
        sabc = IERC721(_address);
    }

    function setRequiredComicPower(uint256 _requiredComicPower)
        public
        onlyOwner
    {
        requiredComicPower = _requiredComicPower;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}