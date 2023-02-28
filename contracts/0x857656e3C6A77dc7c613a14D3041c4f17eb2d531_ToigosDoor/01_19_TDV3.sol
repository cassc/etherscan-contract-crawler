// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ ////////
//▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌///////
// ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌ ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌//////
///////▐░▌     ▐░▌       ▐░▌     ▐░▌     ▐░▌          ▐░▌       ▐░▌▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌/////
///////▐░▌     ▐░▌       ▐░▌     ▐░▌     ▐░▌ ▄▄▄▄▄▄▄▄ ▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌////
///////▐░▌     ▐░▌       ▐░▌     ▐░▌     ▐░▌▐░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌///
///////▐░▌     ▐░▌       ▐░▌     ▐░▌     ▐░▌ ▀▀▀▀▀▀█░▌▐░▌       ▐░▌ ▀▀▀▀▀▀▀▀▀█░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░█▀▀▀▀█░█▀▀/// 
///////▐░▌     ▐░▌       ▐░▌     ▐░▌     ▐░▌       ▐░▌▐░▌       ▐░▌          ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌     ▐░▌///  
///////▐░▌     ▐░█▄▄▄▄▄▄▄█░▌ ▄▄▄▄█░█▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌ ▄▄▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░▌     //▐░▌
///////▐░▌     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌    /////▐░▌     

//Developed by Co-Labs. Hire us at https://co-labs.studio 

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "https://github.com/nickyoung92/Solidity-Contracts/blob/main/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol";

