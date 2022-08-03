// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Counters.sol";

contract TGUtilities is ERC1155Supply, ERC1155Burnable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private counter; 
    
    mapping(uint256 => Utility) public utilities;

    struct Utility {
        string ipfsMetadataHash;  
        string name;
        string description;
        uint256 price;
        uint256 maxSupply;
    }
    string public mycontractURI;
    bool public isSalePaused = false;

    string public name_;
    string public symbol_;  

    //royalty
    uint256 public royaltyBasis = 1000;

    address private vaultAddress = 0x924017Eb78A0B2229F1F3b34E1383573F994E4Be;

    constructor() ERC1155("ipfs://") {     
        name_ = "Taco Gatos Utilities";
        symbol_ = "TGU";   
        mycontractURI = "https://api.tacogatosnft.com/contract_tgutilities";
    }

    /**
    * @notice adds a new Utility
    * 
    * @param _ipfsMetadataHash the ipfs hash for Utility metadata
    * @param _name is the name of the Utility
    * @param _description is the description for the Utility
    */
    function addUtility(         
        string memory _ipfsMetadataHash,
        string memory _name,
        string memory _description,
        uint256 _price,
        uint256 _maxSupply
    ) external onlyOwner {
        Utility storage c = utilities[counter.current()];
        c.ipfsMetadataHash = _ipfsMetadataHash;
        c.name = _name;                                       
        c.description = _description;
        c.price = _price;
        c.maxSupply = _maxSupply;
        counter.increment();
    }    

    /*
    * @notice edit an existing Utility
    * 
    * @param _ipfsMetadataHash the ipfs hash for Utility metadata
    * @param _name is the name of the Utility
    * @param _description is the description for the Utility
    * @param _price the price of the utility in wei
    * @param _maxSupply the total max supply of the utility token
    * @param _utilityIndex the index of the utility to modify
    */
    function editUtility(      
        string memory _ipfsMetadataHash,
        string memory _name,
        string memory _description,
        uint256 _price,
        uint256 _maxSupply,
        uint256 _utilityIndex
    ) external onlyOwner {
        require(exists(_utilityIndex), "EditUtility: utility does not exist");

        utilities[_utilityIndex].ipfsMetadataHash = _ipfsMetadataHash;  
        utilities[_utilityIndex].name = _name;                               
        utilities[_utilityIndex].description = _description;                  
        utilities[_utilityIndex].price = _price;                  
        utilities[_utilityIndex].maxSupply = _maxSupply;  
    }

    function mint(uint256 id, uint256 amount) external payable {
        require(!isSalePaused, "SALE IS PAUSED");        
        require(exists(id), "Mint: Utility token does not exist!");
        require(totalSupply(id) + amount  <= utilities[id].maxSupply, "MAX SUPPLY FOR TOKEN REACHED!");
        require(msg.value >= amount * utilities[id].price, "INVALID PAYMENT!"); 

        _mint(msg.sender, id, amount, "");
    }

    //ERC-2981
    function royaltyInfo(uint256, uint256 _salePrice) external view 
        returns (address receiver, uint256 royaltyAmount){          
            return (vaultAddress, _salePrice.mul(royaltyBasis).div(10000));
    }

    // OWNER FUNCTIONS
    function sendUtility(uint256 id, uint256 amount, address to) external onlyOwner {
        require(totalSupply(id) + amount  <= utilities[id].maxSupply, "MAX SUPPLY FOR TOKEN REACHED!");
        require(exists(id), "Mint: Utility token does not exist!");
        _mint(to, id, amount, "");
    }

    function setRoyalty(uint256 _royaltyBasis) external onlyOwner {
        royaltyBasis = _royaltyBasis;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0);

        // Owner
        payable(vaultAddress).transfer(address(this).balance);
    }
    
    function setVaultAddress(address _vaultAddress) external onlyOwner {
        vaultAddress = _vaultAddress;
    }  
    
    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(mycontractURI));
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        mycontractURI = _contractURI; //Contract Metadata format based on:  https://docs.opensea.io/docs/contract-level-metadata    
    }

    function uri(uint256 id) public view override returns (string memory) {            
        return string(abi.encodePacked(super.uri(id), utilities[id].ipfsMetadataHash));
    }      
    
    function name() external view returns (string memory) {
        return name_;
    }

    function symbol() external view returns (string memory) {
        return symbol_;
    }          

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }  

    /**
    * @notice indicates weither any token exist with a given id, or not
    */
    function exists(uint256 id) public view override returns (bool) {
        return utilities[id].maxSupply > 0;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }      
}