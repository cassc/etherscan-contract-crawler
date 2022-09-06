//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IERC721A.sol";

contract EightHundredEightyEight is ERC721A, Ownable {
    using SafeMath for uint256;

    error NotEligible();
    error NotAllowedToSend();
    error NotTheOwnerOfToken();
    error NotActive();
    error InsufficientFunds();
    error MintWouldExceedMaxSupply();
    error YouCannotBurn888NFTs();

    string private _baseTokenURI;

    uint256 public maxSupply = 888;
    uint256 public amountOfInactiveUsers;
    uint256 private rewardsSentOutRecent;
    uint256 public timeRestriction = 9676800; // 112 Days | 1 Day = 86400

    mapping(address => bool) private _inactiveList;

    constructor() ERC721A("888 Club", "888") {
        rewardsSentOutRecent = block.timestamp;
        _mint(0x9234E442ED4Df8BB53eA2d05311241d8ec522499, 888);
    }

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function setUsersInactive(address[] calldata targets) external onlyOwner {
        for (uint256 i = 0; i < targets.length; i++) {
            _inactiveList[targets[i]] = true;
        }
        amountOfInactiveUsers += targets.length;
    }

    function removeInactiveUsers(address[] calldata targets)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < targets.length; i++) {
            _inactiveList[targets[i]] = false;
        }
        amountOfInactiveUsers -= targets.length;
    }

    function isUserInactive(address _checkUser) external view returns (bool) {
        return _inactiveList[_checkUser];
    }

    function setTimeRestriction(uint256 _newTimeRestriction)
        external
        onlyOwner
    {
        timeRestriction = _newTimeRestriction;
    }

    function resetTimestamp() external onlyOwner {
        rewardsSentOutRecent = block.timestamp;
    }

    function setTimestamp(uint256 _timeInBlocks) external onlyOwner {
        rewardsSentOutRecent = _timeInBlocks;
    }

    function airdropRewardPerNFT() external onlyOwner {
        require(
            block.timestamp - rewardsSentOutRecent > timeRestriction,
            "Not Allowed To Send"
        );
        uint256 ts = totalSupply();
        uint256 balance = address(this).balance;

        uint256 allocation = (balance).div(ts - amountOfInactiveUsers);

        for (uint256 i = 0; i < ts; i++) {
            if (!_inactiveList[ownerOf(i)]) {
                payable(ownerOf(i)).transfer(allocation);
            }
        }
        rewardsSentOutRecent = block.timestamp;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawAllFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawSpecificAmount(uint256 _amount) external onlyOwner {
        uint256 balance = address(this).balance;
        if (_amount > balance) revert InsufficientFunds();
        payable(msg.sender).transfer(_amount);
    }
}