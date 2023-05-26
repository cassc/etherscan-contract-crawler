// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

import "./PVAllowlist.sol";
import "./PvERC1155.sol";

/*
* @title ERC1155 token for WAGMI
*/
contract WagmiUnited is PvERC1155, PVAllowlist, PaymentSplitter  {

    uint256 public constant maxSupply = 12000;
    uint256 public constant mintPrice = 0.35 ether;

    uint256 public maxPerTx = 5;
    uint256 public tokenIdToMint = 2;

    uint256 public publicWindowOpens;
    uint256 public mintingWindowCloses;
    uint256 public burnWindowOpens;
    uint256 public burnWindowCloses;

    mapping(address => uint256) public purchased;

    uint256[] public stageWindows;  
    bytes32[] public merkleRoots;

    event Redeemed(uint256 indexed idToRedeem, uint256 indexed idToMint, address indexed account, uint256 amount);

    constructor(
        string memory _name, 
        string memory _symbol,  
        string memory _uri,
        bytes32[] memory _merkleRoots,
        uint256[] memory _stageWindows,
        uint256 _mintingWindowCloses,
        address[] memory payees,
        uint256[] memory shares_
    ) PvERC1155(_name, _symbol, _uri) PaymentSplitter(payees, shares_) {
        require(_stageWindows.length == _merkleRoots.length, "same length required");

        mintingWindowCloses = _mintingWindowCloses;

        merkleRoots = _merkleRoots;
        stageWindows = _stageWindows;

        _mint(msg.sender, 1, 158, "");
    } 

    modifier whenStageExists(uint256 stage) {
        require(
            stage < stageWindows.length, "stage does not exist"
        );
        _;
    }

    /**
    * @notice set card id that can be minted by burning previous cards
    */
    function startNextPhase() external onlyOwner {
        tokenIdToMint += 1;    
    }    

    /**
    * @notice emergency function to return to previous stage
    */
    function returnToPreviousPhase() external onlyOwner {
        require(tokenIdToMint > 2, "Cannot go below phase 1");

        tokenIdToMint -= 1;    
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
    * @notice edit minting window
    * 
    * @param _mintingWindowCloses UNIX timestamp for minting window closing time
    */
    function editMintingWindow(
        uint256 _mintingWindowCloses       
    ) external onlyOwner {         
        mintingWindowCloses = _mintingWindowCloses;  
    }

    /**
    * @notice edit mint price
    * 
    * @param _maxPerTx max mint amount per tx
    */
    function editMaxPerTx(
        uint256 _maxPerTx    
    ) external onlyOwner {         
        maxPerTx = _maxPerTx;  
    }

    /**
    * @notice edit public window
    * 
    * @param _publicWindowOpens UNIX timestamp for public window opening time
    */
    function editPublicWindow(
        uint256 _publicWindowOpens       
    ) external onlyOwner {         
        publicWindowOpens = _publicWindowOpens;  
    }

    /**
    * @notice edit burn windows
    * 
    * @param _burnWindowOpens UNIX timestamp for burn window opening time
    * @param _burnWindowCloses UNIX timestamp for burn window closing time
    */
    function editBurnWindow(
        uint256 _burnWindowOpens,
        uint256 _burnWindowCloses        
    ) external onlyOwner {         
        burnWindowOpens = _burnWindowOpens;
        burnWindowCloses = _burnWindowCloses;        
    }

    /**
    * @notice allowlisted mint function
    * 
    * @param stage the stage to mint in 
    * @param amount the amount of tokens to purchase
    * @param amount max amount of tokens wallet is eligible to purchase
    * @param index the index of the merkle proof
    * @param merkleProof the valid merkle proof of sender
    */
    function mint(
        uint256 stage,
        uint256 amount,
        uint256 maxAmount,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable whenStageExists(stage) whenInAllowlist(index, maxAmount, merkleProof, merkleRoots[stage]) {
        require(purchased[msg.sender] + amount <= maxAmount && amount > 0, "max amount exceeded");
        require(block.timestamp > stageWindows[stage] && block.timestamp < mintingWindowCloses, "minting closed"); 
        require(totalSupply(1) + amount <= maxSupply, "Purchase: Max supply reached");
        require(msg.value == amount * mintPrice, "Purchase: Incorrect payment"); 

        unchecked {
            purchased[msg.sender] += amount;
        }

        _mint(msg.sender, 1, amount, "");
    }     

    /**
    * @notice purchase during public sale
    * 
    * @param amount the amount of tokens to purchase
    */
    function publicMint(uint256 amount) external payable {
        require(amount > 0 && amount <= maxPerTx, "max amount exceeded");
        require(msg.value == amount * mintPrice, "Purchase: Incorrect payment"); 
        require(totalSupply(1) + amount <= maxSupply, "Purchase: Max supply reached");

        require(block.timestamp > publicWindowOpens && block.timestamp < mintingWindowCloses, "Purchase: window closed");

        _mint(msg.sender, 1, amount, "");
    }

    /**
    * @notice redeem tokens for future phase
    * 
    * @param tokenIdToRedeem the token id to redeem
    * @param amount the amount of tokens to redeem
    */
    function redeem(uint256 tokenIdToRedeem, uint256 amount) external {
        require(amount > 0, "Redeem: amount not allowed");
        require(block.timestamp > burnWindowOpens && block.timestamp < burnWindowCloses, "Redeem: window closed");
        require(tokenIdToRedeem < tokenIdToMint, "Redeem: cannot be redeemed");

        _burn(msg.sender, tokenIdToRedeem, amount);
        _mint(msg.sender, tokenIdToMint, amount, "");

        emit Redeemed(tokenIdToRedeem, tokenIdToMint, msg.sender, amount);       
    }

    /**
     * @notice Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     * 
     * @param account the payee to release funds for
     */
    function release(address payable account) public override {
        require(msg.sender == account || msg.sender == owner(), "Release: no permission");

        super.release(account);
    }   

    /**
     * @notice Mints the given amount of token id 0 to specified receiver address
     * 
     * @param _receiver the receiving wallet
     * @param _amount the amount of tokens to mint
     */
    function ownerMint(address _receiver, uint256 _amount) external onlyOwner {
        require(totalSupply(1) + _amount <= maxSupply, "Purchase: Max supply reached");

        _mint(_receiver, 1, _amount, "");        
    }     

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }      

    /**
    * @notice returns the metadata uri for a given id
    * 
    * @param _id the card id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
            require(exists(_id), "URI: nonexistent token");
            
            return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }    
}