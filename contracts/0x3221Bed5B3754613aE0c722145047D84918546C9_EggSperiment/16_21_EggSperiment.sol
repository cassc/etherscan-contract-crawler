//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.13;
 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; 
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "hardhat/console.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract EggSperiment is ERC721Enumerable, ERC2981, DefaultOperatorFilterer, Ownable {
    using Strings for uint256;

    address public genesisBirdez;  // 0x5e9ee3B23C533FDA7bCfBECABD1E0e5e91098210
    address public babyBirdez; // 0x2A8A33Af953B989F2E1bB900beEa420312Bb8026
    uint256[] public legendaryTokens; // [1310,355,558,649,692,1188]

    // name = EggSperiment
    // symbol = EGGSPERIMENT
    constructor(string memory _name, string memory _symbol, address _genesisBirdez, address _babyBirdez, uint256[] memory _legendaryTokens)
        ERC721(_name, _symbol)
    {
        babyBirdez = _babyBirdez;
        genesisBirdez = _genesisBirdez;
        legendaryTokens = _legendaryTokens;
    }

    uint256[] public genesisUsed;
    uint256[] public babyUsed;
    uint256[] public legendaryUsed;
 
    uint256 public constant MAX_M1 = 2500;
    uint256 public constant MAX_M2 = 661;
    uint256 public constant MAX_M3 = 10;

    uint256 public constant START_M1 = 0;
    uint256 public constant START_M2 = MAX_M1;
    uint256 public constant START_M3 = MAX_M1 + MAX_M2; 
  
    uint256 public mintedM1 = 0;
    uint256 public mintedM2 = 0;
    uint256 public mintedM3 = 0;

  

    bool public publicSale = false; 

    string private baseURI; 

    function setBaseURI(string memory newURI) public onlyOwner { 
        baseURI = newURI;
    } 

    function flipSaleState() public onlyOwner { 
        publicSale = !publicSale;
    } 

    function setLegendaty(uint256[] memory _legendaryTokens) public onlyOwner {
        legendaryTokens = _legendaryTokens;
    }
 
    
    function _checkLegendary(uint256 num) public view returns (bool ){ 
        uint arrayLength = legendaryTokens.length;
        bool found=false;
        for (uint i = 0; i < arrayLength; i++) {
            if(legendaryTokens[i]==num){
                found=true;
                break;
            }
        }
        return found;
    }

    function checkIfGenesisIsUsed(uint256 _token) public view returns(bool){ 
        bool found=false;
        for (uint i = 0; i < genesisUsed.length; i++) {
            if(genesisUsed[i]==_token){
                found=true;
                break;
            }
        }
        return found;
    }

    function checkIfBabyIsUsed(uint256 _token) public view returns(bool){ 
        bool found=false;
        for (uint i = 0; i < babyUsed.length; i++) {
            if(babyUsed[i]==_token){
                found=true;
                break;
            }
        }
        return found;
    }

    function checkIfLegendaryIsUsed(uint256 _token) public view returns(bool){ 
        bool found=false;
        for (uint i = 0; i < legendaryUsed.length; i++) {
            if(legendaryUsed[i]==_token){
                found=true;
                break;
            }
        }
        return found;
    }

    function getOwnerOfGenesis(uint256 _token) public view returns (address){
        return IERC721Enumerable(genesisBirdez).ownerOf(_token);
    }

    function getOwnerOfBaby(uint256 _token) public view returns (address){
        return IERC721Enumerable(babyBirdez).ownerOf(_token);
    }


    function getOwner( bool _genesis, uint256 _token) private view returns (address){
        address _contract;
        if( _genesis ){  _contract = genesisBirdez; }
        else{  _contract = babyBirdez; }
        return IERC721Enumerable(_contract).ownerOf(_token);
    }

    function mintM1(uint256 _token1, uint256 _token2) public {
        address _sender = msg.sender; 

        require(publicSale, "sale-not-active");
        require(!isContract(msg.sender), "mint-via-contract");   

        require(_token1 != _token2, "wrong-tokens"); 
 
        require(getOwner(false, _token1) == _sender && getOwner(false, _token2) == _sender, "wrong-tokens");   
 
        require(!checkIfBabyIsUsed(_token1) && !checkIfBabyIsUsed(_token2), "already-used-token");   
        
        if (mintedM1 < MAX_M1) {
            _safeMint(_sender, START_M1 + mintedM1);  
            mintedM1++; 
            babyUsed.push(_token1);
            babyUsed.push(_token2); 
        } 
 
    } 

    function mintM2(uint256 _token1, uint256 _token2) public {
        address _sender = msg.sender; 

        require(publicSale, "sale-not-active");
        require(!isContract(msg.sender), "mint-via-contract"); 
        require(_token1 != _token2, "wrong-tokens");   
         
        require(getOwner(true, _token1) == _sender && getOwner(true, _token2) == _sender, "wrong-tokens");   

        require(!checkIfGenesisIsUsed(_token1) && !checkIfGenesisIsUsed(_token2), "already-used-token");   

        if (mintedM2 < MAX_M2) {
            _safeMint(_sender, START_M2 + mintedM2); 
            mintedM2++;
            genesisUsed.push(_token1);
            genesisUsed.push(_token2); 
        } 
    }

    function mintM3(uint256 _token) public {
        address _sender = msg.sender; 

        require(publicSale, "sale-not-active");
        require(!isContract(msg.sender), "mint-via-contract");   
         
        require(getOwner(true, _token) == _sender && _checkLegendary(_token), "wrong-tokens");  
        require(!checkIfLegendaryIsUsed(_token), "already-used-token");   

        if (mintedM3 < MAX_M3) {
            _safeMint(_sender, START_M3 + mintedM3); 
            mintedM3++;
            legendaryUsed.push(_token);  
        } 
    }


    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "non-existent-token");
        string memory _base = _baseURI();
        return string(abi.encodePacked(_base, tokenId.toString()));
    }

    function burn(uint256 tokenId) public  {
        address owner = ERC721.ownerOf(tokenId);
        require( owner == msg.sender, "cannot-burn");
        super._burn(tokenId);
    }




     /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(IERC721, ERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}