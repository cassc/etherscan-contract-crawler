// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Rescueable.sol";

interface IERC1155Mintable {
    function mintBatch(
        address to,
        uint256[] memory id,
        uint256[] memory amount,
        bytes memory data
    ) external;
}

interface IERC721Mintable {
    function mint(address to) external;
}

interface IBurnable is IERC20 {
    function burn(uint256 amount) external;
}

contract BomberzillaChest is Rescueable {
    using SafeERC20 for IBurnable;

    uint256 private nonce;
    IERC721Mintable public characterNFT;
    IERC1155Mintable public assetsNFT;

    address public paymentRecipient;
    IBurnable public paymentToken;

    uint256 public burnPercent = 8000; // 80%

    uint256 public characterChestPrice;
    uint256 public skinsChestPrice;
    uint256 public mixChestPrice;

    uint256 public minSkinTokenId = 0;
    uint256 public maxSkinTokenId = 658;

    uint256 public freeMintLimit = 10000;
    uint256 public freeMintCount = 0;
    mapping (address => bool) public freeMinted;
    bool public freeMintPaused = false;

    event CharacterChestBought(address indexed user, uint256 quantity);
    event SkinsChestBought(address indexed user, uint256 quantity);
    event MixChestBought(address indexed user, uint256 quantity);

    event CharacterChestPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event SkinsChestPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event MixChestPriceUpdated(uint256 oldPrice, uint256 newPrice);

    event PaymentRecipientUpdated(address oldPaymentRecipient, address newPaymentRecipient);
    event PaymentTokenUpdated(address oldPaymentToken, address newPaymentToken);

    event FreeMintLimitUpdated(uint256 newFreeMintLimit);
    event FreeMintPaused(bool value);
    event FreeMint(address indexed user);

    constructor(
        IERC721Mintable _characterNFT, // ERC721
        IERC1155Mintable _assetsNFT, // 1155
        address _paymentRecipient,
        IBurnable _paymentToken,
        uint256 _characterChestPrice,
        uint256 _skinsChestPrice,
        uint256 _mixChestPrice,
        uint256 _freeMintLimit
    ) {
        characterNFT = _characterNFT;
        assetsNFT = _assetsNFT;
        setPaymentRecipient(_paymentRecipient);
        setPaymentToken(_paymentToken);
        setCharacterChestPrice(_characterChestPrice);
        setSkinsChestPrice(_skinsChestPrice);
        setMixChestPrice(_mixChestPrice);
        setFreeMintLimit(_freeMintLimit);        
    }

    function buyCharacterChest(uint256 quantity) external payable {
        if (isFreeMintAvailable(_msgSender())) {
            paymentTransfer(msg.sender, characterChestPrice * quantity);
        } else {
            require(quantity == 1, "BomberzillaChest: Free mint is available only for 1 chest");
            require(msg.value == 0, "BomberzillaChest: BNB not required for free mint");
            freeMintCount += 1;
            freeMinted[msg.sender] = true;
            emit FreeMint(_msgSender());
        }
        _openCharacterChest(quantity, msg.sender);
    }

    function buySkinsChest(uint256 quantity) external payable {
        paymentTransfer(msg.sender, skinsChestPrice * quantity);
        _openSkinChest(quantity, msg.sender);
    }

    function buyMixChest(uint256 quantity) external payable {
        paymentTransfer(msg.sender, mixChestPrice * quantity);
        for (uint256 i = 0; i < quantity; i++) {
            if (getRandomNumber(0, 1) == 0) {
                _openCharacterChest(1, msg.sender);
            } else {
                _openSkinChest(1, msg.sender);
            }
        }
        emit MixChestBought(msg.sender, quantity);
    }

    function _openCharacterChest(uint256 quantity, address user) internal {
        for (uint256 i = 0; i < quantity; i++) {
            characterNFT.mint(user);
        }
        emit CharacterChestBought(user, quantity);
    }

    function _openSkinChest(uint256 quantity, address user) internal {
        uint256[] memory tokensIds = new uint256[](quantity);
        uint256[] memory amounts = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            tokensIds[i] = getRandomNumber(minSkinTokenId, maxSkinTokenId);
            amounts[i] = 1;
        }
        assetsNFT.mintBatch(user, tokensIds, amounts, "");

        emit SkinsChestBought(user, quantity);
    }

    function setPaymentRecipient(address _paymentRecipient) public onlyOwner {
        emit PaymentRecipientUpdated(paymentRecipient, _paymentRecipient);
        paymentRecipient = _paymentRecipient;
    }

    function setPaymentToken(IBurnable _paymentToken) public onlyOwner {
        emit PaymentTokenUpdated(address(paymentToken), address(_paymentToken));
        paymentToken = _paymentToken;
    }

    function setCharacterChestPrice(uint256 _price) public onlyOwner {
        emit CharacterChestPriceUpdated(characterChestPrice, _price);
        characterChestPrice = _price;
    }

    function setSkinsChestPrice(uint256 _price) public onlyOwner {
        emit CharacterChestPriceUpdated(skinsChestPrice, _price);
        skinsChestPrice = _price;
    }

    function setMixChestPrice(uint256 _price) public onlyOwner {
        emit CharacterChestPriceUpdated(mixChestPrice, _price);
        mixChestPrice = _price;
    }

    function paymentTransfer(address user, uint256 amount) internal {
        if (address(paymentToken) != address(0)) {
            require(msg.value == 0, "BNB Not Allowed");
            uint256 burnAmount = (amount * burnPercent) / 10000;
            paymentToken.safeTransferFrom(user, paymentRecipient, amount - burnAmount);
            // need to transfer tokens to this contract first before burning
            paymentToken.safeTransferFrom(user, address(this), burnAmount);
            paymentToken.burn(burnAmount);
        } else {
            require(msg.value == amount, "Invalid amount");
            payable(paymentRecipient).transfer(amount);
        }
    }

    function setSkinsTokenIdRange(uint256 min, uint256 max) external onlyOwner {
        minSkinTokenId = min;
        maxSkinTokenId = max;
    }

    function getRandomNumber(uint256 min, uint256 max) internal returns (uint256) {
        if (max == 0) return 0;
        return
            (uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, nonce++))) % (max + 1)) +
            min;
    }

    function setFreeMintLimit(uint256 _freeMintLimit) public onlyOwner {
        freeMintLimit = _freeMintLimit;
        emit FreeMintLimitUpdated(_freeMintLimit);
    }   

    function setFreeMintPaused(bool _value) public onlyOwner {
        freeMintPaused = _value;
        emit FreeMintPaused(_value);
    }

    function isFreeMintAvailable(address _account) public view returns (bool) {
        if(freeMintCount >= freeMintLimit || freeMinted[_account] || freeMintPaused)
        return false;
        else return true;
    }
}