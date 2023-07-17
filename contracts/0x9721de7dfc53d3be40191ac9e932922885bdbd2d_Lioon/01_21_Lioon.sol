// SPDX-License-Identifier: MIT LICENSE

import "hardhat/console.sol";

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ILioon.sol";
import "./ISafari.sol";
import "./STRIPES.sol";


contract Lioon is ILioon, ERC721Enumerable, Ownable, Pausable {

    // mint price
    uint256 public constant MINT_PRICE = .04 ether;
    uint256 public constant WL_MINT_PRICE = .035 ether;
    // max number of tokens that can be minted - 50000 in production
    uint256 public immutable MAX_TOKENS;
    // number of tokens that can be claimed for free - 20% of MAX_TOKENS
    uint256 public PAID_TOKENS;
    // number of tokens have been minted so far
    uint16 public minted;

    // reference to the Safari for choosing random Lion thieves
    ISafari public safari;
    // reference to $STRIPES for burning on mint
    STRIPES public stripes;


    string public baseZebraURI;
    string public baseLionURI;

    //Data for Stats
    uint256 public numZebrasMinted = 0;
    uint256 public numLionsMinted = 0;
    uint256 public numStolen = 0;

    //For Whitelist
    mapping(address => uint256) public whiteList;

    //Keep track of data
    mapping(uint256 => TokenMetadata) public _idData;

    /** 
    * instantiates contract and rarity tables
    */
    constructor(address _stripes, uint256 _maxTokens) ERC721("Lion Game", 'LGAME') { 
        stripes = STRIPES(_stripes);
        MAX_TOKENS = _maxTokens;
        PAID_TOKENS = _maxTokens / 5;
    }

    /** EXTERNAL */

    /** 
    * mint a token - 90% Zebra, 10% Lions
    * The first 20% are free to claim, the remaining cost $STRIPES
    */
    function mint(uint256 amount, bool stake) external payable whenNotPaused {
        require(tx.origin == _msgSender(), "Only EOA");
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0 && amount <= 10, "Invalid mint amount");
        if (minted < PAID_TOKENS) {
            require(minted + amount <= PAID_TOKENS, "All tokens on-sale already sold");
            require(amount * MINT_PRICE == msg.value, "Invalid payment amount");
        } else {
            require(msg.value == 0);
        }

        uint256 totalStripesCost = 0;
        uint16[] memory tokenIds = stake ? new uint16[](amount) : new uint16[](0);
        uint256 seed;
        
        for (uint i = 0; i < amount; i++) {
            minted++;
            seed = random(minted);
            
            _idData[minted] = generate(minted, seed);

            address recipient = selectRecipient(seed);
            if(recipient != _msgSender()){
                numStolen++;
            }
            if (!stake || recipient != _msgSender()) {
                _mint(recipient, minted);
            } else {
                _mint(address(safari), minted);
                tokenIds[i] = minted;
            }
            totalStripesCost += mintCost(minted);
        }
        
        if (totalStripesCost > 0) stripes.burn(_msgSender(), totalStripesCost);
        if (stake) safari.addManyToSafariAndPack(_msgSender(), tokenIds);
    }

    function mintWhitelist(uint256 amount, bool stake) external payable whenNotPaused {
        require(tx.origin == _msgSender(), "Only EOA");
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0 && amount <= 3, "Invalid mint amount");
        require(whiteList[_msgSender()] >= amount, "Invalid Whitelist Amount");
        require(amount * WL_MINT_PRICE == msg.value, "Invalid payment amount");

        whiteList[_msgSender()] = whiteList[_msgSender()] - amount;

        uint16[] memory tokenIds = stake ? new uint16[](amount) : new uint16[](0);
        uint256 seed;

        for (uint i = 0; i < amount; i++) {
            minted++;
            seed = random(minted);
            
            _idData[minted] = generate(minted, seed);

            address recipient = _msgSender();
            if (!stake) {
                _mint(recipient, minted);
            } else {
                _mint(address(safari), minted);
                tokenIds[i] = minted;
            }
        }

        if (stake) safari.addManyToSafariAndPack(_msgSender(), tokenIds);
    }

    /** 
    * the first 20% are paid in ETH
    * the next 20% are 20000 $STRIPES
    * the next 40% are 40000 $STRIPES
    * the final 20% are 80000 $STRIPES
    * @param tokenId the ID to check the cost of to mint
    * @return the cost of the given token ID
    */
    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= PAID_TOKENS) return 0;
        if (tokenId <= MAX_TOKENS * 2 / 5) return 20000 ether;
        if (tokenId <= MAX_TOKENS * 4 / 5) return 40000 ether;
        return 80000 ether;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Hardcode the Safari's approval so that users don't have to waste gas approving
        if (_msgSender() != address(safari))
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /** INTERNAL */

    /**
    * generates traits for a specific token, checking to make sure it's unique
    * @param tokenId the id of the token to generate traits for
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t - a struct of traits for the given token ID
    */
    function generate(uint256 tokenId, uint256 seed) internal returns (TokenMetadata memory t) {
        TokenMetadata memory newData;

        uint256 random1 = random(seed);
        uint256 random2 = random(seed + 1);

        newData.isLion = (random1 % 10 == 0);

        if(newData.isLion){
            numLionsMinted++;
        }
        else{
            numZebrasMinted++;
        }

        newData.alpha = uint8(5 + (random2 % 4));
        
        return newData;
    }

    /**
    * the first 20% (ETH purchases) go to the minter
    * the remaining 80% have a 10% chance to be given to a random staked lion
    * @param seed a random value to select a recipient from
    * @return the address of the recipient (either the minter or the Lion thief's owner)
    */
    function selectRecipient(uint256 seed) internal view returns (address) {
        if (minted <= PAID_TOKENS || ((seed >> 245) % 10) != 0) return _msgSender(); // top 10 bits haven't been used
        address thief = safari.randomLionOwner(seed >> 144); // 144 bits reserved for trait selection
        if (thief == address(0x0)) return _msgSender();
        return thief;
    }

    /**
    * generates a pseudorandom number
    * @param seed a value ensure different outcomes for different sources in the same block
    * @return a pseudorandom value
    */
    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
        tx.origin,
        blockhash(block.number - 1),
        block.timestamp,
        seed
        )));
    }

    /** READ */
    function getPaidTokens() external view override returns (uint256) {
        return PAID_TOKENS;
    }

    function getTokenData(uint256 tokenId) external view returns (TokenMetadata memory) {
        return _idData[tokenId];
    }

    function getStats() external view returns(uint256, uint256, uint256){
        return(numZebrasMinted, numLionsMinted, numStolen);
    }

    /** ADMIN */

    /**
    * called after deployment so that the contract can get random lion thieves
    * @param _safari the address of the Safari
    */
    function setSafari(address _safari) external onlyOwner {
        safari = ISafari(_safari);
    }

    function setUris(string calldata _zebraUri, string calldata _lionUri) external onlyOwner {
        baseZebraURI = _zebraUri;
        baseLionURI = _lionUri;
    }

    function addToWhitelist(address[] memory toWhitelist) external onlyOwner {
        for(uint256 i = 0; i < toWhitelist.length; i++){
            address idToWhitelist = toWhitelist[i];
            whiteList[idToWhitelist] = 3;
        }
    }

    /**
    * allows owner to withdraw funds from minting
    */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
    * updates the number of tokens for sale
    */
    function setPaidTokens(uint256 _paidTokens) external onlyOwner {
        PAID_TOKENS = _paidTokens;
    }

    /**
    * enables owner to pause / unpause minting
    */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /** RENDER */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(_idData[tokenId].isLion)
        {
            return string(abi.encodePacked(baseLionURI, Strings.toString(tokenId)));
        }
        else
        {
            return string(abi.encodePacked(baseZebraURI, Strings.toString(tokenId)));
        }
    }
}