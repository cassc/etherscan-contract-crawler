// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract WenWLRuby is ERC1155Supply, Ownable{
    uint256 public constant RUBY_SUPPLY = 555;

    uint256 public constant RUBY = 0;

    uint256 public RUBY_PRICE = 0.25 ether;
    uint256 public constant RUBY_FOR_TEAM = 51;

    uint256 public constant RUBY_LIMIT = 1;

    //Create Setters for status
    bool public RUBY_IS_ACTIVE = false;
    bool public RUBYPUBLIC_IS_ACTIVE = false;

    //Make setters for the RUBY
    bytes32 rubyRoot;

    mapping(address => uint256) addressBlockBought;
    mapping (address => uint256) public mintedRuby;
    mapping (address => uint256) public mintedPublicRuby;

    string private _baseUri;

    address public constant ADDRESS_2 = 0xc9b5553910bA47719e0202fF9F617B8BE06b3A09; //ROYAL LABS
    address public constant ADDRESS_1 = 0x8975b2c67Cffc4498D927B0B18C7c9030512672B; // WENWL TEAM

    address signer;

    constructor() ERC1155("https://rl.mypinata.cloud/ipfs/QmdjBkKwrHYsW3gJpw2Wzwqssuad8zocNgL1fkeZz5GJx1/") {}

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(RUBY_IS_ACTIVE, "RUBY_MINT_IS_NOT_YET_ACTIVE");
        }

        if(mintType == 2) {
            require(RUBYPUBLIC_IS_ACTIVE, "RUBY_PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseUri, Strings.toString(_id)));
    }

    // Ruby Mint Function WL
    function mintRuby(bytes32[] memory proof) external isSecured(1) payable{
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, rubyRoot, leaf),"PROOF_INVALID");
        require(1 + totalSupply(RUBY) <= RUBY_SUPPLY,"NOT_ENOUGH_PRESALE_SUPPLY");
        require(mintedRuby[msg.sender] + 1 <= RUBY_LIMIT,"MINTED_RUBY_ALREADY");

        require(msg.value == RUBY_PRICE , "WRONG_ETH_VALUE");
        addressBlockBought[msg.sender] = block.timestamp;
        mintedRuby[msg.sender] += 1;

        _mint(msg.sender, RUBY, 1, "");
    }

    // Ruby Mint Function Public
    function mintRubyPublic(uint64 expireTime, bytes memory sig) external isSecured(2) payable{
        bytes32 digest = keccak256(abi.encodePacked(msg.sender,expireTime));
        require(isAuthorized(sig,digest),"CONTRACT_MINT_NOT_ALLOWED");
        require(1 + totalSupply(RUBY) <= RUBY_SUPPLY,"NOT_ENOUGH_PRESALE_SUPPLY");
        require(mintedPublicRuby[msg.sender] + 1 <= RUBY_LIMIT,"MINTED_RUBY_ALREADY");

        require(msg.value == RUBY_PRICE , "WRONG_ETH_VALUE");
        addressBlockBought[msg.sender] = block.timestamp;
        mintedPublicRuby[msg.sender] += 1;

        _mint(msg.sender, RUBY, 1, "");
    }

    // Ruby Mint to owner's wallet for giveaway
    function mintRubyForTeam() external onlyOwner {
        require(totalSupply(RUBY) <= RUBY_SUPPLY,"EXCEED_MINT_LIMIT");
        require(totalSupply(RUBY) <= RUBY_FOR_TEAM,"EXCEED_MINT_LIMIT");
        _mint(msg.sender, RUBY, RUBY_FOR_TEAM, "");
    }

    // Base URI
    function setBaseURI(string calldata URI) external onlyOwner {
        _baseUri = URI;
    }

    // Ruby's WL status
    function setRubyWLSaleStatus() external onlyOwner {
        RUBY_IS_ACTIVE = !RUBY_IS_ACTIVE;
    }

    // Ruby PUblic Sale Status
    function setRubyPublicSaleStatus() external onlyOwner {
        RUBYPUBLIC_IS_ACTIVE = !RUBYPUBLIC_IS_ACTIVE;
    }

    function setPresaleRoot(bytes32 _rubyRoot) external onlyOwner {
        rubyRoot = _rubyRoot;
    }

    function setSigner(address _signer) external onlyOwner{
        signer = _signer;
    }

    function setRubyPrice(uint256 _rubyPrice) external onlyOwner {
      RUBY_PRICE = _rubyPrice;
    }

    function isAuthorized(bytes memory sig,bytes32 digest) private view returns (bool) {
        return ECDSA.recover(digest, sig) == signer;
    }

    //Essential

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(ADDRESS_2).transfer((balance * 1500) / 10000);
        payable(ADDRESS_1).transfer(address(this).balance);
    }
}