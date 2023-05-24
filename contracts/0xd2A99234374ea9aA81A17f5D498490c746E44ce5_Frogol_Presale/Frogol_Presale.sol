/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-22
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-22
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;
interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
/* --------- Access Control --------- */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(){
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Claimable is Ownable {
    function claimToken(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function claimETH(uint256 amount) external onlyOwner {
        (bool sent, ) = owner().call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract Frogol_Presale is Claimable {
    event Buy(address to, uint256 amount);
    address public tokenAddress;
    address adminWallet;
    uint256 price;
    uint256 public startTime;
    uint256 public totalSaled;

    constructor(
        address _tokenAddress,
        address _adminWallet,
        uint256 _price
    ) {
        tokenAddress = _tokenAddress;
        adminWallet = _adminWallet;
        price = _price;
        startTime = block.timestamp;
        totalSaled = 0;
    }

    function resetPrice(uint256 _price) public onlyOwner {
        price = _price;
    }
    function resetStartTime() public onlyOwner {
        startTime = block.timestamp;
    }

    function setAdminWallet(address _adminWallet) external onlyOwner {
        adminWallet = _adminWallet;
    }

    function buy() public payable {
        uint256 tokenAmount = (msg.value * getPrice()) / 1e6;
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        totalSaled += tokenAmount;
        (bool sent, ) = owner().call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        emit Buy(msg.sender, tokenAmount);
    }

    function getPrice() public view returns (uint256 tokenPrice) {
        tokenPrice = price;
    }

    receive() external payable {
        buy();
    }

    fallback() external payable {
        buy();
    }
}