// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IClashFantasyVault {
    function withdraw(address _to, uint256 _amount, uint256 _hasNfts) external;
}

interface IClashFantasyCards {
    function getInternalUserTokenById(address from, uint256 tokenId)
        external
        view
        returns (
            uint256 _amount,
            uint256 _aditionalId,
            uint256 _manaPower,
            uint256 _hasMana,
            uint256 _fansyExtra,
            uint256 _cardLevel,
            uint256 _energy,
            uint256 _typeOf
        );

    function updateCardEnergyBatch(uint256[] memory _tokenId, address _from) external;
    function getCountUserToken(address _address) external view returns(uint256);
}

interface IClashFantasyDecks {
    function updateDeckState(
        address _from,
        uint256 _tokenId,
        uint256 _state
    ) external;

    function getDeckById(address _from, uint256 _tokenId)
        external
        view
        returns (
            uint256, // typeOf
            uint256, // deckLevel
            uint256, // activatePoint
            uint256, // manaSum
            uint256, // fansySum
            uint256, // deckState,
            uint256  // amount
            
        );



    function getCardsInDeckArr(uint256 _tokenId) external view returns (uint256[] memory);

    function updateDeckEnergy(uint256 _tokenId, address _from) external;
}

contract ClashFantasyMiniGameV5 is Initializable {
    address private adminContract;
    IClashFantasyDecks private contractDeck;
    IClashFantasyCards private contractCard;
    IClashFantasyVault private contractVault;
    IERC20 private contractErc20;
    address private walletPrimary;
    address private walletSecondary;
    uint256 private random;

    struct RewardTable {
        uint256 manaPowerAllow;
        uint256 percentage;
        uint256 reward;
    }

    struct DeckTime {
        uint256 lastActivated;
        bool result;
        uint256 reward;
    }
    mapping(uint256 => DeckTime[]) private deckTimeArr;
    mapping(address => uint256) private withdrawLastArr;
    mapping(address => uint256) private rewardArr;
    mapping(uint256 => mapping(address => int256)) private arenaRankingArr;

    RewardTable[] private rangeGame;
    uint256 prePercentageTax;
    uint256 percentageTax;
    address private walletTax;

    address private externalUpdater;

    modifier checkTimeDeckCanPlay(uint256 _tokenId) {
        if (deckTimeArr[_tokenId].length == 0) {
            _;
        } else {
            uint256 _last = deckTimeArr[_tokenId][deckTimeArr[_tokenId].length - 1].lastActivated;
            if (_last != 0) {
                require(_last + 1 days <= block.timestamp, "Locked");
            }
            _;
        }
    }

    modifier onlyAdminOwner() {
        require(
            adminContract == msg.sender,
            "Only the contract admin owner can call this function"
        );
        _;
    }

    modifier onlyExternalUpdater() {
        require(externalUpdater == msg.sender, "ClashFantasyMiniGame contract invalid updater");
        _;
    }

    function initialize(IClashFantasyDecks _contractDeck, IClashFantasyCards _contractCard)
        public
        initializer
    {
        adminContract = msg.sender;
        contractDeck = _contractDeck;
        contractCard = _contractCard;
    }

    function withdraw(uint256 _amount) public {
        require(withdrawLastArr[msg.sender] + 1 days <= block.timestamp, "withdraw Locked");
        uint256 amount = _amount * 10**16;
        require(rewardArr[msg.sender] >= amount, "Wallet Balance insuficent");
        rewardArr[msg.sender] -= amount;
        contractVault.withdraw(msg.sender, amount, contractCard.getCountUserToken(msg.sender));
        withdrawLastArr[msg.sender] = block.timestamp;
    }

    function playClickToEarn(uint256 _arenaSelected, uint256 _deckTokenId)
        public
        checkTimeDeckCanPlay(_deckTokenId)
    {
        (   ,
            ,
            uint256 _activatePoint,
            uint256 _manaSum,
            uint256 _fansySum,
            uint256 _deckState,
            uint256 cardAmount
        ) = contractDeck.getDeckById(msg.sender, _deckTokenId);
        
        uint256 reward = rangeGame[_arenaSelected].reward * 10**18;
        uint256 amount = ((((reward * _fansySum) / 100) + reward) * prePercentageTax) / 100;
        preGameTax(amount);

        require(cardAmount == 8, "checkCanPlay: Deck must have eight cards");
        require(_deckState == 1, "checkCanPlay: Deck must be enabled");
        require(_activatePoint >= 1, "Deck need more energy");
        require(
            rangeGame[_arenaSelected].manaPowerAllow <= _manaSum,
            "Deck Need more Mana to Play in this arena"
        );
        (bool canPlay, uint256[] memory _cardsToUpdate) = checkCanPlay(_deckTokenId);
        require(canPlay == true, "Cards in deck need more energy");
        random++;
        bool success = checkFail(rangeGame[_arenaSelected].percentage);
        uint256 _reward = 0;
        if (success) {
            rewardArr[msg.sender] += (((reward * _fansySum) / 100) + reward);
            _reward = (((reward * _fansySum) / 100) + reward);
        }
        
        contractCard.updateCardEnergyBatch(_cardsToUpdate, msg.sender);
        contractDeck.updateDeckEnergy(_deckTokenId, msg.sender);
        deckTimeArr[_deckTokenId].push(DeckTime(block.timestamp, success, _reward));
    }

    function getLastTimeDeckPlayed(uint256 _tokenId)
        public
        view
        returns (
            uint256,
            bool,
            uint256
        )
    {
        uint256 index = deckTimeArr[_tokenId].length;
        if (index == 0) {
            return (0, false, 0);
        }
        index = index - 1;
        if (index >= deckTimeArr[_tokenId].length) {
            return (0, false, 0);
        } else {
            return (
                deckTimeArr[_tokenId][index].lastActivated,
                deckTimeArr[_tokenId][index].result,
                deckTimeArr[_tokenId][index].reward
            );
        }
    }

    function changeFromGame(uint256 _amount) public {
        require(rewardArr[msg.sender] >= _amount, "Wallet Balance insuficent");
        rewardArr[msg.sender] -= _amount;
    }

    //internal
    function checkCanPlay(uint256 _deckTokenId) internal view returns (bool, uint256[] memory) {
        bool can = true;
        uint256[] memory cards = contractDeck.getCardsInDeckArr(_deckTokenId);
        for (uint256 index = 0; index < cards.length; index++) {
            (, , , , , , uint256 _energy, ) = contractCard.getInternalUserTokenById(
                msg.sender,
                cards[index]
            );
            if (_energy == 0) {
                can = false;
            }
        }
        return (can, cards);
    }

    function preGameTax(uint256 _amount) internal {
        uint256 balance = contractErc20.balanceOf(msg.sender);
        require(balance >= _amount, "preGameTax: Check the token balance");

        uint256 allowance = contractErc20.allowance(msg.sender, address(this));
        require(allowance == _amount, "preGameTax: Check the token allowance");

        uint256 toTaxWallet = (_amount / uint256(100)) * percentageTax;
        uint256 normalTransfer = (_amount / uint256(100)) * uint256( 100 - percentageTax );
        uint256 half = normalTransfer / 2;

        contractErc20.transferFrom(msg.sender, walletTax, toTaxWallet);
        contractErc20.transferFrom(msg.sender, walletPrimary, half);
        contractErc20.transferFrom(msg.sender, walletSecondary, half);
    }

    function checkFail(uint256 _percentage) internal view returns (bool) {
        uint256[] memory myArray = new uint256[](100);
        for (uint256 j = 0; j < _percentage; j++) {
            if (j < _percentage) {
                myArray[j] = 1;
            }
        }
        uint256 purchasenumber = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, random))
        ) % 100;
        bool success = false;

        if (myArray[purchasenumber] == 1) {
            success = true;
        }
        return (success);
    }

    //public view
    function getPercentageTax() public view returns(uint256) {
        return prePercentageTax;
    }

    function getRewardWallet(address _address) public view returns (uint256) {
        return (rewardArr[_address]);
    }

    function getLastWithdrawAdd(address _from) public view returns (uint256) {
        return withdrawLastArr[_from];
    }

    function getDeckPlayed(uint256 _tokenId) public view returns (DeckTime[] memory) {
        return deckTimeArr[_tokenId];
    }

    function getRangeGame() public view returns (RewardTable[] memory) {
        return rangeGame;
    }

    function getWalletVault() public view returns (address, address) {
        return (walletPrimary, walletSecondary);
    }

    //protected
    function updatePrePercentage(uint256 _prePercentageTax) public onlyAdminOwner {
        prePercentageTax = _prePercentageTax;
    }

    function setPercentageTax(uint256 _percentageTax) public onlyAdminOwner {
        percentageTax = _percentageTax;
    }

    function setWalletTax(address _walletTax) public onlyAdminOwner {
        walletTax = _walletTax;
    }

    function setContractErc20(IERC20 _contractErc20) public onlyAdminOwner {
        contractErc20 = _contractErc20;
    }

    function setVaultContract(IClashFantasyVault _contractVault) public onlyAdminOwner {
        contractVault = _contractVault;
    }

    function setWalletPrimary(address _address) public onlyAdminOwner {
        walletPrimary = _address;
    }

    function setWalletSecondary(address _address) public onlyAdminOwner {
        walletSecondary = _address;
    }

    function setExternalUpdater(address _contract) public onlyAdminOwner {
        externalUpdater = _contract;
    }

    function revokeWallet(address _address) public onlyAdminOwner {
        rewardArr[_address] = 0;
    }

    function setRangeGame(
        uint256[] memory _manaPowerAllow,
        uint256[] memory _percentage,
        uint256[] memory _reward
    ) public onlyAdminOwner {
        delete rangeGame;
        for (uint256 index = 0; index < _manaPowerAllow.length; index++) {
            RewardTable memory room = RewardTable(
                _manaPowerAllow[index],
                _percentage[index],
                _reward[index]
            );
            rangeGame.push(room);
        }
    }

    //only external
    function claimFromGame(address _address, uint256 _amount) public onlyExternalUpdater {
        rewardArr[_address] += _amount;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}