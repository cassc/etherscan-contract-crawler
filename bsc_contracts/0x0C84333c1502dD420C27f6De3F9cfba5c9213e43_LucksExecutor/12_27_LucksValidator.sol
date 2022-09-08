// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin contracts
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Openluck interfaces
import {TaskItem, TaskExt, TaskStatus, UserState} from "../interfaces/ILucksExecutor.sol";
import {ILucksHelper} from "../interfaces/ILucksHelper.sol";

library LucksValidator {
    
    using SafeMath for uint256;   
    using AddressUpgradeable for address;

    /**
     * @notice check the new task inputs
     */
    function checkNewTask(address user, TaskItem memory item) internal view returns(bool) { 

        require(item.seller != address(0) && item.seller == user, "seller");      
        require(item.nftChainId > 0, "nftChain");       
        require(item.tokenIds.length > 0, "tokenIds");
        require(block.timestamp < item.endTime, "endTime");
        require(item.endTime - block.timestamp > 84600 && item.endTime - block.timestamp < 2678400, "duration"); // at least 23.5 hour, 31 days limit
        require(item.price > 0 && item.price < item.targetAmount && item.targetAmount.mod(item.price) == 0,"price or targetAmount");

        uint num = item.targetAmount.div(item.price);
        require(num > 0 && num <= 100000 && num.mod(10) == 0, "num");

        require(item.amountCollected == 0, "collect");        

        return true;
    }

    function checkNewTaskNFTs(address seller, address nft, uint256[] memory tokenIds, uint256[] memory amounts,ILucksHelper HELPER) internal view {
        // check nftContract
        require(HELPER.checkNFTContract(nft), "nft");
        (bool checkState, string memory checkMsg) = HELPER.checkTokenListing(nft, seller, tokenIds, amounts);
        require(checkState, checkMsg);
    }

    function checkNewTaskExt(TaskExt memory ext) internal pure returns(bool) {
        require(bytes(ext.title).length >=0 && bytes(ext.title).length <= 256, "title");
        require(bytes(ext.note).length <= 256, "note");
        return true;
    }

    function checkNewTaskRemote(TaskItem memory item, ILucksHelper HELPER) internal view returns (bool) 
    {        
        if (address(item.exclusiveToken.token) != address(0) && item.exclusiveToken.amount > 0) {
            require(item.exclusiveToken.token.isContract(), "exclusive");
        }       
        require(HELPER.checkAcceptToken(item.acceptToken), "Unsupported acceptToken");
        uint256 minTarget = HELPER.getMinTargetLimit(item.acceptToken);
        require(minTarget == 0 || item.targetAmount >= minTarget, "target");
        return true;
    }

    function checkReCreateTask(       
        mapping(uint256 => TaskItem) storage tasks,
        mapping(address => mapping(uint256 => UserState)) storage userState,         
        uint256 taskId,
        TaskItem memory item, 
        TaskExt memory ext
        ) 
        internal view {

        TaskItem storage task = tasks[taskId];

        require(task.seller == msg.sender, "owner"); // only seller

        bool canReCreate = false;

        // checking state

        if((task.status == TaskStatus.Fail || (task.amountCollected < task.targetAmount && block.timestamp > task.endTime))
            && (userState[task.seller][taskId].claimed == false)) {
            // can Claim
            canReCreate = true;
        }else if((task.status == TaskStatus.Pending || task.status == TaskStatus.Open) && task.amountCollected == 0) {
            // can Cancel
            canReCreate = true;
        }     

        require(canReCreate, "state");
      
        // checking inputs
        require(task.nftChainId == item.nftChainId, "nftChain"); // action must start from NFTChain   
        require(task.nftContract == item.nftContract, "nft");
        require(keccak256(abi.encodePacked(task.tokenIds)) == keccak256(abi.encodePacked(item.tokenIds)), "tokenIds");
        require(keccak256(abi.encodePacked(task.tokenAmounts)) == keccak256(abi.encodePacked(item.tokenAmounts)), "tokenAmounts");
        require(task.seller == item.seller, "owner");
        require(task.depositId == item.depositId, "depositId");
                
        checkNewTask(msg.sender, item);
        checkNewTaskExt(ext);
    }

    function checkJoinTask(
        TaskItem storage item,
        address user, 
        uint32 num, 
        string memory note, 
        ILucksHelper HELPER) internal view returns(bool) {

        require(bytes(note).length <= 256, "Note len");
        require(HELPER.checkPerJoinLimit(num), "Join limit");                
        require(num > 0, "num");

        require(item.seller != user, "Not owner");
        require(block.timestamp >= item.startTime && block.timestamp <= item.endTime, "endTime");
        require(item.status == TaskStatus.Pending || item.status == TaskStatus.Open, "status");

        // Calculate number of TOKEN to this contract
        uint256 amount = item.price.mul(num);
        require(amount > 0, "amount");

        // check Exclusive
        if (address(item.exclusiveToken.token) != address(0) && item.exclusiveToken.amount > 0) {
            require(
                checkExclusive(user, address(item.exclusiveToken.token), item.exclusiveToken.amount),
                "Exclusive"
            );
        }

        return true;
    }

    function checkExclusive(address account, address token, uint256 amount) internal view returns (bool){
        if (amount > 0 && token.isContract()) {
            if (IERC165(token).supportsInterface(0x80ac58cd)) {
                return IERC721(token).balanceOf(account) >= amount;
            }
            return IERC20(token).balanceOf(account) >= amount;
        }

        return true;
    }
}