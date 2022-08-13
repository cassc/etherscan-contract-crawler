pragma solidity 0.8.6;


import "IJellyAccessControls.sol";
import "IERC20.sol";
import "IMerkleList.sol";
import "IJellyContract.sol";
import "SafeERC20.sol";
import "BoringMath.sol";
import "Documents.sol";


/**
* @title Jelly Drop V1.5:
*
*              ,,,,
*            [email protected]@@@@@K
*           [email protected]@@@@@@@P
*            [email protected]@@@@@@"                   [email protected]@@  [email protected]@@
*             "*NNM"                     [email protected]@@  [email protected]@@
*                                        [email protected]@@  [email protected]@@
*             ,[email protected]@@g        ,,[email protected],     [email protected]@@  [email protected]@@ ,ggg          ,ggg
*            @@@@@@@@p    [email protected]@@[email protected]@W   [email protected]@@  [email protected]@@  [email protected]@g        ,@@@Y
*           [email protected]@@@@@@@@   @@@P      ]@@@  [email protected]@@  [email protected]@@   [email protected]@g      ,@@@Y
*           [email protected]@@@@@@@@  [email protected]@D,,,,,,,,]@@@ [email protected]@@  [email protected]@@   '@@@p     @@@Y
*           [email protected]@@@@@@@@  @@@@EEEEEEEEEEEE [email protected]@@  [email protected]@@    "@@@p   @@@Y
*           [email protected]@@@@@@@@  [email protected]@K             [email protected]@@  [email protected]@@     '@@@, @@@Y
*            @@@@@@@@@   %@@@,    ,[email protected]@@  [email protected]@@  [email protected]@@      ^@@@@@@Y
*            "@@@@@@@@    "[email protected]@@@@@@@E'   [email protected]@@  [email protected]@@       "*@@@Y
*             "[email protected]@@@@@        "**""       '''   '''        @@@Y
*    ,[email protected]@g    "[email protected]@@P                                     @@@Y
*   @@@@@@@@p    [email protected]@'                                    @@@Y
*   @@@@@@@@P    [email protected]                                    RNNY
*   '[email protected]@@@@@     $P
*       "[email protected]@@p"'
*
*
*/

/**
* @author ProfWobble 
* @dev
*  - Allows for a group of users to claim tokens from a list.
*  - Supports Merkle proofs using the Jelly List interface.
*  - Token claim paused on deployment (Jelly not set yet!).
*  - SetJelly() function allows tokens to be claimed when ready.
*
*/

