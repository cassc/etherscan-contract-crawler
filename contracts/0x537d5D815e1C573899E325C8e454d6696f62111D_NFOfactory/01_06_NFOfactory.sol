// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFOfactory is Ownable {

    event PrintFinal(address _address, uint _id);

    address public stable;
    address public NFOtoken;
    address public NFOfinal;
    address public factoryWallet;
    mapping (uint => uint) public stablePrice;
    mapping (uint => uint) public nfoPrice;

    constructor(address _stable, address _nfoToken, address _nfoFinal) {
        stable = _stable;
        NFOtoken = _nfoToken;
        NFOfinal = _nfoFinal;
        factoryWallet = msg.sender;
    }


    // factory orders
    function orderFinal(uint _id, bool _nfoTokenClaim) public {
        require(IERC721(NFOfinal).ownerOf(_id) == msg.sender, "invalid final id");
        if (_nfoTokenClaim) {
            require(IERC20(NFOtoken).balanceOf(msg.sender) >= nfoPrice[_id], "balance too low");
            IERC20(NFOtoken).transferFrom(msg.sender, factoryWallet, nfoPrice[_id]);
        } else {
            require(IERC20(stable).balanceOf(msg.sender) >= stablePrice[_id], "balance too low");
            IERC20(stable).transferFrom(msg.sender, factoryWallet, stablePrice[_id]);
        }
        emit PrintFinal(msg.sender, _id);
    }

    // setters
    function setStable(address _newAddress) public onlyOwner {
        stable = _newAddress;
    }

    function setNfoToken(address _newAddress) public onlyOwner {
        NFOtoken = _newAddress;
    }

    function setFactoryWallet(address _newAddress) public onlyOwner {
        factoryWallet = _newAddress;
    }

    function setStablePrice(uint _id, uint _price) public onlyOwner {
        stablePrice[_id] = _price;
    }

    function setNfoPrice(uint _id, uint _price) public onlyOwner {
        nfoPrice[_id] = _price;
    }
}