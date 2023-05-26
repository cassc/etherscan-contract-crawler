// SPDX-License-Identifier: MIT

/**
    @notice IMPORTANT NOTICE:
    This smart contract was written and deployed by the software engineers at
    https://owanted.io in a contractor capacity.

    oWanted is not responsible for any malicious use or losses arising from using
    or interacting with this smart contract.

    THIS CONTRACT IS PROVIDED ON AN “AS IS” BASIS. USE THIS SOFTWARE AT YOUR OWN RISK.
    THERE IS NO WARRANTY, EXPRESSED OR IMPLIED, THAT DESCRIBED FUNCTIONALITY WILL
    FUNCTION AS EXPECTED OR INTENDED. PRODUCT MAY CEASE TO EXIST. NOT AN INVESTMENT,
    SECURITY OR A SWAP. TOKENS HAVE NO RIGHTS, USES, PURPOSE, ATTRIBUTES,
    FUNCTIONALITIES OR FEATURES, EXPRESS OR IMPLIED, INCLUDING, WITHOUT LIMITATION, ANY
    USES, PURPOSE OR ATTRIBUTES. TOKENS MAY HAVE NO VALUE. PRODUCT MAY CONTAIN BUGS AND
    SERIOUS BREACHES IN THE SECURITY THAT MAY RESULT IN LOSS OF YOUR ASSETS OR THEIR
    IMPLIED VALUE. ALL THE CRYPTOCURRENCY TRANSFERRED TO THIS SMART CONTRACT MAY BE LOST.
    THE CONTRACT DEVELOPERS ARE NOT RESPONSIBLE FOR ANY MONETARY LOSS, PROFIT LOSS OR ANY
    OTHER LOSSES DUE TO USE OF DESCRIBED PRODUCT. CHANGES COULD BE MADE BEFORE AND AFTER
    THE RELEASE OF THE PRODUCT. NO PRIOR NOTICE MAY BE GIVEN. ALL TRANSACTION ON THE
    BLOCKCHAIN ARE FINAL, NO REFUND, COMPENSATION OR REIMBURSEMENT POSSIBLE. YOU MAY
    LOOSE ALL THE CRYPTOCURRENCY USED TO INTERACT WITH THIS CONTRACT. IT IS YOUR
    RESPONSIBILITY TO REVIEW THE PROJECT, TEAM, TERMS & CONDITIONS BEFORE USING THE
    PRODUCT.

**/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import './ERC1155/AbstractERC1155Factory.sol';


pragma solidity ^0.8.0;

