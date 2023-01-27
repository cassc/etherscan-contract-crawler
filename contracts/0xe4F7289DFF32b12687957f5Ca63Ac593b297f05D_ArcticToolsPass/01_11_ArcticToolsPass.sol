// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
 
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
 
contract ArcticToolsPass is ERC721A, PaymentSplitter, Ownable { 
    uint public maxSupply = 1111;
    uint public maxMintsPerWallet = 1;
    uint public price = .089 ether;
 
    bytes32 public merkleRoot;
 
    bool public mintOpen = false;
    bool public whitelistOnly = true;
    bool public allowBurn = false;
 
    string internal baseTokenURI = "ipfs://bafybeigdzkutb7ruat3u3gwbzq7l6xympnafhvcwhtngmr54fgxk6gdlry/";
 
	address[] private addressList = [
        0x846ab08ffF0B8BcF3A99A8d00cB74cED930F6879,
        0x7F14cE4c3cDeAf9cF8189D599032B881E442e76c,
        0xA40AE6C8bEb96faA18645d130a020908C996b114,
        0x963Caf5744526C1D231C10FDB99B61e6AA7F159d,
        0x5D870CBB38ed1759f4774B73EC97DB9277de0613,
        0x97d398B06006Bf1EBF76CF015884cD0456ccfC2C,
        0x4a6c0819aa3137C720F6439812F1bB55296945B5,
        0x67d5894E8aA3F2395d6EDd94551d25aC9D30D6DA,
        0x46F06B48Dd254f4D31562d3Ffb3781621934a4Dd
    ];
 
	uint[] private shareList = [
        50000,
        50000,
        292500,
        222750,
        177750,
        135000,
        45000,
        18000,
        9000
	];
 
    constructor() ERC721A("Arctic Tools Pass", "ATP") PaymentSplitter(addressList, shareList) {}
 
    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }
 
    function toggleWhitelist() external onlyOwner {
        whitelistOnly = !whitelistOnly;
    }
 
    function toggleBurning() external onlyOwner {
        allowBurn = !allowBurn;
    }
 
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
 
    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }
 
    function setMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
 
    function setMaxMintsPerWallet(uint _maxMintsPerWallet) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
    }
 
    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }
 
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }
 
    function mintWhitelist(bytes32[] calldata _merkleProof) external payable {
        require(mintOpen, "Mint Not Open");
        require(MerkleProof.verifyCalldata(_merkleProof, merkleRoot,keccak256(abi.encodePacked(msg.sender))), "Proof invalid");
        require(msg.value >= price, "Not Enough Ether");
        require(_totalMinted() + 1 <= maxSupply, "Max Supply");
        require(_numberMinted(msg.sender) + 1 <= maxMintsPerWallet, "Out Of Mints");
        _mint(msg.sender, 1);
    }
 
    function mintPublic() external payable {
        require(mintOpen, "Mint Not Open");
        require(!whitelistOnly, "Only Whitelist");
        require(msg.value >= price, "Not Enough Ether");
        require(_totalMinted() + 1 <= maxSupply, "Max Supply");
        require(_numberMinted(msg.sender) + 1 <= maxMintsPerWallet, "Out Of Mints");
        _mint(msg.sender, 1);
    }
 
    function mintOwner(uint _amount) external onlyOwner {
        _mint(msg.sender, _amount);
    }
 
    function burn(uint256 tokenId) public virtual {
        require(allowBurn, "Not Allowed");
        _burn(tokenId, true);
    }
 
    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }
 
}