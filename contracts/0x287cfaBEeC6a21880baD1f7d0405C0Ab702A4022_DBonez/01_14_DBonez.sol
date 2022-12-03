// SPDX-License-Identifier: MIT

// ######         #######     ########    ##      #     #########   ##########
// #    ##        ##   ###    #      #    # #     #     #                   #
// #      #       ##  ###     #      #    #  #    #     #                  #
// #      #       #####       #      #    #   #   #     #####             #
// #      #       ##  ###     #      #    #    #  #     #               #
// #    ##        ##   ###    #      #    #     # #     #             # 
// ######     #   #######     ########    #      ##     #########   ##########

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract DBonez is ERC721A, ERC2981, Ownable,DefaultOperatorFilterer {
    bytes32 public merkleRootWL=0xac3264a12bc18716a8dbcae5138677c51d746c6f28225f68d99a89814514fc9b;
    string public baseURI="";
    string public tokenSuffix="";
    string public unrevealedURI="ipfs://bafkreiel3xygs3qhwo6iclhya3hwmm3gswq6gvz6vlj4l67qlqabvx7eoe";
    bool public isRevealed = false;
    uint256 public MAX_MINT_PUBLIC = 1;
    uint256 public MAX_MINT_WHITELIST = 1;
    uint256 public constant maxTokens = 999;
    uint256 public mintPhase=0;
    address public payoutAddress=0x882D0C349841EE6Bf714d9F8523fa0214285bf63;
    mapping(address => uint256) public whitelistMintedCount;  
    mapping(address => uint256) public publicMintedCount;  

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

    //add events
    event PaymentReleased(address to, uint256 amount);
    event TokenMinted(uint256 tokenId, address owner);


    //constructor
    constructor() ERC721A("DBonez", "DBonez") {
       setRoyalties(payoutAddress,750);
    }

    /* MINTING */
    function mintFromWhiteList(uint256 numberOfTokens,bytes32[] calldata _merkleProof) external payable{
        require(mintPhase==1,"Whitelist Minting is not available");
        require(totalMinted()+numberOfTokens <= maxTokens, "Not enough tokens available to mint");
        require(whitelistMintedCount[msg.sender]+numberOfTokens <=MAX_MINT_WHITELIST,"Exceeded WL Allocation");
        bytes32 leaf=keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verifyCalldata(_merkleProof,merkleRootWL,leaf), "Invalid Proof for Whitelist");
        _basicMint(msg.sender, numberOfTokens);
        whitelistMintedCount[msg.sender] +=numberOfTokens;
    }

    function publicMint(uint256 numberOfTokens) external payable{
        require(mintPhase==2,"Public Mint is not available");
        require(totalMinted()+numberOfTokens <= maxTokens, "Not enough tokens available to mint");
        require(publicMintedCount[msg.sender]+numberOfTokens <=MAX_MINT_PUBLIC,"Exceeded Public Allocation");
        _basicMint(msg.sender, numberOfTokens);
        publicMintedCount[msg.sender]+= numberOfTokens;
    }

    function adminMintBulk(address to,uint256 numberOfTokens) public onlyOwner {
        require(totalMinted()+numberOfTokens <= maxTokens, "Not enough tokens available to mint");      
        _basicMint(to, numberOfTokens);
    }

    function _basicMint(address to, uint256 q) private {
        _safeMint(to, q);
        emit TokenMinted(totalSupply()-1, to);
    }

    //Minting Verifications EXTERNAL Only
    function getWLMintedCountForAddress(address w) external view returns (uint256){
        return whitelistMintedCount[w];
    }

    function getPublicMintedCountForAddress(address w) external view returns (uint256){
        return publicMintedCount[w];
    }

    function verifyWLWallet(address a, bytes32[] calldata _merkleProof) external view returns (bool){
        bytes32 leaf=keccak256(abi.encodePacked(a));
        return MerkleProof.verifyCalldata(_merkleProof,merkleRootWL,leaf);
    }

    function totalMinted() public view returns(uint) {
        return _totalMinted();
    }

    //OWNER Setters
    function setMerkleRoot(bytes32 merk) external onlyOwner {
        merkleRootWL=merk;
    }

    function setMAXPublic(uint256 p) external onlyOwner{
        MAX_MINT_PUBLIC=p;
    }

    function setIsRevealed(bool b) external onlyOwner{
        isRevealed=b;
    }

    function setMAXWL(uint256 p) external onlyOwner{
        MAX_MINT_WHITELIST=p;
    }

    function setMintPhase(uint256 p) external onlyOwner{
        mintPhase=p;
    }

     
    //balance withdrawal functions
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        uint256 payment = amount;
        Address.sendValue(payable(payoutAddress), payment);
        emit PaymentReleased(payoutAddress, payment);
    }

    function setPayoutAddress(address s) external onlyOwner {
        payoutAddress=s;
    }

    function payAddress(address to, uint256 amount) external onlyOwner{
        require(amount <= 1 ether, "Over max payment");
        require(address(this).balance >= amount, "Insufficient balance");
        Address.sendValue(payable(to), amount);
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
                return unrevealedURI;
            }

            return string.concat(baseURI, _toString(tokenId),tokenSuffix);
        }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setTokenSuffix(string memory suffix) external onlyOwner {
        tokenSuffix = suffix;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }
    
    function _unrevealedURI() internal view virtual returns (string memory) {
        return unrevealedURI;
    }

    function contractURI() public pure returns (string memory) {
        return "http://dbonez.com/contractdbonez.json";
    }
   
    function setRoyalties(address receiver, uint96 royaltyFraction) public onlyOwner {
        _setDefaultRoyalty(receiver, royaltyFraction);
    }

    function version() public pure returns (string memory){
        return ".1";
    }
    
    //returns list of tokens for an owner
    function getTokensOfOwner(address owner) external view virtual returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    //Only token owner or approved can burn
    function burn(uint256 tokenId) public virtual {
        _burn(tokenId, true);
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