// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/uniswapv2.sol";
import "./interfaces/ivault.sol";


contract MasterSuperVault is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => bool) public whiteList;

    address public immutable capitalToken;

    uint256 public maxCap = 0;
    
    address public constant pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // mainnet v2

    uint256 public constant pancakeswapSlippage = 10;

    uint public constant VAULT_COUNT = 5;

    address [] public vaults;

    string public vaultName;

    address public strategist;

    address public addrFactory;

    event FundTransfer(address, uint256);
    event Received(address, uint);
    event ParameterUpdated(uint256);
    event FactoryAddressUpdated(address);
    event StrategistAddressUpdated(address);
    event WhiteListAdded(address);
    event WhiteListRemoved(address);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    constructor(
        string memory _name, 
        address _capitalToken,
        uint256 _maxCap
    )
        ERC20(
            string(abi.encodePacked("xUBXT_", _name)), 
            string(abi.encodePacked("xUBXT_", _name))
        )
    {
        require(_capitalToken != address(0), "_capitalToken zero address");

        capitalToken = _capitalToken;
        vaultName = _name;
        maxCap = _maxCap;
        strategist = address(0);

        whiteList[msg.sender] = true;
    }

    function setParameters(
        uint256 _maxCap
    ) external onlyOwner {
        
        maxCap = _maxCap;

        emit ParameterUpdated(maxCap);
    }

    // Send remanining BNB (used for paraswap integration) to other wallet
    function fundTransfer(address receiver, uint256 amount) external onlyOwner {
        
        require(receiver != address(0), "receiver zero address");

        // payable(receiver).transfer(amount);
        (bool sent, ) = receiver.call{value: amount}("");
        require(sent, "Failed to send Fund");

        emit FundTransfer(receiver, amount);
    }

    function poolSize() public view returns (uint256) {

        if (vaults.length < VAULT_COUNT) return 0;

        uint256[] memory amounts;
        address[] memory path = new address[](2);    
        path[1] = capitalToken;    

        uint256 _poolSize = 0;

        for (uint i = 0; i < VAULT_COUNT; i++) {
            uint256 shares = IERC20(vaults[i]).balanceOf(address(this));
            uint256 subPoolSize = IVault(vaults[i]).poolSize() * shares / IERC20(vaults[i]).totalSupply();

            if (subPoolSize == 0) continue;

            uint256 subPoolSizeInCapital;
            if (IVault(vaults[i]).quoteToken() == capitalToken) {
                subPoolSizeInCapital = subPoolSize;
            }
            else {
                path[0] = IVault(vaults[i]).quoteToken();
                amounts = UniswapRouterV2(pancakeRouter).getAmountsOut(subPoolSize, path);
                subPoolSizeInCapital = amounts[1];
            }

            _poolSize = _poolSize + subPoolSizeInCapital;
        }

        return _poolSize;
    }

    function deposit(uint256 amount) external nonReentrant {
        if (isContract(msg.sender)) {
            require(whiteList[msg.sender], "Not whitelisted SC");
        }

        require (vaults.length == VAULT_COUNT, "vaults are not updated yet.");

        // 1. Check max cap
        require (maxCap == 0 || totalSupply() + amount < maxCap, "The vault reached the max cap");

        // 2. receive funds
        IERC20(capitalToken).safeTransferFrom(msg.sender, address(this), amount);
        amount = IERC20(capitalToken).balanceOf(address(this));

        // 3. divide, swap to each quote token and deposit to the vaults
        uint256 subAmount = amount / VAULT_COUNT;
        for (uint i = 0; i < VAULT_COUNT; i++) {
            depositToVault(vaults[i], subAmount);
        }
        
        // 4. mint tokens for shares
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = amount;
        }
        else {
            shares = amount * totalSupply() / poolSize();
        }
        _mint(msg.sender, shares);
    }

    function withdraw(uint256 shares) external nonReentrant {
        if (isContract(msg.sender)) {
            require(whiteList[msg.sender], "Not whitelisted SC");
        }

        require (vaults.length == VAULT_COUNT, "vaults length isn't VAULT_COUNT");
        require (shares <= balanceOf(msg.sender), "invalid share amount");

        // 1. iterate vaults, calculate partial shares, withdraw, swap to capital token
        for (uint i = 0; i < VAULT_COUNT; i++) {
            uint subShare = IERC20(vaults[i]).balanceOf(address(this)) * shares / totalSupply();
            withdrawFromVault(vaults[i], subShare);
        }

        // 2. transfer capital to the user
        if (IERC20(capitalToken).balanceOf(address(this)) > 0) {
            IERC20(capitalToken).safeTransfer(msg.sender, IERC20(capitalToken).balanceOf(address(this)));
        }

        // 3. burn share tokens
        _burn(msg.sender, shares);
    }

    function updateVaults(address[] memory _vaults) external {
        require(whiteList[msg.sender], "Not whitelisted");

        // 1. check array length and zero address and strategist
        require (_vaults.length == VAULT_COUNT, "vaults length isn't VAULT_COUNT");

        require (_vaults[0] != address(0), "vaults[0] zero address");
        require (_vaults[1] != address(0), "vaults[1] zero address");
        require (_vaults[2] != address(0), "vaults[2] zero address");
        require (_vaults[3] != address(0), "vaults[3] zero address");
        require (_vaults[4] != address(0), "vaults[4] zero address");

        // Check the strategy address
        require (IVault(_vaults[0]).strategist() == strategist, "vaults[0] strategist not valid");
        require (IVault(_vaults[1]).strategist() == strategist, "vaults[1] strategist not valid");
        require (IVault(_vaults[2]).strategist() == strategist, "vaults[2] strategist not valid");
        require (IVault(_vaults[3]).strategist() == strategist, "vaults[3] strategist not valid");
        require (IVault(_vaults[4]).strategist() == strategist, "vaults[4] strategist not valid");

        // Check the deployer address
        require (IVault(_vaults[0]).addrFactory() == addrFactory, "vaults[0] factory not valid");
        require (IVault(_vaults[1]).addrFactory() == addrFactory, "vaults[1] factory not valid");
        require (IVault(_vaults[2]).addrFactory() == addrFactory, "vaults[2] factory not valid");
        require (IVault(_vaults[3]).addrFactory() == addrFactory, "vaults[3] factory not valid");
        require (IVault(_vaults[4]).addrFactory() == addrFactory, "vaults[4] factory not valid");

        // 2. Check if this is the initial update
        if (vaults.length < VAULT_COUNT) {
            vaults = _vaults;
            return;
        }

        // 3. withdraw all funds and swap back to capital token (it could be no quote token in some cases)
        for (uint i = 0; i < VAULT_COUNT; i++) {
            withdrawFromVault(vaults[i], IERC20(vaults[i]).balanceOf(address(this)));
        }

        // 4. update vaults addresses
        vaults = _vaults;
        
        // 5. divide, swap and deposit funds to each vault
        uint256 amount = IERC20(capitalToken).balanceOf(address(this)) / VAULT_COUNT;
        for (uint i = 0; i < VAULT_COUNT; i++) {
            depositToVault(vaults[i], amount);
        }
    }

    function setFactoryAddress(address _address) external onlyOwner {
        require(_address != address(0),"factory address zero");
        addrFactory = _address;
        emit FactoryAddressUpdated(_address);
    }

    function updateStrategist(address _address) external onlyOwner {
        require(_address != address(0),"strategist address zero");
        strategist = _address;
        emit StrategistAddressUpdated(_address);
    }

    function addToWhiteList(address _address) external onlyOwner {
        require(_address != address(0),"white list address zero");
        whiteList[_address] = true;
        emit WhiteListAdded(_address);
    }

    function removeFromWhiteList(address _address) external onlyOwner {
        require(_address != address(0),"white list address zero");
        whiteList[_address] = false;
        emit WhiteListRemoved(_address);
    }

    // *** internal functions ***

    function depositToVault(address vault, uint256 amount) internal {
        require(vault != address(0), "vault zero address");

        if (amount == 0) {
            return;
        }

        if (isContract(msg.sender)) {
            require(whiteList[msg.sender], "Not whitelisted SC");
        }        

        // 1. get quote token of the vault
        address quoteToken = IVault(vault).quoteToken();

        // 2. swap to quote token
        if (capitalToken != quoteToken) {
            uint256 _before = IERC20(quoteToken).balanceOf(address(this));
            _swapPancakeswap(capitalToken, quoteToken, amount);
            uint256 _after = IERC20(quoteToken).balanceOf(address(this));
            amount = _after - _before;
        }

        // 3. deposit
        assert(IERC20(quoteToken).approve(vault, amount));
        IVault(vault).depositQuote(amount);
    }

    function withdrawFromVault(address vault, uint256 shares) internal {

        require(vault != address(0), "vault zero address");

        if (shares == 0) {
            return;
        }

        if (isContract(msg.sender)) {
            require(whiteList[msg.sender], "Not whitelisted SC");
        }        

        // 1. get withdraw token (position: 0 => quote token, 1 => base token)
        
        address withdrawToken;
        if (IVault(vault).position() == 0 ) {
            withdrawToken = IVault(vault).quoteToken();
        }
        else {
            withdrawToken = IVault(vault).baseToken();
        }

        // 2. withdraw from vault
        uint256 _before = IERC20(withdrawToken).balanceOf(address(this));
        IVault(vault).withdraw(shares);
        uint256 _after = IERC20(withdrawToken).balanceOf(address(this));
        uint256 amount = _after - _before;

        // 3. swap to capital token
        if (amount > 0) {
            _swapPancakeswap(withdrawToken, capitalToken, amount);
        }
    }

    function _swapPancakeswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_from != address(0) && _to != address(0), "from or to zero address");

        if (_from == _to) {
            return;
        }

        // Swap with uniswap
        assert(IERC20(_from).approve(pancakeRouter, 0));
        assert(IERC20(_from).approve(pancakeRouter, _amount));

        address[] memory path;

        path = new address[](2);
        path[0] = _from;
        path[1] = _to;

        uint256[] memory amountOutMins = UniswapRouterV2(pancakeRouter).getAmountsOut(
            _amount,
            path
        );
        uint256 amountOutMin = amountOutMins[path.length -1].mul(100 - pancakeswapSlippage).div(100);

        uint256[] memory amounts = UniswapRouterV2(pancakeRouter).swapExactTokensForTokens(
            _amount,
            amountOutMin,
            path,
            address(this),
            block.timestamp + 60
        );

        require(amounts[0] > 0, "amounts[0] zero  amount");
    }

    function isContract(address _addr) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}