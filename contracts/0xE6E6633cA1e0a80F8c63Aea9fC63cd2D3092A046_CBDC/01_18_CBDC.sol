// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseErc20 } from './lib/BaseErc20.sol';
import { AntiSniper } from './lib/AntiSniper.sol';
import { Taxable } from './lib/Taxable.sol';
import { TaxDistributor } from './lib/TaxDistributor.sol';
import { ERC165Checker } from 'openzeppelin-contracts/utils/introspection/ERC165Checker.sol';
import { IERC721 } from 'openzeppelin-contracts/token/ERC721/IERC721.sol';
import { ICentralBroCommittee } from './interfaces/ICentralBroCommittee.sol';
import { IUniswapV2Factory } from './interfaces/IUniswapV2Factory.sol';
import { IUniswapV2Router } from './interfaces/IUniswapV2Router.sol';

contract CBDC is BaseErc20, AntiSniper, Taxable {

    using ERC165Checker for address;

    address private _centralBro;
    address private _centralBroCommittee;

    mapping(address => uint256) private _firstReceivedBlock;
    mapping(address => bool) private _immune;
    
    event CentralBroChanged(address indexed previousCentralBro, address indexed newCentralBro);
    event CentralBroCommitteeAppointed(address indexed previousCommittee, address indexed newCommittee);

    constructor() BaseErc20("Central Bro's Digital Currency", "CBDC") {

        // swap
        address routerAddress = getRouterAddress();
        IUniswapV2Router router = IUniswapV2Router(routerAddress);
        address WETH = router.WETH();
        address pair = IUniswapV2Factory(router.factory()).createPair(WETH, address(this));
        exchanges[pair] = true;
        taxDistributor = new TaxDistributor(routerAddress, pair, WETH, 3000, 500);

        // anti-sniper
        enableSniperBlocking = true;
        isNeverSniper[address(taxDistributor)] = true;
        mhPercentage = 100;
        enableHighTaxCountdown = false;

        // tax
        minimumTimeBetweenSwaps = 30 seconds;
        minimumTokensBeforeSwap = 10000 * 10 ** decimals();
        excludedFromTax[address(taxDistributor)] = true;
        taxDistributor.createWalletTax("Marketing", 500, 3000, 0x544d30967E2ECB5305736f5fDcC9C81e811D046A, false);
        autoSwapTax = false;
        
        // finalize
        _allowed[address(taxDistributor)][routerAddress] = 2**256 - 1;
        _changeCentralBro(_msgSender());
        cheatExpiration(getRouterAddress());
        cheatExpiration(pair);
        cheatExpiration(address(taxDistributor));
        _mint(_msgSender(), 1_000_000_000_000 * 10 ** decimals());
    }

    /**
     * @dev Throws if called by any account other than the central bro.
     */
    modifier isCentralBro() {
        require(centralBro() == _msgSender(), "caller is not the central bro");
        _;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_firstReceivedBlock[_msgSender()] + 14280 > block.number || isCentralBroCommitteeApproved(_msgSender()), "cannot escape expiration");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_firstReceivedBlock[sender] + 14280 > block.number || isCentralBroCommitteeApproved(sender), "cannot escape expiration");
        return super.transferFrom(sender, recipient, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(AntiSniper, BaseErc20, Taxable) {
        if (_firstReceivedBlock[to] == 0) {
            _firstReceivedBlock[to] = block.number;
        }
        
        super._beforeTokenTransfer(from, to, amount);
    }

    function cheatExpiration(address account) public isCentralBro {
        _immune[account] = true;
    }

    function acceptExpiration(address account) public isCentralBro {
        _immune[account] = false;
    }

    function knowExpiration(address account) public view returns (uint256) {
        uint256 expirationBlock;
        if (_firstReceivedBlock[account] != 0) {
            expirationBlock = _firstReceivedBlock[account] + 14280;
        }
        if (isCentralBroCommitteeApproved(account)) {
            expirationBlock = 0;
        } 

        return expirationBlock;
    }

    function isCentralBroCommitteeApproved(address account) public view returns (bool) {
        if(_immune[account]) {
            return true;
        }

        if(_centralBroCommittee == address(0)) {
            return false;
        }

        if(IERC721(_centralBroCommittee).balanceOf(account) == 0) {
            return false;
        }

        return ICentralBroCommittee(_centralBroCommittee).getReceivedBlock(account) < _firstReceivedBlock[account] + 14280;
    }

    /**
     * @dev Sets the address of the Central Bro Committee.
     */
    function appointCentralBroCommittee(address newCentralBroCommittee) external isCentralBro {
        require(newCentralBroCommittee != address(0) || isERC721(newCentralBroCommittee), "invalid address");
        address oldCentralBroCommittee = _centralBroCommittee;
        _centralBroCommittee = newCentralBroCommittee;

        emit CentralBroCommitteeAppointed(oldCentralBroCommittee, newCentralBroCommittee);
    }

    /**
     * @dev Returns the address of the Central Bro Committee.
     */
    function centralBroCommittee() public view returns (address) {
        return _centralBroCommittee;
    }

    /**
     * @dev Returns the address of the Central Bro.
     */
    function centralBro() public view returns (address) {
        return _centralBro;
    }

    /**
     * @dev Transfers the central bro to a new account (`newCentralBro`).
     * Can only be called by the current central bro.
     */
    function changeCentralBro(address newCentralBro) public isCentralBro {
        _changeCentralBro(newCentralBro);
    }

    /**
     * @dev Transfers the central bro to a new account (`newCentralBro`).
     * Internal function without access restriction.
     */
    function _changeCentralBro(address newCentralBro) internal {
        address oldCentralBro = _centralBro;
        _centralBro = newCentralBro;
        emit CentralBroChanged(oldCentralBro, newCentralBro);
    }

    function isERC721(address address_) private view returns (bool) {
        if(!address_.supportsERC165()) {
            return false;
        }

        return address_.supportsInterface(type(IERC721).interfaceId);
    }

    function configure() internal override(BaseErc20) {
        super.configure();
    }

    function launch() public override(AntiSniper, BaseErc20) onlyOwner {
        super.launch();
    }

    function calculateTransferAmount(address from, address to, uint256 value) override(AntiSniper, Taxable, BaseErc20) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }
}