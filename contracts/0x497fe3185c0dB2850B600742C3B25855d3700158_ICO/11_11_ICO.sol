// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ICO is ReentrancyGuard, AccessControl{
    event TokenBuyed(address indexed to, uint256 amount);
    event TokenPerUSDPriceUpdated(uint256 amount);
    event PaymentTokenDetails(tokenDetail);
    event TokenAddressUpdated(address indexed tokenAddress);
    event SignerAddressUpdated(
        address indexed previousSigner,
        address indexed newSigner
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    mapping(uint256 => tokenDetail) public paymentDetails;
    mapping(uint256 => bool) usedNonce;

    IERC20 public tokenAddress;
    address public signer;
    address public owner;
    uint256 public tokenAmountPerUSD = 2 * 10 ** 13;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    struct tokenDetail {
        string paymentName;
        address priceFetchContract;
        address paymentTokenAddress;
        uint256 decimal;
        bool status;
    }

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    constructor(IERC20 _tokenAddress) {
        owner = msg.sender;
        signer = msg.sender;
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(SIGNER_ROLE, msg.sender);
        tokenAddress = _tokenAddress;

       paymentDetails[0] = tokenDetail(
            "ETH",
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            18,
            true
        );
        paymentDetails[1] = tokenDetail(
            "WBTC",
            0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c,
            0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            8,
            true
        );
        paymentDetails[2] = tokenDetail(
            "WMATIC",
            0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676,
            0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0,
            18,
            true
        );
        paymentDetails[3] = tokenDetail(
            "USDC",
            0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6,
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            6,
            true
        );paymentDetails[4] = tokenDetail(
            "USDT",
            0x3E7d1eAB13ad0104d2750B8863b489D65364e32D,
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            6,
            true
        );
    }

    function transferOwnership(address newOwner)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(newOwner != address(0), "Invalid Address");
        _revokeRole(ADMIN_ROLE, owner);
        address oldOwner = owner;
        owner = newOwner;
        _setupRole(ADMIN_ROLE, owner);
        emit OwnershipTransferred(oldOwner, owner);
    }

    function setSignerAddress(address signerAddress)
        external
        onlyRole(SIGNER_ROLE)
    {
        require(signerAddress != address(0), "Invalid Address");
        _revokeRole(SIGNER_ROLE, signer);
        address oldSigner = signer;
        signer = signerAddress;
        _setupRole(SIGNER_ROLE, signer);
        emit SignerAddressUpdated(oldSigner, signer);
    }

    function getLatestPrice(uint256 paymentType) public view returns(int256) {
        (, int256 price, , , ) = AggregatorV3Interface(
            paymentDetails[paymentType].priceFetchContract
        ).latestRoundData();
        return price;
    }

    function buyToken(
        address recipient,
        uint256 paymentType,
        uint256 tokenAmount,
        Sign memory sign
    ) external payable nonReentrant {
        require(paymentDetails[paymentType].status, "Invalid Payment");
        require(!usedNonce[sign.nonce], "Invalid Nonce");
        usedNonce[sign.nonce] = true;
        require(msg.value > 0 || tokenAmount > 0, "Invalid amount");
        uint256 amount;
        if (paymentType == 0) {
            verifySign(paymentType, recipient, msg.sender, msg.value, sign);
            amount = getToken(paymentType, msg.value);
            payable(owner).transfer(msg.value);
        } else {
            verifySign(paymentType, recipient, msg.sender, tokenAmount, sign);
            amount = getToken(paymentType, tokenAmount);
            IERC20(paymentDetails[paymentType].paymentTokenAddress).transferFrom(
                msg.sender,
                owner,
                tokenAmount
            );
        }
        bool success = tokenAddress.transfer(recipient, amount);
        require(success, "tx failed");
        emit TokenBuyed(msg.sender, amount);
    }

    function getToken(uint256 paymentType, uint256 tokenAmount)
        public
        view
        returns (uint256 data)
    {
        uint256 price = uint256(getLatestPrice(paymentType));
        uint256 amount = price * tokenAmountPerUSD / 1e8;
        data = amount * tokenAmount / (10 ** paymentDetails[paymentType].decimal);
    }

    function recoverETH(address walletAddress)
        external
        payable
        onlyRole(ADMIN_ROLE)
    {
        require(walletAddress != address(0), "Null address");
        uint256 balance = address(this).balance;
        payable(walletAddress).transfer(balance);
    }

    function recoverToken(address _tokenAddress,address walletAddress, uint256 amount)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(walletAddress != address(0), "Null address");
        require(amount <= IERC20(_tokenAddress).balanceOf(address(this)), "Insufficient amount");
        bool success = IERC20(_tokenAddress).transfer(
            walletAddress,
            amount
        );
        require(success, "tx failed");
    }

    function setPaymentTokenDetails(uint256 paymentType, tokenDetail memory _tokenDetails)
        external
        onlyRole(ADMIN_ROLE)
    {
        paymentDetails[paymentType] = _tokenDetails;
        emit PaymentTokenDetails(_tokenDetails);
    }

    function setTokenAddress(address _tokenAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        tokenAddress = IERC20(_tokenAddress);
        emit TokenAddressUpdated(address(tokenAddress));
    }

    function setTokenPricePerUSD(uint256 tokenAmount)
        external
        onlyRole(ADMIN_ROLE)
    {
        tokenAmountPerUSD = tokenAmount;
        emit TokenPerUSDPriceUpdated(tokenAmountPerUSD);
    }

    function verifySign(
        uint256 assetType,
        address recipient,
        address caller,
        uint256 amount,
        Sign memory sign
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(assetType, recipient, caller, amount, sign.nonce)
        );
        require(
            signer ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            hash
                        )
                    ),
                    sign.v,
                    sign.r,
                    sign.s
                ),
            "Owner sign verification failed"
        );
    }

}