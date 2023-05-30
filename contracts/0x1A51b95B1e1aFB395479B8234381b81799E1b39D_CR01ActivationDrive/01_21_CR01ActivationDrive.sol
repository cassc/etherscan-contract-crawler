// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Ownable is needed to setup sales royalties on Open Sea
// if you are the owner of the contract you can configure sales Royalties in the Open Sea website
import "@openzeppelin/contracts/access/Ownable.sol";

contract CR01ActivationDrive is ERC721Enumerable, ERC721URIStorage, AccessControl, Ownable {
    using Counters for Counters.Counter;
    using Address for address;

    // Counter to auto increment tokenIds for each mint
    Counters.Counter private _tokenIdCounter;

    // Mapping controlling how many and address has minted
    mapping(address => uint256) private _ownerToAmountMinted;

    // Simple flag to check if the contract has been initialized or not
    bool private _initialized = false;

    // Metadata related variables
    string private _baseTokenURI = "";
    string private _mainTokenUri = "ipfs://QmZ3JvmjetyntV8CVYeyN77TvXu5XRwbPqvKEbTESTEbNM";

    // Other contracts
    address public _mysteryBoxAddr;
    address public _wasTokenAddr;
    address public _wsdrMasterAddr;
    address public _wsdrGeniusAddr;

    // Flag controlling if minting is allowed for everyone or not
    bool public _onlyMysteryBoxHoldersCanMint = true;
    bool public _onlyWasTokenHoldersCanMint = false;
    bool public _onlyWsdrMasterOrGeniusHoldersCanMint = false;
    bool public _onlyWasderNFTHoldersCanMint = false;

    // Variable holding the price to mint "aka buy" the token for a given user. Price in wei
    uint256 public _mintPrice;

    // Flag controlling if minting is allowed or not
    bool public _allowMinting = false;

    // Total amount of tokens that can be minted
    uint256 public _cap = 1200;

    // Total amount of tokens a single address can own
    uint256 public _capPerAddress = 2;

    event TokenMinted(address account, uint256 amount);
    event Withdrawn(address payee, uint256 weiAmount);

    constructor() ERC721("WSDR ACTIVATION MINT DRIVE", "WASDERDACTIVATIONDRIVE")  {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function initialize(
        address mysteryBoxAddr_,
        address wasTokenAddr_,
        address wsdrMasterAddr_,
        address wsdrGeniusAddr_,
        uint256 mintPrice_
    ) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        _initialized = true;
        _mintPrice = mintPrice_;
        _mysteryBoxAddr = mysteryBoxAddr_;
        _wasTokenAddr = wasTokenAddr_;
        _wsdrMasterAddr = wsdrMasterAddr_;
        _wsdrGeniusAddr = wsdrGeniusAddr_;
    }

    /**
     * OVERRIDE METHODS
     */
    function supportsInterface(bytes4 interfaceId) public view virtual 
        override(ERC721Enumerable, ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721)  {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
      * @dev Function override to disable burning the NFT
     */
    function _burn(uint256 tokenId) internal virtual override(ERC721URIStorage, ERC721)  {
        super._burn(tokenId);
    }

    /**
      * @dev Function override to make sure all NFTs actually do have the same URI for the metadata
     */
    function tokenURI(uint256) public view virtual override(ERC721URIStorage, ERC721) returns (string memory) {
        return _mainTokenUri;
    }

    /**
      * @dev Function override to make sure all NFTs actually do have the same URI for the metadata
     */
    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Views
     */
    function getCurrentTokenId() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function hasWasderNFT(address addr) public view returns (bool) {
        return hasMysteryBox(addr) || hasWsdrMasterOrGenius(addr);
    }

    function hasMysteryBox(address addr) public view returns (bool) {
        IERC721 MysteryBoxContract = IERC721(_mysteryBoxAddr);
        return MysteryBoxContract.balanceOf(addr) > 0;
    }

    function hasWasToken(address addr) public view returns (bool) {
        IERC20 WasTokenContract = IERC20(_wasTokenAddr);
        return WasTokenContract.balanceOf(addr) > 0;
    }

    function hasWsdrMasterOrGenius(address addr) public view returns (bool) {
        IERC721 WsdrMaster = IERC721(_wsdrMasterAddr);
        IERC721 WsdrGenius = IERC721(_wsdrGeniusAddr);
        return WsdrMaster.balanceOf(addr) > 0 || WsdrGenius.balanceOf(addr) > 0;
    }

    /**
     * Setters
     */
    function setAllowMinting(bool allowMinting_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        _allowMinting = allowMinting_;
    }

    function setMintPrice(uint256 mintPrice_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        _mintPrice = mintPrice_;
    }

    function setBaseURI(string memory baseTokenURI_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        _baseTokenURI = baseTokenURI_;
    }

    function setCap(uint256 cap_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        _cap = cap_;
    }
    
    function setCapPerAddress(uint256 capPerAddress_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        _capPerAddress = capPerAddress_;
    }

    /**
      * @dev Function to set the token URI (aka metadata)
     */
    function setMainTokenURI(string memory mainTokenURI_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        _mainTokenUri = mainTokenURI_;
    }

    function setOnlyMysteryBoxHoldersCanMint(bool value) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        _onlyMysteryBoxHoldersCanMint = value;
    }

    function setOnlyWasTokenHoldersCanMint(bool value) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        _onlyWasTokenHoldersCanMint = value;
    }

    function setOnlyWsdrMasterOrGeniusHoldersCanMint(bool value) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        _onlyWsdrMasterOrGeniusHoldersCanMint = value;
    }

    function setOnlyWasderNFTHoldersCanMint(bool value) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        _onlyWasderNFTHoldersCanMint = value;
    }

    function checkIfMintingIsAllowed(address mintTo) public view returns (bool) {
        require(_allowMinting, "Minting is no longer allowed");
        require(_ownerToAmountMinted[mintTo] < _capPerAddress, "Cap reached for given address");

        if (_onlyMysteryBoxHoldersCanMint) {
            require(hasMysteryBox(mintTo), "You don't have a Mystery Box");
        }

        if (_onlyWasTokenHoldersCanMint) {
            require(hasWasToken(mintTo), "You don't have a WAS Token");
        }

        if (_onlyWsdrMasterOrGeniusHoldersCanMint) {
            require(hasWsdrMasterOrGenius(mintTo), "You don't have a WSDR MASTER OR GENIUS token");
        }

        if (_onlyWasderNFTHoldersCanMint) {
            require(hasWasderNFT(mintTo), "You don't have a WASDER NFT");
        }

        return true;
    }

    /**
      * @dev Function to mint a new token with a specific TokenId
      */
    function mint(address mintTo) public virtual payable returns (bool) {
        require(_initialized, "Contract is not initialized");
        require(mintTo != address(0), "ERC721: mint to the zero address");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        // Even admins need to adhere to this, so we don't loose sync 
        // between the tokenIdCounter and the cap
        require(tokenId <= _cap, "Cap reached");

        // Lets make sure admins can mint as many as needed
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            require(checkIfMintingIsAllowed(mintTo), "You are not allowed to mint new tokens");
            require(msg.value >= _mintPrice, "Not enough ETH sent; check price!");
        }

        _ownerToAmountMinted[mintTo] = _ownerToAmountMinted[mintTo] + 1;
        _safeMint(mintTo, tokenId);

        emit TokenMinted(mintTo, tokenId);

        return true;
    }

    function mintMany(address[] calldata mintToList) public returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");

        for (uint256 i = 0; i < mintToList.length; i++) {
            require(mintToList[i] != address(0), "ERC721: mint to the zero address");
        }
        for (uint256 i = 0; i < mintToList.length; i++) {
            // This way we can avoid the transaction getting reverted due to the fact that a contract
            // might not be able to receive ERC721 tokens.
            if (mintToList[i].isContract()) {
                continue;
            }
            mint(mintToList[i]);
        }
        return true;
    }

    function withdraw() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        
        uint256 balance = address(this).balance;
        
        payable(_msgSender()).transfer(balance);

        emit Withdrawn(_msgSender(), balance);
    }
}