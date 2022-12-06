// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ShopNEXT_MOON_Membership is Ownable {
    struct Mooner {
        uint256 startUpTime;
        uint256 startDownTime;
        uint256 endTimeVip;
        uint256 durationTime;
        uint256 amountLock;
    }
    event ChangeMoonerStatus(
        address indexed user,
        uint256 indexed op,
        uint256 indexed time,
        uint256 endTime,
        uint256 amount
    );
    event Claimed(address indexed user, uint256 indexed amount);
    event ChangeConfigDurationTime(uint256 indexed duration);
    event ChangeStakeMode(bool indexed mode);
    event ChangeApr(uint256 indexed apr);
    event ChangeInterestTokenAddress(address indexed newAdd);
    event ChangeInterestStoreTokenAddress(address indexed newAdd);
    event ChangeNextTokenAddress(address indexed newAdd);
    event ChangeExpiredTime(uint256 indexed time);
    using SafeERC20 for IERC20;
    uint256 public durationLock;
    IERC20 public nextToken;
    IERC20 public interestToken;
    mapping(address => Mooner) public moonerList;
    bool public isStakeMode = false;
    uint256 public apr = 800;
    uint256 BPS = 10000;
    uint256 public expiredTime = 600;
    mapping(address => bool) public signers;
    address public storeInterestToken;

    constructor() {
        signers[_msgSender()] = true;
    }

    function setApr(uint256 aprNew) external onlyOwner {
        apr = aprNew;
        emit ChangeApr(aprNew);
    }

    function setStoreInterestToken(address newAddress) external onlyOwner {
        storeInterestToken = newAddress;
        emit ChangeInterestStoreTokenAddress(newAddress);
    }

    function setExpiredTime(uint256 _expiredTime) external onlyOwner {
        expiredTime = _expiredTime;
        emit ChangeExpiredTime(_expiredTime);
    }

    function setModeStakeMode(bool mode) external onlyOwner {
        isStakeMode = mode;
        emit ChangeStakeMode(mode);
    }

    function addSigner(address _signer) external onlyOwner {
        require(
            _signer != address(0) && !signers[_signer],
            "SN: invalid address"
        );
        signers[_signer] = true;
    }

    function removeSigner(address _signer) external onlyOwner {
        require(
            _signer != address(0) && signers[_signer],
            "SN: invalid address"
        );
        signers[_signer] = false;
    }

    function setDurationTime(uint256 duration) external onlyOwner {
        durationLock = duration;
        emit ChangeConfigDurationTime(duration);
    }

    function setNextToken(address nextAddress) external onlyOwner {
        nextToken = IERC20(nextAddress);
        emit ChangeNextTokenAddress(nextAddress);
    }

    function setInterestToken(address interestAddress) external onlyOwner {
        interestToken = IERC20(interestAddress);
        emit ChangeInterestTokenAddress(interestAddress);
    }

    function isMoon(address user) public view returns (bool) {
        Mooner memory mooner = moonerList[user];
        if (
            mooner.amountLock > 0 && 
            (mooner.endTimeVip == 0 || mooner.endTimeVip > block.timestamp)
        ) {
            return true;
        }
        return false;
    }

    function upgradeMoon(
        uint256 amountLockToMoon,
        uint256 time,
        bytes calldata signature
    ) external {
        require(!isMoon(_msgSender()), "SN: user is mooner");
        require(time + expiredTime > block.timestamp, "SN: token expired");
        bytes32 _msgHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        "SN_UP_MOON",
                        _msgSender(),
                        amountLockToMoon,
                        time
                    )
                )
            )
        );
        address signer = getSigner(_msgHash, signature);
        require(signers[signer], "SN: invalid signer");

        Mooner storage mooner = moonerList[_msgSender()];
        uint256 amountClaimAble;
        uint256 amountInterest;
        if (mooner.amountLock > 0) {
            amountClaimAble = mooner.amountLock;
            if (isStakeMode) {
                amountInterest =
                    (mooner.amountLock *
                        apr *
                        (mooner.endTimeVip - mooner.startUpTime)) /
                    (365 days * BPS);
            }
        }
        mooner.amountLock = amountLockToMoon;
        mooner.startUpTime = block.timestamp;
        mooner.startDownTime = 0;
        mooner.endTimeVip = 0;
        mooner.durationTime = durationLock;
        nextToken.safeTransferFrom(msg.sender, address(this), amountLockToMoon);
        if (amountClaimAble > 0) {
            nextToken.safeTransfer(msg.sender, amountClaimAble);
            emit Claimed(msg.sender, amountClaimAble);
            if (isStakeMode && amountInterest > 0) {
                interestToken.safeTransferFrom(
                    storeInterestToken,
                    msg.sender,
                    amountInterest
                );
            }
        }
        emit ChangeMoonerStatus(_msgSender(), 1, block.timestamp, 0,amountLockToMoon);
    }

    function cancelDowngradeMoon() external {
        require(isMoon(_msgSender()), "SN: user is not mooner");
        Mooner storage mooner = moonerList[_msgSender()];
        require(mooner.endTimeVip >0 && mooner.endTimeVip > block.timestamp,"SN:user not request down moon" );
        mooner.startDownTime = 0;
        mooner.endTimeVip = 0; 
        emit ChangeMoonerStatus(
            _msgSender(),
            2,
            block.timestamp,
            0,
            mooner.amountLock
        );
    }
    function downgradeMoon() external {
        require(isMoon(_msgSender()), "SN: user is not mooner");
        Mooner storage mooner = moonerList[_msgSender()];
        mooner.startDownTime = block.timestamp;
        mooner.endTimeVip = (block.timestamp > mooner.startUpTime &&
            (block.timestamp - mooner.startUpTime) % mooner.durationTime == 0)
            ? block.timestamp
            : block.timestamp +
                (mooner.durationTime -
                    ((block.timestamp - mooner.startUpTime) %
                        mooner.durationTime));

        emit ChangeMoonerStatus(
            _msgSender(),
            0,
            block.timestamp,
            mooner.endTimeVip,
            mooner.amountLock
        );
    }
    function getUserInfo(address user) external view returns(bool userIsMoon, uint256 startTime, uint256 endTime, uint256 amountClaimAble){
        Mooner memory mooner = moonerList[user];
        if (
            mooner.amountLock > 0 &&
            (mooner.endTimeVip == 0 || mooner.endTimeVip > block.timestamp)
        ) {
            userIsMoon=  true;
            amountClaimAble = 0;
        }else{
            userIsMoon = false;
            amountClaimAble = mooner.amountLock;
        }        
        startTime = mooner.startUpTime;
        endTime = mooner.endTimeVip;
    }

    function claimToken() external {
        require(!isMoon(_msgSender()), "SN: user is  mooner");
        Mooner storage mooner = moonerList[_msgSender()];
        uint256 amountClaim;
        uint256 amountInterest;
        amountClaim = mooner.amountLock;
        if (isStakeMode) {
            amountInterest = ((mooner.amountLock *
                apr *
                (mooner.endTimeVip - mooner.startUpTime)) / (365 days * BPS));
        }

        mooner.amountLock = 0;

        if (amountClaim > 0) {
            nextToken.safeTransfer(_msgSender(), amountClaim);
            emit Claimed(msg.sender, amountClaim);
        }
        if (amountInterest > 0 && isStakeMode) {
            interestToken.safeTransfer(_msgSender(), amountInterest);
        }
    }

    function getSigner(bytes32 msgHash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(msgHash, v, r, s);
    }

    function splitSignature(bytes memory signature)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(signature.length == 65, "SN: invalid signature length");
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }
}