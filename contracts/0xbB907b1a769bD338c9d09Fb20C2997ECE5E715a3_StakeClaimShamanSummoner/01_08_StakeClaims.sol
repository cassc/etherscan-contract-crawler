// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "../interfaces/IBAAL.sol";

// shaman that works with a stake token to mint shares or loot
// will mint shares/loot to the contributor based on some claim
// the dao can update claims
// if expiered the owner(dao) can withdraw remainder

contract StakeClaimShaman is Initializable, OwnableUpgradeable {
    IBAAL public baal;
    IERC20 public stakeToken;

    mapping(address => uint256) public claims;

    bool public isShares;
    uint256 public expiery;
    uint256 public multiplier;

    event SetClaims(address[] accounts, uint256[] amounts);
    event Claim(address account, uint256 amount);
    event DaoWithdraw(address account, uint256 amount);

    function init(
        address _moloch,
        address _stakeToken,
        bool _isShares,
        uint256 _expiery,
        uint256 _multiplier
    ) external initializer {
        __Ownable_init();
        baal = IBAAL(_moloch);
        stakeToken = IERC20(_stakeToken);
        isShares = _isShares;
        expiery = _expiery;
        multiplier = _multiplier;
    }

    // Mint share or loot tokens
    function _mintTokens(address to, uint256 amount) private {
        address[] memory _receivers = new address[](1);
        _receivers[0] = to;

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = amount;

        if (isShares) {
            baal.mintShares(_receivers, _amounts); // interface to mint shares
        } else {
            baal.mintLoot(_receivers, _amounts); // interface to mint loot
        }
    }

    function claim() public {
        require(block.timestamp < expiery, "claim window expiered");
        require(claimOf(msg.sender) > 0, "no claim available");
        require(
            claimOf(msg.sender) < stakeToken.balanceOf(address(this)),
            "insolvent"
        );

        uint256 currentClaim = claimOf(msg.sender);
        claims[msg.sender] = 0;

        require(stakeToken.transfer(baal.target(), currentClaim), "transfer failed");
        _mintTokens(msg.sender, currentClaim * multiplier);

        emit Claim(msg.sender, currentClaim);
    }

    function updateClaims(address[] memory _accounts, uint256[] memory _claims)
        public
        onlyOwner
    {
        require(_accounts.length == _claims.length, "lengths do not match");
        for (uint256 i = 0; i < _accounts.length; i++) {
            claims[_accounts[i]] = _claims[i];
        }
        emit SetClaims(_accounts, _claims);
    }

    function daoWithdraw(address _to) external onlyOwner {
        require(expiery < block.timestamp, "claim window not expiered");
        uint256 _balance = stakeToken.balanceOf(address(this));
        require(stakeToken.transfer(_to, _balance), "transfer failed");
        emit DaoWithdraw(_to, _balance);
    }

    function claimOf(address _account) public view returns (uint256) {
        return claims[_account];
    }
}

contract StakeClaimShamanSummoner {
    address payable public template;

    event SummonStakeClaim(
        address indexed baal,
        address stakeClaim,
        address token,
        address owner,
        bool isShares,
        uint256 expiery,
        uint256 multiplier,
        string details
    );

    constructor(address payable _template) {
        template = _template;
    }

    function summonStakeClaim(
        address _moloch,
        address _stakeToken,
        address _owner,
        bool _isShares,
        uint256 _expiery,
        uint256 _multiplier,
        string calldata _details
    ) public returns (address) {
        StakeClaimShaman stakeClaim = StakeClaimShaman(
            payable(Clones.clone(template))
        );

        stakeClaim.init(_moloch, _stakeToken, _isShares, _expiery, _multiplier);

        stakeClaim.transferOwnership(_owner);

        emit SummonStakeClaim(
            _moloch,
            address(stakeClaim),
            _stakeToken,
            _owner,
            _isShares,
            _expiery,
            _multiplier,
            _details
        );

        return address(stakeClaim);
    }
}