// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AdvisorsVesting {

    uint256 immutable private tokens;
    address immutable private icomToken;
    address immutable private owner;

    uint256 constant private FIRST_STEP = 500000000000000000;
    uint256 constant private SECOND_STEP = 750000000000000000;
    uint256 constant private THIRD_STEP = 1000000000000000000;

    address[8] private advisorsWallet;
    uint16[8] private percentages;
    uint48 public maxVestingDate;
    bool[3] private unlockedTranche;

    event advisorTokensSent(uint256 _amount);

    constructor(address _icomToken, address[] memory _advisorsWallet, uint16[] memory _percentages, uint256 _tokens, uint48 _maxVestingDate) {
        icomToken = _icomToken;
        tokens = _tokens;
        maxVestingDate = _maxVestingDate;
        owner = msg.sender;

        for (uint256 i=0; i< _advisorsWallet.length; i++) {
            advisorsWallet[i] = _advisorsWallet[i];
            percentages[i] = _percentages[i];
        }
    }

    function withdrawTokens(bytes calldata _params, bytes calldata _messageLength, bytes calldata _signature) external {
        uint256 unlockPercentage = _checkPrice(_params, _messageLength, _signature);
        require(block.timestamp >= maxVestingDate || unlockPercentage > 0, "CantWithdrawYet");

        if (block.timestamp >= maxVestingDate) {
            uint256 balance = IERC20(icomToken).balanceOf(address(this));
            _sendTokens(balance);
        } else {
            uint256 amount = tokens * unlockPercentage / 100;
            _sendTokens(amount);
        }
    }

    function recoverAllTokens() external {
        require(msg.sender == owner, "BadOwner");

        uint256 balance = IERC20(icomToken).balanceOf(address(this));
        IERC20(icomToken).transfer(owner, balance);
    }

    function _checkPrice(bytes calldata _params, bytes calldata _messageLength, bytes calldata _signature) internal returns(uint256) {
        address _signer = _decodeSignature(_params, _messageLength, _signature);
        require(_signer == owner, "BadSigner");
    
        (, uint256 _price) = abi.decode(_params, (uint256, uint256));
        return _unlockedPercentage(_price);
    }

    function _unlockedPercentage(uint256 _price) internal returns(uint256) {
        uint256 percentage = 0;
        if ((_price >= FIRST_STEP) && (unlockedTranche[0] == false)) {
            percentage += 35;
            unlockedTranche[0] = true;
        } else if ((_price >= SECOND_STEP) && (unlockedTranche[1] == false)) {
            percentage += 35;
            unlockedTranche[1] = true;
        } else if ((_price >= THIRD_STEP) && (unlockedTranche[2] == false)) {
            percentage += 30;
            unlockedTranche[2] = true;
        }

        return percentage;
    }

    function _sendTokens(uint256 _amount) internal {
        for (uint256 i = 0; i< advisorsWallet.length; i++) {
            IERC20(icomToken).transfer(advisorsWallet[i], _amount * percentages[i] / 1000);
        }
        
        emit advisorTokensSent(_amount);
    }

    function _decodeSignature(bytes memory _message, bytes memory _messageLength, bytes memory _signature) internal pure returns (address) {
        if (_signature.length != 65) return (address(0));

        bytes32 messageHash = keccak256(abi.encodePacked(hex"19457468657265756d205369676e6564204d6573736167653a0a", _messageLength, _message));
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return address(0);

        if (v != 27 && v != 28) return address(0);
        
        return ecrecover(messageHash, v, r, s);
    }
}