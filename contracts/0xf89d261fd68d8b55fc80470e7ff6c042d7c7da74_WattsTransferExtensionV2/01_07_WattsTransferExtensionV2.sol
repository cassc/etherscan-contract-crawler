// SPDX-License-Identifier: MIT
// Developed by KG Technologies (https://kgtechnologies.io)

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract IBreedingContract {
    /**
     * @notice function to set the merkle root for breeding.
     *
     * @param _merkleRoot. The new merkle root to set.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external {}

    /**
     * @notice function to turn on/off breeding.
     *
     * @param _status. The new state of the breeding.
     */
    function setBreedingStatus(bool _status) external {}    

    /**
     * @notice function to set the maximum amount of juniors that can be bred.
     *
     * @param max. The new maximum.
     */
    function setMaxBreedableJuniors(uint256 max) external {}

    /**
     * @notice function to set the cooldown period for breeding a slotie.
     *
     * @param coolDown. The new cooldown period.
     */
    function setBreedCoolDown(uint256 coolDown) external {}

    /**
     * @notice function to set the watts price for breeding two sloties.
     *
     * @param price. The new watts price.
     */
    function setBreedPice(uint256 price) external {}

    /**
     * @dev WATTS OWNER
     */

    function WATTSOWNER_TransferOwnership(address newOwner) external {}

    function WATTSOWNER_SetSlotieNFT(address newSlotie) external {}

    function WATTSOWNER_SetLockPeriod(uint256 newLockPeriod) external {}

    function WATTSOWNER_SetIsBlackListed(address _set, bool _is) external {}

    function WATTSOWNER_seeClaimableBalanceOfUser(address user) external view returns (uint256) {}

    function WATTSOWNER_seeClaimableTotalSupply() external view returns (uint256) {}

    function transferOwnership(address newOwner) public {}
}

abstract contract IWatts is IERC20 {
    function burn(address _from, uint256 _amount) external {}
    function seeClaimableBalanceOfUser(address user) external view returns(uint256) {}
    function seeClaimableTotalSupply() external view returns(uint256) {}
    function burnClaimable(address _from, uint256 _amount) public {}
    function mintClaimable(address _to, uint256 _amount) public {}
    function transferOwnership(address newOwner) public {}
    function setSlotieNFT(address newSlotieNFT) external {}
    function setLockPeriod(uint256 newLockPeriod) external {}
    function setIsBlackListed(address _address, bool _isBlackListed) external {}
}

abstract contract ISlotie is IERC721 {
    function nextTokenId() external view returns(uint256){}
}

/**
 * @title WattsTransferExtensionV2.
 *
 * @author KG Technologies (https://kgtechnologies.io).
 *
 * @notice This Smart Contract extends on the WATTS ERC-20 token with transfer functionality.
 *
 */
