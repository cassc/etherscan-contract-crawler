// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../../common/Errors.sol";
import "../../common/IConfigurator.sol";
import "../../token/RoboFiToken.sol";
import "../interfaces/IDABot.sol";
import "../interfaces/IDABotComponent.sol";
import "../interfaces/IDABotStakingModule.sol";
import "../../treasury/ITreasuryManager.sol";
import "../../treasury/ITreasuryAsset.sol";

/** Interest-beared Certificate Token
 */
contract IBCertToken is IDABotCertTokenEvent, RoboFiToken, IDABotComponent, IERC165 {

    using SafeERC20 for IRoboFiERC20;

    IDABot internal _bot;
    IRoboFiERC20 internal _asset;
    IConfigurator internal immutable _config;

    uint256 internal _totalDeposit;      // total deposit of underlying asset
    uint256 internal _totalLock;         // locked liquid of underlying asset

    modifier authorizedByBot() {
        address caller = _msgSender();
        require((caller == address(_bot)) || IDABotStakingModule(address(_bot)).isCertLocker(caller), 
            Errors.BCT_CALLER_IS_NEITHER_BOT_NOR_CERTLOCKER 
        );
        _;
    }

    modifier ownedBotOnly() {
        require(_msgSender() == address(_bot), Errors.BCT_CALLER_IS_NOT_OWNER); 
        _;
    }

    modifier ownedBotOrOwner() {
        require(_msgSender() == address(_bot) ||
                _msgSender() == _bot.metadata().botOwner,
            Errors.BCT_CALLER_IS_NOT_OWNER); 
        _;
    }

    constructor(IConfigurator config) RoboFiToken('', '', 0, address(0)) {
        _config = config;
    }

    function init(bytes calldata data) external payable override {
        require(address(_bot)  == address(0), Errors.CM_CONTRACT_HAS_BEEN_INITIALIZED);
        (_bot, _asset) = abi.decode(data, (IDABot, IRoboFiERC20));
    }

    function finalize() external ownedBotOnly {
        require(totalSupply() == 0, Errors.BCT_REQUIRE_ALL_TOKENS_BURNT);

        selfdestruct(payable(address(_bot)));
    }

    function moduleInfo() external pure override virtual
        returns(string memory, string memory, bytes32)
    {
        return ("IBCertToken", "v0.1.20220301", BOT_CERT_TOKEN_TEMPLATE_ID);
    }

    function isCertToken() external pure returns(bool) {
        return true;
    }

    function isTreasuryAsset() internal view returns(bool) {
        ITreasuryManager treasuryManager = ITreasuryManager(_config.addressOf(AddressBook.ADDR_TREASURY_MANAGER));
        require(address(treasuryManager) != address(0), Errors.CM_TREASURY_MANAGER_IS_NOT_CONFIGURED);
        return treasuryManager.isTreasury(address(_asset));
    }

    function isNativeAsset() internal view returns(bool) {
        return address(_asset) == NATIVE_ASSET_ADDRESS;
    }

    function totalStake() external view returns(uint) {
        return _totalDeposit;
    }

    function totalLiquid() public view returns(uint) {
        return _totalDeposit >= _totalLock ? _totalDeposit - _totalLock : 0;
    }

    function owner() public view returns (address) {
        return address(_bot);
    }

    function symbol() public view override returns(string memory) {
        return string(abi.encodePacked(_bot.metadata().symbol, _asset.symbol()));
    }

    function name() public view override returns(string memory) {
        return string(abi.encodePacked(_bot.metadata().name, " Certificate ", _asset.name()));
    }

    function decimals() public view override returns(uint8) {
        return _asset.decimals();
    }

    function asset() external view returns(IRoboFiERC20) {
        return _asset;
    }   

    function value(uint certTokenAmount) public view returns(uint256) {
        if (totalSupply() == 0)
            return 0;
        return certTokenAmount * _totalDeposit / totalSupply();
    }

    function lock(uint assetAmount) external ownedBotOrOwner {
        require(_totalLock + assetAmount <= _totalDeposit, Errors.BCT_INSUFFICIENT_LIQUID_FOR_LOCKING);
        _lock(assetAmount);
    }

    function _lock(uint assetAmount) internal virtual {
        _totalLock += assetAmount;
        if (isTreasuryAsset())
            ITreasuryAsset(address(_asset)).lock(assetAmount);
        emit Lock(assetAmount);
    }

    function unlock(uint assetAmount) external payable virtual ownedBotOrOwner {
        if (isNativeAsset()) {
            require(assetAmount == msg.value, Errors.BCT_VALUE_MISMATCH_ASSET_AMOUNT); 
        }
        require(_totalLock >= assetAmount, Errors.BCT_UNLOCK_AMOUNT_EXCEEDS_TOTAL_LOCKED);
        // require(_asset.balanceOf(address(this)) >= totalLiquid() + assetAmount, Errors.BCT_INSUFFICIENT_LIQUID_FOR_UNLOCKING);
        _unlock(assetAmount);
    }

    function _unlock(uint assetAmount) internal virtual {
        _totalLock -= assetAmount;
        if (isTreasuryAsset()) {
            ITreasuryAsset treasury = ITreasuryAsset(address(_asset));
            if (!treasury.isNativeAsset()) {
                IRoboFiERC20 underlyAsset = treasury.asset();
                if (underlyAsset.allowance(address(this), address(treasury)) < assetAmount)
                    underlyAsset.approve(address(treasury), type(uint).max);
            }
            treasury.unlock{value: msg.value}(address(this), assetAmount);
        }
 
        emit Unlock(assetAmount);
    }

    function compound(uint assetAmount, bool profitOrLoss) external ownedBotOnly {
        if (profitOrLoss)
            _totalDeposit += assetAmount;
        else {
            require(_totalDeposit >= assetAmount, Errors.BCT_AMOUNT_EXCEEDS_TOTAL_STAKE);
            _totalDeposit -= assetAmount;
            if (_totalLock > _totalDeposit)
                _totalLock = _totalDeposit;
            if (isTreasuryAsset())
                ITreasuryAsset(address(_asset)).slash(assetAmount);
        }
        emit Compound(assetAmount, profitOrLoss);
    }

    function mint(address account, uint assetAmount) external ownedBotOnly returns(uint) {
        require(account != address(0), Errors.BCT_CANNOT_MINT_TO_ZERO_ADDRESS);
        if (assetAmount == 0)
            return 0;

        // convertion rate between IBCertToken and its pegged asset = (_totalDeposit/_totalSupply)
        uint mintedAmount = _totalDeposit == 0 ? assetAmount :
                            assetAmount * totalSupply() / _totalDeposit;
        _totalDeposit += assetAmount;
        _mint(account, mintedAmount);
        return mintedAmount;
    }

    function burn(address account, uint amount) external authorizedByBot returns(uint) {
        return __burn(account, amount, true);
    }

    function burn(uint amount) external authorizedByBot returns(uint) {
        return __burn(_msgSender(), amount, true);
    }

    function slash(address account, uint slashAmount) external ownedBotOnly {
         __burn(account, slashAmount, false);
    }

    function __burn(address account, uint amount, bool updateTotalDeposit) internal returns(uint redeemAssetAmount) {
        require(amount <= balanceOf(account), Errors.BCT_INSUFFICIENT_ACCOUNT_FUND);

        redeemAssetAmount = amount * _totalDeposit / totalSupply();
        require(_totalLock + redeemAssetAmount <= _totalDeposit, Errors.BCT_INSUFFICIENT_LIQUID_FOR_BURN);

        _burn(account, amount);

        if (updateTotalDeposit) {
            _totalDeposit -= redeemAssetAmount;
            _asset.safeTransfer(account, redeemAssetAmount);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return (interfaceId == type(IERC165).interfaceId) ||
                (interfaceId == type(IDABotCertToken).interfaceId)
        ;
    }
}