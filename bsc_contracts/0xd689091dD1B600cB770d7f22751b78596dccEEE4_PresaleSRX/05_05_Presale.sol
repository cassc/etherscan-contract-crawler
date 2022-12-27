// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PresaleSRX is Ownable {
    //Price feeds
    AggregatorV3Interface public btcPriceFeed;
    AggregatorV3Interface public bnbPriceFeed;

    //Token address
    address public btcAddress;
    address public bnbAddress;
    address public usdcAddress;
    address public busdAddress;

    //Total tokens in contract
    uint256 public btcAmountInContract;
    uint256 public bnbAmountInContract;
    uint256 public usdcAmountInContract;
    uint256 public busdAmountInContract;

    //SRX token address
    address public srxAddress;

    //Presale start and end time
    uint256 public startTime;
    uint256 public endTime;

    //Presale token price 0.25 usd in usdc = 4 times the coins
    uint256 public srxPrice = 4;

    //Presale hard cap per wallet = 5000 usd
    uint256 public hardCapPerWallet = 5000 * 10 ** 18;

    //Presale min entry = 20 usd
    uint256 public minEntry = 20 * 10 ** 18;

    //Presale token amount 6m
    uint256 public srxAmount = 6000000 * 10 ** 18;

    //Presale token amount sold
    uint256 public srxAmountSold = 0;

    //Presale token amount left
    uint256 public srxAmountLeft = srxAmount;

    //Presale token amount claimed
    uint256 public srxAmountClaimed = 0;

    //Total participants
    uint256 public totalParticipants = 0;

    //Presale user to token amounts
    mapping(address => uint256) public userToBtcTokenAmount;
    mapping(address => uint256) public userToBnbTokenAmount;
    mapping(address => uint256) public userToUsdcTokenAmount;
    mapping(address => uint256) public userToBusdTokenAmount;

    //Presale user to total tokens to claim
    mapping(address => uint256) public userToTotalTokenToClaim;

    //User already tracked
    mapping(address => bool) public userAlreadyTracked;

    //User to total srx token value
    mapping(address => uint256) public userToTotalSrxTokenValue;

    //Events
    event PresaleStarted(uint256 startTime, uint256 endTime);
    event PresaleClaimed(address user, uint256 amount);
    event PresaleTokensBought(
        address user,
        uint256 amount,
        uint256 price,
        address token
    );

    event TokensWithdrawn(address reciever);
    event SRXBurned(uint256 amount);
    event PresaleEndedEarly(uint256 time);

    //constructor
    constructor() {
        //Set price feeds
        btcPriceFeed = AggregatorV3Interface(
            0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf
        );
        bnbPriceFeed = AggregatorV3Interface(
            0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        );

        //Set token addresses
        btcAddress = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
        bnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        usdcAddress = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
        busdAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

        //Set SRX token address
        srxAddress = 0xDeF49c195099E30E41B2df7dAd55E0BbBe60A0C5;
    }

    //Start presale
    function startPresale(
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        require(
            IERC20(srxAddress).balanceOf(address(this)) >= srxAmount,
            "Presale: Not enough tokens in contract"
        );
        require(
            _startTime > block.timestamp,
            "Presale: Start time is in the past"
        );
        require(
            _endTime > _startTime,
            "Presale: End time is before start time"
        );
        startTime = _startTime;
        endTime = _endTime;
        emit PresaleStarted(_startTime, _endTime);
    }

    //Claim presale
    function claimPresale() external {
        require(block.timestamp > endTime, "Presale: Presale is still ongoing");
        require(
            userToTotalTokenToClaim[msg.sender] > 0,
            "Presale: No tokens to claim"
        );
        require(
            srxAmountClaimed < srxAmount,
            "Presale: All tokens have been claimed"
        );
        require(
            srxAmountClaimed + userToTotalTokenToClaim[msg.sender] <= srxAmount,
            "Presale: Not enough tokens left to claim"
        );
        require(
            IERC20(srxAddress).transfer(
                msg.sender,
                userToTotalTokenToClaim[msg.sender]
            ),
            "Presale: Transfer failed"
        );
        srxAmountClaimed += userToTotalTokenToClaim[msg.sender];
        emit PresaleClaimed(msg.sender, userToTotalTokenToClaim[msg.sender]);
        userToTotalTokenToClaim[msg.sender] = 0;
    }

    //getTokenPrice function
    function getTokenPrice(
        address _tokenAddress
    ) public view returns (uint256) {
        if (_tokenAddress == btcAddress) {
            (, int256 price, , , ) = btcPriceFeed.latestRoundData();
            return uint256(price);
        } else if (_tokenAddress == bnbAddress) {
            (, int256 price, , , ) = bnbPriceFeed.latestRoundData();
            return uint256(price);
        } else if (_tokenAddress == usdcAddress) {
            //Hard coding the USDC price to 1 USD to avoid price feed errors and its a stable coin
            return 10 ** 8;
        } else if (_tokenAddress == busdAddress) {
            //Hard coding the BUSD price to 1 USD to avoid price feed errors and its a stable coin
            return 10 ** 8;
        } else {
            return 0;
        }
    }

    //Buy srx with any token by specifiying address
    function buySRXWithToken(address _tokenAddress, uint256 _amount) external {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Presale: Presale is not ongoing"
        );
        require(
            srxAmountSold < srxAmount,
            "Presale: All tokens have been sold"
        );
        require(
            srxAmountSold + srxAmountLeft >= srxAmount,
            "Presale: Not enough tokens left to sell"
        );

        require(
            userToTotalSrxTokenValue[msg.sender] <= hardCapPerWallet,
            "Presale: User has already bought the maximum amount of tokens per wallet"
        );

        require(
            _tokenAddress == btcAddress ||
                _tokenAddress == bnbAddress ||
                _tokenAddress == usdcAddress ||
                _tokenAddress == busdAddress,
            "Presale: Invalid token address"
        );
        require(
            IERC20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Presale: Transfer failed"
        );
        uint256 tokenPrice = (getTokenPrice(_tokenAddress) / 10 ** 8);
        uint256 buyingPower = _amount * tokenPrice;
        uint256 tokenAmount = buyingPower * srxPrice;

        require(
            tokenAmount <= srxAmountLeft,
            "Presale: Not enough tokens left to sell"
        );

        require(buyingPower >= minEntry, "Presale: Buying power is too low");

        require(
            userToTotalSrxTokenValue[msg.sender] + buyingPower <=
                hardCapPerWallet,
            "Presale: User cannot exceed hard cap of tokens per wallet"
        );

        userToTotalSrxTokenValue[msg.sender] += buyingPower;

        if (_tokenAddress == btcAddress) {
            userToBtcTokenAmount[msg.sender] += _amount;
            btcAmountInContract += _amount;
        } else if (_tokenAddress == bnbAddress) {
            userToBnbTokenAmount[msg.sender] += _amount;
            bnbAmountInContract += _amount;
        } else if (_tokenAddress == usdcAddress) {
            userToUsdcTokenAmount[msg.sender] += _amount;
            usdcAmountInContract += _amount;
        } else if (_tokenAddress == busdAddress) {
            userToBusdTokenAmount[msg.sender] += _amount;
            busdAmountInContract += _amount;
        }
        userToTotalTokenToClaim[msg.sender] += tokenAmount;

        srxAmountSold += tokenAmount;
        srxAmountLeft -= tokenAmount;

        if (!userAlreadyTracked[msg.sender]) {
            userAlreadyTracked[msg.sender] = true;
            totalParticipants = totalParticipants + 1;
        }

        emit PresaleTokensBought(
            msg.sender,
            tokenAmount,
            tokenPrice,
            _tokenAddress
        );
    }

    //Presale sold early
    function soldEarly() external onlyOwner {
        require(block.timestamp < endTime, "Presale: Presale is not ongoing");
        require(srxAmount <= srxAmountSold, "Presale: Presale is not sold out");

        endTime = block.timestamp;
        emit PresaleEndedEarly(endTime);
    }

    //withdrawl all tokens to owner
    function withdrawAllTokens() external onlyOwner {
        require(block.timestamp > endTime, "Presale: Presale is still ongoing");
        require(
            IERC20(btcAddress).transfer(
                owner(),
                IERC20(btcAddress).balanceOf(address(this))
            ),
            "Presale: Transfer failed"
        );
        require(
            IERC20(bnbAddress).transfer(
                owner(),
                IERC20(bnbAddress).balanceOf(address(this))
            ),
            "Presale: Transfer failed"
        );
        require(
            IERC20(usdcAddress).transfer(
                owner(),
                IERC20(usdcAddress).balanceOf(address(this))
            ),
            "Presale: Transfer failed"
        );
        require(
            IERC20(busdAddress).transfer(
                owner(),
                IERC20(busdAddress).balanceOf(address(this))
            ),
            "Presale: Transfer failed"
        );

        emit TokensWithdrawn(owner());
    }

    //Burn all SRX that is left and not sold
    function burnAllSRX() external onlyOwner {
        require(block.timestamp > endTime, "Presale: Presale is still ongoing");

        emit SRXBurned(srxAmountLeft);
        srxAmountLeft = 0;
    }
}