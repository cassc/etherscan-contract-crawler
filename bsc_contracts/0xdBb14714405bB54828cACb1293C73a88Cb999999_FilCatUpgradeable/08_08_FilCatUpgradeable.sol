// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FilCatUpgradeable is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable
{
    uint256 public constant initTotalSupply = 21_000_000e18;
    uint256 public constant targetTotalSupply = 2_100_000e18;

    uint256 public burnPercentTotal;
    uint256 public burnPercentBuy;
    uint256 public nftPercentBuy;
    uint256 public ecoPercentBuy;
    uint256 public burnPercentSell;
    uint256 public nftPercentSell;
    uint256 public ecoPercentSell;
    uint256 public percent;

    mapping(address => bool) public lists;

    uint256 private keepAmount;

    address public nftSettlement;
    address public ecoAddr;
    address public mintAddr;

    function initialize(
        string memory name_,
        string memory symbol_,
        address mintAddr_,
        address owner
    ) public initializer {
        if (mintAddr_ == address(0)) {
            mintAddr_ = 0xfa201eAD5104aDC6f615a1Cec796A4cB594e56A6;
        }

        __ERC20_init(name_, symbol_);

        super._mint(mintAddr_, initTotalSupply);

        if (owner == address(0)) {
            owner = 0x5C59a0dbdd354d8b558FeF5FB1B7C87B7DCACC0A;
        }
        super._transferOwnership(owner);

        burnPercentTotal = 1000;
        burnPercentBuy = 0;
        nftPercentBuy = 0;
        ecoPercentBuy = 1000;
        burnPercentSell = 10;
        nftPercentSell = 10;
        ecoPercentSell = 10;
        percent = 1000;

        keepAmount = 1e9;

        nftSettlement = 0x08af05DD414AA3106b819d975C2Ee76FD1c1A705;
        ecoAddr = 0xc0469D37E475BB3484ACeD793E97dC9914411514;
        mintAddr = mintAddr_;

        initLists();
    }

    function initLists() private {
        address[100] memory listAddr = [
            0x343a0bAE8fE7884c65f7682EBFBe3ABA27f78A22,
            0x5D9a8ab529B8c865208519932e75a6b5a80dB189,
            0xeFb3DdB4d81100f1fAe652aCc1E8459231D95FD4,
            0x16D3cC001c773519e14F5709194B34d87dfaa6C9,
            0xEc997Ae8e5801eb2401862622cD27878de2A8618,
            0xe3732623148BFf3C1DD214A7892cd8Cf07036D6f,
            0x43891856B8fc8Dd19E4571e4b58613d233c87FD9,
            0x5374e111c21505F38d0b364934ff1e54f9d5A3B4,
            0x30d25b0c2A3A44Ce080410aCEa211cFcc793cD03,
            0x358c59284C56c624D6a87eAd4Bd9630Ad84F5943,
            0x4a4C8718E7781e3339090150479dfCCF286e1ccD,
            0x1eCfE1D08B37b95699E673c4D4Fbda82BBedBA56,
            0x2Acd907Ad5e8D1b45d9d9ad01E0AfE203cF6C4e7,
            0x2846d3712F889b1eCF51f698C633f9068c888Ecf,
            0x373DBDc54005242d6E5c877C2B7D6b76bdD8De18,
            0x4AFBE783dcc914E07D0877F9299f8CAd93d265C3,
            0xCe07c23c832E8cB70Bb8Dcd89F4C458c1eD4199A,
            0x893E76672b657FA336CAF39cfb8330c58b1Ea845,
            0x3E024AD8604a9C446292942C4dc3B384eC0bF1b9,
            0x31d490871364Ffc68Ca7745608c56bE9C2888659,
            0xe446aa5C8088Fd374558D1B261B1A66CFc19496F,
            0x20D3dE3199bA33Edb002A9C2BD315052220ef899,
            0x296E3b0207DF6194487eeB7e7Ee115d4A9319ADe,
            0x5e39ED2d84ae4e55E016b72025569061C28AB38c,
            0x66Fb2fCE912F894B2eaf0ece8950a9fE8cAb070d,
            0x4E8F736854cC182b2f30964c7748Ee7843bA7809,
            0xbB81c4a8028128d06f09230b5d4dc6e0F7250F9B,
            0x167eCC736bE566Ae88a0401BA4874ac7746caf40,
            0x7aff1b9ED61AD3961937a085fD3e4505D8369A0C,
            0xcd341B148c000DC1A285c1D4366C0A473f9ffe6A,
            0xaaDe84e5c0E4E368B5aF4f9CE623C68deE6baA70,
            0xA9d071d542b18C7204843e1Ba0461cF3d0cAd716,
            0x61A10946845C712EEa620b92e7A080B6fc90F397,
            0x719EDc548Adbd121f783B0b398c152C3C6260083,
            0x220Ba5ea69Bb1DBA79C043f48F239dcbF17914bF,
            0x688bE7670b2a7A641abF81AC98f21935eF6dA891,
            0xB8982C2B43Da9fD13756eC72656769a384708FF1,
            0xa25feC37E2B013B59C71D135703159715c13856C,
            0xeB41f1443bfa46f14260ADAEB14D001362f8c676,
            0x5f5573BF900Ff5772140d5076D2912162dcAE99A,
            0x76F4B7CDc3f626974E39D83cBf0e8950C3b32fcc,
            0xE21f85152118971904d8Ed0f73BF0D5F9B30DA9d,
            0x002E6c052E44e95f4c12292753F0c55185A46544,
            0x65fDF13E3Bf56bDefE6714d75c9d54299e056b7F,
            0x844846895ec179d64d7DCE6E8F39e754f3a4fb42,
            0x2ECB85f76D9D604b3E545A8FD449f8B28d2Fe1fD,
            0x4A2277b610652055C146CF1C6e5a602aA7596F1F,
            0xc2000Da8CaeB7f8a99DD212012d80B00028C3139,
            0xe57E9c9923B176f63b6F65991B51202D638ebDa5,
            0x562b77D4213BB66A09a6312fa215124Bb63682Cb,
            0xb65862c5e8Cb2615B24b0909c9e4F452f70e247C,
            0x8d3dBcA2439205653df31BA1660942c96e0b726d,
            0x4402D7358Ea02E7D27F9B9221177Cff7639F1555,
            0xB3415cF96B9eFFBB0D2342B0ade5f2651eeBB014,
            0xA469533c15C039008098f132C915f5f776Df3AD4,
            0xadFC635BDADe4227B94a65602f4b28aB7Da489B7,
            0x389E01a633C127D60bAEc1695eC4b177923EFaA6,
            0x4D766753f6819e7c8Dd006512498736D856f9eeE,
            0xd76e6E6D71568acce79D3701C30EC36f361Ce281,
            0x80F7bf374feD02F46b9EA9D8aC533e0A2Eb4A9dD,
            0xC6625d86FA5d1F6b8720218196740e647FE9e91E,
            0xf8EA25E620381657DCe0d18D94605aC302e5B314,
            0xB2eF78c49eb69d2472b33774dec73e01Daf4ebbb,
            0xCa333f7498f7c416eb27EEf9C5eD56e3C0d7781A,
            0xCf4f5f99141AFa46F2687d11eF4f3cc2249774Cd,
            0x3A55a455d69a213DB56A800aBD6833ABF115eDAB,
            0xdcb1Fb6755e7dAC675DB8AB0214d2435a1FBa61F,
            0x533C23145325538E7b330022a0a8889B1241a9B8,
            0xA484cfCA1068CCd87A467f7d3E637fE1ff610002,
            0x6F09E53Ec9C8BC8dEBF704eb8bfDD6a2E0f9e015,
            0x07362007EE9969FdB7076c88bE7F6b1B5Ae39b98,
            0x261A48BB716aa3Ec4F3067EB56058CFb7A00ecf6,
            0xef2e828ebD0dB37a9D67EE2B7E276C8b4BA1b2B8,
            0xa3eA1e8e281500537001F870cb91d01351846D7e,
            0x652Cb9815Af49C1ABf439De86280F7a019B48376,
            0x721A416c7F8289f1cdc191EffbFe2ec6a150A417,
            0x3f291562c8E3684F4DA076cC07030019b39d1E52,
            0x5EFEd337e1419FfaCc3c722Efe6aB321800Efee0,
            0x5DC1566D555f43A1Fc305DDFA4545da77A828A4d,
            0xE8f9325EE15E21466dA444c693E770a16dA1d85e,
            0xC65346C17aEb7ed829208b962561a840C9B015C6,
            0xc593Be79fe973De0C5956aE0D89Be545554AE349,
            0x821ddc41eB4123dF815aB4b18DF8B72bCaB3027F,
            0x09c506c8d3Cf5144F478A8b88f9FFf9cB69538F2,
            0x597562b3AE69559ecfFFc8693614dFC8fe7e320E,
            0xe74860c25eCB9a5BA7905d2FB6dC0C03F19927B9,
            0x28f0D29b3C1629f41b149Df8D945864E90219860,
            0xeF68abd4f40D3dcC9f420b4bE9A63FfeD4479A59,
            0xF65bE6E257F09914078F892EE1F2fb979cE4528c,
            0x5DC5DcaEc70A63801C6f3c000251Be592d995976,
            0x7B0742149Af590baf2f880444fABA537535b960F,
            0xE1f5f3e22E21e4b5cc4D2585E91D84C84db78a55,
            0x863BBc1509Eda3232040D75e0f066629f07ACeF1,
            0x67158E69e0E41B8B33Ba3A194b87457B604F8794,
            0x3D2d73Eaa0842d96bb81fF623538aEDa1C5bD0A1,
            0x2A798b27E6eaEd72A553922289b3ea1dDa56F8FF,
            0x26ea3e1d80296d6bcc1EEaD29c4d7d084808b33a,
            0x353Fe0705A22b308211b9b27b97c76e018EA554a,
            0xb5bdde652B73994D1031A2c88Fc373Bb510d8d7A,
            0x2D3CC5E2643B7F06BE86cf06bE08d58Aa570f740
        ];

        for (uint256 i = 0; i < listAddr.length; i++) {
            lists[listAddr[i]] = true;
        }
        lists[ecoAddr] = true;
        lists[nftSettlement] = true;
        lists[mintAddr] = true;
    }

    function setNFT(address addr) external onlyOwner {
        nftSettlement = addr;
    }

    function setEco(address addr) external onlyOwner {
        ecoAddr = addr;
    }

    function setPercentBuy(
        uint256 _burnPercent,
        uint256 _nftPercent,
        uint256 _ecoPercent
    ) external onlyOwner {
        burnPercentBuy = _burnPercent;
        nftPercentBuy = _nftPercent;
        ecoPercentBuy = _ecoPercent;
    }

    function setPercentSell(
        uint256 _burnPercent,
        uint256 _nftPercent,
        uint256 _ecoPercent
    ) external onlyOwner {
        burnPercentSell = _burnPercent;
        nftPercentSell = _nftPercent;
        ecoPercentSell = _ecoPercent;
    }

    function setBurnPercentTotal(uint256 _burnPercentTotal) external onlyOwner {
        burnPercentTotal = _burnPercentTotal;
    }

    function setMintAddr(address addr) external onlyOwner {
        mintAddr = addr;
    }

    function setKeepAmount(uint256 amount) external onlyOwner {
        keepAmount = amount;
    }

    function addList(address addr, bool isL) public onlyOwner {
        lists[addr] = isL;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 newAmount = _keepAmount(from, amount);

        if (lists[from] || lists[to]) {
            super._transfer(from, to, newAmount);
            return;
        }

        if (!isContract(from) && !isContract(to)) {
            super._transfer(from, to, newAmount);
            return;
        }

        _transferTax(from, to, newAmount);
    }

    function _keepAmount(
        address from,
        uint256 amount
    ) private view returns (uint256) {
        uint256 fromBalance = balanceOf(from);
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        if (fromBalance >= amount + keepAmount) {
            return amount;
        }

        if (amount <= keepAmount) {
            return 0;
        }

        return amount - keepAmount;
    }

    function _transferTax(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 burnPercent = 0;
        uint256 nftPercent = 0;
        uint256 ecoPercent = 0;

        // buy
        if (isContract(from)) {
            burnPercent = burnPercentBuy;
            nftPercent = nftPercentBuy;
            ecoPercent = ecoPercentBuy;
        } else {
            //sell
            burnPercent = burnPercentSell;
            nftPercent = nftPercentSell;
            ecoPercent = ecoPercentSell;

            if (burnPercentTotal > 0) {
                if (totalSupply() - amount > targetTotalSupply) {
                    super._burn(
                        mintAddr,
                        (amount * burnPercentTotal) / percent
                    );
                }
            }
        }

        uint256 burnAmount = (amount * burnPercent) / percent;
        if (totalSupply() - burnAmount <= targetTotalSupply) {
            burnAmount = 0;
        } else {
            super._burn(from, burnAmount);
        }

        uint256 ecoAmount = (amount * ecoPercent) / percent;
        super._transfer(from, ecoAddr, ecoAmount);

        uint256 nftAmount = (amount * nftPercent) / percent;
        super._transfer(from, nftSettlement, nftAmount);

        super._transfer(from, to, amount - burnAmount - ecoAmount - nftAmount);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}