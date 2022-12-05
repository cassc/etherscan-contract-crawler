// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract LMT is ERC721A, Ownable {
    using Strings for uint256;

    bytes32 public merkleRoot;

    mapping(address => uint256) public wlClaimed;

    string public uriPrefix = "";
    string public uriSuffix = "";

    // whitelist
    uint256 public wlCost = 0 ether;
    uint256 public wlMaxMintAmount = 1;

    // max supply
    uint256 public maxSupply = 100;


    bool public whitelistMintEnabled = false;
    bool private costPayed = false;

    address public royaltyAddress = address(0);
    uint256 public royaltyPercent = 10;

    constructor() ERC721A("Limited Club - Genesis", "LMT") {}

    modifier wlMintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount <= wlMaxMintAmount,
            "That amount is higher then wlMaxMintAmount"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Whitelist Mint sold out already"
        );
        _;
    }

    modifier wlPriceCompliance(uint256 _mintAmount) {
        require(
            msg.value >= wlCost * _mintAmount,
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

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        wlMintCompliance(_mintAmount)
        wlPriceCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "Whitelist minting is not enabled yet");

        require(
            MerkleProof.verify(
                _merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "You are not in the list!"
        );

        // Make sure the user does not mint more than what he is allowed to
        require(
            (wlClaimed[msg.sender] + _mintAmount) <= wlMaxMintAmount,
            "You have already claimed what you are allowed to!"
        );

        // Update the number of claimed tokens for the whitelist sale
        wlClaimed[msg.sender] += _mintAmount;
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

    function setWlCost(uint256 _cost) public onlyOwner {
        wlCost = _cost;
    }

    function setWlMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
        wlMaxMintAmount = _maxMintAmount;
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

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
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
        (bool ds, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(ds);
        // =============================================================================
    }

    function emergencyWithdraw() public onlyOwner {
        bool os = payable(owner()).send(address(this).balance);
        require(os, "Transfer failed.");
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