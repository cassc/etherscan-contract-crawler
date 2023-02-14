// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract XPROFuturesSale is ReentrancyGuard, Ownable {
    uint256 public futuressaleId;
    uint256 public DISCOUNT_RATE = 5;
    uint256 public DISCOUNT_MONTHS = 4;
    uint256 public MONTH = (30 * 24 * 3600);

    struct FuturesSale {
        address saleToken;
        uint256 amountPerBNB;
        uint256 tokensToSellAmount;
        uint256 inSale;
    }

    struct Vesting {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 buyTime;
        uint256 claimTime;
    }

    mapping(address => bool) private _BlackList;
    mapping(uint256 => bool) public paused;
    mapping(uint256 => FuturesSale) public futuressale;
    mapping(address => mapping(uint256 => Vesting)) public userVesting;

    event FuturesSaleCreated(
        uint256 indexed _id,
        uint256 _totalTokens
    );

    event FuturesSaleUpdated(
        bytes32 indexed key,
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );

    event TokensBought(
        address indexed user,
        uint256 indexed id,
        address indexed purchaseToken,
        uint256 tokensBought,
        uint256 amountPaid,
        uint256 timestamp
    );

    event TokensClaimed(
        address indexed user,
        uint256 indexed id,
        uint256 amount,
        uint256 timestamp
    );

    event FuturesSaleTokenAddressUpdated(
        address indexed prevValue,
        address indexed newValue,
        uint256 timestamp
    );

    event FuturesSalePaused(uint256 indexed id, uint256 timestamp);
    event FuturesSaleUnpaused(uint256 indexed id, uint256 timestamp);
    event Withdrawn(address token, uint256 amount);


    /**
     * @dev Creates a new futuressale
     * @param _amountPerBNB amount Per 1 BNB
     * @param _tokensToSellAmount No of tokens to sell without denomination. If 1 million tokens to be sold then - 1_000_000 has to be passed
     */
    function createFuturesSale(uint256 _amountPerBNB, uint256 _tokensToSellAmount) external onlyOwner {
        require(_amountPerBNB > 0, "Zero amount per 1 BNB");
        require(_tokensToSellAmount > 0, "Zero tokens to sell");

        futuressaleId++;

        futuressale[futuressaleId] = FuturesSale(
            address(0),
            _amountPerBNB,
            _tokensToSellAmount,
            _tokensToSellAmount
        );

        emit FuturesSaleCreated(futuressaleId, _tokensToSellAmount);
    }

    /**
     * @dev To update the sale token address
     * @param _id FuturesSale id to update
     * @param _newAddress Sale token address
     */
    function changeSaleTokenAddress(uint256 _id, address _newAddress) external checkFuturesSaleId(_id) onlyOwner
    {
        require(_newAddress != address(0), "Zero token address");
        address prevValue = futuressale[_id].saleToken;
        futuressale[_id].saleToken = _newAddress;
        emit FuturesSaleTokenAddressUpdated(
            prevValue,
            _newAddress,
            block.timestamp
        );
    }

    /**
     * @dev To update the token amount per BNB
     * @param _id FuturesSale id to update
     * @param _newAmountPerBNB New amount per BNB
     */
    function changeAmountPerBNB(uint256 _id, uint256 _newAmountPerBNB) external checkFuturesSaleId(_id) onlyOwner
    {
        require(_newAmountPerBNB > 0, "Zero amount per 1 BNB");
        uint256 prevValue = futuressale[_id].amountPerBNB;
        futuressale[_id].amountPerBNB = _newAmountPerBNB;
        emit FuturesSaleUpdated(
            bytes32("AMOUNTPERBNB"),
            prevValue,
            _newAmountPerBNB,
            block.timestamp
        );
    }

    /**
     * @dev To pause the futuressale
     * @param _id FuturesSale id to update
     */
    function pauseFuturesSale(uint256 _id) external checkFuturesSaleId(_id) onlyOwner {
        require(!paused[_id], "Already paused");
        paused[_id] = true;
        emit FuturesSalePaused(_id, block.timestamp);
    }

    /**
     * @dev To unpause the futuressale
     * @param _id FuturesSale id to update
     */
    function unPauseFuturesSale(uint256 _id) external checkFuturesSaleId(_id) onlyOwner
    {
        require(paused[_id], "Not paused");
        paused[_id] = false;
        emit FuturesSaleUnpaused(_id, block.timestamp);
    }

    modifier checkFuturesSaleId(uint256 _id) {
        require(_id > 0 && _id <= futuressaleId, "Invalid futuressale id");
        _;
    }


    function setBlacklistStatus(address _account, bool status) external onlyOwner {
        _BlackList[_account] = status;
    }

    function isBlackList(address _account) external view returns (bool) {
        return _BlackList[_account];
    }

    /**
     * @dev To buy into a futuressale using BNB
     * @param _id FuturesSale id
     * @param period Claim Period
     */
    function buyToken(uint256 _id, uint256 period) external payable checkFuturesSaleId(_id) nonReentrant returns (bool)
    {
        require(!paused[_id], "FuturesSale paused");
        require(!_BlackList[_msgSender()], "The wallet has been blacklisted for suspicious transaction");
        require(period % 4 == 0, "Period is not allowed");

        uint256 discount = (period / DISCOUNT_MONTHS) * DISCOUNT_RATE;
        uint256 transferFee = 5;
        // 5% fee for XPRO Token
        require((msg.value >= 1 * 10 ** 17), "The amount of BNB attempted to be paid does not meet the minimum requirement.");
        uint256 totalBNB = msg.value / (10 ** 18);
        uint256 normalAmount = msg.value * futuressale[_id].amountPerBNB;
        uint256 amount = (normalAmount + (normalAmount * ((discount + transferFee) / 100))) / (10 ** 18);

        require(
            amount > 0,
            "Token amount not greater than zero"
        );

        require(
            amount <= futuressale[_id].inSale,
            "Token amount is less than the amount on sale"
        );

        futuressale[_id].inSale -= amount;

        if (userVesting[_msgSender()][_id].totalAmount > 0) {
            userVesting[_msgSender()][_id].totalAmount += amount;
        } else {
            userVesting[_msgSender()][_id] = Vesting(
                amount,
                0,
                block.timestamp,
                block.timestamp + (period * MONTH)
            );
        }
        emit TokensBought(
            _msgSender(),
            _id,
            address(0),
            amount,
            totalBNB,
            block.timestamp
        );
        return true;
    }

    /**
     * @dev Helper funtion to get claimable tokens
     * @param user User address
     * @param _id FuturesSale id
     */
    function claimableAmount(address user, uint256 _id) public view checkFuturesSaleId(_id) returns (uint256)
    {
        Vesting memory _user = userVesting[user][_id];
        require(!_BlackList[_msgSender()], "The wallet has been blacklisted for suspicious transaction");
        require(_user.totalAmount > 0, "Nothing to claim");
        uint256 amount = _user.totalAmount - _user.claimedAmount;
        require(amount > 0, "Already claimed");
        return amount;
    }

    /**
     * @dev To claim tokens
     * @param user User address
     * @param _id FuturesSale id
     */
    function claim(address user, uint256 _id) public returns (bool) {
        require(!_BlackList[_msgSender()], "The wallet has been blacklisted for suspicious transaction");
        uint256 amount = claimableAmount(user, _id);
        require(amount > 0, "Zero claim amount");
        uint256 sentAmount = amount * (10 ** 9);
        // XPRO Decimals
        require(futuressale[_id].saleToken != address(0), "FuturesSale token address not set");
        require(
            sentAmount <= IERC20(futuressale[_id].saleToken).balanceOf(address(this)),
            "Not enough tokens in the contract"
        );
        if (user != this.owner()) {
            require(
                userVesting[user][_id].claimTime >= block.timestamp,
                "The time required for the claim has not expired"
            );
        }
        userVesting[user][_id].claimedAmount += amount;
        bool status = IERC20(futuressale[_id].saleToken).transfer(user, sentAmount);
        require(status, "Token transfer failed");
        emit TokensClaimed(user, _id, amount, block.timestamp);
        return true;
    }

    function withdrawTokens(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit Withdrawn(tokenAddress, tokenAmount);
    }

    function withdrawBNB(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}