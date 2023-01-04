pragma solidity ^0.8.12;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol';

contract TayarraStorage {
    struct Vars {
        mapping(address => bool) whitelistedAddressesForClaim;
        mapping(address => bool) whitelistedAddressesForPause;
        mapping(address => bool) whitelistedAddressesForFees;
        mapping(address => bool) blacklistedAddresses;
    }

    function vars() internal pure returns(Vars storage ds) {
        bytes32 storagePosition = keccak256("diamond.storage.AccessControlUpgradeable");
        assembly {ds.slot := storagePosition}
        return ds;
    }

    address constant MARKETING_WALLET =        0xe44a66C45C33021E0d2E98Cb3a7368E18e7813F4;
    address constant DEVELOPMENT_WALLET =      0x49B2c763aa0c22d0446b581D551FE58fee29b633;
    address constant LIQUIDITY_WALLET =        0x09b76532bDC76F4a7f3b9b5fA77553b7EcC620B2;

    address constant ROUTER_ADDRESS_MAINNET =  0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant ROUTER_ADDRESS_TESTNET =  0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    
    uint256 constant MARKETING_TAX_BUY =        4;
    uint256 constant DEVELOPMENT_TAX_BUY =      3;
    uint256 constant LIQUIDITY_TAX_BUY =        1;

    uint256 constant MARKETING_TAX_SELL =       5;
    uint256 constant DEVELOPMENT_TAX_SELL =     3;
    uint256 constant LIQUIDITY_TAX_SELL =       2;
}

