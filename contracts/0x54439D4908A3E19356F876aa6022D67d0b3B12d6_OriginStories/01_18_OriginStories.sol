// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PVERC721.sol";
import "./PVAllowlist.sol";

/*
* @title ERC721 token for Origin Stories #1
* @author Niftydude
*/
contract OriginStories is PVERC721, PVAllowlist {
    uint256 constant MAX_SUPPLY = 5902;
    uint256 constant MAX_SALE_SUPPLY = 5704;
    uint256 constant MINT_PRICE = 1e17;

    uint256 public purchaseWindowOpensPublic;

    uint256[] public stageWindows;  
    bytes32[] public merkleRoots;

    mapping(address => uint256) public purchased;

    constructor(
        string memory _name, 
        string memory _symbol,  
        string memory _uri,
        bytes32[] memory _merkleRoots,
        uint256[] memory _stageWindows,
        uint256 _purchaseWindowOpensPublic      
    ) PVERC721(_name, _symbol, _uri) {
        require(_stageWindows.length == _merkleRoots.length, "same length required");

        merkleRoots = _merkleRoots;
        stageWindows = _stageWindows;

        purchaseWindowOpensPublic = _purchaseWindowOpensPublic;

        _mint(0x580A96BC816C2324Bdff5eb2a7E159AE7ee63022, totalSupply() + 1);           
        _mint(0xcf3bC13C0F19B9549364CC5F4b7EA807b737C062, totalSupply() + 1);           
    } 

    modifier whenStageExists(uint256 stage) {
        require(
            stage < stageWindows.length, "stage does not exist"
        );
        _;
    }

    /**
    * @notice set merkle roots for each stage
    * 
    * @param _stage the index of the stage to change
    * @param _merkleRoot array containing all merkle roots
    */
    function editMerkleRoot(
        uint256 _stage,
        bytes32 _merkleRoot
    ) external onlyOwner whenStageExists(_stage) {
        merkleRoots[_stage] = _merkleRoot;
    }                       

    /**
    * @notice edit windows
    * 
    * @param _stage the index of the stage to change
    * @param _windowOpens UNIX timestamp for window opening time
    */
    function editStageWindows(
        uint256 _stage,
        uint256 _windowOpens     
    ) external onlyOwner whenStageExists(_stage) {   
        stageWindows[_stage] = _windowOpens;
    }

    /**
    * @notice edit window for public sale
    * 
    * @param _purchaseWindowOpensPublic UNIX timestamp for public purchase window opening time
    */
    function editPublicWindow(
        uint256 _purchaseWindowOpensPublic     
    ) external onlyOwner {         
        purchaseWindowOpensPublic = _purchaseWindowOpensPublic;       
    }

    /**
    * @notice mint function for contract owner
    * 
    * @param _to array of addresses to mint tokens to
    * @param _amount the amount of tokens to mint to address in _to parameter at same index
    */
    function ownerMint (address[] calldata _to, uint256[] calldata _amount) external onlyOwner {
        require(_to.length == _amount.length, "same length required");

        for(uint256 i; i < _to.length; i++) {
            require(totalSupply() + _amount[i] <= MAX_SUPPLY, "max owner supply exceeded");
            _mintMany(_to[i], _amount[i]);
        }
    }      

    /**
    * @notice purchase during early access sale
    * 
    * @param amount the amount to purchase
    * @param index the index of the merkle proof
    * @param maxAmount max amount user is eligible to mint
    * @param merkleProof the valid merkle proof of sender
    */
    function earlyAccessSale  (
        uint256 stage,
        uint256 amount,
        uint256 index,
        uint256 maxAmount,
        bytes32[] calldata merkleProof
    ) external payable 
       whenStageExists(stage) 
       whenInAllowlist(index, maxAmount, merkleProof, merkleRoots[stage]) 
    {
        require(block.timestamp >= stageWindows[stage], "stage not open yet"); 
        require(purchased[msg.sender] + amount <= maxAmount, "max purchase amount exceeded");

        _purchase(amount);
    }     

    /**
    * @notice purchase during public sale
    * 
    * @param amount the amount of tokens to purchase
    */
    function purchase(uint256 amount) external payable {
        require(block.timestamp >= purchaseWindowOpensPublic, "Purchase: window closed");
        require(purchased[msg.sender] + amount <= 5 , "max wallet amount exceeded");

        _purchase(amount);
    }

    function withdrawEther(address payable _to, uint256 _amount) external onlyOwner {
        _to.transfer(_amount);
    }  

    /**
    * @notice global purchase function used in early access and public sale
    * 
    * @param amount the amount of tokens to purchase
    */
    function _purchase(uint256 amount) private {
        require(totalSupply() + amount <= MAX_SALE_SUPPLY, "Purchase: Max supply reached");
        require(msg.value == amount * MINT_PRICE, "Purchase: Incorrect payment"); 
        require(amount > 0, "Cannot mint zero tokens");
        purchased[msg.sender] += amount;

        _mintMany(msg.sender, amount);          
    }   

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token. 
     */
    function tokenURI(uint256) public view override returns (string memory) {
        return uri;
    }             
}