// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";

contract WenWL is ERC721A, Ownable{
    uint256 public constant TOTAL_SUPPLY = 643;
    bool public DIAMOND_FOR_AUCTION_MINTED = false;
    //Create Setters for price
    uint256 public RUBY_PRICE = 0.25 ether;
    uint256 public DIAMOND_PRICE = 0.12 ether;
    uint256 public RUBY_FOR_TEAM = 51;

    uint256 public constant RUBY_MINT_LIMIT = 1;

    //Create Setters for status
    bool public RUBY_IS_ACTIVE = false;
    bool public RUBYPUBLIC_IS_ACTIVE = false;

    //Make setters for the RUBY
    bytes32 rubyRoot = 0x106565418632040e51592ea6849dc9d875964840cc0763513c2c19073d2ceee9;

    mapping(address => uint256) addressBlockBought;
    mapping (address => uint256) public mintedRuby;
    mapping (address => uint256) public mintedPublicRuby;

    address public constant ADDRESS_2 = 0xc9b5553910bA47719e0202fF9F617B8BE06b3A09; //ROYAL LABS
    string private baseURI = "https://rl.mypinata.cloud/ipfs/QmSboi2sSNQBYZeMtXkmoSRTvdU1PHtvyfGTYxMxy8jgaN/";
    address signer;

    constructor() ERC721A("WenWL", "WENWL",100,643) {}

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(RUBY_IS_ACTIVE, "RUBY__MINT_IS_NOT_YET_ACTIVE");
        }

        if(mintType == 2) {
            require(RUBYPUBLIC_IS_ACTIVE, "RUBY_PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Ruby Mint Function WL
    function mintRuby(bytes32[] memory proof) external isSecured(1) payable{
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, rubyRoot, leaf),"PROOF_INVALID");
        require(1 + totalSupply() <= TOTAL_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(mintedRuby[msg.sender] + 1 <= RUBY_MINT_LIMIT,"MINTED_RUBY_ALREADY");

        require(msg.value == RUBY_PRICE , "WRONG_ETH_VALUE");
        addressBlockBought[msg.sender] = block.timestamp;
        mintedRuby[msg.sender] += 1;

        _safeMint(msg.sender, 1);
    }

    // Ruby Mint Function Public
    function mintRubyPublic(uint64 expireTime, bytes memory sig) external isSecured(2) payable{
        bytes32 digest = keccak256(abi.encodePacked(msg.sender,expireTime));
        require(block.timestamp <= expireTime, "EXPIRED_SIGNATURE");
        require(isAuthorized(sig,digest),"CONTRACT_MINT_NOT_ALLOWED");
        require(1 + totalSupply() <= TOTAL_SUPPLY,"NOT_ENOUGH_PRESALE_SUPPLY");
        require(mintedPublicRuby[msg.sender] + 1 <= RUBY_MINT_LIMIT,"MINTED_RUBY_ALREADY");

        require(msg.value == RUBY_PRICE , "WRONG_ETH_VALUE");
        addressBlockBought[msg.sender] = block.timestamp;
        mintedPublicRuby[msg.sender] += 1;

        _safeMint(msg.sender, 1);
    }

    // Diamond Mint to owner's wallet
    function mintDiamond() external onlyOwner {
        require(!DIAMOND_FOR_AUCTION_MINTED,"DIAMOND_HAS_BEEN_MINTED");
        DIAMOND_FOR_AUCTION_MINTED = true;
        _safeMint(msg.sender, 88);
    }

    // DiamoRubynd Mint to owner's wallet for giveaway
    function mintRubyForTeam() external onlyOwner {
        require(RUBY_FOR_TEAM > 0,"EXCEED_MINT_LIMIT");
        RUBY_FOR_TEAM = 0;
        _safeMint(msg.sender, 51);
    }

    // Base URI
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    // Ruby's WL status
    function setRubyWLSaleStatus() external onlyOwner {
        RUBY_IS_ACTIVE = !RUBY_IS_ACTIVE;
    }

    // Ruby PUblic Sale Status
    function setRubyPublicSaleStatus() external onlyOwner {
        RUBYPUBLIC_IS_ACTIVE = !RUBYPUBLIC_IS_ACTIVE;
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function setPresaleRoot(bytes32 _rubyRoot) external onlyOwner {
        rubyRoot = _rubyRoot;
    }

    //Passed as wei
    function setRubyPrice(uint256 _rubyPrice) external onlyOwner {
        RUBY_PRICE = _rubyPrice;
    }

    function setSigner(address _signer) external onlyOwner{
        signer = _signer;
    }

    function isAuthorized(bytes memory sig,bytes32 digest) private view returns (bool) {
        return ECDSA.recover(digest, sig) == signer;
    }

    //Essential

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(ADDRESS_2).transfer((balance * 1500) / 10000);
        payable(msg.sender).transfer(address(this).balance);
    }
}