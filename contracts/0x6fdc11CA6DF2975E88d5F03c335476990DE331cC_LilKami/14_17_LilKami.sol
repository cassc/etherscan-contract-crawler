// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721MT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract LilKami is DefaultOperatorFilterer,ERC721MT, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    //CONST
    uint256 public constant LK_MAX = 5555;
    uint256 public constant PURCHASE_LIMIT = 10;
    address private constant DEVWALLET = 0xc8B7D79F9BC89Ad8818c04b3913a501813F8F2a2;


    bool public isPublicSaleActive;
    uint256 public offsetIndex;
    string public constant PROVENANCE_HASH = "025da8e68f3e112cf875a231a6e33f1f67539386dd90c1f0511c0a37e2380539";
    string private _baseTokenURI = "https://lilkami.s3.amazonaws.com/META/";
    string private _placeHolderURI = "https://lilkami.s3.amazonaws.com/placeholder"; 
    uint256 private _price = 0.02 ether; 


    constructor() ERC721MT("Lil-Kami","LK") {
            _mint(DEVWALLET, 5);
      }

 
    function getPrice(uint256 quantity) public view returns (uint256) {
        return _price * quantity;
    }
   function mintTokens(uint256 quantity) private {
       _mint(msg.sender, quantity);
    }

    function mint(uint256 numberOfTokens) external payable {
        require(msg.sender == tx.origin, "contracts can't mint");
        require(totalSupply() < LK_MAX, "Sold Out");
        require(totalSupply() + numberOfTokens <= LK_MAX, "exceeds the public amount"); 
        require(msg.value == getPrice(numberOfTokens), "wrong eth value");
        require(isPublicSaleActive, "Public Sale is not active");
        require(numberOfTokens <= PURCHASE_LIMIT,"Would exceed purchase limit");
        mintTokens(numberOfTokens);
    }

    function reserveTokens(uint256 quantity) public onlyOwner {
         require(totalSupply() + quantity <= LK_MAX, "this exceed the public amount");
        mintTokens(quantity);
    }

   function walletOfOwner(address address_)
        public
        view
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _index;

        for (uint256 i = 1; i <= (totalSupply()); i++) {
            if (_exists(i)){
            if (address_ == ownerOf(i)) {
                _tokens[_index] = i;
                _index++;
            }}
        }
        return _tokens;
    }

    //owner functions
    function toggleIsActive() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function reveal() external onlyOwner {
        require(offsetIndex == 0);
         offsetIndex = uint(keccak256(abi.encodePacked(blockhash(block.number-1)))).mod(totalSupply()) +1;
    }

     function withdraw() external onlyOwner { 
        uint256 _DevCut = address(this).balance * 5 / 100;
        uint256 theRest = address(this).balance - _DevCut; 
        require(payable(DEVWALLET).send(_DevCut));
        require(payable(msg.sender).send(theRest));
    }

     function setPrice(uint256 _newPrice) public onlyOwner {
          _price = _newPrice;
    }

    //metaData
    function setBaseURI(string calldata URI) external onlyOwner {
        _baseTokenURI = URI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

   function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721MT)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        if (offsetIndex == 0){
            return  _placeHolderURI;
        }
        else{
             uint256 offsetId = tokenId.add(LK_MAX.sub(offsetIndex)).mod(LK_MAX) +1;
             return string(abi.encodePacked(_baseURI(), offsetId.toString()));
        }
    }

//bs OS settings
function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}