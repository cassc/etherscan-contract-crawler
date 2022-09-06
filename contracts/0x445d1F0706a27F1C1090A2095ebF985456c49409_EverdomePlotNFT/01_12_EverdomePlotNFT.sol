pragma solidity ^0.8.0;
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract EverdomePlotNFT is ERC721, Ownable{
    string public constant BASE_URL = "https://api.everdome.io/nft/plots/";
    uint256 constant MAX_TOTAL_SUPPLY = 10000;
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
        return uint(x+(2**32))+uint(y+(2**32))*(2**33);
    }

    function getCoords(uint id) public pure returns(int x, int y){
        y = int(id/(2**33))-2**32;
        x = (int(id%(2**33))-2**32);
    }

    function mint(address to, int x, int y) public onlyOwner{
        totalSupply++;
        require(MAX_TOTAL_SUPPLY>=totalSupply,"EverdomeStakingNFT/too-many-tokens");
        _mint(to , getId(x, y));
    }
}