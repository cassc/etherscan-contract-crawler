// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ForjSoulboundERC1155} from  "contracts/utils/ForjSoulboundERC1155.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ForjClaimLogic is ForjSoulboundERC1155 {

    bool public claimInitialized;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public mintedAmount;
    bytes32 public merkleRoot;

    address public tradeContract;

    mapping(address => mapping(uint256 => uint256)) public userMintedAmount;
    mapping(uint256 => bool) public claimIds;

    event TradeIn(address indexed user, uint256[] indexed ids, uint256[] indexed amounts);
    event Claim(address indexed user, uint256 indexed id, uint256 indexed amount);

    function _claimInitialize(
        bytes32 _merkleRoot,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256[] memory _claimIds
    ) internal onlyAdminOrOwner(msg.sender) {
        if(claimInitialized) revert AlreadyInitialized();
        merkleRoot = _merkleRoot;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        setClaimIds(_claimIds);
        claimInitialized = true;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyAdminOrOwner(msg.sender){
        merkleRoot = _merkleRoot;
    }

    function setClaimPeriod(uint256 _startTimestamp, uint256 _endTimestamp) public onlyAdminOrOwner(msg.sender){
        if(_startTimestamp >= _endTimestamp) revert ClaimPeriodTooShort();

        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
    }

    function setTradeContractAddress(address _tradeContract) public onlyAdminOrOwner(msg.sender){
        tradeContract = _tradeContract;
    }

    function setClaimIds(uint256[] memory _claimIds) public onlyAdminOrOwner(msg.sender){
        uint256 length = _claimIds.length;
        for(uint256 i = 0; i < length; i++){
            claimIds[_claimIds[i]] = true;
        }
    }

    function claim(
        address user,
        uint256 amount,
        uint256 limitPerWallet,
        bytes32[] calldata merkleProof,
        uint256 targetId
    ) external payable onlyUnpaused(){
        if(user != _msgSender()) revert MsgSenderIsNotOwner();

        _checks(
            user,
            amount,
            limitPerWallet,
            merkleProof,
            targetId
        );
        
        _claimMint(user, amount, targetId);

        emit Claim(user, targetId, amount);
    }

    function trade(
        address from,  
        uint256[] memory ids, 
        uint256[] memory amounts,
        bytes memory data
    ) public {
        if(ids.length != amounts.length) revert ArrayLengthsDiffer();
        if(from != _msgSender()) revert MsgSenderIsNotOwner();

        _safeBatchTransferFrom(from, tradeContract, ids, amounts, data);

        emit TradeIn(from, ids, amounts);
    }

    function _checks(
        address _mintAddress,
        uint256 _amount,
        uint256 _limitPerWallet,
        bytes32[] calldata _merkleProof,
        uint256 targetId
    ) internal view {
        if(mintedAmount + _amount > supplyPerId[targetId].max) revert MaxSupplyReached();
        if(userMintedAmount[_mintAddress][targetId] + _amount > _limitPerWallet) revert MintLimitReached();
        if(startTimestamp > block.timestamp) revert CurrentlyNotClaimPeriod();
        if(endTimestamp < block.timestamp) revert CurrentlyNotClaimPeriod();

        if(!MerkleProof.verify(
            _merkleProof, 
            merkleRoot, 
            keccak256(abi.encodePacked(_mintAddress, _limitPerWallet))
        )) revert InvalidProof();
    }

    function _claimMint(address user, uint256 amount, uint256 targetId) internal {
        require(claimIds[targetId], "Target ID Not Available For Claim");
        userMintedAmount[user][targetId] += amount;
        supplyPerId[targetId].total += amount;
        mintedAmount += amount;

        super._mint(user, targetId, amount, "");
    }
}