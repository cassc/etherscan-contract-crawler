// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClaimFeePaymentContract is Ownable {

    uint public fee;
    address public reveneuAddress;

    struct Proof {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event FeeChange(uint _fee);
    event ReveneuAddressChange(address _reveneuAddress);
    event DistributeRewards(address sender, address[] _addresses, uint[] _amounts, address _tokenAddress);
    event FeePaid(address sender, uint fee);

    constructor(uint _fee, address _reveneuAddress) {
        fee = _fee;
        reveneuAddress = _reveneuAddress;
    }

    function setFee(uint _fee) onlyOwner public {
        require(fee != _fee, "fees are the same");
        fee = _fee;

        emit FeeChange(fee);
    }

    function setReveneueAddress(address _address) onlyOwner public {
        require(_address != reveneuAddress, "same address");
        reveneuAddress = _address;
        emit ReveneuAddressChange(reveneuAddress);
    }

    function calculateFee(uint _amount) internal view returns (uint) {
        return _amount * fee / 100000000000000000000;
    }

    function verifyProof(address _scholar, uint _amount, Proof memory _proof )
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(abi.encodePacked(
            address(this),
            msg.sender,
            _amount,
            _scholar
        ));
        address signatory = ecrecover(hash, _proof.v, _proof.r, _proof.s);
        return signatory == _scholar;
    }

    function distributeRewards(address _tokenAddress, address[] memory _addresses, uint[] memory _amounts, Proof[] memory _proofs) public {
        require(_addresses.length == _amounts.length, "_addresses and _amounts has to be the same length");
        require(_addresses.length == _proofs.length, "_addresses and _proofs has to be the same length");

        for (uint i = 0; i < _addresses.length; i++) {
          require(verifyProof(_addresses[i], _amounts[i], _proofs[i]), "invalid signature");

          uint currentFee = calculateFee(_amounts[i]);
          uint amount = _amounts[i] - currentFee;

          IERC20(_tokenAddress).transferFrom(_addresses[i], reveneuAddress, currentFee);
          IERC20(_tokenAddress).transferFrom(_addresses[i], msg.sender, amount);
        }

        emit DistributeRewards(msg.sender, _addresses, _amounts, _tokenAddress);
        emit FeePaid(msg.sender, fee);
    }
}