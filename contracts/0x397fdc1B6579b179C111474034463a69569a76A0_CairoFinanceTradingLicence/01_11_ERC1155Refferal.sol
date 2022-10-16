// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract CairoFinanceTradingLicence is ERC1155, Ownable, ERC1155Supply {
    event Distribution(
        address indexed receiver,
        address fromUser,
        uint256 levelIncome,
        uint256 incomeReceived
    ); //Reward Distribution Event
    event NFTBought(
        address userAddress,
        address referredBy,
        uint256 amountPaid,
        uint256 joingDate
    );
    struct userData {
        uint256 id;
        address userAddress;
        address referredBy;
        uint256 amountPaid;
        uint256 joingDate;
        uint256 referCount100;
        bool activeAllLevel;
        bool isExist;
    } // Stores data of every user who purchased nft.
    struct levelEarning {
        uint256 level1;
        uint256 level2;
        uint256 level3;
    }
    bool mintAllowed = true; // Minting status
    uint256 public _currentId = 1;
    uint256[] levelDistribution = [10, 5]; //Level of reward distribution after referre
    uint256 NFT_Price = 0.01 ether; //Price of nft
    mapping(address => userData) public users;
    mapping(address => uint256) public distributionIncome; //Get income received from distribution;
    mapping(address => levelEarning) public levelEarnings;
    address internal firstId;

    constructor() ERC1155("") {
        totalSupply(9999);
        users[msg.sender] = userData(
            _currentId,
            msg.sender,
            address(0),
            100,
            block.timestamp,
            1,
            true,
            true
        ); // Creating a user instance for owner
        firstId = msg.sender;
        _currentId++;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function buyNFT(address referredBy) external payable {
        require(msg.sender != address(0), "Can't be zero address");
        require(mintAllowed, "Max supply reached");
        require(checkUserExists(referredBy) == true, "Invalid refer address");
        require(msg.value == NFT_Price, "Invalid Amount Sent");

        _mint(msg.sender, 1, 1, ""); //Minting ERC1155
        uint256 amountTransfered = (msg.value * 15) / 100; //Keeping records of the refferal rewards sent.
        payable(referredBy).transfer((msg.value * 15) / 100); //Sending Reffer Rewards

        emit Distribution(referredBy, msg.sender, 5, amountTransfered); //Emitting 1st refferal reward distribution.
        levelEarnings[referredBy].level1 += amountTransfered; //Level 1 earning
        distributionIncome[referredBy] += (amountTransfered); //Recording the rewards per account.
        address uplineUserAddress = getUplineAddress(referredBy); //Getting previous refferal adresses.
        uint256 currentLevelDistribute = 0;

        for (uint256 i = 0; i <= _currentId; i++) {
            if (uplineUserAddress == firstId) {
                break;
            } else {
                if (currentLevelDistribute < 2) {
                    if (users[uplineUserAddress].activeAllLevel == true) {
                        payable(uplineUserAddress).transfer(
                            (msg.value *
                                levelDistribution[currentLevelDistribute]) / 100
                        );
                        distributionIncome[uplineUserAddress] +=
                            (msg.value *
                                levelDistribution[currentLevelDistribute]) /
                            100;
                        emit Distribution(
                            uplineUserAddress,
                            msg.sender,
                            currentLevelDistribute,
                            (msg.value *
                                levelDistribution[currentLevelDistribute]) / 100
                        );
                        amountTransfered +=
                            (msg.value *
                                levelDistribution[currentLevelDistribute]) /
                            100;
                        if (currentLevelDistribute == 0) {
                            levelEarnings[uplineUserAddress].level2 +=
                                (msg.value *
                                    levelDistribution[currentLevelDistribute]) /
                                100; //Level2 earning
                        }
                        if (currentLevelDistribute == 1) {
                            levelEarnings[uplineUserAddress].level3 +=
                                (msg.value *
                                    levelDistribution[currentLevelDistribute]) /
                                100; //Level3 earning
                        }
                        uplineUserAddress = getUplineAddress(uplineUserAddress);

                        currentLevelDistribute++;
                    } else {
                        uplineUserAddress = getUplineAddress(uplineUserAddress);
                    }
                } else {
                    break;
                }
            }
        }
        if (users[msg.sender].userAddress == address(0)) {
            users[msg.sender] = userData(
                _currentId,
                msg.sender,
                referredBy,
                msg.value,
                block.timestamp,
                1,
                true,
                true
            );

            _currentId++;
        } else if (users[msg.sender].userAddress == msg.sender) {
            users[msg.sender].amountPaid += msg.value;
            users[msg.sender].referCount100++;
        }
        payable(firstId).transfer(msg.value - amountTransfered);
        emit NFTBought(msg.sender, referredBy, msg.value, block.timestamp);
    }

    function getUplineAddress(address _userAddress)
        internal
        view
        returns (address)
    {
        return users[_userAddress].referredBy;
    }

    function getRewards(address _userAddress) public view returns (uint256) {
        uint256 bv = distributionIncome[_userAddress];
        return bv;
    }

    function checkUserExists(address _userAddress)
        internal
        view
        returns (bool)
    {
        return users[_userAddress].isExist;
    }

    function level1Earnings(address _userAddress)
        public
        view
        returns (uint256)
    {
        return levelEarnings[_userAddress].level1;
    }

    function level2Earnings(address _userAddress)
        public
        view
        returns (uint256)
    {
        return levelEarnings[_userAddress].level2;
    }

    function level3Earnings(address _userAddress)
        public
        view
        returns (uint256)
    {
        return levelEarnings[_userAddress].level3;
    }
}