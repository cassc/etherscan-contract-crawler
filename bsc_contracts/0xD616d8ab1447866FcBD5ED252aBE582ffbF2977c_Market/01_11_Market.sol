// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC1155Burnable {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}

interface IERC1155Mintable {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

interface IERC1155SnapShot {
    function snapshot() external returns (uint256);

    function balanceOfAt(
        address account,
        uint256 tokenId,
        uint256 snapshotId
    ) external view returns (uint256);
}

interface IOracle {
    function random(uint256 blockNumber) external returns (uint256);
}

enum PayType {
    USDT,
    MTS,
    Both
}

contract Market is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant FEE_DENOMINATOR = 100;
    uint256 public constant SALES_VOLUMES = 2000;

    uint8 public paymentType = uint8(PayType.Both);

    uint256 public winner = 0;
    uint256 public jackpot = 0;
    uint256 public fund = 0;
    uint256 public partA = 0;
    uint256 public partB = 0;

    address public payee;
    address public fundPayee;
    address public techPayee;

    address public immutable token = 0x55d398326f99059fF775485246999027B3197955;
    address public box;
    address public card;
    address public mtsToken;

    address public oracle;

    uint256 private _interval = 7 days;
    uint256 private _snapshotId = 0;
    uint256 private _startEpochTime = 0;
    uint256 private _currentEpochTime = 0;

    mapping(address => address) public superior;

    mapping(address => bool) public winnerReward;

    mapping(address => TraderReward) private _traders;
    mapping(address => User) private _users;

    mapping(uint256 => uint256) private _cardSales;

    mapping(address => mapping(uint256 => uint256)) private _periodVolumes;

    struct User {
        uint256 purchases;
        uint256 userRewards;
        uint256 userRequest;
    }

    struct TraderReward {
        uint256 volume;
        uint256 reward;
        uint256 currentPeriod;
    }

    event Claimed(address indexed account, uint256 amount, uint256 period);
    event WinnerClaimed(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, address indexed token_, uint256 amount);
    event WithdrawnFund(address indexed account, address indexed token_, uint256 amount);
    event Won(uint256 tokenId,uint256 snapshotId);
    event PayeeUpdated(address previousPayee, address newPayee);
    event FundPayeeUpdated(address previousPayee, address newPayee);
    event TechPayeeUpdated(address previousPayee, address newPayee);
    event PaymentTypeUpdated(uint8 previous, uint8 newPaymentType);
    
    constructor(address box_,
        address card_,
        address payee_,
        address fundPayee_,
        address techPayee_,
        address mtsToken_
    ) {
        require(
            payee_ != address(0) &&
            fundPayee_ != address(0) &&
            techPayee_ != address(0) &&
            box_ != address(0) &&
            card_ != address(0) &&
            mtsToken_ != address(0),
            "address is zero"
        );
        payee = payee_;
        fundPayee = fundPayee_;
        techPayee = techPayee_;
        mtsToken = mtsToken_;
        box = box_;
        card = card_;
        
        _startEpochTime = block.timestamp;
        _currentEpochTime = block.timestamp + _interval;
    }

    modifier advanceTraderRewards(address account) {
        _currentEpochTime = getCurrentEpochTime();
        if (_currentEpochTime > _traders[account].currentPeriod) {
            _traders[account].currentPeriod = _currentEpochTime;
            if (_traders[account].volume >= SALES_VOLUMES * 1e18) {
                _traders[account].reward += 
                    _traders[account].volume
                    .mul(5).div(FEE_DENOMINATOR);
            }

            _traders[account].volume = 0;
        }
        _;
    }

    function getCurrentEpochTime() public view returns (uint256) {
        return 
            block.timestamp < _currentEpochTime ? 
            _currentEpochTime :
            _currentEpochTime + _interval * _calcPeriod();
    }

    function claimableRewards(address account) external view returns (uint256) {
        return
            getCurrentEpochTime() > _traders[account].currentPeriod &&
            _traders[account].volume >= SALES_VOLUMES * 1e18 ?
            _traders[account].volume.mul(5).div(FEE_DENOMINATOR) + 
            _traders[account].reward :
            _traders[account].reward;
    }

    function getCurrentEpochVolume(address account) external view returns (uint256) {
        return _periodVolumes[account][getCurrentEpochTime()];
    }

    function getVolumeOfUser(address account) external view returns (uint256) {
        return _users[account].purchases;
    }

    function getUserReward(address account) external view returns (uint256) {
        return _users[account].userRewards;
    }

    function share(address account) public view returns (uint256) {
        if (winner == 0 || _cardSales[winner] == 0) {
            return 0;
        }
        
        uint256 count = IERC1155SnapShot(card).balanceOfAt(account, winner, _snapshotId);
        return jackpot.mul(count).div(_cardSales[winner]);
    }

    function hasRequest(address account) public view returns (bool) {
        return
            _users[account].userRequest < block.number &&
            _users[account].userRequest > (block.number - 256);
    }

    function setOracle(address oracle_) external onlyOwner {
        oracle = oracle_;
    }

    function setPayee(address newPayee) external onlyOwner {
        address previousPayee = payee;
        payee = newPayee;
        emit PayeeUpdated(previousPayee, newPayee);
    }

    function setFundPayee(address newFundPayee) external onlyOwner {
        address previousPayee = fundPayee;
        fundPayee = newFundPayee;
        emit FundPayeeUpdated(previousPayee, newFundPayee);
    }
    
    function setTechPayee(address newTechPayee) external onlyOwner {
        address previousPayee = techPayee;
        techPayee = newTechPayee;
        emit TechPayeeUpdated(previousPayee, newTechPayee);
    }

