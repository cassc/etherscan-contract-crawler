pragma solidity ^0.8.0;
import { ProofsVerifier } from "./ProofsVerifier.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Mintable {
    function mint(address to, uint256 tokenId) external;
    function exists(uint256 id) external view returns(bool) ;
    function transferOwnership(address newOwner) external ;
}

contract EverdomeNFTClaim is ProofsVerifier {

    bytes32 public root;
    address public token; 
    address public deployer;

    uint256 public lockTime;
    bool public overriden=false;
    uint256 public claimEnd; 


    constructor(bytes32 _root, address _token){
        root = _root;
        token = _token;
        deployer = msg.sender;
    }

    function transferTokenOwnership(address newOwner) public onlyOwner{
        Mintable(token).transferOwnership(newOwner);
    }

    function transferLocked(address token) public {
        IERC20(token).transfer(deployer, IERC20(token).balanceOf((address(this))));
        payable(deployer).transfer(address(this).balance);
    }

    function claimNFT(uint256 nft_id, address owner, bytes32[] calldata proof) public {
        bytes32 leaf = getNode(nft_id, owner);
        require(verify(root, proof, leaf), "proof-incorrect");
        require(Mintable(token).exists(nft_id)==false,"already-minted");
        Mintable(token).mint(owner, nft_id);
    }
}