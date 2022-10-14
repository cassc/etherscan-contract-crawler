// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Claim is Ownable {
    using SafeERC20 for IERC20;

    event Claimed(address indexed token, address indexed from, address indexed to, uint256 value);

    function getAvailableToClaim(address _token) external view returns(uint256) {
        return _availableToClaim(_token);
    }

    function getAvailableToClaimFrom(address _token, address _from) external view returns(uint256) {
        return IERC20(_token).allowance(_from, address(this));
    }

    function claimToken(address _token) external onlyOwner {
        _claimToken(_token);
    }

    function claimBatchToken(address[] memory _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            _claimToken(_tokens[i]);
        }
    }

    function claimTokenFrom(address _token, address _from, uint256 _amount) external onlyOwner {
        _claimTokenFrom(_token, _from, _amount);
    }

    function _availableToClaim(address _token) internal view returns(uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function _claimToken(address _token) internal {
        uint256 amount = _availableToClaim(_token);
        IERC20(_token).safeTransfer(msg.sender, amount);
        emit Claimed(_token, address(this), msg.sender, amount);
    }

    function _claimTokenFrom(address _token, address _from, uint256 _amount) internal {
        IERC20(_token).safeTransferFrom(_from, msg.sender, _amount);
        emit Claimed(_token, address(this), msg.sender, _amount);
    }
}