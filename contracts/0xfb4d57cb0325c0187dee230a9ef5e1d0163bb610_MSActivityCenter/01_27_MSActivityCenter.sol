// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./NoahNFT.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MSActivityCenter is Context, Pausable, AccessControlEnumerable {
    using SafeERC20 for ERC20;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    struct Charge {
        address token;
        uint256 price;
    }

    mapping(uint256 => Charge[]) activityCharges;

    struct Activity {
        address nftContract;
        uint256 period;
        uint256 circulation;
        uint256 maxCirculation;
    }

    mapping(uint256 => Activity) internal activities;

    event ActivityCreated(
        uint256 activityId,
        Charge[] charges,
        address nftContract,
        uint256 period,
        uint256 maxCirculation
    );
    event Presale(
        uint256 activityId,
        Charge[] charges,
        address buyer,
        address nftContract,
        uint256[] tokenIds,
        uint256 timestamp
    );
    event Withdraw(address to, uint256 value);
    event WithdrawToken(address tokenAddress, address to, uint256 amount);

    modifier onlyPauser() {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "MSActivityCenter: Must have pauser"
        );
        _;
    }

    modifier onlyCreator() {
        require(
            hasRole(CREATOR_ROLE, _msgSender()),
            "MSActivityCenter: Must have creator role"
        );
        _;
    }

    modifier onlyWithdrawer() {
        require(
            hasRole(WITHDRAWER_ROLE, _msgSender()),
            "MSActivityCenter: Must have withdrawer role"
        );
        _;
    }

    modifier periodNotZero(uint256 activityId) {
        require(
            activities[activityId].period != 0,
            "MSActivityCenter: Period cannot be 0"
        );
        _;
    }

    constructor(
        address pauser,
        address creator,
        address withdrawer
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, pauser);
        _setupRole(CREATOR_ROLE, creator);
        _setupRole(WITHDRAWER_ROLE, withdrawer);
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function withdraw(address payable to) public whenNotPaused onlyWithdrawer {
        require(
            address(this).balance != 0,
            "MSActivityCenter: No enough ETH to withdraw"
        );
        uint256 value = address(this).balance;
        (bool success, ) = to.call{value: value}("");
        require(
            success,
            "MSActivityCenter: Unable to send value, recipient may have reverted"
        );
        emit Withdraw(to, value);
    }

    function withdrawTokens(address[] calldata tokens, address to)
        public
        whenNotPaused
        onlyWithdrawer
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balance = ERC20(tokens[i]).balanceOf(address(this));
            require(
                balance != 0,
                "MSActivityCenter: No enough ERC20 token to withdraw"
            );
            ERC20(tokens[i]).safeTransfer(to, balance);
            emit WithdrawToken(tokens[i], to, balance);
        }
    }

    function getActivity(uint256 activityId)
        public
        view
        returns (Activity memory)
    {
        return activities[activityId];
    }

    function getActivityCharges(uint256 activityId)
        public
        view
        returns (Charge[] memory)
    {
        return activityCharges[activityId];
    }

    function unsetActivity(uint256 activityId)
        public
        whenNotPaused
        onlyCreator
    {
        activities[activityId].period = 0;
        delete activityCharges[activityId];
    }

    function setActivity(
        uint256 activityId,
        Charge[] calldata charges,
        address nftContract,
        uint256 period,
        uint256 maxCirculation
    ) public whenNotPaused onlyCreator {
        require(period != 0, "MSActivityCenter: Period cannot be 0");
        require(
            charges.length >= 1,
            "MSActivityCenter: Charges length is less than 1"
        );

        activities[activityId] = Activity(
            nftContract,
            period,
            0,
            maxCirculation
        );

        delete activityCharges[activityId];

        for (uint256 i = 0; i < charges.length; i++) {
            activityCharges[activityId].push(charges[i]);
        }

        emit ActivityCreated(
            activityId,
            charges,
            nftContract,
            period,
            maxCirculation
        );
    }

    function presale(uint256 activityId, uint256 tokenQuantity)
        public
        payable
        whenNotPaused
        periodNotZero(activityId)
    {
        Activity storage activity = activities[activityId];
        require(
            activity.period >= block.timestamp,
            "MSActivityCenter: This activity is out of date"
        );
        require(
            activity.circulation + tokenQuantity <= activity.maxCirculation,
            "MSActivityCenter: The circulation exceeds max circulation"
        );

        chargeTokens(activityId, tokenQuantity);

        uint256[] memory tokenIds = new uint256[](tokenQuantity);
        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 tokenId = NoahNFT(activity.nftContract).mint(
                activityId,
                _msgSender()
            );
            tokenIds[i] = tokenId;
        }
        activity.circulation += tokenQuantity;

        emit Presale(
            activityId,
            activityCharges[activityId],
            _msgSender(),
            activity.nftContract,
            tokenIds,
            block.timestamp
        );
    }

    function chargeTokens(uint256 activityId, uint256 tokenQuantity) internal {
        for (uint256 i = 0; i < activityCharges[activityId].length; i++) {
            if (activityCharges[activityId][i].token == address(0)) {
                require(
                    msg.value ==
                        activityCharges[activityId][i].price * tokenQuantity,
                    "MSActivityCenter: Send wrong ETH value"
                );
            } else {
                require(
                    ERC20(activityCharges[activityId][i].token).allowance(
                        _msgSender(),
                        address(this)
                    ) >= activityCharges[activityId][i].price * tokenQuantity, 
                    "MSActivityCenter: Approved insufficient ERC20 tokens"
                );
                ERC20(activityCharges[activityId][i].token).safeTransferFrom(
                    _msgSender(),
                    address(this),
                    activityCharges[activityId][i].price * tokenQuantity
                );
            }
        }
    }
}