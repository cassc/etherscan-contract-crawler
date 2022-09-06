// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.4;

/*

NFTKollabs

Twitter: https://twitter.com/NFTKollabs
Website: https://nftkollabs.com
Instagram: https://www.instagram.com/NFTKollabs

*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTKSC is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public nftSaleStartTime;
    bool public nftsOnSale = true;
    bool public allowNewBeneficiary = true;

    enum NftList{
        NFT_LIST_1,
        NFT_LIST_2, 
        NFT_LIST_3, 
        NFT_LIST_4, 
        NFT_LIST_5, 
        NFT_LIST_6, 
        NFT_LIST_7, 
        NFT_LIST_8, 
        NFT_LIST_9, 
        NFT_LIST_10,
        NFT_LIST_11,
        NFT_LIST_12,
        NFT_LIST_13,
        NFT_LIST_14,
        NFT_LIST_15,
        NFT_LIST_16,
        NFT_LIST_17,
        NFT_LIST_18,
        NFT_LIST_19,
        NFT_LIST_20 
    }

    uint256 public constant NFT_LIST_SALE_START = 1; 
    uint256 public constant NFTS_PER_LIST = 500;

    uint256 public constant TOTAL_SUPPLY = 9999;
    uint256 public constant EACH_SALE_PHASE_TOTAL_SUPPLY = 3333; 

    uint256 public constant FIRST_NFT_SALE_PHASE_PRICE = 0.133 ether; 
    uint256 public constant SECOND_NFT_SALE_PHASE_PRICE = 0.166 ether; 
    uint256 public constant THIRD_NFT_SALE_PHASE_PRICE = 0.199 ether; 

    uint256 public constant MAX_NFTS_PER_TX = 100;   
    uint256 public constant MAX_NFTS_PER_WALLET = 100;   

    mapping(address => uint256) private _totalClaimed;

    mapping(NftList => string) private _revealNFTS_LIST_URLs;

    string public beforeRevealURI; 
    address private _beneficiary;

    event SetNFTsOnSale(bool onsale);

    constructor(string memory beforeReveal, address beneficiary, uint256 saleStartTime) ERC721("NFTKSC", "NFTKSC") {
        beforeRevealURI = beforeReveal;
        _beneficiary = beneficiary;
        nftSaleStartTime = saleStartTime;
    }

    function setNftSaleStartTime(uint256 newNftSaleStartTime) external onlyOwner {
        nftSaleStartTime = newNftSaleStartTime;
    }

    function setNFTsOnSale(bool onsale) external onlyOwner {
        nftsOnSale = onsale;
        emit SetNFTsOnSale(onsale);
    }

    function revealNFTList(NftList nftList, string memory uri) external onlyOwner {
        _revealNFTS_LIST_URLs[nftList] = uri;
    }

    function setBeforeRevealURI(string memory newBeforeRevealUri) external onlyOwner {
       beforeRevealURI = newBeforeRevealUri;
    }

    function disallowNewBeneficiary() external onlyOwner {
        allowNewBeneficiary = false;
    }

    function setBeneficiary(address newBeneficiary) external onlyOwner {
        require(allowNewBeneficiary == true, "NEW_BENEFICIARY_NOT_ALLOWED");
        _beneficiary = newBeneficiary;
    }

    function currentNftSalePhasePrice() public view returns (uint256) {
        uint256 currentTotalSupply = totalSupply();
        if (currentTotalSupply < EACH_SALE_PHASE_TOTAL_SUPPLY) {
           return FIRST_NFT_SALE_PHASE_PRICE;
        } else if (currentTotalSupply < EACH_SALE_PHASE_TOTAL_SUPPLY * 2) {
            return SECOND_NFT_SALE_PHASE_PRICE;
        } else {
            return THIRD_NFT_SALE_PHASE_PRICE;
        }
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "NON_EXISTENT_TOKEN");

        NftList nftList; 

        if (tokenId >= NFT_LIST_SALE_START && tokenId <= NFTS_PER_LIST) { 
            nftList = NftList.NFT_LIST_1; 
        }
        else if (tokenId <= NFTS_PER_LIST * 2) { 
            nftList = NftList.NFT_LIST_2;
        } 
        else if (tokenId <= NFTS_PER_LIST * 3) { 
            nftList = NftList.NFT_LIST_3;
        } 
        else if (tokenId <= NFTS_PER_LIST * 4) { 
            nftList = NftList.NFT_LIST_4;
        }
        else if (tokenId <= NFTS_PER_LIST * 5) { 
            nftList = NftList.NFT_LIST_5;
        }
        else if (tokenId <= NFTS_PER_LIST * 6) { 
            nftList = NftList.NFT_LIST_6;
        }
        else if (tokenId <= NFTS_PER_LIST * 7) { 
            nftList = NftList.NFT_LIST_7;
        }
        else if (tokenId <= NFTS_PER_LIST * 8) { 
            nftList = NftList.NFT_LIST_8;
        }
        else if (tokenId <= NFTS_PER_LIST * 9) { 
            nftList = NftList.NFT_LIST_9;
        } 
        else if (tokenId <= NFTS_PER_LIST * 10) { 
            nftList = NftList.NFT_LIST_10;
        }
        else if (tokenId <= NFTS_PER_LIST * 11) { 
            nftList = NftList.NFT_LIST_11;
        }
        else if (tokenId <= NFTS_PER_LIST * 12) { 
            nftList = NftList.NFT_LIST_12;
        }
        else if (tokenId <= NFTS_PER_LIST * 13) { 
            nftList = NftList.NFT_LIST_13;
        }
        else if (tokenId <= NFTS_PER_LIST * 14) { 
            nftList = NftList.NFT_LIST_14;
        }
        else if (tokenId <= NFTS_PER_LIST * 15) {
            nftList = NftList.NFT_LIST_15;
        }
        else if (tokenId <= NFTS_PER_LIST * 16) { 
            nftList = NftList.NFT_LIST_16;
        }
        else if (tokenId <= NFTS_PER_LIST * 17) {
            nftList = NftList.NFT_LIST_17;
        }
        else if (tokenId <= NFTS_PER_LIST * 18) { 
            nftList = NftList.NFT_LIST_18;
        }
        else if (tokenId <= NFTS_PER_LIST * 19) { 
            nftList = NftList.NFT_LIST_19;
        }
        else if (tokenId <= ((NFTS_PER_LIST * 20) - 1)) { 
            nftList = NftList.NFT_LIST_20;
        }

        string memory revealUrl = _revealNFTS_LIST_URLs[nftList];

        return bytes(revealUrl).length > 0
            ? string(abi.encodePacked(revealUrl, tokenId.toString(), ".json")) 
            : beforeRevealURI;
    }

    function isContractCall(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function mint(uint256 quantity) external payable {
        require(
            nftSaleStartTime != 0 && 
            block.timestamp >= nftSaleStartTime,
            "NFTS_SALE_NOT_STARTED"
        );

        require(nftsOnSale != false, "NFTS_NOT_ON_SALE");

        uint256 currentTotalSupply = totalSupply();

        require(tx.origin == msg.sender, "NO_BOT_ORIGIN");
        require(!isContractCall(msg.sender), "NO_BOT_CONTRACT");

        require(quantity > 0, "QUANTITY_CANNOT_BE_MORE_THAN_ZERO");
        require(quantity <= MAX_NFTS_PER_TX, "EXCEEDS_MAX_MINT_PER_TX");

        require(currentTotalSupply < TOTAL_SUPPLY, "SOLD_OUT");
        require(currentTotalSupply + quantity <= TOTAL_SUPPLY, "EXCEEDS_MAX_SUPPLY");

        require(_totalClaimed[msg.sender] + quantity <= MAX_NFTS_PER_WALLET, "EXCEEDS_MAX_ALLOWANCE");

        if (currentTotalSupply < EACH_SALE_PHASE_TOTAL_SUPPLY) { 
            require(msg.value >= FIRST_NFT_SALE_PHASE_PRICE * quantity, "INVALID_TOTAL_ETH_AMOUNT_FOR_FIRST_NFT_SALE_PHASE");
        } else if (currentTotalSupply < EACH_SALE_PHASE_TOTAL_SUPPLY * 2) { 
            require(msg.value >= SECOND_NFT_SALE_PHASE_PRICE * quantity, "INVALID_TOTAL_ETH_AMOUNT_FOR_SECOND_NFT_SALE_PHASE");
        } else if (currentTotalSupply < EACH_SALE_PHASE_TOTAL_SUPPLY * 3) { 
            require(msg.value >= THIRD_NFT_SALE_PHASE_PRICE * quantity, "INVALID_TOTAL_ETH_AMOUNT_FOR_THIRD_NFT_SALE_PHASE");
        }

        for (uint256 i = 0; i < quantity; i++) {
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "NO_BALANCE_TO_WITHDRAW");
        
        payable(_beneficiary).transfer(balance);
    }
}