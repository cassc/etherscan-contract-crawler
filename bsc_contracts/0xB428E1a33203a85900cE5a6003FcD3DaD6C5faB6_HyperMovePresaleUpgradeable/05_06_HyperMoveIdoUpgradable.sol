/// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

import "./IERC20.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title The HyperMovePresaleUpgradeable
 * @dev The contract is upgradeable through EIP1967 pattern
 * @author HyperMove
 * @notice Performs HyperMove presale & claim
 */
contract HyperMovePresaleUpgradeable is Initializable, OwnableUpgradeable {

    /// @dev The presale info
    struct PreSaleInfo {
        // The minimum hyperMove allocation
        uint256 minAllocation;
        // The maximum hyperMove allocation
        uint256 maxAllocation;
        // The purchase cap
        uint256 purchaseCap;
    }

    /// @notice The presale info
    PreSaleInfo public preSaleInfo;

    /// @notice the admin wallet
    address public adminWallet;

    /// @notice The contract instance of BUSD token
    IERC20 public BUSD;

    /// @notice The contract instance of HyperMove token
    IERC20 public hyperMove;

    /// @notice The price of hyper move token
    uint256 public hyperMovePrice;

    /// @notice The raised amount BUSD
    uint256 public raisedBUSD;

    /// @notice The number of total users participated
    uint256 public totalUsersParticipated;

    /// @notice the identifier to check if sale started
    bool public isSaleStarted;

    /// @notice The identifier for activate Claimable
    bool public isClaimable;

    /// @notice The identifier to check if sale ends
    bool public isSaleEnd;

    /// @notice The list of user purchases
    mapping(address => uint256) public userPurchases;

    event Claim(address recieverAddress, uint256 amount);

    /**
     * @notice Initliazation of HyperMovePresaleUpgradeable
     * @param _busd The contract address of BUSD token
     * @param _hyperMove The contract address of HyperMove token
     * @param _hyperMovePrice The price per BUSD of HyperMove
     * @param _minAllocation The minimum amount of user allocation
     * @param _maxAllocation The maximum amount of user allocation
     * @param _purchaseCap The purchase cap
     * @param _adminWallet admin wallet
     */
    function __HyperMovePresaleUpgradeable_init(
        address _busd,
        address _hyperMove,
        uint256 _hyperMovePrice,
        uint256 _minAllocation,
        uint256 _maxAllocation,
        uint256 _purchaseCap,
        address _adminWallet
    ) external initializer {
        __Ownable_init();
        __HyperMovePresaleUpgradeable_init_unchained(
            _busd,
            _hyperMove,
            _hyperMovePrice,
            _minAllocation,
            _maxAllocation,
            _purchaseCap,
            _adminWallet
        );
    }

    /**
     * @notice Sets initial state of HyperMove presale contract
     * @param _busd The contract address of BUSD token
     * @param _hyperMove The contract address of HyperMove token
     * @param _hyperMovePrice The price per BUSD of HyperMove
     * @param _minAllocation The minimum amount of user allocation
     * @param _maxAllocation The maximum amount of user allocation
     * @param _purchaseCap The purchase cap
     * @param _adminWallet The purchase cap
     */
    function __HyperMovePresaleUpgradeable_init_unchained(
        address _busd,
        address _hyperMove,
        uint256 _hyperMovePrice,
        uint256 _minAllocation,
        uint256 _maxAllocation,
        uint256 _purchaseCap,
        address _adminWallet
    ) internal initializer {
        require(
            _hyperMove != address(0) && _busd != address(0) && _adminWallet != address(0) &&
                _minAllocation > 0 &&
                _maxAllocation > _minAllocation &&
                _purchaseCap > _maxAllocation,
            "Invalid Args"
        );

        BUSD = IERC20(_busd);
        hyperMove = IERC20(_hyperMove);
        hyperMovePrice = _hyperMovePrice;
        adminWallet = _adminWallet;

        // set presale details
        preSaleInfo = PreSaleInfo({
            minAllocation: _minAllocation,
            maxAllocation: _maxAllocation,
            purchaseCap: _purchaseCap
        });
    }

    /**
     * @notice set is sale started
     * @dev call by current owner
     * @param startStatus the status of sale start
     */
    function setSaleStarted(bool startStatus) external onlyOwner {
        isSaleStarted = startStatus;
    }

    /**
     * @notice set is claimable of HyperMove
     * @dev Call by current owner of HyperMove presale
     * @param claimStatus The status of sale flag
     */
    function setIsClaimable(bool claimStatus) external onlyOwner {
        isClaimable = claimStatus;
    }

    /**
     * @notice Update hyper move price
     * @dev Call by current owner of HyperMove presale
     * @param _hyperMovePrice The price of hyper move token
     */
    function updateHyperMovePrice(uint256 _hyperMovePrice) external onlyOwner {
        hyperMovePrice = _hyperMovePrice;
    }

    /**
     * @notice Update Hyper Move token contract instance
     * @dev Call by current owner of HyperMove presale
     * @param _hyperMove The contract address of HyperMove token
     */
    function updateHyperMove(address _hyperMove) external onlyOwner {
        hyperMove = IERC20(_hyperMove);
    }

    function updateBUSD(address _busd) external onlyOwner {
        BUSD = IERC20(_busd);
    }

    /**
     * @notice Update presale info
     * @dev Call by current owner of HyperMove presale
     * @param minAllocation The amount of minimum allocation
     * @param maxAllocation The amount of maximum allocation
     * @param purchaseCap The purchase cap
     */
    function updatePreSaleInfo(
        uint256 minAllocation,
        uint256 maxAllocation,
        uint256 purchaseCap
    ) external onlyOwner {
        require(
            minAllocation > 0 &&
                maxAllocation > minAllocation &&
                purchaseCap > maxAllocation,
            "Invalid Sale Info"
        );
        preSaleInfo = PreSaleInfo(minAllocation, maxAllocation, purchaseCap);
    }

    /**
     * @notice Sets sale ends
     * @dev Call by current owner of HyperMove presale
     * @param saleEndFlag The status of sale ends flag
     */
    function setSaleEnds(bool saleEndFlag) external onlyOwner {
        isSaleEnd = saleEndFlag;
    }

    /**
     * @notice buy HyperMove token with BUSD
     * @param amount The amount of bnb to purchase
     */
    function buy(uint256 amount) external {
        // verify the purchase
        _verifyPurchase(amount);

        require(isSaleStarted, "Sale not yet started");
        require(!isSaleEnd, "Sale Ends");

        require(
            preSaleInfo.purchaseCap >= raisedBUSD + amount,
            "Purchase Cap Reached"
        );

        require(BUSD.transferFrom(_msgSender(), adminWallet, amount), "token transfer failed");

        raisedBUSD += amount;

        if (userPurchases[_msgSender()] == 0) {
            totalUsersParticipated++;
        }

        userPurchases[_msgSender()] += amount;
    }

    /**
     * @notice Claim Hyper Move
     * @dev Countered Error when invalid attempt or sale not ends
     */
    function claimHyperMove() external {
        uint256 purchaseAmount = userPurchases[_msgSender()];
        require(purchaseAmount > 0, "Invalid Attempt");
        require(isClaimable, "Claiming Not startes");

        // reset to 0
        userPurchases[_msgSender()] = 0;

        uint256 transferableHyperMove = _convertBusdToHyperMove(purchaseAmount);
        hyperMove.transfer(_msgSender(), transferableHyperMove);

        emit Claim(_msgSender(), transferableHyperMove);
    }

    /**
     * @notice Rescue Any Token
     * @dev Call by current owner of HyperMove presale
     * @param withdrawableAddress The account of withdrawable
     * @param token The instance of ERC20 token
     * @param amount The token amount to withdraw
     */
    function rescueToken(
        address withdrawableAddress,
        IERC20 token,
        uint256 amount
    ) external onlyOwner {
        require(
            withdrawableAddress != address(0),
            "Invalid Withdrawable Address"
        );
        token.transfer(withdrawableAddress, amount);
    }

    /**
     * @notice Verify the purchases
     * @dev Throws error when purchases verification failed
     * @param amount The amount to buy
     */
    function _verifyPurchase(uint256 amount) internal view {
        uint256 maxAllocation = preSaleInfo.maxAllocation;
        require(
            amount >= preSaleInfo.minAllocation &&
                userPurchases[_msgSender()] + amount <= maxAllocation,
            "Buy Failed"
        );
    }

    /**
     * @notice Convert BUSD to Hyper Move token & Returns converted HyperMove's
     * @param amount The amount of BUSD
     * @return hyperMoves The amount of HyperMove's
     */
    function _convertBusdToHyperMove(uint256 amount)
        internal
        view
        returns (uint256)
    {
        return (amount * hyperMovePrice);
    }
}