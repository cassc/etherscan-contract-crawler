// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ShotCallers is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 2500;
    uint256 public constant MAX_PUBLIC_MINT = 5;
    uint256 public constant PUBLIC_SALE_PRICE = .04 ether;

    string private  baseTokenUri;

    bool public publicSale;
    bool public pause;

    mapping(address => uint256) public totalPublicMint;

    constructor() ERC721A("ShotCallers", "SC"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "Already minted 3 times!");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "Below ");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    /// walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }

    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function withdraw() external onlyOwner{
        (bool success, ) = payable(owner()).call{value: address(this).balance}('');
        require(success, 'Withdraw Failed');
    }
}