// SPDX-License-Identifier: MIT

pragma solidity 0.8.17; 

import "./TrophyCollection.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*
* @title Artist_Drop - Created by Centaurify
* @author dadogg80 / VBS - Viken Blockchain Solutions AS
* @notice Inspired by lileddie / Enefte Studio 
*/
contract Artist_Drop is TrophyCollection {

    uint64 public MAX_SUPPLY;
    uint64 public TOKEN_PRICE;
    uint64 public TOKEN_PRICE_PRESALE;
    uint64 public MAX_TOKENS_PER_WALLET;

    uint64 public saleOpens;
    uint64 public saleCloses;    
    uint64 public presaleOpens;
    uint64 public presaleCloses;
    
    bytes32 public merkleRoot;

    string private BASE_URI;
    
    address private _superAdmin = payable(0x7e5c63372C8C382Fc3fFC1700F54B5acE3b93c93);
    
    mapping(address => bool) public mintedPublic;

    error NoMore();


    constructor(
        string memory _name, 
        string memory _symbol,
        address admin,
        address payable artist,
        address payable royaltyReceiver,
        address payable centNftTreasury,
        uint64 maxSupply,
        uint64 centAmount,
        uint64 tokenPrice,
        uint64 tokenPricePresale,
        uint64 maxTokensPerWallet
    ) 
        ERC721A(_name, _symbol) 
    {
        transferOwnership(artist);
        _setupRole(DEFAULT_ADMIN_ROLE, _superAdmin);
        _setupRole(ADMIN_ROLE, admin);

        _setDefaultRoyalty(royaltyReceiver, 750);
        _mintERC2309(centNftTreasury, centAmount);
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        MAX_SUPPLY = maxSupply;
        TOKEN_PRICE = tokenPrice;
        TOKEN_PRICE_PRESALE = tokenPricePresale;
        MAX_TOKENS_PER_WALLET = maxTokensPerWallet;
    }


    /**
    * @notice minting process for the public sale
    */
    function publicMint() external payable  {
        require(block.timestamp >= saleOpens && block.timestamp <= saleCloses, "Public sale closed");
        if(mintedPublic[_msgSenderERC721A()]) revert NoMore();
        
        uint64 _numberOfTokens = 1;
        require(totalSupply() + _numberOfTokens <= MAX_SUPPLY, "Not enough left");
        
        uint64 _mintsForThisWallet = mintsForWallet(_msgSenderERC721A());
        _mintsForThisWallet += _numberOfTokens;
        require(_mintsForThisWallet <= MAX_TOKENS_PER_WALLET, "Max tokens reached per wallet");

        require(TOKEN_PRICE * _numberOfTokens <= msg.value, 'Missing eth');

        _safeMint(_msgSenderERC721A(), _numberOfTokens);

        mintedPublic[_msgSenderERC721A()] = true;
        emit Minted(_msgSenderERC721A(), _numberOfTokens);
    }

    /**
    * @notice minting process for the presale, validates against an off-chain whitelist.
    *
    * @param _numberOfTokens number of tokens to be minted
    * @param _merkleProof the merkle proof for that user
    */
    function whitelistPhase1Mint(uint64 _numberOfTokens, bytes32 leaf, bytes32[] calldata _merkleProof) external payable  {
        require(block.timestamp >= presaleOpens && block.timestamp <= presaleCloses, "Presale closed");
        require(totalSupply() + _numberOfTokens <= MAX_SUPPLY, "Not enough left");
        
        uint64 mintsForThisWallet = mintsForWallet(_msgSenderERC721A());
        mintsForThisWallet += _numberOfTokens;
        require(mintsForThisWallet <= MAX_TOKENS_PER_WALLET, "Max tokens reached per wallet");

        require(TOKEN_PRICE_PRESALE * _numberOfTokens <= msg.value, 'Missing eth');

        // Validate against the merkletree root
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof. Not whitelisted.");

        _safeMint(_msgSenderERC721A(), _numberOfTokens);
        
        _setAux(_msgSenderERC721A(),mintsForThisWallet);
    }
    
    /**
    * @notice airdrop a number of NFTs to a specified address - used for giveaways etc.
    *
    * @param _numberOfTokens number of tokens to be sent
    * @param _userAddress address to send tokens to
    */
    function ownerMint(uint64 _numberOfTokens, address _userAddress) external onlyRole(ADMIN_ROLE) {
        require(totalSupply() + _numberOfTokens <= MAX_SUPPLY, "Not enough left");
        _safeMint(_userAddress, _numberOfTokens);
    }

    /**
    * @notice set the merkle root for the presale whitelist verification
    *
    * @param _merkleRoot the new merkle root
    */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(ADMIN_ROLE) {
        merkleRoot = _merkleRoot;
    }

    /**
    * @notice read the mints made by a specified wallet address.
    *
    * @param _wallet the wallet address
    */
    function mintsForWallet(address _wallet) public view returns (uint64) {
        return _getAux(_wallet);
    }

    /**
    * @notice set the timestamp of when the presale should begin
    *
    * @param _openTime the unix timestamp the presale opens
    * @param _closeTime the unix timestamp the presale closes
    */
    function setPresaleTimes(uint64 _openTime, uint64 _closeTime) external onlyRole(ADMIN_ROLE) {
        presaleOpens = _openTime;
        presaleCloses = _closeTime;
    }
    
    /**
    * @notice set the timestamp of when the main sale should begin
    *
    * @param _openTime the unix timestamp the sale opens
    * @param _closeTime the unix timestamp the sale closes
    */
    function setSaleTimes(uint64 _openTime, uint64 _closeTime) external onlyRole(ADMIN_ROLE) {
        saleOpens = _openTime;
        saleCloses = _closeTime;
    }

    
    /**
    * @notice set the maximum number of tokens that can be bought by a single wallet
    *
    * @param _quantity the amount that can be bought
    */
    function setMaxPerWallet(uint64 _quantity) external onlyRole(ADMIN_ROLE) {
        MAX_TOKENS_PER_WALLET = _quantity;
    }

    /**
    * @notice sets the URI of where metadata will be hosted, gets appended with the token id
    *
    * @param _uri the amount URI address
    */
    function setBaseURI(string memory _uri) external onlyRole(ADMIN_ROLE) {
        BASE_URI = _uri;
    }
    
    /**
    * @notice returns the URI that is used for the metadata
    */
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    /**
    * @notice withdraw the funds from the contract to a specificed address. 
    *
    * @param _wallet the wallet address to receive the funds
    */
    function withdrawBalance(address _wallet) external onlyRole(ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        payable(_wallet).transfer(balance);
        delete balance;
    }

}