// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721AUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract DragonGuild is Initializable, ERC721AUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    string public baseURI;
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmount;
    bytes32 public root;
    bool public paused;
    bool public onlyWhiteList;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        bytes32 _root
    ) public initializer {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();
        setBaseURI(_initBaseURI);
        cost = 1 ether;
        maxSupply = 8888;
        maxMintAmount = 10;
        paused = true;
        onlyWhiteList = true;
        root = _root;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        if (onlyWhiteList) {
            return MerkleProofUpgradeable.verify(proof, root, leaf);
        }
        return true;
    }

    function mint(uint256 _mintAmount, bytes32[] memory proof) public payable {
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not part of Allowlist");
        uint256 supply = totalSupply();
        require(!paused, "Paused");
        require(_mintAmount > 0, "Mintamount too low");
        require(_mintAmount <= maxMintAmount, "Mintamount too high");
        require(supply + _mintAmount <= maxSupply, "Mintamount would increase max supply");

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "not enough ETH");
        }
        _mint(msg.sender, _mintAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721AMetadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _toString(tokenId)
                    )
                )
                : "";
    }

    // only owner
    function ownerMint(uint256 _mintAmount) public onlyOwner {
        uint256 supply = totalSupply();
        require(_mintAmount > 0);
        require(supply + _mintAmount <= maxSupply);
        _mint(msg.sender, _mintAmount);
    }

    function setRoot(bytes32 _newRoot) public onlyOwner {
        root = _newRoot;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelist(bool _state) public onlyOwner {
        onlyWhiteList = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}