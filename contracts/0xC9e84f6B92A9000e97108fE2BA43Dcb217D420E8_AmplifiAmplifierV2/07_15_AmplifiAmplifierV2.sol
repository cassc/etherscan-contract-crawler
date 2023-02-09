// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAmplifi.sol";
import "./interfaces/IAmplifiNode.sol";
import "./interfaces/IUniswap.sol";
import {IAmplifierV2} from "./interfaces/IAmplifierV2.sol";
import "./FusePoolV2.sol";
import "./Types.sol";
import "./Events.sol";

/**
 * Amplifi
 * Website: https://perpetualyield.io/
 * Telegram: https://t.me/Amplifi_ERC
 * Twitter: https://twitter.com/amplifidefi
 */
contract AmplifiAmplifierV2 is Ownable, ReentrancyGuard, IAmplifierV2 {
    uint16 public maxMonths = 6;
    uint16 public maxAmplifiersPerMinter = 96;
    uint256 public gracePeriod = 30 days;
    uint256 public gammaPeriod = 72 days;
    uint256 public fuseWaitPeriod = 90 days;

    uint256 public totalAmplifiers = 0;
    mapping(uint256 => Types.AmplifierV2) private _amplifiers;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(uint256 => uint256)) public ownedAmplifiers;
    mapping(uint256 => uint256) public ownedAmplifiersIndex;
    mapping(uint256 => bool) public migratedAmplifiers;

    mapping(Types.FuseProduct => uint256) public fuseLockDurations;
    mapping(Types.FuseProduct => FusePoolV2) public fusePools;
    mapping(Types.FuseProduct => uint256) public boosts;

    uint256 public creationFee = 0.008 ether;
    uint256 public renewalFee = 0.008 ether;
    uint256 public fuseFee = 0.008 ether;
    uint256 public mintPrice = 20e18;

    uint256[20] public rates = [
        1009000000000,
        857650000000,
        729002500000,
        619652125000,
        526704306250,
        447698660313,
        380543861266,
        323462282076,
        274942939764,
        233701498800,
        198646273980,
        168849332883,
        143521932950,
        121993643008,
        103694596557,
        88140407073,
        74919346012,
        63681444110,
        54129227494,
        46009843370
    ];

    IAmplifi public immutable amplifi;
    IAmplifiNode public immutable oldAmplifiNode;
    IUniswapV2Router02 public immutable router;
    IERC20 public immutable USDC;

    Types.AmplifierFeeRecipients public feeRecipients;

    uint16 public claimFee = 750;
    // Basis for above fee values
    uint16 public constant bps = 10_000;

    constructor(IAmplifi _amplifi, IAmplifiNode _oldAmplifiNode, IUniswapV2Router02 _router, IERC20 _usdc) {
        amplifi = _amplifi;
        oldAmplifiNode = _oldAmplifiNode;
        router = _router;
        USDC = _usdc;

        feeRecipients = Types.AmplifierFeeRecipients(
            0xc766B8c9741BC804FCc378FdE75560229CA3AB1E,
            0x58c5a97c717cA3A7969F82D670A9b9FF16545C6F,
            0x454cD1e89df17cDB61D868C6D3dBC02bC2c38a17
        );

        fuseLockDurations[Types.FuseProduct.OneYear] = 365 days;
        fuseLockDurations[Types.FuseProduct.ThreeYears] = 365 days * 3;
        fuseLockDurations[Types.FuseProduct.FiveYears] = 365 days * 5;

        fusePools[Types.FuseProduct.OneYear] = new FusePoolV2(msg.sender, this, 365 days);
        fusePools[Types.FuseProduct.ThreeYears] = new FusePoolV2(msg.sender, this, 365 days * 3);
        fusePools[Types.FuseProduct.FiveYears] = new FusePoolV2(msg.sender, this, 365 days * 5);

        boosts[Types.FuseProduct.OneYear] = 2e18;
        boosts[Types.FuseProduct.ThreeYears] = 12e18;
        boosts[Types.FuseProduct.FiveYears] = 36e18;
    }

    function createAmplifier(uint256 _months) external payable nonReentrant returns (uint256) {
        uint256 payment = getRenewalFeeForMonths(_months) + creationFee;
        require(msg.value == payment, "Invalid Ether value provided");
        require(balanceOf[msg.sender] < maxAmplifiersPerMinter, "Too many amplifiers");
        require(amplifi.burnForAmplifier(msg.sender, mintPrice), "Not able to burn");

        uint256 id = _createAmplifier(_months);

        (bool success,) = feeRecipients.validatorAcquisition.call{value: payment}("");
        require(success, "Could not send ETH");

        return id;
    }

    function createAmplifierBatch(uint256 _amount, uint256 _months)
        external
        payable
        nonReentrant
        returns (uint256[] memory ids)
    {
        uint256 payment = (getRenewalFeeForMonths(_months) + creationFee) * _amount;
        require(msg.value == payment, "Invalid Ether value provided");
        require(balanceOf[msg.sender] + _amount <= maxAmplifiersPerMinter, "Too many amplifiers");
        require(amplifi.burnForAmplifier(msg.sender, mintPrice * _amount), "Not able to burn");

        ids = new uint256[](_amount);
        for (uint256 i = 0; i < _amount;) {
            ids[i] = _createAmplifier(_months);
            unchecked {
                ++i;
            }
        }

        (bool success,) = feeRecipients.validatorAcquisition.call{value: payment}("");
        require(success, "Could not send ETH");

        return ids;
    }

    function _createAmplifier(uint256 _months) internal returns (uint256) {
        require(_months > 0 && _months <= maxMonths, "Must be 1-6 months");

        uint256 id;
        unchecked {
            id = totalAmplifiers++;
        }

        _amplifiers[id] = Types.AmplifierV2({
            fuseProduct: Types.FuseProduct.None,
            minter: msg.sender,
            numClaims: 0,
            created: uint48(block.timestamp),
            expires: uint48(block.timestamp + 30 days * _months),
            lastClaimed: 0,
            fused: 0,
            unlocks: 0
        });

        uint256 length;
        unchecked {
            length = balanceOf[msg.sender]++;
        }
        ownedAmplifiers[msg.sender][length] = id;
        ownedAmplifiersIndex[id] = length;

        emit Events.AmplifierCreated(id, msg.sender, _months);

        return id;
    }

    function renewAmplifier(uint256 _id, uint256 _months) external payable nonReentrant {
        uint256 payment = getRenewalFeeForMonths(_months);
        require(msg.value == payment, "Invalid Ether value provided");

        _renewAmplifier(_id, _months);

        (bool success,) = feeRecipients.validatorAcquisition.call{value: payment}("");
        require(success, "Could not send ETH");
    }

    function renewAmplifierBatch(uint256[] calldata _ids, uint256 _months) external payable nonReentrant {
        uint256 length = _ids.length;
        uint256 payment = (getRenewalFeeForMonths(_months)) * length;
        require(msg.value == payment, "Invalid Ether value provided");

        for (uint256 i = 0; i < length;) {
            _renewAmplifier(_ids[i], _months);
            unchecked {
                ++i;
            }
        }

        (bool success,) = feeRecipients.validatorAcquisition.call{value: payment}("");
        require(success, "Could not send ETH");
    }

    function _renewAmplifier(uint256 _id, uint256 _months) internal {
        Types.AmplifierV2 storage amplifier = _amplifiers[_id];

        require(amplifier.minter == msg.sender, "Invalid ownership");
        require(amplifier.expires + gracePeriod >= block.timestamp, "Grace period expired");

        amplifier.expires += uint48(30 days * _months);

        require(amplifier.expires < block.timestamp + (30 days * maxMonths), "Too many months");

        emit Events.AmplifierRenewed(_id, msg.sender, _months);
    }

    function fuseAmplifier(uint256 _id, Types.FuseProduct fuseProduct) external payable nonReentrant {
        Types.AmplifierV2 storage amplifier = _amplifiers[_id];

        require(amplifier.minter == msg.sender, "Invalid ownership");
        require(amplifier.fuseProduct == Types.FuseProduct.None, "Already fused");
        require(amplifier.expires > block.timestamp, "Amplifier expired");

        require(msg.value == fuseFee, "Invalid Ether value provided");

        uint48 unlocks = fusePools[fuseProduct].enter(_id);

        amplifier.fuseProduct = fuseProduct;
        amplifier.fused = uint48(block.timestamp);
        amplifier.unlocks = unlocks;

        emit Events.AmplifierFused(_id, msg.sender, fuseProduct);

        (bool success,) = feeRecipients.validatorAcquisition.call{value: msg.value}("");
        require(success, "Could not send ETH");
    }

    function claimAMPLIFI(uint256 _id) external nonReentrant {
        uint256 amount = _claimAMPLIFI(_id);

        amount = takeClaimFee(amount);
        require(amplifi.transfer(msg.sender, amount));

        emit Events.AMPLIFIClaimed(msg.sender, amount);
    }

    function claimAMPLIFIBatch(uint256[] calldata _ids) external nonReentrant {
        uint256 amount;
        uint256 length = _ids.length;
        for (uint256 i = 0; i < length;) {
            amount += _claimAMPLIFI(_ids[i]);
            unchecked {
                ++i;
            }
        }

        amount = takeClaimFee(amount);
        require(amplifi.transfer(msg.sender, amount));

        emit Events.AMPLIFIClaimed(msg.sender, amount);
    }

    function _claimAMPLIFI(uint256 _id) internal returns (uint256 amount) {
        Types.AmplifierV2 storage amplifier = _amplifiers[_id];
        require(amplifier.minter == msg.sender, "Invalid ownership");
        require(amplifier.fuseProduct == Types.FuseProduct.None, "Must be unfused");
        require(amplifier.expires > block.timestamp, "Amplifier expired");

        amount = getPendingAMPLIFI(_id);

        amplifier.numClaims++;
        amplifier.lastClaimed = uint48(block.timestamp);
    }

    function claimETH(uint256 _id, uint256[] calldata _blockNumbers) external nonReentrant {
        _claimETH(_id, _blockNumbers);
    }

    function claimETHBatch(uint256[] calldata _ids, uint256[] calldata _blockNumbers) external nonReentrant {
        uint256 length = _ids.length;
        for (uint256 i = 0; i < length;) {
            _claimETH(_ids[i], _blockNumbers);
            unchecked {
                ++i;
            }
        }
    }

    function _claimETH(uint256 _id, uint256[] calldata _blockNumbers) internal {
        Types.AmplifierV2 storage amplifier = _amplifiers[_id];
        require(amplifier.fuseProduct != Types.FuseProduct.None, "Must be fused");
        require(block.timestamp - amplifier.fused > fuseWaitPeriod, "Cannot claim ETH yet");

        if (_blockNumbers.length != 0) {
            require(amplifier.expires > block.timestamp, "Amplifier expired");
            uint256 amount = fusePools[amplifier.fuseProduct].claim(_id, _blockNumbers);

            emit Events.ETHClaimed(_id, amplifier.minter, msg.sender, amount);
        }

        if (amplifier.unlocks <= block.timestamp) {
            if (amplifier.expires > block.timestamp) {
                require(amplifi.transfer(amplifier.minter, boosts[amplifier.fuseProduct]));
            }
            fusePools[amplifier.fuseProduct].exit(_id);
            amplifier.fuseProduct = Types.FuseProduct.None;
            amplifier.fused = 0;
            amplifier.unlocks = 0;
        }
    }

    function getPendingAMPLIFI(uint256 _id) public view returns (uint256) {
        Types.AmplifierV2 memory amplifier = _amplifiers[_id];

        uint256 rate = amplifier.numClaims >= rates.length ? rates[rates.length - 1] : rates[amplifier.numClaims];
        uint256 amount =
            (block.timestamp - (amplifier.numClaims > 0 ? amplifier.lastClaimed : amplifier.created)) * (rate);
        if (amplifier.created < block.timestamp + gammaPeriod) {
            uint256 _seconds = (block.timestamp + gammaPeriod) - amplifier.created;
            uint256 _percent = 100;
            if (_seconds >= 4838400) {
                _percent = 900;
            } else if (_seconds >= 4233600) {
                _percent = 800;
            } else if (_seconds >= 3628800) {
                _percent = 700;
            } else if (_seconds >= 3024000) {
                _percent = 600;
            } else if (_seconds >= 2419200) {
                _percent = 500;
            } else if (_seconds >= 1814400) {
                _percent = 400;
            } else if (_seconds >= 1209600) {
                _percent = 300;
            } else if (_seconds >= 604800) {
                _percent = 200;
            }
            uint256 _divisor = amount * _percent;
            (, uint256 result) = tryDiv(_divisor, 10000);
            amount -= result;
        }

        return amount;
    }

    function takeClaimFee(uint256 amount) internal returns (uint256) {
        uint256 fee = (amount * claimFee) / bps;

        address[] memory path = new address[](2);
        path[0] = address(amplifi);
        path[1] = address(USDC);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(fee, 0, path, address(this), block.timestamp);

        uint256 usdcToSend = USDC.balanceOf(address(this)) / 2;

        USDC.transfer(feeRecipients.operations, usdcToSend);
        USDC.transfer(feeRecipients.developers, usdcToSend);

        return amount - fee;
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) {
                return (false, 0);
            }
            return (true, a / b);
        }
    }

    function getRenewalFeeForMonths(uint256 _months) public view returns (uint256) {
        return renewalFee * _months;
    }

    function amplifiers(uint256 _id) public view override returns (Types.AmplifierV2 memory) {
        return _amplifiers[_id];
    }

    function airdropAmplifiers(
        address[] calldata _users,
        uint256[] calldata _months,
        Types.FuseProduct[] calldata _fuseProducts
    ) external onlyOwner returns (uint256[] memory ids) {
        require(_users.length == _months.length && _months.length == _fuseProducts.length, "Lengths not aligned");

        uint256 length = _users.length;
        ids = new uint256[](length);
        for (uint256 i = 0; i < length;) {
            ids[i] = _airdropAmplifier(_users[i], _months[i], _fuseProducts[i]);
            unchecked {
                ++i;
            }
        }
        return ids;
    }

    function _airdropAmplifier(address _user, uint256 _months, Types.FuseProduct _fuseProduct)
        internal
        returns (uint256)
    {
        require(_months <= maxMonths, "Too many months");

        uint256 id;
        uint256 length;
        unchecked {
            id = totalAmplifiers++;
            length = balanceOf[_user]++;
        }

        uint48 fused;
        uint48 unlocks;

        if (_fuseProduct != Types.FuseProduct.None) {
            fused = uint48(block.timestamp);

            unlocks = fusePools[_fuseProduct].enter(id);
        }

        _amplifiers[id] = Types.AmplifierV2({
            fuseProduct: _fuseProduct,
            minter: _user,
            numClaims: 0,
            created: uint48(block.timestamp),
            expires: uint48(block.timestamp + 30 days * _months),
            lastClaimed: 0,
            fused: fused,
            unlocks: unlocks
        });

        ownedAmplifiers[_user][length] = id;
        ownedAmplifiersIndex[id] = length;

        return id;
    }

    function removeAmplifier(uint256 _id) external onlyOwner {
        uint256 lastAmplifierIndex = balanceOf[_amplifiers[_id].minter];
        uint256 amplifierIndex = ownedAmplifiersIndex[_id];

        if (amplifierIndex != lastAmplifierIndex) {
            uint256 lastAmplifierId = ownedAmplifiers[_amplifiers[_id].minter][lastAmplifierIndex];

            ownedAmplifiers[_amplifiers[_id].minter][amplifierIndex] = lastAmplifierId; // Move the last amplifier to the slot of the to-delete token
            ownedAmplifiersIndex[lastAmplifierId] = amplifierIndex; // Update the moved amplifier's index
        }

        // This also deletes the contents at the last position of the array
        delete ownedAmplifiersIndex[_id];
        delete ownedAmplifiers[_amplifiers[_id].minter][lastAmplifierIndex];

        balanceOf[_amplifiers[_id].minter]--;
        totalAmplifiers--;

        delete _amplifiers[_id];
    }

    function setRates(uint256[] calldata _rates) external onlyOwner {
        require(_rates.length == rates.length, "Invalid length");

        uint256 length = _rates.length;
        for (uint256 i = 0; i < length;) {
            rates[i] = _rates[i];
            unchecked {
                ++i;
            }
        }
    }

    function migrateV1Amplifiers(uint256[] calldata _ids) external returns (uint256[] memory) {
        uint256 length = _ids.length;
        uint256[] memory migratedIds = new uint256[](length);
        for (uint256 i = 0; i < length;) {
            uint256 id = _ids[i];
            require(!migratedAmplifiers[id], "Amplifier already migrated");

            Types.Amplifier memory v1Amplifier = oldAmplifiNode.amplifiers(id);
            require(v1Amplifier.created != 0, "Amplifier doesn't exist");
            require(v1Amplifier.expires + gracePeriod >= block.timestamp, "Grace period expired");
            require(msg.sender == v1Amplifier.minter, "Amplifier can only be migrated by the minter");

            migratedAmplifiers[id] = true;
            migratedIds[i] = _createMigratedAmplifier(v1Amplifier, id);

            unchecked {
                ++i;
            }
        }
        return migratedIds;
    }

    function _createMigratedAmplifier(Types.Amplifier memory _v1Amplifier, uint256 _v1AmplifierId)
        internal
        returns (uint256)
    {
        uint256 id;
        unchecked {
            id = totalAmplifiers++;
        }

        _amplifiers[id] = Types.AmplifierV2({
            fuseProduct: _v1Amplifier.fuseProduct,
            minter: _v1Amplifier.minter,
            numClaims: uint16(_v1Amplifier.numClaims),
            created: uint48(_v1Amplifier.created),
            expires: uint48(_v1Amplifier.expires),
            lastClaimed: uint48(_v1Amplifier.lastClaimed),
            fused: uint48(_v1Amplifier.fused),
            unlocks: uint48(_v1Amplifier.unlocks)
        });

        if (_v1Amplifier.fuseProduct != Types.FuseProduct.None) {
            fusePools[_v1Amplifier.fuseProduct].migrateShare(id, uint48(_v1Amplifier.unlocks), false);
        }

        uint256 length;
        unchecked {
            length = balanceOf[_v1Amplifier.minter]++;
        }
        ownedAmplifiers[_v1Amplifier.minter][length] = id;
        ownedAmplifiersIndex[id] = length;

        emit Events.AmplifierMigrated(_v1AmplifierId, id, _v1Amplifier.minter);

        return id;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMonths(uint16 _maxMonths) external onlyOwner {
        maxMonths = _maxMonths;
    }

    function setFees(uint256 _creationFee, uint256 _renewalFee, uint256 _fuseFee, uint16 _claimFee)
        external
        onlyOwner
    {
        creationFee = _creationFee;
        renewalFee = _renewalFee;
        fuseFee = _fuseFee;
        claimFee = _claimFee;
    }

    function setFuseLockDurations(Types.FuseProduct _fuseProduct, uint256 _duration) external onlyOwner {
        fuseLockDurations[_fuseProduct] = _duration;
    }

    function setFusePool(Types.FuseProduct _fuseProduct, FusePoolV2 _fusePool) external onlyOwner {
        fusePools[_fuseProduct] = _fusePool;
    }

    function setBoosts(Types.FuseProduct _fuseProduct, uint256 _boost) external onlyOwner {
        boosts[_fuseProduct] = _boost;
    }

    function setFeeRecipients(Types.AmplifierFeeRecipients calldata _feeRecipients) external onlyOwner {
        feeRecipients = _feeRecipients;
    }

    function setPeriods(uint256 _gracePeriod, uint256 _gammaPeriod, uint256 _fuseWaitPeriod) external onlyOwner {
        gracePeriod = _gracePeriod;
        gammaPeriod = _gammaPeriod;
        fuseWaitPeriod = _fuseWaitPeriod;
    }

    function approveRouter() external onlyOwner {
        amplifi.approve(address(router), type(uint256).max);
    }

    function withdrawETH(address _recipient) external onlyOwner {
        (bool success,) = _recipient.call{value: address(this).balance}("");
        require(success, "Could not send ETH");
    }

    function withdrawToken(IERC20 _token, address _recipient) external onlyOwner {
        _token.transfer(_recipient, _token.balanceOf(address(this)));
    }

    receive() external payable {}
}