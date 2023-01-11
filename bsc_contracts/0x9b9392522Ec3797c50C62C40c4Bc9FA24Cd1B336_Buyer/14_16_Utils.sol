// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../security/Administered.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Utils is Administered {
    /// @dev SafeMath library
    using SafeMath for uint256;

    /// @dev event
    event LogDepositReceived(address _address, uint256 amount);

    address public apocalypse;

    constructor(address _apocalypse) {
        apocalypse = _apocalypse; ///  @dev  wallet que puede destruir el contrato
    }

    /**
     * @dev selfdestruct
     * apocalypse: address to send the remaining balance
     */
    function destroy() public {
        require(
            apocalypse == _msgSender(),
            "only the apocalypse can call this"
        );
        selfdestruct(payable(apocalypse));
    }

    /**
     * @dev fallback
     * will keep all the Ether sent to this contract
     */
    fallback() external payable {
        emit LogDepositReceived(_msgSender(), msg.value);
    }

    /**
     * @dev receive
     * will keep all the Ether sent to this contract
     */
    receive() external payable {
        emit LogDepositReceived(_msgSender(), msg.value);
    }

    /**
     * @dev get balance
     */
    function getBalanceContract() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev  Withdrawal eth
     */
    function withdrawEth(uint256 _amount) public onlyAdmin {
        require(_amount <= getBalanceContract(), "insufficient funds");
        payable(_msgSender()).transfer(_amount);
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
}