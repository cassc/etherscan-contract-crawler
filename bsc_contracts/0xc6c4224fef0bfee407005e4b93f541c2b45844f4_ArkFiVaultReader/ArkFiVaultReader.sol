/**
 *Submitted for verification at BscScan.com on 2023-05-02
*/

/**
 *Submitted for verification at BscScan.com on 2023-04-24
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVAULT {
    function getAvailableReward(address _address)
        external
        view
        returns (uint256);

    function principalBalance(address _address) external view returns (uint256);

    function airdropBalance(address _address) external view returns (uint256);

    function deposits(address _address) external view returns (uint256);

    function newDeposits(address _address) external view returns (uint256);

    function out(address _address) external view returns (uint256);

    function postTaxOut(address _address) external view returns (uint256);

    function roi(address _address) external view returns (uint256);

    function tax(address _address) external view returns (uint256);

    function cwr(address _address) external view returns (uint256);

    function maxCwr(address _address) external view returns (uint256);

    function penalized(address _address) external view returns (bool);

    function accountReachedMaxPayout(address _address)
        external
        view
        returns (bool);

    function doneCompounding(address _address) external view returns (bool);

    function lastAction(address _address) external view returns (uint256);

    function compounds(address _address) external view returns (uint256);

    function withdrawn(address _address) external view returns (uint256);

    function airdropped(address _address) external view returns (uint256);

    function airdropsReceived(address _address) external view returns (uint256);

    function roundRobinRewards(address _address)
        external
        view
        returns (uint256);

    function directRewards(address _address) external view returns (uint256);

    function timeOfEntry(address _address) external view returns (uint256);

    function referrerOf(address _address) external view returns (address);

    function roundRobinPosition(address _address)
        external
        view
        returns (uint256);

    function upline(address _address, uint256 i)
        external
        view
        returns (address);

    function checkNdv(address investor) external view returns (int256);

    function getBondValue(address investor) external view returns (uint256);
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface ILEGACY {
    function getCwr(address investor) external view returns (uint256);

    function getLevels(address investor) external view returns (uint256);

    function getClaimableRewards(address investor)
        external
        view
        returns (uint256);
    function tokenOfOwnerByIndex(address investor, uint256 index) external view returns (uint256);
    function levelOfNft(uint256 nftId) external view returns (uint256);
}

interface IBOND {
    function getBondBalance(address investor) external view returns (uint256);

    function checkAvailableRewards(address investor)
        external
        view
        returns (uint256);
}

contract ArkFiVaultReader {
    IVAULT arkFiVault = IVAULT(0xeB5f81A779BCcA0A19012d24156caD8f899F6452);
    IBEP20 ARK_TOKEN = IBEP20(0x111120a4cFacF4C78e0D6729274fD5A5AE2B1111);
    IBOND bondContract = IBOND(0x3333e437546345F8Fd48Aa5cA8E92a77eD4b3333);
    ILEGACY legacy = ILEGACY(0x2222223B05B5842c918a868928F57cD3A0332222);

    struct Bond {
        uint256 bondValue;
        uint256 bondBalance;
    }

    struct Nfts {
        uint256 nftRewards;
        uint256 nftLevel;
    }

    struct Vault {
        address investor;
        uint256 principalBalance;
        uint256 availableRewards;
        uint256 deposits;
        uint256 cwr;
        int256 ndv;
        uint256 roi;
        uint256 lastAction;
        uint256 withdrawn;
        uint256 walletBalance;
        uint256 newDeposits;
        uint256 airdropsReceived;
    }

    function getInvestorStats(address investor)
        public
        view
        returns (
            Vault memory vaultData,
            Bond memory bondData,
            Nfts memory nftData
        )
    {
        vaultData = getVaultData(investor);
        bondData = getBondData(investor);
        nftData = getNftData(investor);
    }

    function getVaultData(address investor)
        private
        view
        returns (Vault memory investorData)
    {
        uint256 availableRewards = arkFiVault.getAvailableReward(investor);
        uint256 principalBalance = arkFiVault.principalBalance(investor);
        uint256 deposits = arkFiVault.deposits(investor);
        uint256 cwr = arkFiVault.cwr(investor);
        int256 ndv = arkFiVault.checkNdv(investor);
        uint256 roi = arkFiVault.roi(investor);
        uint256 lastAction = arkFiVault.lastAction(investor);
        uint256 withdrawn = arkFiVault.withdrawn(investor);
        uint256 walletBalance = ARK_TOKEN.balanceOf(investor);
        uint256 newDeposits = arkFiVault.newDeposits(investor);
        uint256 airdropsReceived = arkFiVault.airdropsReceived(investor);
        investorData = Vault(
            investor,
            principalBalance,
            availableRewards,
            deposits,
            cwr,
            ndv,
            roi,
            lastAction,
            withdrawn,
            walletBalance,
            newDeposits,
            airdropsReceived
        );
        return investorData;
    }

    function getBondData(address investor)
        public
        view
        returns (Bond memory bondData)
    {
        uint256 bondValue = arkFiVault.getBondValue(investor);
        uint256 bondBalance = bondContract.getBondBalance(investor);
        bondData = Bond(bondValue, bondBalance);
        return bondData;
    }

    function getNftData(address investor)
        public
        view
        returns (Nfts memory nftData)
    {
        uint256 nftId;
        try legacy.tokenOfOwnerByIndex(investor, 0) returns (uint256 tokenId) {
            nftId = tokenId;
        } catch {

        nftId = 0; // set nftId to an empty string
    }
        uint256 nftLevel;
        if(nftId == 0) {
            nftLevel = 0;
        } else {
            nftLevel = legacy.levelOfNft(nftId);
        }
        
        uint256 nftRewards = legacy.getClaimableRewards(investor);
        
        nftData = Nfts(nftRewards, nftLevel);
        return nftData;
    }
}