// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../security/Administered.sol";

contract TransactionFee is Administered {
    // @dev SafeMath library
    using SafeMath for uint256;

    // @dev fee per transaction
    address public a1 = 0xb0254eff10137c3a3bbf8ad21161652f1fbc299B;
    address public a2 = 0xc8bD344C3206Ba9aB6451360d114BEc50C74BDAA;

    /// @dev fee per transaction
    uint256 public _fbpa1 = 270; // 2.7%
    uint256 public _fbpa2 = 30; // 0.3%
    uint256 public seller = 0; // 0%

    address public _addressOracle = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    uint256 public _addressDecimalOracle = 10;
    bool public _isActive = true;

    /**
     * set setting
     */
    function setting(
        uint _type,
        bool _bool,
        address _addrs,
        uint256 _uint
    ) public onlyAdmin {
        if (_type == 1) {
            _isActive = _bool;
        } else if (_type == 2) {
            _addressOracle = _addrs;
        } else if (_type == 2) {
            _addressDecimalOracle = _uint;
        }
    }

    /**
     * @dev Returns the fee per transaction
     */
    function calculateFee(
        uint256 _amount,
        uint256 _fbp
    ) public pure returns (uint256) {
        return (_amount * _fbp) / 10000;
    }

    /**
     * get  full seller
     */
    function getFullSeller() public view returns (uint256) {
        return 10000 - (_fbpa1 + _fbpa2);
    }

    /**
     * @dev set address for fee
     */

    function setAddress(uint256 _type, address _newAddress) public onlyAdmin {
        if (_type == 1) {
            a1 = _newAddress;
        }
        if (_type == 2) {
            a2 = _newAddress;
        }
    }

    /**
     * @dev set fee per transaction
     */
    function setFee(uint256 _type, uint256 _newFee) public onlyAdmin {
        if (_type == 1) {
            _fbpa1 = _newFee;
        }
        if (_type == 2) {
            _fbpa2 = _newFee;
        }
    }
}