pragma solidity ^0.8.7;


import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/MerkleProofLib.sol";

enum SaleState {
    NOSALE, WLSALE, PUBLICSALE
}

contract OokamiToHitsuji is ERC721A('Ookami To Hitsuji', 'OTH'), Ownable {
    using LibString for uint256;

    address constant WG = 0x41538872240Ef02D6eD9aC45cf4Ff864349D51ED;     
    address constant RIRIYAKI = 0x4c73EAffC8f62C3c42f781594e9b121B8A1Be18B;   
    address constant FANCY = 0x4c73EAffC8f62C3c42f781594e9b121B8A1Be18B;  
    string baseuri = "ipfs://Qmeog744mM5gx6DEigU8BiFX1Gqr52bNRfk9RBm4hAqtg3";   

    uint256 public price = .01 ether;
    uint256 public maxSupply = 999;

    mapping(address => bool) public wlMintClaimed;

    SaleState public saleState = SaleState.NOSALE;
    
    bytes32 public wlMerkleRoot;

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseuri, '/', _tokenId.toString(), '.json'));
    }

    function publicMint(uint256 count) external payable {
        require(msg.value >= (price * count), "not sending enough ether for mint");
        require(totalSupply() + count <= maxSupply);
        require(saleState == SaleState.PUBLICSALE, "Not in public sale");
        require(count < 6, "mint is max 5 only");
        _safeMint(msg.sender, count);
    }

    function whitelistMint(bytes32[] calldata proof, uint256 count) external {
        require(saleState == SaleState.WLSALE, "Not in WL sale");
        require(MerkleProofLib.verify(proof, wlMerkleRoot, keccak256(abi.encodePacked(msg.sender, count.toString()))));
        require(!wlMintClaimed[msg.sender], "wl claimed");
        require(totalSupply() + count <= maxSupply);
        _safeMint(msg.sender, count);
        wlMintClaimed[msg.sender] = true;
    }

    function ownerMint(address _user, uint256 _count) external onlyOwner {
        require(totalSupply() + _count <= maxSupply);
        _safeMint(_user, _count);
    }

    function setSaleState(SaleState newSaleState) external onlyOwner {
        saleState = newSaleState;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }
    function setWlMerkleRoot(bytes32 newWlMerkleRoot) external onlyOwner {
        wlMerkleRoot = newWlMerkleRoot;
    }

    function setBaseUri(string memory _newBaseUri) external onlyOwner {
        baseuri = _newBaseUri;
    }

    function withdrawEth() external {
        uint256 bal = address(this).balance;
        payable(WG).call{value: (bal / 4)}('');
        payable(FANCY).call{value: bal / 4}('');
        payable(RIRIYAKI).call{value: address(this).balance}('');
    }
}