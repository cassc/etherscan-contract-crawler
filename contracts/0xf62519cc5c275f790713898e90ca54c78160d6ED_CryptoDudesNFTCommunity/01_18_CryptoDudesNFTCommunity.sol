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

contract CryptoDudesNFTCommunity is Ownable, ERC721A, ERC721AQueryable, PaymentSplitter {

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
    uint public MAX_WHITELISTCLAIM = 605;
    uint public MAX_PUBLIC = 1595;
    uint public MAX_GIFT = 22;

    uint public MAX_NFT_PER_WALLET = 2;

    uint public WHITELIST_DURATION = 720 minutes;

    uint public wlSalePrice = 0 ether;
    uint public publicSalePrice = 0 ether;

    // excluding gif and claim (we count here the whitelist mint + public mint)
    // so we are sure to keep in reserve the claimable dudes
    // max reallyMinted = max_public
    uint256 internal reallyMinted = 0;

    uint public claimStartTime = 1657125000;     // jul 6 18h30
    uint public saleStartTime = 1656531000;

    //claimable nft from first contract
    bytes32 public merkleRootClaimList;
    //whitelist public
    bytes32 public merkleRoot;
    

    //URI of the NFTs when revealed
    string public baseURI;

    //URI of the NFTs when not revealed
    string public notRevealedURI;

    //keep track of minted nft during public
    mapping(address => uint) public amountNFTsperWalletSale;

    //keep track of claim list
    mapping(address => bool) public hasAlreadyClaimed;

    //team share length
    uint private teamLength;

    // **********************************************************************************
    // *********** CONSTRUCTOR 
    // **********************************************************************************

    constructor(address[] memory _team, uint[] memory _teamShares, bytes32 _merkleRootClaimList, bytes32 _merkleRoot, string memory _notRevealedURI, uint _startTime, uint _claimStartTime) ERC721A("CryptoDudes", "CRYPTODUDES") PaymentSplitter(_team, _teamShares) {
        merkleRootClaimList = _merkleRootClaimList;
        merkleRoot = _merkleRoot;
        notRevealedURI = _notRevealedURI;
        teamLength = _team.length;
        saleStartTime = _startTime;
        claimStartTime = _claimStartTime;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }


    // **********************************************************************************
    // *********** CLAIM NFTs from old contrat
    // **********************************************************************************

    function ClaimMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        uint price = wlSalePrice;
      
        // check times , no, can be done anytime after the gift has been done
        require(currentTime() >= claimStartTime, "Claim mint has not started yet");
        require(sellingStep == Step.Sale, "Claim is not activated");
        require(hasAlreadyClaimed[msg.sender] == false, "You have already claimed your NFTs");
        require(isWhiteListedClaimList(msg.sender, _quantity, _proof), "You are not whitelisted for the claim list");

        // are you sending enough eth - should be set to 0 for the claim
        require(msg.value >= price * _quantity, "Not enought funds");

        // mint 
        hasAlreadyClaimed[msg.sender] = true;
        _safeMint(_account, _quantity);
    }

    // **********************************************************************************
    // *********** WHITE LIST MINT - PUBLIC MINT
    // **********************************************************************************

    function whitelistMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        uint price = wlSalePrice;

        // check times after startime and before starttime + whitelist duration
        require(currentTime() >= saleStartTime, "Whitelist mint has not started yet");
        require(currentTime() <= saleStartTime + WHITELIST_DURATION, "Whitelist Sale is finished");

        // are we in step sale, whitelisted, and trying to mint only MAX_NFT_PER_WALLET_WHITELIST
        require(sellingStep == Step.Sale, "Whitelist mint is not activated");
        //forced to 1, but we can mint any quantity if needed
        require(isWhiteListed(msg.sender, 1, _proof), "You are not whitelisted");
        require(amountNFTsperWalletSale[msg.sender] + _quantity <= MAX_NFT_PER_WALLET, "You can only get 2 NFTs during the free mint");

        // allow mint up to MAX_SUPPLY even during whitelist if list is big enough
        require(reallyMinted + _quantity <= MAX_PUBLIC, "Max Public supply exceeded");

        // are you sending enough eth - should be set to 0 for free mint
        require(msg.value >= price * _quantity, "Not enought funds");

        // if we reach the max minted here, automatically switch to the End Step (team and gift mint)
        if (totalSupply() + _quantity == MAX_SUPPLY) {
            sellingStep = Step.End;
        }

        // mint
        reallyMinted += _quantity;
        amountNFTsperWalletSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    // **********************************************************************************
    // *********** PUBLIC MINT  same as whitelist , except we don't check the merketree whitelist
    // **********************************************************************************

    function publicSaleMint(address _account, uint _quantity) external payable callerIsUser {
        uint price = publicSalePrice;

        // check times after the whitelist phase only
        require(currentTime() > saleStartTime + WHITELIST_DURATION, "Public mint has not started yet");

        // are we in step sale, and trying to mint too many nft
        require(sellingStep == Step.Sale, "Public mint is not activated");
        require(amountNFTsperWalletSale[msg.sender] + _quantity <= MAX_NFT_PER_WALLET, "You can only get 2 NFTs during the free mint");
        

        // allow mint up to MAX_WHITELIST + MAX_PUBLIC during public mint
        require(reallyMinted + _quantity <= MAX_PUBLIC, "Max Public supply exceeded");   

        // are you sending enough eth
        require(msg.value >= price * _quantity, "Not enought funds");

        // if we reach the max minted here, automatically switch to the End Step (team and gift mint)
        if (totalSupply() + _quantity == MAX_SUPPLY) {
            sellingStep = Step.End;
        }

        // mint
        reallyMinted += _quantity;
        amountNFTsperWalletSale[msg.sender] += _quantity;
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

    function leaf(address _account, uint256 _amount) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account,_amount));
    }

    //-- claim
    function isWhiteListedClaimList(address _account, uint256 _amount,  bytes32[] calldata _proof) internal view returns(bool) {
        return _verifyClaim(leaf(_account, _amount), _proof);
    }

    function _verifyClaim(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, merkleRootClaimList, _leaf);
    }

    // --- whitelist
    function isWhiteListed(address _account, uint256 _amount,  bytes32[] calldata _proof) internal view returns(bool) {
        return _verify(leaf(_account, _amount), _proof);
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

     function setClaimStartTime(uint _claimStartTime) external onlyOwner {
        require(currentTime() < claimStartTime,"Sale has already started");
        claimStartTime = _claimStartTime;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMerkleRootClaim(bytes32 _merkleRootClaimList) external onlyOwner {     
        merkleRootClaimList = _merkleRootClaimList;
    }


    function setSupply(uint _maxSupply, uint _maxWhitelist, uint _maxPublic, uint _maxGift) external onlyOwner {
        require(_maxSupply == _maxWhitelist + _maxPublic + _maxGift,"Wrong supply count" );
        MAX_SUPPLY = _maxSupply;                // 2222
        MAX_WHITELISTCLAIM = _maxWhitelist;     //  570
        MAX_PUBLIC = _maxPublic;                // 1630
        MAX_GIFT = _maxGift;                    //   22 
    }
   
    function setMaxMintPerWallet(uint _maxMintPerWallet) external onlyOwner {
        MAX_NFT_PER_WALLET = _maxMintPerWallet;
    }
   
    function setWhitelistDuration(uint _duration) external onlyOwner {
        WHITELIST_DURATION = _duration;
    }

    function setWhitelistPrice(uint _wlPrice) external onlyOwner {
        wlSalePrice = _wlPrice;
    }
   
    function setPublicPrice(uint _price) external onlyOwner {
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