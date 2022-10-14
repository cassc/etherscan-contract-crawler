// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

//import "./access/TrustedForwarder.sol";
import "@artman325/trustedforwarder/contracts/TrustedForwarder.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract RewardsBase is TrustedForwarder, OwnableUpgradeable {
    address internal sellingToken;
    uint256[] internal timestamps;
    uint256[] internal prices;

    uint256 internal maxGasPrice;

    uint256 internal constant priceDenom = 100_000_000; //1*10**8;

    struct Participant {
        string groupName;
        uint256 totalAmount;
        uint256 contributed;
        bool exists;
    }

    struct Group {
        string name;
        uint256 totalAmount;
        address[] participants;
        bool exists;
    }

    mapping(string => Group) groups;
    mapping(address => Participant) participants;

    mapping(address => uint256) totalInvestedGroupOutside;

    uint256[] thresholds; // count in ETH
    uint256[] bonuses; // percents mul by 100

    modifier validGasPrice() {
        require(tx.gasprice <= maxGasPrice, "Transaction gas price cannot exceed maximum gas price.");
        _;
    }

    function __Rewards_init(
        address _sellingToken,
        uint256[] memory _timestamps,
        uint256[] memory _prices,
        uint256[] memory _thresholds,
        uint256[] memory _bonuses
    ) internal onlyInitializing {
        __TrustedForwarder_init();
        __Ownable_init();

        require(_sellingToken != address(0), "_sellingToken can not be zero");

        maxGasPrice = 1 * 10**18;

        sellingToken = _sellingToken;
        timestamps = _timestamps;
        prices = _prices;
        thresholds = _thresholds;
        bonuses = _bonuses;
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, TrustedForwarder)
        returns (address signer)
    {
        return TrustedForwarder._msgSender();
    }

    /**
     * data which contract was initialized
     */
    function getConfig()
        public
        view
        returns (
            address _sellingToken,
            uint256[] memory _timestamps,
            uint256[] memory _prices,
            uint256[] memory _thresholds,
            uint256[] memory _bonuses
        )
    {
        _sellingToken = sellingToken;
        _timestamps = timestamps;
        _prices = prices;
        _thresholds = thresholds;
        _bonuses = bonuses;
    }

    // [deprecated] used then need toi calculate "how much user will obtain tokens when send ETH(or erc20) into contract"
    // function _exchange(uint256 inputAmount) internal {
    //     uint256 tokenPrice = getTokenPrice();
    //     uint256 amount2send = _getTokenAmount(inputAmount, tokenPrice);
    //     require(amount2send > 0, "FundContract: Can not calculate amount of tokens");

    //     uint256 tokenBalance = IERC20(sellingToken).balanceOf(address(this));
    //     require(tokenBalance >= amount2send, "FundContract: Amount exceeds allowed balance");

    //     bool success = IERC20(sellingToken).transfer(_msgSender(), amount2send);
    //     require(success == true, "Transfer tokens were failed");

    //     // bonus calculation
    //     _addBonus(_msgSender(), (inputAmount));
    // }

    /**
     * @dev setup trusted forwarder address
     * @param forwarder trustedforwarder's address to set
     * @custom:shortd setup trusted forwarder
     * @custom:calledby owner
     */
    function setTrustedForwarder(address forwarder) public override onlyOwner {
        require(owner() != forwarder, "FORWARDER_CAN_NOT_BE_OWNER");
        _setTrustedForwarder(forwarder);
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(!_isTrustedForwarder(msg.sender), "DENIED_FOR_FORWARDER");
        //if (_isTrustedForwarder(msg.sender)) {revert DeniedForTrustedForwarder(msg.sender);}

        if (_isTrustedForwarder(newOwner)) {
            _setTrustedForwarder(address(0));
        }
        // _accountForOperation(
        //     OPERATION_SET_TRANSFER_OWNERSHIP << OPERATION_SHIFT_BITS,
        //     uint256(uint160(_msgSender())),
        //     uint256(uint160(newOwner))
        // );
        super.transferOwnership(newOwner);
    }

    /**
     * @param addresses array of addresses which need to link with group
     * @param groupName group name. if does not exists it will be created
     */
    function setGroup(address[] memory addresses, string memory groupName) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _setGroup(addresses[i], groupName);
        }
    }

    /**
     * get exchange rate ETH -> sellingToken
     */
    function getTokenPrice() public view returns (uint256 price) {
        uint256 ts = timestamps[0];
        price = prices[0];
        for (uint256 i = 0; i < timestamps.length; i++) {
            if (block.timestamp >= timestamps[i] && timestamps[i] >= ts) {
                ts = timestamps[i];
                price = prices[i];
            }
        }
    }

    /**
     * @param groupName group name
     */
    function getGroupBonus(string memory groupName) public view returns (uint256 bonus) {
        return _getGroupBonus(groupName);
    }

   

    function _claim(address addr, string memory groupName) internal {
        //// send tokens
        uint256 groupBonus = _getGroupBonus(groupName);
        uint256 tokenPrice = getTokenPrice();

        uint256 participantTotalBonusTokens = (_getTokenAmount(participants[addr].totalAmount, tokenPrice) *
            groupBonus) / 1e2;

        if (participantTotalBonusTokens > participants[addr].contributed) {
            uint256 amount2Send = participantTotalBonusTokens - participants[addr].contributed;
            participants[addr].contributed = participantTotalBonusTokens;

            _sendTokens(amount2Send, addr);
        }
    }

    function _getGroupBonus(string memory groupName) internal view returns (uint256 bonus) {
        bonus = 0;

        if (groups[groupName].exists == true) {
            uint256 groupTotalAmount = groups[groupName].totalAmount;
            uint256 tmp = 0;
            for (uint256 i = 0; i < thresholds.length; i++) {
                if (groupTotalAmount >= thresholds[i] && thresholds[i] >= tmp) {
                    tmp = thresholds[i];
                    bonus = bonuses[i];
                }
            }
        }
    }

    /**
     * calculate token"s amount
     * @param amount amount in eth that should be converted in tokenAmount
     * @param price token price. can be calculated in getTokenPrice method
     * @return amount of selling tokens that user should obtain after exchange
     */
    function _getTokenAmount(uint256 amount, uint256 price) internal pure returns (uint256) {
        return (amount * priceDenom) / price;
    }

    /**
    * @param tokenAmount amount in selling tokens
    * @param price token price it current period time. can be calculated in getTokenPrice method
    * @return amount of input tokens(eth or erc20) that user should send into contract to obtain selling token
    */
    function _getNeededInputAmount(uint256 tokenAmount, uint256 price) internal pure returns(uint256) {
        return (tokenAmount * price / priceDenom);
    }

    /**
     * @param amount amount of tokens
     * @param addr address to send
     */
    function _sendTokens(uint256 amount, address addr) internal {
        require(amount > 0, "Amount can not be zero");
        require(addr != address(0), "address can not be empty");

        uint256 tokenBalance = IERC20(sellingToken).balanceOf(address(this));
        require(tokenBalance >= amount, "Amount exceeds allowed balance");

        bool success = IERC20(sellingToken).transfer(addr, amount);
        require(success == true, "Transfer tokens were failed");
    }

    /**
     * @param addr address which need to link with group
     * @param groupName group name. if does not exists it will be created
     */
    function _setGroup(address addr, string memory groupName) internal {
        require(addr != address(0), "address can not be empty");
        require(bytes(groupName).length != 0, "groupName can not be empty");

        if (participants[addr].exists == false) {
            participants[addr].exists = true;
            participants[addr].contributed = 0;
            participants[addr].groupName = groupName;

            if (groups[groupName].exists == false) {
                groups[groupName].exists = true;
                groups[groupName].name = groupName;
                groups[groupName].totalAmount = 0;
            }

            groups[groupName].participants.push(addr);

            if (totalInvestedGroupOutside[addr] > 0) {
                _addBonus(addr, totalInvestedGroupOutside[addr], true);
            }
        }
    }

    /**
     * calculate user bonus tokens and send it to him
     * @param addr Address of participant
     * @param ethAmount amount
     */
    function _addBonus(address addr, uint256 ethAmount, bool doClaim) internal {
        if (participants[addr].exists == true) {
            string memory groupName = participants[addr].groupName;

            groups[groupName].totalAmount += ethAmount;
            participants[addr].totalAmount += ethAmount;

            if (doClaim) {
                _claim(addr, groupName);
            }

            /*
            ////cycle for sending tokens for all group participants
            
            uint256 groupBonus = _getGroupBonus(groupName);
            address participantAddr;
            uint256 participantTotalBonusTokens;

            uint256 tokenPrice = getTokenPrice();

            for (uint256 i = 0; i < groups[groupName].participants.length; i++) {
                participantAddr = groups[groupName].participants[i];

                participantTotalBonusTokens = _getTokenAmount(
                                                                participants[participantAddr].totalAmount, 
                                                                tokenPrice
                                                            ) * groupBonus / 1e2;

                if (participantTotalBonusTokens > participants[participantAddr].contributed) {
                    uint256 amount2Send = participantTotalBonusTokens - participants[participantAddr].contributed;
                    participants[participantAddr].contributed = participantTotalBonusTokens;
                  
                    _sendTokens(amount2Send, participantAddr);
                    
                }
            }
            */
        } else {
            totalInvestedGroupOutside[addr] += ethAmount;
        }
    }

}