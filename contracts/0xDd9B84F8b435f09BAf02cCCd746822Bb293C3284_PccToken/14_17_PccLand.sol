// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./PccTierTwoItem.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "./MintUpdater.sol";

contract PccLand is ERC721, Ownable {

    using Strings for uint256;
    mapping(address => mapping(uint256 => bool)) public HasClaimed;

    uint256 public constant MAX_SUPPLY = 9856;
    uint256 public constant MAX_MINT = 20;
    uint256 public CurrentMaxSupply = 500;
    uint256 public MintPrice = 0.09 ether;
    string public BaseUri;
    uint256 public totalSupply;
    bytes32 public MerkleRoot;
    bool public PublicMintingOpen;
    uint256 public currentPhase;

    ILandMintUpdater public tokenContract;


    constructor()ERC721("Country Club Land", "PCCL") {
        
    }


    function claimLand(bytes32[] memory _proofs, uint256 _quantity) public payable canMint(_proofs, _quantity) {
        require(totalSupply + _quantity < CurrentMaxSupply, "too many minted");
        

        if(msg.value == 0 && !HasClaimed[msg.sender][currentPhase]){
            HasClaimed[msg.sender][currentPhase] = true;
        }

        for(uint256 i; i < _quantity; ){

            _mint(msg.sender, totalSupply);
            tokenContract.updateLandMintingTime(totalSupply);
            unchecked {
                ++i;
                ++totalSupply;
            }
        }

    }


    modifier canMint(bytes32[] memory _proofs, uint256 _qty) {
        if(PublicMintingOpen){
            require(msg.value == MintPrice * _qty, "incorrect ether");
            require(_qty <= MAX_MINT, "too many");
        }
        else{
            require(msg.value == 0, "free");
            
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _qty));
            require(
                MerkleProof.verify(_proofs, MerkleRoot, leaf),
                "not authorised"
            );
            require(!HasClaimed[msg.sender][currentPhase], "already claimed from this wallet");
        }
        _;
    }

    function setMintPrice(uint256 _priceInWei) public onlyOwner {
        MintPrice = _priceInWei;
    }


    function setMerkleRoot(bytes32 _root) public onlyOwner {
        MerkleRoot = _root;
    }

    function setBaseUri(string calldata _uri) public onlyOwner {
        BaseUri = _uri;
    }

    function setTokenContract(address _token) public onlyOwner{
        tokenContract = ILandMintUpdater(_token);
    }

    function setPublicMintingOpen(bool _mintingOpen) public onlyOwner {
        PublicMintingOpen =  _mintingOpen;
    }
    
    function incrementPhase() public onlyOwner {
        unchecked{
            ++currentPhase;
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setTempMaxSupply(uint256 _supply) public onlyOwner {
        require(_supply > totalSupply, "cannot set supply to less than current supply");
        require(_supply <= MAX_SUPPLY, "cannot set supply to higher than max supply");
        CurrentMaxSupply = _supply;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_ownerOf[id] != address(0), "not minted");
        return string(abi.encodePacked(BaseUri, id.toString()));
    }


}