/* 2022 TRIBUTE TO HYPE CULTURE
by @Whatisayoc

A generated Art Collection Paying homage to Online Hype culture, sneakers and NFT's.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
//import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TributeToHypeculture is ERC721A, Ownable, ERC721AQueryable, ReentrancyGuard {
    
    using SafeMath for uint256;
    using Strings for uint256;
    using Address for address;


   

    uint256 public MAX_TOKENS = 275; //Tentative
    uint256 public constant MAX_PER_MINT = 1; //Tentative
    uint256 private constant maxBatchSize = 1; //Tentative

    address public withdrawalWallet;
    address public secondaryToggler;

    uint256 public price = 0.001 ether; //Tentative
    bool public isRevealed = false;
    bool public publicSaleStarted = false;
    bool public presaleStarted = false;

    //mapping(address => uint256) private _presaleMints;
    //uint256 public presaleMaxPerWallet = 1;

    uint256 public tokensReserved;
    uint256 public reserveAmount;
    

    string private baseURI = ""; 
    bytes32 public merkleRoot;

    constructor() ERC721A("Tribute to Hype Culture by Yoc", "THCULTURE") {
        withdrawalWallet = msg.sender;
        secondaryToggler = msg.sender;
    }

    function setWithdrawalWallet(address _nWallet) external onlyOwner {
        withdrawalWallet = _nWallet;
    }

    function setReserveAmount(uint256 amount) public onlyOwner {
        require(presaleStarted == false);
        require(publicSaleStarted == false);
        reserveAmount = amount;
    }

    function setMaxTokens(uint256 _maxTokenAmount) public onlyOwner {
        require(presaleStarted == false);
        require(publicSaleStarted == false);
        MAX_TOKENS = _maxTokenAmount;
    }


    function setSecondaryToggler(address _secondToggler) external onlyOwner {
        secondaryToggler = _secondToggler;
    }

    // function togglePresaleStarted() external onlyOwner {
    //     presaleStarted = !presaleStarted;
    // }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function togglePublicSaleStartedbySecondary() public {
        require(tx.origin == msg.sender, "Contract can't toggle");
        require(msg.sender == secondaryToggler, "Caller must be the secondary toggler.");
        publicSaleStarted = !publicSaleStarted;
    }


    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    // function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    //     merkleRoot = _merkleRoot;
    // }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (isRevealed) {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        "https://videoincome.s3.ap-southeast-1.amazonaws.com/ode/",
                        "symbol.json"
                    )
                ); //Tentative
        }
    }

    /// Set number of maximum presale mints a wallet can have
    /// @param _newPresaleMaxPerWallet value to set
    // function setPresaleMaxPerWallet(uint256 _newPresaleMaxPerWallet)
    //     external
    //     onlyOwner
    // {
    //     presaleMaxPerWallet = _newPresaleMaxPerWallet;
    // }

    // function isInWhitelist(bytes32[] memory merkleProof)
    //     public
    //     view
    //     returns (bool)
    // {
    //     return
    //         MerkleProof.verify(
    //             merkleProof,
    //             merkleRoot,
    //             keccak256(abi.encodePacked(msg.sender))
    //         );
    // }

    /// Presale mint function
    /// @param tokens number of tokens to mint
    /// @param merkleProof Merkle Tree proof
    /// @dev reverts if any of the presale preconditions aren't satisfied
    // function mintPresale(uint256 tokens, bytes32[] memory merkleProof)
    //     external
    //     payable
    // {
    //     require(tx.origin == msg.sender, "Contract can't mint");
    //     require(presaleStarted, "Presale has not started");
    //     require(
    //         isInWhitelist(merkleProof),
    //         "You are not eligible for the presale"
    //     );
    //     require(
    //         _presaleMints[_msgSender()] + tokens <= presaleMaxPerWallet,
    //         "Presale limit for this wallet reached"
    //     );
    //     require(
    //         tokens <= MAX_PER_MINT,
    //         "Cannot purchase this many tokens in a transaction"
    //     );
    //     require(
    //         totalSupply() + tokens + reserveAmount - tokensReserved <=
    //             MAX_TOKENS,
    //         "Minting would exceed max supply"
    //     );

    //     require(tokens > 0, "Must mint at least one token");
    //     require(price * tokens == msg.value, "ETH amount is incorrect");

    //     _safeMint(_msgSender(), tokens);
    //     _presaleMints[_msgSender()] += tokens;
    // }

    /// Public Sale mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the public sale preconditions aren't satisfied
    function mint(uint256 tokens) external payable {
        require(tx.origin == msg.sender, "Contract can't mint");
        require(publicSaleStarted, "Public sale has not started");
        require(
            tokens <= MAX_PER_MINT,
            "Cannot purchase this many tokens in a transaction"
        );
        require(
            totalSupply() + tokens + reserveAmount - tokensReserved <=
                MAX_TOKENS,
            "Minting would exceed max supply"
        );
        require(tokens > 0, "Must mint at least one token");
        require(price * tokens == msg.value, "ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }

    // Reservation mint function for team
    function reserveMint(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "zero address");
        require(amount > 0, "invalid amount");
        require(totalSupply() + amount <= MAX_TOKENS, "max supply exceeded");
        require(
            tokensReserved + amount <= reserveAmount,
            "max reserve amount exceeded"
        );
        require(
            amount % maxBatchSize == 0,
            "can only mint a multiple of the maxBatchSize"
        );

        uint256 numChunks = amount / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(recipient, maxBatchSize);
        }
        tokensReserved += amount;
    }

    // Distribute funds to pool wallet
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");

        _widthdraw(withdrawalWallet, balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to widthdraw Ether");
    }
}