// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./DegenFlipTypes.sol";

interface IDFCoinNFT {
    function mint(address account, uint amount) external;
}

contract DegenFlipCoinMinter is Ownable, AccessControlEnumerable, ReentrancyGuard {
    enum MintType {
        FLIP, DIRECT
    }

    struct Flip {
        uint id;
        uint flippedOn;
        uint resolvedOn;
        uint randomResult;
        address account;
        bool won;
        bool refunded;
        CoinSide side;
    }

    struct ContractData {
        bool minting;
        uint8 maxFlipsPerTx;
        uint8 maxDirectMintPerTx;
        uint16 maxSupply;
        uint16 currentSupply;
        uint directPrice;
        uint directPriceWL;
        uint flipPrice;
        uint currentFlipId;
        uint lastResolvedId;
        address coinAddress;
    }

    bool public MINTING;
    uint8 public MAX_FLIPS_PER_TX = 1;
    uint8 public MAX_DIRECT_PER_TX = 10;
    uint16 public MAX_SUPPLY;
    uint16 public CURRENT_SUPPLY;
    uint public DIRECT_PRICE;
    uint public DIRECT_PRICE_WL;
    uint public FLIP_PRICE;
    uint public CURRENT_FLIP_ID;
    uint public LAST_FLIP_RESOLVED_ID;

    mapping(address => bool) private WHITELIST;
    mapping(uint => Flip) private MINT_FLIPS;

    address public COIN_NFT_ADDRESS;
    IDFCoinNFT CoinNFT;

    event Flipped(address indexed account, uint16 amount, CoinSide side, uint timestamp);
    event FundsReceived(address indexed account, uint amount, uint timestamp);
    event Minted(address indexed account, uint16 amount, uint timestamp);
    event Refunded(address indexed account, uint payment, uint timestamp);
    event Resolved(address indexed account, uint flipId, CoinSide side, bool won, uint timestamp);

    constructor(uint16 maxSupply, uint directPrice, uint directPriceWL, uint flipPrice) Ownable() {
        _grantRole(DEFAULT_ADMIN_ROLE, owner());

        MAX_SUPPLY = maxSupply;
        DIRECT_PRICE = directPrice;
        DIRECT_PRICE_WL = directPriceWL;
        FLIP_PRICE = flipPrice;
    }

    // fallback //
    receive() external payable {
        emit FundsReceived(_msgSender(), msg.value, block.timestamp);
    }

    // utils //
    modifier mintable(address account, uint16 amount, uint payment, MintType mintType) {
        require(MINTING, "Minting not started");
        require(
            amount <= (mintType == MintType.DIRECT ? MAX_DIRECT_PER_TX : MAX_FLIPS_PER_TX),
            "Cannot mint more than max per transaction"
        );
        require(CURRENT_SUPPLY + amount <= MAX_SUPPLY, "Cannot mint more than max supply");
        require(
            payment >= amount * (mintType == MintType.DIRECT ? (WHITELIST[account] ? DIRECT_PRICE_WL : DIRECT_PRICE) : FLIP_PRICE),
            "Insufficient payment"
        );
        _;
    }

    function _refund(uint flipId) internal {
        if (!MINT_FLIPS[flipId].refunded) {
            MINT_FLIPS[flipId].refunded = true;
            payable(MINT_FLIPS[flipId].account).transfer(FLIP_PRICE);

            emit Refunded(MINT_FLIPS[flipId].account, FLIP_PRICE, block.timestamp);
        }
    }

    // owner //
    function withdraw(uint amount) external onlyOwner {
        payable(owner()).transfer(amount > 0 ? amount : address(this).balance);
    }

    function activateMinter(address coin) external onlyOwner {
        COIN_NFT_ADDRESS = coin;
        CoinNFT = IDFCoinNFT(coin);
    }

    function setMinting(bool minting) external onlyOwner {
        require(COIN_NFT_ADDRESS != address(0), "Minter not activated");
        MINTING = minting;

        if (MINTING && CURRENT_SUPPLY == 0) {
            // mint 10 for airdrop
            CoinNFT.mint(owner(), 10);
            CURRENT_SUPPLY += 10;
        }
    }

    function setMaxPerTx(uint8 flips, uint8 direct) external onlyOwner {
        MAX_FLIPS_PER_TX = flips;
        MAX_DIRECT_PER_TX = direct;
    }

    function setPrices(uint directPrice, uint directPriceWL, uint flipPrice) external onlyOwner {
        DIRECT_PRICE = directPrice;
        DIRECT_PRICE_WL = directPriceWL;
        FLIP_PRICE = flipPrice;
    }

    function addWhitelist(address[] calldata wallets) external onlyOwner {
        for (uint8 _index = 0; _index < wallets.length; _index++) {
            if (!WHITELIST[wallets[_index]]) {
                WHITELIST[wallets[_index]] = true;
            }
        }
    }

    function removeWhitelist(address[] calldata wallets) external onlyOwner {
        for (uint8 _index = 0; _index < wallets.length; _index++) {
            if (WHITELIST[wallets[_index]]) {
                WHITELIST[wallets[_index]] = false;
            }
        }
    }

    // operator //
    function resolve(uint[] calldata flipIds, uint[] calldata results) external onlyRole(OPERATOR) {
        require(flipIds.length == results.length, "Number of flips and results must be the same");

        uint _now = block.timestamp;
        uint _flipId;
        uint _randomResult;
        address _account;
        bool _won;
        for (uint8 _index = 0; _index < flipIds.length; _index++) {
            _flipId = flipIds[_index];
            if (CURRENT_SUPPLY == MAX_SUPPLY) {
                _refund(_flipId);
            } else {
                _account = MINT_FLIPS[_flipId].account;
                _randomResult = results[_index]; // random number from resolver
                _won = ((_randomResult % 2) == 0 ? CoinSide.HEADS : CoinSide.TAILS) ==  MINT_FLIPS[_flipId].side; // even -> HEADS, odd -> TAILS

                if (_won) {
                    CoinNFT.mint(_account, 1);
                    CURRENT_SUPPLY += 1;
                }
            }

            MINT_FLIPS[_flipId].resolvedOn = _now;
            MINT_FLIPS[_flipId].randomResult = _randomResult;
            LAST_FLIP_RESOLVED_ID = _flipId;

            emit Resolved(_account, _flipId, MINT_FLIPS[_flipId].side, _won, _now);
        }
    }

    // public - writes //
    function mint(uint16 amount) external
    payable nonReentrant mintable(_msgSender(), amount, msg.value, MintType.DIRECT) {
        CoinNFT.mint(_msgSender(), amount);
        CURRENT_SUPPLY += amount;

        emit Minted(_msgSender(), amount, block.timestamp);
    }

    function flip(uint16 amount, CoinSide side) external
    payable nonReentrant mintable(_msgSender(), amount, msg.value, MintType.FLIP) {
        address _account = _msgSender();
        uint _now = block.timestamp;

        for (uint16 _index = 0; _index < amount; _index++) {
            CURRENT_FLIP_ID += 1;
            MINT_FLIPS[CURRENT_FLIP_ID] = Flip({
                id: CURRENT_FLIP_ID,
                flippedOn: _now,
                randomResult: 0,
                resolvedOn: 0,
                account: _account,
                side: side,
                won: false,
                refunded: false
            });
        }

        emit Flipped(_account, amount, side, _now);
    }

    // public - views //
    function whitelisted(address wallet) external view returns(bool) {
        return WHITELIST[wallet];
    }

    function contractData() external view returns (ContractData memory) {
        return ContractData({
            minting: MINTING,
            maxFlipsPerTx: MAX_FLIPS_PER_TX,
            maxDirectMintPerTx: MAX_DIRECT_PER_TX,
            maxSupply: MAX_SUPPLY,
            currentSupply: CURRENT_SUPPLY,
            directPrice: DIRECT_PRICE,
            directPriceWL: DIRECT_PRICE_WL,
            flipPrice: FLIP_PRICE,
            currentFlipId: CURRENT_FLIP_ID,
            lastResolvedId: LAST_FLIP_RESOLVED_ID,
            coinAddress: COIN_NFT_ADDRESS
        });
    }
}