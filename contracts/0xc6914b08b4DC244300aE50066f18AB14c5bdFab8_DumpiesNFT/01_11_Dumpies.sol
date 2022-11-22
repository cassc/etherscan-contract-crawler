pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./DefaultOperatorFilterer.sol";

contract DumpiesNFT is  DefaultOperatorFilterer, ERC721A, Ownable {

    using ECDSA for bytes32;

    mapping(address => bool) hasClaimed;
    mapping(address => uint256) numMinted;

    uint256 public MAX_MINT = 2;
    uint256 public COST = 29000000000000000;
    uint256 public COLLECTION_SIZE = 6000;
    uint256 public ADMIN_MINTS = 800;

    bool public openForPublic;

    address private signer;
    address payable private DUMPIESWALLET;

    uint256 public adminMints;

    string internal baseURI;

    struct URI {
        string path;//the path
        uint256 upto;//represents tokens from the top of the last URI upto this value
    }

    URI[] private URIs;


    constructor() ERC721A("DumpiesNFT", "DUMPIESNFT"){
        baseURI = ""; //Placeholder Token
        signer = 0x12372095C552F88056FCf63AC4E5c8776418Cf6b; 
        DUMPIESWALLET = payable(0xf8a5964f25D0b1a21e14EFFB70620796D742758E);
    }

    function mint(uint256 quantity, uint8 mintType, bytes memory signature) external payable {
        require(mintType == 0);
        require(quantity > 0, "Zero mint dissallowed");
        require(quantity + numMinted[msg.sender] <= MAX_MINT, "Exceeds max mint per transaction");
        require(_totalMinted() + quantity <= COLLECTION_SIZE - 800, "Mint would exceed collection size");

        if(!openForPublic){
            require(verify(msg.sender, mintType, signature), "ACCESS DENIED");
            require(!hasClaimed[msg.sender], "ALREADY CLAIMED");
            require(quantity == 1);

            hasClaimed[msg.sender] = true;
        }else{
            require(quantity <= 2);
            require(msg.value >= COST * quantity, "insufficient funds");
        }

        _mint(msg.sender, quantity);
        numMinted[msg.sender] += quantity; 
 
    }

    function verify(address user, uint8 mintType, bytes memory signature) private view returns (bool){
        return keccak256(abi.encode(user, mintType)).toEthSignedMessageHash().recover(signature) == signer;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        bool locatedURI;
        uint256 index;
        for(uint256 i = 0; i < URIs.length; i++){
            if(tokenId <= URIs[i].upto){
                locatedURI = true;
                index = i;
                break;
            }
        }

        return locatedURI ? string(abi.encodePacked(URIs[index].path, _toString(tokenId + 1), ".json")) : baseURI;
    }

    function revealBatch(string memory newURI, uint256 upto) public onlyOwner{
        if(URIs.length > 0) require(URIs[URIs.length - 1].upto < upto, "Batch must not include existing batches");
        require(upto <= _totalMinted(), "Batch includes unminted tokens");

        URI memory uri = URI(newURI, upto);
        URIs.push(uri);
    }


    function adminMint(uint256 quantity, address target) public onlyOwner{
        require(_totalMinted() + quantity <= COLLECTION_SIZE, "Would exceed collection size");

        adminMints += quantity;
        _mint(target, quantity);
    }

    function withdraw() public onlyOwner{
        DUMPIESWALLET.transfer(address(this).balance);
    }

    function setOpenForPublic() public onlyOwner{
        openForPublic = !openForPublic;
    }

    function setSigner(address newSigner) public onlyOwner{
        signer = newSigner;
    }

    function setPlaceholder(string memory newURI) public onlyOwner{
        baseURI = newURI;
    }

    function setPrice(uint256 newPrice) public onlyOwner{
        COST = newPrice;
    }

    //OVERRIDES FOR OPENSEA'S OPERATOR FILTERER
    function setApprovalForAll(address operator, bool approved) public virtual override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public virtual override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        virtual
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}