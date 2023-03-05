// important: remember to exclude this contract from KOL LIBERO LIBERA THOREUM fee
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./AuthUpgradeable.sol";
import "./IUniswap.sol";
import "./ISolidlyRouter.sol";
pragma solidity ^0.8.13;

interface ILibero {
    function checkFeeExempt(address _account) external view returns (bool); // for LIBERO
    function totalSellFee() external view returns (uint256); // for LIBERO
}

interface ILibera is IERC20Upgradeable {

    function checkIsExcludedFromFees(address _account) external view returns (bool);
    function totalSellFees() external view returns (uint256);
    function totalBuyFees() external view returns (uint256);
    function circuitBreakerFlag() external view returns (uint);
    function breakerSellFee() external view returns (uint256);
    function breakerBuyFee() external view returns (uint256);
    function blacklistFrom(address _addr) external view returns (bool);
    function blacklistTo(address _addr) external view returns (bool);
    function marketingWallet() external view returns (address);
}

interface IBank {
    function depositFor(address _addr, uint256 _value) external;
    function lockedOf(address _addr) external view returns (uint256);
    function createLockFor(address _adr, uint256 _value, uint256 _days, address _referrer) external;
}

interface IVault {
    function depositFor(address _addr, uint256 _value) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

/**
 * A zapper implementation which converts a single asset into
 * a THOREUM/BUSD or KOL/WBNB liquidity pair. And breaks a liquidity pair to single assets
 *
 */
contract KolZap_init is Initializable, UUPSUpgradeable, AuthUpgradeable {

    function _authorizeUpgrade(address) internal override onlyOwner {}


    IUniswapV2Router public constant BISWAP=IUniswapV2Router(0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8);
    IUniswapV2Router public constant PANCAKE=IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    ISolidlyRouter public constant THENA=ISolidlyRouter(0x20a304a7d126758dfe6B243D0fc515F83bCA8431);
    IBank public BANK; // KOL BANK

    address public constant THOREUM = 0xCE1b3e5087e8215876aF976032382dd338cF8401;    //THOREUM
    address public constant LIBERA = 0x3A806A3315E35b3F5F46111ADb6E2BAF4B14A70D;    //KOL
    address public constant LIBERO = 0x0DFCb45EAE071B3b846E220560Bbcdd958414d78;    //LIBERO
    address public constant KOL = 0xC95cD75dCea473a30C8470B232b36ee72aE5DcC2;    //KOL

    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD
    address public constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8; // ETH

    mapping(address => address) public DEXPAIRS;
    mapping(address => address) public VAULTS;

    bool public TAKE_FEE;
    bool public paused;
    mapping(address => address) private routePairAddresses;

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __AuthUpgradeable_init();

        // approve our main input tokens
        IERC20Upgradeable(KOL).approve(address(BISWAP), type(uint256).max);
        IERC20Upgradeable(BUSD).approve(address(BISWAP), type(uint256).max);
        IERC20Upgradeable(THOREUM).approve(address(BISWAP), type(uint256).max);
        IERC20Upgradeable(LIBERO).approve(address(PANCAKE), type(uint256).max);

        //approve to deposit into bank
        //            BANK=IBank(0x2a873F66084FbE4f284771F199FCA94fbea0054e);
        //            IERC20Upgradeable(DEXPAIRS[DEX_TOKEN]).approve(address(BANK), type(uint256).max);

        routePairAddresses[LIBERA] = BUSD;
        routePairAddresses[KOL] = ETH;

        Approve(KOL);
        Approve(WBNB);

        Set_Pair(ETH,0x972291C293a2eE6c7397017a6412035976E4326C, 0xC5966EF49cE6975516c76484274fe1180Fc68F05);

        TAKE_FEE = false;
    }

    function Approve(address _token) public onlyOwner {
        IERC20Upgradeable(_token).approve(address(THENA), type(uint256).max);
    }

    function Set_Pair(address dex_token, address dex_pair, address _vault) public onlyOwner {
        Approve(dex_token);
        DEXPAIRS[dex_token] = dex_pair;
        Approve(dex_pair);
        VAULTS[dex_token] = _vault;
        IERC20Upgradeable(DEXPAIRS[dex_token]).approve(_vault, type(uint256).max);
    }

    function Set_TAKE_FEE(bool _TAKE_FEE) external onlyOwner {
        TAKE_FEE = _TAKE_FEE;
    }

    function Approve_KOL() external onlyOwner {
        Approve(KOL);
    }

    receive() external payable {}

    function zapKolToLP(
        uint256 amount,
        address dex_token,
        bool _deposit,
        address _ref,
        bool _vault,
        bool _bank
    ) public whenNotPaused {
        zapKolToLPDays (msg.sender, dex_token, amount, _deposit, _ref, _vault, _bank, 0);
    }

