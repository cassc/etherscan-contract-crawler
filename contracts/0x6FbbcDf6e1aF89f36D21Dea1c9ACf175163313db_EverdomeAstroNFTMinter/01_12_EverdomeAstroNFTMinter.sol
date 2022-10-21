pragma solidity ^0.8.0;
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



interface IMintable{
    function mint(address to, uint256 tokenId) external;
    function owner() external view returns(address);
    function transferOwnership(address newOwner) external;
}

contract EverdomeAstroNFTMinter{
    ERC721 public genesisToken;
    IMintable astro;
    address immutable private deployer;
    uint public startTime;

    constructor(address astro_, 
        address parentToken_)
    {
        genesisToken = ERC721(parentToken_);
        astro = IMintable(astro_);
        deployer = msg.sender;
    }

    function setStartTime(uint256 time) public {
        require(msg.sender == deployer, "no-permissions");
        require(startTime == 0, "already-set");
        startTime = time;
    }


    function mint(uint256 tokenId) public {
        require(block.timestamp >= startTime || startTime == 0, "not-started");
        if(address(genesisToken) != address(0)){
            try genesisToken.ownerOf(tokenId) returns(address owner){
                require(owner == msg.sender, "astro-nft/only-genesis-owner");
            }catch{
                revert("astro-nft/no-coresponding-genesis");
            }
        }
        astro.mint(msg.sender, tokenId);
    }

    function astroOwner() public view returns(address){
        return astro.owner();
    }

    function transferAstroOwnership(address newOwner) public {
        require(msg.sender == deployer, "no-permissions");
        require(startTime == 0, "already-set");
        astro.transferOwnership(newOwner);
    }

}