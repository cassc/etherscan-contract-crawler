// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./UtilToken.sol";
import "./ERC721.sol";
import "./Ownable.sol";

/// @title RebirthStaking
/// @author Hub3

/*
 /$$$$$$$$ /$$                       /$$$$$$$            /$$       /$$             /$$     /$$      
|__  $$__/| $$                      | $$__  $$          | $$      |__/            | $$    | $$      
   | $$   | $$$$$$$   /$$$$$$       | $$  \ $$  /$$$$$$ | $$$$$$$  /$$  /$$$$$$  /$$$$$$  | $$$$$$$ 
   | $$   | $$__  $$ /$$__  $$      | $$$$$$$/ /$$__  $$| $$__  $$| $$ /$$__  $$|_  $$_/  | $$__  $$
   | $$   | $$  \ $$| $$$$$$$$      | $$__  $$| $$$$$$$$| $$  \ $$| $$| $$  \__/  | $$    | $$  \ $$
   | $$   | $$  | $$| $$_____/      | $$  \ $$| $$_____/| $$  | $$| $$| $$        | $$ /$$| $$  | $$
   | $$   | $$  | $$|  $$$$$$$      | $$  | $$|  $$$$$$$| $$$$$$$/| $$| $$        |  $$$$/| $$  | $$
   |__/   |__/  |__/ \_______/      |__/  |__/ \_______/|_______/ |__/|__/         \___/  |__/  |__/å                                                                                                                                                                                     
*/

