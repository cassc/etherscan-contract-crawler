// SPDX-License-Identifier: MIT

//  ########     ######         madness23
//  ##           #    ##        madness23
//  ##           #      #       madness23
//    ####       #      #       madness23
//        ##     #      #       madness23
//        ##     #    ##        madness23
//  #######      #####          madness23

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error SaleNotActive();
error InsufficientPayment();
error WrongBonezAmt();
error NotOwner();

interface IParentContract{
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address owner);
}

contract SDMadness is ERC721A, ERC2981, Ownable,DefaultOperatorFilterer,ReentrancyGuard {
    uint32 public bonezburnAmt=2;
    address public dbonezaddress;
    bool public isRevealed;
    bool public mintPhaseActive;
    uint256 public mintPrice=0.015 ether;
    string public baseURI="ipfs://bafkreicylouwcw32y6wwhrxvqag4674hzaxbyyzqtbsjm5u7eqdimfqexe";
    mapping(address => uint256) public canClaimAmount;  

    /**
     * @inheritdoc ERC721A
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId)
            || ERC2981.supportsInterface(interfaceId);
    }

    //constructor
    constructor(address payout,address daddr,address[] memory addresses,uint256[] memory amounts) ERC721A("SDMadness", "SDMadness") {
       setRoyalties(payout,750);
       setClaimAmounts(addresses, amounts);
       setDBonezAddress(daddr);
    }

    /* MINTING */
    function doBonezMint(uint256[] calldata tokens) external nonReentrant{
        if(!mintPhaseActive) revert SaleNotActive();
        if(tokens.length < bonezburnAmt) revert WrongBonezAmt();
        if(tokens.length % bonezburnAmt != 0) revert WrongBonezAmt();
        uint256 tobeminted=tokens.length / bonezburnAmt;
        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenOwner = IParentContract(dbonezaddress).ownerOf(tokens[i]);
            if(msg.sender != tokenOwner) revert NotOwner();
            IParentContract(dbonezaddress).burn(tokens[i]);
        }
        _mint(msg.sender,tobeminted);
    }

    function doMint(uint256 qty) external payable nonReentrant{
        if(!mintPhaseActive) revert SaleNotActive();
        uint256 claim=canClaimAmount[msg.sender];
        if(claim>0)
        {
            uint256 tempAmt = qty - claim;
            if(msg.value != (tempAmt * mintPrice)) revert InsufficientPayment();
            canClaimAmount[msg.sender]=0;
        }else{
            if(msg.value != (qty * mintPrice)) revert InsufficientPayment();
        }
        _mint(msg.sender, qty);     
    }

    function adminMintBulk(address[] calldata addresses,uint256[] calldata amounts) public onlyOwner {
         for(uint i =0;i<addresses.length;i++){
            _mint(addresses[i],amounts[i]);
         }
    }

    //GETS
    function getCanClaimAmountForAddr(address w) external view returns (uint256){
        return canClaimAmount[w];
    }

    function totalMinted() public view returns(uint) {
        return _totalMinted();
    }

    //OWNER Setters
    function setClaimAmounts(address[] memory addresses,uint256[] memory amounts) public onlyOwner{
         for(uint i =0;i<addresses.length;i++){
            canClaimAmount[addresses[i]]=amounts[i];
         }
    }

    function setIsRevealed(bool b) external onlyOwner{
        isRevealed=b;
    }

    function setMintPrice(uint256 b) external onlyOwner{
        mintPrice=b;
    }
    function setBonezAmt(uint32 b) external onlyOwner{
        bonezburnAmt=b;
    }

    function setDBonezAddress(address b) public onlyOwner{
        dbonezaddress=b;
    }

    function toggleMintPhase() external onlyOwner{
        if(mintPhaseActive)
            mintPhaseActive=false;
        else
            mintPhaseActive=true;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setRoyalties(address receiver, uint96 royaltyFraction) public onlyOwner {
        _setDefaultRoyalty(receiver, royaltyFraction);
    }

    
     
    //balance withdrawal functions
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "NoBal");
        uint256 payment = amount;
        Address.sendValue(payable(msg.sender), payment);
    }

    function getBal() public view returns(uint) {
        return address(this).balance;
    }

    //URI
    function tokenURI (uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
        {
            require(_exists(tokenId), "URIQueryForNonexistentToken");

            if (!isRevealed) {
                return baseURI;
            }

            return string.concat(baseURI, _toString(tokenId),".json");
        }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function contractURI() public pure returns (string memory) {
        return "http://spacedogworld.com/contractsdmadness.json";
    }
   
    function version() public pure returns (string memory){
        return ".1";
    }
    
    //OS Overrides
    //OS FILTERER
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
             override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
           override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
          override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}