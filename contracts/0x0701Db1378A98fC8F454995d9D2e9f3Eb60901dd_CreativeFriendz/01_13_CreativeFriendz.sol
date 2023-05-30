// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "erc721a/contracts/ERC721A.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


/*
The Creative Friendz NFT is a limited edition membership pass and digital collectible item.
The Copyright of the artwork attached to it remains with German Gonzalez and it's not been transferred to holders.
You do not receive commercial rights in the corresponding artwork
*/
contract CreativeFriendz is ERC721A, Ownable{
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MINT_PRICE = 0.06 ether;
    uint128 public constant MAX_MINT_QUANTITY = 3;
    uint128 public constant MAX_SUPPLY = 8888;
    address[] public team;

    mapping(address => uint32) public minters;
    string private baseURI;
    bool public publicSale;
    bool public paused = true;
    bytes32 public merkleRoot;

    constructor(address[] memory _team, bytes32 _merkleRoot)
        ERC721A("Creative Friendz", "TCFC")
    {

        team = _team;
        merkleRoot = _merkleRoot;

        uint256 tLength = team.length;
        for(uint128 i = 0; i < tLength; i+=1){
            safeMint(team[i], 1);
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: token not found");

        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }


    function reserve(uint32 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Quantity exceeds supply");

        safeMint(msg.sender, _quantity);
    }

    function MintFriendz(uint32 _quantity, bytes32[] calldata merkleProof, uint256 maxAmount) external payable {
        require(!paused, "Contract is paused");
        require(_quantity <= (maxAllowed(merkleProof, msg.sender, maxAmount) - minters[msg.sender])  , "Quantity exceeds allowed purchase limit");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Quantity exceeds supply");
        require(MINT_PRICE.mul(_quantity) <= msg.value, "Amount of ether sent does not match total mint amount");

        safeMint(msg.sender, _quantity);
    }

    function safeMint(address to, uint32 _quantity) private  {
        _safeMint(to, _quantity);
        minters[to] += _quantity;
    }


    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }


    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        MINT_PRICE = _mintPrice;
    }


    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }


    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }


    function togglePaused() external onlyOwner {
        paused = !paused;
    }


    function maxAllowed(
        bytes32[] calldata merkleProof,
        address sender,
        uint256 maxAmount
    ) public view returns (uint256) {
       bool isVerified = _verify(merkleProof, sender, maxAmount);
        if(!isVerified && !publicSale) {
            return 0;
        }
        if(isVerified && !publicSale) {
            return maxAmount;
        }
        if(!isVerified && publicSale) {
            return MAX_MINT_QUANTITY;
        }

        return MAX_MINT_QUANTITY + maxAmount;
    }


    function _verify(
        bytes32[] calldata merkleProof,
        address sender,
        uint256 maxAmount
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender, maxAmount.toString()));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }



    function withdraw() external onlyOwner {
        (bool sentCreator, ) = payable(0xdA905DE41ab2C756F038a2F4d5B4E9dC5E9Ecc21).call{value: address(this).balance * 5 / 100}("");
        require(sentCreator);

        uint256 amount = address(this).balance;
        uint256 tLength = team.length;
        uint _each = amount.div(tLength);
        for(uint256 i = 0; i < tLength; i+=1) {
            (bool sent,) = team[i].call{value: _each}("");
            require(sent);
        }
    }
}