// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";
import "./Football.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WorldCup is ERC721, Ownable {
    using Strings for uint;
    string private baseUri;
    bool public isPrize;
    uint private prizeTime;
    bool private isHandlingFeeWithdrawn;
    bytes32 private premintWhitelist; // whitelist merkle tree root hash
    bytes32 private superMintWhitelist;
    mapping(address => bool) public preminted;
    mapping(address => bool) public superMinted;
    mapping(address => uint[]) public holdingNft; // holding nft list by address
    mapping(address => address) public inviter; // inviter
    mapping(address => uint) public inviteCount; // invite count by address
    mapping (uint => bool) public exchanged; // exchanged nft
    mapping (uint => bool) private exchangedHost; // host exchanged
    uint private priceInWhitelist = 0.01 ether;
    uint private pool = 0 ether;
    bool public stopMint = false;
    uint public mintedCount = 0;
    uint public premintStartTime = 9999999999;
    uint public mintStartTime = 9999999999;
    uint public transferStartTime = 9999999999;
    uint constant maxTokenId = 10000;
    Football football;
    string public _contractURI = "";

    enum PrizeType {
        GOLD,
        SILVER,
        BRONZE,
        OTHERS,
        HOST
    }

    struct matchResult {
        bytes32 gold;
        bytes32 silver;
        bytes32 bronze;
        bytes32 others;
        bytes32 host;

        // prize that each nft can earn
        uint goldPrize;
        uint silverPrize;
        uint bronzePrize;
        uint othersPrize;
        uint hostPrize;
        uint handlingFee;
    }
    matchResult private result;
    
    /**
     * Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_, 
        string memory blindBoxBaseUri_, string memory contractURI_, address payable footballAddress_) ERC721(name_, symbol_) {
        _transferOwnership(msg.sender);
        baseUri = blindBoxBaseUri_;
        football = Football(footballAddress_);
        _contractURI = contractURI_;
    }

    /**
     * Support blind box.
     */
    function setBaseUri(string memory baseUri_) public onlyOwner {
        baseUri = baseUri_;
    }

    function tokenURI(uint tokenId_) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId_.toString()));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    /**
     * Stop mint stage.
     */
    function setStopMint(bool stopMint_) public onlyOwner {
        stopMint = stopMint_;
    }

    /**
     * Start prize exchange.
     */
    function setIsPrize(bool enable_) public onlyOwner {
        isPrize = enable_;
        if (enable_) {
            prizeTime = block.timestamp;
        }
    }

    /**
     * Batch mint code snippet.
     */
    function _batchMint(address addr_, uint amount_) private {
        uint totalPrice;
        uint totalAmount;
        uint i = 0;
        while (i < amount_) {
            uint price;
            uint amount;
            (price, amount) = _getTokenPriceAndFootballAmount(mintedCount+i+1);
            totalPrice += price;
            totalAmount += amount;
            i+=1;
        }
        require(msg.value == totalPrice, string.concat("value sent is invalid: ", Strings.toString(msg.value), " != ", Strings.toString(totalPrice)));
        
        // start mint
        i = 0;
        while (i < amount_) {
            uint tokenId = mintedCount + i + 1;
            _mint(msg.sender, tokenId);
            holdingNft[msg.sender].push(tokenId);
            i += 1;
        }
        football.mint(addr_, totalAmount);
        pool += msg.value;
        mintedCount += amount_;
    }

    /**
     * Buy blind box nft.
     */
    function mint(uint amount_, address inviter_) public payable {
        require(!stopMint, "minting is stopped now");
        require(block.timestamp > mintStartTime, "minting is not start now");
        require(msg.value != 0, "value sent equals to 0");

        _batchMint(msg.sender, amount_);

        // reward inviter
        if (inviter_ != address(0) && inviter[msg.sender] == address(0)) {
            inviter[msg.sender] = inviter_;
            inviteCount[inviter_] += 1;
            football.mint(inviter_, 1000);
        }
    }

    /**
     * Premint.
     */
    function premint(uint amount_, bytes32[] memory proof_) public payable {
        require(!stopMint, "minting is stopped now");
        require(block.timestamp > premintStartTime && block.timestamp < mintStartTime, "preminting stopped");
        require(!preminted[msg.sender], "you already used the whitelist");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof_, premintWhitelist, leaf), "you are not in whitelist");
        
        _batchMint(msg.sender, amount_);

        preminted[msg.sender] = true;
    }

    function superMint(bytes32[] memory proof_) public {
        require(!stopMint, "minting is stopped now");
        require(block.timestamp > premintStartTime, "super mint not start");
        require(!superMinted[msg.sender], "you already used the whitelist");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof_, superMintWhitelist, leaf), "you are not in whitelist");
        uint tokenId = mintedCount + 1;
        uint price;
        uint amount;
        (price, amount) = _getTokenPriceAndFootballAmount(tokenId);
        
        _mint(msg.sender, tokenId);
        football.mint(msg.sender, amount);
        holdingNft[msg.sender].push(tokenId);
        mintedCount += 1;
        
        superMinted[msg.sender] = true;
    }

    /**
     * Get owned NFT ID Array by address.
     */
    function _getOwnedNft(address user_, uint page_) private view returns (uint[100] memory) {
        uint[100] memory result_;
        uint start = (page_-1)*100;
        uint end = start+100;
        if (end > holdingNft[user_].length) {
            end = holdingNft[user_].length;
        }
        uint i = start;
        while (i < end) {
            result_[i-start] = holdingNft[user_][i];
            i += 1;
        }
        return result_;
    }
    
    function getOwnedNft(address addr_, uint page_) public view returns (uint[100] memory) {
        return _getOwnedNft(addr_, page_);
    }

    /**
     * Set mint configration.
     */
    function setMint(bytes32 premintWhitelist_,  bytes32 superMintWhitelist_, uint premintStartTime_, 
                        uint mintStartTime_, uint transferStartTime_) public onlyOwner {
        premintWhitelist = premintWhitelist_;
        superMintWhitelist = superMintWhitelist_;
        premintStartTime = premintStartTime_;
        mintStartTime = mintStartTime_;
        transferStartTime = transferStartTime_;
    }

    /**
     * Get price by a specific tokenId.
     */
    function getTokenIdPriceAndFootballAmount(uint tokenId_) public pure returns (uint, uint) {
        return _getTokenPriceAndFootballAmount(tokenId_);
    }

    function _getTokenPriceAndFootballAmount(uint tokenId_) pure internal returns (uint, uint) {
        require(tokenId_ <= maxTokenId, "token id must be less than 10000");
        uint price = 0;
        uint tokenAmount = 0;
        if (tokenId_ <= 1000) {
            price = 0.015 ether;
            tokenAmount = 10000;
        } else if (tokenId_ <= 5000) {
            price = 0.01 ether + 0.01 ether * ((tokenId_-1) / 1000);
            tokenAmount = 10000 + 1000 * ((tokenId_-1) / 1000);
        } else if (tokenId_ <= 10000) {
            price = 0.06 ether + 0.01 ether * ((tokenId_-5001) / 500);
            tokenAmount = 15000 + 1000 * ((tokenId_-5001) / 500);
        } else {
            // protect
            price = 9999 ether;
            tokenAmount = 0;
        }
        return (price, tokenAmount);
    }

    /**
     * Set worldcup match result.
     */
    function setMatchResult(bytes32[5] memory result_, uint[5] memory prizeNftCount_) public onlyOwner {
        result.gold = result_[0];
        result.silver = result_[1];
        result.bronze = result_[2];
        result.others = result_[3];
        result.host = result_[4];
        result.goldPrize = pool / 100 * 30 / prizeNftCount_[0];
        result.silverPrize = pool / 100 * 20 / prizeNftCount_[1];
        result.bronzePrize = pool / 100 * 10 / prizeNftCount_[2];
        result.othersPrize = pool / 100 * 15 / prizeNftCount_[3];
        result.hostPrize = pool / 100 * 5 / prizeNftCount_[4];
        result.handlingFee = pool / 100 * 20;
    }

    /**
     * Withdraw the rest balance in contract.
     */
    function withdrawRestBalance(address payable to_) public onlyOwner{
        require(isPrize == true, "no lottery yet");
        // We can withdraw the rest balance 7 days after the lottery
        require((block.timestamp - prizeTime) > 604800, "can not withdraw now");
        to_.transfer(address(this).balance);
    }

    /**
     * Withdraw 20% of the pool (handling fee)
     */
    function withdrawHandlingFee(address payable to_) public onlyOwner{
        require(isPrize, "no lottery yet");
        require(isHandlingFeeWithdrawn == false, "you already withdrew");
        isHandlingFeeWithdrawn = true;
        to_.transfer(result.handlingFee);
    }

    /**
     * Get prize by prize type.
     */
    function getPrize() public view returns (uint[5] memory) {
        return [result.goldPrize, result.silverPrize, result.bronzePrize, result.othersPrize, result.hostPrize];
    }


    /**
     * Batch exchange prize.
     */
    function batchExchangePrize(uint[] memory tokenIdArray_,  PrizeType[] memory prizeTypeArray_, bytes32[][] memory proofArray_) public {
        uint i = 0;
        uint totalPrize_ = 0;
        while (i < tokenIdArray_.length) {
            if ((prizeTypeArray_[i] == PrizeType.HOST) && (exchangedHost[tokenIdArray_[i]] == false)) {
                exchangedHost[tokenIdArray_[i]] = true;
                totalPrize_ += getPrizeByTokenId(tokenIdArray_[i],  prizeTypeArray_[i], proofArray_[i]);
            } else if(exchanged[tokenIdArray_[i]] == false) {
                exchanged[tokenIdArray_[i]] = true;
                totalPrize_ += getPrizeByTokenId(tokenIdArray_[i],  prizeTypeArray_[i], proofArray_[i]);
            }
            i += 1;
        }
        require(totalPrize_ > 0, "you have no prize to exchange");
        payable(msg.sender).transfer(totalPrize_);
    }

    function getPrizeByTokenId(uint tokenId_, PrizeType prizeType_, bytes32[] memory proof_) private view returns (uint) {
        require(isPrize, "no lottery yet");
        require(ownerOf(tokenId_) == msg.sender, "nft doesn't belong to you");
        bytes32 leaf = keccak256(abi.encodePacked(Strings.toString(tokenId_)));
        bytes32 root_;
        uint prize_;
        if (prizeType_ == PrizeType.GOLD) {
            root_ = result.gold;
            prize_ = result.goldPrize;
        } else if (prizeType_ == PrizeType.SILVER) {
            root_ = result.silver;
            prize_ = result.silverPrize;
        } else if (prizeType_ == PrizeType.BRONZE) {
            root_ = result.bronze;
            prize_ = result.bronzePrize;
        } else if (prizeType_ == PrizeType.OTHERS) {
            root_ = result.others;
            prize_ = result.othersPrize;
        } else if (prizeType_ == PrizeType.HOST) {
            root_ = result.host;
            prize_ = result.hostPrize;
        } else {
            revert("invalid prize type");
        }
        require(MerkleProof.verify(proof_, root_, leaf), "invalid prize");
        return prize_;
    }

    /*
    ** Only can transfer after `transferStartTime` by overwriting `_transfer` function
    */
    function _transfer(
        address from,
        address to,
        uint tokenId
    ) internal virtual override {
        require(block.timestamp > transferStartTime, "can not transfer yet");
        super._transfer(from, to, tokenId);

        // Remove nft owned by `from`
        for (uint i = 0; i < holdingNft[from].length; i++) {
            if (holdingNft[from][i] == tokenId) {
                delete holdingNft[from][i];
                break;
            }
        }

        // Add nft owned by `to`
        holdingNft[to].push(tokenId);
    }

    function _mint(address to, uint tokenId) internal override {
        require(tokenId <= maxTokenId);
        super._mint(to, tokenId);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}