    function setPaymentType(uint8 newPaymentType) external onlyOwner {
        require(newPaymentType < 3,"Invalid payment type");
        uint8 previous = paymentType;
        paymentType = newPaymentType;
        emit PaymentTypeUpdated(previous,newPaymentType);
    }

    function request() external nonReentrant {
        _users[_msgSender()].userRequest = block.number + 1;
    }

    function purchase(address account, address token_, uint256 amount, uint256 source)
        external
        nonReentrant
        advanceTraderRewards(superior[account]) {
        require(winner == 0,"The game is over");
        require(
            (token_ == token && uint8(PayType.USDT) == paymentType) 
            || (token_ == mtsToken && uint8(PayType.MTS) == paymentType)
            || ((token_ == token || token_ == mtsToken) &&
             uint8(PayType.Both) == paymentType),
            "Invalid token");
        require(amount > 0,"Invalid amount");

        uint256 totalPrice = amount.mul(10).mul(1e18);
        _executeTransferFrom(token_,_msgSender(),totalPrice);
        if (source == 1) {
            partA += totalPrice;
        }
        if (source == 2) {
            partB += totalPrice;
        }
        
        if ((account != address(0) && 
            (superior[account] != _msgSender())) ||
            (account == address(0) && superior[_msgSender()] != address(0))
        ) { 
            require(account != _msgSender(),"Inviter cannot be yourself");
            if (superior[_msgSender()] == address(0) && 
                superior[account] != _msgSender()
            ) {
                superior[_msgSender()] = account;
            }
            address upper = superior[_msgSender()];
            address higher = superior[upper];

            uint256 reward = totalPrice.mul(10).div(100);
            _executeTransfer(upper, reward);
            _users[upper].userRewards += reward;
            _users[upper].purchases += totalPrice;
            fund -= reward;  

            if (higher != address(0)) {
                _traders[higher].volume += totalPrice;
                _periodVolumes[higher][_currentEpochTime] += totalPrice;
            }
        }

        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        IERC1155Mintable(box).mintBatch(_msgSender(), ids, amounts, "");
    }
    
    function open() external nonReentrant {
        require(hasRequest(_msgSender()), "Invalid block number");
        
        uint256 tokenId = IOracle(oracle).random(_users[_msgSender()].userRequest);
        if (winner == 0) {
            _cardSales[tokenId] += 1;
        }
        
        _users[_msgSender()].userRequest = 0;
        
        IERC1155Burnable(box).burn(_msgSender(),1,1);
        IERC1155Mintable(card).mint(_msgSender(), tokenId, 1, "");
    }

    function win(uint256 tokenId) external onlyOwner {
        require(_snapshotId == 0 && winner == 0,"Aready set");
        winner = tokenId;
        _snapshotId = IERC1155SnapShot(card).snapshot();
        emit Won(tokenId,_snapshotId);
    }

    function withdrawFund(address token_,uint256 amount) external onlyOwner {
        require(winner != 0,"The game is not over yet");
        require(token_ == token || token_ == mtsToken,"Invalid token");
        require(amount <= fund,"Invalid amount");

        fund -= amount;
        IERC20(token_).safeTransfer(fundPayee,amount);
        emit WithdrawnFund(fundPayee,token_, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(winner != 0,"The game is not over yet");
        require(
            amount <= IERC20(token).balanceOf(address(this))
            .sub(jackpot).sub(fund)
            ,"invalid amount"
        );

        IERC20(token).safeTransfer(_msgSender(),amount);
        emit Withdrawn(_msgSender(),token, amount);
    }

    function claim() external nonReentrant advanceTraderRewards(_msgSender()){
        TraderReward memory trader = _traders[_msgSender()];
        if (trader.currentPeriod == 0) {
            require(
                block.timestamp >= 
                _startEpochTime + _interval,
                "The current cycle has not ended"
            );
        }

        uint256 reward = trader.reward;
        require(reward > 0,"Fail to reach");
        _users[_msgSender()].userRewards += reward;
        fund -= reward;

        IERC20(token).safeTransfer(_msgSender(),reward);
        trader.reward = 0;

        _traders[_msgSender()] = trader;
        emit Claimed(_msgSender(), reward, trader.currentPeriod);
    }

    function winnerClaim() external nonReentrant {
        require(winner != 0,"The game is not finished");
        require(!winnerReward[_msgSender()],"Already received");
        winnerReward[_msgSender()] = true;

        uint256 reward = share(_msgSender());
        _users[_msgSender()].userRewards += reward;
        IERC20(token).safeTransfer(_msgSender(),reward);
        emit WinnerClaimed(_msgSender(),reward);
    }

    function _calcPeriod() internal view returns (uint256) {
        uint256 epochs = block.timestamp.sub(_currentEpochTime).div(_interval);
        return epochs + 1;
    }

    function _executeTransferFrom(address token_, address from, uint256 amount) private {
        uint256 fundAmount = amount.mul(15).div(100);
        uint256 payeeAmount = amount.mul(39).div(100);
        uint256 techAmount = amount.mul(1).div(100);
        jackpot += amount - fundAmount.mul(2) - payeeAmount - techAmount;
        fund += fundAmount;
        
        IERC20(token_).safeTransferFrom(from,address(this),amount);

        _executeTransfer(payee,payeeAmount);
        _executeTransfer(techPayee,techAmount);
        _executeTransfer(fundPayee,fundAmount);
    }

    function _executeTransfer(address to,uint256 amount) private {
        IERC20(token).safeTransfer(to, amount);
    }
}