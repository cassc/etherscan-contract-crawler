pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


abstract contract ERC20Handler{
    using SafeERC20 for IERC20;
    function _deriveERC20Signers(
        address _token,
        string memory _txHash,
        uint256 _amount,
        bytes32[] memory _r,
        bytes32[] memory _s,
        uint8[] memory _v
    ) internal view returns (address[] memory) {
        bytes32 _hash = keccak256(abi.encodePacked(block.chainid, _token, msg.sender, _txHash, _amount));
        address[] memory _signers = new address[](_r.length);
        for (uint8 i = 0; i < _r.length; i++) {
            _signers[i] = ecrecover(_hash, _v[i], _r[i], _s[i]);
        }

        return _signers;
    }

    function _sendERC20(
        address _token,
        address _receiver,
        uint256 _amount
    ) internal {
       IERC20(_token).safeTransfer(_receiver, _amount);
    }
}