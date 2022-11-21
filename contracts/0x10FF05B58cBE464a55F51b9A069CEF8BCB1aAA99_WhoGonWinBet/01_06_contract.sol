// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract WhoGonWinBet is Ownable, ReentrancyGuard {

    BetPool[] betPools;
    uint8 royaltyFactor = 10;
    uint immutable minimumBetValue = 0.01 ether;
    IERC721A immutable whoGoWinNft;

    struct BaseBetPool {
        string key;
        uint startTimestamp;
        uint endTimestamp;
        uint8[] options;
        string config;
    }

    struct BetPool {
        BaseBetPool base;

        // update on finalized
        uint8 finalizedOption;
        uint royaltyFactor;
        bool claimable;
    }

    struct EthToEarn {
        uint valueForSender;
        uint valueForInvitor;
    }

    mapping(string => mapping(uint8 => mapping(address => uint))) optionAddressBetValueMap;
    mapping(string => mapping(uint8 => address[])) optionBetAddresses;
    mapping(string => mapping(uint8 => uint)) optionBetValueMap;

    mapping(string => mapping(address => address[])) invitorAddressesMap;
    mapping(string => mapping(address => bool)) addressClaimedMap;

    mapping(string => bool) betKeysMap;
    mapping(string => uint) betKeyIndexMap;

    constructor() {
        whoGoWinNft = IERC721A(0xE855DD773A3d9c5F7F66869D7711194Cee6dD47E);
    }

    function updateRoyaltyFactor(uint8 royaltyFactor_) public onlyOwner {
        royaltyFactor = royaltyFactor_;
    }

    function upsertBetPool(string memory _betKey, uint _startTimestamp, uint _endTimestamp, uint8[] memory _options, string memory _config) public onlyOwner {
        require(_options.length > 1 && _options.length <= 4, 'InvalidArgs: options');
        require(_startTimestamp < _endTimestamp, 'InvalidArgs: timestamp');
        if (!betKeysMap[_betKey]) {
            betKeysMap[_betKey] = true;
            betKeyIndexMap[_betKey] = betPools.length;
            BaseBetPool memory baseBetPool = BaseBetPool(_betKey, _startTimestamp, _endTimestamp, _options, _config);
            BetPool memory newBetPool = BetPool(baseBetPool, 0, royaltyFactor, false);
            betPools.push(newBetPool);
        }

        BetPool storage betPool = betPools[betKeyIndexMap[_betKey]];
        require(!betPool.claimable, 'Cannot update betPool after the betPool is claimable');
        betPool.base.key = _betKey;
        betPool.base.startTimestamp = _startTimestamp;
        betPool.base.endTimestamp = _endTimestamp;
        betPool.base.options = _options;
        betPool.base.config = _config;
    }

    function finalize(string memory _betKey, uint8 _option) public onlyOwner {
        require(betKeysMap[_betKey], 'InvalidArgs: betKey');

        BetPool storage betPool = betPools[betKeyIndexMap[_betKey]];
        require(block.timestamp >= betPool.base.endTimestamp, 'InvalidArgs: blockTimestamp');
        require(_option < betPool.base.options.length, 'InvalidArgs: option');

        betPool.royaltyFactor = royaltyFactor;
        betPool.finalizedOption = _option;
        betPool.claimable = true;
    }

    function betEth(string memory _betKey, uint8 _option, address _inviteAddress) payable external {
        address msgSender = _msgSender();
        uint msgValue = msg.value;
        uint blockTimestamp = block.timestamp;

        require(msgValue >= minimumBetValue, 'InvalidArgs: minimumBetValue');
        require(betKeysMap[_betKey], 'InvalidArgs: betKey');

        BetPool storage betPool = betPools[betKeyIndexMap[_betKey]];
        require(blockTimestamp >= betPool.base.startTimestamp && blockTimestamp < betPool.base.endTimestamp, 'InvalidArgs: blockTimestamp');
        require(_option < betPool.base.options.length, 'InvalidArgs: option');

        if (optionAddressBetValueMap[_betKey][_option][msgSender] == 0) {
            optionBetAddresses[_betKey][_option].push(msgSender);
        }
        optionAddressBetValueMap[_betKey][_option][msgSender] += msgValue;
        optionBetValueMap[_betKey][_option] += msgValue;

        if (invitorAddressesMap[_betKey][msgSender].length == 0 && _inviteAddress != address(0) && _inviteAddress != msgSender && whoGoWinNft.balanceOf(_inviteAddress) > 0) {
            invitorAddressesMap[_betKey][msgSender].push(_inviteAddress);
        }
    }

    function _calculateEthToEarn(address msgSender, BetPool storage betPool) private view returns (EthToEarn memory) {
        string memory _betKey = betPool.base.key;
        uint betValue = optionAddressBetValueMap[_betKey][betPool.finalizedOption][msgSender];
        if (betValue == 0) {
            return EthToEarn(0, 0);
        }

        uint totalRewards = 0;
        for (uint i = 0; i < betPool.base.options.length; i++) {
            uint8 option = betPool.base.options[i];
            if (option != betPool.finalizedOption) {
                totalRewards += optionBetValueMap[_betKey][option];
            }
        }
        if (totalRewards == 0) {
            return EthToEarn(0, 0);
        }

        uint valueForSender = totalRewards * (100 - betPool.royaltyFactor) / 100 * betValue / optionBetValueMap[_betKey][betPool.finalizedOption];
        if (invitorAddressesMap[_betKey][msgSender].length > 0) {
            uint finalEthToEarn = valueForSender * 95 / 100;
            return EthToEarn(finalEthToEarn + betValue, valueForSender - finalEthToEarn);
        }
        return EthToEarn(valueForSender + betValue, 0);
    }

    function earnEth(string memory _betKey) external nonReentrant {
        require(betKeysMap[_betKey], 'InvalidArgs: betKey');

        address msgSender = _msgSender();
        BetPool storage betPool = betPools[betKeyIndexMap[_betKey]];
        require(!addressClaimedMap[_betKey][msgSender], 'Already claimed');

        EthToEarn memory ethToEarn = _calculateEthToEarn(msgSender, betPool);
        require(ethToEarn.valueForSender > 0, 'ethToEarn must greater than 0');

        (bool _os1,) = payable(msgSender).call{value : ethToEarn.valueForSender}('');
        require(_os1);

        if (ethToEarn.valueForInvitor > 0 && invitorAddressesMap[_betKey][msgSender].length > 0) {
            address invitor = invitorAddressesMap[_betKey][msgSender][0];
            (bool _os2,) = payable(invitor).call{value : ethToEarn.valueForInvitor}('');
            require(_os2);
        }
        addressClaimedMap[_betKey][msgSender] = true;
    }

    struct FeBetOption {
        uint8 option;
        uint betValue;
        uint totalBetValue;
        uint totalBetAddressCount;
    }

    struct FeBetPool {
        BaseBetPool base;
        bool claimable;
        bool claimed;
        uint claimableValue;
        address[] invitorAddresses;
        FeBetOption[] options;
    }

    function getBetPoolList(address msgSender) public view returns (FeBetPool[] memory) {
        FeBetPool[] memory list = new FeBetPool[](betPools.length);

        for (uint i = 0; i < betPools.length; i++) {
            BetPool storage betPool = betPools[i];
            string memory _betKey = betPool.base.key;

            FeBetOption[] memory options = new FeBetOption[](betPool.base.options.length);
            for (uint j = 0; j < betPool.base.options.length; j++) {
                uint8 option = betPool.base.options[j];
                options[j] = FeBetOption(option, optionAddressBetValueMap[_betKey][option][msgSender], optionBetValueMap[_betKey][option], optionBetAddresses[_betKey][option].length);
            }

            bool claimable = betPool.claimable;
            uint claimableValue = 0;
            if (claimable) {
                claimableValue = _calculateEthToEarn(msgSender, betPool).valueForSender;
            }

            list[i] = FeBetPool(betPool.base, claimable, addressClaimedMap[_betKey][msgSender], claimableValue, invitorAddressesMap[_betKey][msgSender], options);
        }
        return list;
    }
}