// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract BIFUGFFContract is Ownable, ReentrancyGuard {

    uint256 public fundsRaisedV1 = 13502 * 1e18; // Funds that were raised in the V1 contract
    uint256 public AUM; // Total fund value that decides the NAV
    uint256 public numberOfShares; // Total number of shares
    uint256 public NAV = 10 * 1e18; // Net asset value at which the fund is bought and sold
    uint256 public denominator = 1e18; // Accuracy upto 18 decimal places

    uint256 public inceptionTime; // Start time of trading in fund

    uint256 public minInvestmentAmnt = 250 * 1e18; // $250

    IERC20 public usdtToken;
    IERC20 public busdToken;
    address public treasury;

    mapping(address => uint256) public totalSharesHeldByInvestor;
    mapping(address => bool) public frozenAccounts;

    event FundInitiated(uint256 startTime);
    event Invested(
        address indexed investor,
        uint256 amount
    );
    event Withdrawn(
        address indexed investor,
        uint256 amount
    );
    event InvestmentMapped(address[] investor, uint256[] shares);
    event MinInvestmentAmountUpdated(uint256 _newAmnt);
    event AccountFrozen(address investor, string reason);
    event ETHCollected(address collector, uint256 amount);
    event IERC20TokenWithdrawn(address collector, uint256 amount);
    event FundsWithdrawn(address treasury, uint256 usdtAmount, uint256 busdAmount, string reason);

    constructor(
        address _usdtTokenAddress,
        address _busdTokenAddress,
        address _treasury
    ) {
        require(
            _usdtTokenAddress != address(0) && _treasury != address(0),
            "Can't set to zero address"
        );
        usdtToken = IERC20(_usdtTokenAddress);
        busdToken = IERC20(_busdTokenAddress);
        treasury = _treasury;
        inceptionTime = block.timestamp;
    }

    // internal functions

    function calculateNAV(uint256 _AUM) internal {
        NAV = _AUM * 1e18 / numberOfShares;
    }

    // Investor functions

    function calculateInvestmentValue(address investor) public view returns(uint256) {
        uint256 totalInvestedValue= (totalSharesHeldByInvestor[investor] * NAV) / 1e18;

        return totalInvestedValue;
    }

    function invest(
        uint256 _amount,
        IERC20 _tokenAddress
    ) external {
        require(
            _tokenAddress == usdtToken || _tokenAddress == busdToken,
            "Use either USDT or BUSD only!"
        );
        require(_amount >= minInvestmentAmnt, "Amount must be greater than min investment amount set in the contract");
        require(_tokenAddress.balanceOf(msg.sender) >= _amount, "Not enough balance in wallet to invest");

        require(_tokenAddress.transferFrom(msg.sender, address(this), _amount), "Fund transfer to contract failed!");

        uint256 calculateNumberOfShares = _amount * 1e18 / NAV;

        AUM += _amount;

        totalSharesHeldByInvestor[msg.sender] += calculateNumberOfShares;
        numberOfShares += calculateNumberOfShares;

        emit Invested(msg.sender, _amount);
    }

    function withdrawInvestment(
        uint256 _numberOfShares,
        uint256 nonce,
        bytes memory _signature
    ) external nonReentrant {

        require(
            totalSharesHeldByInvestor[msg.sender] >= _numberOfShares && _numberOfShares > 0,
            "Error: Not enough shares!"
        );
        require(
            !frozenAccounts[msg.sender],
            "This account has been frozen on account of hack!"
        );

        bytes32 message = prefixed(
            keccak256(abi.encodePacked(msg.sender, _numberOfShares, nonce, this))
        );

        require(
            recoverSigner(message, _signature) == msg.sender,
            "Invalid signature"
        );

        uint256 totalAmount = (_numberOfShares * NAV) / 1e18;
        // take 1% withdrawal fee
        uint256 withdrawalFee = totalAmount / 100;
        uint256 withdrawableAmnt = totalAmount - withdrawalFee;

        AUM -= totalAmount;

        totalSharesHeldByInvestor[msg.sender] -= _numberOfShares;
        numberOfShares -= _numberOfShares;

        require(usdtToken.balanceOf(address(this)) >= withdrawableAmnt, "Error: Not enough USDT balance in the contract");

        usdtToken.transfer(msg.sender, withdrawableAmnt);

        emit Withdrawn(msg.sender, withdrawableAmnt);
    }

    // Signature verifications

    function prefixed(bytes32 _hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            );
    }

    function recoverSigner(bytes32 _message, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(_signature);

        return ecrecover(_message, v, r, s);
    }

    function splitSignature(bytes memory _signature)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        return (v, r, s);
    }

    // Admin priveledges

    /** 
        To map investments from V1 of the contract at https://bscscan.com/address/0x47d69c7701de0fde09992a62b52f73c19cc2eafa
        For a total amount of 13,502 USDT and 1350.2 shares at $10 NAV 
     **/
    function _mapInvestments(address[] calldata investors, uint256[] calldata shares, uint256 _AUM, uint256 _totalShares) external onlyOwner{
        require(_AUM <= fundsRaisedV1, "Error: Can't map than more than the amount held in the V1 of the contract");
        for(uint i = 0; i< investors.length; i++){
            require(investors[i] != address(0));
            totalSharesHeldByInvestor[investors[i]] = shares[i];
        }

        AUM += _AUM;
        numberOfShares += _totalShares;
        emit InvestmentMapped(investors, shares);
    }

    // @dev declares daily profit/loss in 18 decimals which decide the closing AUM and NAV
    function declareAUMChange(int256 _delta) external onlyOwner {
        if(_delta < 0) {
            AUM -= uint256(-(_delta));
            calculateNAV(AUM);
        } else {
            AUM += uint256(_delta);
            calculateNAV(AUM);
        }
    }

    function updateMinInvestmentAmount(uint256 _newAmnt) external onlyOwner {
        require(_newAmnt >= 100 && _newAmnt <= 100000, "Error: value out of bounds");

        minInvestmentAmnt = _newAmnt * 1e18;

        emit MinInvestmentAmountUpdated(_newAmnt * 1e18);
    }

    function freezeAccount(
        address _investor,
        string memory _reason,
        uint256 nonce,
        bytes memory _signature
    ) external onlyOwner {
        require(!frozenAccounts[_investor], "Account is already frozen!");

        bytes32 message = prefixed(
            keccak256(abi.encodePacked(msg.sender, _reason, nonce, this))
        );

        require(
            recoverSigner(message, _signature) == msg.sender,
            "Invalid signature"
        );

        frozenAccounts[_investor] = true;

        emit AccountFrozen(_investor, _reason);
    }

    function collectNativeCurrency() external onlyOwner {
        uint256 fundsToSend = address(this).balance;
        bool sent = payable(treasury).send(fundsToSend);
        require(sent, "Failed to send Ether");

        emit ETHCollected(treasury, fundsToSend);
    }

    function withdrawOtherTokens(address _token) external onlyOwner {
        require(_token != address(0), "can't withdraw zero token");
        require(
            IERC20(_token) != usdtToken && IERC20(_token) != busdToken,
            "Use collectUSDT method!"
        );
        uint256 fundsToSend;

        fundsToSend = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, fundsToSend);

        emit IERC20TokenWithdrawn(msg.sender, fundsToSend);
    }

    function collectFunds(string memory _reason) external onlyOwner {
        uint256 usdtToSend = usdtToken.balanceOf(address(this));
        uint256 busdToSend = busdToken.balanceOf(address(this));

        if (usdtToSend > 0 || busdToSend > 0) {
            usdtToken.transfer(treasury, usdtToSend);
            busdToken.transfer(treasury, busdToSend);
        }

        emit FundsWithdrawn(treasury, usdtToSend, busdToSend, _reason);
    }
}