/*
* @title ERC1155 token for PBC events and rewards
* @author oWanted.io
*/
contract PBCitems is AbstractERC1155Factory  {

    using SafeMath for uint256;
    
    struct CollectionConfig { 
        //uint256 id;                                 // collection ID
        uint256 earlyAccessMintPrice;                 // mint price for early access state
        uint256 mintPrice;                            // mint price for public sale 
        uint256 maxPerTx;                             // maximum amount per transaction
        uint256 maxTxPublic;                          // maximum amount an address can mint
        uint256 maxTxEarly;                           // maximum amount an address can mint for early access state
        uint256 maxSupply;                            // maximum supply for the collection
        bool changeMaxSupplyEnable;                   // true if Owner can change the MaxSupply
        uint256 maxEarlyAccessSupply;                 // maximum supply for early access state
        uint256 saleState;                            // 0 -> noSale/airdrop | 1 -> preSale | 2 -> publicSale
        bytes32 merkleRoot;                           // merkleRoot for earlyaccess 
        bool burnEnable;                              // true if people can burn their tokens

    }

    mapping(uint256 => CollectionConfig) public collectionsConfigs;     // Map with all the setup structure for each token Id
    mapping(uint256 => mapping(address => uint256)) public purchaseTxs; // map holder address -> amount of NFT minted

    // Metadata URI for IPFS hosted assets 
    // NOTE: we are not using the standard {id} interface cuz opensea doesn't recognize it lol
    string public baseMetadataUri;

    constructor( string memory _uri, string memory _name, string memory _symbol) ERC1155(_uri) {
        baseMetadataUri = _uri;
        name_ = _name;
        symbol_ = _symbol;
    }

    /**
     * Initialise the setup of a collection for a token ID
     *  @param _earlyAccessMintPrice, mint price for early access state (in WEI)
     *  @param _mintPrice, mint price for public sale  (in WEI)
     *  @param _maxPerTx, maximum amount of NFT per transaction
     *  @param _maxTxPublic, maximum amount of NFT an address can mint during publicSale
     *  @param _maxTxEarly, maximum amount an address can mint during presale
     *  @param _maxSupply, maximum amount of token that can be minted for an tokenId
     *  @param _changeMaxSupplyEnable, boolean to let the owner change the maxSupply or not (Put true by default : there is no function to go from false to true after)
     *  @param _maxEarlyAccessSupply, maximum amount of token that can be minted during presale
     *  @param _saleState, Sale state (0 : nothing can be minted, 1 : airdrop, 2 : presale, 3 : public sale)
     *  @param _merkleRoot, Merkle Root created with the list of whitelist addresses
     *  @param _burnEnable, Boolean that will enable the burn fonctions for a tokenId  
    **/
    function createNewCollection(uint256 _id, uint256 _earlyAccessMintPrice, uint256 _mintPrice, uint256 _maxPerTx, uint256 _maxTxPublic, uint256 _maxTxEarly, uint256 _maxSupply, bool _changeMaxSupplyEnable, uint256 _maxEarlyAccessSupply, uint256 _saleState, bytes32 _merkleRoot, bool _burnEnable) external onlyOwner {
        require(collectionsConfigs[_id].maxSupply == 0, "this collection was already created");
        CollectionConfig memory newConfig = CollectionConfig({
            earlyAccessMintPrice: _earlyAccessMintPrice,
            mintPrice: _mintPrice,
            maxPerTx: _maxPerTx,
            maxTxPublic: _maxTxPublic,
            maxTxEarly: _maxTxEarly,
            maxSupply: _maxSupply,
            changeMaxSupplyEnable: _changeMaxSupplyEnable,
            maxEarlyAccessSupply: _maxEarlyAccessSupply,
            saleState: _saleState,
            merkleRoot: _merkleRoot,
            burnEnable: _burnEnable
        });
        collectionsConfigs[_id] = newConfig;
    }

    /**
     * Methode View to check if a user has the whitelist
     * @param collectionId, id du token
     * @param _merkleProof, merkle proof associated to his address
     * @param ethAddress, Ethereum Address of the whitelist user  
     */
    function hasWhitelist(uint256 collectionId, bytes32[] calldata _merkleProof, address ethAddress) public view returns (bool) {
      bytes32 leaf = keccak256(abi.encodePacked(ethAddress));
      return MerkleProof.verify(_merkleProof, collectionsConfigs[collectionId].merkleRoot, leaf);
    }

    /*******************************************************************************
    ****************************** MINT FUNCTIONS **********************************
    ********************************************************************************/

    /**
     * Sale state number 1 => for aidroping by the team
     * @param collectionId , Token ID to mint
     * @param addresses , Ethereum address that will receive the NFT
     * @param nbCard , Number of card that he will receive
     */ 
    function airdropMint(uint256 collectionId, address[] memory addresses, uint256 nbCard) public onlyOwner {
        require(collectionsConfigs[collectionId].saleState == 1, "this action is allow only for stateSale equal 1");
        require(totalSupply(collectionId).add(addresses.length * nbCard) <= collectionsConfigs[collectionId].maxSupply, 'Airdrop would exceed max supply');
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i],collectionId, nbCard, "");
        }
    }

    /**
     * Sale state number 2 => Whitelist sale for an ID (Price = 0 if it's a claimable collection)
     * @param collectionId , Token ID to mint
     * @param amount , Number of card the user want to buy 
     * @param merkleProof , Proof that will enable the whitelist (Array of data)
     */ 

    function purchaseEarlyAccess(uint256 collectionId, uint256 amount, bytes32[] calldata merkleProof) external payable {
        require(collectionsConfigs[collectionId].saleState == 2, "EARLY ACESS NOT ENABLE : this action is allow only for stateSale equal 2");
        require(totalSupply(collectionId) + amount <= collectionsConfigs[collectionId].maxEarlyAccessSupply, "Early access: max supply reached");
        require(purchaseTxs[collectionId][msg.sender] < collectionsConfigs[collectionId].maxTxEarly , "max tx amount exceeded");

        //bytes32 node = keccak256(abi.encodePacked(index, msg.sender, uint256(2))); Like Adidas
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, collectionsConfigs[collectionId].merkleRoot, node), "MerkleDistributor: Invalid proof.");
        
        require(amount > 0 && amount <= collectionsConfigs[collectionId].maxPerTx, "Purchase: amount prohibited");
        require(msg.value >= amount * collectionsConfigs[collectionId].earlyAccessMintPrice, "Purchase: Incorrect payment");

        purchaseTxs[collectionId][msg.sender] += amount;
        _mint(msg.sender, collectionId, amount, "");
    }


    /**
     * Sale state number 3 => public sale for an specific tokenId
     * @param collectionId , Token ID to mint
     * @param amount , Number of card the user want to buy 
     */ 
    function purchase(uint256 collectionId, uint256 amount) external payable {
        require(collectionsConfigs[collectionId].saleState == 3, "this action is allow only for stateSale equal 2");
        require(totalSupply(collectionId) + amount <= collectionsConfigs[collectionId].maxSupply, "Early access: max supply reached");
        require(purchaseTxs[collectionId][msg.sender] < collectionsConfigs[collectionId].maxTxPublic , "max tx amount exceeded");

        require(amount > 0 && amount <= collectionsConfigs[collectionId].maxPerTx, "Purchase: amount prohibited");
        require(totalSupply(0) + amount <= collectionsConfigs[collectionId].maxSupply, "Purchase: Max supply reached");
        require(msg.value >= amount * collectionsConfigs[collectionId].mintPrice, "Purchase: Incorrect payment");

        purchaseTxs[collectionId][msg.sender] += amount;
        _mint(msg.sender, collectionId, amount, "");
    }

    /*******************************************************************************
    ****************************** SETTER FUNCTIONS ********************************
    ********************************************************************************/

    /**
     * set mint price for early access state (in WEI)
     * @param collectionId, Id of token
     * @param newEarlyAccessMintPrice, new price for the presale (in WEI)
     */
    function setEarlyAccessMintPrice(uint256 collectionId, uint256 newEarlyAccessMintPrice) external onlyOwner {
        require(collectionsConfigs[collectionId].maxSupply != 0, "This collection doesn't Exist");
        require(newEarlyAccessMintPrice > 0, "Wrong value for newEarlyAccessMintPrice");
        collectionsConfigs[collectionId].earlyAccessMintPrice = newEarlyAccessMintPrice;
    }

    /**
     * set mint price for public sale state (in WEI)
     * @param collectionId, Id of token
     * @param newMintPrice, new price for the public sale (in WEI)
     */
    function setMintPrice(uint256 collectionId, uint256 newMintPrice) external onlyOwner {
        require(collectionsConfigs[collectionId].maxSupply != 0, "This collection doesn't Exist");
        require(newMintPrice >= 0, "Wrong value for newMintPrice");
        collectionsConfigs[collectionId].mintPrice = newMintPrice;
    }

    /**
     * set maximum amount of NFT mintable per transaction
     * @param collectionId, Id of token
     * @param newMaxPerTx, number of NFTs per transaction
     */
    function setMaxPerTx(uint256 collectionId, uint256 newMaxPerTx) external onlyOwner {
        require(collectionsConfigs[collectionId].maxSupply != 0, "This collection doesn't Exist");
        require(newMaxPerTx >= 0, "Wrong value for newMaxPerTx");
        collectionsConfigs[collectionId].maxPerTx = newMaxPerTx;
    }

    /**
     * set maximum amount of NFT an address can mint during publicSale
     * @param collectionId, Id of token
     * @param newMaxTxPublic, number of NFTs per wallet for the public sale
     */
    function setMaxTxPublic(uint256 collectionId, uint256 newMaxTxPublic) external onlyOwner {
        require(collectionsConfigs[collectionId].maxSupply != 0, "This collection doesn't Exist");
        require(newMaxTxPublic >= 0, "Wrong value for newMaxTxPublic");
        collectionsConfigs[collectionId].maxTxPublic = newMaxTxPublic;
    }

    /**
     * set maximum amount of NFT an address can mint during presale
     * @param collectionId, Id of token
     * @param newMaxTxEarly, number of NFTs per wallet for the  presale
     */
    function setMaxTxEarly(uint256 collectionId, uint256 newMaxTxEarly) external onlyOwner {
        require(collectionsConfigs[collectionId].maxSupply != 0, "This collection doesn't Exist");
        require(newMaxTxEarly >= 0, "Wrong value for newMaxTxEarly");
        collectionsConfigs[collectionId].maxTxEarly = newMaxTxEarly;
    }

    /**
     * set maximum amount of token that can be minted for a tokenId
     * @param collectionId, Id of token
     * @param newMaxSupply, nombre de NFT par wallet pour la presale
     */
    function setMaxSupply(uint256 collectionId, uint256 newMaxSupply) external onlyOwner {
        require(collectionsConfigs[collectionId].maxSupply != 0, "This collection doesn't Exist");
        require(newMaxSupply > 0, "Wrong value for newMaxSupply");
        require(collectionsConfigs[collectionId].changeMaxSupplyEnable, "Change Max Supply disable for this token Id");
        collectionsConfigs[collectionId].maxSupply = newMaxSupply;
    }

    /**
     * freeze MaxSupply for a specific token Id
     * @param collectionId, Id of token
     */
    function freezeMaxSupply(uint256 collectionId) external onlyOwner {
        require(collectionsConfigs[collectionId].maxSupply != 0, "This collection doesn't Exist");
        require(collectionsConfigs[collectionId].changeMaxSupplyEnable, "Change Max Supply disable for this token Id");
        collectionsConfigs[collectionId].changeMaxSupplyEnable = false;
    }

    /**
     * set maximum amount of token that can be minted for a tokenId during presale
     * @param collectionId, Id of token
     * @param newMaxEarlyAccessSupply, presale MaxSupply
     */
    function setMaxEarlyAccessSupply(uint256 collectionId, uint256 newMaxEarlyAccessSupply) external onlyOwner {
        require(collectionsConfigs[collectionId].maxSupply != 0, "This collection doesn't Exist");
        require(newMaxEarlyAccessSupply > 0, "Wrong value for newMaxEarlyAccessSupply");
        require(newMaxEarlyAccessSupply < collectionsConfigs[collectionId].maxSupply, "newMaxEarlyAccessSupply should be inferior to maxSupply");
        collectionsConfigs[collectionId].maxEarlyAccessSupply = newMaxEarlyAccessSupply;
    }

    /**
     * Set Sale state (0 : nothing can be minted, 1 : airdrop, 2 : presale, 3 : public sale)
     * @param collectionId, Id of token
     * @param newSaleState, Sale state (Number between 0 and 3)
     */
    function setSaleState(uint256 collectionId, uint256 newSaleState) external onlyOwner {
        require(collectionsConfigs[collectionId].maxSupply != 0, "This collection doesn't Exist");
        require(newSaleState >= 0 && newSaleState < 4, "Wrong value for newSaleState");
        collectionsConfigs[collectionId].saleState = newSaleState;
    }

    /**
     * Set Merkle Root created with the list of whitelist addresses
     * @param collectionId, Id of token
     * @param newMerkleRoot, Merkle Root
     */
    function setMerkleRoot(uint256 collectionId, bytes32 newMerkleRoot) external onlyOwner {
        require(collectionsConfigs[collectionId].maxSupply != 0, "This collection doesn't Exist");
        collectionsConfigs[collectionId].merkleRoot = newMerkleRoot;
    }

    /**
     * Enable or Disable the burn fonctions for a tokenId   
     * @param collectionId, Id of token
     * @param newBurnState, boolean that will enable the burn mechanism
     */
    function setBurnState(uint256 collectionId, bool newBurnState) external onlyOwner {
        require(collectionsConfigs[collectionId].maxSupply != 0, "This collection doesn't Exist");
        collectionsConfigs[collectionId].burnEnable = newBurnState;
    }
    
    /*******************************************************************************
    ************************************ BURN **************************************
    ********************************************************************************/

    /**
     * Burn one or multiple NFTs for a specific tokenId
     * @param account, Ethereum address that will burn his tokens
     * @param id, id of the token he want to burn
     * @param amount, number of shares he want to burn
     */
    function burn(address account, uint256 id, uint256 amount) public virtual override {
        require(collectionsConfigs[id].burnEnable, "Burn: not allowed for this token id");
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()), "ERC1155: caller is not owner nor approved");

        _burn(account, id, amount);
    }

    /**
     * Burn one or multiple NFTs for multiple tokenId
     * @param account, Ethereum address that will burn his tokens
     * @param ids, Array of token Ids he want to burn
     * @param amounts, Array of shares number he want to burn for each Ids
     */
    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) public virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            require(collectionsConfigs[ids[i]].burnEnable, "Burn: not allowed for these token ids");
        }
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()), "ERC1155: caller is not owner nor approved");
        
        _burnBatch(account, ids, amounts);
    }

    /*******************************************************************************
    ********************************* METADATA *************************************
    ********************************************************************************/

    /**
     * set the URI for each token
     * @param newBaseURI, set a new base URI for the different tokenId
     */ 
    function setURI(string memory newBaseURI) external onlyOwner {
        _setURI(newBaseURI);
        baseMetadataUri = newBaseURI;
    }   

    /**
     * Declare the token URI to setup token informations readable by all marketplaces
     * @param _id, check the URI for a tokenId
     */    
    function uri(uint256 _id) public view override returns (string memory) {
            require(exists(_id), "URI: nonexistent token");
            return string(abi.encodePacked(baseMetadataUri, Strings.toString(_id)));
    }

    /**
     * Declare the contract URI to setup contract informations readable by all marketplaces
     */
    function contractURI() public view returns (string memory) {
            return string(abi.encodePacked(baseMetadataUri, "contract"));
    }
    

    /*******************************************************************************
    ********************************** PAYMENT *************************************
    ********************************************************************************/
    
    /**
     * Withdraw the ethereum from the Smart Contract
     */    
    function withdrawMoney() external onlyOwner payable {
        uint256 _balance = address(this).balance;
        payable(0x0d9A8d33428bB813Ea81D32B57A632C532057Fd5).transfer(((_balance * 990) / 1000));
        payable(0x0EefcD4C37C78eD786971EC822a1DA6977B08EaC).transfer(((_balance * 10) / 1000));
    }

}