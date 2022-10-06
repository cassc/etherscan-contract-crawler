/**
 *Submitted for verification at BscScan.com on 2022-05-06
 */

/**
 *Submitted for verification at BscScan.com on 2022-02-25
 */

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// nft
interface IERC21 is IERC721 {
    function mintNFT(address recipient, string memory tokenURI)
        external
        returns (uint256);

    function mintNFTs(address recipient, string[] memory tokenURI)
        external
        returns (uint256[] memory ids);

    function getBank() external view returns (address);
}

// token
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function totalSupplyLimit() external view returns (uint256);

    function getBank() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function mint(address to, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract UsdtDeposit is ReentrancyGuard {
    using SafeMath for uint256;

    address private _owner;
    address private _manager;

    uint256 public depositFee = 5 * 10**18;
    uint256 public minDeposit = 50 * 10**18;
    uint256 public withdrawFee = 5 * 10**18;
    uint256 public minWithdraw = 50 * 10**18;


    uint256 public totalStaked = 0;
    uint256 public totalDeposit = 0;
    uint256 public collectedFee = 0;
    uint256 public totalrewardGoes = 0;

    uint256 public melmPerUSDT = 25;
    uint256 public OneNFTforUSDT = 500 * 10**18;

    address[] public whitelistAddresses;

    string private _hash;

    IERC20 public usdtContract;
    IERC20 public lemlContract;
    IERC21 public nftContract;

    mapping(address => uint256) private _whitelistedIndexes;

    mapping(address => bool) private _isWhitelisted;

    mapping(address => uint256) public balances;

    mapping(address => uint256) public claimableLEML;

    mapping(address => uint256) public claimableNFT;

    mapping(address => uint256) public rewards;

    mapping(address => uint256) private _amountDeposited;

    mapping(address => uint256) private _amountSaked;

    mapping(address => uint256) private _amountWithdrawn;

    event DepositAndStakeFor(
        address indexed account,
        uint256 value,
        uint256[] ids,
        uint256 leml
    );
    event Deposit(address indexed account, uint256 value);
    event NFTmint(uint256[] ids);

    event Stake(
        address indexed account,
        uint256 value,
        uint256[] ids,
        uint256 leml
    );

    event Withdraw(address indexed account, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Sender is not the owner.");
        _;
    }
    modifier onlyManager() {
        require(
            msg.sender == _owner || msg.sender == _manager,
            "Sender is not the owner or manager."
        );
        _;
    }

    constructor(
        IERC20 usdtAddress,
        IERC20 lemlAddress,
        IERC21 nftAddress,
        address manager
    ) {
        usdtContract = usdtAddress;
        lemlContract = lemlAddress;
        nftContract = nftAddress;
        _owner = msg.sender;
        _manager = manager;
        updateWhiteList(msg.sender, true);
    }

    receive() external payable {}

    //
    function depositAndStakeFor(
        address account,
        uint256 amount,
        string[] memory tokenURIs
    ) public payable nonReentrant onlyOwner {
        require(amount > 0, "Amount should be greater than 0.");
        uint256[] memory ids;
        uint256 _tokenToMined;
        _amountDeposited[account] += amount;
        totalDeposit += amount;
        updateWhiteList(account, true);
        if (lemlContract.getBank() == address(this)) {
            _amountSaked[account] += amount;
            totalStaked += amount;
            _tokenToMined = amount * melmPerUSDT;
            lemlContract.mint(account, amount * melmPerUSDT);
        }
        if (tokenURIs.length == amount / OneNFTforUSDT) {
            ids = nftContract.mintNFTs(msg.sender, tokenURIs);
        }
        emit DepositAndStakeFor(account, amount, ids, _tokenToMined);
    }

    //
    function deposit(uint256 amount) public payable nonReentrant {
        require(
            amount >  minDeposit,
            "Amount is less than min deposit."
        );
        require(
            amount >  depositFee,
            "Amount is less than deposit fee."
        );
        require(
            usdtContract.allowance(msg.sender, address(this)) >= amount,
            "Allowance: Not enough usdt allowance to spend."
        );
        usdtContract.transferFrom(msg.sender, address(this), amount);
        _amountDeposited[msg.sender] += amount - depositFee;
        balances[msg.sender] += amount - depositFee;
        collectedFee += depositFee;
        totalDeposit += amount - depositFee;
        updateWhiteList(msg.sender, true);
        emit Deposit(msg.sender, amount);
    }

    function transferBalance(address account, uint256 amount) public  {
        require(
            balances[msg.sender] >= amount,
            "Not Enogh Balance To Transfer"
        );
        updateWhiteList(account, true);
        balances[msg.sender] -= amount;
        balances[account] += amount;
    }

    function stake(uint256 amount, string[] memory tokenURIs)
        public
        nonReentrant
    {
        // require(
        //     _amountDeposited[msg.sender] >= amount,
        //     "You haven't deposit any USDT"
        // );
        require(
            balances[msg.sender] >= amount,
            "You have not enough USDT to stake"
        );
        require(_isWhitelisted[msg.sender], "Account not whitelisted");
        uint256[] memory ids;
        uint256 _tokenToMined;

        balances[msg.sender] -= amount;
        _amountSaked[msg.sender] += amount;
        totalStaked += amount;
        // update price
        // mint MEML
        if (lemlContract.getBank() == address(this)) {
            updateLEMLPrice();
            _tokenToMined = amount * melmPerUSDT;
            lemlContract.mint(msg.sender, amount * melmPerUSDT);
        } else {
            claimableLEML[msg.sender] += amount * melmPerUSDT;
        }
        if (
            nftContract.getBank() == address(this) &&
            tokenURIs.length == amount / OneNFTforUSDT
        ) {
            ids = nftContract.mintNFTs(msg.sender, tokenURIs);
        } else {
            claimableNFT[msg.sender] += amount / OneNFTforUSDT;
        }
        emit Stake(msg.sender, amount, ids, _tokenToMined);
    }

    function claimLeml() public {
        require(claimableLEML[msg.sender] > 0, "Have not any calaimable LEML");
        require(lemlContract.getBank() == address(this), "Can't transfer LELM");
        lemlContract.mint(msg.sender, claimableLEML[msg.sender]);
        claimableLEML[msg.sender] = 0;
    }

    function claimNFT(string[] memory tokenURIs) public {
        require(claimableNFT[msg.sender] > 0, "Have not any calaimable LEML");
        require(nftContract.getBank() == address(this), "Can't mint NFT");
        require(
            tokenURIs.length == claimableNFT[msg.sender],
            "NFT link not in valid amount"
        );
        uint256[] memory ids = nftContract.mintNFTs(msg.sender, tokenURIs);
        claimableNFT[msg.sender] = 0;
        emit NFTmint(ids);
    }

    function updatebalanceUSDT(
        address account,
        uint256 newBalance,
        bool inc
    ) public onlyManager {
        if (inc) {
            rewards[account] += newBalance;
            totalrewardGoes += newBalance;
            balances[account] += newBalance;
        } else {
            if ((balances[account] + newBalance) < 0) {
                balances[account] = 0;
            } else {
                balances[account] -= newBalance;
            }
        }
    }

    // update maney blance
    function updatebalancesUSDT(
        address[] memory accounts,
        uint256[] memory amounts
    ) public onlyManager {
        require(
            accounts.length == amounts.length,
            "Data is not formated well."
        );
        for (uint256 i = 0; i < accounts.length; i++) {
            rewards[accounts[i]] += amounts[i];
            totalrewardGoes += amounts[i];
            balances[accounts[i]] += amounts[i];
        }
    }

    // update lrml price
    function updateLEMLPrice() private {
        uint256 percent = (lemlContract.totalSupply() * 100) /
            lemlContract.totalSupplyLimit();
        if (percent <= 25) melmPerUSDT = 25;
        else if (percent <= 35) melmPerUSDT = 20;
        else if (percent <= 50) melmPerUSDT = 15;
        else if (percent <= 75) melmPerUSDT = 14;
        else if (percent <= 80) melmPerUSDT = 13;
        else if (percent <= 85) melmPerUSDT = 12;
        else if (percent <= 90) melmPerUSDT = 10;
        else if (percent <= 92) melmPerUSDT = 9;
        else if (percent <= 94) melmPerUSDT = 8;
        else if (percent <= 95) melmPerUSDT = 7;
        else if (percent <= 100) melmPerUSDT = 5;
    }

    //
    function updateWhiteList(address account, bool add)
        private
        returns (address[] memory)
    {
        if (add) {
            if (_isWhitelisted[account]) return whitelistAddresses;
            whitelistAddresses.push(account);
            _whitelistedIndexes[account] = whitelistAddresses.length - 1;
            _isWhitelisted[account] = true;
            return whitelistAddresses;
        } else {
            uint256 index = _whitelistedIndexes[account];
            if (index >= whitelistAddresses.length) return whitelistAddresses;

            // address[] memory result ;
            address[] memory result = new address[](
                whitelistAddresses.length - 1
            );
            for (uint256 i = 0; i < whitelistAddresses.length; i++) {
                if (i < whitelistAddresses.length - 1) {
                    if (i < index) {
                        result[i] = whitelistAddresses[i];
                    } else {
                        result[i] = whitelistAddresses[i + 1];
                    }
                }
            }
            delete _whitelistedIndexes[account];
            whitelistAddresses = result;
            _isWhitelisted[account] = false;
            return whitelistAddresses;
        }
    }

    function withdraw(address account, uint256 amount) public {
        require(amount <= balances[account], "Balance not enough to withdraw.");
        require(
            amount > minWithdraw,
            "Amount is low than min withdraw."
        );
        require(
            amount > withdrawFee,
            "Amount is low than withdraw fee."
        );
        // require(_amountDeposited[account] > 0, "User has no deposits.");
        require(_isWhitelisted[account], "Account not whitelisted");
        require(
            usdtContract.balanceOf(address(this)) >= amount,
            "Not Enogh Balance In Emolume To withdraw"
        );
        _amountWithdrawn[account] += amount;

        balances[account] -= amount;
        collectedFee += withdrawFee;
        usdtContract.transfer(account, amount - withdrawFee);

        emit Withdraw(account, amount);
    }

    // public getters
    function getStaked() public view returns (uint256) {
        return _amountSaked[msg.sender];
    }

    function getWhiteListedAddresses() public view returns (address[] memory) {
        return whitelistAddresses;
    }

    function isManager() public view returns (bool) {
        return msg.sender == _manager;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    // function getCollectedFee() public view onlyOwner returns (uint256) {
    //     return collectedFee;
    // }

    function checkBalance() public view returns (uint256) {
        return _amountDeposited[msg.sender];
    }

    function checkStaked() public view returns (uint256) {
        return _amountSaked[msg.sender];
    }

    function checkWithdrawnAmount(address account)
        public
        view
        returns (uint256)
    {
        return _amountWithdrawn[account];
    }

    // manage contract by owner #####################################################################################

    function updateManager(address manager) public onlyOwner {
        _manager = manager;
    }

    function updateWhitelistAddresses(address[] memory accounts, bool _add)
        public
        onlyOwner
    {
        for (uint256 index = 0; index < accounts.length; index++) {
            updateWhiteList(accounts[index], _add);
        }
    }

    function addWhitelist(address account) public onlyOwner {
        updateWhiteList(account, true);
    }

    function removeWhitelist(address account) public onlyOwner {
        updateWhiteList(account, false);
    }

    function changeAdmin(address admin) public onlyOwner {
        _owner = admin;
    }

    function renounceOwnership() public onlyOwner {
        _owner = address(0);
    }

    function updateMEMLPerUSDT(uint256 amount) public onlyOwner {
        melmPerUSDT = amount;
    }
    function updateOneNFTForUSDT(uint256 amount) public onlyOwner {
        OneNFTforUSDT = amount;
    }

    function updateUSDTAddress(IERC20 _usdtContract) public onlyOwner {
        usdtContract = _usdtContract;
    }

    function updateMEMLAddress(IERC20 _lemlContract) public onlyOwner {
        lemlContract = _lemlContract;
    }

    function updateDepositFee(uint256 _depositFee) public onlyOwner {
        depositFee = _depositFee;
    }
    function updateMinDeposit(uint256 _minDeposit) public onlyOwner {
        minDeposit = _minDeposit;
    }
    function updateMinWithdraw(uint256 _minWithdraw) public onlyOwner {
        minWithdraw = _minWithdraw;
    }

    function updateWithdrawFee(uint256 _withdrawFee) public onlyOwner {
        withdrawFee = _withdrawFee;
    }

    function transferUSDT(address account, uint256 amount) public onlyOwner {
        require(
            usdtContract.balanceOf(address(this)) >= amount,
            "Not Enogh Balance In Emolume To withdraw"
        );
        usdtContract.transfer(account, amount);
    }
}