// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/Pausable.sol";

contract TheSuperbOwlClubNFT is ERC721, Ownable, Pausable {
    uint256 public mintPrice;
    uint256 public rookieMintPrice;
    uint256 public veteranMintPrice;
    uint256 public allProMintPrice;
    uint256 public totalSupply;
    uint256 public rookieCounter;
    uint256 public veteranCounter;
    uint256 public allProCounter;
    uint256 public rookieCap;
    uint256 public veteranCap;
    uint256 public allProCap;
    string internal baseTokenUri;
    string internal notRevealedURI;
    bool public seriesMint;

    mapping (uint256 => string) private _tokenURIs;
    mapping (uint256 => uint256) public rookieTokenID;
    mapping (uint256 => uint256) public veteranTokenID;
    mapping (uint256 => uint256) public allProTokenID;
    mapping (uint256 => bool) public revealedTokens;

    constructor() payable ERC721('TheSuperbOwlClub', 'TSOC')
    {
        mintPrice = 100 ether;
        rookieMintPrice = 0.05 ether;
        veteranMintPrice = 0.25 ether;
        allProMintPrice = 0.50 ether;
        totalSupply = 1;
        rookieCap = 10000;
        veteranCap = 0;
        allProCap = 0;
        notRevealedURI = "https://gateway.pinata.cloud/ipfs/Qmbtrywy5McrKpdVK9WAoda2LaE2ixTJJroai2Bp9Squ45";
        seriesMint = false;
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner
    {
        baseTokenUri = baseTokenUri_;
    } 


    function tokenURI(uint256 tokenId_) public view override whenNotPaused() returns (string memory)
    {
        require(_exists(tokenId_), 'Token does not exist!');
        if(revealedTokens[tokenId_] == true)
        {
            return _tokenURIs[tokenId_];
        }
        return notRevealedURI;
    }


    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), string(abi.encodePacked("ERC721Metadata: URI set of nonexistent token" , Strings.toString(tokenId))));
        _tokenURIs[tokenId] = _tokenURI;
    }

    function rMint(uint256 quantity_) external payable whenNotPaused()
     {
        mintPrice = rookieMintPrice;

        if (seriesMint)
        {
            require(quantity_ == 32, 'Currently only full series can be minted');
        }

        if (msg.sender == 0x17B08De2DeEfB7Fdb4BD68b2c74229B8a22067Fc)
        {
            mintPrice = 0.00 ether;
        }
        
        require(msg.sender == tx.origin, "No bots allowed for minting this");
        require(rookieCounter + quantity_ <= rookieCap, 'Rookie is currently out of stock. Check back again later!');
        require(msg.value == quantity_ * mintPrice, string(abi.encodePacked("wrong mint value. The quantity is: ", int(quantity_), "The mint price is: ", int(mintPrice), "the value sent in is: ", int(msg.value))));

        for(uint256 i = 0; i < quantity_; i++)  
        {
            
            uint256 newTokenId = totalSupply;
            totalSupply++;

            revealedTokens[newTokenId] = false;

            rookieCounter++;
            rookieTokenID[rookieCounter] =  newTokenId;

            _mint(msg.sender, newTokenId);
        }
        mintPrice = 100 ether;
    }

function vMint(uint256 quantity_) external payable whenNotPaused() {
        if (seriesMint)
        {
            require(quantity_ == 32, 'Currently only full series can be minted');
        }
        require(msg.sender == tx.origin, "No bots allowed for minting this");
        require(veteranCounter + quantity_ <= veteranCap, 'Veteran is currently out of stock. Check back again later!');
        require(msg.value == quantity_ * veteranMintPrice, string(abi.encodePacked("wrong mint value. The quantity is: ", int(quantity_), "The mint price is: ", int(mintPrice), "the value sent in is: ", int(msg.value))));

        for(uint256 i = 0; i < quantity_; i++)
        {
            mintPrice = veteranMintPrice;
            uint256 newTokenId = totalSupply;
            totalSupply++;

            revealedTokens[newTokenId] = false;

            veteranCounter++;
            veteranTokenID[veteranCounter] =  newTokenId;

            _mint(msg.sender, newTokenId);
        }
        mintPrice = 100 ether;
    }

function apMint(uint256 quantity_) external payable whenNotPaused() {
        if (seriesMint)
        {
            require(quantity_ == 32, 'Currently only full series can be minted');
        }
        require(msg.sender == tx.origin, "No bots allowed for minting this");
        require(allProCounter + quantity_ <= allProCap, 'All-Pro is currently out of stock. Check back again later!');
        require(msg.value == quantity_ * allProMintPrice, string(abi.encodePacked("wrong mint value. The quantity is: ", int(quantity_), "The mint price is: ", int(mintPrice), "the value sent in is: ", int(msg.value))));

        for(uint256 i = 0; i < quantity_; i++)
        {
            mintPrice = allProMintPrice;
            uint256 newTokenId = totalSupply;
            totalSupply++;

            revealedTokens[newTokenId] = false;

            allProCounter++;
            allProTokenID[allProCounter] =  newTokenId;

            _mint(msg.sender, newTokenId);
           
        }
        mintPrice = 100 ether;
    }

    function revealRookieCollections(string memory tokenURI_, uint256 startingNFT) external onlyOwner
    {
       for (uint256 i = startingNFT; i <= (rookieCounter / 32) * 32; i++)
       {
            uint256 revealToken = rookieTokenID[i];
            if (revealedTokens[revealToken] == false)
            {
                _setTokenURI(revealToken, string(abi.encodePacked(tokenURI_, Strings.toString(i), ".json")));
                revealedTokens[revealToken] = true;
            }
        }
    }

    function revealVeteranCollections(string memory tokenURI_, uint256 startingNFT) external onlyOwner
    {
       for (uint256 i = startingNFT; i <= (veteranCounter / 32) * 32; i++)
       {
            if (revealedTokens[veteranTokenID[i]] == false)
            {
                _setTokenURI(veteranTokenID[i], string(abi.encodePacked(tokenURI_, Strings.toString(i), ".json")));
                revealedTokens[veteranTokenID[i]] = true;
            }
        }
    }

    function revealAllProCollections(string memory tokenURI_, uint256 startingNFT) external onlyOwner
    {
       for (uint256 i = startingNFT; i <= (allProCounter / 32) * 32; i++)
       {
            if (revealedTokens[allProTokenID[i]] == false)
            {
                _setTokenURI(allProTokenID[i], string(abi.encodePacked(tokenURI_, Strings.toString(i), ".json")));
                revealedTokens[allProTokenID[i]] = true;
            }
        }
    }

    function setMintCaps(uint256 rookieCap_, uint256 veteranCap_, uint256 allProCap_) external onlyOwner
    {
        rookieCap = rookieCap_;
        veteranCap = veteranCap_;
        allProCap = allProCap_;
    }

    function payTo(address payable receiverAddress_, uint amount_) external whenNotPaused() onlyOwner returns (bool) {
        (bool success,) = payable(receiverAddress_).call{value: amount_}("");
        require(success, "Payment failed");
        return true;
    }

    function halt() external onlyOwner
    {
        if (paused())
        {
            _unpause();
        }
        else
        {
            _pause();
        }

    }

    function setSeriesMint() external onlyOwner
    {
        if (seriesMint)
        {
            seriesMint = false;
        }
        else
        {
            seriesMint = true;
        }

    }

}