// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AggregatorV3Interface.sol";

contract DopPreSale is Ownable {
    IERC20 public usdt;
    IERC20 public token;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bool public buyEnable;
    bool public claimEnable;

    AggregatorV3Interface internal priceFeed;

    address public signerWallet;
    address public fundsWallet;
    address public dopWallet;

    struct Claim {
        uint amount;
        uint round;
    }

    struct Code {
        string code;

        uint256 GodAgentPercentage;
        uint256 MegaAgentPercentage;
        uint256 SuperAgentPercentage;
        uint256 AgentPercentage;

        address GodAgentAddress;
        address MegaAgentAddress;
        address SuperAgentAddress;
        address AgentAddress;
    }

    mapping(address => mapping(uint => Claim)) public claimTokenAmount;
    mapping(address => uint) public Index;
    mapping(address => bool) public blacklistAddress;

    event investedWithEth  (address by, Code _code, uint amountInvestedEth , uint round, uint index,uint price, uint dopPurchased);
    event investedWithUSDT (address by, Code _code, uint amountInUsd , uint round , uint index,uint price , uint dopPurchased);

    event claimed(address by, uint amount, uint time, uint index, uint round);
    event claimedBatch(address by, uint amount, uint time, uint[] indexes);

    constructor() {
        fundsWallet = 0xA0C73b7D38887A4e7C5970b43EC03dec3E8d75Af;
        usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        signerWallet = 0xC2DE2ce0938E3fB70f3D63Ad3A5078c36Bb7ec9b ;
        dopWallet= 0x347114deA137a6EDdFBa91bc07A238c719Eb505D;
        buyEnable = true;
    }

    function toggleBuyEnable() public onlyOwner {
        buyEnable = !buyEnable;
    }

    function toggleClaimEnable() public onlyOwner {
        claimEnable = !claimEnable;
    }

    function changeSigner(address _signer) public onlyOwner {
        signerWallet = _signer;
    }

    function changeDopWallet(address _wallet) public onlyOwner {
        dopWallet = _wallet;
    }

    function changeFundsWallet(address _wallet) public onlyOwner {
        fundsWallet = _wallet;
    }

    function updateDopToken(IERC20 _dop) public onlyOwner {
        token = _dop;
    }

    function updateBlackListedUser(address _address , bool _access) public onlyOwner {
        blacklistAddress[_address] = _access;
    }

    function purchaseWithEth(
        Code memory _code,
        uint round,
        uint deadline,  // now + 5 minutes
        uint price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        require(!blacklistAddress[msg.sender], "You are blacklisted");
        require(buyEnable, "Wait for buy enable");
        require(block.timestamp < deadline, "Deadline has been crossed");

        verifySign(_code, price, deadline, v, r, s);

        require(msg.value > 0, "Send value greater than 0");
        require(
            _code.GodAgentPercentage
                .add(_code.MegaAgentPercentage)
                .add( _code.SuperAgentPercentage)
                .add( _code.AgentPercentage)
            <= 250,
            "Percentage Sum should be <= 25"
        );

        processPurchase(true,msg.value, _code);

        uint currentInvestment = msg.value.mul(getLatestPriceEth());

        uint toReturn = (currentInvestment.mul(1e10)).div(price);

        claimTokenAmount[msg.sender][Index[msg.sender]].amount = toReturn;
        claimTokenAmount[msg.sender][Index[msg.sender]].round = round;
        emit investedWithEth (msg.sender, _code, msg.value, round, Index[msg.sender], price, toReturn);
        Index[msg.sender]++;
    }

    function processPurchase(bool isEth,uint invested, Code memory _code) internal {
        uint256 GodAgentAmount = invested.mul(_code.GodAgentPercentage).div(1000);
        uint256 MegaAgentAmount = invested.mul(_code.MegaAgentPercentage).div(1000);
        uint256 SuperAgentAmount = invested.mul(_code.SuperAgentPercentage).div(1000);
        uint256 AgentAmount = invested.mul(_code.AgentPercentage).div(1000);

        if (isEth) {
            if(GodAgentAmount!=0 && _code.GodAgentAddress != address(0)) payable(_code.GodAgentAddress).transfer(GodAgentAmount);
            if(MegaAgentAmount!=0 && _code.MegaAgentAddress != address(0)) payable(_code.MegaAgentAddress).transfer(MegaAgentAmount);
            if(SuperAgentAmount!=0 && _code.SuperAgentAddress != address(0)) payable(_code.SuperAgentAddress).transfer(SuperAgentAmount);
            if(AgentAmount!=0 && _code.AgentAddress != address(0)) payable(_code.AgentAddress).transfer(AgentAmount);
            payable(fundsWallet).transfer(msg.value.sub(GodAgentAmount .add( MegaAgentAmount) .add( SuperAgentAmount) .add( AgentAmount)));
        }
        else {
            if(GodAgentAmount!=0 && _code.GodAgentAddress != address(0)) usdt.safeTransferFrom(msg.sender, _code.GodAgentAddress, GodAgentAmount);
            if(MegaAgentAmount!=0 && _code.MegaAgentAddress != address(0)) usdt.safeTransferFrom(msg.sender, _code.MegaAgentAddress, MegaAgentAmount);
            if(SuperAgentAmount!=0 && _code.SuperAgentAddress != address(0)) usdt.safeTransferFrom(msg.sender, _code.SuperAgentAddress, SuperAgentAmount);
            if(AgentAmount!=0 && _code.AgentAddress != address(0)) usdt.safeTransferFrom(msg.sender, _code.AgentAddress, AgentAmount);

            usdt.safeTransferFrom(msg.sender, fundsWallet, invested.sub(GodAgentAmount .add( MegaAgentAmount) .add( SuperAgentAmount) .add( AgentAmount)));
        }
    }

    function purchaseWithUsdt(uint investment, Code memory _code,uint deadline,  uint round ,uint price, uint8 v, bytes32 r, bytes32 s) public  {
        require(!blacklistAddress[msg.sender], "You are BlackListed");
        require(buyEnable, "Wait for buy Enable");
        require(block.timestamp < deadline, "Deadline has been crossed");
        verifySign(_code, price, deadline,v, r, s);

        require(investment > 0, "investment should be greater than 0");
        require((_code.GodAgentPercentage.add(_code.MegaAgentPercentage).add(_code.SuperAgentPercentage).add(_code.AgentPercentage))<=250,
                "Percentage Sum should be <= 25"
                );
        processPurchase(false,investment,_code);
        uint toReturn = (investment.mul(1e30)).div(price);
        claimTokenAmount[msg.sender][Index[msg.sender]].amount = toReturn;
        claimTokenAmount[msg.sender][Index[msg.sender]].round = round;
        emit investedWithUSDT (msg.sender, _code, investment, round,Index[msg.sender],price, toReturn);
        Index[msg.sender]++;
    }

    function claimTokens(uint _index) public {
        require(!blacklistAddress[msg.sender], "You are BlackListed");
        require(claimEnable, "Wait for Claim Enable");
        Claim memory claim_= claimTokenAmount[msg.sender][_index];
        require(claim_.amount > 0, "No Claim Amount");
        delete claimTokenAmount[msg.sender][_index];
        token.safeTransferFrom(dopWallet, msg.sender, claim_.amount);
        emit claimed(msg.sender, claim_.amount, block.timestamp, _index, claim_.round);
    }

    function claimTokensBatch( uint[] memory indexes ) public {
        require(!blacklistAddress[msg.sender], "You are BlackListed");
        require(claimEnable, "Wait for Claim Enable");
        uint totalAmount;

        for (uint i = 0; i < indexes.length; i++) {
            uint _amount = claimTokenAmount[msg.sender][indexes[i]].amount;
            if (_amount > 0) {
                delete claimTokenAmount[msg.sender][indexes[i]];
                totalAmount += _amount;
            }
        }
        if (totalAmount > 0) {
            token.safeTransferFrom(dopWallet, msg.sender, totalAmount);
            emit claimedBatch(
                msg.sender,
                totalAmount,
                block.timestamp,
                indexes
            );
        }
    }

    function getLatestPriceEth() public view returns (uint) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = /*uint timeStamp*/ priceFeed.latestRoundData();

        return uint(price); // returns value 8 decimals
    }

    function verifySign(  Code memory _code, uint price,uint deadline ,uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 encodedMessageHash = keccak256(abi.encodePacked(
            _msgSender(),
            _code.code,
            _code.GodAgentAddress,
            _code.GodAgentPercentage,
            _code.MegaAgentAddress,
            _code.MegaAgentPercentage,
            _code.SuperAgentAddress,
            _code.SuperAgentPercentage,
            _code.AgentAddress,
            _code.AgentPercentage,
            price,
            deadline

        ));

        require(signerWallet == ecrecover(getSignedHash(encodedMessageHash), v, r, s), "Invalid Sign");
    }

    function getSignedHash(bytes32 _messageHash) private pure returns(bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
}