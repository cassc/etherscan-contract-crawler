/**
 *Submitted for verification at Etherscan.io on 2023-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable is Context {
    address private _owner;

    // Set original owner
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    // Return current owner
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Restrict function to contract owner only
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Renounce ownership of the contract
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Transfer the contract to to a new owner
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract DogeCookiePresale is Ownable {
    AggregatorV3Interface internal priceFeed;
    uint256 public presaleNo = 1;
    uint256 public priceInUsdt = 100; // 0.0001 usdt (USDT 6 decimals chain eth )
    uint256 public tokenDecimals = 9;
    uint256 public supply = 30000000000 * 10 ** tokenDecimals;
    uint256 public usdtDecimal = 10 ** 6;
    uint256 public referralProfit = 10; // 1 percent

    IERC20 token;
    IERC20 usdt;

    uint256 public totalDckAllowance = 0;
    uint256 public totalUsdtAllowance = 0;
    uint256 public totalEthAllowance = 0;
    mapping(string => address) public codeToAddress;
    mapping(string => uint256) public codeToPackage;
    mapping(address => uint256) public allowanceDck;
    mapping(address => uint256) public allowanceUsdt;
    mapping(address => uint256) public allowanceEth;
    mapping(address => uint256) public totalReferrals; //count of total number of referrals
    mapping(address => uint256) public totalReferralAmountInUsdt; //amount of usdt purchasecd by a referral code

    event PurchaseWithUsdt(
        uint256 usdtAmount,
        uint256 tokenAmount,
        address buyer
    );

    event PurchaseWithNativeToken(
        uint256 ethAmount,
        uint256 token,
        address buyer
    );

    constructor() {
        token = IERC20(0x21D5AF064600f06F45B05A68FddC2464A5dDaF87); // mainnet
        usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); //mainnet
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 //mainnet
        );
        
    }

    function getSplit(uint256 percent) private pure returns (uint256, uint256) {
        uint256 dck = (3 * percent) / 10;
        uint256 native = percent - dck;
        return (native, dck);
    }

    function getPercentages(
        uint256 packageId,
        uint256 usdtAmount
    ) private view returns (uint256, uint256) {
        if (
            usdtAmount >= (100 * usdtDecimal) &&
            usdtAmount < (200 * usdtDecimal)
        ) {
            if (packageId == 1) {
                return getSplit(50);
            } else if (packageId == 2) {
                return getSplit(35);
            }
            return (0, 0);
        } else if (
            usdtAmount >= (200 * usdtDecimal) &&
            usdtAmount < (500 * usdtDecimal)
        ) {
            if (packageId == 3) {
                return getSplit(55);
            } else if (packageId == 4) {
                return getSplit(40);
            }
            return (0, 0);
        } else if (
            usdtAmount >= (500 * usdtDecimal) &&
            usdtAmount < (1000 * usdtDecimal)
        ) {
            if (packageId == 5) {
                return getSplit(60);
            } else if (packageId == 6) {
                return getSplit(45);
            }
            return (0, 0);
        } else if (
            usdtAmount >= (1000 * usdtDecimal) &&
            usdtAmount < (2000 * usdtDecimal)
        ) {
            if (packageId == 7) {
                return getSplit(65);
            } else if (packageId == 8) {
                return getSplit(50);
            }
            return (0, 0);
        } else if (
            usdtAmount >= (2000 * usdtDecimal) &&
            usdtAmount < (5000 * usdtDecimal)
        ) {
            if (packageId == 9) {
                return getSplit(70);
            } else if (packageId == 10) {
                return getSplit(55);
            }
            return (0, 0);
        } else if (
            usdtAmount >= (5000 * usdtDecimal) &&
            usdtAmount < (10000 * usdtDecimal)
        ) {
            if (packageId == 11) {
                return getSplit(80);
            } else if (packageId == 12) {
                return getSplit(65);
            }
            return (0, 0);
        } else if (usdtAmount >= (10000 * usdtDecimal)) {
            if (packageId == 13) {
                return getSplit(100);
            } else if (packageId == 14) {
                return getSplit(75);
            }
            return (0, 0);
        }
        return (0, 0);
    }

    function takeReferralProfits(address wallet) private {
        uint256 dckPart = allowanceDck[wallet];
        uint256 usdtPart = allowanceUsdt[wallet];
        uint256 native = allowanceEth[wallet];
        if (dckPart > 0) {
            token.transfer(msg.sender, dckPart);
            allowanceDck[wallet] = 0;
            totalDckAllowance -= dckPart;
        }
        if (usdtPart > 0) {
            usdt.transfer(msg.sender, usdtPart);
            allowanceUsdt[wallet] = 0;
            totalUsdtAllowance -= usdtPart;
        }
        if (native > 0) {
            payable(wallet).transfer(native);
        }
    }

    function issueProfits(address wallet) public onlyOwner {
        takeReferralProfits(wallet);
    }

    function makePurchase(
        uint256 tokenAmount,
        uint256 usdtAmount,
        uint256 ethValue,
        bool isEthPurchase,
        string calldata code
    ) private returns (uint256) {
        require(supply >= tokenAmount, "Not Enough Tokens : 1");
        uint256 finalTokenAmount = tokenAmount;

        if (codeToAddress[code] != address(0)) {
            // this means that a valid referral code has been passed by the user
            totalReferralAmountInUsdt[codeToAddress[code]] += usdtAmount;
            (uint256 usdtP, uint256 dckP) = getPercentages(
                    usdtAmount,
                    codeToPackage[code]
                );
            if (usdtP != 0 || dckP != 0) {
                
                    uint256 usdtPart = (usdtAmount * usdtP) / 1000;
                    uint256 ethPart = (ethValue * usdtP) / 1000;
                    uint256 dckPart = (tokenAmount * dckP) / 1000;
                    uint256 userExtra = (tokenAmount * referralProfit) / 1000;

                    require(
                        supply >= tokenAmount + dckPart + userExtra,
                        "Not Enough Tokens : 2"
                    );

                    totalReferrals[codeToAddress[code]]++;
                    allowanceDck[codeToAddress[code]] += dckPart;
                    totalDckAllowance += dckPart;

                    if (isEthPurchase) {
                        allowanceEth[codeToAddress[code]] += ethPart;
                        totalEthAllowance += ethPart;
                    } else {
                        allowanceUsdt[codeToAddress[code]] += usdtPart;
                        totalUsdtAllowance += usdtPart;
                    }

                    finalTokenAmount += userExtra;
                    if (codeToPackage[code] % 2 == 0) {
                        if (totalReferrals[codeToAddress[code]] % 5 == 0) {
                            takeReferralProfits(codeToAddress[code]);
                        }
                    } else {
                        if (totalReferrals[codeToAddress[code]] % 10 == 0) {
                            takeReferralProfits(codeToAddress[code]);
                        }
                    }
            }
        }
        token.transfer(msg.sender, finalTokenAmount);
        supply -= finalTokenAmount;
        return tokenAmount;
    }

    function buyWithUsdt(uint256 _amountUsdt, string calldata code) public {
        // for 1 usdt => _amountUsdt = 1000000 -> 1e6
        require(
            _amountUsdt >= priceInUsdt,
            "Amount cannot be less than sell price"
        );
        usdt.transferFrom(msg.sender, address(this), _amountUsdt);
        uint256 tokenAmount = (_amountUsdt * 10 ** tokenDecimals) / priceInUsdt; // multiplied with 10^9 for 9 decimal dck token
        uint256 totalIssued = makePurchase(
            tokenAmount,
            _amountUsdt,
            0,
            false,
            code
        );
        emit PurchaseWithUsdt(_amountUsdt, totalIssued, msg.sender);
    }

    function buyWithNativeToken(
        uint256 _amountEth,
        string calldata code
    ) public payable {
        // for 1 eth => _amountEth = 1000000000000000000 -> 1e18
        require(_amountEth > 0, "Amount cannot be zero");
        require(msg.value == _amountEth, "Invalid value and amount");
        uint256 amountInUsdt = (uint256(getThePrice()) * _amountEth) / 10 ** 18;
        require(
            amountInUsdt >= priceInUsdt,
            "Amount cannot be less than sell price"
        );
        uint256 tokenAmount = (amountInUsdt * 10 ** tokenDecimals) /
            priceInUsdt;
        uint256 totalIssued = makePurchase(
            tokenAmount,
            amountInUsdt,
            _amountEth,
            true,
            code
        );
        emit PurchaseWithNativeToken(_amountEth, totalIssued, msg.sender);
    }

    function getThePrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        //divide by 100 because the price is returned iwth 8 decimals , divide to make it standard 6 decimals 
        // multiple by 10^10 because the price is returned with 8 decimals , multiply to make it standard 18 decimals
        return price / 100;
    }

    function updatePresale(
        uint256 _presaleNo,
        uint256 _supply,
        uint256 _priceInUsdt
    ) public onlyOwner {
        presaleNo = _presaleNo;
        supply = _supply;
        priceInUsdt = _priceInUsdt;
    }

    function withdrawPresaleTokens() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        supply -= balance;
        token.transfer(msg.sender, balance);
    }

    function withdrawUsdt() public onlyOwner {
        uint256 balance = usdt.balanceOf(address(this));
        usdt.transfer(msg.sender, balance);
    }

    function withdrawNativeToken() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    //for 1 % => percent should be 10
    function updateReferralProfit(uint256 percent) public onlyOwner {
        require(percent >= 0 && percent <= 1000, "Invalid percent");
        referralProfit = percent;
    }

    function registerPresaleCode(
        string memory code,
        address wallet,
        uint256 _package
    ) public {
        require(_package > 0 && _package <= 14, "Invalid package");
        require(codeToAddress[code] == address(0), "Code already in use");
        codeToAddress[code] = wallet;
        codeToPackage[code] = _package;
    }
}