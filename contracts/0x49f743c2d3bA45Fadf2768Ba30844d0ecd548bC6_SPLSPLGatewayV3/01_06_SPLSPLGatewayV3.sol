// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/Withdrawable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface GuildAsset {
    function getTotalVolume(uint16 _guildType) external view returns (uint256);
}

interface SPLGuildPool {
    function addEthToGuildPool(uint16 _guildType, address _purchaseBy) external payable;
}

interface IngameMoney {
    function hashTransactedAt(bytes32 _hash) external view returns(uint256);
    function buy(address payable _user, address payable _referrer, uint256 _referralBasisPoint, uint16 _guildType, bytes calldata _signature, bytes32 _hash) external payable;
}

contract SPLSPLGatewayV3 is Withdrawable, IngameMoney, Pausable {
    struct Campaign {
        uint8 purchaseType;
        uint8 subPurchaseType;
        uint8 proxyPurchaseType;
    }

    uint8 constant PURCHASE_NORMAL = 0;
    uint8 constant PURCHASE_ETH_BACK = 1;
    uint8 constant PURCHASE_UP20 = 2;
    uint8 constant PURCHASE_REGULAR = 3;
    uint8 constant PURCHASE_ETH_BACK_UP20 = 4;

    Campaign public campaign;

    mapping(uint256 => bool) public payableOptions;
    address public validater;

    GuildAsset public guildAsset;
    SPLGuildPool public guildPool;
    uint256 public guildBasisPoint;

    uint256 constant BASE = 10000;
    uint256 private nonce;
    uint16 public chanceDenom;
    uint256 public ethBackBasisPoint;
    bytes private salt;
    mapping(bytes32 => uint256) private _hashTransactedAt;

    event Sold(
        address indexed user,
        address indexed referrer,
        uint8 purchaseType,
        uint256 grossValue,
        uint256 referralValue,
        uint256 guildValue,
        uint256 netValue,
        uint16 indexed guildType
    );

    event CampaignUpdated(
        uint8 purchaseType,
        uint8 subPurchaseType,
        uint8 proxyPurchaseType
    );

    event GuildBasisPointUpdated(
        uint256 guildBasisPoint
    );

    constructor(
        address _validater,
        address _guildAssetAddress,
        address payable _guildPoolAddress
    ) {
        setValidater(_validater);
        guildAsset = GuildAsset(_guildAssetAddress);
        guildPool = SPLGuildPool(_guildPoolAddress);

        setCampaign(0, 0, 0);
        updateGuildBasisPoint(1500);
        updateEthBackBasisPoint(5000);
        updateChance(25);
        salt = bytes("iiNg4uJulaa4Yoh7");

        nonce = 220000;

        // payableOptions[0] = true;
        payableOptions[0.01 ether] = true;
        payableOptions[0.02 ether] = true;
        payableOptions[0.03 ether] = true;
        payableOptions[0.05 ether] = true;
        payableOptions[0.1 ether] = true;
        payableOptions[0.5 ether] = true;
        payableOptions[1 ether] = true;
        payableOptions[5 ether] = true;
        payableOptions[10 ether] = true;
    }

    function setValidater(address _varidater) public onlyOwner {
        validater = _varidater;
    }

    function setPayableOption(uint256 _option, bool desired) external onlyOwner {
        payableOptions[_option] = desired;
    }

    function setCampaign(
        uint8 _purchaseType,
        uint8 _subPurchaseType,
        uint8 _proxyPurchaseType
    )
        public
        onlyOwner
    {
        campaign = Campaign(_purchaseType, _subPurchaseType, _proxyPurchaseType);
        emit CampaignUpdated(_purchaseType, _subPurchaseType, _proxyPurchaseType);
    }

    function updateGuildBasisPoint(uint256 _newGuildBasisPoint) public onlyOwner() {
        guildBasisPoint = _newGuildBasisPoint;
        emit GuildBasisPointUpdated(
            guildBasisPoint
        );
    }

    function updateChance(uint16 _newchanceDenom) public onlyOwner {
        chanceDenom = _newchanceDenom;
    }

    function updateEthBackBasisPoint(uint256 _ethBackBasisPoint) public onlyOwner {
        ethBackBasisPoint = _ethBackBasisPoint;
    }

    function buy(
        address payable _user,
        address payable _referrer,
        uint256 _referralBasisPoint,
        uint16 _guildType,
        bytes memory _signature,
        bytes32 _hash
    )
        public
        payable
        override
        whenNotPaused()
    {
        require(_referralBasisPoint + ethBackBasisPoint + guildBasisPoint <= BASE, "Invalid basis points");
        require(payableOptions[msg.value], "Invalid msg.value");
        require(validateSig(encodeData(_user, _referrer, _referralBasisPoint, _guildType), _signature), "Invalid signature");
        if (_hash != bytes32(0)) {
            recordHash(_hash);
        }
        uint8 purchaseType = campaign.proxyPurchaseType;
        uint256 netValue = msg.value;
        uint256 referralValue = _referrerBack(_referrer, _referralBasisPoint);
        uint256 guildValue = _guildPoolBack(_guildType);
        netValue = msg.value - referralValue - guildValue;

        emit Sold(
            _user,
            _referrer,
            purchaseType,
            msg.value,
            referralValue,
            guildValue,
            netValue,
            _guildType
        );
    }

    function buySPL(
        address payable _referrer,
        uint256 _referralBasisPoint,
        uint16 _guildType,
        bytes memory _signature
    )
        public
        payable
    {
        require(_referralBasisPoint + ethBackBasisPoint + guildBasisPoint <= BASE, "Invalid basis points");
        require(payableOptions[msg.value], "Invalid msg.value");
        require(validateSig(encodeData(msg.sender, _referrer, _referralBasisPoint, _guildType), _signature), "Invalid signature");

        uint8 purchaseType = campaign.purchaseType;
        uint256 netValue = msg.value;
        uint256 referralValue = 0;
        uint256 guildValue = 0;

        if (purchaseType == PURCHASE_ETH_BACK || purchaseType == PURCHASE_ETH_BACK_UP20) {
            if (getRandom(chanceDenom, nonce, msg.sender) == 0) {
                uint256 ethBackValue = _ethBack(payable(msg.sender), ethBackBasisPoint);
                netValue = netValue - ethBackValue;
            } else {
                purchaseType = campaign.subPurchaseType;
                referralValue = _referrerBack(_referrer, _referralBasisPoint);
                guildValue = _guildPoolBack(_guildType);
                netValue = msg.value - referralValue - guildValue;
            }
            nonce++;
        } else {
            referralValue = _referrerBack(_referrer, _referralBasisPoint);
            guildValue = _guildPoolBack(_guildType);
            netValue = msg.value - referralValue - guildValue;
        }

        emit Sold(
            msg.sender,
            _referrer,
            purchaseType,
            msg.value,
            referralValue,
            guildValue,
            netValue,
            _guildType
        );
    }

    function hashTransactedAt(bytes32 _hash) public view override returns (uint256) {
        return _hashTransactedAt[_hash];
    }

    function recordHash(bytes32 _hash) internal {
        require(_hashTransactedAt[_hash] == 0, "The hash is already transacted");
        _hashTransactedAt[_hash] = block.number;
    }

    function getRandom(uint16 max, uint256 _nonce, address _sender) public view returns (uint16) {
        return uint16(
            bytes2(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number-1),
                        _sender,
                        _nonce,
                        salt
                    )
                )
            )
        ) % max;
    }

    function _ethBack(address payable _buyer, uint256 _ethBackBasisPoint) internal returns (uint256) {
        uint256 ethBackValue = msg.value * _ethBackBasisPoint / BASE;
        _buyer.transfer(ethBackValue);
        return ethBackValue;
    }

    function _guildPoolBack(uint16 _guildType) internal returns (uint256) {
        if(_guildType == 0) {
            return 0;
        }
        require(guildAsset.getTotalVolume(_guildType) != 0, "Invalid _guildType");

        uint256 guildValue;
        guildValue = msg.value * guildBasisPoint / BASE;
        guildPool.addEthToGuildPool{value: guildValue}(_guildType, msg.sender);
        return guildValue;
    }

    function _referrerBack(address payable _referrer, uint256 _referralBasisPoint) internal returns (uint256) {
        if(_referrer == address(0x0) || _referrer == msg.sender) {
            return 0;
        }
        uint256 referralValue = msg.value * _referralBasisPoint / BASE;
        _referrer.transfer(referralValue);
        return referralValue;
    }

    function encodeData(address _sender, address _referrer, uint256 _referralBasisPoint, uint16 _guildType) public pure returns (bytes32) {
        return keccak256(abi.encode(
                            _sender,
                            _referrer,
                            _referralBasisPoint,
                            _guildType
                            )
                    );
    }

    function validateSig(bytes32 _message, bytes memory _signature) public view returns (bool) {
        require(validater != address(0), "validater must be set");
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(_message), _signature);
        return (signer == validater);
    }

    function recover(bytes32 _message, bytes memory _signature) public pure returns (address) {
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(_message), _signature);
        return signer;
    }
}