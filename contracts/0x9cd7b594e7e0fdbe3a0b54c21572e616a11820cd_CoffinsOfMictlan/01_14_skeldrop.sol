// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

/*
* @title ERC1155 token for Cranky Critter Passes
*/

contract CoffinsOfMictlan is ERC1155, Ownable  {
    using Counters for Counters.Counter;
    Counters.Counter private counter; 
    mapping(uint256 => Pass) public passes;

    struct Pass {
        uint256 totalSupply;
        string ipfsMetadataHash;
        address burnContract;
    }

    constructor() ERC1155("ipfs://") {
    }

    /**
    * @notice adds a new pass
    * 
    * @param _ipfsMetadataHash the ipfs hash for metadata
    * @param _burnContract  the contract that will burn the pass
    */
    function addpass(         
        string memory _ipfsMetadataHash,
        address _burnContract
    ) public onlyOwner {
        Pass storage p = passes[counter.current()];                                      
        p.ipfsMetadataHash = _ipfsMetadataHash;
        p.burnContract = _burnContract;
        counter.increment();
    }    

    /**
    * @notice edit an existing pass
    * @param _ipfsMetadataHash the ipfs hash for pass metadata
    * @param _passIndex the pass id to change
    */
    function editPassMeta(
        string memory _ipfsMetadataHash,
        uint256 _passIndex
    ) external onlyOwner {
        require(exists(_passIndex), "Editpass: pass does not exist");                  
        passes[_passIndex].ipfsMetadataHash = _ipfsMetadataHash;  
    }    

        /**
    * @notice edit an existing pass
    * @param _burnContract  the contract that will burn the pass
    * @param _passIndex the pass id to change
    */
    function editPassBurner(
        address _burnContract,
        uint256 _passIndex
    ) external onlyOwner {
        require(exists(_passIndex), "Editpass: pass does not exist");     
        passes[_passIndex].burnContract = _burnContract; 
    }  

    /**
    * @notice owner mint pass tokens for airdrops
    * @param passID the pass id to mint
    * @param amount the amount of tokens to mint
    */
    function mint(uint256 passID, uint256 amount, address to) external onlyOwner {
        require(exists(passID), "pass does not exist");
        _mint(to, passID, amount, "");
        passes[passID].totalSupply += amount;
    }

    function burnToClaim(
        address account, 
        uint256 index, 
        uint256 amount
    ) external {
        require(passes[index].burnContract == msg.sender, "Only allow from specified contract");
        _burn(account, index, amount);
    }  

    /**
    * @notice return total supply for all existing passes
    */
    function totalSupplyAll() external view returns (uint[] memory) {
        uint[] memory result = new uint[](counter.current());

        for(uint256 i; i < counter.current(); i++) {
            result[i] = passes[i].totalSupply;
        }
        return result;
    }

    /**
    * @notice indicates weither any token exist with a given id, or not
    */
    function exists(uint256 id) public view returns (bool) {
        return keccak256(bytes(passes[id].ipfsMetadataHash)) != keccak256(bytes(""));
    }    

    /**
    * @notice returns the metadata uri for a given id
    * 
    * @param _id the pass id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
            require(exists(_id), "URI: nonexistent token");
            return string(abi.encodePacked(super.uri(_id), passes[_id].ipfsMetadataHash));
    }
}