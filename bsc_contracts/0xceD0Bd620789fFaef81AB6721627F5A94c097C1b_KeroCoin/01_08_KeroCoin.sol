// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract KeroCoin is ERC20, Pausable, Ownable {
    using SafeMath for uint256;

    uint256 public _basisPoint = 0;
    address public _feeRecipient;

    event Fee(address indexed from, address indexed to, uint256 value);

    constructor() ERC20("KeroCoin", "KERO") {
        _mint(msg.sender, 500000000 * 10**decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function transfer(address _to, uint256 _value)
        public
        override
        whenNotPaused
        returns (bool)
    {
        require(_feeRecipient != address(0), "fee recipient not configured");

        uint256 fee = _calculateFee(_value);
        uint256 toSend = _value - fee;

        super.transfer(_feeRecipient, fee);
        emit Fee(msg.sender, _feeRecipient, toSend);

        return super.transfer(_to, toSend);
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        override
        whenNotPaused
        returns (bool)
    {
        require(_feeRecipient != address(0), "fee recipient not configured");

        uint256 fee = _calculateFee(_value);
        uint256 toSend = _value - fee;

        super.transferFrom(_from, _feeRecipient, fee);
        emit Fee(msg.sender, _feeRecipient, toSend);

        return super.transferFrom(_from, _to, toSend);
    }

    function _calculateFee(uint256 _amount) internal virtual returns (uint256) {
        uint256 fee = _amount.mul(_basisPoint).div(10000);
        return fee;
    }

    /* Only owner */
    function setBasisPoint(uint256 _newBasisPoint) public onlyOwner {
        require(_newBasisPoint > 0, "invalid basis point");
        _basisPoint = _newBasisPoint;
    }

    function setFeesRecipient(address _newFeeRecipient) public onlyOwner {
        require(_newFeeRecipient != address(0), "invalid fee recipient");
        _feeRecipient = _newFeeRecipient;
    }
}