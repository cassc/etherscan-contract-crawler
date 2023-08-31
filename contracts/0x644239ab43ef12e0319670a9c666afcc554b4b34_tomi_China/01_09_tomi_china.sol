// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPriceOracle {
    function getTomiPrice() external view returns (uint);
}

contract tomi_China is Ownable {
    uint public releaseTime;
    IERC20 public usdt;
    IERC20 public tomi;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public tomiWallet;
    address public fundsWallet;

    bool public buyEnable;
    bool public claimEnable;

    IPriceOracle public priceOracle;
    AggregatorV3Interface internal priceFeed;

    address public signerWallet;

    struct claim {
        uint amount;
        uint releaseTime;
    }

    struct code {
        string code;
        address ownerAddress;
        uint256 ownerPercentage;
        uint256 userPercentage;
    }

    mapping(address => mapping(uint => claim)) public claimTokenAmount;
    mapping(address => uint) public Index;
    mapping(address => bool) public blaclistAddress;

    event withEth(
        code _code,
        address By,
        uint AmountSpent,
        uint AmountTomi,
        uint Bonus,
        uint totalTomi,
        uint ReleaseTime,
        uint currentIndex
    );
    event withUsdt(
        code code,
        address By,
        uint PurchaseTime,
        uint AmountSpent,
        uint AmountTomi,
        uint Bonus,
        uint totalTomi,
        uint ReleaseTime,
        uint currentIndex
    );
    event claimed(address by, uint amount, uint time, uint index);
    event claimedBatch(address by, uint amount, uint time, uint[] indexes);

    constructor() {
        //mainnet
        tomiWallet = 0xAA5DcB677D8fBE7F6b28aa61b22Db3253FF98606;
        fundsWallet = 0x703931fa9E31b1327dBafAdac0df06bF622cdcEb;

        priceOracle = IPriceOracle(0x4c7f63B6105Ff95963fC79dB8111628fa014769b);

        tomi = IERC20(0x4385328cc4D643Ca98DfEA734360C0F596C83449);
        usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );

        releaseTime = 7 days;

        buyEnable = true;
        claimEnable = true;

        signerWallet = 0xcE32FDdB8F960E6B00008c5A513ad75dBf5432Bf;
    }

    function setReleaseTime(uint _newTimeInSeconds) public onlyOwner {
        releaseTime = _newTimeInSeconds;
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

    function updateBlackListedUser(
        address _address,
        bool _access
    ) public onlyOwner {
        blaclistAddress[_address] = _access;
    }

    function purchaseWithEth(
        code memory _code,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        require(!blaclistAddress[msg.sender], "You are BlackListed");
        require(buyEnable, "Wait for buy Enable");

        verifySign(
            _code.code,
            _code.ownerAddress,
            _code.ownerPercentage,
            _code.userPercentage,
            v,
            r,
            s
        );

        require(msg.value > 0, "Send value greater than 0");

        uint256 codeOwnerFunds = msg.value.mul(_code.ownerPercentage).div(1000);
        payable(_code.ownerAddress).transfer(codeOwnerFunds);
        payable(fundsWallet).transfer(msg.value.sub(codeOwnerFunds));

        uint tomiPriceUsdt = priceOracle.getTomiPrice();
        uint ethPriceUsdt = getLatestPriceEth();
        uint currentInvestment = msg.value.mul(ethPriceUsdt);
        uint toReturn = currentInvestment.div(tomiPriceUsdt);
        uint amounTomi = toReturn;
        uint eightPercent = (toReturn.mul(_code.userPercentage)).div(1000);
        toReturn = toReturn.add(eightPercent);
        claimTokenAmount[msg.sender][Index[msg.sender]].amount = toReturn;
        claimTokenAmount[msg.sender][Index[msg.sender]].releaseTime = block
            .timestamp
            .add(releaseTime);

        emit withEth(
            _code,
            msg.sender,
            msg.value,
            amounTomi,
            eightPercent,
            toReturn,
            block.timestamp.add(releaseTime),
            Index[msg.sender]
        );
        Index[msg.sender]++;
    }

    function purchaseWithUsdt(
        uint _investment,
        code memory _code,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(!blaclistAddress[msg.sender], "You are BlackListed");
        require(buyEnable, "Wait for buy Enable");

        verifySign(
            _code.code,
            _code.ownerAddress,
            _code.ownerPercentage,
            _code.userPercentage,
            v,
            r,
            s
        );

        require(_investment > 0, "Send _investment greater than 0");

        uint256 codeOwnerFunds = _investment.mul(_code.ownerPercentage).div(
            1000
        );
        usdt.safeTransferFrom(
            msg.sender,
            fundsWallet,
            _investment.sub(codeOwnerFunds)
        );
        usdt.safeTransferFrom(msg.sender, _code.ownerAddress, codeOwnerFunds);

        uint tomiPriceUsdt = priceOracle.getTomiPrice(); // in 8 decimals
        uint toReturn = (_investment.mul(1e20)).div(tomiPriceUsdt);
        uint eightPercent = (toReturn.mul(_code.userPercentage)).div(1000);
        uint amounTomi = toReturn;
        toReturn = toReturn.add(eightPercent);
        claimTokenAmount[msg.sender][Index[msg.sender]].amount = toReturn;
        claimTokenAmount[msg.sender][Index[msg.sender]].releaseTime = block
            .timestamp
            .add(releaseTime);

        emit withUsdt(
            _code,
            msg.sender,
            block.timestamp,
            _investment,
            amounTomi,
            eightPercent,
            toReturn,
            (block.timestamp.add(releaseTime)),
            Index[msg.sender]
        );

        Index[msg.sender]++;
    }

    function claimTomi(uint _index) public {
        require(!blaclistAddress[msg.sender], "You are BlackListed");
        require(claimEnable, "Wait for Claim Enable");
        require(
            block.timestamp > claimTokenAmount[msg.sender][_index].releaseTime,
            "Now isn't ReleaseTime "
        );

        uint _amount = claimTokenAmount[msg.sender][_index].amount;
        require(_amount > 0, "No Claim Amount");
        delete claimTokenAmount[msg.sender][_index];
        tomi.safeTransferFrom(tomiWallet, msg.sender, _amount);
        emit claimed(msg.sender, _amount, block.timestamp, _index);
    }

    function claimAllTomi(uint[] memory indexes) public {
        require(!blaclistAddress[msg.sender], "You are BlackListed");
        require(claimEnable, "Wait for Claim Enable");
        uint totalAmount;
        uint till = indexes.length;
        for (uint i = 0; i < till; i++) {
            if (
                block.timestamp >
                claimTokenAmount[msg.sender][indexes[i]].releaseTime &&
                claimTokenAmount[msg.sender][indexes[i]].amount > 0
            ) {
                uint _amount = claimTokenAmount[msg.sender][indexes[i]].amount;
                delete claimTokenAmount[msg.sender][indexes[i]];
                totalAmount += _amount;
            }
        }
        if (totalAmount > 0) {
            tomi.safeTransferFrom(tomiWallet, msg.sender, totalAmount);
            emit claimedBatch(
                msg.sender,
                totalAmount,
                block.timestamp,
                indexes
            );
        }
    }

    function withdrawEth() public onlyOwner {
        uint funds = address(this).balance;
        if (funds == 0) revert("Zero funds");
        payable(owner()).transfer(funds);
    }

    function withdrawToken(IERC20 _token) public onlyOwner {
        uint funds = _token.balanceOf(address(this));
        if (funds == 0) revert("Zero funds");
        _token.safeTransfer(owner(), funds);
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

    function currentTomiPriceUsdt() public view returns (uint) {
        uint tomiPriceUsdt = priceOracle.getTomiPrice();
        return tomiPriceUsdt;
    }

    function verifySign(
        string memory code_,
        address ownerAddress,
        uint256 ownerPercentage,
        uint256 userPercentage,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 encodedMessageHash = keccak256(
            abi.encodePacked(
                address(this),
                _msgSender(),
                code_,
                ownerAddress,
                ownerPercentage,
                userPercentage
            )
        );
        require(
            signerWallet ==
                ecrecover(getSignedHash(encodedMessageHash), v, r, s),
            "Invalid Sign"
        );
    }

    function getSignedHash(
        bytes32 _messageHash
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }
}