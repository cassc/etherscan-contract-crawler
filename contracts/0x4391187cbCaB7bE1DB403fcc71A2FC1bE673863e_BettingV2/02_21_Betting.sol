// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./common/Storage.sol";
import "./interfaces/IERC1155PresetMinterPauser.sol";
import "./interfaces/IBettingAdmin.sol";

contract Betting is Storage, UUPSUpgradeable, AccessControlUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // Minimum bet value. Currently user can place 0.01 USDC
    uint256 public constant MIN_BET = 1e4;
    // Commission percentage : 1%
    uint8 public constant COMMISION = 100; // in bps
    // Used to avoid losing precision when dividing integers
    uint256 public constant SCALING_FACTOR = 100;
    // 100% = 10000 bps
    uint256 public constant BPS_UNIT = 10000;
    // Array of all bets
    Bet[] public bets;

    // Mapping from poolid -> userAddress -> bet indexes placed against this pool
    mapping (uint256 => mapping(address => uint256[])) public userBets; 

    // Mapping from userAddress -> poolid -> winning amount
    mapping (address => mapping(uint256 => uint256)) public claimedPayouts;

    // Mapping from userAddress -> poolid -> refund amount
    mapping (address => mapping(uint256 => uint256)) public claimedRefunds;

    // Mapping from userAddress -> poolid -> commision amount
    mapping (address => mapping(uint256 => uint256)) public claimedCommissions;

    // Mapping from poolid -> teamid -> team bets
    // mapping (uint256 => mapping (uint256 => uint256)) public poolBalance;

    // Mapping from poolid -> betid -> commision 
    mapping(uint256 => mapping(uint256 => Commission)) public poolCommission;
    // Mapping from poolid -> bet indexes placed against this pool
    mapping (uint256 => uint256[]) public poolBets; 

    // Address of bettingAdmin contract
    IBettingAdmin public bettingAdmin;

    event BetPlaced(uint256 indexed poolId, address indexed player, uint256 indexed teamId, uint256 amount);
    event WinningsClaimed(uint256 indexed poolId, address indexed player, uint256 amount);
    event RefundClaimed(uint256 indexed poolId, address indexed player, uint256 amount);
    event CommissionClaimed(uint256 indexed poolId, address indexed player, uint256 amount);    
    event TeamRefundClaimed(uint256 indexed poolId, address indexed player, uint256 amount);

    // poolId should be > 0 and less than total number of pools
    modifier validPool(uint256 poolId_) {
        require(poolId_ >= 0 && poolId_ < getTotalPools(), "Betting: Id is not valid");
        _;
    }

    // Checks if status of pool matches required status
    modifier validStatus(uint256 status_, uint256 requiredStatus_) {
        require(status_ == requiredStatus_, "Betting: pool status does not match");
        _;
    }

    modifier onlyBettingAdmin() {
        require(msg.sender == address(bettingAdmin));
        _;
    }

    // Initializes initial contract state
    // Since we are using UUPS proxy, we cannot use contructor instead need to use this
    function initialize(address bettingAdmin_) public initializer {
        __UUPSUpgradeable_init();

        bettingAdmin = IBettingAdmin(bettingAdmin_);

        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Allow only admins to perform a future upgrade to the contract
    function _authorizeUpgrade (address newImplementation) internal virtual override onlyRole(ADMIN_ROLE) {

    }

    function getTotalPools() public view returns(uint256) {
        return bettingAdmin.getTotalPools();
    }

    function getPool(uint256 poolId_) public view returns(Pool memory) {
        return bettingAdmin.getPool(poolId_);
    }

    function getPoolTeam(uint256 poolId_, uint256 teamId_) public view returns(Team memory) {
        return bettingAdmin.getPoolTeam(poolId_, teamId_);
    }

    function getPoolTeams(uint256 poolId_) public view returns(Team[] memory) {
        return bettingAdmin.getPoolTeams(poolId_);
    }

    function erc20Contract() public view returns(IERC20Upgradeable) {
        return bettingAdmin.erc20Contract();
    }

    function signer() public view returns(address) {
        return bettingAdmin.signer();
    }

    function vault() public view returns(address) {
        return bettingAdmin.vaultContract();
    }

    function _placeBet(address player_, uint256 poolId_, uint256 teamId_, uint256 amount_, uint256 commission_) internal returns (bool) {
        return bettingAdmin.betPlaced(player_, poolId_, teamId_, amount_, commission_);
    }

    function _payoutClaimed(address player_, uint256 poolId_, uint256 commissionAmount_) internal returns (bool) {
        return bettingAdmin.payoutClaimed(player_, poolId_, commissionAmount_);
    }

    function _refundClaimed(address player_, uint256 poolId_, uint256 commissionAmount_) internal returns (bool) {
        return bettingAdmin.refundClaimed(player_, poolId_, commissionAmount_);
    }

    function _commissionClaimed(address player_, uint256 poolId_, uint256 commissionAmount_) internal returns (bool) {
        return bettingAdmin.commissionClaimed(player_, poolId_, commissionAmount_);
    }


    // Allows user to place bet in a pool against teamId_
    // Commission, if applicable, is calculated on the amount_ and added to final deduction
    // amount_ + commission is transferred from user's balance to contract
    // user is minted amount_ ERC1155 tokens of type teamId_
    // player_ is address that receives the bet
    function placeBet(address player_, uint256 poolId_, uint256 teamId_, uint256 amount_) external validPool(poolId_) {
        Pool memory pool = getPool(poolId_);
        require(pool.status == PoolStatus.Running, "Betting: Pool status should be Running");
        require(amount_ >= MIN_BET, "Betting: Amount should be more than MIN_BET");
        require(pool.startTime > block.timestamp, "Betting: Cannot place bet after pool start time");

        Team memory team = getPoolTeam(poolId_, teamId_);
        require(team.status == TeamStatus.Created, "Betting: Team status should be Created");

        uint256 betId = bets.length;

        uint _commission = 0;
        // Update commission stats
        if (pool.totalBets > 0) {
            _commission = _calculateCommission(amount_);
            poolCommission[poolId_][betId] = Commission(_commission, pool.totalAmount, player_);
        }

        // console.log("netamount: %s, sender: %s", _netAmount, msg.sender);
        bets.push(Bet(betId, poolId_, teamId_, amount_, player_, block.timestamp));
        userBets[poolId_][player_].push(betId);
        poolBets[poolId_].push(betId);
        _placeBet(player_, poolId_, teamId_, amount_, _commission);

        uint256 _netAmount = amount_ + _commission;
        erc20Contract().safeTransferFrom(msg.sender, address(this), _netAmount);
        // Mint team tokens
        pool.mintContract.mint(player_, teamId_, amount_, "") ;

        emit BetPlaced(poolId_, player_, teamId_, amount_);
    }

    // Allows user to claim payout against a poolId
    // Payout is only transferred if user has made a bet against winning team
    // player_ is address that receives payment
    function claimPayment(address player_, uint256 poolId_) external validPool(poolId_) {
        Pool memory pool = getPool(poolId_);

        address[] memory _player = _replicateAddress(player_, pool.winners.length);
        uint256[] memory balances = pool.mintContract.balanceOfBatch(_player, pool.winners);

        require(pool.status == PoolStatus.Decided, "Betting: Pool status should be Decided");
        require(!pool.paymentDisabled, "Betting: Pool payment has been disabled");

        uint256 _winningAmount = _totalAmountWon(player_, poolId_);
        require(_winningAmount > 0, "Betting: No payout to claim"); 
        require(_winningAmount <= pool.totalAmount, "Betting: Payout exceeds total amount");

        claimedPayouts[player_][poolId_] = _winningAmount;
        _payoutClaimed(player_, poolId_, _winningAmount);

        // Burn all supply of user after claiming winning
        pool.mintContract.burnBatch(msg.sender, pool.winners, balances);
        erc20Contract().safeTransfer(player_, _winningAmount);

        emit WinningsClaimed(poolId_, player_, _winningAmount);
    }

    // Allows user to claim refund against a poolId
    // Refund is only transferred if pool was cancelled by admin
    function claimRefund(uint256 poolId_) external validPool(poolId_) {
        Pool memory pool = getPool(poolId_);
        address player = msg.sender;
        
        require(pool.status == PoolStatus.Canceled, "Betting: Pool status should be Canceled");
        require(claimedRefunds[player][poolId_] == 0, "Betting: Refund already claimed"); 

        uint256 _refundAmount = _totalAmountRefunded(player, poolId_);
        require(_refundAmount > 0, "Betting: No refund to claim"); 
        claimedRefunds[player][poolId_] = _refundAmount;

        address[] memory _player = _replicateAddress(player, pool.numberOfTeams);
        uint256[] memory _tokens = _getTokenIds(poolId_);
        uint256[] memory balances = pool.mintContract.balanceOfBatch(_player, _tokens);
        
        _refundClaimed(player, poolId_, _refundAmount);

        pool.mintContract.burnBatch(player, _tokens, balances);
        erc20Contract().safeTransfer(player, _refundAmount);

        emit RefundClaimed(poolId_, player, _refundAmount);
    }

    // Allows user to claim refund against a specific team in a pool
    // Refund is only transferred if team was removed by admin
    // function claimTeamRefund(uint256 poolId_, uint256 teamId_) external validPool(poolId_) {
    //     Pool memory pool = getPool(poolId_);
    //     address player = msg.sender;

    //     Team memory team = getPoolTeam(poolId_, teamId_);
    //     require(team.status == TeamStatus.Refunded, "Betting: Team status should be Refunded");

    //     uint256 balance = pool.mintContract.balanceOf(player, teamId_);
    //     require(balance > 0, "Betting: No refund to claim"); 
        
    //     pool.mintContract.burn(player, teamId_, balance);
    //     erc20Contract().safeTransfer(player, balance);

    //     emit TeamRefundClaimed(poolId_, player, balance);
    // }

    // Allows user to claim generated commission if any in a pool.
    function claimCommission(uint256 poolId_) external validPool(poolId_) {
        Pool memory pool = getPool(poolId_);
        address player = msg.sender;
        
        require(pool.status == PoolStatus.Decided, "Betting: Pool status should be Deciced");
        require(claimedCommissions[player][poolId_] == 0, "Betting: Commission already claimed");
        require(!pool.commissionDisabled, "Betting: Pool commission has been disabled");

        uint256 _commissionAmount = _totalCommissionGenerated(player, poolId_);
        require(_commissionAmount > 0, "Betting: No commission to claim"); 
        require(_commissionAmount <= pool.totalCommissions, "Betting: Payout exceeds total amount");

        claimedCommissions[player][poolId_] = _commissionAmount;
        _commissionClaimed(player, poolId_, _commissionAmount);

        erc20Contract().safeTransfer(player, _commissionAmount);

        emit CommissionClaimed(poolId_, player, _commissionAmount);
    }

    // Allows user to claim generated commission if any in a pool
    // The commission is calculated off-chain and the amount is signed by *signer* address
    // This makes sure amount is not tempered.
    function claimCommissionWithSignature(uint256 poolId_, uint256 amount_, uint256 signedBlockNum_, bytes memory signature_) external validPool(poolId_) {
        Pool memory pool = getPool(poolId_);
        address player = msg.sender;

        require(pool.status == PoolStatus.Decided, "Betting: Pool status should be Deciced");
        require(claimedCommissions[player][poolId_] == 0, "Betting: Commission already claimed");
        require(!pool.commissionDisabled, "Betting: Pool commission has been disabled");
        require(amount_ > 0, "Betting: No commission to claim"); 
        require(amount_ <= pool.totalCommissions, "Betting: Payout exceeds total amount");

        _verifySignature(player, poolId_, amount_, signedBlockNum_, signature_);
        require(signedBlockNum_ <= block.number, "Signed block number must be older");
        require(signedBlockNum_ + 50 >= block.number, "Signature expired");

        // console.log("Transfer amount: %s", amount_);
        claimedCommissions[player][poolId_] = amount_;
        _commissionClaimed(player, poolId_, amount_);

        erc20Contract().safeTransfer(player, amount_);

        emit CommissionClaimed(poolId_, player, amount_);
    }

    function transferCommissionToVault(uint256 poolId_, uint256 amount_) external onlyBettingAdmin {
        Pool memory pool = getPool(poolId_);
        require(amount_ <= pool.totalCommissions, "Betting: Transfer exceeds total commissions");
        erc20Contract().safeTransfer(vault(), amount_);
    }

    function transferPayoutToVault(uint256 poolId_, uint256 amount_) external onlyBettingAdmin {
        Pool memory pool = getPool(poolId_);
        require(amount_ <= pool.totalAmount, "Betting: Transfer exceeds total payouts");
        erc20Contract().safeTransfer(vault(), amount_);
    }

    // Stats functions
    function viewPoolDistribution(uint256 poolId_) external view returns (uint256[] memory _betAmounts){
        Pool memory pool = getPool(poolId_);
        _betAmounts = new uint256[](pool.numberOfTeams);
        for (uint256 i = 0; i < pool.numberOfTeams; ++i) {
            _betAmounts[i] = pool.mintContract.totalSupply(i);
        }

        return _betAmounts;
    }

    // Returns estimated commission based on amount passed
    function estimateCommision(uint256 amount_) external pure returns (uint256) {
        return _calculateCommission(amount_);
    }

    // Returns net amount after commission is deducted
    function viewCommisionPaid(uint256 amount_) external pure returns (uint256) {
        return amount_ - _calculateCommission(amount_);
    }

    // Returns impact of a bet placed in a pool on team odds
    function viewPriceImpact(uint256 poolId_, uint256 teamId_, uint256 amount_) external view returns (uint256) {
        return _calculateFutureOdds(poolId_, teamId_, amount_);
    }

    // Calculate odds of winning for a team
    function calculateOdds(uint256 poolId_, uint256 teamId_) external view returns (uint256) {
        return _calculateOdds(poolId_, teamId_);
    }

    // Returns total amount won by player in a pool
    function totalPayouts(address who_, uint256 poolId_) external view returns(uint256) {
        return _totalAmountWon(who_, poolId_);
    }

    // Returns total refund player is eligible to claim
    function totalRefunds(address who_, uint256 poolId_) external view returns(uint256) {
        return _totalAmountRefunded(who_, poolId_);
    }

    // Returns total commission player is eligible to claim
    function totalCommissions(address who_, uint256 poolId_) external view returns(uint256) {
        return _totalCommissionGenerated(who_, poolId_);
    }

    function allPayouts(address who_, uint256 poolId_) external view returns(uint256, uint256, uint256) {
        uint256 _payout = _totalAmountWon(who_, poolId_) - claimedPayouts[who_][poolId_];
        uint256 _refund = _totalAmountRefunded(who_, poolId_) - claimedRefunds[who_][poolId_];
        uint256 _commission = _totalCommissionGenerated(who_, poolId_) - claimedCommissions[who_][poolId_];
        return (_payout, _refund, _commission);
    }

    // Calculate payout won by player in a pool
    function _totalAmountWon(address who_, uint256 poolId_) internal view returns(uint256) {
        Pool memory pool = getPool(poolId_);
        if (pool.status != PoolStatus.Decided) {
            return 0;
        }

        uint256 _totalWinnings = 0;
        for  (uint256 i = 0; i < pool.winners.length; ++i) { 
            Team memory _team = getPoolTeam(poolId_, pool.winners[i]);
            _totalWinnings += _team.totalAmount;
        }
        _totalWinnings = pool.totalAmount - _totalWinnings;
        uint256 _winningsPerTeam = _totalWinnings / pool.winners.length;

        uint256 _winningAmount = 0;
        for (uint256 i = 0; i < pool.winners.length; ++i) {
            Team memory _team = getPoolTeam(poolId_, pool.winners[i]);
            uint256 _teamBalance = _team.totalAmount;
            if (_teamBalance == 0) {
                continue;
            }

            uint256 _userBalance = pool.mintContract.balanceOf(who_, pool.winners[i]);
            _winningAmount = _winningAmount + ((_winningsPerTeam * _userBalance)/ _teamBalance) + _userBalance;
        }
        
        return _winningAmount;
    }

    // Calculate refund eligible to claim by player in a pool
    function _totalAmountRefunded(address who_, uint256 poolId_) internal view returns(uint256) {
        Pool memory pool = getPool(poolId_);
        if (pool.status != PoolStatus.Canceled) {
            return 0;
        }

        address[] memory _player = _replicateAddress(who_, pool.numberOfTeams);
        uint256[] memory _tokens = _getTokenIds(poolId_);
        uint256[] memory balances = pool.mintContract.balanceOfBatch(_player, _tokens);
        // Mark all payments by user in this pool as available for refund
        uint256[] memory _userBets = userBets[poolId_][who_];
        uint256 _refundedAmount = 0;

        for (uint8 i = 0; i < balances.length; ++i) {
            _refundedAmount += balances[i];
        }

        for (uint256 i = 0; i < _userBets.length; ++i) {
            Commission memory commission = poolCommission[poolId_][_userBets[i]];
            _refundedAmount += commission.amount;
        } 

        return _refundedAmount;
    }

    // Calculate commission eligible to claim by player in a pool
    function _totalCommissionGenerated(address who_, uint256 poolId_) internal view returns(uint256) {
        Pool memory pool = getPool(poolId_);
        // We return commission when user claims refund
        if (pool.status == PoolStatus.Canceled) {
            return 0;
        }
        // Mark all payments by user in this pool as available for refund
        uint256[] memory _userBets = userBets[poolId_][who_];
        if (_userBets.length == 0) {
            return 0;
        }
        uint256 _commissionAmount = 0;

        uint256 startIndex = 0;
        for(uint256 i = 0; i < poolBets[poolId_].length; ++i) {
            if (poolBets[poolId_][i] == _userBets[0]) {
                startIndex = i;
                break;
            }
        }

        Bet memory bet = bets[_userBets[0]];
        uint256 betAmount = bet.amount;
        for (uint256 i = startIndex + 1; i < poolBets[poolId_].length; ++i) {
            uint256 _betId = poolBets[poolId_][i];
            Commission memory commission = poolCommission[poolId_][_betId];
            if (commission.player == address(0)) {
                continue;
            }
            Bet memory _bet = bets[_betId];
            // Get commission reference
            _commissionAmount = _commissionAmount + (betAmount * SCALING_FACTOR * commission.amount) / commission.totalAmount;
            if (_bet.player == who_) {
                betAmount += _bet.amount;
            }
        } 

        return _commissionAmount / SCALING_FACTOR;
    }

    // Calculates odds of winning against a team in pool
    function _calculateOdds(uint256 poolId_, uint256 teamId_) internal view returns (uint256) {
        Pool memory pool = getPool(poolId_);
        uint256 _teamBalance = pool.mintContract.totalSupply(teamId_);
        if (_teamBalance == 0) {
            return 0;
        }

        return ((pool.totalAmount - _teamBalance) * SCALING_FACTOR)/ _teamBalance;
    }

    function _calculateFutureOdds(uint256 poolId_, uint256 teamId_, uint256 amount_) internal view returns (uint256) {
        Pool memory pool = getPool(poolId_);
        uint256 _teamBalance = pool.mintContract.totalSupply(teamId_);
        uint256 _futureBalance = _teamBalance += amount_;
        return (((pool.totalAmount + amount_) - _futureBalance) * SCALING_FACTOR )/ _futureBalance;
    }

    function _calculateCommission(uint256 amount_) internal pure returns (uint256) {
        return (amount_ * COMMISION * SCALING_FACTOR / BPS_UNIT) / SCALING_FACTOR;
    }

    function getMessageHash(address player_, uint256 poolId_, uint256 amount_, uint256 signedBlockNum_) public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(
                player_,
                poolId_,
                amount_,
                signedBlockNum_
            )
        );
    }

    function _verifySignature(
        address player_,
        uint256 poolId_,
        uint256 amount_,
        uint256 signedBlockNum_,
        bytes memory signature_
    ) internal view {
        bytes32 msgHash = getMessageHash(player_, poolId_, amount_, signedBlockNum_);
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)
        );
        require(
            recoverSigner(signedHash, signature_) == signer(),
            "Invalid signature"
        );
    }

    function _getTokenIds(uint256 poolId_) internal view returns (uint256[] memory) {
        Pool memory pool = getPool(poolId_);
        uint256[] memory tokenIds = new uint256[](pool.numberOfTeams);
        for (uint256 i = 0; i < pool.numberOfTeams; ++i) {
            tokenIds[i] = i;
        }
        return tokenIds;
    } 

    function _replicateAddress(address sender_, uint256 count_) internal pure returns (address[] memory) {
        address[] memory _addresses = new address[](count_);
        for (uint8 i = 0; i < count_; ++i) {
            _addresses[i] = sender_;
        }
        return _addresses;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}