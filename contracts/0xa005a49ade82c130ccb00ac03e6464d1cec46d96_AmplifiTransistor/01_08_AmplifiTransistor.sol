// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAmplifi.sol";
import "./interfaces/IUniswap.sol";
import "./Types.sol";

/**
 * Amplifi
 * Website: https://perpetualyield.io/
 * Telegram: https://t.me/Amplifi_ERC
 * Twitter: https://twitter.com/amplifidefi
 */
contract AmplifiTransistor is Ownable, ReentrancyGuard {
    uint16 public maxMonths = 1;
    uint16 public maxTransistorsPerMinter = 48;
    uint256 public gracePeriod = 30 days;

    uint256 public totalTransistors = 0;
    mapping(uint256 => Types.Transistor) public transistors;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(uint256 => uint256)) public ownedTransistors;
    mapping(uint256 => uint256) public ownedTransistorsIndex;

    uint256 public creationFee = 0.004 ether;
    uint256 public renewalFee = 0.004 ether;
    uint256 public refundFee = 0.12 ether;
    uint256 public mintPrice = 6e18;
    uint256 public refundAmount = 6e18;
    address public burnAddress;

    uint256[20] public rates = [
        169056603773,
        151305660376,
        135418566037,
        121199616603,
        108473656860,
        97083922889,
        86890110986,
        77766649332,
        69601151153,
        62293030282,
        55752262102,
        49898274581,
        44658955750,
        39969765396,
        35772940030,
        32016781327,
        28655019287,
        25646242262,
        20543281208,
        17236591470
    ];

    IAmplifi public immutable amplifi;
    IUniswapV2Router02 public immutable router;
    IERC20 public immutable USDC;

    Types.TransistorFeeRecipients public feeRecipients;

    uint16 public claimFee = 600;
    uint16 public mintBurn = 9_000;
    uint16 public mintLP = 1_000;
    // Basis for above fee values
    uint16 public constant bps = 10_000;

    constructor(
        IAmplifi _amplifi,
        IUniswapV2Router02 _router,
        IERC20 _usdc,
        address _burnAddress,
        address _standardFeeRecipient,
        address _taxRecipient,
        address _operations,
        address _developers
    ) {
        amplifi = _amplifi;
        router = _router;
        USDC = _usdc;
        burnAddress = _burnAddress;

        feeRecipients = Types.TransistorFeeRecipients(
            _standardFeeRecipient,
            _taxRecipient,
            _standardFeeRecipient,
            _standardFeeRecipient,
            _operations,
            _developers
        );

        amplifi.approve(address(_router), type(uint256).max);
    }

    function createTransistor(uint256 _months, uint256 _amountOutMin) external payable nonReentrant returns (uint256) {
        require(msg.value == getRenewalFeeForMonths(_months) + creationFee, "Invalid Ether value provided");
        chargeFee(feeRecipients.creationFee, msg.value);

        return _createTransistor(_months, _amountOutMin);
    }

    function createTransistorBatch(
        uint256 _amount,
        uint256 _months,
        uint256 _amountOutMin
    ) external payable nonReentrant returns (uint256[] memory ids) {
        require(msg.value == (getRenewalFeeForMonths(_months) + creationFee) * _amount, "Invalid Ether value provided");
        chargeFee(feeRecipients.creationFee, msg.value);

        ids = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; ) {
            ids[i] = _createTransistor(_months, _amountOutMin);
            unchecked {
                ++i;
            }
        }
        return ids;
    }

    function _createTransistor(uint256 _months, uint256 _amountOutMin) internal returns (uint256) {
        require(balanceOf[msg.sender] < maxTransistorsPerMinter, "Too many transistors");
        require(_months > 0 && _months <= maxMonths, "Must be greater than 0 and less than maxMonths");

        require(amplifi.transferFrom(msg.sender, address(this), mintPrice), "Unable to transfer Amplifi");

        // we can't burn from the contract so we have to send to a special address from which the deployer will then burn
        amplifi.transfer(burnAddress, (mintPrice * mintBurn) / bps);

        sell((mintPrice * (mintLP / 2)) / bps, _amountOutMin);
        uint256 usdcBalance = USDC.balanceOf(address(this));
        USDC.transfer(feeRecipients.creationTax, usdcBalance);

        amplifi.transfer(feeRecipients.creationTax, (mintPrice * (mintLP / 2)) / bps);

        uint256 id;
        uint256 length;
        unchecked {
            id = totalTransistors++;
            length = balanceOf[msg.sender]++;
        }

        transistors[id] = Types.Transistor(msg.sender, block.timestamp, block.timestamp + 30 days * _months, 0, 0);
        ownedTransistors[msg.sender][length] = id;
        ownedTransistorsIndex[id] = length;

        return id;
    }

    function renewTransistor(uint256 _id, uint256 _months) external payable nonReentrant {
        require(msg.value == getRenewalFeeForMonths(_months), "Invalid Ether value provided");
        chargeFee(feeRecipients.renewalFee, msg.value);

        _renewTransistor(_id, _months);
    }

    function renewTransistorBatch(uint256[] calldata _ids, uint256 _months) external payable nonReentrant {
        uint256 length = _ids.length;
        require(msg.value == (getRenewalFeeForMonths(_months)) * length, "Invalid Ether value provided");
        chargeFee(feeRecipients.renewalFee, msg.value);

        for (uint256 i = 0; i < length; ) {
            _renewTransistor(_ids[i], _months);
            unchecked {
                ++i;
            }
        }
    }

    function _renewTransistor(uint256 _id, uint256 _months) internal {
        Types.Transistor storage transistor = transistors[_id];

        require(transistor.minter == msg.sender, "Invalid ownership");
        require(transistor.expires + gracePeriod >= block.timestamp, "Grace period expired or transistor reversed");

        uint256 monthsLeft = 0;
        if (block.timestamp > transistor.expires) {
            monthsLeft = (block.timestamp - transistor.expires) / 30 days;
        } else {
            monthsLeft = (transistor.expires - block.timestamp) / 30 days;
        }

        require(_months + monthsLeft <= maxMonths, "Too many months");

        transistor.expires += 30 days * _months;
    }

    function reverseTransistor(uint256 _id) external payable nonReentrant {
        Types.Transistor storage transistor = transistors[_id];

        require(transistor.minter == msg.sender, "Invalid ownership");
        require(transistor.expires > block.timestamp, "Transistor expired");
        require(transistor.numClaims == 0, "Already claimed");
        require(msg.value == refundFee, "Invalid Ether value provided");

        chargeFee(feeRecipients.reverseFee, msg.value);

        transistor.expires = 0;
        amplifi.transfer(msg.sender, refundAmount);
    }

    function claimAMPLIFI(uint256 _id, uint256 _amountOutMin) external nonReentrant {
        _claimAMPLIFI(_id, _amountOutMin);
    }

    function claimAMPLIFIBatch(uint256[] calldata _ids, uint256 _amountOutMin) external nonReentrant {
        uint256 length = _ids.length;
        for (uint256 i = 0; i < length; ) {
            _claimAMPLIFI(_ids[i], _amountOutMin);
            unchecked {
                ++i;
            }
        }
    }

    function _claimAMPLIFI(uint256 _id, uint256 _amountOutMin) internal {
        Types.Transistor storage transistor = transistors[_id];
        require(transistor.minter == msg.sender, "Invalid ownership");
        require(transistor.expires > block.timestamp, "Transistor expired or reversed");

        uint256 amount = getPendingAMPLIFI(_id);
        amount = takeClaimFee(amount, _amountOutMin);
        amplifi.transfer(msg.sender, amount);

        transistor.numClaims++;
        transistor.lastClaimed = block.timestamp;
    }

    function getPendingAMPLIFI(uint256 _id) public view returns (uint256) {
        Types.Transistor memory transistor = transistors[_id];

        uint256 rate = transistor.numClaims >= rates.length ? rates[rates.length - 1] : rates[transistor.numClaims];
        uint256 amount = (block.timestamp - (transistor.numClaims > 0 ? transistor.lastClaimed : transistor.created)) *
            (rate);

        return amount;
    }

    function takeClaimFee(uint256 _amount, uint256 _amountOutMin) internal returns (uint256) {
        uint256 fee = (_amount * claimFee) / bps;

        sell(fee, _amountOutMin);

        uint256 usdcBalance = USDC.balanceOf(address(this));

        USDC.transfer(feeRecipients.claimFeeDevelopers, (usdcBalance * 34) / 100);
        USDC.transfer(feeRecipients.claimFeeOperations, (usdcBalance * 66) / 100);

        return _amount - fee;
    }

    function sell(uint256 _amount, uint256 _amountOutMin) internal {
        address[] memory path = new address[](2);
        path[0] = address(amplifi);
        path[1] = address(USDC);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            _amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

    function getRenewalFeeForMonths(uint256 _months) public view returns (uint256) {
        return renewalFee * _months;
    }

    function airdropTransistors(address[] calldata _users, uint256[] calldata _months)
        external
        onlyOwner
        returns (uint256[] memory ids)
    {
        require(_users.length == _months.length, "Lengths not aligned");

        uint256 length = _users.length;
        ids = new uint256[](length);
        for (uint256 i = 0; i < length; ) {
            ids[i] = _airdropTransistor(_users[i], _months[i]);
            unchecked {
                ++i;
            }
        }

        return ids;
    }

    function _airdropTransistor(address _user, uint256 _months) internal returns (uint256) {
        require(_months <= maxMonths, "Too many months");

        uint256 id;
        uint256 length;
        unchecked {
            id = totalTransistors++;
            length = balanceOf[_user]++;
        }

        transistors[id] = Types.Transistor(_user, block.timestamp, block.timestamp + 30 days * _months, 0, 0);
        ownedTransistors[_user][length] = id;
        ownedTransistorsIndex[id] = length;

        return id;
    }

    function removeTransistor(uint256 _id) external onlyOwner {
        uint256 lastTransistorIndex = balanceOf[transistors[_id].minter];
        uint256 transistorIndex = ownedTransistorsIndex[_id];

        if (transistorIndex != lastTransistorIndex) {
            uint256 lastTransistorId = ownedTransistors[transistors[_id].minter][lastTransistorIndex];

            ownedTransistors[transistors[_id].minter][transistorIndex] = lastTransistorId; // Move the last Transistor to the slot of the to-delete token
            ownedTransistorsIndex[lastTransistorId] = transistorIndex; // Update the moved Transistor's index
        }

        // This also deletes the contents at the last position of the array
        delete ownedTransistorsIndex[_id];
        delete ownedTransistors[transistors[_id].minter][lastTransistorIndex];

        balanceOf[transistors[_id].minter]--;
        totalTransistors--;

        delete transistors[_id];
    }

    function chargeFee(address _recipient, uint256 _amount) internal {
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Could not send ETH");
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
        uint256 _refundFee,
        uint16 _claimFee,
        uint16 _mintBurn,
        uint16 _mintLP
    ) external onlyOwner {
        creationFee = _creationFee;
        renewalFee = _renewalFee;
        refundFee = _refundFee;
        claimFee = _claimFee;
        mintBurn = _mintBurn;
        mintLP = _mintLP;
    }

    function setRefundAmounts(uint256 _refundAmount) external onlyOwner {
        refundAmount = _refundAmount;
    }

    function setBurnAddress(address _burnAddress) external onlyOwner {
        burnAddress = _burnAddress;
    }

    function setFeeRecipients(Types.TransistorFeeRecipients calldata _feeRecipients) external onlyOwner {
        feeRecipients = _feeRecipients;
    }

    function setPeriods(uint256 _gracePeriod) external onlyOwner {
        gracePeriod = _gracePeriod;
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