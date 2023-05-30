// SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.8.0 <=0.8.19;

import {ForjSoulboundERC1155} from  "contracts/utils/ForjSoulboundERC1155.sol";
import {ForjModifiers} from "contracts/utils/ForjModifiers.sol";
import {ForjCustomErrors} from "contracts/utils/ForjCustomErrors.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract SBTClaim is ForjSoulboundERC1155, ReentrancyGuard, ForjModifiers, ForjCustomErrors {

    using Strings for uint256;

    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public claimId;

    uint256 public mintedAmount;
    uint256 public totalSupply;
    uint256 public maxSupply;

    bool public initialized;
    bytes32 public merkleRoot;

    address public tradeContract;

    // User => ID => Amount
   mapping(address => mapping(uint256 => uint256)) public userMintedAmount;

   event TradeIn(address indexed user, uint256[] indexed ids, uint256[] indexed amounts);
   event Claim(address indexed user, uint256 indexed id, uint256 indexed amount);
   event Burn(address indexed user, uint256[] indexed ids, uint256[] indexed amounts);

    constructor(){}

    function initialize(
        address _multisig,
        string memory _baseURI,
        string memory _name,
        string memory _symbol,
        bytes32 _merkleRoot,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) public onlyAdminOrOwner(msg.sender) {
        if(initialized) revert AlreadyInitialized();

        multisig = _multisig;
        name = _name;
        symbol = _symbol;
        merkleRoot = _merkleRoot;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        baseURI = _baseURI;

        initialized = true;
    }

    function setMultiSig(address _multisig) public onlyAdminOrOwner(msg.sender){
        multisig = _multisig;
    }

    function setBaseURI(string memory _baseURI) public onlyAdminOrOwner(msg.sender){
        baseURI = _baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyAdminOrOwner(msg.sender){
        merkleRoot = _merkleRoot;
    }

    function setClaimPeriod(uint256 _startTimestamp, uint256 _endTimestamp) public onlyAdminOrOwner(msg.sender){
        if(_startTimestamp >= _endTimestamp) revert ClaimPeriodTooShort();

        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyAdminOrOwner(msg.sender){
        maxSupply = _maxSupply;
    }

    function setAdmin(address _admin) public onlyAdminOrOwner(msg.sender){
        isAdmin[_admin] = true;
    }

    function removeAdmin(address _admin) public onlyAdminOrOwner(msg.sender){
        isAdmin[msg.sender] = false;
    }

    function setTradeContractAddress(address _tradeContract) public onlyAdminOrOwner(msg.sender){
        tradeContract = _tradeContract;
    }

    function setClaimId(uint256 _claimId) public onlyAdminOrOwner(msg.sender){
        claimId = _claimId;
    }

    function claim(
        address user,
        uint256 amount,
        uint256 limitPerWallet,
        bytes32[] calldata merkleProof
    ) external payable onlyUnpaused(){
        if(user != _msgSender()) revert MsgSenderIsNotOwner();

        _checks(
            user,
            amount,
            limitPerWallet,
            merkleProof
        );
        
        _claimMint(user, amount);

        emit Claim(user, claimId, amount);
    }

    function trade(
        address from,  
        uint256[] memory ids, 
        uint256[] memory amounts
    ) public {
        if(ids.length != amounts.length) revert ArrayLengthsDiffer();
        if(from != _msgSender()) revert MsgSenderIsNotOwner();

        _safeBatchTransferFrom(from, tradeContract, ids, amounts, "");

        emit TradeIn(from, ids, amounts);
    }

    function burn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public {
        if(ids.length != amounts.length) revert ArrayLengthsDiffer();
        if(from != _msgSender()) revert MsgSenderIsNotOwner();

        for(uint256 i = 0; i < ids.length; i++){
            _burn(from, ids[i], amounts[i]);
            totalSupply -= amounts[i];
        }

        emit Burn(from, ids, amounts);
    }

    function uri(uint256 _tokenId) public view override returns (string memory){
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function _checks(
        address _mintAddress,
        uint256 _amount,
        uint256 _limitPerWallet,
        bytes32[] calldata _merkleProof
    ) internal view {
        if(mintedAmount + _amount > maxSupply) revert MaxSupplyReached();
        if(userMintedAmount[_mintAddress][claimId] + _amount > _limitPerWallet) revert MintLimitReached();
        if(startTimestamp > block.timestamp) revert CurrentlyNotClaimPeriod();
        if(endTimestamp < block.timestamp) revert CurrentlyNotClaimPeriod();

        if(!MerkleProof.verify(
            _merkleProof, 
            merkleRoot, 
            keccak256(abi.encodePacked(_mintAddress, _limitPerWallet))
        )) revert InvalidProof();
    }

    function _claimMint(address user, uint256 amount) internal {
        userMintedAmount[user][claimId] += amount;
        totalSupply += amount;
        mintedAmount += amount;

        _mint(user, claimId, amount, "");
    }
}