contract RebirthStaking is Ownable {
    struct ContractMult {
        ERC721 erc721;
        uint128 initialMultiplier; //multiplier for initial claming (set in percentage -> x2 === 200%)
        uint128 stakingMultiplier; //multiplier for staking         (set in percentage -> x2 === 200%)
    }

    /// @notice Mapping of base contracts to their multiplier.
    UtilToken public utilToken;

    /// @notice Mapping of any additional contracts to their multiplier.
    mapping(address => ContractMult) public additionalContracts;

    /// @notice Stores addresses of additional contracts
    address[] public addContrAddresses;

    /// @notice Keeps track of the timestamp of when a holder last withdrew their rewards.
    mapping(address => uint256) public lastUpdated;

    uint256 constant oneHourInSeconds = 3600;

    uint256 public initialClaim = 100 ether;
    uint256 public stakingReward = 5 ether;

    constructor(address _utilToken) {
        utilToken = UtilToken(_utilToken);
    }

    function getContractsCount() public view returns (uint256 count) {
        return addContrAddresses.length;
    }

    function walletHoldsAnyToken(address _wallet) public view returns (bool) {
        for (uint8 i = 0; i < addContrAddresses.length; i++) {
            if (walletHoldsToken(_wallet, additionalContracts[addContrAddresses[i]].erc721)) {
                return true;
            }
        }
        return false;
    }

    function walletHoldsToken(address _wallet, ERC721 _contract) public view returns (bool) {
        return _contract.balanceOf(_wallet) > 0;
    }

    function claimAllTokens() public {
        require(
            isUserAllowedToClaim(msg.sender),
            "You have to wait at least 24 hours until your next claim!"
        );

        utilToken.mintUtil(msg.sender, getRewardAmount(msg.sender));

        lastUpdated[msg.sender] = getTime();
    }

    function getRewardAmount(address recipient) public view returns (uint256) {
        uint256 earningsMultiplier;
        for (uint8 i = 0; i < addContrAddresses.length; i++) {
            earningsMultiplier += getEarningsMultFromContract(
                additionalContracts[addContrAddresses[i]],
                recipient
            );
        }

        if (lastUpdated[recipient] == 0) {
            return (initialClaim * earningsMultiplier) / 100;
        } else {
            return (stakingReward * earningsMultiplier) / 100;
        }
    }

    /**
     * @notice this function returns the earnings multiplier for a specific contract
     * @notice earnings multiplier is calculated by number of NFTs from contract in wallet * multiplier * (hours since last claim / 24)
     */
    function getEarningsMultFromContract(ContractMult memory _contract, address _wallet)
        internal
        view
        returns (uint256)
    {
        uint256 nftBalance = _contract.erc721.balanceOf(_wallet);
        uint256 claimingMult = _contract.stakingMultiplier;
        uint256 timeMultiplier = (getHoursSinceLastClaim(_wallet) * 100) / 24; //multiply by 100 to avoid floats

        if (lastUpdated[_wallet] == 0) {
            claimingMult = _contract.initialMultiplier;
            timeMultiplier = 100;
        }

        return (nftBalance * claimingMult * timeMultiplier) / 100;
    }

    /*///////////////////////////////////////////////////////////////
                            TIMESTAMP FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function isUserAllowedToClaim(address _wallet) public view returns (bool) {
        if (lastUpdated[_wallet] == 0) return true;
        if (getHoursSinceLastClaim(_wallet) >= 24) return true;
        return false;
    }

    function getHoursSinceLastClaim(address _wallet) public view returns (uint256) {
        return (getTime() - lastUpdated[_wallet]) / oneHourInSeconds;
    }

    /*///////////////////////////////////////////////////////////////
                            UPDATE CONTRACTS
    //////////////////////////////////////////////////////////////*/

    function addContract(
        address _contract,
        uint128 initialMultiplier,
        uint128 stakingMultiplier
    ) public onlyOwner {
        additionalContracts[_contract] = ContractMult(
            ERC721(_contract),
            initialMultiplier,
            stakingMultiplier
        );
        addContrAddresses.push(_contract);
    }

    function removeContract(address _contract) public onlyOwner {
        delete (additionalContracts[_contract]);

        for (uint8 i = 0; i < addContrAddresses.length; i++) {
            if (addContrAddresses[i] == _contract) {
                addContrAddresses[i] = addContrAddresses[addContrAddresses.length - 1];
                addContrAddresses.pop();
                break;
            }
        }
    }

    function updateMultiplierForContract(
        address _contract,
        uint128 _initialMultiplier,
        uint128 _stakingMultiplier
    ) public onlyOwner {
        require(isContractAdded(_contract), "The given contract is not added as a valid claiming condition!");
        additionalContracts[_contract].initialMultiplier = _initialMultiplier;
        additionalContracts[_contract].stakingMultiplier = _stakingMultiplier;
        // event informing contract was not found
    }

    function updateInitialClaim(uint256 _initialClaim) public onlyOwner {
        initialClaim = _initialClaim;
    }

    function updateStakingReward(uint256 _stakingReward) public onlyOwner {
        stakingReward = _stakingReward;
    }

    /*///////////////////////////////////////////////////////////////	
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function isContractAdded(address _contract) internal view returns (bool) {
        for (uint8 i = 0; i < addContrAddresses.length; i++) {
            if (addContrAddresses[i] == _contract) {
                return true;
            }
        }
        return false;
    }

    function getTime() public view virtual returns (uint256) {
        // current block timestamp as seconds since unix epoch
        // ref: https://solidity.readthedocs.io/en/v0.5.7/units-and-global-variables.html#block-and-transaction-properties
        return block.timestamp;
    }

    function getInitialMultiplierForContract(address _contract) internal view returns (uint128) {
        require(isContractAdded(_contract), "Contract is not added!");
        return additionalContracts[_contract].initialMultiplier;
    }

    function getStakingMultiplierForContract(address _contract) internal view returns (uint128) {
        require(isContractAdded(_contract), "Contract is not added!");
        return additionalContracts[_contract].stakingMultiplier;
    }

    function getDailyRewardAmount(address recipient) public view returns (uint256) {
        uint256 earningsMultiplier;
        for (uint8 i = 0; i < addContrAddresses.length; i++) {
            uint256 nftBalance = additionalContracts[addContrAddresses[i]].erc721.balanceOf(recipient);
            uint256 claimingMult = additionalContracts[addContrAddresses[i]].stakingMultiplier;
            earningsMultiplier += nftBalance * claimingMult;
        }
        return (stakingReward * earningsMultiplier) / 100;
    }
}