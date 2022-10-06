//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract SomefiV2 is
Initializable,
ERC20Upgradeable,
ERC20BurnableUpgradeable,
AccessControlEnumerableUpgradeable,
OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    IERC20Upgradeable public tokenUSDT;

    struct Account {
        bool    canBeRef;
        address parent;
        uint256 tokenFromDapp;
        bytes32 left;
        bytes32 right;
    }

    struct Airdrop {
        address userAddress;
        uint256 amount;
    }

    struct Round {
        uint256 startTimeICO;
        uint256 maxSoldByRound;
        uint256 ratePerUSDT;
        uint256 amountSoldByRound;
        mapping(uint256 => bool) packages;
    }

    struct Whitelist {
        uint256 amount;
        bool allowTransfer;
    }

    uint256 public roundId;
    address public backupWallet;
    address payable public mainWallet;
    bool public icoHasEnded;
    bool public isLockTokenDapp;
    address private root;
    uint256 public withdrawFee;

    mapping(uint256 => Round) public rounds;
    mapping(address => Account) public refInfo;
    mapping(bytes32 => address) public refOfAccount;
    mapping(address => Whitelist) public whitelists;
    mapping(address => bool) public blacklist;
    mapping(address => mapping(uint256 => uint256)) public maxPackages;

    event BuyICOPackage(bytes32 referrer, address buyer, bytes32 left, bytes32 right, uint256 amount, uint256 roundId);
    event UpdateICOPackage(address buyer, uint256 amount, uint256 roundId);
    event Withdraw(address user, uint256 roundId);
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    function initialize(
        address _owner,
        address _usdtContractAddress,
        address _walletBackup,
        address payable _walletMain
    ) external initializer {
        require(_usdtContractAddress != address(0), "invalid-USDT");
        __ERC20_init("Somefi", "SOFI");
        __Ownable_init();
        _mint(_owner, 5000000000000000000000000);
        tokenUSDT = IERC20Upgradeable(_usdtContractAddress);
        icoHasEnded = true;
        isLockTokenDapp = true;
        backupWallet = _walletBackup;
        mainWallet = _walletMain;
        withdrawFee = 0.00015 * 10**18;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    receive() external payable {}

    fallback() external payable {}

    function addRoot(address sender) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(root == address(0), "root not null");
        _checkBlackList(sender);

        if (root == address(0)) {
            Account storage account = refInfo[sender];
            bytes32 leftByte = _generateLinkRef(sender, true);
            bytes32 rightByte = _generateLinkRef(sender, false);
            account.canBeRef = true;
            account.parent = address(0);
            account.left = leftByte;
            account.right = rightByte;

            refOfAccount[leftByte] = sender;
            refOfAccount[rightByte] = sender;
            root = sender;
        }
    }

    function buyICO(bytes32 refByte, uint256 amount) external {
        address sender = _msgSender();
        require(!icoHasEnded, "BuyICO: ICO time is expired");
        require(root != address(0), "BuyICO: Root does not assign");

        _checkBlackList(sender);

        Round storage round = rounds[roundId];
        require(block.timestamp >= round.startTimeICO, "BuyICO: ICO time does not start now");
        require(round.amountSoldByRound + amount <= round.maxSoldByRound, "BuyICO: Reach maximum sold");
        require(round.packages[amount], "BuyICO: Package is not available");

        Account storage account = refInfo[sender];

        if (!account.canBeRef) {
            address refAddress = refOfAccount[refByte];

            if (refAddress == address(0)) {
                refAddress = root;
            }

            bytes32 leftByte = _generateLinkRef(sender, true);
            bytes32 rightByte = _generateLinkRef(sender, false);
            account.canBeRef = true;
            account.parent = refAddress;
            account.left = leftByte;
            account.right = rightByte;
            refOfAccount[leftByte] = sender;
            refOfAccount[rightByte] = sender;
            maxPackages[sender][roundId] = amount;

            uint256 buyAmountToken = amount.mul(round.ratePerUSDT);
            tokenUSDT.transferFrom(sender, address(this), amount);
            _buy(sender, buyAmountToken, amount);

            emit BuyICOPackage(refByte, sender, leftByte, rightByte, amount, roundId);
        } else {
            if (amount > maxPackages[sender][roundId]) {
                maxPackages[sender][roundId] = amount;

                uint256 buyAmountToken = amount.mul(round.ratePerUSDT);
                tokenUSDT.transferFrom(sender, address(this), amount);
                _buy(sender, buyAmountToken, amount);
            }

            emit UpdateICOPackage(sender, amount, roundId);
        }
    }

    function whitelistUnlock(
        address[] calldata _unlockAddresses,
        bool[] calldata _isUnlockAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        uint256 count = _unlockAddresses.length;
        require(count < 201, "Array Overflow");
        for (uint256 i = 0; i < count; i++) {
            require(_unlockAddresses[i] != address(0), "zero-address");
            Whitelist storage whitelist = whitelists[_unlockAddresses[i]];
            whitelist.allowTransfer = _isUnlockAddress[i];
        }
        return true;
    }

    function changeFee(uint256 fee) external  onlyRole(DEFAULT_ADMIN_ROLE) {
        require(fee > 0, "ChangeFee: fee is zero");
        withdrawFee = fee;
    }

    function startNewRound(
        uint256 _startTimeICO,
        uint256 _totalAmountPerUSDT,
        uint256 _totalSold,
        uint256[] calldata _packages
    ) external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_startTimeICO > block.timestamp, "invalid time");
        require(_totalAmountPerUSDT > 0, "invalid rate buy ICO by USDT");
        require(icoHasEnded, "ICO must end");
        roundId += 1;

        Round storage round = rounds[roundId];

        round.startTimeICO = _startTimeICO;
        round.ratePerUSDT = _totalAmountPerUSDT;
        round.maxSoldByRound = _totalSold;
        icoHasEnded = false;

        for (uint i = 0; i < _packages.length; i++) {
            round.packages[_packages[i]] = true;
        }
    }

    function userWithdraw() payable external {
        require(msg.value >= withdrawFee, "UserWithdraw: gas fee not enough");
        address sender = _msgSender();
        _checkBlackList(sender);

        mainWallet.transfer(msg.value);

        emit Withdraw(sender, roundId);
    }

    function _checkBlackList(address sender) private view {
        require(sender != address(0), "zero address");
        require(!blacklist[sender], "blacklist user");
    }

    function _buy(address sender, uint256 buyAmountToken, uint256 amountUsdt) internal {
        uint256 half = amountUsdt / 2;

        Round storage round = rounds[roundId];

        round.amountSoldByRound += buyAmountToken;
        _mint(sender, buyAmountToken);

        tokenUSDT.transfer(backupWallet, half);
        tokenUSDT.transfer(mainWallet, half);
    }

    function _generateLinkRef(address sender, bool isLeft) private view returns(bytes32) {
        return keccak256(abi.encodePacked(sender, isLeft, block.timestamp));
    }

    function mint(address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }

    function addAddressToBlacklist(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(0), "zero address");
        blacklist[_address] = true;
    }

    function removeAddressFromBlacklist(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(0), "zero address");
        delete blacklist[_address];
    }

    function closeIco() external onlyRole(DEFAULT_ADMIN_ROLE) {
        icoHasEnded = true;
    }

    // lock transfer token from Dapp
    function setIsLockTokenDapp(bool _isLock) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isLockTokenDapp = _isLock;
    }

    function transferAirdrops(Airdrop[] memory arrAirdrop) external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < arrAirdrop.length; i++) {
            Whitelist storage whitelist = whitelists[arrAirdrop[i].userAddress];
            whitelist.amount += arrAirdrop[i].amount;
            whitelist.allowTransfer = false;
            _mint(arrAirdrop[i].userAddress, arrAirdrop[i].amount);
        }
    }

    function transferLockToken(address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool)
    {
        Whitelist storage whitelist = whitelists[recipient];
        whitelist.amount += amount;
        _mint(recipient, amount);
        return true;
    }

    /* @dev transfer override function transfer */
    function transfer(address to, uint256 amount) public override returns (bool) {
        address sender = _msgSender();
        Whitelist storage whitelist = whitelists[sender];
        uint256 amountToken = balanceOf(sender);
        uint256 availableToken = amountToken;

        if ((isLockTokenDapp || !whitelist.allowTransfer ) && !hasRole(DEFAULT_ADMIN_ROLE, sender)) {

            if (isLockTokenDapp) {
                Account storage account = refInfo[sender];
                availableToken -= account.tokenFromDapp;
            }

            if (!whitelist.allowTransfer) {
                availableToken -= whitelist.amount;
            }

            require( availableToken >= amount,  "ERC20: transfer amount exceeds balance" );
            _transfer(sender, to, amount);

            return true;
        } else {
            return super.transfer(to, amount);
        }
    }

    function transferAdmin(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_admin != address(0), "ZERO_ADDRESS");
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (from == address(0) && !icoHasEnded && !hasRole(DEFAULT_ADMIN_ROLE, to)) {
            Account storage account = refInfo[to];
            account.tokenFromDapp += amount;
        } else {
            super._beforeTokenTransfer(from, to, amount);
        }
    }
}