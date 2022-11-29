// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../common/RoleConstant.sol";
import "../common/Pause.sol";
import "./WithdrawWallet.sol";
import "../erc20/FandoraTokenV2.sol";

contract ICO is
Initializable,
ContextUpgradeable,
OwnableUpgradeable,
WithdrawWallet,
AccessControlEnumerableUpgradeable,
Pause
{
    using SafeMathUpgradeable for uint256;

    using SafeERC20Upgradeable for IERC20Upgradeable;

    FandoraTokenV2 public tokenProject;

    uint256 private price;

    mapping(address => address) private purchasers;

    address[] private leaders;

    address[] private managers;

    mapping(address => uint256) private revenue;

    uint256 private ref_directSale;

    uint256 private ref_leader;

    address[] private whitelists;

    bool public isWhitelist;

    uint256 public saleAllocation;

    uint256 public allocation;

    uint256 private timeLock;

    uint256 private lengthVesting;

    address[] private tokenRaises;

    mapping(address => Order[]) private orders;

    address[] public purchaserList;

    struct Order {
        uint256 tokenRaiseAmount_;
        uint256 tokenProjectAmount_;
        uint256 claimDate_;
        address manager_;
        address referral_;
        bool isClaim_;
    }

    event TokensPurchased(
        address indexed from,
        address indexed to,
        uint256 value
    );

    function initialize(address _tokenProject, address _withdrawWallet, uint256 _allocation, uint256 _timeLock, uint256 _lengthVesting)
    public
    initializer
    {
        __Context_init_unchained();
        __Ownable_init();
        __Withdraw_init(_withdrawWallet);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MOD_ROLE, _msgSender());
        tokenProject = FandoraTokenV2(_tokenProject);
        isWhitelist = false;
        ref_directSale = 20;
        ref_leader = 20;
        price = 10000;
        allocation = _allocation;
        saleAllocation = 0;
        timeLock = _timeLock;
        lengthVesting = _lengthVesting;
    }

    function addTokenRaise(address token_) public {
        require(hasRole(MOD_ROLE, _msgSender()));
        tokenRaises.push(token_);
    }

    function removeTokenRaise(uint256 index_) public {
        require(hasRole(MOD_ROLE, _msgSender()));
        delete tokenRaises[index_];
    }

    function getLengthTokenRaise() public view returns (uint){
        return tokenRaises.length;
    }

    function execute(
        address tokenRaiseAddress_,
        uint256 tokenRaiseAmount_,
        address referral_
    ) public isPause {
        require(checkExists(tokenRaiseAddress_, tokenRaises));

        if (isManager(referral_)) {
            addLeader(_msgSender());
        }

        IERC20Upgradeable tokenRaise_ = IERC20Upgradeable(tokenRaiseAddress_);

        address referral_ = getReferral(referral_);

        address manager_ = getManager(referral_, managers);

        validate(tokenRaise_, tokenRaiseAmount_);

        paySystem(tokenRaise_, tokenRaiseAmount_);

        payReferral(tokenRaise_, referral_, tokenRaiseAmount_);

        payLeader(tokenRaise_, referral_, tokenRaiseAmount_);

        addPurchaser(referral_);

        createOrder(tokenRaiseAmount_, referral_, manager_);

        claimOrder();

        emit TokensPurchased(_msgSender(), address(this), tokenRaiseAmount_);
    }

    function _execute(address buyer, uint256 amount_) public {
        require(hasRole(MOD_ROLE, _msgSender()));
        emit TokensPurchased(buyer, address(this), amount_);
    }

    function paySystem(IERC20Upgradeable tokenRaise_, uint256 tokenRaiseAmount_) internal {
        SafeERC20Upgradeable.safeTransferFrom(tokenRaise_, _msgSender(), address(this), tokenRaiseAmount_);
    }

    function payReferral(IERC20Upgradeable tokenRaise_, address referral_, uint256 tokenRaiseAmount_) internal {
        uint256 amount = SafeMathUpgradeable.mul(tokenRaiseAmount_, ref_directSale).div(100);
        uint256 balance_ = tokenRaise_.balanceOf(address(this));
        tokenRaise_.approve(address(this), amount);
        SafeERC20Upgradeable.safeTransfer(tokenRaise_, referral_, amount);
    }

    function payLeader(IERC20Upgradeable tokenRaise_, address referral_, uint256 tokenRaiseAmount_) internal {
        address leader_ = getLeader(referral_);
        uint256 amount = SafeMathUpgradeable.mul(tokenRaiseAmount_, ref_leader).div(100);
        tokenRaise_.approve(address(this), amount);
        SafeERC20Upgradeable.safeTransfer(tokenRaise_, leader_, amount);
    }

    function createOrder(uint256 tokenRaiseAmount_, address referral_, address manager_) internal {
        uint256 tokenProjectAmount = SafeMathUpgradeable.div(tokenRaiseAmount_, price).mul(10000);
        calculateRevenue(manager_, tokenRaiseAmount_);
        for (uint i = 0; i < lengthVesting; i++) {
            uint256 tokenProjectAmountVesting = SafeMathUpgradeable.div(tokenProjectAmount, lengthVesting);
            uint256 timeVesting = SafeMathUpgradeable.mul(i, 30 days).add(block.timestamp);

            Order memory order = Order(tokenRaiseAmount_, tokenProjectAmountVesting, timeVesting, manager_, referral_, false);
            orders[_msgSender()].push(order);
        }
        calculate(tokenProjectAmount);
    }

    function getOrder(address buyer) public view returns (Order[] memory) {
        return orders[buyer];
    }

    function getTotalPurchaser() public view returns (uint256) {
        return purchaserList.length;
    }

    function claimOrder() public {
        Order[] memory orders_ = orders[_msgSender()];
        for (uint256 i; i < orders_.length; i++) {
            Order memory order_ = orders_[i];
            if (order_.claimDate_ <= block.timestamp && order_.isClaim_ == false) {
                tokenProject.approve(address(this), order_.tokenProjectAmount_);
                SafeERC20Upgradeable.safeTransfer(tokenProject, _msgSender(), order_.tokenProjectAmount_);
                Order memory order = Order(order_.tokenRaiseAmount_, order_.tokenProjectAmount_, order_.claimDate_, order_.manager_, order_.referral_, true);
                address sender = _msgSender();
                orders[_msgSender()][i] = order;
            }
        }

        address[] memory blacklist = new address[](1);
        blacklist[0] = _msgSender();
        tokenProject.grantMultiAccountToRole(BLACKLIST_ROLE, blacklist);
    }

    function getAmountClaim(address purchaser) public view returns (uint256) {
        uint256 amount = 0;
        Order[] memory orders = orders[_msgSender()];
        for (uint256 i; i < orders.length; i++) {
            Order memory order = orders[i];
            if (order.claimDate_ <= block.timestamp && order.isClaim_ == false) {
                amount += order.tokenProjectAmount_;
            }
        }
        return amount;
    }

    function calculate(uint256 _tokenAmount) internal {
        saleAllocation += _tokenAmount;
    }

    function addPurchaser(address referral_) internal {
        if(purchasers[_msgSender()] == address(0)) {
            purchasers[_msgSender()] = referral_;
        }
        if(!isPurchaserList(_msgSender())) {
            purchaserList.push(_msgSender());
        }
    }

    function isPurchaserList(address purchaser_) internal view returns (bool) {
        return checkExists(purchaser_, purchaserList);
    }

    function getParent(address purchaser) public view returns (address) {
        return purchasers[purchaser];
    }

    function validate(IERC20Upgradeable tokenRaise_, uint256 amount_) internal {
        require(
            tokenRaise_.balanceOf(msg.sender) >= amount_,
            "You don't have enough tokens"
        );

        require(validateWhitelist());

        require(allocation >= saleAllocation, "Don't have enough tokens for sell");
    }

    // ######## Withdraw Token ###########
    function withdrawToken(address token_) external onlyOwner isWithdrawWallet {
        IERC20Upgradeable tokenERC20_ = IERC20Upgradeable(token_);
        uint256 balance_ = tokenERC20_.balanceOf(address(this));
        tokenERC20_.approve(address(this), balance_);
        SafeERC20Upgradeable.safeTransfer(tokenERC20_, getWithdrawWallet(), balance_);
    }

    // ######## Start Ref ###########
    function setRefDirectSale(uint256 percent_) public {
        require(hasRole(MOD_ROLE, _msgSender()));
        ref_directSale = percent_;
    }

    function setRefLeader(uint256 percent_) public {
        require(hasRole(MOD_ROLE, _msgSender()));
        ref_leader = percent_;
    }

    function getReferral(address referral_) internal view returns (address) {
        if (referral_ == address(0) || referral_ == _msgSender()) {
            return getRefWalletDefault();
        }

        return referral_;
    }
    // ######## End Ref ###########

    // ######## Start white List ###########
    function setWhitelist(address[] memory whitelists_) public {
        require(hasRole(MOD_ROLE, _msgSender()));
        whitelists = whitelists_;
    }

    function getWhitelist() public view returns (address[] memory) {
        return whitelists;
    }

    function setIsWhitelist(bool isWhitelist_) public {
        require(hasRole(MOD_ROLE, _msgSender()));
        isWhitelist = isWhitelist_;
    }

    function validateWhitelist() internal view returns (bool) {
        if (!isWhitelist) {
            return true;
        }

        address[] memory whiteList = getWhitelist();
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (whiteList[i] == _msgSender()) {
                return true;
            }
        }
        return false;
    }
    // ######## End white List ###########

    // ########### Start Manager ###########
    function addManager(address manager_) public {
        require(hasRole(MOD_ROLE, _msgSender()));
        if (!isManager(manager_)) {
            managers.push(manager_);
        }
    }

    function removeManager(uint256 index_) public {
        require(hasRole(MOD_ROLE, _msgSender()));
        delete managers[index_];
    }

    function getLengthManager() public view returns (uint){
        return managers.length;
    }

    function isManager(address manager_) public view returns (bool){
        return checkExists(manager_, managers);
    }

    function getManager(address referral_, address[] memory managers) internal returns (address){
        if (isManager(_msgSender())) {
            return _msgSender();
        }

        if (isManager(referral_)) {
            return referral_;
        }

        address manager_ = purchasers[referral_];

        if (manager_ != address(0)) {
            return getManager(manager_, managers);
        }

        return referral_;
    }

    function calculateRevenue(address manager, uint256 _tokenAmount) internal {
        revenue[manager] += _tokenAmount;
    }

    function getRevenue(address manager_) public view returns (uint256) {
        return revenue[manager_];
    }

    // ########### Start leader ###########
    function addLeader(address leader_) internal {
        if (!isLeader(leader_)) {
            leaders.push(leader_);
        }
    }

    function getLengthLeader() public view returns (uint){
        return leaders.length;
    }

    function getLeader(address referral_) public view returns (address){
        if (isLeader(referral_)) {
            return referral_;
        }

        address leader_ = purchasers[referral_];
        address refDefault_ = getRefWalletDefault();

        if (leader_ == address(0) || referral_ == address(0) || referral_ == refDefault_ || leader_ == refDefault_) {
            return refDefault_;
        }

        if (leader_ != address(0)) {
            return getLeader(leader_);
        }

        return referral_;
    }

    function isLeader(address leader_) public view returns (bool){
        return checkExists(leader_, leaders);
    }

    function checkExists(address address_, address[] memory list) internal view returns (bool) {
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == address_) {
                return true;
            }
        }
        return false;
    }
    // ########### End leader ###########

}