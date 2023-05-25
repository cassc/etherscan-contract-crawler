// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import './AbstractMintPassFactory.sol';

contract MintPassFactory is AbstractMintPassFactory  {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private mpCounter; 
  
    // new mint passes can be added to support future collections
    mapping(uint256 => MintPass) public mintPasses;
    
    event Claimed(uint index, address indexed account, uint amount);

    struct MintPass {
        bytes32 merkleRoot;
        uint256 windowOpens;
        uint256 windowCloses;
        uint256 mintPrice;
        string ipfsMetadataHash;
        address redeemableContract; // contract of the redeemable NFT
        mapping(address => uint256) claimedMPs;
    }

    constructor(
        string memory _name, 
        string memory _symbol
    ) public ERC1155("ipfs://ipfs/") {
        name_ = _name;
        symbol_ = _symbol;
    }

    function addMintPass(
        bytes32 _merkleRoot, 
        uint256 _windowOpens, 
        uint256 _windowCloses, 
        uint256  _mintPrice, 
        string memory _ipfsMetadataHash,
        address _redeemableContract
    ) external onlyOwner {
        require(_windowOpens < _windowCloses, "addMintPass: open window must be before close window");
        require(_windowOpens > 0 && _windowCloses > 0, "addMintPass: window cannot be 0");

        MintPass storage mp = mintPasses[mpCounter.current()];
        mp.merkleRoot = _merkleRoot;
        mp.windowOpens = _windowOpens;
        mp.windowCloses = _windowCloses;
        mp.mintPrice = _mintPrice;
        mp.ipfsMetadataHash = _ipfsMetadataHash;
        mp.redeemableContract = _redeemableContract;

        mpCounter.increment();
    }

    function editMintPass(
        bytes32 _merkleRoot, 
        uint256 _windowOpens, 
        uint256 _windowCloses, 
        uint256 _mintPrice, 
        string memory _ipfsMetadataHash,        
        address _redeemableContract, 
        uint256 _mpIndex
    ) external onlyOwner {
        require(_windowOpens < _windowCloses, "editMintPass: open window must be before close window");
        require(_windowOpens > 0 && _windowCloses > 0, "editMintPass: window cannot be 0");

        mintPasses[_mpIndex].merkleRoot = _merkleRoot;
        mintPasses[_mpIndex].windowOpens = _windowOpens;
        mintPasses[_mpIndex].windowCloses = _windowCloses;
        mintPasses[_mpIndex].mintPrice = _mintPrice;    
        mintPasses[_mpIndex].ipfsMetadataHash = _ipfsMetadataHash;    
        mintPasses[_mpIndex].redeemableContract = _redeemableContract;  
    }       

    function burnFromRedeem(
        address account, 
        uint256 mpIndex, 
        uint256 amount
    ) external {
        require(mintPasses[mpIndex].redeemableContract == msg.sender, "Burnable: Only allowed from redeemable contract");

        _burn(account, mpIndex, amount);
    }  

    function claim(
        uint256 numPasses,
        uint256 index,
        uint256 amount,
        uint256 mpIndex,
        bytes32[] calldata merkleProof
    ) external payable {
        // verify contract is not paused
        require(!paused(), "Claim: claiming is paused");
        // verify mint pass for given index exists
        require(mintPasses[mpIndex].windowOpens != 0, "Claim: Mint pass does not exist");
        // Verify within window
        require (block.timestamp > mintPasses[mpIndex].windowOpens && block.timestamp < mintPasses[mpIndex].windowCloses, "Claim: time window closed");
        // Verify minting price
        require(msg.value >= numPasses.mul(mintPasses[mpIndex].mintPrice), "Claim: Ether value incorrect");
        // Verify numPasses is within remaining claimable amount 
        require(mintPasses[mpIndex].claimedMPs[msg.sender].add(numPasses) <= amount, "Claim: Not allowed to claim given amount");

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
        require(
            MerkleProof.verify(merkleProof, mintPasses[mpIndex].merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        uint256 excessPayment = msg.value.sub(numPasses.mul(mintPasses[mpIndex].mintPrice));
        if (excessPayment > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessPayment}("");
            require(returnExcessStatus, "Error returning excess payment");
        }
        
        mintPasses[mpIndex].claimedMPs[msg.sender] = mintPasses[mpIndex].claimedMPs[msg.sender].add(numPasses);
        _mint(msg.sender, mpIndex, numPasses, "");

        emit Claimed(index, msg.sender, numPasses);
    }
    
    function withdrawEther(address payable _to, uint256 _amount) public onlyOwner
    {
        _to.transfer(_amount);
    }

    function getClaimedMps(uint256 poolId, address userAdress) public view returns (uint256) {
        return mintPasses[poolId].claimedMPs[userAdress];
    }

    function uri(uint256 _id) public view override returns (string memory) {
            require(totalSupply(_id) > 0, "URI: nonexistent token");
            
            return string(abi.encodePacked(super.uri(_id), mintPasses[_id].ipfsMetadataHash));
    }    
}