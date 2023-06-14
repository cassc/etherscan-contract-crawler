//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract BlockifyGamesToken is ERC20, Ownable {
    bool private _enableGateKeeper;
    bool private _tradingEnabled;
    bool private _enableTransactionLimit;
    IERC1155 private _gateKeeperCollection;
    uint256 private _gateKeeperNftId;
    uint256 private _gateKeeperNftAmount;
    uint256 private _gateKeeperMaxTokenAmount;
    address private _deployer;
    mapping(address => uint256) private _lastBuyBlock;

    constructor()
    ERC20(
        "Blockify.Games",
        "BLOCKIFY"
    ) {
        _deployer = msg.sender;

        _mint(
            msg.sender,
            1_000_000_000_000 ether
        );

        // Shortly after our initial launch, we will disable the gatekeeper and turn this into a regular, vanilla ERC20 token.
        // Once disabled, there is no way to turn it back on...
        _enableGateKeeper = true;

        // This allows us to test the contract after adding liquidity, without people actually buying things (in case we get something wrong)
        // Once trading is enabled, it can never be disabled again.
        _tradingEnabled = false;

        _enableTransactionLimit = true;
    }

    function isTradingEnabled() public view returns (bool) {
        return _tradingEnabled;
    }

    function isGateKeeperEnabled() public view returns (bool) {
        return _enableGateKeeper && _gateKeeperNftId != 0;
    }

    function isGateKeeperPermanentlyDisabled() public view returns (bool) {
        return !_enableGateKeeper;
    }

    function enableTrading() public onlyOwner {
        _tradingEnabled = true;
    }

    function permanentlyDisableTransactionLimit() public onlyOwner {
        _enableTransactionLimit = false;
    }

    function permanentlyDisarmUniswapGateKeeper() public onlyOwner {
        _enableGateKeeper = false;
    }

    function setupGateKeeper(IERC1155 collection, uint256 nftId, uint256 nftAmount, uint256 maxTokenAmount) public onlyOwner {
        if (collection == IERC1155(address(0))) {
            require(nftId == 0);
            require(nftAmount == 0);
            require(maxTokenAmount == 0);
        } else {
            require(nftId > 0);
            require(nftAmount > 0);
            require(maxTokenAmount > 0);
        }

        _gateKeeperCollection = collection;
        _gateKeeperNftId = nftId;
        _gateKeeperNftAmount = nftAmount;
        _gateKeeperMaxTokenAmount = maxTokenAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        require(_tradingEnabled || from == _deployer || to == _deployer, "Trading is not enabled yet. Refer to our Telegram for further information.");

        if (!isGateKeeperEnabled()) {
            // once disabled, we are just a vanilla ERC20 token...
            return;
        }

        // buying from Uniswap and transferring between wallets requires a certain amount of a specific NFT
        uint256 actualNftAmount = _gateKeeperCollection.balanceOf(to, _gateKeeperNftId);

        require(actualNftAmount >= _gateKeeperNftAmount, "Buy blocked by gatekeeper. Target wallet does not own enough of our NFTs. Refer to our Telegram for further information. This restriction will be lifted in a few hours.");

        if (_enableTransactionLimit) {
            require(amount <= _gateKeeperMaxTokenAmount * (1 ether), "Buy blocked by gatekeeper. Token limit per transaction exceeded. Refer to our Telegram for further information. This restriction will be lifted in a few hours.");
            require(_lastBuyBlock[to] < block.number, "Buy blocked by gatekeeper. You can only buy once per block. Refer to our Telegram for further information. This restriction will be lifted in a few hours.");

            _lastBuyBlock[to] = block.number;
        }
    }
}