// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Hidden Kitten City by Bitiocracy

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./ERC721OperatorFilter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



error InsufficientPayment();

interface NftContract {
    function balanceOf(address) external view returns (uint256);
}



contract HiddenKittenCity is
    Ownable,
    EIP712, 
    ERC721OperatorFilter,
    ERC721AQueryable {
    // EIP712 Feature
    bytes32 public constant TYPEHASH =
        keccak256("PassReq(address receiver,uint256 amount)");
    struct PassReq {
        address receiver;
        uint256 amount;
    }

     

    // CockaDoodles Contract Addresss for Mint
    NftContract public cNft =
        NftContract(0xa86359c1aD8c0483A1A49b37ea3646dEaF6e342A);
   
            
//bitiocracy
    address private constant core1Address =
        0x3002E0E7Db1FB99072516033b8dc2BE9897178bA;
    uint256 private constant core1Shares = 75500;

    address private constant core2Address =
        0xCe335de9Adc23EB0F4C034ec3428b81D057F2316;
    uint256 private constant core2Shares = 19000;

    address private constant core3Address =
        0xA55c2F8Af10d603976dEcA0B61Cd87ba2F9C6492;
    uint256 private constant core3Shares = 3000;

    address private constant core4Address =
        0x71db1f8E62BB3D2B77b00077b434a477CE966f2b;
    uint256 private constant core4Shares = 2000;

    address private constant core5Address =
        0xc8b0D32bc09Fb11C12C82582825C1e6b624822b8;
    uint256 private constant core5Shares = 500;    



    // Merkle Tree Roots
    bytes32 public merkleRootTier1;
    bytes32 public merkleRootTier2;
    bytes32 public merkleRootPublic;

    string public baseURI;
    uint256 public MAX_SUPPLY = 8888;
    uint256 public MAX_SUPPLY_PLUS_ONE = 8889;
    uint256 public MAX_TX_PLUS_ONE = 3; //actual value 2 for public sale tx
    uint256 public price = 0.088 ether;
    address public store;

    uint256 public MAX_PRESALE_MINTS = 2;
    uint256 public MAX_PRESALE_MINTS_PLUS_ONE = 3;  //actual value 2 for public sale tx 
    uint256 public GENERAL_MEOWLIST_SUPPLY = 6000;
    uint256 public GENERAL_MEOWLIST_SUPPLY_PLUS_ONE = 6001;
    uint256 public TOTAL_MEOWLIST_SUPPLY = 8000;
    uint256 public TOTAL_MEOWLIST_SUPPLY_PLUS_ONE = 8001;
    
    uint256 public generalMeowMinted = 0;


    mapping(address => uint256) private premintedAmount; 
    mapping(address => uint256) private premintedAmountCD; 

    uint256 private constant baseMod = 100000;

    event SetStore(address store);
    event SetBaseURI(string baseURI);
    event MintMeowListReservedHash(address claimer, uint256 amount);
    event MintMeowListGeneralMerkle(address claimer, uint256 amount);
    event MintMeowListReservedMerkle(address claimer, uint256 amount);
    event MintPublicMerkle(address claimer, uint256 amount);
    event Mint(address claimer, uint256 amount);


    bool public presaleOn = false;
    bool public mainSaleOn = false;
    bool public openSaleOn = false;

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
            core1Address == msg.sender || core2Address == msg.sender || core3Address == msg.sender ||  core5Address == msg.sender|| owner() == msg.sender,
            "caller is neither Team Wallet nor Owner"
        );
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    } 

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override(ERC721A, ERC721OperatorFilter) {
        
        super._beforeTokenTransfers(from, to, tokenId, quantity);
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


    function setTotalMeowList (uint256 _newtotal) external onlyOwner {
        TOTAL_MEOWLIST_SUPPLY = _newtotal;
        TOTAL_MEOWLIST_SUPPLY_PLUS_ONE = _newtotal +1;
    }

    function setGeneralMeowList (uint256 _newgeneral) external onlyOwner {
        GENERAL_MEOWLIST_SUPPLY = _newgeneral;
        GENERAL_MEOWLIST_SUPPLY_PLUS_ONE = _newgeneral +1;
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

    function amountPreminted(address _address) external view returns (uint256) {
        return premintedAmount[_address];
    }

    function amountPremintedCD(address _address) external view returns (uint256) {
        return premintedAmountCD[_address];
    }

    // Sale Toggles

    function togglePresale() external onlyOwner {
        presaleOn = !presaleOn;
    }

    function toggleMainSale() external onlyOwner {
        mainSaleOn = !mainSaleOn;
    }    

    function toggleOpenSale() external onlyOwner {
        openSaleOn = !openSaleOn;
    }



    // Merkel Tree Functions

    function _generateMerkleLeaf(address account) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(account) );
    }


    // Tier 1

    /**
        Merkle Tree for Reserved MeowList (Tier 1)
     */    
    function setMerkleRootReserved( bytes32 _merkleRoot ) external onlyOwner {
        merkleRootTier1 = _merkleRoot;
    }



    /**
        MeowList Sale with Merkle Tree
     */
    function mintMeowListReservedMerkle(
        uint256 amount, 
        bytes32[] calldata proof
    ) external payable {
        require(presaleOn, "Presale Not Live");

        //Just checking against total meowlist numbers.
        require(totalSupply() + amount < TOTAL_MEOWLIST_SUPPLY_PLUS_ONE, "Exceeds max supply");

        uint256 totalClaim = premintedAmount[msg.sender] + amount;
        require(totalClaim < MAX_PRESALE_MINTS_PLUS_ONE, "Over max presale allowed");

        uint256 generalAmount = 0;
        if (totalClaim > 1)
        {
            generalAmount = totalClaim - 1;
            if (generalAmount > amount) {
                generalAmount = amount;
            }
        } 
        require(generalMeowMinted + generalAmount < GENERAL_MEOWLIST_SUPPLY_PLUS_ONE, "Exceeds General Meowlist");

        uint256 cost = amount * price;
        if (msg.value < cost) revert InsufficientPayment();

        require( 
            MerkleProof.verify(proof, merkleRootTier1, _generateMerkleLeaf(msg.sender)), "User not in WL" 
        );

        premintedAmount[msg.sender] += amount;
        _safeMint(msg.sender, amount);

        generalMeowMinted += generalAmount;

        emit MintMeowListReservedMerkle(msg.sender, amount);
    }



    // Tier 2

    /**
        Merkle Tree for General MeowList (Tier2)
     */    
    function setMerkleRootGeneral( bytes32 _merkleRoot ) external onlyOwner {
        merkleRootTier2 = _merkleRoot;
    }



    /**
        MeowList Tier 2 Sale with Merkle Tree
     */
    function mintMeowListGeneralMerkle(
        uint256 amount, 
        bytes32[] calldata proof
    ) external payable {
        require(presaleOn, "Presale Not Live");
        require(totalSupply() + amount < TOTAL_MEOWLIST_SUPPLY_PLUS_ONE, "Exceeds max supply");

        require(premintedAmount[msg.sender] + amount < MAX_PRESALE_MINTS_PLUS_ONE, "Over max presale allowed");
        require(generalMeowMinted + amount < GENERAL_MEOWLIST_SUPPLY_PLUS_ONE, "Exceeds General Meowlist");

        uint256 cost = amount * price;
        if (msg.value < cost) revert InsufficientPayment();

        require( 
            MerkleProof.verify(proof, merkleRootTier2, _generateMerkleLeaf(msg.sender)), "User not in WL" 
        );

        premintedAmount[msg.sender] += amount;
        _safeMint(msg.sender, amount);

        generalMeowMinted += amount;

        emit MintMeowListGeneralMerkle(msg.sender, amount);
    }



    /**
        Mint Tier 1 CockaDoodle Mint - Abilty to set amount by wallet
     */
    function mintMeowListCockadoodleHash(
        uint256 amount,
        uint256 _passAmount,
        uint8 vSig,
        bytes32 rSig,
        bytes32 sSig
    ) external payable {

        require(presaleOn, "Presale Not Live");


        //Just checking against total meowlist numbers.
        require(totalSupply() + amount < TOTAL_MEOWLIST_SUPPLY_PLUS_ONE, "Exceeds max supply");

        uint256 totalPassAmount = (2 * _passAmount);
        uint256 totalClaim = premintedAmountCD[msg.sender] + amount;
        require(totalClaim <= totalPassAmount, "Claiming Too Many");

        // add up total amount, subtract tier1 amount to see how many are in tier 2
        uint256 generalAmount = 0;
        if (totalClaim > _passAmount)
        {
            generalAmount = totalClaim - _passAmount;
            if (generalAmount > amount) {
                generalAmount = amount;
            }
        } 
        require(generalMeowMinted + generalAmount < GENERAL_MEOWLIST_SUPPLY_PLUS_ONE );


        uint256 _balance = cNft.balanceOf(msg.sender);
        require( (totalClaim * 3) <= _balance, "Claiming Too Many");


        uint256 cost = amount * price;
        if (msg.value < cost) revert InsufficientPayment();

        
        // hash verification
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(TYPEHASH, msg.sender, _passAmount))
        );
        address signer = ecrecover(digest, vSig, rSig, sSig);
        require(signer == owner(), "Signature is not from the owner");


        premintedAmountCD[msg.sender] += amount;

        _safeMint(msg.sender, amount);

        generalMeowMinted += generalAmount;

        emit MintMeowListReservedHash(msg.sender, amount);

    }


    /**
        Mint Tier 1 CockaDoodle Mint - No Wallet Check - set amount by wallet
     */
    function mintMeowListCockadoodleNoCheckHash(
        uint256 amount,
        uint256 _passAmount,
        uint8 vSig,
        bytes32 rSig,
        bytes32 sSig
    ) external payable {

        require(presaleOn, "Presale Not Live");


        //Just checking against total meowlist numbers.
        require(totalSupply() + amount < TOTAL_MEOWLIST_SUPPLY_PLUS_ONE, "Exceeds max supply");

        uint256 totalPassAmount = (2 * _passAmount);     
        uint256 totalClaim = premintedAmountCD[msg.sender] + amount;
        require(totalClaim <= totalPassAmount, "Claiming Too Many");

        // add up total amount, subtract tier1 amount to see how many are in tier 2
        uint256 generalAmount = 0;
        if (totalClaim > _passAmount)
        {
            generalAmount = totalClaim - _passAmount;
            if (generalAmount > amount) {
                generalAmount = amount;
            }
        } 
        require(generalMeowMinted + generalAmount < GENERAL_MEOWLIST_SUPPLY_PLUS_ONE );
        

        uint256 cost = amount * price;
        if (msg.value < cost) revert InsufficientPayment();


        // hash verification
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(TYPEHASH, msg.sender, _passAmount))
        );
        address signer = ecrecover(digest, vSig, rSig, sSig);
        require(signer == owner(), "Signature is not from the owner");


        premintedAmountCD[msg.sender] += amount;

        _safeMint(msg.sender, amount);

        generalMeowMinted += generalAmount;

        emit MintMeowListReservedHash(msg.sender, amount);

    }

    // Merkel Tree Public
    function setMerkleRootPublic( bytes32 _merkleRoot ) external onlyOwner {
        merkleRootPublic = _merkleRoot;
    }



    /**
        Public Sale with Merkle Tree
     */
    function mintPublicMerkle(
        uint256 amount, 
        bytes32[] calldata proof
    ) external payable {
        require(mainSaleOn, "Main Sale Not Live");
        require(amount < MAX_TX_PLUS_ONE, "Over max public tx");
        require(totalSupply() + amount < MAX_SUPPLY_PLUS_ONE, "Exceeds Supply");

        uint256 cost = amount * price;
        if (msg.value < cost) revert InsufficientPayment();

        require( 
            MerkleProof.verify(proof, merkleRootPublic, _generateMerkleLeaf(msg.sender)), "User not in Merkle" 
        );


        _safeMint(msg.sender, amount);

  
        emit MintPublicMerkle(msg.sender, amount);
    }
 




    /**
        open mint
     */
    function mint(uint256 amount) external payable callerIsUser {
        require(openSaleOn, "Open Sale Not On");
        require(totalSupply() + amount < MAX_SUPPLY_PLUS_ONE, "Exceeds max supply");
        require(amount < MAX_TX_PLUS_ONE, "Over Max per Mint");

        uint256 cost = amount * price;
        if (msg.value < cost) revert InsufficientPayment();


        _safeMint(msg.sender, amount);

        emit Mint(msg.sender, amount);
    }

    // BACKUP STORE

    /**
        Mint with external store function (backup)
     */
    function mintStore(address to, uint256 amount) external onlyOwnerOrStore {
        require(totalSupply() + amount < MAX_SUPPLY_PLUS_ONE, "Exceeds max supply");

        _safeMint(to, amount);

        emit Mint(to, amount);
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
        _withdraw(core5Address, address(this).balance);
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