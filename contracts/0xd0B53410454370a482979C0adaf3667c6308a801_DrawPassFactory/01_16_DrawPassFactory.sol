// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import './AbstractERC1155Factory.sol';

/// @author Niftydude
/// @notice Smart contract for Pixelvault ERC1155 coins
contract DrawPassFactory is AbstractERC1155Factory  {
    using Counters for Counters.Counter;
    Counters.Counter private dpCounter; 
  
    mapping(uint256 => DrawPass) public drawPasses;
    
    event Claimed(uint index, address indexed account, uint amount);

    /// @notice struct representing a draw pass
    struct DrawPass {
        bytes32 merkleRoot;
        uint256 windowOpens;
        uint256 windowCloses;
        string ipfsMetadataHash;
        address redeemContract;
        mapping(address => bool) claimedDPs;
    }

    constructor(
        string memory _name, 
        string memory _symbol
    ) ERC1155("ipfs://") {
        name_ = _name;
        symbol_ = _symbol;
    }

    /// @notice add new draw pass at next index
    /// @param _merkleRoot the merkle root to verifiy wallets eligible to claim
    /// @param _windowOpens UNIX timestamp for claim window opening
    /// @param _windowCloses UNIX timestamp for claim window closing
    /// @param _ipfsMetadataHash the IPFS hash representing draw pass metadata
    /// @param _redeemContract the redeem contract allowed to burn draw passes
    function addDrawPass(
        bytes32 _merkleRoot, 
        uint256 _windowOpens, 
        uint256 _windowCloses, 
        string memory _ipfsMetadataHash,
        address _redeemContract
    ) external onlyOwner {
        require(_windowOpens < _windowCloses, "open window must be prior close");
        require(_windowOpens > 0 && _windowCloses > 0, "window cannot be 0");

        DrawPass storage dp = drawPasses[dpCounter.current()];
        dp.merkleRoot = _merkleRoot;
        dp.windowOpens = _windowOpens;
        dp.windowCloses = _windowCloses;
        dp.ipfsMetadataHash = _ipfsMetadataHash;
        dp.redeemContract = _redeemContract;

        dpCounter.increment();
    }

    /// @notice add new draw pass at next index
    /// @param _merkleRoot the merkle root to verifiy wallets eligible to claim
    /// @param _windowOpens UNIX timestamp for claim window opening
    /// @param _windowCloses UNIX timestamp for claim window closing
    /// @param _ipfsMetadataHash the IPFS hash representing draw pass metadata
    /// @param _redeemContract the redeem contract allowed to burn draw passes
    /// @param _dpIndex the index of the draw pass to edit  
    function editDrawPass(
        bytes32 _merkleRoot, 
        uint256 _windowOpens, 
        uint256 _windowCloses, 
        string memory _ipfsMetadataHash,        
        address _redeemContract, 
        uint256 _dpIndex
    ) external onlyOwner {
        require(_windowOpens < _windowCloses, "window open must be prior close");
        require(_windowOpens > 0 && _windowCloses > 0, "window cannot be 0");

        drawPasses[_dpIndex].merkleRoot = _merkleRoot;
        drawPasses[_dpIndex].windowOpens = _windowOpens;
        drawPasses[_dpIndex].windowCloses = _windowCloses;
        drawPasses[_dpIndex].ipfsMetadataHash = _ipfsMetadataHash;    
        drawPasses[_dpIndex].redeemContract = _redeemContract;  
    }       

    /// @notice burn draw pass from redeem contract
    /// @param _account the wallet to burn draw passes from
    /// @param _dpIndex the index of the draw pass to burn 
    /// @param _amount the amount of draw passes to burn
    function burnFromRedeem(
        address _account, 
        uint256 _dpIndex, 
        uint256 _amount
    ) external {
        require(drawPasses[_dpIndex].redeemContract == msg.sender, "Burnable: Only allowed from redeem contract");

        _burn(_account, _dpIndex, _amount);
    }  

    /// @notice claim draw passes
    /// @param index the index of the wallet in merkle tree
    /// @param maxAmount the max amount sender wallet is eligible to claim
    /// @param dpIndex the index of the draw pass to claim
    /// @param merkleProof the merkle proof for sender wallet
    function claim(
        uint256 index,
        uint256 maxAmount,
        uint256 dpIndex,
        bytes32[] calldata merkleProof
    ) external whenNotPaused {
        require(drawPasses[dpIndex].windowOpens != 0, "Claim: Draw pass does not exist");
        require (block.timestamp > drawPasses[dpIndex].windowOpens && block.timestamp < drawPasses[dpIndex].windowCloses, "Claim: time window closed");
        require(!drawPasses[dpIndex].claimedDPs[msg.sender], "Claim: already claimed");

        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, maxAmount));
        require(
            MerkleProof.verify(merkleProof, drawPasses[dpIndex].merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );
        
        drawPasses[dpIndex].claimedDPs[msg.sender] = true;

        _mint(msg.sender, dpIndex, maxAmount, "");
        emit Claimed(index, msg.sender, maxAmount);
    }

    /// @notice allow contract owner to mint
    /// @param amount the amount of tokens to mint
    /// @param dpIndex the id of the token
    /// @param to the receiver address   
    function ownerMint(uint256 amount, uint256 dpIndex, address to) external onlyOwner {
        require(drawPasses[dpIndex].windowOpens != 0, "Claim: Draw pass does not exist");

        _mint(to, dpIndex, amount, "");
    }

    /// @notice check if a wallet already claimed a specific draw pass
    /// @param _index the index of the draw pass to query
    /// @param _account the wallet address to query for
    /// @return true if wallet already claimed draw passes for given index
    function getClaimedDps(uint256 _index, address _account) public view returns (bool) {
        return drawPasses[_index].claimedDPs[_account];
    }

    /// @notice returns the URI for token with index `_id`
    /// @param _id the index of the draw to return the uri for
    function uri(uint256 _id) public view override returns (string memory) {
            require(totalSupply(_id) > 0, "URI: nonexistent token");
            
            return string(abi.encodePacked(super.uri(_id), drawPasses[_id].ipfsMetadataHash));
    }    
}