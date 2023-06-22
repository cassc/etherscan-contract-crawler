// contracts/StakerNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./merkle/MerkleDistributor.sol";

contract SniperNFT is ERC721Enumerable, Ownable {
    // bool
    bool public _isMintingLive = false;
    bool public _isAllowListRequired = true;

    // addresses
    address _owner;
    address private feeReceiver;

    // integers
    uint256 public _totalSupply = 0;
    uint256 public MAX_SUPPLY = 999;
    uint256 public GIFT_SNIPER_SUPPLY = 0;
    uint256 public SILVER_SNIPER_SUPPLY = 0;
    uint256 public GOLD_SNIPER_SUPPLY = 0;

    uint256 public MAX_GIFT_SNIPERS = 30;
    uint256 public MAX_SILVER_SNIPERS = 900;
    uint256 public MAX_GOLD_SNIPERS = 69;

    uint256 public SILVER_SNIPER_PRICE = .223 ether;
    uint256 public GOLD_SNIPER_PRICE = .696 ether;

    uint256 private feePaid = 0;

    // bytes
    bytes32 merkleRoot;

    string private _tokenSilverURI = 'ipfs://bafybeieirufnrbiuk7mcngbpijqfe6fuiyz2dcaeo7bxmoleuylbywnoti/metadata/silver_sniper';
    string private _tokenGoldURI = 'ipfs://bafybeieirufnrbiuk7mcngbpijqfe6fuiyz2dcaeo7bxmoleuylbywnoti/metadata/gold_sniper';

    //Mappings
    mapping(uint256 => bool) private _tokenIsGold;
    mapping(address => bool) private _tokenClaimed;

    constructor(bytes32 _merkleRoot) ERC721("onlySnipers", "ONLYSNIPERS") {
        _owner = msg.sender;
        feeReceiver = msg.sender;
        merkleRoot = _merkleRoot;
    }

    function setMintingLive(bool isLive) external onlyOwner {
        require(_isMintingLive != isLive, "Value must be different");
        _isMintingLive = isLive;
    }

    function setAllowListRequired(bool isRequired) external onlyOwner {
        require(_isAllowListRequired != isRequired, "Value must be different");
        _isAllowListRequired = isRequired;
    }

    function addFeePaid(uint256 _feePaid) external {
        require(msg.sender == feeReceiver, "Only fee receiver can call this function");
        feePaid += _feePaid;
    }

    /*
    MINTING FUNCTIONS
    */

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal(bool isGold) internal returns(uint256 tokenId) {
        if(isGold) {
            tokenId = 1 + GOLD_SNIPER_SUPPLY;
            _tokenIsGold[tokenId] = true;
            GOLD_SNIPER_SUPPLY += 1;
        } else {
            tokenId = 1 + MAX_GIFT_SNIPERS + MAX_GOLD_SNIPERS + SILVER_SNIPER_SUPPLY;
            SILVER_SNIPER_SUPPLY += 1;
        }
        _totalSupply += 1;

        _mint(msg.sender, tokenId);
        return tokenId;
    }

    /**
     * @dev Public mint function
     */
    function mint(bool isGold, bytes32[] calldata proof) payable external returns(uint256 tokenId) {
        require(_isMintingLive, "Minting has not started");
        require(
            _totalSupply < MAX_SUPPLY,
            "Tokens have all been minted"
        );

        require(
            !_tokenClaimed[msg.sender],
            "This address already minted"
        );
        
        // check whitelist
        if(_isAllowListRequired){
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(proof, merkleRoot, leaf), 'Proof is invalid');
        }

        if(isGold){
            require(GOLD_SNIPER_SUPPLY < MAX_GOLD_SNIPERS, "All gold snipers have been minted");
            require(msg.value == GOLD_SNIPER_PRICE, "Wrong amount of ether");
        } else {
            require(SILVER_SNIPER_SUPPLY < MAX_SILVER_SNIPERS, "All silver snipers have been minted");
            require(msg.value == SILVER_SNIPER_PRICE, "Wrong amount of ether");
        }

        tokenId = mintInternal(isGold);
        _tokenClaimed[msg.sender] = true;
        return tokenId;
    }

    /**
     * @dev Mint gift tokens for the contract owner
     */
    function mintGifts(uint256 _times) external onlyOwner {
        require(
            GIFT_SNIPER_SUPPLY + _times <= MAX_GIFT_SNIPERS,
            "Must mint fewer than the maximum number of gifted tokens"
        );

        for(uint256 i=0; i<_times; i++) {
            uint256 tokenId = 1 + MAX_GOLD_SNIPERS + GIFT_SNIPER_SUPPLY;
            GIFT_SNIPER_SUPPLY += 1;
            _totalSupply += 1;

            _mint(msg.sender, tokenId);    
        }
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');

        return _tokenIsGold[tokenId] ?
            _tokenGoldURI :
            _tokenSilverURI ;
    }

    function getSupply()
    public
    view
    returns (
        uint256 maxSnipers,
        uint256 maxGoldSnipers,
        uint256 mintedSnipers,
        uint256 mintedGoldSnipers
    ) {
        return (
            MAX_SILVER_SNIPERS,
            MAX_GOLD_SNIPERS,
            SILVER_SNIPER_SUPPLY,
            GOLD_SNIPER_SUPPLY
        );
    }

    function getClaimed(address _address) public view returns (bool hasClaimed) {
        return (_tokenClaimed[_address]);
    }

    function addressIsWhitelisted(address _address, bytes32[] calldata proof) public view returns (bool isWhitelisted) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        isWhitelisted = MerkleProof.verify(proof, merkleRoot, leaf);
        return isWhitelisted;
    }

    /**
     * @dev Withdraw ETH to owner
     */
    function withdraw() public onlyOwner {
        require(feePaid >= 2 ether, "Must pay fee first");
        uint256 amount = address(this).balance;

        payable(msg.sender).transfer(amount);
    }

    /**
     * @dev Withdraw fee
     */
    function withdrawFee() public onlyOwner {
        require(feePaid < 2 ether, "Fee already paid");
        uint256 feeOwed = 2 ether - feePaid;

        uint256 balance = address(this).balance;
        uint256 amount = Math.min(balance, feeOwed);

        payable(feeReceiver).transfer(amount);
        feePaid += amount;
    }
}