// SPDX-License-Identifier: MIT

/*
                              .,'
                           .'`.'
                          .' .'
              _.ood0Pp._ ,'  `.~ .q?00doo._
          .od00Pd0000Pdb._. . _:db?000b?000bo.
        .?000Pd0000PP?000PdbMb?000P??000b?0000b.
      .d0000Pd0000P'  `?0Pd000b?0'  `?000b?0000b.
     .d0000Pd0000?'     `?d000b?'     `?00b?0000b.
     d00000Pd0000Pd0000Pd00000b?00000b?0000b?0000b
     ?00000b?0000b?0000b?b    dd00000Pd0000Pd0000P
     `?0000b?0000b?0000b?0b  dPd00000Pd0000Pd000P'
      `?0000b?0000b?0000b?0bd0Pd0000Pd0000Pd000P'
        `?000b?00bo.   `?P'  `?P'   .od0Pd000P'
          `~?00b?000bo._  .db.  _.od000Pd0P~'
              `~?0b?0b?000b?0Pd0Pd000PdP~'
*/
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SPumpkin is ERC721A, Ownable {
    using Strings for uint256;

    bytes32 public merkleRoot;

    mapping(address => uint256) public wlClaimed;
    //public
    mapping(address => uint256) public publicClaimed;

    string public uriPrefix = "";
    string public uriSuffix = "";

    // public mint cost, max supply , max amount
    uint256 public publicCost = 0.0069 ether;
    uint256 public publicMaxMintAmount = 3;
    // whitelist
    uint256 public wlCost = 0.0045 ether;
    uint256 public wlMaxMintAmount = 2;

    // max supply
    uint256 public maxSupply = 2222;

    bool public publicSaleEnabled = false;
    bool public whitelistMintEnabled = false;
    bool private costPayed = false;

    address public royaltyAddress = address(0x877c12a0A3220CDDf5d9Ab654c5678970f2233C8);
    uint256 public royaltyPercent = 10;

    constructor() ERC721A("SPUMPKIN", "SPUMPKIN") {}

    // Makes sure the mint amount is valid and not greater than the max supply.
    modifier publicMintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount <= publicMaxMintAmount,
            "That amount is higher then publicMaxMintAmount"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Public Mint sold out already"
        );
        _;
    }

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

    modifier publicPriceCompliance(uint256 _mintAmount) {
        require(
            msg.value >= publicCost * _mintAmount,
            "You didn't send enough ETH to mint"
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

    function mint(uint256 _mintAmount)
        public
        payable
        publicMintCompliance(_mintAmount)
        publicPriceCompliance(_mintAmount)
    {
        require(
            publicSaleEnabled,
            "Public sale is not enabled yet. Check back later!"
        );
        require(
            (publicClaimed[msg.sender] + _mintAmount) <= publicMaxMintAmount,
            "You have already claimed what you are allowed to!"
        );
        publicClaimed[msg.sender] += _mintAmount;
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

    function setPublicCost(uint256 _cost) public onlyOwner {
        publicCost = _cost;
    }

    function setWlCost(uint256 _cost) public onlyOwner {
        wlCost = _cost;
    }

    function setPublicMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
        publicMaxMintAmount = _maxMintAmount;
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

    function setPublicSaleEnabled(bool _state) public onlyOwner {
        publicSaleEnabled = _state;
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
        uint256 bal = address(this).balance;
        uint256 cost = 0 ether;
        uint256 balance = bal;
        
        address devAddress = address(0x840a56131FcfbF169e84dEadA1546b0684BDAD5f);
        address artistAddress = address(0xA91B390FeFa2C198FCF1Bd25B426F114D30fda9b);
        address marketingAddress = address(0x4caC860b1A5b005fE7598069c4B4F60D062E749a);

        if (bal > 0.9 ether && !costPayed) {
            cost = 0.9 ether;
            balance = bal - cost;
            costPayed = true;
            payable(marketingAddress).transfer(cost);
        }
        // Dev : 33% , Artist : 33%, Marketing : 33% , inkl Cost
        uint256 dev = (balance * 33) / 100;
        uint256 artist = (balance * 33) / 100;
        uint256 marketing = (balance * 33) / 100;


        (bool ds, ) = payable(devAddress).call{value: dev}("");
        (bool gs, ) = payable(artistAddress).call{value: artist}("");
        (bool ms, ) = payable(marketingAddress).call{value: marketing}("");

        require(ds && gs && ms, "Transfer failed.");
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