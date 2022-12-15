// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./Governable.sol";

contract RoyaltyConfig is Configurable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    bytes32 internal constant MaxFeeRatio           = bytes32("FC::MaxFeeRatio");
    bytes32 internal constant MinFeeRatio           = bytes32("FC::MinFeeRatio");
    bytes32 internal constant PlatformFeeReceiver   = bytes32("FC::PlatformFeeReceiver");
    bytes32 internal constant PlatformFeeRatio      = bytes32("FC::PlatformFeeRatio");

    address public signer;

    // collection address => receiver
    mapping(address => address) royaltyReceiver;
    // collection address => ratio
    mapping(address => uint) royaltyRatio;

    event CollectionConfigSet(
        address indexed sender,
        address indexed collection,
        address indexed royaltyReceiver,
        uint royaltyRatio
    );
    event ChargeFeeETH(
        address indexed platformReceiver,
        address indexed royaltyReceiver,
        address indexed collection,
        uint platformFee,
        uint royaltyFee
    );
    event ChargeFeeToken(
        address indexed platformReceiver,
        address indexed royaltyReceiver,
        address indexed collection,
        address token,
        uint platformFee,
        uint royaltyFee
    );

    function initialize(address signer_) public override initializer {
        super.initialize(msg.sender);
        signer = signer_;

        config[PlatformFeeReceiver] = uint(address(this));
        config[PlatformFeeRatio] = 0.035 ether; // 3.5%
        config[MaxFeeRatio] = 0.065 ether; // 6.5%
        config[MinFeeRatio] = 0.001 ether; // 0.1%
    }

    function getPlatformFee(uint amount) public view returns (uint) {
        return amount.mul(getPlatformFeeRatio()).div(1 ether);
    }

    function getRoyaltyFee(address collection, uint amount) public view returns (uint) {
        return amount.mul(royaltyRatio[collection]).div(1 ether);
    }

    function getFeeAndRemaining(address collection, uint amount) public view returns (uint, uint, uint) {
        uint platformFee = getPlatformFee(amount);
        uint royaltyFee = getRoyaltyFee(collection, amount);
        uint remaining = amount.sub(platformFee).sub(royaltyFee);
        return (platformFee, royaltyFee, remaining);
    }

    function chargeFeeETH(address collection, uint platformFee, uint royaltyFee) external payable {
        require(platformFee.add(royaltyFee) == msg.value, "invalid msg.value");

        address platformReceiver = feeETHToPlatform(platformFee);
        address _royaltyReceiver = feeETHToCollection(collection, royaltyFee);

        emit ChargeFeeETH(platformReceiver, _royaltyReceiver, collection, platformFee, royaltyFee);
    }

    function chargeFeeToken(address collection, address token, address from, uint platformFee, uint royaltyFee) external {
        address platformReceiver = feeTokenToPlatform(token, from, platformFee);
        address _royaltyReceiver = feeTokenToCollection(collection, token, from, royaltyFee);

        emit ChargeFeeToken(platformReceiver, _royaltyReceiver, collection, token, platformFee, royaltyFee);
    }

    function feeETHToPlatform(uint fee) internal returns (address) {
        address receiver = getPlatformFeeReceiver();
        if (address(this) != receiver && fee > 0) {
            payable(receiver).transfer(fee);
        }
        return receiver;
    }

    function feeETHToCollection(address collection, uint fee) internal returns (address) {
        if (address(this) != royaltyReceiver[collection] && fee > 0) {
            payable(royaltyReceiver[collection]).transfer(fee);
        }
        return royaltyReceiver[collection];
    }

    function feeTokenToPlatform(address token, address from, uint fee) internal returns (address) {
        address receiver = getPlatformFeeReceiver();
        if (address(this) != receiver && fee > 0) {
            IERC20(token).safeTransferFrom(from, receiver, fee);
        }
        return receiver;
    }

    function feeTokenToCollection(address collection, address token, address from, uint fee) internal returns (address) {
        if (address(this) != royaltyReceiver[collection] && fee > 0) {
            IERC20(token).safeTransferFrom(from, royaltyReceiver[collection], fee);
        }
        return royaltyReceiver[collection];
    }

    function setPlatFormatReceiver(address feeReceiver) external governance {
        config[PlatformFeeReceiver] = uint(feeReceiver);
    }

    function setPlatformFeeRatio(uint feeRatio) external governance {
        config[PlatformFeeRatio] = feeRatio;
    }

    function setMaxFeeRatio(uint maxFeeRatio) external governance {
        require(maxFeeRatio > getMinFeeRatio(), "maxFeeRatio must larger than minFeeRatio");
        config[MaxFeeRatio] = maxFeeRatio;
    }

    function setMinFeeRatio(uint minFeeRatio) external governance {
        require(minFeeRatio < getMaxFeeRatio(), "minFeeRatio must less than maxFeeRatio");
        config[MinFeeRatio] = minFeeRatio;
    }

    function setSigner(address signer_) external governance {
        signer = signer_;
    }

    function setCollectionConfig(address collection, address _royaltyReceiver, uint _royaltyRatio, uint expireTime, bytes calldata sign) external {
        require(block.timestamp <= expireTime, "SIGN EXPIRE");
        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encode(msg.sender, collection, _royaltyReceiver, _royaltyRatio, expireTime)));
        require(ECDSA.recover(hash, sign) == signer, "INVALID SIGNER");

        require(_royaltyRatio <= getMaxFeeRatio(), "_royaltyRatio must less than or equal to maxFeeRatio");
        require(_royaltyRatio >= getMinFeeRatio(), "_royaltyRatio must larger than or equal to minFeeRatio");
        royaltyReceiver[collection] = _royaltyReceiver;
        royaltyRatio[collection] = _royaltyRatio;

        emit CollectionConfigSet(msg.sender, collection, _royaltyReceiver, _royaltyRatio);
    }

    function getMaxFeeRatio() public view returns (uint) {
        return config[MaxFeeRatio];
    }

    function getMinFeeRatio() public view returns (uint) {
        return config[MinFeeRatio];
    }

    function getPlatformFeeReceiver() public view returns (address) {
        return address(config[PlatformFeeReceiver]);
    }

    function getPlatformFeeRatio() public view returns (uint) {
        return config[PlatformFeeRatio];
    }

    function totalFeeRatio(address collection) public view returns (uint) {
        return getPlatformFeeRatio().add(royaltyRatio[collection]);
    }

    function sendReward(address payable to, uint amount) external governance {
        require(address(this).balance >= amount, "INSUFFICIENT AMOUNT");
        to.transfer(amount);
    }

    function sendERC20Reward(address token, address to, uint amount) external governance {
        require(IERC20(token).balanceOf(address(this)) >= amount, "INSUFFICIENT AMOUNT");
        IERC20(token).safeTransfer(to, amount);
    }
}