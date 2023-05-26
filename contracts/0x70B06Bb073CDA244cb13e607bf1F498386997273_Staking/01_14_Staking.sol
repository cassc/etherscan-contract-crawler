//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;
import "./interfaces/IERC721Receiver.sol";
import "./ERC/ERC721.sol";
import "./utils/Context.sol";
import "./AMMO.sol";



/**
* @dev Implementation of a staking contract that receives custody of a user's Non Fungible Tokens to generate ERC20 tokens.
* The contracts stakes immediately the Non Fungible Token upon reception and retains the original owner as the rightful owner with ownerOf mapping.
* The original users retains the rights to stop staking at anytime therefore receiving its earning and the full custody and ownership of its Non Fungible Tokens.
* User can claim its ERC20 earnings  at anytime.
 */

contract Staking is IERC721Receiver, Context {
    using Address for address;
    using Strings for uint256;

    /**
    *@dev emitted when '_user' claims its earnings and sends '_amount' to it
     */
    event Claim(address _user, uint _amount);

    /**
    *@dev emitted on reception and staking of '_tokenId' token from '_user'.
     */
    event Stake(address _user, uint _tokenId);

    /**
    *@dev emitted when '_user' unstakes '_tokenId' token.
     */
    event Unstake(address _user, uint _tokenId);

    // The base formula to define how much ERC20 is minted per day.
    uint private rewardSpeed; 

    // Address of NFT collection contract
    address public whiteListedContract;

    // Address of the owner of this contract.
    address private owner;

    // The staking informations of a user
    mapping( address => StakingInfo) public stakingInfo;

    // The owner of a token in custody in this contract. To ensure that the original sender retains ownership.
    mapping(uint => address) private _ownerOf;

    //The NFT collection contract
    ERC721 public CHAMPS;

    //The ERC20 token contract
    AMMO public ammo;


    /**
    *@notice Structure containing all the staking informations of an address.
    *@dev lastClaim is in epoch time.
     */
    struct StakingInfo {
        uint stakedNftNum; //Number of tokens from owner currently in staking
        uint multiplier; // Modifies ERC20 token generations speed
        uint claimed; // All ERC20 claimed by user until now
        uint lastClaim; //Last time of ERC20 claim
        mapping(uint => uint) tokenIds; // a list of tokenIds by index. Use stakedNftNum to enumerate all tokenIds in staking.
    }

    modifier onlyOwner() {
        require(_msgSender() == owner, "only owner");
        _;
    }

    /**
     * @dev Initializes the contract and sets the owner .
     */
    constructor(address _whiteListedContract, uint _rewardSpeed, address _owner) {
        owner = _owner;
        whiteListedContract = address(_whiteListedContract);
        rewardSpeed = _rewardSpeed;
        CHAMPS = ERC721(whiteListedContract);
    } 

    /**
    *@dev sets the address of the ERC20 Ammo contract that will be used for minting new tokens.
     */
    function setERC20(address _contractAddress) external onlyOwner {
        require(_contractAddress.isContract(), "is not a contract");
        ammo = AMMO(_contractAddress);
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
        function onERC721Received(
        address operator, 
        address from, 
        uint256 tokenId, 
        bytes calldata data) external override returns (bytes4) {
        require(address(whiteListedContract) == msg.sender, "wrong contract address");  
        _stake(tokenId, from);
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice It stakes the token upon reception in the contract. Only called on reception from OnERC721Received(). 
     * All ERC20 already earned is automatically claimed and transfered to user.
     * The NFT of the sender is now in custody of this contract but original owner retains ownership. see { ownerOf() }.
     * @dev   mapping owner of is to ensure that the original owner retains the right of claiming back its token at anytime.
     * @param _tokenId The id of the token to stake.
     * @param _from The owner of the NFT that is staked on this contract.
     * Emits a {Stake} event
     */
    function _stake(uint _tokenId, address _from) private {
        require(msg.sender == whiteListedContract, "base contract only");
        StakingInfo storage copy = stakingInfo[_from]; //copy to store data

        if (copy.stakedNftNum > 0)  _claim(_from); //make sure to claim only if NFT were already staked
        //Update user staking informations
        stakingInfo[_from].lastClaim = block.timestamp;
        stakingInfo[_from].multiplier = 10 + (copy.stakedNftNum * 10 + (copy.stakedNftNum)); // add 1.1 every time
        stakingInfo[_from].tokenIds[stakingInfo[_from].stakedNftNum ] = _tokenId; // store the tokenId
        stakingInfo[_from].stakedNftNum = copy.stakedNftNum +1;
        _ownerOf[_tokenId] = _from; // user is owner of staked token
        
        emit Stake(_from, _tokenId);
    }

    /**
     * @notice it unstakes a NFT and sends it back to its owner. Called by user interaction. 
     * It automatically claims and send ERC20 already earned to the user.
     * @dev 
     * @param _index the id of the token to unstake and claim back
     * Emits a {Unstake} event
     */
    function unstake(uint _index) external {
        uint tokenId = stakingInfo[_msgSender()].tokenIds[_index];
        require(_ownerOf[tokenId] == _msgSender(), "not owner or staked");
        StakingInfo storage copy = stakingInfo[_msgSender()];
        
        _claim(_msgSender()); // claim gains and creates ERC20 tokens into the user's address
        //Update user staking informations
        (copy.stakedNftNum > 1) ? stakingInfo[_msgSender()].multiplier = copy.multiplier - 11 : stakingInfo[_msgSender()].multiplier = 0;
        
        stakingInfo[_msgSender()].stakedNftNum = copy.stakedNftNum - 1; //Keeps track ofhow many NFT are in staking
        stakingInfo[_msgSender()].tokenIds[_index] = stakingInfo[_msgSender()].tokenIds[stakingInfo[_msgSender()].stakedNftNum]; // tokenId is replaced by last in array
        stakingInfo[_msgSender()].tokenIds[stakingInfo[_msgSender()].stakedNftNum] = 0; //last in array is deleted
        _ownerOf[tokenId] = address(0); // This contract doesn't retain an owner.
        CHAMPS.safeTransferFrom(address(this), _msgSender(), tokenId); // Token is unlocked and sent back to owner

        emit Unstake(_msgSender(), tokenId);
    }


    /**
     * @notice The ERC20 generation speed is set by this function.
     * It depends on how many NFTs the user has staked in this contract.
     * @param _user the user's struct with its parameters.
     * @dev the base rate is 100 $AMMO per day.
     */
    function _toClaim(address _user) internal view returns(uint){
        StakingInfo storage SI = stakingInfo[_user];
        uint toClaim = 10 ** 18 * (block.timestamp - SI.lastClaim) * (SI.multiplier / 10) / rewardSpeed;
        return toClaim;
    }

    /**
     * @notice That function allows user to manually claim its gains at anytime.
     * @dev public function that can be called by this contract or an external account. 
     * Emits a {} event
     */
    function claim() public {
        _claim(_msgSender());
    }
    
    /**
     * @notice Internal function to claim ERC20 tokens earned by a user and send them to it.
     * @dev safeTransferFrom() (see {ERC721}) is called by the registered collection contract. 
     * This contract needing to claim the user's earnings, it cannot call msg.sender that is the NFT collection contract address.
     * This function is only called during reception of the safeTransferFrom() and therefore needs the user's address as a parameter.
     * @param _from The address of the address to claim the gains for.
     * Emits a {Claim} event
     */
    function _claim(address _from) internal {
        uint toClaim = _toClaim(_from);
        stakingInfo[_from].lastClaim = block.timestamp;
        stakingInfo[_from].claimed += toClaim;
        ammo.mint(_from, toClaim);
        emit Claim(_from, toClaim);
    }

    /**
    *@notice The NFT is now on contract address and in the original NFT contract it appears as the owner. 
    * This function shows that the user that sent its NFT to the contract retains ownership.
    *@param _tokenId the token idof the NFT to view
     */
    function ownerOf(uint _tokenId) external view returns(address) {
        return _ownerOf[_tokenId];
    }

    /**
    *@notice Returns the amount of ERC20 tokens generated that a user can claim
     */
    function checkToClaim() public view returns(uint) {
        return _toClaim(_msgSender());
    }

    /**
    *@dev allows to change the base ERC20 generation speed of staking.Only owner can call.
     */
    function updateRewardSpeed(uint _rewardSpeed) external onlyOwner {
        rewardSpeed = _rewardSpeed;
    }

    /**
    *@notice used to check what tokenIds are staked by a user
    *@dev to use with stakedNftNum for enumeration.
    *@param _index the index at which the tokenId is stored
    *@param _user the user to call for verification of possessions
     */
    function tokenIdByIndex(uint _index, address _user) external view returns(uint){
        return stakingInfo[_user].tokenIds[_index];
    }
}