contract TayarraCoin is TayarraStorage, Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    
    constructor() {
        _disableInitializers();
    }

    IUniswapV2Router02 uniswapV2Router;
    IUniswapV2Factory uniswapV2Factory;

    function initialize() initializer public {
        __ERC20_init("Tayarra Hub", "THUB");
        __ERC20Burnable_init();
        __Ownable_init();
        uniswapV2Router = IUniswapV2Router02(getPancakeSwapRouterAddress());
        uniswapV2Factory = IUniswapV2Factory(uniswapV2Router.factory());
    }

    
    receive() external payable {}

    function mintWholeCoins(address to, uint256 amount) public onlyOwner {
        mint(to, amount * 10**decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(isUserWhitelistedForClaim(to), "You are not whitelisted to perform mint operation");
        _mint(to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!isNotPermitted(from, to), "Transfers may not be available at this time using this address.");
        require(!isUserBlacklisted(from) && !isUserBlacklisted(to), "Address is black listed by Owner");

        uint256 marketingFeeBuy = amount * MARKETING_TAX_BUY / 100;
        uint256 developmentFeeBuy = amount * DEVELOPMENT_TAX_BUY / 100;
        uint256 liquidityFeeBuy = amount * LIQUIDITY_TAX_BUY / 100;

        uint256 marketingFeeSell = amount * MARKETING_TAX_SELL / 100;
        uint256 developmentFeeSell = amount * DEVELOPMENT_TAX_SELL / 100;
        uint256 liquidityFeeSell = amount * LIQUIDITY_TAX_SELL / 100;

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }

        if (isPair(from) && (to != owner() || !isUserWhitelistedForFees(to) || !isUserWhitelistedForLaunch(to))) {
            
            _balances[MARKETING_WALLET] += marketingFeeBuy;
            _balances[DEVELOPMENT_WALLET] += developmentFeeBuy;
            _balances[LIQUIDITY_WALLET] += liquidityFeeBuy;

            uint256 remainder = amount - marketingFeeBuy - developmentFeeBuy - liquidityFeeBuy;
            require(remainder + marketingFeeBuy + developmentFeeBuy + liquidityFeeBuy == amount, "tax calculated incorrectly");
            _balances[to] += remainder;
        } else if (isPair(to) && (from != owner() || !isUserWhitelistedForFees(from)) || !isUserWhitelistedForLaunch(from)) {
            
            _balances[MARKETING_WALLET] += marketingFeeSell;
            _balances[DEVELOPMENT_WALLET] += developmentFeeSell;
            _balances[LIQUIDITY_WALLET] += liquidityFeeSell;

            uint256 remainder = amount - marketingFeeSell - developmentFeeSell - liquidityFeeSell;
            require(remainder + marketingFeeSell + developmentFeeSell + liquidityFeeSell == amount, "tax calculated incorrectly");
            _balances[to] += remainder;
        } else {
            
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    
    
    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    
    function getBalance() public view returns (uint256) {
        return balanceOf(msg.sender);
    }

    function isNotPermitted(address from, address to) private view returns(bool) {
        if (callerIsOwner() || isUserWhitelistedForPause(_msgSender())
        || isOwner(from) || isOwner(to)
        || isUserWhitelistedForPause(from) || isUserWhitelistedForPause(to)) {
            return false;
        }
        return paused();
    }

    
    function getPancakeSwapRouterAddress() private view returns (address) {
        if (isTestnet()) {
            return ROUTER_ADDRESS_TESTNET;
        }
        return ROUTER_ADDRESS_MAINNET;
    }

    function getRouter() private view returns (IUniswapV2Router02) {
        return uniswapV2Router;
    }

    function getPair() private view returns (address pair) {
        address uniswapPair = uniswapV2Factory.getPair(address(this),uniswapV2Router.WETH()); 
        return uniswapPair;
    }

    function isPair(address _addressToCheck) private view returns (bool) {
        if (_addressToCheck == address(0)) {
            return false;
        }
        return _addressToCheck == getPair();
    }

    
    function getChainId() private view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    function isTestnet() private view returns (bool) {
        return getChainId() == 97;
    }

    function isOwner(address _addressToCheck) private view returns (bool) {
        return _addressToCheck == owner();
    }

    function callerIsOwner() private view returns (bool) {
        return _msgSender() == owner();
    }

    
    function addWhitelistedUser(address _addressToWhitelist) public onlyOwner {
        vars().whitelistedAddressesForClaim[_addressToWhitelist] = true;
    }

    function removeWhitelistedUser(address _addressToWhitelist) public onlyOwner {
        vars().whitelistedAddressesForClaim[_addressToWhitelist] = false;
    }

    function addBlacklistedUser(address _addressToBlacklist) public onlyOwner {
        vars().blacklistedAddresses[_addressToBlacklist] = true;
    }

    function removeBlacklistedUser(address _addressToBlacklist) public onlyOwner {
        vars().blacklistedAddresses[_addressToBlacklist] = false;
    }

    function addPauseWhitelistedUser(address _addressToWhitelist) public onlyOwner {
        vars().whitelistedAddressesForPause[_addressToWhitelist] = true;
    }

    function removePauseWhitelistedUser(address _addressToWhitelist) public onlyOwner {
        vars().whitelistedAddressesForPause[_addressToWhitelist] = false;
    }

    function addFeesWhitelistedUser(address _addressToWhitelist) public onlyOwner {
        vars().whitelistedAddressesForFees[_addressToWhitelist] = true;
    }

    function removeFeesWhitelistedUser(address _addressToWhitelist) public onlyOwner {
        vars().whitelistedAddressesForFees[_addressToWhitelist] = false;
    }

    function addLaunchWhitelistedUser(address _addressToWhitelist) public onlyOwner {
        addPauseWhitelistedUser(_addressToWhitelist);
        addFeesWhitelistedUser(_addressToWhitelist);
    }

    function removeLaunchWhitelistedUser(address _addressToWhitelist) public onlyOwner {
        removePauseWhitelistedUser(_addressToWhitelist);
        removeFeesWhitelistedUser(_addressToWhitelist);
    }

    function isUserWhitelistedForClaim(address _addressToCheck) public view returns(bool) {
        bool userIsWhitelistedForClaim = vars().whitelistedAddressesForClaim[_addressToCheck];
        return userIsWhitelistedForClaim || isOwner(_addressToCheck);
    }

    function isUserWhitelistedForPause(address _addressToCheck) public view returns(bool) {
        bool userIsWhitelistedForPause = vars().whitelistedAddressesForPause[_addressToCheck];
        return userIsWhitelistedForPause || isOwner(_addressToCheck);
    }

    function isUserWhitelistedForFees(address _addressToCheck) public view returns(bool) {
        bool userIsWhitelistedForFees = vars().whitelistedAddressesForFees[_addressToCheck];
        return userIsWhitelistedForFees || isOwner(_addressToCheck);
    }

    function isUserWhitelistedForLaunch(address _addressToCheck) public view returns(bool) {
        bool userIsWhitelistedForPause = vars().whitelistedAddressesForPause[_addressToCheck];
        bool userIsWhitelistedForFees = vars().whitelistedAddressesForFees[_addressToCheck];
        return (userIsWhitelistedForPause && userIsWhitelistedForFees) || isOwner(_addressToCheck);
    }

    function isUserBlacklisted(address _addressToCheck) public view returns(bool) {
        bool userIsBlacklisted = vars().blacklistedAddresses[_addressToCheck];
        return userIsBlacklisted;
    }
}