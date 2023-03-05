// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Phase3.sol";

contract SoulOokami is ERC721, Ownable {
    using Counters for Counters.Counter;
    Joumeijin Hunter;

    event Attest(address indexed to, uint256 indexed tokenId);
    event Revoke(address indexed to, uint256 indexed tokenId);
    event claimedBy(string indexed DiscordID);
    mapping(uint256 => bool) public claimed;
    Counters.Counter public supply;
    uint256 public Price = 0.01 ether;
    uint256 MAX_SUPPLY = 47;
    address private immutable _hunterAddress = 0x3591aF9168C0049ed9ee63fC0EE5713657A953c9;
    string public uri = "https://bafybeibmbdqehujjyar3odu3l4cx6wufifw67irk4umqwh5kemxbgptafi.ipfs.nftstorage.link/Ookami.json";

    constructor() ERC721("Ookami", "OKA") {
        supply.increment();
        Hunter = Joumeijin(_hunterAddress);
    }

    function OwnerMint(address to) public onlyOwner {
        uint256 tokenId = supply.current();
        supply.increment();
        _mint(to, tokenId);
    }

    

    function setPrice(uint256 price) public onlyOwner {
        Price = price;
    }

    function burn(uint256 tokenId) external{

        require(ownerOf(tokenId) == msg.sender, "only owner can burn");
        _burn(tokenId);
    }

    function revoke(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function Claim(string memory DiscordID, uint256 tokenNumber) payable external {
        require(msg.value == Price,"wrong value");
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        require(!claimed[tokenNumber],"Already Claimed");
        require(Hunter.ownerOf(tokenNumber) == msg.sender ,"You dont own an Ookami");


        uint256 tokenId = supply.current();
        require(supply.current() < MAX_SUPPLY, "max supply reached");
        supply.increment();
        claimed[tokenNumber] = true;
        _mint(msg.sender, tokenId);
        emit claimedBy(DiscordID);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override virtual {

        require(from == address(0) || to == address(0),"no transfer");
        
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override virtual {

        if(from == address(0)){
            emit Attest(to, tokenId);

        } else if(to == address(0)){
            emit Revoke(to, tokenId);
        }
    }


    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return uri;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}