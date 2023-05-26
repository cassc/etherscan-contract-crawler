//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

contract mintNFT721 is
    RevokableDefaultOperatorFilterer,
    ERC721URIStorage,
    Ownable,
    ERC2981
{
    //@notice flg of pause
    bool public paused;

    //@notice totalSupply
    uint256 public totalSupply;

    //@notice maxSupply
    uint256 public maxSupply;

    //@notice cost
    uint256 public cost;

    //@notice merkleRoot
    bytes32 public merkleRoot;

    //@notice userMintedAmount
    mapping(address => uint256) userMintedAmount;

    //@notice baseURI
    string public baseURI;

    //@notice baseExtension
    string public baseExtension = ".json";

    //
    //CONSTRUCTOR
    //

    constructor() ERC721("NFT LIFE CARD", "NLC") {
        paused = true;
        maxSupply = 8000;
        cost = 0;
        merkleRoot = 0xe2cb07aaa9b42679a209214d3e7c704c375424d9b5e5719062c360eefdc71dee;
        setDefaultRoyalty(0x8FD635F6397f11815f1C742909EdCDA596a0AbC9, 1000);
    }

    //
    //MINT
    //

    //@notice mint amount should be fixed one by frontend logic
    function mint(
        uint256 _mintAmount,
        uint256 _maxMintAmount,
        bytes32[] calldata _merkleProof
    ) public {
        //check
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender, _maxMintAmount));
        require(!paused, "The contract is paused");
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, _leaf),
            "user is not allowlisted"
        );
        require(
            _mintAmount + userMintedAmount[msg.sender] <= _maxMintAmount,
            "You have already received"
        );
        require(
            (totalSupply + _mintAmount) <= maxSupply,
            "Mints num exceeded limit"
        );

        //effect
        userMintedAmount[msg.sender] += _mintAmount;
        for (uint256 i = 0; i < _mintAmount; i++) {
            totalSupply += 1;

            //interaction
            _safeMint(msg.sender, totalSupply);
        }
    }

    //@notice tokenURI
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return currentBaseURI;
    }

    //
    //SET
    //

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(
        string memory _newBaseExtension
    ) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    //@notice set Pause
    function setPaused(bool _newPause) external onlyOwner {
        paused = _newPause;
    }

    //@notice set Royality
    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    //@notice set maxMintedNum
    function setMaxSupply(
        uint256 _tokenId,
        uint256 _newNum
    ) external onlyOwner {
        maxSupply = _newNum;
    }

    //@notice set cost
    function setCost(uint256 _tokenId, uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }

    //@notice set merkleRoot
    function setMerkleRoot(
        uint256 _tokenId,
        bytes32 _newMerkleRoot
    ) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    //
    //GET
    //
    function getUserMintedAmount(
        address _user
    ) public view returns (uint256) {
        return userMintedAmount[_user];
    }

    function getWhitelist(
        address _user,
        uint256 _tokenId,
        uint256 _maxMintAmount,
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(_user, _maxMintAmount));
        return MerkleProof.verify(_merkleProof, merkleRoot, _leaf);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    //
    //INTERFACE
    //

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}