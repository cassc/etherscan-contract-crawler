// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAmplifi.sol";
import "./interfaces/IUniswap.sol";
import "./FusePool.sol";
import "./Types.sol";

contract AmplifiNode is Ownable, ReentrancyGuard {
    uint16 public maxMonths = 6;
    uint16 public maxAmplifiersPerMinter = 96;
    uint256 public gracePeriod = 30 days;
    uint256 public gammaPeriod = 72 days;
    uint256 public fuseWaitPeriod = 90 days;

    uint256 public totalAmplifiers = 0;
    mapping(uint256 => Types.Amplifier) public amplifiers;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(uint256 => uint256)) public ownedAmplifiers;
    mapping(uint256 => uint256) public ownedAmplifiersIndex;

    mapping(Types.FuseProduct => uint256) public fuseLockDurations;
    mapping(Types.FuseProduct => FusePool) public fusePools;
    mapping(Types.FuseProduct => uint256) public boosts;

    uint256 public creationFee = 0;
    uint256 public renewalFee = 0.006 ether;
    uint256 public fuseFee = 0.007 ether;
    uint256 public mintPrice = 20e18;

    uint256[20] public rates = [
        700000000000,
        595000000000,
        505750000000,
        429887500000,
        365404375000,
        310593718750,
        264004660937,
        224403961797,
        190743367527,
        162131862398,
        137812083039,
        117140270583,
        99569229995,
        84633845496,
        71938768672,
        61147953371,
        51975760365,
        44179396311,
        37552486864,
        31919613834
    ];

    IAmplifi public immutable amplifi;
    IUniswapV2Router02 public immutable router;
    IERC20 public immutable USDC;

    Types.AmplifierFeeRecipients public feeRecipients;

    uint16 public claimFee = 600;
    // Basis for above fee values
    uint16 public constant bps = 10_000;

    constructor(
        IAmplifi _amplifi,
        IUniswapV2Router02 _router,
        IERC20 _usdc,
        address _owner
    ) {
        transferOwnership(_owner);
        amplifi = _amplifi;
        router = _router;
        USDC = _usdc;

        feeRecipients = Types.AmplifierFeeRecipients(
            0xc766B8c9741BC804FCc378FdE75560229CA3AB1E,
            0x682Ce32507D2825A540Ad31dC4C2B18432E0e5Bd,
            0x454cD1e89df17cDB61D868C6D3dBC02bC2c38a17
        );

        fuseLockDurations[Types.FuseProduct.OneYear] = 365 days;
        fuseLockDurations[Types.FuseProduct.ThreeYears] = 365 days * 3;
        fuseLockDurations[Types.FuseProduct.FiveYears] = 365 days * 5;

        fusePools[Types.FuseProduct.OneYear] = new FusePool(_owner, 365 days);
        fusePools[Types.FuseProduct.ThreeYears] = new FusePool(_owner, 365 days * 3);
        fusePools[Types.FuseProduct.FiveYears] = new FusePool(_owner, 365 days * 5);

        boosts[Types.FuseProduct.OneYear] = 2e18;
        boosts[Types.FuseProduct.ThreeYears] = 12e18;
        boosts[Types.FuseProduct.FiveYears] = 36e18;
    }

    function createAmplifier(uint256 _months) external payable nonReentrant returns (uint256) {
        require(msg.value == getRenewalFeeForMonths(_months) + creationFee, "Invalid Ether value provided");
        return _createAmplifier(_months);
    }

    function createAmplifierBatch(uint256 _amount, uint256 _months)
        external
        payable
        nonReentrant
        returns (uint256[] memory ids)
    {
        require(msg.value == (getRenewalFeeForMonths(_months) + creationFee) * _amount, "Invalid Ether value provided");
        ids = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; ) {
            ids[i] = _createAmplifier(_months);
            unchecked {
                ++i;
            }
        }
        return ids;
    }

    function _createAmplifier(uint256 _months) internal returns (uint256) {
        require(balanceOf[msg.sender] < maxAmplifiersPerMinter, "Too many amplifiers");
        require(_months > 0 && _months <= maxMonths, "Must be 1-6 months");

        require(amplifi.burnForAmplifier(msg.sender, mintPrice), "Not able to burn");

        (bool success, ) = feeRecipients.validatorAcquisition.call{
            value: getRenewalFeeForMonths(_months) + creationFee
        }("");
        require(success, "Could not send ETH");

        uint256 id;
        uint256 length;
        unchecked {
            id = totalAmplifiers++;
            length = balanceOf[msg.sender]++;
        }

        amplifiers[id] = Types.Amplifier(
            Types.FuseProduct.None,
            msg.sender,
            block.timestamp,
            block.timestamp + 30 days * _months,
            0,
            0,
            0,
            0,
            0
        );
        ownedAmplifiers[msg.sender][length] = id;
        ownedAmplifiersIndex[id] = length;

        return id;
    }

    function renewAmplifier(uint256 _id, uint256 _months) external payable nonReentrant {
        require(msg.value == getRenewalFeeForMonths(_months), "Invalid Ether value provided");
        _renewAmplifier(_id, _months);
    }

    function renewAmplifierBatch(uint256[] calldata _ids, uint256 _months) external payable nonReentrant {
        uint256 length = _ids.length;
        require(msg.value == (getRenewalFeeForMonths(_months)) * length, "Invalid Ether value provided");
        for (uint256 i = 0; i < length; ) {
            _renewAmplifier(_ids[i], _months);
            unchecked {
                ++i;
            }
        }
    }

    function _renewAmplifier(uint256 _id, uint256 _months) internal {
        Types.Amplifier storage amplifier = amplifiers[_id];

        require(amplifier.minter == msg.sender, "Invalid ownership");
        require(amplifier.expires + gracePeriod >= block.timestamp, "Grace period expired");

        uint256 monthsLeft = 0;
        if (block.timestamp > amplifier.expires) {
            monthsLeft = (block.timestamp - amplifier.created) / 30 days;
        }
        require(_months + monthsLeft <= maxMonths, "Too many months");

        (bool success, ) = feeRecipients.validatorAcquisition.call{value: getRenewalFeeForMonths(_months)}("");
        require(success, "Could not send ETH");

        amplifier.expires += 30 days * _months;
    }

    function fuseAmplifier(uint256 _id, Types.FuseProduct fuseProduct) external payable nonReentrant {
        Types.Amplifier storage amplifier = amplifiers[_id];

        require(amplifier.minter == msg.sender, "Invalid ownership");
        require(amplifier.fuseProduct == Types.FuseProduct.None, "Already fused");
        require(amplifier.expires > block.timestamp, "Amplifier expired");

        require(msg.value == fuseFee, "Invalid Ether value provided");

        (bool success, ) = feeRecipients.validatorAcquisition.call{value: msg.value}("");
        require(success, "Could not send ETH");

        INetwork network = fusePools[fuseProduct];
        network.increaseShare(msg.sender, block.timestamp + fuseLockDurations[fuseProduct]);

        amplifier.fuseProduct = fuseProduct;
        amplifier.fused = block.timestamp;
        amplifier.unlocks = block.timestamp + fuseLockDurations[fuseProduct];
    }

    function claimAMPLIFI(uint256 _id) external nonReentrant {
        _claimAMPLIFI(_id);
    }

    function claimAMPLIFIBatch(uint256[] calldata _ids) external nonReentrant {
        uint256 length = _ids.length;
        for (uint256 i = 0; i < length; ) {
            _claimAMPLIFI(_ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _claimAMPLIFI(uint256 _id) internal {
        Types.Amplifier storage amplifier = amplifiers[_id];
        require(amplifier.minter == msg.sender, "Invalid ownership");
        require(amplifier.fuseProduct == Types.FuseProduct.None, "Must be unfused");
        require(amplifier.expires > block.timestamp, "Amplifier expired");

        uint256 amount = getPendingAMPLIFI(_id);
        amount = takeClaimFee(amount);
        amplifi.transfer(msg.sender, amount);

        amplifier.numClaims++;
        amplifier.lastClaimed = block.timestamp;
    }

    function claimETH(uint256 _id) external nonReentrant {
        _claimETH(_id);
    }

    function claimETHBatch(uint256[] calldata _ids) external nonReentrant {
        uint256 length = _ids.length;
        for (uint256 i = 0; i < length; ) {
            _claimETH(_ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _claimETH(uint256 _id) internal {
        Types.Amplifier storage amplifier = amplifiers[_id];
        require(amplifier.minter == msg.sender, "Invalid ownership");
        require(amplifier.fuseProduct != Types.FuseProduct.None, "Must be fused");
        require(amplifier.expires > block.timestamp, "Amplifier expired");
        require(block.timestamp - amplifier.fused > fuseWaitPeriod, "Cannot claim ETH yet");

        fusePools[amplifier.fuseProduct].distributeDividend(msg.sender);

        if (amplifier.unlocks <= block.timestamp) {
            require(amplifi.transfer(msg.sender, boosts[amplifier.fuseProduct]));

            fusePools[amplifier.fuseProduct].decreaseShare(amplifier.minter);
            amplifier.fuseProduct = Types.FuseProduct.None;
            amplifier.fused = 0;
            amplifier.unlocks = 0;
        }
    }

    function getPendingAMPLIFI(uint256 _id) public view returns (uint256) {
        Types.Amplifier memory amplifier = amplifiers[_id];

        uint256 rate = amplifier.numClaims >= rates.length ? rates[rates.length - 1] : rates[amplifier.numClaims];
        uint256 amount = (block.timestamp - (amplifier.numClaims > 0 ? amplifier.lastClaimed : amplifier.created)) *
            (rate);
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

    function airdropAmplifiers(
        address[] calldata _users,
        uint256[] calldata _months,
        Types.FuseProduct[] calldata _fuseProducts
    ) external onlyOwner returns (uint256[] memory ids) {
        require(_users.length == _months.length && _months.length == _fuseProducts.length, "Lengths not aligned");

        uint256 length = _users.length;
        ids = new uint256[](length);
        for (uint256 i = 0; i < length; ) {
            ids[i] = _airdropAmplifier(_users[i], _months[i], _fuseProducts[i]);
            unchecked {
                ++i;
            }
        }

        return ids;
    }

    function _airdropAmplifier(
        address _user,
        uint256 _months,
        Types.FuseProduct _fuseProduct
    ) internal returns (uint256) {
        require(_months <= maxMonths, "Too many months");

        uint256 id;
        uint256 length;
        unchecked {
            id = totalAmplifiers++;
            length = balanceOf[_user]++;
        }

        uint256 fused;
        uint256 unlocks;

        if (_fuseProduct != Types.FuseProduct.None) {
            fused = block.timestamp;
            unlocks = block.timestamp + fuseLockDurations[_fuseProduct];
        }

        amplifiers[id] = Types.Amplifier(
            _fuseProduct,
            _user,
            block.timestamp,
            block.timestamp + 30 days * _months,
            0,
            0,
            fused,
            unlocks,
            0
        );
        ownedAmplifiers[_user][length] = id;
        ownedAmplifiersIndex[id] = length;

        return id;
    }

    function removeAmplifier(uint256 _id) external onlyOwner {
        uint256 lastAmplifierIndex = balanceOf[amplifiers[_id].minter];
        uint256 amplifierIndex = ownedAmplifiersIndex[_id];

        if (amplifierIndex != lastAmplifierIndex) {
            uint256 lastAmplifierId = ownedAmplifiers[amplifiers[_id].minter][lastAmplifierIndex];

            ownedAmplifiers[amplifiers[_id].minter][amplifierIndex] = lastAmplifierId; // Move the last amplifier to the slot of the to-delete token
            ownedAmplifiersIndex[lastAmplifierId] = amplifierIndex; // Update the moved amplifier's index
        }

        // This also deletes the contents at the last position of the array
        delete ownedAmplifiersIndex[_id];
        delete ownedAmplifiers[amplifiers[_id].minter][lastAmplifierIndex];

        balanceOf[amplifiers[_id].minter]--;
        totalAmplifiers--;

        delete amplifiers[_id];
    }

    function setRates(uint256[] calldata _rates) external onlyOwner {
        require(_rates.length == rates.length, "Invalid length");

        uint256 length = _rates.length;
        for (uint256 i = 0; i < length; ) {
            rates[i] = _rates[i];
            unchecked {
                ++i;
            }
        }
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMonths(uint16 _maxMonths) external onlyOwner {
        maxMonths = _maxMonths;
    }

    function setFees(
        uint256 _creationFee,
        uint256 _renewalFee,
        uint256 _fuseFee,
        uint16 _claimFee
    ) external onlyOwner {
        creationFee = _creationFee;
        renewalFee = _renewalFee;
        fuseFee = _fuseFee;
        claimFee = _claimFee;
    }

    function setFuseLockDurations(Types.FuseProduct _fuseProduct, uint256 _duration) external onlyOwner {
        fuseLockDurations[_fuseProduct] = _duration;
    }

    function setFusePool(Types.FuseProduct _fuseProduct, FusePool _fusePool) external onlyOwner {
        fusePools[_fuseProduct] = _fusePool;
    }

    function setBoosts(Types.FuseProduct _fuseProduct, uint256 _boost) external onlyOwner {
        boosts[_fuseProduct] = _boost;
    }

    function setFeeRecipients(Types.AmplifierFeeRecipients calldata _feeRecipients) external onlyOwner {
        feeRecipients = _feeRecipients;
    }

    function setPeriods(
        uint256 _gracePeriod,
        uint256 _gammaPeriod,
        uint256 _fuseWaitPeriod
    ) external onlyOwner {
        gracePeriod = _gracePeriod;
        gammaPeriod = _gammaPeriod;
        fuseWaitPeriod = _fuseWaitPeriod;
    }

    function approveRouter() external onlyOwner {
        amplifi.approve(address(router), type(uint256).max);
    }

    function withdrawETH(address _recipient) external onlyOwner {
        (bool success, ) = _recipient.call{value: address(this).balance}("");
        require(success, "Could not send ETH");
    }

    function withdrawToken(IERC20 _token, address _recipient) external onlyOwner {
        _token.transfer(_recipient, _token.balanceOf(address(this)));
    }

    receive() external payable {}
}