// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NUTSPriorityPass is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";

    bool public paused = false;
    uint256 public cost = 0.2 ether;
    uint256 public constant MAX_SUPPLY = 3500;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function mint(address _recipient, uint256 _amount) public payable {
        require(!paused, "Minting is currently paused");
        require(msg.value >= _amount * cost, "Insufficient funds sent");

        uint256 supply = totalSupply();
        require(
            supply + _amount <= MAX_SUPPLY,
            "Insufficient supply remaining"
        );

        _safeMint(_recipient, _amount);
    }

    function airdrop(address _recipient, uint256 _amount) public onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + _amount <= MAX_SUPPLY,
            "Insufficient supply remaining"
        );

        _safeMint(_recipient, _amount);
    }

    function burn(uint256 _tokenId) public onlyOwner {
        _burn(_tokenId);
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

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success);
    }
}