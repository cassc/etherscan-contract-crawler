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
        mapping(address => bool) claimedRewardAddresses;
        mapping(address => bool) nftClaimed;
        mapping(address => bool) presaleRound1Claimed;
        mapping(address => bool) presaleRound2Claimed;
        mapping(address => bool) vipPresaleRound1Claimed;
        mapping(address => bool) vipPresaleRound2Claimed;
        mapping(address => bool) vipPresaleRound3Claimed;
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

    
    uint256 constant MARKETING_TAX_BUY =        3;
    uint256 constant DEVELOPMENT_TAX_BUY =      3;
    uint256 constant LIQUIDITY_TAX_BUY =        0;

    uint256 constant MARKETING_TAX_SELL =       4;
    uint256 constant DEVELOPMENT_TAX_SELL =     3;
    uint256 constant LIQUIDITY_TAX_SELL =       0;

    
    uint256 constant CURRENT_PRESALE_ROUND =     1;
    uint256 constant CURRENT_VIP_PRESALE_ROUND = 1;
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

    event ClaimReward(uint256 nftReward, uint256 presaleReward, uint256 vipPresaleReward);

    function claimReward()
    public
    returns (uint256, uint256, uint256) {
        require(!isUserBlacklisted(_msgSender()), "You are blacklisted!");
        address[54] memory NFT_WALLETS = [0x057Aff91847Ac9DCD143805C3EA45E73517032B1,0x192c883a93F853D38640B1d7224472Dd71f2769B,0x19a6d28FE9942Ab02E674a4CbD11BA49562366DD,0x2d6305803a4B79B51CD773100Ec1CD40C1f7C397,0x2Db2deb9161F93A2579357E9a84db6A912F0dC58,0x346464ca770DB5D8349b3D1000d59A838e57070e,0x362d614D2cf2F34AFa94563882f60E45AB4A8a4d,0x3bD2bF83f8C77Dd991e1eb591a354A708694A181,0x420EB26eA0a5dB152dfD4a172D543Dbb98f2e514,0x422a3524DBe79f401fb5fCAAF43C8AF3fdd3F408,0x58175D33774aDe676E459448d0Bd0178DBf86544,0x6315C34d8E423c254b0D9eea0e9Ad1C9fD1589Af,0x6E56aC1A6BbFe0aF404c52413E6e60e8038Cb205,0x71619A7f0e077F8dE84027f59207C7c9c93e3eEc,0x74285833ab9054f413028B3B60bC64e1b9105272,0x747446215E3756993B8ED5a5524F810E0dC396b8,0x75c1167E8C67C8E2C7f05e54432a4059e65BCed6,0x80A7FACd872186047CE21A88555Ac9b1F6fd2b97,0x8518869FF07Bb25d43695A82f4D724BE04dBab57,0x88De39ECEa5CC4bF4d504eb29921387426f60E3C,0x8CAc449b052EBB35A3cFAb552709571Ab4c9E81B,0x8D8550B2a087Ea5C38f3ECE4b8b3f7D9bb330FC6,0x9A276F44A5e8DC521E11fd9C60d5b9aDd95A5963,0xA69a93dee2f028B5E62Ca9Bb7C3123839F54d9A1,0xA74f3043d42df45b9B4552EdA77778C389086bAE,0xbdeB4D3BD9E380f6B0A4A70b4b0Adb8394884B54,0xC2D00A14911F1Fd1aff37f5B09907F119B85A4F8,0xc5E7e396bc341265B27e60e494F437AdF6625814,0xC84163844272e3FcEF69BE3A77f35Dc33F9343B1,0xcDb3B54384460a3369C19FAbc386Cb719B2C1d1c,0xd3e39e6601C0e7EcA8e6e2048AA8200da567395A,0xd48A9ED8c06c7593566DbC83DCF37Db7bF456006,0xD620faA3e19D44a07005852b94b74A7Ec3B97Ce2,0xd8Cf2D540FD8Ee4D037a353eE10B93C361E43258,0xDE8a0403e814A894AFaD56649d782e983F68b50e,0xe2F68FD2df23A199CCD2544F9A13ea3a55935a39,0xe5E33C7BeDb8f9D0fd08d43eB3fc853D03472496,0xe67069D42B3802fd45429C42131DE35Cc9B2bf23,0xe6AacB8998b6Ec9A2fd0E7B97390863Bb9eA476d,0xE708dADd5750060a13094aB7eF95fF6f3Cecb4b4,0xEA0d9a8a3d521C7c1F0967b42d0384e84AA62D28,0xebe0794c3502fcAaE993Fc61d63F30D12EabE40F,0xeDC8f75B2C9f4aaBF6AcB709DC8e2bDD8C229792,0xf63bdD734ea8cdc8b43809C6541a2FBBCf056469,0xfB5848736A8c5Fd0ce22F3c460db630E09c383F6,0x2076117bE15A8469745700dA365b81663A9Cb544,0x4ACE00829D7571F39d258fd8c94e809E63595626,0x7Ae6C0B41CB8770531058C685EaB1e8a8b866115,0x7b9C4E5244382c78cE2FFc9fbB489b4361271149,0x9509E95a0d43C7F6cb42Df99BbE73340cfaA98D1,0xE921e3fE109402064C4eDE11862855B7473a1814,0x7863F87084F2a01cb6bD3E003eBbF030Fcb1FFE7,0x7bC8DdA12969F7874685F6604B51371DbA28f250,0xc25e36566868647a679c5e7B2A18F96fFff45a45];
        uint80[54] memory NFT_COIN_AMOUNT = [779301745635910000000,1558603491271820000000,1246882793017460000000,1168952618453870000000,2805486284289280000000,4909600997506230000000,15508104738154600000000,467581047381546000000,77930174563591000000,77930174563591000000,22599750623441400000000,155860349127182000000,77930174563591000000,42316084788029900000000,389650872817955000000,77930174563591000000,155860349127182000000,77930174563591000000,3506857855361600000000,77930174563591000000,1168952618453870000000,233790523690773000000,1168952618453870000000,77930174563591000000,77930174563591000000,1324812967581050000000,155860349127182000000,545511221945137000000,77930174563591000000,1168952618453870000000,779301745635910000000,77930174563591000000,77930174563591000000,77930174563591000000,6779925187032420000000,233790523690773000000,95620324189526200000000,77930174563591000000,857231920199501000000,26418329177057400000000,77930174563591000000,77930174563591000000,77930174563591000000,1168952618453870000000,779301745635910000000,467581047381546000000,467581047381546000000,2961346633416460000000,467581047381546000000,467581047381546000000,467581047381546000000,2493765586034910000000,2493765586034910000000,2493765586034910000000];

        address[29] memory PRESALE_WALLETS = [0x19a6d28FE9942Ab02E674a4CbD11BA49562366DD,0xD9aC63b9fba5cB64f536E232acEe4453dbD53D2D,0x5258D43E3FaA2F6794B31a32B130b6DFA707266f,0x8f1e2D101764CF619f05f3e1B8F1DF2E8C718902,0x2C0f07f859249bB8A8d647a6f167b3b50c9f224C,0x70a5931f13A1308f0B4eAC5F2A492eD84d20027F,0x08B8156CA9fFC05Df441dBCFd30800FEa596B181,0x49B2c763aa0c22d0446b581D551FE58fee29b633,0xD9b133f8C6984B337F5A235A902eA717699A5aFe,0xe44a66C45C33021E0d2E98Cb3a7368E18e7813F4,0x63fB612cfd13FF3096c4239e780D23B2A776824a,0xb7F0c1418C4a7c932f6be5d26DD3B9b57230574F,0xD51D87CA358c6Be3353D44376B739185d3763ECC,0x22C529942B3CEBbb7b28F37338f1d80c4f2F1735,0x541c45812f2ecfA0BFBA77a95ea54c044739231b,0xAF070182F4f9087eB634b333F283F10e9C943166,0x5B0DA1E40359976E433bcb30b7E4D77c544D0A81,0x7ae6586e3A8236A97CAc0FaBF06f85dB7e51d67C,0xaA7db76Daa94638F91D4F8A3311B064A4699a563,0xA18e37419912B70c9f6A4b3F47D86E7a2E73581E,0x392E213b2145945Ac6eaa8BA99fDd1A30AA2A598,0x88De39ECEa5CC4bF4d504eb29921387426f60E3C,0x2F4277Adbd3E7129098368D44ccABA112c9b35e6,0x9Df1fc23ad63170E1BA7c6CB18BC80c8E968EcF3,0x88De39ECEa5CC4bF4d504eb29921387426f60E3C,0x4ACE00829D7571F39d258fd8c94e809E63595626,0x94568c3a1040489C804C04f47fB15AF8c459b3C1,0xB205fB92Fc27870EA54c3A28c9Bb0B546dC3A0Ea,0x3455C0BB63636F82D280aa4053d88d3577292e8d];
        uint80[29] memory PRESALE_COIN_AMOUNT_ROUND_1 = [5496670000000000000000,10993340000000000000000,7695338000000000000000,10993340000000000000000,10993340000000000000000,10993340000000000000000,10993340000000000000000,10993340000000000000000,8794672000000000000000,10993340000000000000000,5496670000000000000000,5496670000000000000000,5496670000000000000000,10993340000000000000000,10993340000000000000000,10993340000000000000000,10993340000000000000000,8794672000000000000000,10993340000000000000000,10993340000000000000000,10993340000000000000000,5496670000000000000000,10993340000000000000000,10993340000000000000000,5496670000000000000000,10993340000000000000000,10993340000000000000000,10993340000000000000000,7695338000000000000000];
        uint80[29] memory PRESALE_COIN_AMOUNT_ROUND_2 = [5496670000000000000000,10993340000000000000000,7695338000000000000000,10993340000000000000000,10993340000000000000000,10993340000000000000000,10993340000000000000000,10993340000000000000000,8794672000000000000000,10993340000000000000000,5496670000000000000000,5496670000000000000000,5496670000000000000000,10993340000000000000000,10993340000000000000000,10993340000000000000000,10993340000000000000000,8794672000000000000000,10993340000000000000000,10993340000000000000000,10993340000000000000000,5496670000000000000000,10993340000000000000000,10993340000000000000000,5496670000000000000000,10993340000000000000000,10993340000000000000000,10993340000000000000000,7695338000000000000000];

        address[11] memory VIP_PRESALE_WALLETS = [0xDE8a0403e814A894AFaD56649d782e983F68b50e,0xa0592cF230B1a16f757e10E2994aff03a2499028,0x8518869FF07Bb25d43695A82f4D724BE04dBab57,0x057Aff91847Ac9DCD143805C3EA45E73517032B1,0x71619A7f0e077F8dE84027f59207C7c9c93e3eEc,0xE708dADd5750060a13094aB7eF95fF6f3Cecb4b4,0x58175D33774aDe676E459448d0Bd0178DBf86544, 0x1074104A6364581C4d8775e84b6128F97164cD8F,0xcDb3B54384460a3369C19FAbc386Cb719B2C1d1c,0xe5E33C7BeDb8f9D0fd08d43eB3fc853D03472496,0x3B9f5a98A83Ef6723c7359B0c8ea8a46c93Ca2a4];
        uint80[11] memory VIP_PRESALE_COIN_AMOUNT_ROUND_1 = [58593348000000000000000,29296674000000000000000,17783081118000000000000,8115178698000000000000,58593348000000000000000,58593348000000000000000,58593348000000000000000,29296674000000000000000,58593348000000000000000,35156008800000000000000,26835753384000000000000];
        uint80[11] memory VIP_PRESALE_COIN_AMOUNT_ROUND_2 = [58593348000000000000000,29296674000000000000000,17783081118000000000000,8115178698000000000000,58593348000000000000000,58593348000000000000000,58593348000000000000000,29296674000000000000000,58593348000000000000000,35156008800000000000000,26835753384000000000000];
        uint80[11] memory VIP_PRESALE_COIN_AMOUNT_ROUND_3 = [60368904000000000000000,30184452000000000000000,18321962364000000000000,8361093204000000000000,60368904000000000000000,60368904000000000000000,60368904000000000000000,30184452000000000000000,60368904000000000000000,36221342400000000000000,27648958032000000000000];

        uint256 nftReward = findNFTReward(_msgSender(), NFT_WALLETS, NFT_COIN_AMOUNT);
        uint256 presaleReward = findPresaleReward(_msgSender(), PRESALE_WALLETS, PRESALE_COIN_AMOUNT_ROUND_1, PRESALE_COIN_AMOUNT_ROUND_2);
        uint256 vipPresaleReward = findVIPPresaleReward(_msgSender(), VIP_PRESALE_WALLETS, VIP_PRESALE_COIN_AMOUNT_ROUND_1, VIP_PRESALE_COIN_AMOUNT_ROUND_2, VIP_PRESALE_COIN_AMOUNT_ROUND_3);
        uint256 total = nftReward + presaleReward + vipPresaleReward;
        if (total > 0) {
            _mint(_msgSender(), total);
        }
        emit ClaimReward(nftReward, presaleReward, vipPresaleReward);
        return (nftReward, presaleReward, vipPresaleReward);
    }

    function findNFTReward(address _addressToCheck, address[54] memory NFT_WALLETS, uint80[54] memory NFT_COIN_AMOUNT) private returns(uint256) {
        for (uint256 i = 0; i < NFT_WALLETS.length; i++) {
            if (NFT_WALLETS[i] == _addressToCheck && !vars().nftClaimed[_addressToCheck]) {
                vars().nftClaimed[_addressToCheck] = true;
                return NFT_COIN_AMOUNT[i];
            }
        }
        return 0;
    }

    function findPresaleReward(address _addressToCheck, address[29] memory PRESALE_WALLETS, uint80[29] memory PRESALE_COIN_AMOUNT_ROUND_1, uint80[29] memory PRESALE_COIN_AMOUNT_ROUND_2) private returns(uint256) {
        for (uint256 i = 0; i < PRESALE_WALLETS.length; i++) {
            if (PRESALE_WALLETS[i] == _addressToCheck) {
                return calculateRewardForPresale(_addressToCheck, i, PRESALE_COIN_AMOUNT_ROUND_1, PRESALE_COIN_AMOUNT_ROUND_2);
            }
        }
        return 0;
    }

    function findVIPPresaleReward(address _addressToCheck, address[11] memory VIP_PRESALE_WALLETS, uint80[11] memory VIP_PRESALE_COIN_AMOUNT_ROUND_1, uint80[11] memory VIP_PRESALE_COIN_AMOUNT_ROUND_2, uint80[11] memory VIP_PRESALE_COIN_AMOUNT_ROUND_3) private returns(uint256) {
        for (uint256 i = 0; i < VIP_PRESALE_WALLETS.length; i++) {
            if (VIP_PRESALE_WALLETS[i] == _addressToCheck) {
                return calculateRewardForVIPPresale(_addressToCheck, i, VIP_PRESALE_COIN_AMOUNT_ROUND_1, VIP_PRESALE_COIN_AMOUNT_ROUND_2, VIP_PRESALE_COIN_AMOUNT_ROUND_3);
            }
        }
        return 0;
    }

    function calculateRewardForPresale(address _addressToCheck, uint256 index, uint80[29] memory PRESALE_COIN_AMOUNT_ROUND_1, uint80[29] memory PRESALE_COIN_AMOUNT_ROUND_2) private returns(uint256) {
        uint256 reward = 0;
        if (!vars().presaleRound1Claimed[_addressToCheck]) {
            reward += PRESALE_COIN_AMOUNT_ROUND_1[index];
            vars().presaleRound1Claimed[_addressToCheck] = true;
        }
        if (!vars().presaleRound2Claimed[_addressToCheck] && CURRENT_PRESALE_ROUND == 2) {
            reward += PRESALE_COIN_AMOUNT_ROUND_2[index];
            vars().presaleRound2Claimed[_addressToCheck] = true;
        }
        return reward;
    }

    function calculateRewardForVIPPresale(address _addressToCheck, uint256 index, uint80[11] memory VIP_PRESALE_COIN_AMOUNT_ROUND_1, uint80[11] memory VIP_PRESALE_COIN_AMOUNT_ROUND_2, uint80[11] memory VIP_PRESALE_COIN_AMOUNT_ROUND_3) private returns(uint256) {
        uint256 reward = 0;
        if (!vars().vipPresaleRound1Claimed[_addressToCheck]) {
            reward += VIP_PRESALE_COIN_AMOUNT_ROUND_1[index];
            vars().vipPresaleRound1Claimed[_addressToCheck] = true;
        }
        if (!vars().vipPresaleRound2Claimed[_addressToCheck] && CURRENT_VIP_PRESALE_ROUND >= 2) {
            reward += VIP_PRESALE_COIN_AMOUNT_ROUND_2[index];
            vars().vipPresaleRound2Claimed[_addressToCheck] = true;
        }
        if (!vars().vipPresaleRound3Claimed[_addressToCheck] && CURRENT_VIP_PRESALE_ROUND == 3) {
            reward += VIP_PRESALE_COIN_AMOUNT_ROUND_3[index];
            vars().vipPresaleRound3Claimed[_addressToCheck] = true;
        }
        return reward;
    }

    function mintWholeCoins(address to, uint256 amount) public onlyOwner {
        _mint(to, amount * 10**decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
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