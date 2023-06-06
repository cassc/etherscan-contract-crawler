// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Transfer is Ownable {
    using SafeERC20 for IERC20;

    struct Opening {
        string hackathonId;
        address from;
        uint256[3] prizeAmounts;
        uint256 feeAmount;
        string denomination;
        string executedAt;
    }

    struct Closing {
        string hackathonId;
        address from;
        uint256[3] prizeAmounts;
        uint256 feeAmount;
        string denomination;
        address[3] tos;
        address feeTo;
        string executedAt;
    }

    mapping(string => Opening) private _openings;
    string[] private _openingKeys;
    mapping(string => Closing) private _closings;
    string[] private _closingKeys;

    function openHackathon(
        string memory _hackathonId,
        uint256[3] memory _prizeAmounts,
        uint256 _feeAmount,
        string memory _denomination,
        string memory _executedAt
    ) external {
        require(
            keccak256(bytes(_hackathonId)) != keccak256(bytes("")),
            "hackathon id is empty."
        );
        require(_feeAmount != 0, "fee amount must be more than 0.");
        require(
            _isValidDenomination(_denomination),
            "denomination should be USDC or USDT."
        );
        require(
            keccak256(bytes(_executedAt)) != keccak256(bytes("")),
            "executed at is empty."
        );

        require(
            !_existsInOpenings(_hackathonId),
            "this hackathon is already open."
        );

        _openings[_hackathonId] = Opening(
            _hackathonId,
            msg.sender,
            _prizeAmounts,
            _feeAmount,
            _denomination,
            _executedAt
        );
        _openingKeys.push(_hackathonId);
    }

    function getOpening(string memory _hackathonId)
        public
        view
        returns (Opening memory)
    {
        require(
            _existsInOpenings(_hackathonId),
            "the hackathon doesn't exist."
        );
        return _openings[_hackathonId];
    }

    function getOpenings(uint256 _limit, uint256 _offset)
        external
        view
        returns (Opening[] memory)
    {
        uint256 _len = _openingKeys.length;
        require(_offset <= _len, "offset must be less than opening length.");

        if (_len < _offset + _limit) {
            _limit = _len - _offset;
        }

        Opening[] memory ret = new Opening[](_limit);
        for (uint256 i; i < _limit; ) {
            ret[i] = _openings[_openingKeys[_offset + i]];
            unchecked {
                ++i;
            }
        }
        return ret;
    }

    function closeHackathon(
        string memory _hackathonId,
        address[3] memory _tos,
        string memory _executedAt
    ) external {
        require(
            keccak256(bytes(_hackathonId)) != keccak256(bytes("")),
            "hackathon id is empty."
        );

        require(
            canBeClosed(_hackathonId, msg.sender),
            "this hackathon cannot be closed."
        );

        Opening memory _opening = _openings[_hackathonId];
        uint256[3] memory _amounts = _opening.prizeAmounts;

        require(_isValidTos(_tos, _amounts), "invalid tos");
        require(
            keccak256(bytes(_executedAt)) != keccak256(bytes("")),
            "executed at is empty."
        );

        string memory _denomination = _opening.denomination;

        for (uint256 i = 0; i < 3; i++) {
            if (_tos[i] != address(0)) {
                _transfer(_tos[i], _amounts[i], _denomination);
            }
        }
        _transfer(owner(), _opening.feeAmount, _denomination);

        _closings[_hackathonId] = Closing(
            _hackathonId,
            msg.sender,
            _amounts,
            _opening.feeAmount,
            _denomination,
            _tos,
            owner(),
            _executedAt
        );
        _closingKeys.push(_hackathonId);
    }

    function getClosing(string memory _hackathonId)
        external
        view
        returns (Closing memory)
    {
        require(
            _existsInClosings(_hackathonId),
            "the hackathon doesn't exist."
        );
        return _closings[_hackathonId];
    }

    function getClosings(uint256 _limit, uint256 _offset)
        external
        view
        returns (Closing[] memory)
    {
        uint256 _len = _closingKeys.length;
        require(_offset <= _len, "offset must be less than closing length.");

        if (_len < _offset + _limit) {
            _limit = _len - _offset;
        }

        Closing[] memory ret = new Closing[](_limit);
        for (uint256 i; i < _limit; ) {
            ret[i] = _closings[_closingKeys[_offset + i]];
            unchecked {
                ++i;
            }
        }
        return ret;
    }

    function canBeClosed(string memory _hackathonId, address _address)
        public
        view
        returns (bool)
    {
        return
            _isOrganizer(_hackathonId, _address) &&
            _existsInOpenings(_hackathonId) &&
            !_existsInClosings(_hackathonId);
    }

    // -------------- private functions --------------

    function _isValidDenomination(string memory _denomination)
        private
        pure
        returns (bool)
    {
        return
            keccak256(bytes(_denomination)) == keccak256(bytes("USDC")) ||
            keccak256(bytes(_denomination)) == keccak256(bytes("USDT"));
    }

    function _existsInOpenings(string memory _hackathonId)
        private
        view
        returns (bool)
    {
        Opening memory _opening = _openings[_hackathonId];
        return _opening.from != address(0);
    }

    function _existsInClosings(string memory _hackathonId)
        private
        view
        returns (bool)
    {
        Closing memory _closing = _closings[_hackathonId];
        return _closing.from != address(0);
    }

    function _isOrganizer(string memory _hackathonId, address _address)
        private
        view
        returns (bool)
    {
        Opening memory _opening = _openings[_hackathonId];
        return _address == _opening.from;
    }

    function _isValidTos(address[3] memory _tos, uint256[3] memory _amounts)
        private
        pure
        returns (bool)
    {
        if (_tos[0] == address(0)) {
            return false;
        }
        for (uint256 i = 1; i < 3; ) {
            if (
                (_amounts[i] == 0 && _tos[i] != address(0)) ||
                (_amounts[i] != 0 && _tos[i] == address(0))
            ) {
                return false;
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }

    function _transfer(
        address _to,
        uint256 _amount,
        string memory _denomination
    ) private {
        address usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

        address usingAddress = usdcAddress;
        if (keccak256(bytes(_denomination)) == keccak256(bytes("USDT"))) {
            usingAddress = usdtAddress;
        }

        IERC20 token = IERC20(address(usingAddress));
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _amount, "invalid amount.");
        token.safeTransferFrom(msg.sender, _to, _amount);
    }
}