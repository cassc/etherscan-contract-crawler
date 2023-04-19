// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../token/IERC20.sol';
import './VoteStorage.sol';

contract VoteImplementation is VoteStorage {

    event NewVoteTopic(string topic, uint256 numOptions, uint256 deadline);

    event NewVote(address indexed voter, uint256 option);

    uint256 public constant cooldownTime = 900;

    function initializeVote(string memory topic_, uint256 numOptions_, uint256 deadline_) external _onlyAdmin_ {
        require(block.timestamp > deadline, 'VoteImplementation.initializeVote: still in vote');
        topic = topic_;
        numOptions = numOptions_;
        deadline = deadline_;
        delete voters;
        emit NewVoteTopic(topic_, numOptions_, deadline_);
    }

    function vote(uint256 option) external {
        require(block.timestamp < deadline, 'VoteImplementation.vote: vote ended');
        require(option >= 1 && option <= numOptions, 'VoteImplementation.vote: invalid vote option');
        voters.push(msg.sender);
        votes[msg.sender] = option;
        if (block.timestamp + cooldownTime >= deadline) {
            deadline += cooldownTime;
        }
        emit NewVote(msg.sender, option);
    }


    //================================================================================
    // Convenient query functions
    //================================================================================

    function getVoters() external view returns (address[] memory) {
        return voters;
    }

    function getVotes(address[] memory accounts) external view returns (uint256[] memory) {
        uint256[] memory options = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            options[i] = votes[accounts[i]];
        }
        return options;
    }

    function getVotePowerOnEthereum(address account) public view returns (uint256) {
        address deri = 0xA487bF43cF3b10dffc97A9A744cbB7036965d3b9;
        address uniswapV2Pair = 0xA3DfbF2933FF3d96177bde4928D0F5840eE55600; // DERI-USDT

        // balance in wallet
        uint256 balance1 = IERC20(deri).balanceOf(account);
        // balance in uniswapV2Pair
        uint256 balance2 = IERC20(deri).balanceOf(uniswapV2Pair) * IERC20(uniswapV2Pair).balanceOf(account) / IERC20(uniswapV2Pair).totalSupply();

        return balance1 + balance2;
    }

    function getVotePowerOnBNB(address account) public view returns (uint256) {
        address deri = 0xe60eaf5A997DFAe83739e035b005A33AfdCc6df5;
        address pancakePair = 0xDc7188AC11e124B1fA650b73BA88Bf615Ef15256; // DERI-BUSD
        address poolV3 = 0x1eF92eDA3CFeefb8Dae0DB4507f860d3b73f29BA; // DERI-based Lite Pool
        address lToken = 0xA7620b1D023c8704851086F3eB6d1f0a3A31eAd3; // DERI-based Lite Pool LToken

        // balance in wallet
        uint256 balance1 = IERC20(deri).balanceOf(account);
        // balance in pancakePair
        uint256 balance2 = IERC20(deri).balanceOf(pancakePair) * IERC20(pancakePair).balanceOf(account) / IERC20(pancakePair).totalSupply();
        // balance in lite pool
        uint256 balance3;
        uint256 lTokenId = ILToken(lToken).getTokenIdOf(account);
        if (lTokenId != 0) {
            IPoolV3.LpInfo memory info = IPoolV3(poolV3).lpInfos(lTokenId);
            balance3 = info.liquidity >= 0 ? uint256(info.liquidity) : 0;
        }

        return balance1 + balance2 + balance3;
    }

    function getVotePowerOnArbitrum(address account) public view returns (uint256) {
        address deri = 0x21E60EE73F17AC0A411ae5D690f908c3ED66Fe12;

        // balance in wallet
        uint256 balance1 = IERC20(deri).balanceOf(account);

        return balance1;
    }

    function getVotePowersOnEthereum(address[] memory accounts) external view returns (uint256[] memory) {
        uint256[] memory powers = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            powers[i] = getVotePowerOnEthereum(accounts[i]);
        }
        return powers;
    }

    function getVotePowersOnBNB(address[] memory accounts) external view returns (uint256[] memory) {
        uint256[] memory powers = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            powers[i] = getVotePowerOnBNB(accounts[i]);
        }
        return powers;
    }

    function getVotePowersOnArbitrum(address[] memory accounts) external view returns (uint256[] memory) {
        uint256[] memory powers = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            powers[i] = getVotePowerOnArbitrum(accounts[i]);
        }
        return powers;
    }

}

interface IPoolV3 {
    struct LpInfo {
        address vault;
        int256 amountB0;
        int256 liquidity;
        int256 cumulativePnlPerLiquidity;
    }
    function lpInfos(uint256) external view returns (LpInfo memory);
}

interface ILToken {
    function getTokenIdOf(address account) external view returns (uint256);
}