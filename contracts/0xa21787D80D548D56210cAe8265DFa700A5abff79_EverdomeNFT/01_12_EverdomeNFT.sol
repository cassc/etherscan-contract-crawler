pragma solidity ^0.8.0;
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract EverdomeNFT is ERC721, Ownable{
    string constant BASE_URL = "http://api.everdome.io/nft/astro/";//another possible "https://everdome.io/api/nft/plots"
    uint256 constant MAX_TOTAL_SUPPLY = 10000;
    uint256 public totalSupply;
    using MerkleProof for bytes32[];
    constructor(string memory name_, string memory symbol_)
    ERC721(name_, symbol_)
    {
        totalSupply = 0;
    }

    function exists(uint256 tokenId) public view returns(bool){
        return _exists(tokenId);
    }

    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Only owner can burn");
        _burn(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return BASE_URL;
    }

    function mint(address to, uint256 tokenId) public onlyOwner{
        totalSupply++;
        require(MAX_TOTAL_SUPPLY>=totalSupply,"EverdomeStakingNFT/too-many-tokens");
        _mint(to , tokenId);
    }
}