contract JellyDrop is IJellyContract, Documents {

    using BoringMath128 for uint128;
    using SafeERC20 for OZIERC20;

    /// @notice Jelly template type and id for the pool factory.
    uint256 public constant override TEMPLATE_TYPE = 2;
    bytes32 public constant override TEMPLATE_ID = keccak256("JELLY_DROP");
    uint256 private constant PERCENTAGE_PRECISION = 10000;
    uint256 private constant TIMESTAMP_PRECISION = 10000000000;
    uint256 private constant MULTIPLIER_PRECISION = 1e18;

    /// @notice Address that manages approvals.
    IJellyAccessControls public accessControls;

    /// @notice Address that manages user list.
    address public list;

    /// @notice Reward token address.
    address public rewardsToken;

    /// @notice Current total rewards paid.
    uint256 public rewardsPaid;

    /// @notice Total tokens to be distributed.
    uint256 public totalTokens;

    struct UserInfo {
        uint128 totalAmount;
        uint128 rewardsReleased;
    }

    /// @notice Mapping from user address => rewards paid.
    mapping (address => UserInfo) public userRewards;

    struct RewardInfo {
        /// @notice Sets the token to be claimable or not (cannot claim if it set to false).
        bool tokensClaimable;
        /// @notice Epoch unix timestamp in seconds when the airdrop starts to decay
        uint48 startTimestamp;
        /// @notice Jelly streaming period
        uint32 streamDuration;
        /// @notice Jelly claim period, 0 for unlimited
        uint48 claimExpiry;
        /// @notice Reward multiplier
        uint128 multiplier;

    }
    RewardInfo public rewardInfo;

    /// @notice Whether staking has been initialised or not.
    bool private initialised;

    /// @notice JellyVault is where fees are sent.
    address private jellyVault;

    /// @notice JellyVault is where fees are sent.
    uint256 private feePercentage;

    /**
     * @notice Event emitted when a user claims rewards.
     * @param user Address of the user.
     * @param reward Reward amount.
     */
    event RewardPaid(address indexed user, uint256 reward);

    /**
     * @notice Event emitted when claimable status is updated.
     * @param status True or False.
     */
    event ClaimableStatusUpdated(bool status);

    /**
     * @notice Event emitted when claimable status is updated.
     * @param expiry Timestamp when tokens are no longer claimable.
     */
    event ClaimExpiryUpdated(uint256 expiry);

    /**
     * @notice Event emitted when rewards contract has been updated.
     * @param oldRewardsToken Address of the old reward token contract.
     * @param newRewardsToken Address of the new reward token contract.
     */
    event RewardsTokenUpdated(address indexed oldRewardsToken, address newRewardsToken);

    /**
     * @notice Event emitted when reward tokens have been added to the pool.
     * @param amount Number of tokens added.
     * @param fees Amount of fees.
     */
    event RewardsAdded(uint256 amount, uint256 fees);

    /**
     * @notice Event emitted when list contract has been updated.
     * @param oldList Address of the old list contract.
     * @param newList Address of the new list contract.
     */
    event ListUpdated(address oldList, address newList);

    /**
     * @notice Event emitted when merkle proof has been updated.
     * @param oldMerkleRoot Old merkle proof hash.
     * @param newMerkleRoot New merkle proof hash
     */
    event ProofUpdated(bytes32 oldMerkleRoot, bytes32 newMerkleRoot);


    /**
     * @notice Event emitted for Jelly admin updates.
     * @param vault Address of the new vault address.
     * @param fee New fee percentage.
     */
    event JellyUpdated(address vault, uint256 fee);

    /**
     * @notice Event emitted for when setJelly is called.
     */
    event JellySet();

    /**
     * @notice Event emitted for when tokens are recovered.
     * @param token ERC20 token address.
     * @param amount Token amount in wei.
     */
    event Recovered(address token, uint256 amount);


    constructor() {
    }
 
    //--------------------------------------------------------
    // Setters
    //--------------------------------------------------------

    /**
     * @notice Admin can set reward tokens claimable through this function.
     * @param _enabled True or False.
     */
    function setTokensClaimable(bool _enabled) external  {
        require(accessControls.hasAdminRole(msg.sender), "setTokensClaimable: Sender must be admin");
        rewardInfo.tokensClaimable = _enabled;
        emit ClaimableStatusUpdated(_enabled);
    }

    /**
     * @notice Admin can set token claim expiry through this function.
     * @param _expiry Timestamp for when tokens are no longer able to be claimed.
     */
    function setClaimExpiry(uint256 _expiry) external  {
        require(accessControls.hasAdminRole(msg.sender), "setClaimExpiry: Sender must be admin");
        require(_expiry < TIMESTAMP_PRECISION, "setClaimExpiry: enter claim expiry unix timestamp in seconds, not miliseconds");
        require((rewardInfo.startTimestamp < _expiry && _expiry > block.timestamp )|| _expiry == 0, "setClaimExpiry: claim expiry incorrect");
        rewardInfo.claimExpiry =  BoringMath.to48(_expiry);
        emit ClaimExpiryUpdated(_expiry);
    }

    /**
     * @notice Add more tokens to the JellyDrop contract.
     * @param _rewardAmount Amount of tokens to add, in wei. (18 decimal place format)
     */
    function addRewards(uint256 _rewardAmount) public {
        require(accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender), "addRewards: Sender must be admin/operator");
        OZIERC20(rewardsToken).safeTransferFrom(msg.sender, address(this), _rewardAmount);
        uint256 tokensAdded = _rewardAmount * PERCENTAGE_PRECISION  / uint256(feePercentage + PERCENTAGE_PRECISION);
        uint256 jellyFee =  _rewardAmount * uint256(feePercentage)  / uint256(feePercentage + PERCENTAGE_PRECISION);
        totalTokens += tokensAdded ;
        OZIERC20(rewardsToken).safeTransfer(jellyVault, jellyFee);
        emit RewardsAdded(_rewardAmount, jellyFee);
    }

    /**
     * @notice Jelly vault can update new vault and fee.
     * @param _vault New vault address.
     * @param _fee Fee percentage of tokens distributed.
     */
    function updateJelly(address _vault, uint256 _fee) external  {
        require(jellyVault == msg.sender); // dev: updateJelly: Sender must be JellyVault
        require(_vault != address(0)); // dev: Address must be non zero
        require(_fee < PERCENTAGE_PRECISION); // dev: feePercentage greater than 10000 (100.00%)

        jellyVault = _vault;
        feePercentage = _fee;
        emit JellyUpdated(_vault, _fee);
    }

    /**
     * @notice To initialise the JellyDrop contracts once everything is ready.
     * @param _startTimestamp Timestamp when the tokens rewards are set to begin.
     * @param _streamDuration How long the tokens will drip, in seconds.
     * @param _tokensClaimable Bool to determine if the airdrop is initially claimable.
     */
    function setJellyCustom(uint256 _startTimestamp, uint256 _streamDuration,  bool _tokensClaimable) public  {
        require(accessControls.hasAdminRole(msg.sender), "setJelly: Sender must be admin");
        require(_startTimestamp < TIMESTAMP_PRECISION, "setJelly: enter start unix timestamp in seconds, not miliseconds");

        rewardInfo.tokensClaimable = _tokensClaimable;
        rewardInfo.startTimestamp = BoringMath.to48(_startTimestamp);
        rewardInfo.streamDuration = BoringMath.to32(_streamDuration);
        rewardInfo.multiplier = BoringMath.to128(MULTIPLIER_PRECISION);
        emit JellySet();
    }

    /**
     * @notice To initialise the JellyDrop contracts with default values once everything is ready.
     */
    function setJellyAirdrop() external  {
        setJellyCustom(block.timestamp, 0, false);
    }

    /**
     * @notice To initialise the JellyDrip contracts with a stream duration.
     */
    function setJellyAirdrip(uint256 _streamDuration) external  {
        setJellyCustom(block.timestamp, _streamDuration, false);
    }


    //--------------------------------------------------------
    // Getters 
    //--------------------------------------------------------

    function tokensClaimable() external view returns (bool)  {
        return rewardInfo.tokensClaimable;
    }

    function startTimestamp() external view returns (uint256)  {
        return uint256(rewardInfo.startTimestamp);
    }

    function streamDuration() external view returns (uint256)  {
        return uint256(rewardInfo.streamDuration);
    }

    function claimExpiry() external view returns (uint256)  {
        return uint256(rewardInfo.claimExpiry);
    }

    function calculateRewards(uint256 _newTotalAmount) external view returns (uint256)  {
        if (_newTotalAmount <= totalTokens) return 0;
        uint256 newTokens = _newTotalAmount - totalTokens;
        uint256 fee = newTokens * uint256(feePercentage) / PERCENTAGE_PRECISION;
        return newTokens + fee;
    }

    //--------------------------------------------------------
    // Claim
    //--------------------------------------------------------

    /**
     * @notice Claiming rewards for user.
     * @param _merkleRoot List identifier.
     * @param _index User index.
     * @param _user User address.
     * @param _amount Total amount of tokens claimable by user.
     * @param _data Bytes array to send to the list contract.
     */
    function claim(bytes32 _merkleRoot, uint256 _index, address _user, uint256 _amount, bytes32[] calldata _data ) public {
        UserInfo storage _userRewards =  userRewards[_user];
        
        require(_amount > 0, "Token amount must be greater than 0");
        require(
            _amount > uint256(_userRewards.rewardsReleased),
            "Amount must exceed tokens already claimed"
        );
        require(
            rewardInfo.tokensClaimable == true,
            "Tokens cannnot be claimed yet"
        );

        uint256 merkleAmount = IMerkleList(list).tokensClaimable(_merkleRoot, _index, _user, _amount, _data );
        require(merkleAmount > 0, "Incorrect merkle proof for amount.");

        if (merkleAmount != uint256(_userRewards.totalAmount)) {
            _userRewards.totalAmount = BoringMath.to128(merkleAmount);
        }

        uint256 payableAmount = _earnedAmount(merkleAmount, uint256(_userRewards.rewardsReleased));
        require(payableAmount > 0, "No tokens available to claim");

        _userRewards.rewardsReleased +=  BoringMath.to128(payableAmount);
        rewardsPaid +=  payableAmount;
        require(rewardsPaid <= totalTokens, "Amount claimed exceeds total tokens");

        OZIERC20(rewardsToken).safeTransfer(_user, payableAmount);
        emit RewardPaid(_user, payableAmount);
    }

    /**
     * @notice Calculated the amount that has already earned but hasn't been released yet.
     * @param _user Address to calculate the earned amount for
     */
    function earnedAmount(address _user) external view returns (uint256) {
        return
            _earnedAmount(
                userRewards[_user].totalAmount,
                userRewards[_user].rewardsReleased
            );
    }

    /**
     * @notice Calculates the amount that has already earned but hasn't been released yet.
     */
    function _earnedAmount(
        uint256 total,
        uint256 released

    ) internal view returns (uint256) {
        if (total <= released ) {
            return 0;
        }

        RewardInfo memory _rewardInfo = rewardInfo;

        // Rewards havent started yet
        if (
            block.timestamp <= uint256(_rewardInfo.startTimestamp) 
            || _rewardInfo.tokensClaimable == false
        ) {
            return 0;
        }

        uint256 expiry = uint256(_rewardInfo.claimExpiry);
        // Expiry set and reward claim has expired
        if (expiry > 0 && block.timestamp > expiry  ) {
            return 0;
        }

        uint256 elapsedTime = block.timestamp - uint256(_rewardInfo.startTimestamp);
        uint256 earned;
        // Reward calculation if streamDuration set
        if (elapsedTime >= uint256(_rewardInfo.streamDuration)) {
            earned = total;
        } else {
            earned = (total * elapsedTime) / uint256(_rewardInfo.streamDuration);
        }
    
        return earned - released;
    }

    //--------------------------------------------------------
    // Lists
    //--------------------------------------------------------

    /**
     * @notice Admin can change list contract through this function.
     * @param _list Address of the new list contract.
     */
    function setList(address _list) external {
        require(accessControls.hasAdminRole(msg.sender));
        require(_list != address(0)); // dev: Address must be non zero
        emit ListUpdated(list, _list);
        list = _list;
    }

    /**
     * @notice Updates Merkle Root.
     * @param _merkleRoot Merkle Root
     * @param _merkleURI Merkle URI
     */
    function updateProof(bytes32 _merkleRoot, string memory _merkleURI) public {
        require(
            accessControls.hasAdminRole(msg.sender) 
            ||  accessControls.hasOperatorRole(msg.sender),
            "updateProof: Sender must be admin/operator"
        );
        emit ProofUpdated(currentMerkleRoot(), _merkleRoot);

        IMerkleList(list).updateProof( _merkleRoot, _merkleURI);
    }

    /**
     * @notice Current Merkle Root.
     */
    function currentMerkleRoot() public view returns (bytes32) {
        return IMerkleList(list).currentMerkleRoot();
    }

    /**
     * @notice Current Merkle URI.
     */
    function currentMerkleURI() public view returns (string memory) {
        return IMerkleList(list).currentMerkleURI();
    }

    //--------------------------------------------------------
    // Admin Reclaim
    //--------------------------------------------------------

    /**
     * @notice Admin can end token distribution and reclaim tokens.
     * @notice Also allows for the recovery of incorrect ERC20 tokens sent to contract
     * @param _vault Address where the reclaimed tokens will be sent.
     */
    function adminReclaimTokens(
        address _tokenAddress,
        address _vault, 
        uint256 _tokenAmount
    )
        external
    {
        require(
            accessControls.hasAdminRole(msg.sender),
            "recoverERC20: Sender must be admin"
        );
        require(_vault != address(0)); // dev: Address must be non zero
        require(_tokenAmount > 0); // dev: Amount of tokens must be greater than zero

        if (_tokenAddress == rewardsToken) {
            require(
                rewardInfo.claimExpiry > 0 && block.timestamp > rewardInfo.claimExpiry,
                "recoverERC20: Airdrop not yet expired"
            );
            totalTokens = rewardsPaid;
            rewardInfo.tokensClaimable = false;
        }
        OZIERC20(_tokenAddress).safeTransfer(_vault, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }


    //--------------------------------------------------------
    // Documents
    //--------------------------------------------------------

    /**
     * @notice Admin can set key value pairs for UI.
     * @param _name Document key.
     * @param _data Document value.
     */
    function setDocument(string calldata _name, string calldata _data) external {
        require(accessControls.hasAdminRole(msg.sender) );
        _setDocument( _name, _data);
    }

    function setDocuments(string[] calldata _name, string[] calldata _data) external {
        require(accessControls.hasAdminRole(msg.sender) );
        uint256 numDocs = _name.length;
        for (uint256 i = 0; i < numDocs; i++) {
            _setDocument( _name[i], _data[i]);
        }
    }

    function removeDocument(string calldata _name) external {
        require(accessControls.hasAdminRole(msg.sender));
        _removeDocument(_name);
    }


    //--------------------------------------------------------
    // Factory Init
    //--------------------------------------------------------

    /**
     * @notice Initializes main contract variables.
     * @dev Init function.
     * @param _accessControls Access controls interface.
     * @param _rewardsToken Address of the airdrop token.
     * @param _rewardAmount Total amount of tokens to distribute.
     * @param _list Address for the merkle list verifier contract.
     * @param _jellyVault The Jelly vault address.
     * @param _jellyFee Fee percentage for added tokens. To 2dp (10000 = 100.00%)
     */
    function initJellyAirdrop(
        address _accessControls,
        address _rewardsToken,
        uint256 _rewardAmount,
        address _list,
        address _jellyVault,
        uint256 _jellyFee
    ) public 
    {
        require(!initialised, "Already initialised");
        require(_list != address(0), "List address not set");
        require(_jellyVault != address(0), "jellyVault not set");
        require(_jellyFee < PERCENTAGE_PRECISION , "feePercentage greater than 10000 (100.00%)");
        require(_accessControls != address(0), "Access controls not set");

        rewardsToken = _rewardsToken;
        jellyVault = _jellyVault;
        feePercentage = _jellyFee;
        totalTokens = _rewardAmount;
        if (_rewardAmount > 0) {
            uint256 jellyFee = _rewardAmount * uint256(feePercentage) / PERCENTAGE_PRECISION;
            OZIERC20(_rewardsToken).safeTransferFrom(msg.sender, address(this), _rewardAmount + jellyFee);
            OZIERC20(_rewardsToken).safeTransfer(_jellyVault, jellyFee);
        }
        accessControls = IJellyAccessControls(_accessControls);
        list = _list;
        initialised = true;
    }

    /** 
     * @dev Used by the Jelly Factory. 
     */
    function init(bytes calldata _data) external override payable {}

    function initContract(
        bytes calldata _data
    ) public override {
        (
        address _accessControls,
        address _rewardsToken,
        uint256 _rewardAmount,
        address _list,
        address _jellyVault,
        uint256 _jellyFee
        ) = abi.decode(_data, (address, address,uint256, address,address,uint256));

        initJellyAirdrop(
                        _accessControls,
                        _rewardsToken,
                        _rewardAmount,
                        _list,
                        _jellyVault,
                        _jellyFee
                    );
    }

    /** 
     * @dev Generates init data for factory.
     * @param _accessControls Access controls interface.
     * @param _rewardsToken Address of the airdrop token.
     * @param _rewardAmount Total amount of tokens to distribute.
     * @param _list Address for the merkle list verifier contract.
     * @param _jellyVault The Jelly vault address.
     * @param _jellyFee Fee percentage for added tokens. To 2dp (10000 = 100.00%)
     */
    function getInitData(
        address _accessControls,
        address _rewardsToken,
        uint256 _rewardAmount,
        address _list,
        address _jellyVault,
        uint256 _jellyFee
    )
        external
        pure
        returns (bytes memory _data)
    {
        return abi.encode(
                        _rewardsToken,
                        _accessControls,
                        _rewardAmount,
                        _list,
                        _jellyVault,
                        _jellyFee
                        );
    }


}