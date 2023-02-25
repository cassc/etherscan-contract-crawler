//SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SmartCard is OwnableUpgradeable {
        IERC20 public feeToken;
        address public adminWallet;

        enum CardType{Black, Diamond, Gold}

        // Mappings
        mapping(uint128 => bool) public cardNumberExists;
        mapping(CardType => uint128) public cardTypeToFees;
        mapping(uint128 => address) public cardNumberToUser;

        // Custom Errors
        error AddressZero();
        error WrongCardType();
        error CardAlreadyAdded();
        error InsufficientFunds(uint128 required, uint256 available);
        error UpdatedAddressSame(address inputAddress, address exisitingAddress);

        // Events
        event Initialized();
        event FeeTokenAdded(address indexed feeToken);
        event FeesUpdated(CardType _cardType, uint128 newFees);
        event AdminAddressChanged(address indexed newAdminAddress);
        event CardPurchased(address indexed user, uint128 cardId, uint128 fees, uint256 blockTimestamp);

        constructor() {
        _disableInitializers();
        }

        function initialize(address _adminWallet, IERC20 _tokenAddr, uint128 _feesBlack, uint128 _feesDiamond, uint128 _feesGold) external initializer {
                if (_adminWallet == address(0) || address(_tokenAddr) == address(0)) 
                        revert AddressZero();
                        
                adminWallet = _adminWallet;

                __Ownable_init();

                cardTypeToFees[CardType.Black] = _feesBlack;
                cardTypeToFees[CardType.Diamond] = _feesDiamond;
                cardTypeToFees[CardType.Gold] = _feesGold;

                feeToken = _tokenAddr;

                emit Initialized();
        }

        function purchaseCard(address _user, CardType _cardType, uint128 _cardNumber) external {
                if(cardNumberExists[_cardNumber] == true)
                        revert CardAlreadyAdded();

                IERC20 _token = feeToken;
                uint128 _fees = cardTypeToFees[_cardType];

                if (_token.balanceOf(_user) < _fees)
                        revert InsufficientFunds(_fees, _token.balanceOf(_user));

                bool success = _token.transferFrom(_user, adminWallet, _fees);
                if(!success) revert();

                cardNumberExists[_cardNumber] = true;
                cardNumberToUser[_cardNumber] = _user;

                emit CardPurchased(_user, _cardNumber, _fees, block.timestamp);
        }

        function changeFees(CardType _cardType, uint128 _newFees) external onlyOwner {
                cardTypeToFees[_cardType] = _newFees;

                emit FeesUpdated(_cardType, _newFees);
        }

        function changeAdminAddr(address _newAddress) external onlyOwner {
                if (_newAddress == address(0)) 
                        revert AddressZero();

                if (_newAddress == adminWallet)
                        revert UpdatedAddressSame(_newAddress, adminWallet);

                adminWallet = _newAddress;

                emit AdminAddressChanged(_newAddress);
        }
}