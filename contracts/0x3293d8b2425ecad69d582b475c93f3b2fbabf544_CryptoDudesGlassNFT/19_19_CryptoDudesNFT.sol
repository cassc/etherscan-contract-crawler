// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//@author Mia Dude
//@title CryptoDudes NFT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";
import "./extensions/ERC721AQueryable.sol";

contract CryptoDudesNFT is Ownable, ERC721A, ERC721AQueryable, PaymentSplitter {

    using Strings for uint;

    // *************** selling steps
    // Gift: Reserved for the team and gifts
    // Sale: whitelist and public sale
    // End: mint finished, we can call the setRevealedURI
    // Revealed: ! \o/

    


    enum Step {
        Gift,
        Sale,
        End,
        Revealed,
        Frozen
    }

    Step public sellingStep;

    //settings ----
    uint public MAX_SUPPLY = 2222;
    uint public MAX_WHITELIST = 200;
    uint public MAX_PUBLIC = 2000;
    uint public MAX_GIFT = 22;

    uint public MAX_MINT_PER_TRANSACTION = 20;
    uint public MAX_NFT_PER_WALLET_WHITELIST = 1;

    uint public WHITELIST_DURATION = 1440 minutes;

    uint public wlSalePrice = 0.11 ether;
    uint public publicSalePrice = 0.11 ether;

    uint public saleStartTime = 1655568000;

    bytes32 public merkleRoot;

    //URI of the NFTs when revealed
    string public baseURI;

    //URI of the NFTs when not revealed
    string public notRevealedURI;

    //keep track of whitelisted mint
    mapping(address => uint) public amountNFTsperWalletWhitelistSale;

    //team share length
    uint private teamLength;

    // **********************************************************************************
    // *********** CONSTRUCTOR 
    // **********************************************************************************

    constructor(address[] memory _team, uint[] memory _teamShares, bytes32 _merkleRoot, string memory _notRevealedURI, uint _startTime) ERC721A("CryptoDudes", "CRYPTODUDES") PaymentSplitter(_team, _teamShares) {
        merkleRoot = _merkleRoot;
        notRevealedURI = _notRevealedURI;
        teamLength = _team.length;
        saleStartTime = _startTime;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }


    // **********************************************************************************
    // *********** WHITE LIST MINT 
    // **********************************************************************************

    function whitelistMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        uint price = wlSalePrice;
        require(price != 0, "Price is 0");

        // check times after startime and before starttime + whitelist duration
        require(currentTime() >= saleStartTime, "Whitelist mint has not started yet");
        require(currentTime() <= saleStartTime + WHITELIST_DURATION, "Whitelist Sale is finished");

        // are we in step sale, whitelisted, and trying to mint only MAX_NFT_PER_WALLET_WHITELIST
        require(sellingStep == Step.Sale, "Whitelist mint is not activated");
        require(isWhiteListed(msg.sender, _quantity, _proof), "You are not whitelisted");
        require(amountNFTsperWalletWhitelistSale[msg.sender] + _quantity <= MAX_NFT_PER_WALLET_WHITELIST, "You can only get 1 NFT during the Whitelist mint");

        // allow mint up to MAX_WHITELIST
        require(totalSupply() + _quantity <= MAX_WHITELIST + MAX_GIFT, "Max supply whitelist exceeded");

        // are you sending enough eth
        require(msg.value >= price * _quantity, "Not enought funds");

        // mint 
        amountNFTsperWalletWhitelistSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    // **********************************************************************************
    // *********** PUBLIC MINT  
    // **********************************************************************************

    function publicSaleMint(address _account, uint _quantity) external payable callerIsUser {
        uint price = publicSalePrice;
        require(price != 0, "Price is 0");

        // check times after the whitelist phase only
        require(currentTime() > saleStartTime + WHITELIST_DURATION, "Public mint has not started yet");

        // are we in step sale, and trying to mint too many nft
        require(sellingStep == Step.Sale, "Public mint is not activated");
        require(_quantity <= MAX_MINT_PER_TRANSACTION, "You tried to mint too many NFT in a single transaction");
        

        // allow mint up to MAX_WHITELIST + MAX_PUBLIC during public mint
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");   

        // are you sending enough eth
        require(msg.value >= price * _quantity, "Not enought funds");

        // if we reach the max minted here, automatically switch to the End Step (team and gift mint)
        if (totalSupply() + _quantity == MAX_SUPPLY) {
            sellingStep = Step.End;
        }
        _safeMint(_account, _quantity);
    }

    // **********************************************************************************
    // *********** TEAM AND GIFTS MINT 
    // **********************************************************************************

    function gift(address _to, uint _quantity) external onlyOwner {
        require(sellingStep == Step.Gift, "No Gift during the public sale");
        require(totalSupply() + _quantity <= MAX_GIFT, "Can't gift more than MAX_GIFT");

        if (totalSupply() + _quantity == MAX_GIFT) {
            sellingStep = Step.Sale;
        }
        _safeMint(_to, _quantity);
    }


    // **********************************************************************************
    // *********** BASE URI SETTINGS  
    // **********************************************************************************

    function setRevealedURI(string memory _baseURI) external onlyOwner {
        require(sellingStep == Step.End, "You can only update the revealed URI after the sales");
        sellingStep = Step.Revealed;
        baseURI = _baseURI;
    }

    function currentTime() internal view returns(uint) {
        return block.timestamp;
    }

    // Owner can update manually the steps (ex, if not sold out, switch to sellingStep 'End' allows to do the reveal, or if URI needs an emergency update)
    // Setting the step 'frozen' means that we can't go back to another step (setRevealedURI works only for the 'End' Step, so when frozen, nobody can change the metadatas URI)
    // as we are on IPFS, it's fully decentralized, and nobody will change the NFTs traits and images
    function setStep(uint _step) external onlyOwner {
        require(sellingStep != Step.Frozen, "Set selling steps is now frozen!");
        sellingStep = Step(_step);
    }

    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if(sellingStep < Step.Revealed) {
            return notRevealedURI;
        }
        
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));

    }

    // **********************************************************************************
    // *********** merkle tree functions
    // **********************************************************************************
    function isWhiteListed(address _account, uint256 _amount,  bytes32[] calldata _proof) internal view returns(bool) {
        return _verify(leaf(_account, _amount), _proof);
    }

    function leaf(address _account, uint256 _amount) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account,_amount));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    // **********************************************************************************
    // *********** settings can ONLY be changed before the sale start time 
    // **********************************************************************************

    function setSaleStartTime(uint _saleStartTime) external onlyOwner {
        require(currentTime() < saleStartTime,"Sale has already started");
        saleStartTime = _saleStartTime;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(currentTime() < saleStartTime,"Sale is already started");
        merkleRoot = _merkleRoot;
    }


    function setSupply(uint _maxSupply, uint _maxWhitelist, uint _maxPublic, uint _maxGift) external onlyOwner {
        require(currentTime() < saleStartTime,"Sale is already started");
        require(_maxSupply == _maxWhitelist + _maxPublic + _maxGift,"Wrong supply count" );
        MAX_SUPPLY = _maxSupply;                // 2222
        MAX_WHITELIST = _maxWhitelist;          //  200
        MAX_PUBLIC = _maxPublic;                // 2000
        MAX_GIFT = _maxGift;                    //   22   (2222 = 200 + 2000 + 22)
    }
   
    function setMaxMintPerTransaction(uint _maxMintPerTransaction) external onlyOwner {
        require(currentTime() < saleStartTime,"Sale is already started");
        MAX_MINT_PER_TRANSACTION = _maxMintPerTransaction;
    }
   
    function setMaxNFTPerWalletWhitelist(uint _maxNFTperWhitelist) external onlyOwner {
        require(currentTime() < saleStartTime,"Sale is already started");
        MAX_NFT_PER_WALLET_WHITELIST = _maxNFTperWhitelist;
    }

    function setWhitelistDuration(uint _duration) external onlyOwner {
        require(currentTime() < saleStartTime,"Sale is already started");
        WHITELIST_DURATION = _duration;
    }

    function setWhitelistPrice(uint _wlPrice) external onlyOwner {
        require(currentTime() < saleStartTime,"Sale is already started");
        wlSalePrice = _wlPrice;
    }
   
    function setPublicPrice(uint _price) external onlyOwner {
        require(currentTime() < saleStartTime,"Sale is already started");
        publicSalePrice = _price;
    }

    // ********** end settings **********************************************************



    // ReleaseALL sale funds
    function releaseAll() external {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    receive() override external payable {
        revert('Only if you mint');
    }

}