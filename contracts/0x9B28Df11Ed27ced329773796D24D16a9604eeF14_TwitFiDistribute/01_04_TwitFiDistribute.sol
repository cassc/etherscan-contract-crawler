// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TwitFiDistribute {
    address private _owner;

	  constructor() {
        _owner = msg.sender;
    }

    function setOwner(address _newOwner) public onlyOwner {
        _owner = _newOwner;
    }

    function transfer(address _token, address payable _to, uint _amount) public onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "INSUFFICIENT_BALANCE");
        IERC20(_token).transfer(_to, _amount);
    }

    function assetTransfer(address[] memory _nfts, address[] memory _tos, uint256[] memory _tokenIds) public onlyOwner {
        uint8 i;
        for (i = 0; i < _tos.length; i++) {
          IERC721(address(_nfts[i])).safeTransferFrom(address(this), _tos[i], _tokenIds[i]);
        }
    }

    function distribute(address [] memory _receivers, uint256[] memory _amounts) payable public {
        uint8 i;
        for (i = 0; i < _receivers.length; i++) {
          payable(_receivers[i]).transfer(_amounts[i]);
        }
    }

    function withdraw(address payable _to, uint _amount) public onlyOwner {
        uint amount = address(this).balance;
        require(amount >= _amount, "Insufficient balance");
        (bool success, ) = _to.call {
            value: _amount
        }("");

        require(success, "Failed to send balance");
    }

	  modifier onlyOwner {
        require(msg.sender == _owner, "UNAUTHORIZED");
        _;
    }

    receive() external payable {}
}