    function zapKolToLPDays(
        address _user, // default is msg.sender, can be used to deposit for other users
        address dex_token,
        uint256 amount,
        bool _deposit,
        address _ref,
        bool _vault,
        bool _bank,
        uint256 _days
    ) public whenNotPaused {

    }

    function zapBNBToLP(address dex_token, bool _deposit, address _ref, bool _vault, bool _bank)      public    payable     whenNotPaused
    {
    }

    function zapBNBToLPDays(address dex_token, bool _deposit, address _ref, bool _vault, bool _bank, uint256 _days)    public     payable   whenNotPaused

    {
    }


    function zapTokenToLP( // for LIBERO, THOREUM, BUSD, WBNB
        address _tokenDeposit,
        address dex_token,
        uint256 amount,
        address _ref,
        bool _deposit,
        bool _vault,
        bool _bank
    ) public whenNotPaused {
        if (_tokenDeposit == LIBERO) {
            revert("LIBERO is not enabled");
            //            zapLiberoToLPDays(msg.sender, amount, _ref, _deposit, _vault, _bank, 0);
        } else if (_tokenDeposit == KOL) {
            zapKolToLPDays(msg.sender, dex_token, amount,  _deposit, _ref, _vault, _bank, 0);
        } else {
            zapTokenToLPDays(msg.sender,dex_token,  _tokenDeposit, amount, _ref, _deposit, _vault, _bank, 0);
        }

    }

    function zapTokenToLPDays( // for THOREUM, BUSD and any token with BNB pair on Biswap such as XRP, ADA, LTC...
        address _user, // default is msg.sender, can be used to deposit for other users
        address dex_token,
        address _tokenDeposit,
        uint256 amount,
        address _ref,
        bool _deposit,
        bool _vault,
        bool _bank,
        uint256 _days
    ) public whenNotPaused {
    }
    function zapLiberoToLP( // for LIBERO, use different router
        uint256 amount,
        address dex_token,
        address _ref,
        bool _deposit,
        bool _vault,
        bool _bank
    ) public whenNotPaused {
        zapLiberoToLPDays(msg.sender,dex_token, amount,_ref,_deposit,_vault,_bank,0);
    }

    function zapLiberoToLPDays( // for LIBERO, use different router
        address _user,
        address dex_token,
        uint256 amount,
        address _ref,
        bool _deposit,
        bool _vault,
        bool _bank,
        uint256 _days
    ) public whenNotPaused {


    }
    function userAddLiquidityAndDepositForBankDays(address _user,address dex_token, uint256 dexTokenAmount, uint256 kolAmount, address _ref, uint256 _days, bool _deposit, bool _vault, bool _bank) public payable whenNotPaused {
    }

    function unZapToTokenFor(address dex_token, uint256 amount, address targetToken, address _user) public whenNotPaused {
    }

    function unZapToToken(address dex_token, uint256 amount, address targetToken) public whenNotPaused  {
        unZapToTokenFor(dex_token, amount, targetToken, msg.sender);
    }

    function cleanDust(address _to, address dex_token) private  {
    }

    function _transferBNBToWallet(address payable recipient, uint256 amount) private {
    }

    function breakFor(uint256 amount, address _user, address dex_token) public whenNotPaused {
    }


    function getBuyFee(address _token) public view returns(uint256) {
    }
    function getSellFee(address _token) public view returns(uint256) {
    }

    function addLiquidityAndDeposit(bool _deposit,address dex_token, address _ref, uint256 _tax, bool _vault, bool _bank) private {
        addLiquidityAndDepositDays(msg.sender,dex_token, _deposit, _ref, _tax, _vault, _bank, 0);
    }
    function addLiquidityAndDepositDays(address _user, address dex_token, bool _deposit, address _ref, uint256 _tax, bool _vault, bool _bank, uint256 _days) private {
        cleanDust(_user, dex_token);
    }

    function setKolBank(address _minter, address dex_token) external onlyOwner {
        BANK = IBank(_minter);
        IERC20Upgradeable(DEXPAIRS[dex_token]).approve(_minter, type(uint256).max);
    }

    function getStuckToken(address token) external onlyOwner {
        if (token == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }

        IERC20Upgradeable(token).transfer(
            msg.sender,
            IERC20Upgradeable(token).balanceOf(address(this))
        );
    }


    function setRoutePairAddress(address asset, address route)
    external
    onlyOwner
    {
        routePairAddresses[asset] = route;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }
    function SET_PAUSED(bool _PAUSED) external onlyOwner{
        paused = _PAUSED;
    }

    function updateV2() external onlyOwner {
    }


}