// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



error InsufficientPayment();

interface NftContract {
    function balanceOf(address) external view returns (uint256);
}



contract CockaDoodles is ERC721A, EIP712, Ownable {
    // EIP712 Feature
    bytes32 public constant TYPEHASH =
        keccak256("PassReq(address receiver,uint256 amount)");
    struct PassReq {
        address receiver;
        uint256 amount;
    }

     

    // BF Contract Addresss for Claim
    NftContract public bfNft =
        NftContract(0xBAB7dF6D042F4b83b62070b670Da929b62eD22d8);
   
            

    address private constant core1Address =
        0x3002E0E7Db1FB99072516033b8dc2BE9897178bA;
    uint256 private constant core1Shares = 73000;

    address private constant core2Address =
        0x2D97a5A8Da17227b9b393ca9Be92bfa1a46dF179;
    uint256 private constant core2Shares = 7000;

    address private constant core3Address =
        0x4EA87748D54957ed4e6e09E18dFB8F52A492C51e;
    uint256 private constant core3Shares = 7000;

    address private constant core4Address =
        0x8520201Ec6Ab08AA35270efDCF28b51a826bcd97;
    uint256 private constant core4Shares = 7000;

    address private constant core5Address =
        0xbeB3B8BD01a842Be859A5a92cA3758132C08B546;
    uint256 private constant core5Shares = 5000;    

    address private constant core6Address =
        0x81863F0Cf78358fAdA029B7D5fa0b84674802eF1; 
    uint256 private constant core6Shares = 500;

    address private constant core7Address =
        0xa808208Bb50e2395c63ce3fd41990d2E009E3053; 
    uint256 private constant core7Shares = 500;


    // Merkle Tree 
    bytes32 public merkleRoot;

    string public baseURI;
    uint256 public MAX_SUPPLY = 4444;
    uint256 public MAX_SUPPLY_PLUS_ONE = 4445;
    uint256 public MAX_TX_PLUS_ONE = 6; //actual value 5 for public sale tx
    uint256 public price = 0.04 ether;
    address public store;
    uint256 public MAX_PRESALE_MINTS = 2;
    uint256 public MAX_PRESALE_MINTS_PLUS_ONE = 3;

    mapping(address => uint256) private claimedAmount; 
    mapping(address => uint256) private premintedAmount; 

    uint256 private constant baseMod = 100000;

    event SetStore(address store);
    event SetBaseURI(string baseURI);
    event FashionistaClaim(address claimer, uint256 amount);
    event MintPresaleHash(address claimer, uint256 amount);
    event MintPresaleMerkle(address claimer, uint256 amount);

    bool public claimOn = false;
    bool public presaleOn = false;
    bool public mainSaleOn = false;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI
    ) ERC721A(__name, __symbol) EIP712(__name, "1") {
        baseURI = __baseURI;
    }

    modifier onlyOwnerOrStore() {
        require(
            store == msg.sender || owner() == msg.sender,
            "caller is neither store nor owner"
        );
        _;
    }

    modifier onlyOwnerOrTeam() {
        require(
            core1Address == msg.sender || core2Address == msg.sender || core3Address == msg.sender || core4Address == msg.sender || core6Address == msg.sender|| owner() == msg.sender,
            "caller is neither Team Wallet nor Owner"
        );
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    } 


    /**
        Lowers the Max Supply
     */
    function lowerMaxSupply(uint256 _newmax) external onlyOwner {
        require(_newmax < MAX_SUPPLY,"Can only lower supply");
        require(_newmax > totalSupply(),"Can't set below current");
        MAX_SUPPLY = _newmax;
        MAX_SUPPLY_PLUS_ONE = _newmax + 1;
    }

    function setStore(address _store) external onlyOwner {
        store = _store;
        emit SetStore(_store);
    }

    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
        emit SetBaseURI(__baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function amountClaimed(address _address) external view returns (uint256) {
        return claimedAmount[_address];
    }

    function amountPreminted(address _address) external view returns (uint256) {
        return premintedAmount[_address];
    }


    // Sale Toggles
    function toggleClaim() external onlyOwner {
        claimOn = !claimOn;
    }

    function togglePresale() external onlyOwner {
        presaleOn = !presaleOn;
    }

    function toggleMainSale() external onlyOwner {
        mainSaleOn = !mainSaleOn;
    }    
  

    // Merkel Tree
    function setMerkleRoot( bytes32 _merkleRoot ) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _generateMerkleLeaf(address account) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(account) );
    }


    /**
        New Presale with Merkle Method to as msg.sender
     */
    function mintPresaleMerkle(
        uint256 amount, 
        bytes32[] calldata proof
    ) external payable {
        require(presaleOn, "Presale Not Live");
        require(premintedAmount[msg.sender] + amount < MAX_PRESALE_MINTS_PLUS_ONE, "Over max presale allowed");
        require(totalSupply() + amount < MAX_SUPPLY_PLUS_ONE, "Exceeds max supply");

        uint256 cost = amount * price;
        if (msg.value < cost) revert InsufficientPayment();

        require( 
            MerkleProof.verify(proof, merkleRoot, _generateMerkleLeaf(msg.sender)), "User not in WL" 
        );

        premintedAmount[msg.sender] += amount;
        _safeMint(msg.sender, amount);


        emit MintPresaleMerkle(msg.sender, amount);
    }


    /**
        Fashionista Claim Function
     */
    function fashionistaClaim(
        uint256 amount,
        uint256 _passAmount,
        uint8 vSig,
        bytes32 rSig,
        bytes32 sSig
    ) external payable {

        require(claimOn, "Claim Not On");
        require(totalSupply() + amount < MAX_SUPPLY_PLUS_ONE, "Exceeds max supply");

        uint256 totalClaim = claimedAmount[msg.sender] + amount;
        require(totalClaim <= _passAmount, "Claiming Too Many");

        uint256 _balance = bfNft.balanceOf(msg.sender);
        require(totalClaim <= _balance, "Claiming Too Many");

        // hash verification
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(TYPEHASH, msg.sender, _passAmount))
        );
        address signer = ecrecover(digest, vSig, rSig, sSig);
        require(signer == owner(), "Signature is not from the owner");


        claimedAmount[msg.sender] += amount;

        _safeMint(msg.sender, amount);

        emit FashionistaClaim(msg.sender, amount);

    }



    // PUBLIC SALE

    /**
        main mint
     */
    function mint(address to, uint256 amount) external payable callerIsUser {
        require(mainSaleOn, "Main Sale Not On");
        require(totalSupply() + amount < MAX_SUPPLY_PLUS_ONE, "Exceeds max supply");
        require(amount < MAX_TX_PLUS_ONE, "Over Max per Mint");

        uint256 cost = amount * price;
        if (msg.value < cost) revert InsufficientPayment();


        _safeMint(to, amount);

    }

    // PUBLIC SALE

    /**
        Mint with external store function (backup)
     */
    function mintStore(address to, uint256 amount) external onlyOwnerOrStore {
        require(totalSupply() + amount < MAX_SUPPLY_PLUS_ONE, "Exceeds max supply");

        _safeMint(to, amount);
    }


    //  **** Withdraw Functions

    /**
        Main Withdraw
     */
    function withdrawCore() external onlyOwnerOrTeam {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _splitAll(balance);

    }

    function _splitAll(uint256 _amount) private {
        uint256 singleShare = _amount / baseMod;
        _withdraw(core1Address, singleShare * core1Shares);
        _withdraw(core2Address, singleShare * core2Shares);
        _withdraw(core3Address, singleShare * core3Shares);
        _withdraw(core4Address, singleShare * core4Shares);
        _withdraw(core5Address, singleShare * core5Shares);
        _withdraw(core6Address, singleShare * core6Shares);
        _withdraw(core7Address, address(this).balance);
    }

    /**
        Backup Withdrawal
     */
    function withdrawBU() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(core1Address, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
    }    


}