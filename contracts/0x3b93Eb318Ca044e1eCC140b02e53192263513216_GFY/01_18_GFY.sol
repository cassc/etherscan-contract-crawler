// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";
import "./extensions/ERC721AQueryable.sol";

contract GFY is Ownable, ERC721A, ERC721AQueryable, PaymentSplitter {

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
    uint public MAX_SUPPLY = 5555;
    uint public MAX_GIFT = 55;

    uint public MAX_NFT_PER_WALLET = 1;

    uint public WHITELIST_DURATION = 1440 minutes;

    uint public wlSalePrice = 0 ether;
    uint public publicSalePrice = 0 ether;

    uint public saleStartTime = 1664304161; 

    //whitelist public
    bytes32 public merkleRoot;
    

    //URI of the NFTs when revealed
    string public baseURI;

    //URI of the NFTs when not revealed
    string public notRevealedURI;

    //keep track of minted nft
    mapping(address => uint) public amountNFTsperWallet;

    //keep track of claim list for whitelist (if we set max nft per wallet more than 1)
    mapping(address => bool) public hasAlreadyClaimed;

    //team share length
    uint private teamLength;

    // **********************************************************************************
    // *********** CONSTRUCTOR 
    // **********************************************************************************

    constructor(address[] memory _team, uint[] memory _teamShares, bytes32 _merkleRoot, string memory _notRevealedURI, uint _startTime) ERC721A("GFY", "GFY") PaymentSplitter(_team, _teamShares) {
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

        // check times after startime and before starttime + whitelist duration
        require(currentTime() >= saleStartTime, "Whitelist mint has not started yet");
        require(currentTime() <= saleStartTime + WHITELIST_DURATION, "Whitelist Sale is finished");
        require(sellingStep == Step.Sale, "Whitelist mint is not activated");
        require(isWhiteListed(msg.sender, 1, _proof), "You are not whitelisted");
        require(hasAlreadyClaimed[msg.sender] == false, "You have already used your whitelist");
        require(amountNFTsperWallet[msg.sender] + _quantity <= MAX_NFT_PER_WALLET, "You can only get X NFTs");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max Supply exceeded (whitelist)");

        // are you sending enough eth -  0 for free mint
        require(msg.value >= price * _quantity, "Not enought funds");

        // if we reach the max minted here, automatically switch to the End Step (team and gift mint)
        if (totalSupply() + _quantity == MAX_SUPPLY) {
            sellingStep = Step.End;
        }

        // mint
        hasAlreadyClaimed[msg.sender] = true;
        amountNFTsperWallet[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    // **********************************************************************************
    // *********** PUBLIC MINT  same as whitelist , except we don't check the merketree whitelist
    // **********************************************************************************

    function publicSaleMint(address _account, uint _quantity) external payable callerIsUser {
        uint price = publicSalePrice;

        // check times after the whitelist phase only
        require(currentTime() > saleStartTime + WHITELIST_DURATION, "Public mint has not started yet");
        require(sellingStep == Step.Sale, "Public mint is not activated");
        require(amountNFTsperWallet[msg.sender] + _quantity <= MAX_NFT_PER_WALLET, "You can only get X NFTs");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max Public supply exceeded");   

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