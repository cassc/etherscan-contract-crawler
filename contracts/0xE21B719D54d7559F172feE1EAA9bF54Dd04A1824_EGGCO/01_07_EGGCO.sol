pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EGGCO is ERC721A, Ownable{

    using ECDSA for bytes32;

    uint256 public MAX_MINT = 5;
    uint256 public MAX_ADMIN_MINT = 223;
    uint256 public COST = 69000000000000000;
    uint256 public COLLECTION_SIZE = 8000;

    bool public openForPublic;

    address private signer;
    address payable private EGGWALLET;

    uint256 public adminMints;

    string internal baseURI;

    struct URI {
        string path;//the path
        uint256 upto;//represents tokens from the top of the last URI upto this value
    }

    URI[] private URIs;


    constructor() ERC721A("E.G.G. Collective", "EGGCO"){
        baseURI = "ipfs://Qme2MQ5xt88ohcGDA3ZhmHMFJMdhWs6YtbfnenTGPs5yKj"; //Placeholder Token
        signer = 0xBf2AB93ec5f9661A8F97211981fF2199F0A09D9c; 
        EGGWALLET = payable(0xCf8dC536e9016a89298eC9a57b17e455Fe3451eA);
    }

    function mint(uint256 quantity, uint8 mintType, bytes memory signature) external payable {
        require(mintType == 0);
        require(quantity > 0, "Zero mint dissallowed");
        require(quantity <= MAX_MINT, "Exceeds max mint per transaction");
        require(_totalMinted() + quantity <= COLLECTION_SIZE, "Mint would exceed collection size");
        require(msg.value >= COST * quantity, "insufficient funds");

        if(!openForPublic) require(verify(msg.sender, mintType, signature), "ACCESS DENIED");

        _mint(msg.sender, quantity);
 
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


    function adminMint(uint256 quantity) public onlyOwner{
        require(_totalMinted() + quantity <= COLLECTION_SIZE, "Would exceed collection size");
        require(adminMints + quantity <= MAX_ADMIN_MINT, "Would exceed max admin mints");

        adminMints += quantity;
        _mint(msg.sender, quantity);
    }

    function withdraw() public onlyOwner{
        EGGWALLET.transfer(address(this).balance);
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

}