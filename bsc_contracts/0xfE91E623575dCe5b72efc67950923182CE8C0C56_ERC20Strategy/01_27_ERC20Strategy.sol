// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./BlocklistStrategy.sol";

contract ERC20Strategy is BlocklistStrategy {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _awardCollections;
    mapping(address => uint256) private _numberOfAwards;
    mapping(address => uint256[]) private _numberOfTokensPerAward;
    mapping(address => address) private _awardVault;


    /**
     * @notice Emitted when owner sets awards for a collection.
     */
    event ERC20AwardSet(address indexed collection, address indexed vault, uint256 numberOfAwards, uint256[] numberOfTokensPerAward);

    /**
     * @notice Emitted when owner remove awards for a collection.
     */
    event ERC20AwardRemoved(address indexed collection);

 
    event AwardedExternalERC20(
        address indexed winner,
        address indexed token,
        uint256 amount
    );

    event ErrorAwardingExternalERC20(bytes error);

    constructor(
        uint256 _prizePeriodStart,
        uint256 _prizePeriodSeconds,
        ITicket _ticket,
        IRNG _rng
    )
        PeriodicPrizeStrategy(
            _prizePeriodStart,
            _prizePeriodSeconds,
            _ticket,
            _rng
        )
    {}


    function setERC20Award(
        address collection_,
        address vault_,
        uint256 numberOfAwards_,
        uint256[] memory numberOfTokensPerAward_
    ) external onlyOwner {
        require(numberOfTokensPerAward_.length == numberOfAwards_, "Length mismatch: numberOfTokensPerAward_");
        _awardCollections.add(collection_);
        _awardVault[collection_] = vault_;
        _numberOfAwards[collection_] = numberOfAwards_;
        _numberOfTokensPerAward[collection_] = numberOfTokensPerAward_;

        emit ERC20AwardSet(collection_, vault_, numberOfAwards_, numberOfTokensPerAward_);
    }

    function removeERC20Award(address collection_) external virtual onlyOwner {
        _awardCollections.remove(collection_);
        delete _awardVault[collection_];
        delete _numberOfAwards[collection_];
        delete _numberOfTokensPerAward[collection_];

        emit ERC20AwardRemoved(collection_);
    }

    function getERC20Awards()
        public
        virtual
        view
        returns (
            uint256 numberOfWinners,
            address[] memory collections,
            uint256[] memory numberOfAwards,
            uint256[][] memory numberOfTokensPerAward,
            address[] memory vaults,
            uint256[] memory availableTokens
        )
    {
        uint256 size = _awardCollections.length();
        collections = new address[](size);
        numberOfAwards = new uint256[](size);
        numberOfTokensPerAward = new uint256[][](size);
        vaults = new address[](size);
        availableTokens = new uint256[](size);

        for (uint256 i = 0; i < size; ++i) {
            collections[i] = _awardCollections.at(i);
            numberOfAwards[i] = _numberOfAwards[collections[i]];
            numberOfTokensPerAward[i] = _numberOfTokensPerAward[collections[i]];
            vaults[i] = _awardVault[collections[i]];

            availableTokens[i] = IERC20(collections[i]).balanceOf(vaults[i]);
            uint256 _availableTokens = availableTokens[i];
            for (uint256 a = 0; a < numberOfAwards[i]; ++a) {
                if (_availableTokens < numberOfTokensPerAward[i][a]) {
                    numberOfTokensPerAward[i][a] = _availableTokens;
                    if (_availableTokens == 0) {
                        numberOfAwards[i] -= 1;
                    }
                }
                _availableTokens -= numberOfTokensPerAward[i][a];
            }

            numberOfWinners += numberOfAwards[i];
        }
    }

    /**
     * @notice Distributes captured award balance to winners
     * @dev Distributes the captured award balance to the main winner and secondary winners if __numberOfWinners greater than 1.
     * @param randomNumber Random number seed used to select winners
     */
    function _distribute(uint256 randomNumber) internal virtual override {
        if (IERC20(address(ticket)).totalSupply() == 0) {
            emit NoWinners();
            return;
        }

        (
            uint256 numberOfWinners,
            address[] memory collections,
            uint256[] memory numberOfAwards,
            uint256[][] memory numberOfTokensPerAward,
            address[] memory vaults,
        ) = getERC20Awards();

        (address[] memory winners, ) = _drawWinners(numberOfWinners, randomNumber);
        
        uint256 winnerIndex = 0;
        for (
            uint256 collectionId = 0;
            collectionId < collections.length;
            ++collectionId
        ) {
            address currentToken = collections[collectionId];
            for (
                uint256 awardId = 0;
                awardId < numberOfAwards[collectionId];
                ++awardId
            ) {
                awardExternalERC20(
                    vaults[collectionId],
                    winners[winnerIndex],
                    currentToken,
                    numberOfTokensPerAward[collectionId][awardId]
                );

                winnerIndex++;
            }
        }
    }

    function awardExternalERC20(
        address from,
        address to,
        address externalToken,
        uint256 amount
    ) internal {
        try
            IERC20(externalToken).transferFrom(
                from,
                to,
                amount
            )
        {} catch (bytes memory error) {
            emit ErrorAwardingExternalERC20(error);
        }

        emit AwardedExternalERC20(to, externalToken, amount);
    }
}