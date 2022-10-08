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
    function orderFinal(uint _nfoId, uint _tokenId, bool _nfoTokenClaim) external {
        require(IERC721(NFOfinal).ownerOf(_tokenId) == msg.sender, "invalid final id");
        if (_nfoTokenClaim) {
            require(IERC20(NFOtoken).balanceOf(msg.sender) >= nfoPrice[_nfoId], "nfo balance too low");
            IERC20(NFOtoken).transferFrom(msg.sender, factoryWallet, nfoPrice[_nfoId]);
        } else {
            require(IERC20(stable).balanceOf(msg.sender) >= stablePrice[_nfoId], "stable balance too low");
            IERC20(stable).transferFrom(msg.sender, factoryWallet, stablePrice[_nfoId]);
        }
        emit PrintFinal(msg.sender, _nfoId);
    }

    // setters
    function setStable(address _newAddress) external onlyOwner {
        stable = _newAddress;
    }

    function setNfoToken(address _newAddress) external onlyOwner {
        NFOtoken = _newAddress;
    }

    function setFactoryWallet(address _newAddress) external onlyOwner {
        factoryWallet = _newAddress;
    }

    function setStablePrice(uint _id, uint _price) external onlyOwner {
        stablePrice[_id] = _price;
    }

    function setNfoPrice(uint _id, uint _price) external onlyOwner {
        nfoPrice[_id] = _price;
    }

    function setNfoFinal(address _newAddress) external onlyOwner {
        NFOfinal = _newAddress;
    }
}