// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@layerzerolabs/solidity-examples/contracts/token/oft/extension/BasedOFT.sol";

import {Minter} from "./Minter.sol";

contract Stone is BasedOFT {
    uint256 public constant DAY_INTERVAL = 24 * 60 * 60;

    address public minter;

    uint16 public constant PT_FEED = 1;
    uint16 public constant PT_SET_ENABLE = 2;
    uint16 public constant PT_SET_CAP = 3;

    uint256 public cap;
    bool public enable = true;

    mapping(uint256 => uint256) public quota;

    event FeedToChain(
        uint16 indexed dstChainId,
        address indexed from,
        bytes toAddress,
        uint price
    );
    event SetCapFor(uint16 indexed dstChainId, bytes toAddress, uint cap);
    event SetEnableFor(uint16 indexed dstChainId, bytes toAddress, bool flag);

    constructor(
        address _minter,
        address _layerZeroEndpoint,
        uint256 _cap
    ) BasedOFT("StakeStone Ether", "STONE", _layerZeroEndpoint) {
        minter = _minter;
        cap = _cap;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "NM");
        _;
    }

    function mint(address _to, uint256 _amount) external onlyMinter {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyMinter {
        _burn(_from, _amount);
    }

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) public payable override(IOFTCore, OFTCore) {
        require(enable, "invalid");

        uint256 id;
        assembly {
            id := chainid()
        }
        require(id != _dstChainId, "same chain");

        uint256 day = block.timestamp / DAY_INTERVAL;
        require(_amount + quota[day] <= cap, "Exceed cap");

        quota[day] = quota[day] + _amount;

        super.sendFrom(
            _from,
            _dstChainId,
            _toAddress,
            _amount,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    function updatePrice(
        uint16 _dstChainId,
        bytes memory _toAddress
    ) external payable returns (uint256 price) {
        require(enable, "invalid");

        uint256 id;
        assembly {
            id := chainid()
        }
        require(id != _dstChainId, "same chain");

        price = tokenPrice();

        bytes memory lzPayload = abi.encode(
            PT_FEED,
            _toAddress,
            price,
            block.timestamp
        );

        _lzSend(
            _dstChainId,
            lzPayload,
            payable(msg.sender),
            address(0),
            bytes(""),
            msg.value
        );

        emit FeedToChain(_dstChainId, msg.sender, _toAddress, price);
    }

    function setEnableFor(
        uint16 _dstChainId,
        bool _flag,
        bytes memory _toAddress
    ) external payable onlyOwner {
        uint256 id;
        assembly {
            id := chainid()
        }

        if (_dstChainId == id) {
            enable = _flag;

            emit SetEnableFor(
                _dstChainId,
                abi.encodePacked(address(this)),
                enable
            );
            return;
        }

        bytes memory lzPayload = abi.encode(PT_SET_ENABLE, _toAddress, _flag);
        _lzSend(
            _dstChainId,
            lzPayload,
            payable(msg.sender),
            address(0),
            bytes(""),
            msg.value
        );

        emit SetEnableFor(_dstChainId, _toAddress, _flag);
    }

    function setCapFor(
        uint16 _dstChainId,
        uint256 _cap,
        bytes memory _toAddress
    ) external payable onlyOwner {
        uint256 id;
        assembly {
            id := chainid()
        }

        if (_dstChainId == id) {
            cap = _cap;

            emit SetCapFor(_dstChainId, abi.encodePacked(address(this)), cap);
            return;
        }

        bytes memory lzPayload = abi.encode(PT_SET_CAP, _toAddress, _cap);
        _lzSend(
            _dstChainId,
            lzPayload,
            payable(msg.sender),
            address(0),
            bytes(""),
            msg.value
        );

        emit SetCapFor(_dstChainId, _toAddress, _cap);
    }

    function tokenPrice() public returns (uint256 price) {
        price = Minter(minter).getTokenPrice();
    }

    function getQuota() external view returns (uint256) {
        uint256 amount = quota[block.timestamp / DAY_INTERVAL];
        if (cap > amount && enable) {
            return cap - amount;
        }
    }
}