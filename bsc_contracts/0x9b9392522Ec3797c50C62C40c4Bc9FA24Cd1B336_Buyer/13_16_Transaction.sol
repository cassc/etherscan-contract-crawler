// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../security/Administered.sol";

contract Transaction is Administered {
    // @dev SafeMath library
    using SafeMath for uint256;

    // @dev fee per transaction
    address public a1 = 0x4C54d42aB8a14E0142df679a075E4C4dE767d8D0;
    address public a2 = 0x78303360ec1ACA06F195f48F75D6D59107810Dff;
    address public a3 = 0xd5DE05A2C95e0fF94988F7b8775A1F899309c062;

    /// @dev fee per transaction
    uint256 public _fbpa1 = 270; // 2.7%
    uint256 public _fbpa2 = 30; // 0.3%
    uint256 public seller = 0; // 0%

   

    /**
     * @dev get  full seller
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
        } else if (_type == 2) {
            a2 = _newAddress;
        } else if (_type == 3) {
            a3 = _newAddress;
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