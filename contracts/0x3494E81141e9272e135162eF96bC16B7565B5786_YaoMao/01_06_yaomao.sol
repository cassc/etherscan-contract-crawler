//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "./utils/Strings.sol";
import "./access/Ownable.sol";

// Author: @i0x46

contract YaoMao is ERC721A, Ownable {
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    // The cost of the tokens after free. 
    uint256 public cost = 0.0069 ether;
    // The total number of tokens we have. 
    uint256 public maxSupply = 999;
    // The number of tokens that are retained for selling with cost. 
    uint256 public retainedTokens = 333;
    // The number of tokens one can mint in a single minting process. 
    uint256 public maxMintAmount = 1;
    // Indicates that only whitelisted members can mint from the contract. 
    bool public whitelistOnly = true;
    // Indicates that no one can mint from the contract. 
    bool public paused = false;
    // The list that contains all whitelisted addresses. 
    mapping(address => bool) public whitelisted;
    // The list that contains all free claiming wallets 
    mapping(address => bool) public freeOwners;

    // We also pass in the white list to the constructor to whitelist specific 
    // People during deployment.
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI, 
        address[] memory _whitelist
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelisted[_whitelist[i]] = true;
        }
    }

    // Our start ID starts from 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(address _to, uint256 _mintAmount) public payable {
        // Must not be paused. 
        require(!paused, "The minting has not started yet.");

        // Number of minted tokens
        uint256 minted = _totalMinted();

        // Number of available tokens
        uint256 available = maxSupply - minted;

        // We must have tokens available
        require(available > 0, "All the tokens have been minted.");
        // Mint amount must be greater than 0
        require(_mintAmount > 0, "Mint amount must be greater than 0.");
        // And less than max mint amount.
        require(_mintAmount <= maxMintAmount, "Mint amount is greater than maximum amount.");

        // Check if we are in whitelist mode, and if we are, check if user 
        // is whitelisted. 
        if(whitelistOnly){
            require(whitelisted[_to] == true, "Only whitelisted users can mint from the token at the moment.");
        }

        // We check if the user has already availed their free mint. 
        if(freeOwners[_to]) {
            // Here we cost them the minting price. 
            require(msg.value >= cost * _mintAmount, "Value must be greater than or equal to the cost of minting.");
        } else if (available <= retainedTokens) {
            // Here we explicitly give them for cost. 
            require(msg.value >= cost * _mintAmount, "Value must be greater than or equal to the cost of minting.");
        } else {
            // Here we give them this mint for free.
        }
        _safeMint(_to, _nextTokenId());
        if(!freeOwners[_to]){
            freeOwners[_to] = true;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //Sets the cost of retained tokens.
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    // Sets max mint amount.
    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    // Update baseURI of the tokens.
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    // Pause or resume.
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setWhitelistOnly(bool _state) public onlyOwner {
        whitelistOnly = _state;
    }

    function setRetainedTokens(uint256 _tokenCount) public onlyOwner {
        require(_tokenCount <= maxSupply);
        retainedTokens = _tokenCount;
    }

    // Add a user to whitelist. 
    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }

    // Remove a user from whitelist.
    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    // Adds array of wallets to whitelist. 
    function whitelistUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelisted[_users[i]] = true;
        }
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function getCost(address user) public view returns (uint256){
        // First, if we have already availed free token, we return actual cost.
        if(freeOwners[user]){
            return cost;
        } else {
            // We also check if available tokens are less or equal to retained
            // In which case, we also return cost. 
        
            // Number of minted tokens
            uint256 minted = _totalMinted();

            // Number of available tokens
            uint256 available = maxSupply - minted;

            if(available <= retainedTokens){
                return cost;
            }
        }
        // Otherwise, we return 0 
        return 0;
    }

    function getBalance() public onlyOwner view returns (uint256) {
        return address(this).balance;
    }
}