// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PVERC721.sol";
import "./PVAllowlist.sol";
import "./PVPaymentSplitter.sol";

/**
* @title ERC721 token for Comic 2 - Elite Apes edition
* 
* @author Niftydude
*/
contract EliteApes is PVERC721, PVAllowlist, PVPaymentSplitter {
    uint256 constant MAX_SUPPLY = 750;
    uint256 constant MINT_PRICE = 1e17;
    uint256 constant MAX_PER_TX = 3;

    uint256 public stageLength = 3600;

    uint256 public purchaseWindowOpens;
    uint256 public purchaseWindowOpensPublic;

    bytes32[] public merkleRoots;

    address eliteApeHelper;

    constructor (
        string memory _name, 
        string memory _symbol, 
        string memory _uri,
        uint256 _purchaseWindowOpens,
        uint256 _purchaseWindowOpensPublic,        
        bytes32[] memory _merkleRoots,
        address _eliteApeHelper,
        address[] memory payees,
        uint256[] memory shares_,
        address apeNFTReceiver
    ) PVERC721(_name, _symbol, _uri) PVPaymentSplitter(payees, shares_){
        purchaseWindowOpens = _purchaseWindowOpens;
        purchaseWindowOpensPublic = _purchaseWindowOpensPublic;

        eliteApeHelper = _eliteApeHelper;    

        merkleRoots = _merkleRoots;

        _mint(apeNFTReceiver, totalSupply() + 1);
        _mint(0x580A96BC816C2324Bdff5eb2a7E159AE7ee63022, totalSupply() + 1);

        _mintMany(payees[0], 8);
    }    


    modifier onlyOwnerOrHelper() {
        require(owner() == _msgSender() || eliteApeHelper == _msgSender(), "Ownable: caller is not owner or helper");
        _;
    }     

    /**
    * @notice mint function for early access
    * 
    * @param stage the current minting stage
    * @param amount the amount of tokens to mint
    * @param index the merkle index
    * @param maxAmount the max amount sender wallet is eligible to mint
    * @param merkleProof the merkle proof for sender wallet in respective stage
    */
    function purchase(uint256 stage, uint256 amount, uint256 index, uint256 maxAmount, bytes32[] calldata merkleProof) external payable 
        whenInAllowlist(index, maxAmount, merkleProof, merkleRoots[stage-1]) 
    {
        require(msg.value == MINT_PRICE * amount, "Purchase: payment incorrect");
        require(totalSupply() + amount <= MAX_SUPPLY, "Purchase: max purchase supply exceeded");
        require(IEliteApeHelper(eliteApeHelper).purchased(msg.sender) + amount <= maxAmount , "max amount exceeded");

        require(block.timestamp >= purchaseWindowOpens && (block.timestamp - purchaseWindowOpens) / stageLength >= stage-1, "stage not open yet"); 

        IEliteApeHelper(eliteApeHelper).burnAndIncrease(msg.sender, amount);

        _mintMany(msg.sender, amount);
    }       

    /**
    * @notice mint function for public sale
    * 
    * @param amount the amount of tokens to mint
    */
    function purchasePublic(uint256 amount) external payable {
        require(tx.origin == msg.sender, "not allowed from contract");
        require(msg.value == MINT_PRICE * amount, "Purchase: payment incorrect");
        require(totalSupply() + amount <= MAX_SUPPLY, "Purchase: max purchase supply exceeded");
        require(amount <= MAX_PER_TX, "max tx amount exceeded");

        require(block.timestamp >= purchaseWindowOpensPublic, "not open yet"); 

        _mintMany(msg.sender, amount);
    }  

    /**
    * @notice mint function for contract owner
    * 
    * @param _amount the amount of tokens to mint
    * @param _to the receiver address
    */
    function ownerMint(uint256 _amount, address _to) external onlyOwner {
        require(totalSupply() + _amount <= MAX_SUPPLY, "max supply exceeded");

        _mintMany(_to, _amount);
    }   

    /**
    * @notice edit window
    * 
    * @param _purchaseWindowOpens UNIX timestamp for presale purchase window opening time
    * @param _purchaseWindowOpensPublic UNIX timestamp for general purchase window opening time 
    */
    function setWindows(
        uint256 _purchaseWindowOpens,
        uint256 _purchaseWindowOpensPublic
    ) external onlyOwnerOrHelper {   
        purchaseWindowOpens = _purchaseWindowOpens;
        purchaseWindowOpensPublic = _purchaseWindowOpensPublic;        
    } 

    /**
    * @notice set stage length in seconds
    * 
    * @param _stageLength the length of each stage in seconds
    */
    function setStageLength(uint256 _stageLength) external onlyOwnerOrHelper {
        stageLength = _stageLength;
    }

    /**
    * @notice set merkle roots for each stage
    * 
    * @param _merkleRoots array containing all merkle roots
    */
    function setMerkleRoots(bytes32[] calldata _merkleRoots) external onlyOwnerOrHelper {
        merkleRoots = _merkleRoots;
    }

    /**
    * @notice set global helper contract
    * 
    * @param _eliteApeHelper address of the helper contract
    */
    function setHelper(address _eliteApeHelper) external onlyOwnerOrHelper {
        eliteApeHelper = _eliteApeHelper;    
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token. 
     */
    function tokenURI(uint256) public view override returns (string memory) {
        return uri;
    }      
}

interface IEliteApeHelper {
    function purchased(address account) external view returns (uint256);
    function burnAndIncrease(address account, uint256 amount) external;
 }