//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./SlayToEarnItems.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC20Extended is IERC20 {
    function symbol() external view returns (string memory);
}

// https://t.me/BlockifyGames
contract SlayToEarnToken is Context, Ownable, IERC20, IERC20Metadata, AccessControl {
    bytes32 public constant MAINTENANCE_ROLE = keccak256("MAINTENANCE_ROLE");

    bool private _enableGateKeeper;
    uint256 private _tokenRewardsPercentage;
    uint256 private _tokenDevPercentage;
    uint256 private _tokenBurnPercentage;
    uint256 private _tokenBuyBackPercentage;
    IERC1155 private _originalWitnessCollection;
    SlayToEarnItems private _currentItemCollection;
    uint256 private _maxWalletAmount;
    address private _claimRewardsContract;
    uint256 private _launchTime;
    address private _deployer;
    address private _uniswapLpPair;
    address private _devIncomeWallet;
    IUniswapV2Router02 private _uniswapRouter;
    address private _usdcToken;
    address private _blockifyToken;
    IUniswapV2Factory private _uniswapFactory;

    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _lastBuyBlock;
    mapping(address => uint256) private _taxReductionPercentageMap;

    constructor(
        IERC1155 originalWitnessCollection,
        SlayToEarnItems currentItemCollection,
        address devIncomeWallet,
        address claimRewardsContract,
        IUniswapV2Router02 uniswapRouter,
        IERC20Extended usdcToken,
        IERC20Extended blockifyToken) {

        _name = "Slay To Earn";
        _symbol = "SLAY2EARN";
        _deployer = msg.sender;
        _originalWitnessCollection = originalWitnessCollection;
        _currentItemCollection = currentItemCollection;
        _devIncomeWallet = devIncomeWallet;
        _claimRewardsContract = claimRewardsContract;
        _uniswapRouter = uniswapRouter;
        _usdcToken = address(usdcToken);
        _blockifyToken = address(blockifyToken);
        _uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
        _uniswapLpPair = _uniswapFactory.createPair(address(this), _usdcToken);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MAINTENANCE_ROLE, msg.sender);

        _setRoleAdmin(MAINTENANCE_ROLE, DEFAULT_ADMIN_ROLE);

        require(_uniswapLpPair != address(0), "Failed to create liquidity pair.");
        require(keccak256(bytes(usdcToken.symbol())) == keccak256("USDC"), "You did not supply a valid USDC token.");

        setBlockifyToken(blockifyToken);

        addToWhitelist(_deployer);
        addToWhitelist(address(this));
        setMaxWalletAmount(5_000_000_000 ether);

        _mint(
            _deployer,
            1_000_000_000_000 ether
        );

        // Shortly after our initial launch, we will disable the gatekeeper and turn this into a regular, vanilla ERC20 token.
        // Once disabled, there is no way to turn it back on...
        _enableGateKeeper = true;

        setTaxPercentages(0, 0, 6, 1);
        getOwnedWitnessCount();
    }

    function setBlockifyToken(IERC20Extended blockifyToken) public onlyOwner {
        if (address(blockifyToken) != address(0)) {
            require(keccak256(bytes(blockifyToken.symbol())) == keccak256("BLOCKIFY"), "You did not supply a valid BLOCKIFY token.");
            require(_uniswapFactory.getPair(_blockifyToken, _usdcToken) != address(0), "There is no USDC/BLOCKIFY pool. Likely the tokens you supplied are not valid.");
        }

        _blockifyToken = address(blockifyToken);
    }

    function getBlockifyToken() public view returns (address) {
        return _blockifyToken;
    }

    function getUsdcToken() public view returns (address) {
        return _usdcToken;
    }

    function getLiquidityPair() public view returns (address) {
        return _uniswapLpPair;
    }

    function addToWhitelist(address addressToAdd) public onlyOwner {
        _whitelist[addressToAdd] = true;
    }

    function removeFromWhitelist(address addressToRemove) public onlyOwner {
        _whitelist[addressToRemove] = false;
    }

    function isWhitelisted(address addressToCheck) public view returns (bool) {
        return _whitelist[addressToCheck] == true;
    }

    function isGateKeeperEnabled() public view returns (bool) {
        return _enableGateKeeper;
    }

    function isGateKeeperPermanentlyDisabled() public view returns (bool) {
        return !_enableGateKeeper;
    }

    function setLaunchTime(uint256 unixTimestampSeconds) public onlyOwner {
        _launchTime = unixTimestampSeconds;
    }

    function getLaunchTime() public view returns (uint256) {
        return _launchTime;
    }

    function permanentlyDisarmUniswapGateKeeper() public onlyOwner {
        _enableGateKeeper = false;
    }

    /**
        Use the given item from your inventory to apply tax reduction for your next Uniswap trade.
        The item will be consumed immediately in this call, even if you never make another Uniswap trade.
    */
    function applyTaxReduction(uint256 itemId) public {
        uint256 reduction = 0;
        if (itemId == 2048777) {
            reduction = 10;
        } else if (itemId == 2048809) {
            reduction = 30;
        } else if (itemId == 2048841) {
            reduction = 50;
        } else if (itemId == 2048873) {
            reduction = 70;
        } else if (itemId == 2048905) {
            reduction = 100;
        } else {
            require(false, "The given item does not refer to a tax reduction NFT.");
        }

        _taxReductionPercentageMap[msg.sender] = reduction;

        uint256[] memory items = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        items[0] = itemId;
        amounts[0] = 1;

        require(_currentItemCollection.balanceOf(msg.sender, itemId) > 0, "You don't own the given item.");
        _currentItemCollection.burnBatch(msg.sender, items, amounts);
    }

    function getAppliedTaxReduction(address wallet) public view returns (uint256) {
        return _taxReductionPercentageMap[msg.sender];
    }

    function setTaxPercentages(uint256 burnPercentage, uint256 rewardPercentage, uint256 devPercentage, uint256 blockifyBuyBackPercentage) public onlyOwner {
        _tokenBurnPercentage = burnPercentage;
        _tokenRewardsPercentage = rewardPercentage;
        _tokenDevPercentage = devPercentage;
        _tokenBuyBackPercentage = blockifyBuyBackPercentage;

        require(_tokenBurnPercentage <= 20, "The maximum burn fee is 20%.");
        require(_tokenBuyBackPercentage <= 20, "The maximum buy-back fee is 20%.");
        require(_tokenRewardsPercentage <= 20, "The maximum reward fee is 20%.");
        require(_tokenDevPercentage <= 20, "The maximum dev fee is 20%.");
        require(_tokenBurnPercentage + _tokenBuyBackPercentage + _tokenRewardsPercentage + _tokenDevPercentage <= 30, "The maximum total combined fee is 30%.");
    }

    function getBuyBackPercentage() public view returns (uint256) {
        return _tokenBuyBackPercentage;
    }

    function getBurnPercentage() public view returns (uint256) {
        return _tokenBurnPercentage;
    }

    function getRewardsPercentage() public view returns (uint256) {
        return _tokenRewardsPercentage;
    }

    function getDevPercentage() public view returns (uint256) {
        return _tokenDevPercentage;
    }

    function setCurrentItemCollection(SlayToEarnItems currentCollection) public onlyOwner {
        _currentItemCollection = currentCollection;

        // need to verify that this still works, otherwise transfers will be blocked.
        getOwnedWitnessCount();
    }

    function getCurrentItemCollection() public view returns (IERC1155) {
        return _currentItemCollection;
    }

    function setOriginalWitnessItemCollection(IERC1155 originalCollection) public onlyOwner {
        _originalWitnessCollection = originalCollection;

        // need to verify that this still works, otherwise transfers will be blocked.
        getOwnedWitnessCount();
    }

    function getOriginalWitnessItemCollection() public view returns (IERC1155) {
        return _originalWitnessCollection;
    }

    function getOwnedWitnessCount() public view returns (uint256) {
        return getOwnedWitnessCountForAddress(msg.sender);
    }

    function getOwnedWitnessCountForAddress(address wallet) public view returns (uint256) {
        uint256 newCount = _currentItemCollection.balanceOf(wallet, 2048649);
        uint256 oldCount = _currentItemCollection.balanceOf(wallet, 2048393);

        if (_originalWitnessCollection != IERC1155(address(0))) {
            oldCount += _originalWitnessCollection.balanceOf(wallet, 2048393);
        }

        return newCount + (oldCount > 0 ? 1 : 0);
    }

    function setRewardsClaimContract(address rewardsClaimContract) public onlyOwner {
        _claimRewardsContract = rewardsClaimContract;
    }

    function getRewardsClaimContract() public view returns (address) {
        return _claimRewardsContract;
    }

    function setDevIncomeWallet(address wallet) public onlyOwner {
        _devIncomeWallet = wallet;
    }

    function getDevIncomeWallet() public view returns (address) {
        return _devIncomeWallet;
    }

    function setMaxWalletAmount(uint256 maxWalletAmount) public onlyOwner {
        require(maxWalletAmount == 0 || maxWalletAmount >= 1_000_000_000 ether);

        _maxWalletAmount = maxWalletAmount;
    }

    function getMaxWalletAmount() public view returns (uint256) {
        return _maxWalletAmount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 sentAmount
    ) internal {

        if (isWhitelisted(sender) || isWhitelisted(recipient)) {
            _feelessTransfer(sender, recipient, sentAmount);
            return;
        }

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        bool isGateKeeperDisabled = isGateKeeperPermanentlyDisabled();

        if (getMaxWalletAmount() > 0) {
            if (recipient == _uniswapLpPair) {
                // since we can't limit the LP pair, during selling, we only limit tx amounts
                require(sentAmount <= getMaxWalletAmount(), "Sell blocked. Token limit per transaction exceeded. Refer to our Telegram for further information. This restriction will be lifted shortly.");
            } else {
                // during buys, we make sure that you can't put more than the limit into the wallet
                require(balanceOf(recipient) + sentAmount <= getMaxWalletAmount(), "Buy blocked. Token limit per wallet exceeded. Refer to our Telegram for further information. This restriction will be lifted shortly.");
            }
        }

        // you can only buy once per block while gatekeeper is enabled
        bool noBuyInThisBlock = _lastBuyBlock[recipient] < block.number;
        _lastBuyBlock[recipient] = block.number;
        require(recipient == _uniswapLpPair || noBuyInThisBlock || isGateKeeperDisabled, "Buy blocked by gatekeeper. You can only buy once per block. Refer to our Telegram for further information. This restriction will be lifted shortly.");

        // to buy, you have to hold our launch witness while gatekeeper is enabled
        bool hasRequiredWitnesses = getOwnedWitnessCountForAddress(recipient) >= 2;
        require(recipient == _uniswapLpPair || hasRequiredWitnesses || isGateKeeperDisabled, "Buy blocked by gatekeeper. Target wallet does not own enough of our NFTs. Refer to our Telegram for further information. This restriction will be lifted shortly.");

        uint256 taxReductionPercentage = _taxReductionPercentageMap[sender];
        _taxReductionPercentageMap[sender] = 0;

        uint256 burnedTokens = (sentAmount * _tokenBurnPercentage * (100 - taxReductionPercentage)) / 10_000;
        uint256 rewardTokens = (sentAmount * _tokenRewardsPercentage * (100 - taxReductionPercentage)) / 10_000;
        uint256 devAndBuyBackTokens = (sentAmount * (_tokenDevPercentage + _tokenBuyBackPercentage) * (100 - taxReductionPercentage)) / 10_000;
        uint256 receivedTokens = sentAmount - burnedTokens - rewardTokens - devAndBuyBackTokens;

        if (burnedTokens > 0) {
            _burn(sender, burnedTokens);
        }

        if (rewardTokens > 0) {
            _feelessTransfer(sender, _claimRewardsContract, rewardTokens);
        }

        if (devAndBuyBackTokens > 0) {
            _feelessTransfer(sender, address(this), devAndBuyBackTokens);
        }

        _feelessTransfer(sender, recipient, receivedTokens);
    }

    /**
      * This method can be front-run. Just as with swaps, make sure to select a tight slippage around the actual prices
      before running the methods.
    */
    function runMaintenance(uint256 maximumSlayToEarnPerUsdc, uint256 maximumSlayToEarnPerBlockify) public onlyRole(MAINTENANCE_ROLE) {
        // Anyone can run this method, but we will do it regularly on our own.
        uint256 balance = balanceOf(address(this));

        require(balance > 0, "No tokens are available to sell.");

        if (_blockifyToken == address(0)) {
            _doTransferDevFee(balance, maximumSlayToEarnPerUsdc);
        } else {
            uint256 buyBackTokens = (balance * _tokenBuyBackPercentage) / (_tokenDevPercentage + _tokenBuyBackPercentage);
            uint256 devTokens = balance - buyBackTokens;

            _doTransferDevFee(devTokens, maximumSlayToEarnPerUsdc);
            _doBlockifyBuyback(buyBackTokens, maximumSlayToEarnPerBlockify);
        }
    }

    function _doTransferDevFee(uint256 tokensToSell, uint256 maximumSlayToEarnPerUsdc) internal {
        if (tokensToSell == 0) {
            return;
        }

        // sell buffered tokens into USDC and send them to dev wallet.
        address[] memory tradingPath = new address[](2);
        tradingPath[0] = address(this);
        tradingPath[1] = _usdcToken;

        _approve(
            address(this),
            address(_uniswapRouter),
            _allowances[address(this)][address(_uniswapRouter)] + tokensToSell
        );

        _uniswapRouter.swapExactTokensForTokens(
            tokensToSell,
            tokensToSell / maximumSlayToEarnPerUsdc,
            tradingPath,
            _devIncomeWallet,
            block.timestamp
        );
    }

    function _doBlockifyBuyback(uint256 tokensToSell, uint256 maximumSlayToEarnPerBlockify) internal {
        if (tokensToSell == 0) {
            return;
        }

        // sell buffered tokens into Blockify and burn them.
        address[] memory tradingPath = new address[](3);
        tradingPath[0] = address(this);
        tradingPath[1] = _usdcToken;
        tradingPath[2] = _blockifyToken;

        _approve(
            address(this),
            address(_uniswapRouter),
            _allowances[address(this)][address(_uniswapRouter)] + tokensToSell
        );

        _uniswapRouter.swapExactTokensForTokens(
            tokensToSell,
            tokensToSell / maximumSlayToEarnPerBlockify,
            tradingPath,
            0x000000000000000000000000000000000000dEaD,
            block.timestamp
        );
    }

    function _feelessTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////// OpenZepplin ERC20.sol
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
}