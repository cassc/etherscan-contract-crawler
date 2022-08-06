pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IINK {
    function whitelist_mint(address account, uint256 amount) external;
}

contract StakeMLA is IERC721Receiver, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    address public ERC20_CONTRACT;
    address public ERC721_CONTRACT;
    address public REWARDS_PROXY_CONTRACT;
    uint256 public EXPIRATION; //expiry block number (avg 15s per block)

    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public depositBlocks;
    uint256 public rewardRate;   
    bool started;

    constructor(
        address _erc20,
        address _erc721,
        address _proxy,
        uint256 _expiration
    ) {
        ERC20_CONTRACT = _erc20;
        ERC721_CONTRACT = _erc721;
        REWARDS_PROXY_CONTRACT = _proxy;
        EXPIRATION = block.number + _expiration;
        // number of tokens Per day
        rewardRate = uint256(2 * 1e18) / 6000;
        started = false;
    }

    function setRate(uint256 _rate) public onlyOwner() {
        rewardRate = (_rate * 1e18) / 6000;
    }

    function setExpiration(uint256 _expiration) public onlyOwner() {
        EXPIRATION = _expiration;
    }
    
    function toggleStart() public onlyOwner() {
        started = !started;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner() {
        // Used to change rewards token if needed
        ERC20_CONTRACT = _tokenAddress;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function depositsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); ) {
            tokenIds[i] = depositSet.at(i);
            unchecked{ i++; }
        }

        return tokenIds;
    }

    function calculateRewards(address account, uint256[] memory tokenIds)
        public
        view
        returns (uint256[] memory rewards)
    {
        rewards = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            if (_deposits[account].contains(tokenId)) {
              rewards[i] =
                  rewardRate *
                  (Math.min(block.number, EXPIRATION) -
                      depositBlocks[account][tokenId]);
            } else {
              rewards[i] = 0;
            }
            unchecked{ i++; }
        }
    }

    function calculateRewardsAll(address account, uint256[] memory tokenIds)
        public
        view
        returns (uint256[] memory rewards)
    {
        rewards = new uint256[](tokenIds.length);
        EnumerableSet.UintSet storage depositSet = _deposits[account];

        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = depositSet.at(i);
            rewards[i] = rewardRate *
                (Math.min(block.number, EXPIRATION) -
                    depositBlocks[account][tokenId]);
            unchecked{ i++; }
        }
    }


    function claimRewardsInt(uint256[] calldata tokenIds) private {
        uint256 reward;
        uint256 curblock = Math.min(block.number, EXPIRATION);

        uint256[] memory rewards = calculateRewards(msg.sender, tokenIds);

        for (uint256 i; i < tokenIds.length; ) {
            reward += rewards[i];
            depositBlocks[msg.sender][tokenIds[i]] = curblock;
            unchecked{ i++; }
        }

        if (reward > 0) {
            IINK(ERC20_CONTRACT).whitelist_mint(msg.sender, reward);
        }
    }

    function claimRewards(uint256[] calldata tokenIds) public nonReentrant {
        claimRewardsInt(tokenIds);
    }

    function claimRewardsAllInt(address user) private {
        uint256 reward;
        uint256 curblock = Math.min(block.number, EXPIRATION);

        EnumerableSet.UintSet storage depositSet = _deposits[user];
        uint256[] memory tokenIds = new uint256[](depositSet.length());
        uint256[] memory rewards = calculateRewardsAll(user, tokenIds);

        for (uint256 i; i < tokenIds.length; ) {
            reward += rewards[i];
            depositBlocks[user][depositSet.at(i)] = curblock;
            unchecked{ i++; }
        }

        if (reward > 0) {
            IINK(ERC20_CONTRACT).whitelist_mint(user, reward);
        }
    }

    function claimRewardsAllFor(address user) public nonReentrant {
        require(msg.sender == REWARDS_PROXY_CONTRACT, 'StakeMLA: function only for a proxy contract');
        claimRewardsAllInt(user);
    }

    function claimRewardsAll() public nonReentrant {
        claimRewardsAllInt(msg.sender);
    }

    function deposit(uint256[] calldata tokenIds) external nonReentrant {
        require(started, 'StakeMLA: Staking contract not started yet');

        claimRewardsInt(tokenIds);
        
        for (uint256 i; i < tokenIds.length; ) {
            IERC721(ERC721_CONTRACT).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ''
            );
            _deposits[msg.sender].add(tokenIds[i]);
            unchecked{ i++; }
        }
    }

    function admin_deposit(uint256[] calldata tokenIds) onlyOwner() external nonReentrant {
        claimRewardsInt(tokenIds);

        for (uint256 i; i < tokenIds.length; ) {
            IERC721(ERC721_CONTRACT).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ''
            );
            _deposits[msg.sender].add(tokenIds[i]);
            unchecked{ i++; }
        }
    }

    function withdraw(uint256[] calldata tokenIds) external nonReentrant {
        claimRewardsInt(tokenIds);

        for (uint256 i; i < tokenIds.length; ) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                'StakeMLA: Token not deposited'
            );

            _deposits[msg.sender].remove(tokenIds[i]);

            IERC721(ERC721_CONTRACT).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ''
            );
            unchecked{ i++; }
        }
    }
}