// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "./forks/BoringBatchable.sol";

interface ScheduledTransfersFactory {
    function owner() external view returns (address);

    function oracle() external view returns (address);

    function token() external view returns (address);

    function maxPrice() external view returns (uint256);
}

error NOT_OWNER();
error NOT_ORACLE();
error NOT_OWNER_OR_WHITELISTED();
error INVALID_TIMESTAMP();
error FUTURE_TIMESTAMP();
error MAX_PRICE();
error STREAM_DOES_NOT_EXIST();
error INVALID_TOKEN();
error STREAM_ACTIVE();

contract ScheduledTransfers is ERC721, BoringBatchable {
    using SafeTransferLib for ERC20;

    struct Payment {
        uint32 lastPaid;
        uint32 ends;
        uint32 frequency;
        uint160 usdAmount;
    }

    string public constant baseURI = "https://nft.llamapay.io/scheduled/";
    address public oracle;
    address public owner;
    address public token;
    uint256 public nextTokenId;
    uint256 public maxPrice;

    mapping(uint256 => Payment) public payments;
    mapping(address => mapping(uint256 => address)) public redirects;

    event ScheduleTransfer(
        uint256 id,
        address to,
        uint160 usdAmount,
        uint32 starts,
        uint32 ends,
        uint32 frequency
    );
    event CancelTransfer(uint256 id);
    event BurnStream(uint256 id);
    event WithdrawPayer(address token, uint256 amount);
    event Withdraw(
        uint256 id,
        address to,
        uint256 owed,
        uint160 usdAmount,
        uint256 price,
        uint256 timestamp,
        uint256 lastPaid
    );
    event SetRedirect(address caller, uint256 id, address redirectTo);
    event ChangeOracle(address newOracle);
    event SetMaxPrice(uint256 newMaxprice);

    constructor() ERC721("LlamaPay V2 Scheduled Transfer", "LLAMAPAY") {
        oracle = ScheduledTransfersFactory(msg.sender).oracle();
        owner = ScheduledTransfersFactory(msg.sender).owner();
        token = ScheduledTransfersFactory(msg.sender).token();
        maxPrice = ScheduledTransfersFactory(msg.sender).maxPrice();
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NOT_OWNER();
        _;
    }

    function tokenURI(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (ownerOf(_id) == address(0)) revert STREAM_DOES_NOT_EXIST();
        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(block.chainid),
                    "/",
                    Strings.toHexString(uint160(address(this)), 20),
                    "/",
                    Strings.toString(_id)
                )
            );
    }

    function scheduleTransfer(
        address _to,
        uint160 _usdAmount,
        uint32 _starts,
        uint32 _ends,
        uint32 _frequency
    ) external onlyOwner {
        uint256 id = nextTokenId;
        _safeMint(_to, id);
        payments[id] = Payment({
            lastPaid: _starts,
            ends: _ends,
            frequency: _frequency,
            usdAmount: _usdAmount
        });
        unchecked {
            nextTokenId++;
        }
        emit ScheduleTransfer(id, _to, _usdAmount, _starts, _ends, _frequency);
    }

    function cancelTransfer(uint256 _id) external onlyOwner {
        if (ownerOf(_id) == address(0)) revert STREAM_DOES_NOT_EXIST();
        payments[_id].ends = uint32(block.timestamp);
        emit CancelTransfer(_id);
    }

    /// STILL EXERCISE CAUTION WHEN USING THIS FUNCTION
    function burnStream(uint256 _id) external {
        if (ownerOf(_id) != msg.sender) revert NOT_OWNER();
        if (
            payments[_id].ends >= block.timestamp ||
            payments[_id].ends != payments[_id].lastPaid
        ) revert STREAM_ACTIVE();
        _burn(_id);
        emit BurnStream(_id);
    }

    function withdrawPayer(address _token, uint256 _amount) external onlyOwner {
        ERC20(_token).safeTransfer(owner, _amount);
        emit WithdrawPayer(_token, _amount);
    }

    function withdraw(
        uint256[] calldata ids,
        address _token,
        uint256 _price,
        uint256 _timestamp
    ) external {
        if (_timestamp > block.timestamp) revert FUTURE_TIMESTAMP();
        if (msg.sender != oracle) revert NOT_ORACLE();
        if (_price > maxPrice) revert MAX_PRICE();
        if (token != _token) revert INVALID_TOKEN();
        uint256 i = 0;
        uint256 length = ids.length;
        while (i < length) {
            _withdraw(ids[i], _price, _timestamp);
            unchecked {
                i++;
            }
        }
    }

    function _withdraw(
        uint256 _id,
        uint256 _price,
        uint256 _timestamp
    ) private {
        Payment storage payment = payments[_id];
        if (ownerOf(_id) == address(0)) revert STREAM_DOES_NOT_EXIST();
        if (_timestamp > payment.ends) revert INVALID_TIMESTAMP();
        uint256 updatedTimestamp;
        unchecked {
            // cant overflow because these two are uint32
            updatedTimestamp =
                uint256(payment.lastPaid) +
                uint256(payment.frequency);
        }
        if (_timestamp > updatedTimestamp) revert INVALID_TIMESTAMP();
        uint256 owed = (_timestamp - uint256(payment.lastPaid)) *
            uint256(payment.usdAmount) *
            _price;
        unchecked {
            owed = owed / (uint256(payment.frequency) * 1e18);
        }
        payments[_id].lastPaid = uint32(_timestamp); // _timestamp < block.timestamp, so it will fit into uint32 until 2106
        address to;
        address nftOwner = ownerOf(_id);
        address redirect = redirects[nftOwner][_id];
        if (redirect == address(0)) {
            to = nftOwner;
        } else {
            to = redirect;
        }
        ERC20(token).safeTransfer(to, owed);
        emit Withdraw(
            _id,
            to,
            owed,
            payment.usdAmount,
            _price,
            _timestamp,
            _timestamp
        );
    }

    function setRedirect(uint256 _id, address _redirectTo) external {
        if (msg.sender != ownerOf(_id)) revert NOT_OWNER();
        redirects[msg.sender][_id] = _redirectTo;
        emit SetRedirect(msg.sender, _id, _redirectTo);
    }

    function changeOracle(address newOracle) external onlyOwner {
        oracle = newOracle;
        emit ChangeOracle(newOracle);
    }

    function setMaxPrice(uint256 newMaxPrice) external onlyOwner {
        maxPrice = newMaxPrice;
        emit SetMaxPrice(newMaxPrice);
    }
}