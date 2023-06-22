// SPDX-License-Identifier: MIT

// ( ˘▽˘)っ♨ cooked by @nftchef
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++++++++++++++++++++++++++++++*%%?*+++++++++++++++++++++++++++++++++
// +++++++++++++++++++++++++*??*+++?%%%%*++++*??*++++++++++++++++++++++++
// ++++++++++++++++++++++++*S%%%+++?%%%%*+++*%%%%++++++++++++++++++++++++
// ++++++++++++++++++++++++*S%%S?++?S%%S*+++?%%%?++++++++++++++++++++++++
// +++++++++++++++++++++++++SS%S?++*S%%%?+++S%%S?++??*+++++++++++++++++++
// +++++++++++++++++++++++++%%%%%++?S%%%%++?S%%S*+?%%S+++++++++++++++++++
// +++++++++++++++++++++++++%%%%S*+?S%%%%++%%%%%++%%%S+++++++++++++++++++
// +++++++++++++++++++++++++*S%%%?+?S%%%%++S%%%%++S%%S+++++++++++++++++++
// ++++++++++++++++++++++++++%%%%S+?S%%%%+*S%%%?+*S%%S+++++++++++++++++++
// ++++++++++++++++++++++++++%%%%S*?S%%%S+%%%%%*+%%%S%+++++++++++++++++++
// +++++++++++++++*???*++++++%%%%%?%S%%%S?S%%%S*?S%%S?+++++++++++++++++++
// +++++++++++++++%%%%%*+++++?S%%%%%%%%%%%%%%%S?S%%%S++++++++++++++++++++
// +++++++++++++++*S%%%%*++++?S%%%%%%%%%%%%%%%%%%%%S?++++++++++++++++++++
// ++++++++++++++++?S%%%?++++%S%%%%%%%%S%%%%%%%%%%%S*++++++++++++++++++++
// +++++++++++++++++SS%%%?*+*S%%%%%%%%%%%%%%%%%%%%%%+++++++++++++++++++++
// +++++++++++++++++*SS%%%%%SS%%%%%%%%%%%%%%%%%%%%%%+++++++++++++++++++++
// ++++++++++++++++++*%S%%%%%%%%%%%%%%%%%%%%%%%%%%%?+++++++++++++++++++++
// ++++++++++++++++++++%S%%%%%%%%%%%%%%%%%%%%%%%%%S?+++++++++++++++++++++
// +++++++++++++++++++++SS%%%%%%%%%%%S%%%%%%%%%%%%S*+++++++++++++++++++++
// +++++++++++++++++++++*SS%%%%%%%%%%%%%%%%%%%%%%%S*+++++++++++++++++++++
// ++++++++++++++++++++++*SS%%%%%%%%%%%%%%%%%%%%%%%++++++++++++++++++++++
// ++++++++++++++++++++++++?SS%%%%%%%%%%%%%%%%%%%S?++++++++++++++++++++++
// ++++++++++++++++++++++++++%S%%%%%%%%%%%%%%%%%S?+++++++++++++++++++++++
// +++++++++++++++++++++++++++*%S%%%%%SH%%%%%%%S?++++++++++++++++++++++++
// ++++++++++++++++++++++++++++?S%%%%%%%%%%%%%%S*++++++++++++++++++++++++
// ++++++++++++++++++++++++++++*S%%%%%%%%%%%%%%S*++++++++++++++++++++++++
// ++++++++++++++++++++++++++++*S%%%%%%%%%%%%%%S*++++++++++++++++++++++++
// ++++++++++++++++++++++++++++*S%%%%%%%%%%%%%%S*++++++++++++++++++++++++
// ++++++++++++++++++++++++++++*S%%%NFTCHEF%%%%S+++++++++++++++++++++++++
// ++++++++++++++++++++++++++++?S%%%%%%%%%%%%%%%+++++++++++++++++++++++++
// ++++++++++++++++++++++++++++?S%%%%%%%%%%%%%S%+++++++++++++++++++++++++
// ++++++++++++++++++++++++++++?S%%%%%%%%%%%%%S%+++++++++++++++++++++++++
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StrangeStaking is Pausable, Ownable, ReentrancyGuard {
    IERC721 public StrangeHandsNFT;

    struct Stake {
        address owner;
        uint256 timestamp;
    }

    struct Cycle {
        uint256 timestamp;
        uint256 shares;
        uint256 reward; // wei
    }

    uint256 public totalStaked;
    uint256 public MAX_UNSTAKE = 20;
    uint256 QUALIFICATION = 30 days;

    // maintain the last deposit cycle state
    uint256 public LAST_CYCLE_TIME;
    uint256 public LAST_CYCLE_SHARES;
    uint256[] public stakedTokens;

    // maps tokenID to Stake details
    mapping(uint256 => Stake) public stakes;

    mapping(address => uint256[]) public owned;
    mapping(address => uint256) public redeemedRewards;
    mapping(address => uint256) public allocatedRewards;

    // track owned array, token order
    mapping(uint256 => uint256) public index;

    // Array index tracker for all staked tokens
    mapping(uint256 => uint256) public stakedTokenIndex;

    // all reward cycles tracked over time
    Cycle[] rewardCycles;

    constructor(address _strange) {
        StrangeHandsNFT = IERC721(_strange);
    }

    modifier isApprovedForAll() {
        require(
            StrangeHandsNFT.isApprovedForAll(msg.sender, address(this)),
            "ERC721: transfer caller is not owner nor approved"
        );
        _;
    }

    /**
     * @notice This is what you're here for d=(´▽｀)=b.
     * @param tokenIds array of tokens owned by caller, to be staked.
     */
    function stake(uint256[] calldata tokenIds)
        external
        isApprovedForAll
        whenNotPaused
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                StrangeHandsNFT.ownerOf(tokenIds[i]) == msg.sender,
                "Caller is not token owner"
            );
        }

        uint256[] storage ownedTokens = owned[msg.sender];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            index[tokenIds[i]] = ownedTokens.length;
            ownedTokens.push(tokenIds[i]);
            // updates global arr of all stakedTokens
            stakedTokenIndex[tokenIds[i]] = stakedTokens.length;
            stakedTokens.push(tokenIds[i]);
            // create a Stake
            stakes[tokenIds[i]] = Stake(msg.sender, block.timestamp);

            StrangeHandsNFT.transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
        }

        totalStaked += tokenIds.length;
    }

    /**
     * @notice unstake a single token. May only be called by the owner of
     * the token
     * @param tokenId token to unstake.
     */
    function unstake(uint256 tokenId) public nonReentrant {
        require(
            stakes[tokenId].owner == msg.sender,
            "Caller is not token owner"
        );
        _unstake(tokenId);
        totalStaked--;
    }

    /**
     * @notice convenience function for calling unstake for multiple arrays in a
     * single transaction.
     * @param tokenIds array of token id's
     */
    function unstakeMultiple(uint256[] calldata tokenIds)
        external
        nonReentrant
    {
        require(
            tokenIds.length <= MAX_UNSTAKE,
            "Exceeds maximum number to unstake at once"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                stakes[tokenIds[i]].owner == msg.sender,
                "Caller is not token owner"
            );
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(tokenIds[i]);
        }
        totalStaked -= tokenIds.length;
    }

    /**
     * @notice Retrieves the token ID's owned by _address that are staked
     * @param _address owner wallet address.
     */
    function getOwned(address _address) public view returns (uint256[] memory) {
        return owned[_address];
    }

    /**
     * @notice convenience view function to get the number of total staked tokens
     * owned by a given wallet
     * @param _address owner wallet address
     */
    function getOwnedCount(address _address) public view returns (uint256) {
        return owned[_address].length;
    }

    /**
     * @notice determins which tokens owned by an owner are considered
     *   "qualified" for any cycle.
     * @param _address adress to lookup qualified tokens.
     * @return qualifed array of booleans that map to the index order of owned tokens
     */
    function getAllQualified(address _address)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory qualified = new bool[](owned[_address].length);

        for (uint256 nft = 0; nft < owned[_address].length; nft++) {
            for (uint256 cycle = 0; cycle < rewardCycles.length; cycle++) {
                if (
                    stakes[owned[_address][nft]].timestamp + QUALIFICATION <=
                    rewardCycles[cycle].timestamp
                ) {
                    qualified[nft] = true;
                } else {
                    qualified[nft] = false;
                }
            }
        }

        return qualified;
    }

    /**
     * @notice get all tokenId's that are currently staked.
     * @dev Can also be used to get the number of staked tokens.
     *    Does not a 'sorted' order. Sort offchain if needed.
     * @return tokens array of all staked tokens
     */
    function getStakedTokens() public view returns (uint256[] memory) {
        return stakedTokens;
    }

    function pendingBalance(address _address)
        public
        view
        returns (uint256 claim)
    {
        //  ... calculate qualified tokens
        for (uint256 nft = 0; nft < owned[_address].length; nft++) {
            claim += tokenValue(owned[_address][nft]);
        }
        // then, subtract claimed
        claim -= redeemedRewards[_address];
        // then, add saved
        claim += allocatedRewards[_address];
    }

    function collectRewards() external payable nonReentrant {
        uint256 claim = pendingBalance(msg.sender);
        require(claim > 0, "No rewards available");

        (bool sent, bytes memory data) = msg.sender.call{value: claim}("");
        require(sent, "Failed to send Ether");
        redeemedRewards[msg.sender] += claim;
        allocatedRewards[msg.sender] = 0;
    }

    function tokenValue(uint256 _tokenId)
        internal
        view
        returns (uint256 claim)
    {
        // check every cycle for qualification & rewards. accumulate it-
        for (uint256 cycle = 0; cycle < rewardCycles.length; cycle++) {
            if (
                stakes[_tokenId].timestamp + QUALIFICATION <=
                rewardCycles[cycle].timestamp
            ) {
                // accumlate gross, current staked total wei
                claim += rewardCycles[cycle].reward;
            }
        }
    }

    function _unstake(uint256 tokenId) private {
        uint256[] storage ownedTokens = owned[msg.sender];

        // get and store unclaimed rewards earned for the token
        allocatedRewards[msg.sender] += tokenValue(tokenId);
        // swap and pop to remove token from index
        ownedTokens[index[tokenId]] = ownedTokens[ownedTokens.length - 1];
        index[ownedTokens[ownedTokens.length - 1]] = index[tokenId];
        ownedTokens.pop();

        // set token to "unowned"
        stakes[tokenId] = Stake(address(0), 0);
        // remove the tokenID from stakedTokens
        stakedTokens[stakedTokenIndex[tokenId]] = stakedTokens[
            stakedTokens.length - 1
        ];
        // swap the the index mapping for staked tokenId's
        stakedTokenIndex[
            stakedTokens[stakedTokens.length - 1]
        ] = stakedTokenIndex[tokenId];
        stakedTokens.pop();

        // finally, send the token back to the owners wallet.
        StrangeHandsNFT.transferFrom(address(this), msg.sender, tokenId);
    }

    function snapshotAllQualified() public view returns (uint256) {
        // calculates all qualified tokens (gas intensive) when called
        // on-chain. only used when dopositing, so it's ok.
        uint256 totalShares;

        for (uint256 i = 0; i < stakedTokens.length; i++) {
            if (
                stakes[stakedTokens[i]].timestamp + QUALIFICATION <=
                LAST_CYCLE_TIME
            ) {
                totalShares++;
            }
        }
        return totalShares;
    }

    function depositCycle() external payable onlyOwner {
        LAST_CYCLE_TIME = block.timestamp;
        LAST_CYCLE_SHARES = snapshotAllQualified();
        require(LAST_CYCLE_SHARES > 0, "No qualified shares");

        // add a new cycle to the contract state. forever.
        rewardCycles.push(
            Cycle(
                block.timestamp,
                LAST_CYCLE_SHARES,
                msg.value / LAST_CYCLE_SHARES
            )
        );
    }

    /**
     * @dev Set the timespan required to consider tokens "qualified"
     * @param _time length of time in seconds
     */
    function setQualificationPeriod(uint256 _time) external onlyOwner {
        QUALIFICATION = _time;
    }
}