contract WattsTransferExtensionV2 is Ownable {

    /** 
     * @notice The Smart Contract of Watts.
     * @dev ERC-20 Smart Contract 
     */
    IWatts public watts;

    /** 
     * @notice The Breeding Contract.
     * @dev Breeding Smart Contract 
     */
    IBreedingContract public breeding;

    /** 
     * @notice The Slotie Contract.
     * @dev Slotie Smart Contract 
     */
    ISlotie public slotie;

    mapping(address => bool) public blackListedRecipients;

    /**
     * @dev Events
     */
    
    event transferFromExtension(address indexed sender, address indexed recipient, uint256 claimableTransfered, uint256 balanceTransfered);
    event blackListRecipientEvent(address indexed recipient, bool indexed shouldBlackList);
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event WithdrawAllEvent(address indexed recipient, uint256 amount);

    constructor(
        address slotieAddress,
        address wattsAddress,
        address breedingAddress
    ) Ownable() {
        slotie = ISlotie(slotieAddress);
        watts = IWatts(wattsAddress);
        breeding = IBreedingContract(breedingAddress);

        blackListedRecipients[0x1C075F1c3083F67add5FFAb240DE1f604F978E83] = true; // Sushiswap WETH-WATTS LP Pair
    }
 
    /**
     * @dev TRANSFER
     */

    /**
     * @dev Allows users to transfer accumulated watts
     * to other addresses.
     */
    function transfer(
        uint256 amount,
        address recipient
    ) external {
        require(address(watts) != address(0), "WATTS ADDRESS NOT SET");
        require(watts.balanceOf(msg.sender) >= amount, "TRANSFER EXCEEDS BALANCE");
        require(amount > 0, "CANNOT TRANSFER 0");
        require(!blackListedRecipients[recipient], "RECIPIENT BLACKLISTED");
        
        uint256 claimableBalance = breeding.WATTSOWNER_seeClaimableBalanceOfUser(msg.sender);
        uint256 transferFromClaimable = claimableBalance >= amount ? amount : claimableBalance;
        uint256 transferFromBalance = claimableBalance >= amount ? 0 : amount - claimableBalance;

        require(watts.allowance(msg.sender, address(this)) >= transferFromBalance, "AMOUNT EXCEEDS ALLOWANCE");

        if (claimableBalance > 0) {
            watts.burnClaimable(msg.sender, transferFromClaimable);
            watts.mintClaimable(recipient, transferFromClaimable);
        }
        
        if (transferFromBalance > 0) {
            watts.transferFrom(msg.sender, recipient, transferFromBalance);
        }

        emit transferFromExtension(msg.sender, recipient, transferFromClaimable, transferFromBalance);
    }  

    /**
     * @dev SLOTIE ENUMERABLE EXTENSION
     */
    function slotieWalletOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 _balance = slotie.balanceOf(owner);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = slotie.nextTokenId();
        for (uint i = 1; i < _loopThrough; i++) {
            if (slotie.ownerOf(i) == address(0x0) && _tokens[_balance - 1] == 0) {
                _loopThrough++;
            }
            if (slotie.ownerOf(i) == owner) {
                _tokens[_index] = i;
                _index++;
            }
        }
        return _tokens;
    }

    /** 
     * @dev OWNER ONLY 
     */

    /**
     * @dev Method to blacklist or whitelist
     * an address from receiving WATTS
     */
    function blackListRecipient(address recipient, bool shouldBlackList) external onlyOwner {
        blackListedRecipients[recipient] = shouldBlackList;
        emit blackListRecipientEvent(recipient, shouldBlackList);
    }

    /**
     * @notice function to set the merkle root for breeding.
     *
     * @param _merkleRoot. The new merkle root to set.
     */
    function BREEDOWNER_setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        breeding.setMerkleRoot(_merkleRoot);
    }

    /**
     * @notice function to turn on/off breeding.
     *
     * @param _status. The new state of the breeding.
     */
    function BREEDOWNER_setBreedingStatus(bool _status) external onlyOwner {
        breeding.setBreedingStatus(_status);
    }    

    /**
     * @notice function to set the maximum amount of juniors that can be bred.
     *
     * @param max. The new maximum.
     */
    function BREEDOWNER_setMaxBreedableJuniors(uint256 max) external onlyOwner {
        breeding.setMaxBreedableJuniors(max);
    }

    /**
     * @notice function to set the cooldown period for breeding a slotie.
     *
     * @param coolDown. The new cooldown period.
     */
    function BREEDOWNER_setBreedCoolDown(uint256 coolDown) external onlyOwner {
        breeding.setBreedCoolDown(coolDown);
    }

    /**
     * @notice function to set the watts price for breeding two sloties.
     *
     * @param price. The new watts price.
     */
    function BREEDOWNER_setBreedPice(uint256 price) external onlyOwner {
        breeding.setBreedPice(price);
    }

    function BREEDOWNER_TransferOwnership(address newOwner) external onlyOwner {
        breeding.transferOwnership(newOwner);   
    }

    /**
     * @dev WATTS OWNER
     */


    function WATTSOWNER_TransferOwnership(address newOwner) external onlyOwner {
        breeding.WATTSOWNER_TransferOwnership(newOwner);
    }

    function WATTSOWNER_SetSlotieNFT(address newSlotie) external onlyOwner {
        breeding.WATTSOWNER_SetSlotieNFT(newSlotie);
    }

    function WATTSOWNER_SetLockPeriod(uint256 newLockPeriod) external onlyOwner {
        breeding.WATTSOWNER_SetLockPeriod(newLockPeriod);
    }

    function WATTSOWNER_SetIsBlackListed(address _set, bool _is) external onlyOwner {
        breeding.WATTSOWNER_SetIsBlackListed(_set, _is);
    }

    function WATTSOWNER_seeClaimableBalanceOfUser(address user) external view returns (uint256) {
        return breeding.WATTSOWNER_seeClaimableBalanceOfUser(user);
    }

    function WATTSOWNER_seeClaimableTotalSupply() external view returns (uint256) {
        return breeding.WATTSOWNER_seeClaimableTotalSupply();
    }
    

    /**
     * @dev FINANCE
     */

    /**
     * @notice Allows owner to withdraw funds generated from sale.
     *
     * @param _to. The address to send the funds to.
     */
    function withdrawAll(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");

        uint256 contractBalance = address(this).balance;

        require(contractBalance > 0, "NO ETHER TO WITHDRAW");

        payable(_to).transfer(contractBalance);

        emit WithdrawAllEvent(_to, contractBalance);
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}