contract ToigosDoor is ERC1155, Ownable, ReentrancyGuard, PaymentSplitter, DefaultOperatorFilterer {
    using Strings for uint;
    string public name = "Toigos Door";
    string public symbol = "TD";
    string internal _baseTokenURI = "https://minttoigosdoor.com/img/assets/metadata/";
    uint256 constant private NUM_OPTIONS = 6;
    uint256 constant private MAX_SUPPLY = 1000;
    uint256 constant public maxSupply = 5003;
    uint256 public mintFeePublic = 0.03 ether;
    uint256 public mintFeePresale = 0.02 ether;
    uint256 public presaleMints = 1200;
    uint256 public maxMintPerAddress = 10;
    uint256 public totalSupply;
    bool public presaleOnly = true;
    bool public paused = true;
    uint256[NUM_OPTIONS] private tokenSupply;
    uint256[NUM_OPTIONS] private maxSupplies = [MAX_SUPPLY, MAX_SUPPLY, MAX_SUPPLY, MAX_SUPPLY, MAX_SUPPLY, 3];
    uint256[NUM_OPTIONS] private weights = [uint256(MAX_SUPPLY), uint256(MAX_SUPPLY), uint256(MAX_SUPPLY), uint256(MAX_SUPPLY), uint256(MAX_SUPPLY), uint256(3)];
    mapping(address => uint256) public mintedTokens;
    mapping(address => bool) public nftPayMinters;
    
    event TokenMinted(address indexed account, uint256 indexed id, uint256 amount);

    constructor(uint256[] memory _tokenIds, uint256[] memory _amounts) ERC1155(_baseTokenURI) {
        _mintBatch(msg.sender, _tokenIds, _amounts, ""); //for team
        for(uint i = 0; i<_amounts.length; i++) {
            totalSupply += _amounts[i];
        }
        nftPayMinters[0x895199cb097E184D8F38e2A21F14b33dbe1bC9d7] = true;
        nftPayMinters[0xDDEC0a2a1bec87B227268B86ffe6094e24465CE0] = true;
        nftPayMinters[0x77b4973034A6B054CE5965AE7f2e924532ab7562] = true;
        nftPayMinters[0xF1381c0407Bc7cFA8167675862ce980515758fc4] = true;
        nftPayMinters[0x74bD4D0c420397984c4Fb38aACCC0Ac6E11f7fc0] = true;
    }
        

    //HELPERS


    //calculate weighted odds of minting token ID
    function getWeight(uint256 tokenId) internal view returns (uint256) {
        if (tokenId < NUM_OPTIONS) {
            uint256 remaining = maxSupplies[tokenId - 1] - tokenSupply[tokenId - 1];
            uint256 weight = weights[tokenId - 1] * remaining / maxSupplies[tokenId - 1];
            return weight;
        } else {
            return weights[tokenId - 1];
        }
    }

    function getPrice() internal view returns (uint256) {
        uint256 currentPrice;
        if(totalSupply > presaleMints) {
            currentPrice = mintFeePublic;
        } else {
            currentPrice = mintFeePresale;
        }
        return currentPrice;
    }

    function price() external view returns(uint256) {
        return getPrice();
    }

    //applies to all mint functions
    modifier mintCompliance(uint256 amount) {
        require(paused == false, "Contract is paused.");
        require(amount > 0, "Amount must be greater than zero");
        if(!nftPayMinters[msg.sender]) {
            require(amount + mintedTokens[msg.sender] <= maxMintPerAddress, "You cant mint that many.");
        } else {
            require(amount <= maxMintPerAddress, "You cant mint that many.");
        }
        require(totalSupply + amount < maxSupply+1, "Not enough tokens left to mint that many.");
        require(tx.origin == msg.sender, "No contracts!");
        _;
    }



    //MINT FUNCTIONS

    //public
    function mint(uint256 amount) public payable mintCompliance(amount) nonReentrant {
        require(msg.value == getPrice() * amount, "Incorrect mint fee");
        
        uint256 blockNumber = block.number;
        uint256 blockHash = uint256(blockhash(blockNumber));

        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);

        for (uint256 j = 0; j < amount; j++) {
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockHash, msg.sender, j))) % (10 ** 18);
            uint256 tokenId;
            uint256 totalWeight = 0;
            for (uint256 i = 0; i < NUM_OPTIONS; i++) {
                if (tokenSupply[i] < maxSupplies[i]) {
                    totalWeight += getWeight(i + 1);
                }
            }

            require(totalWeight > 0, "All tokens have been minted");

            for (uint256 i = 0; i < NUM_OPTIONS; i++) {
                if (tokenSupply[i] < maxSupplies[i]) {
                    uint256 weight = getWeight(i + 1);
                    if (randomNumber < (weight * (10 ** 18)) / totalWeight) {
                        tokenId = i + 1;
                        break;
                    }
                    randomNumber -= (weight * (10 ** 18)) / totalWeight;
                }
            }

            require(tokenId > 0 && tokenId <= NUM_OPTIONS, "Invalid token ID");

            tokenSupply[tokenId - 1] += 1;
            ids[j] = tokenId;
            amounts[j] = 1;
            
            emit TokenMinted(msg.sender, tokenId, 1);

        }
        totalSupply += amount;
        mintedTokens[msg.sender] += amount;
        _mintBatch(msg.sender, ids, amounts, "");
    }


    //OWNER FUNCTIONS

    function pause(bool _state) external onlyOwner 
    {
        paused = _state;
    }

    function setBaseURI(string memory baseURI) external onlyOwner 
    {
        _baseTokenURI = baseURI;
    }

    function updatePublicPrice(uint256 _publicPrice) external onlyOwner 
    {
        mintFeePublic = _publicPrice;
    }

    function updatePresalePrice(uint256 _presalePrice) external onlyOwner 
    {
        mintFeePresale = _presalePrice;
    }

    function updateMaxPerWallet(uint256 _newMax) external onlyOwner
    {
        maxMintPerAddress = _newMax;
    }

    function addNFTPayMinter(address[] memory _addresses) external onlyOwner 
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
           nftPayMinters[_addresses[i]] = true;
        }
        
    }

    //URI FUNCTIONS

   

    function uri(uint tokenId) public view virtual override returns (string memory) 
    {
        return bytes(_baseTokenURI).length > 0
        ? string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"))
        : "";
        
    }

    //OPERATOR FILTER REGISTRY

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom( address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

}