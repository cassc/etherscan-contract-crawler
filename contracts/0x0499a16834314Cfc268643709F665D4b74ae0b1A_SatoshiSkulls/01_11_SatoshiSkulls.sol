pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./DefaultOperatorFilterer.sol";

contract SatoshiSkulls is DefaultOperatorFilterer, ERC721A, Ownable {

    using ECDSA for bytes32;
    mapping(address => uint256) numMinted;

    struct URI {
        string path;//the path
        uint256 upto;//represents tokens from the top of the last URI upto this value
    }

    uint256 public MAX_MINT = 3;
    uint256 public COST = 15000000000000000;
    uint256 public COLLECTION_SIZE = 4000;

    bool public openForPublic;

    address private signer;
    address payable private SatoshiWallet;

    uint256 public adminMints;

    string internal baseURI;

    URI[] private URIs;


    constructor() ERC721A("SatoshiSkulls", "SATOSHISKULLS"){
        baseURI = ""; //Placeholder Token
        signer = 0xfED26952578500F031fb27F71365f888199C8B0C; 
        SatoshiWallet = payable(0x90dDCB3b7688D97B8859d9b53901451923063746);
    }

    function mint(uint256 quantity, uint8 mintType, bytes memory signature) external payable {
        require(mintType == 0);
        require(quantity > 0, "Zero mint dissallowed");
        //require(quantity + numMinted[msg.sender] <= MAX_MINT, "Exceeds max mint per transaction");
        require(_totalMinted() + quantity <= COLLECTION_SIZE, "Mint would exceed collection size");

        if(!openForPublic){
            require(verify(msg.sender, mintType, signature), "ACCESS DENIED");
            require(quantity + totalSupply() <= 2000, "Exceeds total whitelist allocation");
            require(quantity + numMinted[msg.sender] <= 3, "Exceeds max whitelist mint");
        }else{
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

    function undo() public onlyOwner{
        URIs.pop();
    }


    function adminMint(uint256 quantity, address target) public onlyOwner{
        require(_totalMinted() + quantity <= COLLECTION_SIZE, "Would exceed collection size");

        adminMints += quantity;
        _mint(target, quantity);
    }

    function withdraw() public onlyOwner{
        SatoshiWallet.transfer(address(this).balance);
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