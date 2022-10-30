// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";
import "./extensions/ERC721AQueryable.sol";

import "./CryptoDudesNFTCommunity.sol";
import "./CryptoDudesGlassNFT.sol";

contract MutantDudes is Ownable, ERC721A, ERC721AQueryable, PaymentSplitter {

    using Strings for uint;

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
    uint public MAX_GIFT = 22;

    //during public mint, max mint per wallet
    uint public MAX_NFT_PER_WALLET = 1;

    uint public DUDES_DURATION = 120 minutes;
    uint public WHITELIST_DURATION = 120 minutes;

    uint public wlSalePrice = 0 ether;
    uint public publicSalePrice = 0 ether;

    uint public saleStartTime = 1667235600;  //31 oct 16 pm utc

    //whitelist public
    bytes32 public merkleRoot;
    

    //URI of the NFTs when revealed
    string public baseURI;

    //URI of the NFTs when not revealed
    string public notRevealedURI;

    //keep track of minted nft during public mint
    mapping(address => uint) public amountNFTsperWallet;

    //keep track of claim list for whitelist
    mapping(address => bool) public hasAlreadyClaimedWL;
    
    //CryptoDudes NFT address
    address public cryptodudesNFTAddress;

    //White Russian NFT address
    address public whiterussianNFTAddress;

    //team share length
    uint private teamLength;

    //used Dudes & WR
    mapping(uint => bool) public cryptodudesUsed;
    mapping(uint => bool) public WRUsed;
    

    // **********************************************************************************
    // *********** CONSTRUCTOR 
    // **********************************************************************************

    constructor(address[] memory _team, uint[] memory _teamShares, bytes32 _merkleRoot, string memory _notRevealedURI, uint _startTime, address _cryptodudesNFTAddress, address _whiterussianNFTAddress) ERC721A("MutantDudes", "MUTANTDUDES") PaymentSplitter(_team, _teamShares) {
        merkleRoot = _merkleRoot;
        notRevealedURI = _notRevealedURI;
        teamLength = _team.length;
        saleStartTime = _startTime;
        cryptodudesNFTAddress = _cryptodudesNFTAddress;
        whiterussianNFTAddress = _whiterussianNFTAddress;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // **********************************************************************************
    // *********** DUDES + WR MINT
    // **********************************************************************************

    function min(uint a, uint b) public pure returns (uint) {
        return a <= b ? a : b;
    }

    function DudesWRMint(address _account, uint[] calldata tokenIdsDudes, address _nftContractDudes, uint[] calldata tokenIdsWR, address _nftContractWR) external payable callerIsUser {
        uint tokenId;
        uint quantity = 0;
        uint nbCryptoDudes = 0;
        uint nbWR = 0;
        CryptoDudesNFTCommunity cryptodudes;
        CryptoDudesGlassNFT whiterussian;

        // check times after startime and before starttime + whitelist duration
        require(currentTime() >= saleStartTime, "Mint has not started yet");
        require(currentTime() <= saleStartTime + DUDES_DURATION + WHITELIST_DURATION, "Whitelist finished");
        require(sellingStep == Step.Sale, "MintWR is not activated");
        require(tokenIdsDudes.length > 0, "No token Ids provided");
        require(tokenIdsWR.length > 0, "No token Ids provided");
        
        require(_nftContractDudes == cryptodudesNFTAddress, "Bad D");
        require(_nftContractWR == whiterussianNFTAddress, "Bad WR");

        //check max amount to mint Dudes
        cryptodudes = CryptoDudesNFTCommunity(payable(_nftContractDudes));
        for(uint i = 0; i < tokenIdsDudes.length ; i++){
            tokenId = tokenIdsDudes[i];
            if ( cryptodudes.ownerOf(tokenId) == msg.sender && cryptodudesUsed[tokenId] == false) {
                nbCryptoDudes += 1;
                cryptodudesUsed[tokenId] = true;
            }
        }

        //check max amount to mint WR
        whiterussian = CryptoDudesGlassNFT(payable(_nftContractWR));
        for(uint i = 0; i < tokenIdsWR.length ; i++){
            tokenId = tokenIdsWR[i];
            if ( whiterussian.ownerOf(tokenId) == msg.sender && WRUsed[tokenId] == false) {
                nbWR += 1;
                WRUsed[tokenId] = true;
            }
        }

        quantity = min(nbCryptoDudes,nbWR);

        require (quantity > 0, "No more !");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max Supply exceeded (WR)");

        
        // if we reach the max minted here, automatically switch to the End Step (team and gift mint)
        // no overallocation, so we don't try to lower the quantity if needed
        if (totalSupply() + quantity == MAX_SUPPLY) {
            sellingStep = Step.End;
        }

        // mint
        _safeMint(_account, quantity);
    }

    // **********************************************************************************
    // *********** WHITE LIST MINT
    // **********************************************************************************

    function whitelistMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        uint price = wlSalePrice;

        // check times after startime and before starttime + whitelist duration
        require(currentTime() >= saleStartTime + DUDES_DURATION, "Mint has not started yet");
        require(currentTime() <= saleStartTime + DUDES_DURATION + WHITELIST_DURATION, "Whitelist finished");
        require(sellingStep == Step.Sale, "WL mint is not activated");
        require(isWhiteListed(msg.sender, 1, _proof), "You are not whitelisted");
        require(hasAlreadyClaimedWL[msg.sender] == false, "Whitelist already used");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max Supply exceeded (WL)");

        // are you sending enough eth -  0 for free mint
        require(msg.value >= price * _quantity, "Not enought funds");

        // if we reach the max minted here, automatically switch to the End Step (team and gift mint)
        if (totalSupply() + _quantity == MAX_SUPPLY) {
            sellingStep = Step.End;
        }

        // mint
        hasAlreadyClaimedWL[msg.sender] = true;
        _safeMint(_account, _quantity);
    }

    // **********************************************************************************
    // *********** PUBLIC MINT 
    // **********************************************************************************

    function publicSaleMint(address _account, uint _quantity, bytes32[] calldata _proof, address _merkleAddr) external payable callerIsUser {
        uint price = publicSalePrice;

        // check times after the whitelist phase only
        require(currentTime() > saleStartTime + DUDES_DURATION + WHITELIST_DURATION, "Mint has not started yet");
        require(sellingStep == Step.Sale, "Mint activated");
        require(isWhiteListed(_merkleAddr, 1, _proof), "Need a proof");
        require(amountNFTsperWallet[msg.sender] + _quantity <= MAX_NFT_PER_WALLET, "You can only get X NFTs");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");   

        // are you sending enough eth
        require(msg.value >= price * _quantity, "Not enought funds");

        // if we reach the max minted here, automatically switch to the End Step (team and gift mint)
        if (totalSupply() + _quantity == MAX_SUPPLY) {
            sellingStep = Step.End;
        }

        // mint
        amountNFTsperWallet[msg.sender] += _quantity;
        _safeMint(_account, _quantity); 
    }

    // **********************************************************************************
    // *********** TEAM AND GIFTS MINT 
    // **********************************************************************************

    function gift(address _to, uint _quantity) external onlyOwner {
        require(sellingStep == Step.Gift, "Gift phase only");
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
        require(sellingStep == Step.End, "revealed URI after the sales");
        sellingStep = Step.Revealed;
        baseURI = _baseURI;
    }

    function currentTime() internal view returns(uint) {
        return block.timestamp;
    }

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


    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setSupply(uint _maxSupply, uint _maxGift) external onlyOwner {
        MAX_SUPPLY = _maxSupply;                // 5555
        MAX_GIFT = _maxGift;                    //   55 
    }
   
    function setMaxMintPerWallet(uint _maxMintPerWallet) external onlyOwner {
        MAX_NFT_PER_WALLET = _maxMintPerWallet;
    }
   
    function setWhitelistDuration(uint _duration) external onlyOwner {
        WHITELIST_DURATION = _duration;
    }

    function setDudesDuration(uint _duration) external onlyOwner {
        DUDES_DURATION = _duration;
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