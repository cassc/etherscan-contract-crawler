// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/interfaces/IERC1820Registry.sol";
import "@openzeppelin/contracts/utils/introspection/ERC1820Implementer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "./PreUtils.sol";
import "./PreUranoBundles.sol";
import "./PreUranoRegistry.sol";
import "./TrackRewards.sol";

contract PreUranoSplitPay is
    Context,
    IERC777Sender,
    ERC1820Implementer,
    IERC777Recipient,
    Ownable
{
    //hooks
    IERC777 public preUrano;
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");
    bytes32 public constant TOKENS_SENDER_INTERFACE_HASH =
        keccak256("ERC777TokensSender");
    IERC1820Registry private _erc1820;

    using SafeERC20 for IERC20;
    IERC20 private _usdt;

    //using EnumerableMap for EnumerableMap.AddressToUintMap;
    //using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;
    Counters.Counter private trxId;

    PreUranoRegistry private preUranoRegistry;
    TrackRewards private trackRewards;

    mapping ( address => uint256 ) private prizesPaid;

    event BuyBundle(
        address indexed caller,
        address indexed referralAddress,
        bytes indexed trxIdentifier,
        address safeOwnerAddress,
        address contractAddress,
        uint16 decimillsApplied,
        uint256 usdtVal,
        uint256 uranoVal,
        uint256[2] netValuesSplit
    );

    event WithdrawAll(
        address indexed destinationAddress,
        bytes indexed trxIdentifier,
        uint256 preUranoQuantity,
        uint256 usdtQuantity
    );

    address private contractAddress;

    // solhint-disable-next-line
    constructor() {
        //replace with current pre-urano contract
        // ERC777 URANO
        preUrano = IERC777(0x46A5Ece048477D34aFFD5dc16B3A960181B02658);
        // production and testnet registry
        _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
        // local test registry overide
        _usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        //_erc1820 = IERC1820Registry(0xd9145CCE52D386f254917e481eB44e9943F39138);
        // 777Recipient
        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
        // track reward split play management contract
        trackRewards = TrackRewards(0x07379f8321811316020158E589fE4300A0a65da6);
        // track user volumes
        preUranoRegistry = PreUranoRegistry(
            0xF11c1578e1a88E13Ffd1DB92b6EEbDb8e2D65F30
        );
        contractAddress = address(this);
    }

    function getBundleJsonArray() public pure returns (string memory) {
        return PreUranoBundles.getBundleJsonArray();
    }

    function getPaydPrize(address _refAddr) public view returns (uint256){
        return prizesPaid[_refAddr];
    }


    function getAvailableBundlesJsonArray()
        public
        view
        returns (string memory)
    {
        return
            PreUranoBundles.getAvailableBundlesJsonArray(
                PreUtils.attoToUnit(preUrano.balanceOf(contractAddress))
            );
    }

    function getBundleByNameJs(string memory _bundle)
        public
        pure
        returns (uint256[2] memory)
    {
        return PreUranoBundles.getBundleByName(_bundle);
    }

    function getLastTransactionId() external view returns (bytes memory) {
        return abi.encodePacked(trxId.current());
    }

    function withdrawAllFromContract() public onlyOwner {
        uint256 usdBalance = _usdt.balanceOf(contractAddress);
        uint256 perUranoBalance = preUrano.balanceOf(contractAddress);
        address safeOwnerAddress = trackRewards.getMainUsdRecipient();
        trxId.increment();
        bytes memory trx = abi.encodePacked(uint256(trxId.current()));
        if (usdBalance > 0) {
            _usdt.transfer(safeOwnerAddress, usdBalance);
        }
        if (perUranoBalance > 0) {
            preUrano.send(safeOwnerAddress, perUranoBalance, trx);
        }
        emit WithdrawAll(safeOwnerAddress, trx, perUranoBalance, usdBalance);
    }

    function buyBundle(string memory _bundle, address referralAddress)
        external
    {
        bool registeredRevAddr = false;
        uint16 decimillsApplied = 0;
        //getBundleByName(string memory _bundle)
        uint256[2] memory bundleVals = PreUranoBundles.getBundleByName(_bundle);
        //"0": "uint256[2]: 1000000000,20000000000000000000000000"
        require(_usdt.balanceOf(msg.sender) >= bundleVals[0], "missing usdt");
        require(
            _usdt.allowance(msg.sender, contractAddress) >= bundleVals[0],
            "insufficient allowance"
        );
        require(
            preUrano.balanceOf(contractAddress) >= bundleVals[1],
            "The amount of tokens on the contract is insufficient to proceed with the bundle sale."
        );

        if (trackRewards.isRegisteredRewardAddress(referralAddress)) {
            // 4% split pay 0x617F2E2fD72FD9D5503197092aC168c91465E7f2
            registeredRevAddr = true;
            decimillsApplied = trackRewards.getRewardByAddress(referralAddress);
        }

        //_usdt.safeIncreaseAllowance(contractAddress, bundleVals[0]);
        /*
        event BuyBundle(
        address indexed caller,
        address indexed referralAddress,
        address contractAddress,
        uint16 decimillsApplied,
        uint16 usdtVal,
        uint256 uranoVal
        );

        */
        address safeOwnerAddress = trackRewards.getMainUsdRecipient();
        trxId.increment();
        bytes memory trx = abi.encodePacked(uint256(trxId.current()));

        uint256[2] memory splitNetValues = PreUtils.readPercent(
            bundleVals[0],
            decimillsApplied
        );
        //safe, owned address
        _usdt.safeTransferFrom(msg.sender, safeOwnerAddress, splitNetValues[1]);
        //safe, new standard
        preUrano.send(msg.sender, bundleVals[1], trx);
        preUranoRegistry.addAmountToDeposit(msg.sender, bundleVals[1]);
        //less safe, external address
        if (registeredRevAddr) {
            _usdt.safeTransferFrom(
                msg.sender,
                referralAddress,
                splitNetValues[0]
            );
            prizesPaid[referralAddress] += splitNetValues[0];
        }

        emit BuyBundle(
            msg.sender,
            referralAddress,
            trx,
            safeOwnerAddress,
            contractAddress,
            decimillsApplied,
            bundleVals[0],
            bundleVals[1],
            splitNetValues
        );
        //_usdt.safeTransferFrom(msg.sender, splitPayConf.getMainUsdRecipient(), bundleVals[0]);
    }

    // 777 BEGIN --------------------------------------------------------------------------------------------------

    event UranoToSendCalled(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes data,
        bytes operatorData,
        address token,
        uint256 fromBalance,
        uint256 toBalance
    );

    event UranoReceivedCalled(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes data,
        bytes operatorData,
        address token,
        uint256 fromBalance,
        uint256 toBalance
    );

    event BeforeTokenTransfer();
    bool private _shouldRevertSend;
    bool private _shouldRevertReceive;

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        if (_shouldRevertSend) {
            revert();
        }

        IERC777 token = IERC777(_msgSender());

        uint256 fromBalance = token.balanceOf(from);
        // when called due to burn, to will be the zero address, which will have a balance of 0
        uint256 toBalance = token.balanceOf(to);

        emit UranoToSendCalled(
            operator,
            from,
            to,
            amount,
            userData,
            operatorData,
            address(token),
            fromBalance,
            toBalance
        );
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        if (_shouldRevertReceive) {
            revert();
        }

        IERC777 token = IERC777(_msgSender());

        uint256 fromBalance = token.balanceOf(from);
        // when called due to burn, to will be the zero address, which will have a balance of 0
        uint256 toBalance = token.balanceOf(to);

        emit UranoReceivedCalled(
            operator,
            from,
            to,
            amount,
            userData,
            operatorData,
            address(token),
            fromBalance,
            toBalance
        );
    }

    function senderFor(address account) public {
        _registerInterfaceForAddress(TOKENS_SENDER_INTERFACE_HASH, account);

        address self = address(this);
        if (account == self) {
            registerSender(self);
        }
    }

    function registerSender(address sender) public {
        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_SENDER_INTERFACE_HASH,
            sender
        );
    }

    function recipientFor(address account) public {
        _registerInterfaceForAddress(TOKENS_RECIPIENT_INTERFACE_HASH, account);

        address self = address(this);
        if (account == self) {
            registerRecipient(self);
        }
    }

    function registerRecipient(address recipient) public {
        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            recipient
        );
    }

    function setShouldRevertSend(bool shouldRevert) public onlyOwner {
        _shouldRevertSend = shouldRevert;
    }

    function setShouldRevertReceive(bool shouldRevert) public onlyOwner {
        _shouldRevertReceive = shouldRevert;
    }

    function send(
        IERC777 token,
        address to,
        uint256 amount,
        bytes memory data
    ) public {
        // This is 777's send function, not the Solidity send function
        token.send(to, amount, data); // solhint-disable-line check-send-result
    }

    function burn(
        IERC777 token,
        uint256 amount,
        bytes memory data
    ) public {
        token.burn(amount, data);
    }

    // 777 END --------------------------------------------------------------------------------------------------
}