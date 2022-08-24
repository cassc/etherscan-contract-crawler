// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IXToken {
    function mint(address _to, uint256 _amount) external;

    function balanceOf(address account) external view returns (uint256);
}

contract Wallet is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TokenConfig {
        bool enable;
        bool own;
        uint256 minAmount;
    }

    struct Inlog {
        uint64 id;
        address from;
        address token;
        uint256 amount;
        string memo;
        uint256 blockNumber;
        uint256 timestamp;
    }

    struct Outlog {
        uint64 id;
        uint256 blockNumber;
        uint256 timestamp;
    }

    address public admin;
    mapping(address => TokenConfig) public tokenConfigs;

    uint64 public currentInlogId;
    mapping(uint64 => Inlog) private _inlogs;
    mapping(uint64 => Outlog) private _outlogs;

    constructor(address _admin, uint64 _inlogId) {
        admin = _admin;
        currentInlogId = _inlogId;
    }

    receive() external payable {}

    function _check(address _token, uint256 _amount) private view {
        require(_amount > 0, "Wallet: invalid amount");

        TokenConfig memory _conf = tokenConfigs[_token];
        require(_conf.enable, "Wallet: token is not enable");

        if (_conf.minAmount > 0) {
            require(_amount >= _conf.minAmount, "Wallet: less than min amount");
        }
    }

    function getMessageHash(
        uint64 _id,
        address _token,
        address _to,
        uint256 _amount,
        uint256 _expiration
    ) private pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(_id, _token, _to, _amount, _expiration));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }

    function regToken(address _token, TokenConfig memory _config)
        public
        onlyOwner
    {
        tokenConfigs[_token] = _config;
    }

    function setInlogId(uint64 _inlogId) public onlyOwner {
        currentInlogId = _inlogId;
    }

    function getInlog(uint64 _id) public view returns (Inlog memory) {
        return _inlogs[_id];
    }

    function getInlogs(uint64 _fromId, uint64 _limit)
        public
        view
        returns (Inlog[] memory)
    {
        if (_limit == 0 || _fromId > currentInlogId) {
            return new Inlog[](0);
        }

        if (_fromId + _limit > currentInlogId + 1) {
            _limit = currentInlogId + 1 - _fromId;
        }

        Inlog[] memory _records = new Inlog[](_limit);
        for (uint64 _i = _fromId; _i < _fromId + _limit; _i++) {
            _records[_i - _fromId] = getInlog(_i);
        }

        return _records;
    }

    function getOutlog(uint64 _id) public view returns (Outlog memory) {
        return _outlogs[_id];
    }

    function deposit(
        address _token,
        uint256 _amount,
        string memory _memo
    ) public payable whenNotPaused nonReentrant {
        _check(_token, _amount);

        currentInlogId++;
        _inlogs[currentInlogId] = Inlog({
            id: currentInlogId,
            from: msg.sender,
            token: _token,
            amount: _amount,
            memo: _memo,
            blockNumber: block.number,
            timestamp: block.timestamp
        });

        // base token
        if (_token == address(0)) {
            require(_amount == msg.value, "Wallet: amount not equal value");
            (payable(address(this))).transfer(_amount);
        } else {
            // ERC20 token
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    function withdraw(
        uint64 _id,
        address _token,
        address payable _to,
        uint256 _amount,
        uint256 _expiration,
        bytes memory _signature
    ) public whenNotPaused nonReentrant {
        require(_expiration > block.timestamp, "withdraw expired");

        bytes32 hash = getMessageHash(_id, _token, _to, _amount, _expiration);
        bytes32 ethhash = getEthSignedMessageHash(hash);
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        require(ecrecover(ethhash, v, r, s) == admin, "no auth withdraw");

        Outlog memory log = _outlogs[_id];
        require(log.id == 0, "already withdrawn");

        _outlogs[_id] = Outlog({
            id: _id,
            blockNumber: block.number,
            timestamp: block.timestamp
        });

        if (_token == address(0)) {
            _to.transfer(_amount);
        } else {
            TokenConfig memory _conf = tokenConfigs[_token];
            if (_conf.own) {
                uint256 balance = IXToken(_token).balanceOf(address(this));
                if (balance < _amount) {
                    IXToken(_token).mint(address(this), _amount - balance);
                }
            }
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    // withdraw tokens that are sent here by mistake
    function ownerWithdraw(
        address _token,
        address payable _to,
        uint256 _amount
    ) public onlyOwner {
        if (_token == address(0)) {
            _to.transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }
}