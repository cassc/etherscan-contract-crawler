// SPDX-License-Identifier: MIT
// Developed by KG Technologies (https://kgtechnologies.io)

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @notice Represents NFT Smart Contract
 */
contract ICryptoBearsERC721 {
    /** 
     * @dev ERC-721 INTERFACE 
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    /** 
     * @dev CUSTOM INTERFACE 
     */
    function mintTo(uint256 amount, address _to) external {}
    function maxMintPerTransaction() public returns (uint256) {}
}

/**
 * @title CryptoBearsClaim.
 *
 * @author KG Technologies (https://kgtechnologies.io).
 *
 * @notice This Smart Contract can be used to claim a Crypto Bear if one holds
 * a Crypto Bull
 *
 * @dev The primary mode of verifying permissioned actions is through Merkle Proofs
 * which are generated off-chain.
 */
contract CryptoBearsClaim is Ownable {

    /** 
     * @notice The Smart Contract of the NFT being sold 
     * @dev ERC-721 Smart Contract 
     */
    ICryptoBearsERC721 public immutable nft;

    /**
     * @notice Crypto Bull Society NFT address
     */
    address public immutable bulls;

    /**
     * @dev CLAIMING
     */
    uint256 public claimStart = 1644692400;
    mapping(uint256 => uint256) public hasBullClaimed; // 0 = false | 1 = true
    
    /**
     * @dev Events
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);    
    event Claim(address indexed claimer, uint256 indexed amount);    
    event setClaimStartEvent(uint256 indexed time);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    constructor(
        address _nftaddress
    ) Ownable() {
        nft = ICryptoBearsERC721(_nftaddress);
        bulls = 0x469823c7B84264D1BAfBcD6010e9cdf1cac305a3;
    }
 
    /**
     * @dev CLAIMING
     */

    /**
     * @notice Claim bears by providing your crypto bull Ids
     * @dev Mints amount of bears to sender as valid crypto bulls 
     * provided. Validity depends on ownership and not having claimed yet.
     *
     * @param bullIds. The tokenIds of the bulls.
     */
    function claimBears(uint256[] calldata bullIds) external {
        require(address(nft) != address(0), "BEARS NFT NOT SET");
        require(bulls != address(0), "BULLS NFT NOT SET");
        require(bullIds.length > 0, "NO IDS SUPPLIED");
        require(block.timestamp >= claimStart, "CANNOT CLAIM YET");

        /// @dev Check if sender is owner of all bulls and that they haven't claimed yet
        /// @dev Update claim status of each bull
        for (uint256 i = 0; i < bullIds.length; i++) {
            uint256 bullId = bullIds[i];
            require(IERC721( bulls ).ownerOf(bullId) == msg.sender, "NOT OWNER OF BULL");
            require(hasBullClaimed[bullId] == 0, "BULL HAS ALREADY CLAIMED BEAR");
            hasBullClaimed[bullId] = 1;
        }

        nft.mintTo(bullIds.length, msg.sender);
        emit Claim(msg.sender, bullIds.length);
    }

    /**
     * @notice View which of your bulls can still claim bears
     * @dev Given an array of bull ids returns a subset of ids that
     * can still claim a bear. Used off chain to provide input of claimBears method.
     *
     * @param bullIds. The tokenIds of the bulls.
     */
    function getNotClaimedBullsByIds(uint256[] calldata bullIds) external view returns (uint256[] memory) {
        require(bullIds.length > 0, "NO IDS SUPPLIED");

        uint256 length = bullIds.length;
        uint256[] memory notClaimedBulls = new uint256[](length);
        uint256 counter;

        /// @dev Check if sender is owner of all bulls and that they haven't claimed yet
        /// @dev Update claim status of each bull
        for (uint256 i = 0; i < bullIds.length; i++) {
            uint256 bullId = bullIds[i];
            //require(IERC721( bulls ).ownerOf(bullId) == owner, "NOT OWNER OF BULL");            
            if (hasBullClaimed[bullId] == 0) {
                notClaimedBulls[counter] = bullId;
                counter++;
            }
        }

        return notClaimedBulls;
    }

    /** 
     * @dev OWNER ONLY 
     */

    /**
     * @notice Change the startime for bulls to claim their bears;
     *
     * @param newStart. The new start time.
     */
    function setClaimStart(uint256 newStart) external onlyOwner {
        claimStart = newStart;
        emit setClaimStartEvent(newStart);
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