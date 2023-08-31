// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IERC721 {
    function ownerOf(uint tokenId) external view virtual returns (address);

    function mint(address to, uint quantity) external virtual;

    function claim(bytes calldata sig, uint tokenId, uint nonce) external virtual;

    function claimed(uint tokenId) external view virtual returns (bool);
}

contract Claimer is Ownable {
    IERC721 public wlPass;
    IERC20 public erc20;

    address public withdrawAddress;
    address public devAddress;
    uint public price;
    bool public claimStarted;
    mapping(uint => string) public reservations;
    mapping(uint => bool) public isReserved;

    constructor(IERC721 _wlPass, IERC20 _erc20, uint _price, address _withdrawAddress, address _devAddress) {
        wlPass = _wlPass;
        erc20 = _erc20;
        price = _price;
        withdrawAddress = _withdrawAddress;
        devAddress = _devAddress;
    }

    function setWLPass(IERC721 _wlPass) public onlyOwner {
        wlPass = _wlPass;
    }

    function setClaimStart(bool _isStarted) public onlyOwner {
        claimStarted = _isStarted;
    }

    function setWithdrawAddress(address _newAddress) public onlyOwner {
        withdrawAddress = _newAddress;
    }

    function setDevAddress(address _newAddress) public onlyOwner {
        devAddress = _newAddress;
    }

    function setPrice(uint _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setERC20(IERC20 _newAddress) public onlyOwner {
        erc20 = _newAddress;
    }

    function reserve(string memory solAddress, uint tokenId) public {
        require(claimStarted, "claim not started");
        require(wlPass.ownerOf(tokenId) == msg.sender, "must be owner of claim token");
        require(wlPass.claimed(tokenId), "claim token must be claimed");

        if (!isReserved[tokenId]) {
            pay();
        }

        reservations[tokenId] = solAddress;
        isReserved[tokenId] = true;
    }

    function pay() internal {
        uint withdrawAmount = (price * 2) / 100;
        erc20.transferFrom(msg.sender, devAddress, withdrawAmount);
        erc20.transferFrom(msg.sender, withdrawAddress, price - withdrawAmount);
    }
}