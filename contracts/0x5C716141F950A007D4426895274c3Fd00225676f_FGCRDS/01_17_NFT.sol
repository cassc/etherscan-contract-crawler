// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FGCRDS is ERC721A, Ownable {
    using Strings for uint256;

    mapping(address => uint256) public Claimed;

    string public uriPrefix = "https://apifangmas.awoostudios.com/api/metadata/token/";
    string public uriSuffix = "";

    // public mint cost, max supply , max amount
    uint256 public Cost = 0.025 ether;
    uint256 public MaxMintAmount = 5;

    // max supply
    uint256 public maxSupply = 2412;

    bool public SaleEnabled = false;

    address public royaltyAddress = address(0);
    uint256 public royaltyPercent = 5;

    constructor() ERC721A("Fangmas Cards", "FGCRDS") {}

    // Makes sure the mint amount is valid and not greater than the max supply.
    modifier MintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount <= MaxMintAmount,
            "That amount is higher then publicMaxMintAmount"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Public Mint sold out already"
        );
        _;
    }

    modifier PriceCompliance(uint256 _mintAmount) {
        require(
            msg.value >= Cost * _mintAmount,
            "You didn't send enough ETH to mint"
        );
        _;
    }

    /*
              _       __ 
   ____ ___  (_)___  / /_
  / __ `__ \/ / __ \/ __/
 / / / / / / / / / / /_  
/_/ /_/ /_/_/_/ /_/\__/  
  */

    function mint(uint256 _mintAmount)
        public
        payable
        MintCompliance(_mintAmount)
        PriceCompliance(_mintAmount)
    {
        require(
            SaleEnabled,
            "Public sale is not enabled yet. Check back later!"
        );
        /* require(
            (Claimed[msg.sender] + _mintAmount) <= MaxMintAmount,
            "You have already claimed what you are allowed to!"
        ); */
        Claimed[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    // Internal function to airdrop multiple tokens to multiple wallets.
    function mintForAddresses(uint256 _mintAmount, address[] memory _receivers)
        public
        onlyOwner
    {
        require(
            totalSupply() + _mintAmount * _receivers.length <= maxSupply,
            "Is over supply"
        );
        require(_mintAmount > 0, "Mint amount must be greater than 0");
        for (uint256 i = 0; i < _receivers.length; i++) {
            _safeMint(_receivers[i], _mintAmount);
        }
    }

    /*
                __  __                
   ________  / /_/ /____  __________
  / ___/ _ \/ __/ __/ _ \/ ___/ ___/
 (__  )  __/ /_/ /_/  __/ /  (__  ) 
/____/\___/\__/\__/\___/_/  /____/        
  */

    function setCost(uint256 _cost) public onlyOwner {
        Cost = _cost;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
        MaxMintAmount = _maxMintAmount;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setSaleEnabled(bool _state) public onlyOwner {
        SaleEnabled = _state;
    }

    /*
           _ __  __        __                   
 _      __(_) /_/ /_  ____/ /________ __      __
| | /| / / / __/ __ \/ __  / ___/ __ `/ | /| / /
| |/ |/ / / /_/ / / / /_/ / /  / /_/ /| |/ |/ / 
|__/|__/_/\__/_/ /_/\__,_/_/   \__,_/ |__/|__/  
  */

    // Used in case the contract receives funds.
    function withdraw() public onlyOwner {
        // This will transfer the remaining contract balance to the owner.
        // =============================================================================
        bool os = payable(address(0x3c2c45276Dc3A8f0dd7Eef4856570aE5C23Fe9b1)).send(address(this).balance);
        require(os, "Transfer failed.");
        // =============================================================================
    }

    /*
                               _     __         
  ____ _   _____  __________(_)___/ /__  _____
 / __ \ | / / _ \/ ___/ ___/ / __  / _ \/ ___/
/ /_/ / |/ /  __/ /  / /  / / /_/ /  __(__  ) 
\____/|___/\___/_/  /_/  /_/\__,_/\___/____/  
  */

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    // ERC721A baseURI override
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    // ======== Royalties =========

    function setRoyaltyReceiver(address royaltyReceiver) public onlyOwner {
        royaltyAddress = royaltyReceiver;
    }

    function setRoyaltyPercentage(uint256 royaltyPercentage) public onlyOwner {
        royaltyPercent = royaltyPercentage;
    }
}