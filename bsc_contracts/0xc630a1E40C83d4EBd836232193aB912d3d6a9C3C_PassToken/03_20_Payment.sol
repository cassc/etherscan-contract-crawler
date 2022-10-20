// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Payment is Ownable {
    uint256 public constant DFAULT_DECIMAL = 1e18;
    address public recipient;

    mapping(address => uint256) internal prices;

    modifier CheckAmount(uint256 amount) {
        require(amount > 0, "Invalid Amount");
        _;
    }

    modifier CheckPayment(address _payToken) {
        require(prices[_payToken] > 0, "Invalid PayToken");
        _;
    }

    constructor(address _recipient) {
        recipient = _recipient;
    }

    /**
     * @notice transfer token based on toke type: ERC20 or Native
     * @param _to token receiver
     * @param _value amount for transfer
     * @param _payToken payment token, address(0) means native token, otherwise ERC20
     */
    function transToken(
        address _to,
        uint256 _value,
        address _payToken
    ) internal {
        if (_payToken != address(0)) {
            IERC20(_payToken).transfer(_to, _value);
        } else {
            payable(_to).transfer(_value);
        }
    }

    /**
     * @dev payment setting
     * @param _price minimum price for payed
     * @param _payToken currency for payment
     */
    function setPayTokenAndPrice(
        uint256[] memory _price,
        address[] memory _payToken
    ) external onlyOwner {
        require(_price.length == _payToken.length, "Invalid Params");
        for (uint256 i = 0; i < _price.length; i++) {
            require(_price[i] > 0, "Invalid Price");
            prices[_payToken[i]] = _price[i];
        }
    }

    /**
     * @dev delete payment setting
     * @param _payToken currency for payment
     */
    function delPayTokenAndPrice(address[] memory _payToken)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _payToken.length; i++) {
            delete prices[_payToken[i]];
        }
    }

    function getPrice(address _tokenAddr) external view returns (uint256) {
        return prices[_tokenAddr];
    }
}