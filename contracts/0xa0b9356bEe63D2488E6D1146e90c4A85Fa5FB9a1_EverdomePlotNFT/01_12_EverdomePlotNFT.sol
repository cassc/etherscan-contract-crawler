pragma solidity ^0.8.0;
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract EverdomePlotNFT is ERC721, Ownable{
    string public constant BASE_URL = "https://api.everdome.io/nft/plots/";
    int256 public constant ID_FACTOR = 100_000_000;
    uint256 totalSupply;
    using MerkleProof for bytes32[];
    constructor(string memory name_, string memory symbol_)
    ERC721(name_, symbol_)
    {
        totalSupply = 0;
    }
    
    function exists(uint256 tokenId) public view returns(bool){
        return _exists(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URL;
    }

    function getId(int x, int y) public pure returns(uint256){
        return uint256(x*ID_FACTOR+y);
    }

    function getCoords(uint id) public pure returns(int x, int y){
        y = int(id)%ID_FACTOR;
        x = int(id)/ID_FACTOR;
    }

    function mint(address to, int x, int y) public onlyOwner{
        _mint(to , getId(x, y));
    }

    function mint(address to, uint id) public onlyOwner{
        _mint(to , id);
    }
}