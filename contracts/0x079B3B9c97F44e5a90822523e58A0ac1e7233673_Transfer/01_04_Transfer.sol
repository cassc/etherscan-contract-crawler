// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Transfer is Ownable {
    struct Opening {
        string hackathonId;
        uint256 amount;
        string denomination;
        address from;
        address to;
        string executedAt;
    }

    struct Closing {
        string hackathonId;
        uint256 amount;
        string denomination;
        address from;
        address to;
        string executedAt;
    }

    mapping(string => Opening) private _openings;
    string[] private _openingKeys;
    mapping(string => Closing) private _closings;
    string[] private _closingKeys;

    function openHackathon(
        string memory _hackathonId,
        uint256 _amount,
        string memory _denomination,
        string memory _executedAt
    ) public {
        require(
            keccak256(bytes(_hackathonId)) != keccak256(bytes("")),
            "hackathon id is empty."
        );
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

        _transfer(owner(), _amount, _denomination);

        _openings[_hackathonId] = Opening(
            _hackathonId,
            _amount,
            _denomination,
            msg.sender,
            owner(),
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

    function getOpenings() public view returns (Opening[] memory) {
        Opening[] memory ret = new Opening[](_openingKeys.length);
        for (uint256 i = 0; i < _openingKeys.length; i++) {
            ret[i] = _openings[_openingKeys[i]];
        }
        return ret;
    }

    function closeHackathon(
        string memory _hackathonId,
        uint256 _amount,
        string memory _denomination,
        address _to,
        string memory _executedAt
    ) public {
        require(
            _isOrganizer(_hackathonId, msg.sender),
            "only organizer can close hackathon."
        );

        require(
            keccak256(bytes(_hackathonId)) != keccak256(bytes("")),
            "hackathon id is empty."
        );
        require(
            _isValidDenomination(_denomination),
            "denomination should be USDC or USDT."
        );
        require(_to != address(0), "address is empty.");
        require(
            keccak256(bytes(_executedAt)) != keccak256(bytes("")),
            "executed at is empty."
        );

        require(_existsInOpenings(_hackathonId), "this hackathon isn't open.");
        require(
            !_existsInClosings(_hackathonId),
            "this hackathon is already closed."
        );

        _transfer(_to, _amount, _denomination);

        _closings[_hackathonId] = Closing(
            _hackathonId,
            _amount,
            _denomination,
            msg.sender,
            _to,
            _executedAt
        );
        _closingKeys.push(_hackathonId);
    }

    function getClosing(string memory _hackathonId)
        public
        view
        returns (Closing memory)
    {
        require(
            _existsInClosings(_hackathonId),
            "the hackathon doesn't exist."
        );
        return _closings[_hackathonId];
    }

    function getClosings() public view returns (Closing[] memory) {
        Closing[] memory ret = new Closing[](_closingKeys.length);
        for (uint256 i = 0; i < _closingKeys.length; i++) {
            ret[i] = _closings[_closingKeys[i]];
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
        token.transferFrom(msg.sender, _to, _amount);
    }
}