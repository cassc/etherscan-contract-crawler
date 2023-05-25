// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.9;

import "./ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/*
              ETHSTER EGGS

             ,a888P88Y888a,
           ,d"8"8",YY,"8"8"b,
          d",P'd' d'`b `b`Y,"b,
        ,P",P',P  8  8  Y,`Y,"Y,
       ,P ,P' d'  8  8  `b `Y, Y,
      ,P ,P_,,8ggg8gg6ggg6,,_Y, Y,
     ,8P"""""""''      ``"""""""Y8,
     d'/~\    /~\    /~\    /~\  `b
     8/   \  /   \  /   \  /   \  8
     8 ,8, \/ ,8, \/ ,6, \/ ,6, \/8
     8 "Y" /\ "Y" /\ "Y" /\ "Y" /\8
     8\   /  \   /  \   /  \   /  8
     8 \_/    \_/    \_/    \_/   8
     8                            8
     Y""""YYYaaaa,,,,,,aaaaPPP""""P
     `b ag,   ``""""""""''   ,ga d'
      `YP "b,  ,aa,  ,aa,  ,d" YP'
        "Y,_"Ya,_)8  8(_,aP"_,P"
          `"Ya_"""    """_aP"'  
             `""YYbbddPP""'     

             EGG HUNT ANYONE? 
               [⊙ ‿ ⊙]
*/


// Developed by @ASXLabs on Twitter
// https://www.asxlabs.com


contract EthsterEggs is Ownable, ERC721A, ERC721ABurnable, ERC2981, ReentrancyGuard {
    using Strings for uint256;

    bool private revealed = false;

    string private prerevealTokenUri;
    string private baseTokenUri;
    string private secondTokenUri;

    uint256 private devMinted = 0;

    bool public mintActive = false;
    bool public publicMintActive = false;
    uint256 public maxSupply = 8866;

    bool public manualOverrideMode = false;
    uint256 public manualOverrideMintPrice = 0.011 ether;

    uint256 public priceStageZero = 0 ether;

    uint256 public priceStageOne = 0.011 ether;
    uint256 public priceStageTwo = 0.022 ether;

    bytes32 public merkleRoot;



    constructor() ERC721A("ETHster Eggs", "EGGS") {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    /** 
    @notice Mint function. 
    */
    function mint(bytes32[] calldata _merkleProof, uint256 amount) external payable callerIsUser {
        require(mintActive, "Minting is not active");
        require(_totalMinted() + amount <= maxSupply, "Max supply reached");
        require(amount <= 10, "You can only mint 10 tokens at a time");

        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verifyCalldata(_merkleProof, merkleRoot, node), "You are not whitelisted");

        uint256 totalMinted = _totalMinted();

        if (manualOverrideMode) {
            require(msg.value >= manualOverrideMintPrice, "Below Mint Price");
        }
        else {
            if (totalMinted <= 1366) {
                require(_getAux(msg.sender) + amount <= 3, "You are trying to mint more than 3 tokens to this address");
                require(msg.value >= priceStageZero , "Below Mint Price");

                _setAux(msg.sender, uint64(amount) + _getAux(msg.sender));
            }
            else if (totalMinted <= 3866) {
                require(msg.value >= priceStageOne, "Below Mint Price");
            }
            else if (totalMinted <= 8866) {
                require(msg.value >= priceStageTwo, "Below Mint Price");
            }
            else {
                require(msg.value >= priceStageTwo, "Below Mint Price");
            }
        }

        _mint(msg.sender, amount);
    }


    
    function publicMint(uint256 amount) external payable callerIsUser {
        require(publicMintActive, "Public Minting is not active");
        require(_totalMinted() + amount <= maxSupply, "Max supply reached");
        require(amount <= 10, "You can only mint 10 tokens at a time");

        uint256 totalMinted = _totalMinted();

        if (manualOverrideMode) {
            require(msg.value >= manualOverrideMintPrice, "Below Mint Price");
        }
        else {
            if (totalMinted <= 1366) {
                require(msg.value >= priceStageZero , "Below Mint Price");
            }
            else if (totalMinted <= 3866) {
                require(msg.value >= priceStageOne, "Below Mint Price");
            }
            else if (totalMinted <= 8866) {
                require(msg.value >= priceStageTwo, "Below Mint Price");
            }
            else {
                require(msg.value >= priceStageTwo, "Below Mint Price");
            }
        }

        _mint(msg.sender, amount);
    }


    // Mint function for dev wallets. Can only be called by the owner. Mints 366 tokens max.
    function mintDev(address to, uint256 amount) external onlyOwner {
        require(devMinted + amount <= 366, "You are trying to mint more than 366 tokens in total");
        require(totalSupply() + amount <= maxSupply, "Max supply reached");        
        unchecked {devMinted += amount;}

        _mint(to, amount);
    }


    // Revoke a token
    function revoke(uint256 tokenId) external onlyOwner {
        _burn(tokenId, false);
    }

    // Set base URI
    /* 
    * @dev Must include trailing slash 
    **/
    function setBaseTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    // Set second URI
    /*
    * @dev Must include trailing slash
    **/
    function setSecondTokenUri(string memory _secondTokenUri) external onlyOwner {
        secondTokenUri = _secondTokenUri;
    }

    // Set pre reveal URI
    /*
    * @dev Must include trailing slash
    **/
    function setPreRevealTokenUri(string memory _prerevealTokenUri) external onlyOwner {
        prerevealTokenUri = _prerevealTokenUri;
    }

    // Toggle minting status
    function setMintActive() external onlyOwner {
        mintActive = !mintActive;
    }

    // Set max supply
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    // Set merkle root for whitelist
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

    // Returns the total amount of tokens minted
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
      _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    // Set manual override mode
    function setManualOverrideMode() external onlyOwner {
        manualOverrideMode = !manualOverrideMode;
    }

    // Set public mint active
    function setPublicMintActive() external onlyOwner {
        publicMintActive = !publicMintActive;
    }

    // Set mint price
    function setManualMintPrice(uint256 _mintPrice) external onlyOwner {
        manualOverrideMintPrice = _mintPrice;
    }
    // Set the differnt mint prices individually functions
    function setPriceStageZero(uint256 _priceStageZero) external onlyOwner {
        priceStageZero = _priceStageZero;
    }

    function setPriceStageOne(uint256 _priceStageOne) external onlyOwner {
        priceStageOne = _priceStageOne;
    }

    function setPriceStageTwo(uint256 _priceStageTwo) external onlyOwner {
        priceStageTwo = _priceStageTwo;
    }

    // Set reveal status
    function setReveal() external onlyOwner {
        revealed = !revealed;
    }

    // Returns the total amount of tokens burned
    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    // Returns the amount of tokens burned by a specific address
    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }

    // Return uri for certain token
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (!revealed) {
            return bytes(prerevealTokenUri).length > 0 ? string(abi.encodePacked(prerevealTokenUri, tokenId.toString())) : "";
        }

        if (tokenId >= 5666) {
            return bytes(secondTokenUri).length > 0 ? string(abi.encodePacked(secondTokenUri, tokenId.toString())) : "";
        } 
        else {
            return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, tokenId.toString())) : "";
        }
    }

    // Withdraw funds
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

}