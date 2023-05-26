// SPDX-License-Identifier: MIT

import "../interfaces/ITokenVestingV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity ^0.8.17;

contract PresaleClaim is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public token;
    ITokenVestingV2 public vesting;

    mapping(address => uint256) claimables;

    constructor(IERC20 token_, ITokenVestingV2 vesting_) {
        token = token_;
        vesting = vesting_;

        _initialSetupClaimables();
    }

    receive() external payable {}

    fallback() external payable {}

    function _initialSetupClaimables() internal {
        claimables[0x0bC013ED8e44079641b815BfAEdd5255B7f0bB43] = 3000000000000;
        claimables[0xbF6ce56CA3bF1031665f4B0f197Dd6C0D932394e] = 850000000000;
        claimables[0xcEaac8d7D9a58610F91f249a212b18681D116ee6] = 50000000000000;
        claimables[0x69687f8f4a5bFF644BBbC6313d746E4d190ccb39] = 29000000000000;
        claimables[0x259e48c0B83AF31bD7524b49d0810C49362045FB] = 22980000000000;
        claimables[0x1D3e5b13a6c98F5c3EdDD6Cb5331260E23BC833b] = 47000000000000;
        claimables[0xb176396e2915296Ff73aE5aABE1a79E8C07ce2E8] = 12000000000000;
        claimables[0x3F51de33b6E62862635A6b1f058F333dEBA4EFb7] = 3161000000000;
        claimables[0xdA506b735450A9310C6eF92f1651A130E7a4aE61] = 10134100000000;
        claimables[0x74525bCe2d626323Ce35Bf042D5b01E920d48817] = 650000000000;
        claimables[0x95D5397eDAFF6947268F74f95f165FFd157aA7F8] = 43620000000000;
        claimables[0x68D824B29B56d5624296D8F947815bedF59a32d7] = 48440000000000;
        claimables[0xf6226496C503e9ceC4D66f44DB137Bb209b0383b] = 49880000000000;
        claimables[0xc88Ac28Fbe88f78f2Eac228651328c7B35dE9EA2] = 1990000000000;
        claimables[0xBd81488D4A5736F0F4f64459848B1FF6CC258256] = 9350000000000;
        claimables[0x151ecE3e8a344bB7AAA4CD31c723c8382a65a469] = 6590000000000;
        claimables[0xB40457B43fBf82e3C75673128891b546582754d2] = 5000000000000;
        claimables[0x05B46ab28e6b09a537B2c85D45bc9636607b7339] = 6000000000000;
        claimables[0x62F5D0E79b18ebADB84c3C3bE21d6D2bEA99eB60] = 47250000000000;
        claimables[0x1eC8855C0C96e24E399ECfac3fBD61C98cFC93A0] = 40000000000000;
        claimables[0xDa99945960073790b7e2BD8e8681d55Bd06d0E38] = 12550000000000;
        claimables[0xa98c1f1D08c12A1e485Cf3539Ac63A1abcce2D23] = 49000000000000;
        claimables[0x1DA8469b048592baA0AA4fA28842a9E63bCfdC8c] = 50000000000000;
        claimables[0x908be06B0337048d79aC301b99109765E3AEeF70] = 1500000000000;
        claimables[0x82BdD90cc9FD198D37f3136bb8a267AB9daCfe54] = 1896500000000;
        claimables[0x18E62349F6DE44b68C5dBb714a56fdaF30149065] = 49000000000000;
        claimables[0xdE7cA9d44e6a63f5D09B47BEDd6871341C10991b] = 4735700000000;
        claimables[0x58515CEeFf459590f43a3D8fc689aa7dEdF199C9] = 4490000000000;
        claimables[0x4E0C09589d862485d724F3f8C1ff5745A52e0570] = 50000000000000;
        claimables[0xCF00E5b1f2ACDb9D471e60cf9A4657F2C5dAae7C] = 4400000000000;
        claimables[0x9864C4142d9792497f94448666089350522aF1fB] = 970000000000;
        claimables[0xa928858A824D30D893145a93423E8D8fb12dcd5c] = 25200000000000;
        claimables[0x701EC6fa016EB52fd8091F336b151a4CBD7C526C] = 2938500000000;
        claimables[0x9F76bD8c6aa46A48b720C042A283AeB154a40E5a] = 1000000000000;
        claimables[0x61e118296e48a5DCA8C62CB7ae06eee98Fb1248D] = 1349100000000;
        claimables[0xa7709810F04585eCAE04969DA3563405E4B8aCF9] = 1030000000000;
        claimables[0x8f08ce7ea46A8dB87f2EB9f308e70843B6361e4C] = 605800000000;
        claimables[0x07Ce6D36263e8B036510A162C73576cd15686a4c] = 2000000000000;
        claimables[0xEAee91DD760FDbA2D3DE57c7FE6B8E0e163C03c1] = 115100000000;
        claimables[0xf37E2cd8F8395e6068EdE1C411F2c80132dD5576] = 300000000000;
        claimables[0x0814Eb3d5F6deaa9b767F912e1132cc174E555a1] = 7270000000000;
        claimables[0x1Cf6aE8A2690491D1DBDd7aB14FAd4CB4EA4a4A8] = 800000000000;
        claimables[0x7bB835d1A53415faC47418e98Ae06945BfEDa894] = 8170000000000;
        claimables[0x12F9A99D371595C1404058A1B5bA15b9182088aE] = 1670000000000;
        claimables[0xB0345Af8Cc7C9C48A1DA404C8a7359a423B5AC84] = 740000000000;
        claimables[0x18650d5534036D2f4Ef0Ff8e62ea9643144d3d42] = 2650000000000;
        claimables[0xAe3b4109986C199C7fCfcdf19BB8Ae69E9B86E8e] = 2500000000000;
        claimables[0x80721A27D0226c4Ec4448eb3A38C66e2BDcce01b] = 1500000000000;
        claimables[0x32918e39d9fbc7C3A2e7F32FB8e994a81E34dCEA] = 1400000000000;
        claimables[0x10E115893E9Ded98aFF37444Fb3a4C0fFd9dBdDa] = 3803900000000;
        claimables[0x7c5788208F2EA5E491854B7974b6B9B3bBE8B55A] = 4762200000000;
        claimables[0x3B10adCDb9580e8ecB734FD0b9910c174F7434B0] = 2920000000000;
        claimables[0x7748100D03D6c63BAEBf7BB51E8128f53E033c79] = 4143200000000;
        claimables[0xCd340a153a69e764C134e4cf2647360c583eBb27] = 2735700000000;
        claimables[0xbA8Ae16329f3EeD926AD3aFEb951961b85723025] = 1190000000000;
        claimables[0x45b3ceABabCfb51816E5D380Be6c69dA4e202bc8] = 240000000000;
        claimables[0x5354435935c39538EF0a3Dcaaf9Baf304f102305] = 8720000000000;
        claimables[0x7d4FA4DE853e98992Bc303FFe51336B55c0154B8] = 8300000000000;
        claimables[0xCcdC2B70635a9f215771b99A123A9B02001f42d5] = 1250000000000;
        claimables[0xE2092085BE7081A8E7Cd428023163754FdFd5291] = 10000000000000;
        claimables[0xca8E702533290442805509b99ac038B2A89F7Fd8] = 1970000000000;
        claimables[0xc1D0684DC978448150487414564ab1987Ac6Cb79] = 960000000000;
        claimables[0x14a7f3D375d7B25109aE784ea69a6c376bc9121F] = 35221600000000;
        claimables[0x1886F79E65487bbA3E0F548824725Abf0933Be3B] = 2500000000000;
        claimables[0xFC155253419614e5159000f6b5265e9F62CecCA7] = 4501800000000;
        claimables[0x18D1f3ee65AC7Ab78f641df5A0C5E4E40F9aF88E] = 9760000000000;
        claimables[0x91dCEc2De622185aEeFa333ce5E7A0DD3d45D02D] = 807700000000;
        claimables[0x4b15f50dc7F2D0945409c99e2CC37144Ad51484e] = 450000000000;
        claimables[0x280dEFa2383558BED52caF1Ccb182B1908d90e4f] = 46910000000000;
        claimables[0xc30b6FcEA4Ff939463Cc47AEF1204E935Eb7f2db] = 400000000000;
        claimables[0x76C958789469598275D2626F5d8fbB17cE9d96a8] = 3000000000000;
        claimables[0x6ADa0214499A8c133eb96EAc08b5329dB7f94Bd7] = 2000000000000;
        claimables[0x09e51096a3104F1F65768150641b2Df840120A75] = 7395200000000;
        claimables[0xa72a890aF80550CBaD4b26DC2218c387d6ca37CB] = 399000000000;
        claimables[0x91bf42B99454719f902C64e439E14dC57fd4cc81] = 350000000000;
        claimables[0x90c1c1c3a37A14Ae826707120114E7513427357e] = 2360000000000;
        claimables[0x977C146C152FD702c45c809f3972Cbe1401Ddc97] = 2000000000000;
        claimables[0xd9860Ef5a57C318fBB001017e4216Ae37c7DDE7C] = 1655400000000;
        claimables[0xdad3f160F858AC82dF8AF5DEAb03EB2b1A7e44d5] = 10000000000000;
        claimables[0x239036E51441F38008A9F48268286c89D10b4504] = 1000000000000;
        claimables[0xF2536B12B668D531a589637eaefE37Ae8f102775] = 10175700000000;
        claimables[0xb3c2A3d6767D17b7258FE031bACdc81A2727c8B2] = 960000000000;
        claimables[0x6583976B33A35a411EaB9A377D7Cd3b66962F22a] = 100000000000;
        claimables[0x587B40b961f9f9Bc786eFAe782C5128699c652C1] = 1100000000000;
        claimables[0x4e582eca1CfD95737A342385262d058ba590509b] = 100000000000;
        claimables[0x8781eA519656cD6a7094d9a235128Cb102A40e06] = 610000000000;
        claimables[0x7917CDF81c9fd57377b7c4Abe556C81419AAdfBB] = 109700000000;
        claimables[0x752BCa44408aF4e2227828D6edEB75FC436B5C18] = 200000000000;
        claimables[0x65922Ef3e5BbE2FBe9feCD86109330AEb1dCC19a] = 100000000000;
        claimables[0x61Aa6Ec5d7ec5866426A02bA9326dff041C7883a] = 540000000000;
        claimables[0xDBA50998Acb58bF2b6e7d0401c43d2Fd6D8B2a1A] = 929000000000;
        claimables[0x0cFD707C2CA9Be2099F4c10E2038Ac2b28fF5106] = 748100000000;
        claimables[0xB1281994030101b8Ed2A7DEE529FC45349378A52] = 260000000000;
        claimables[0x0A68dAcbf117D2620835d5Ec579b7dd29131B095] = 507100000000;
        claimables[0x9B56d94a805e94d8052334425c91ffA052E8752B] = 150000000000;
        claimables[0x0Ae13f82ccdf49B82edf702c2500F471ccbd94fb] = 1000000000000;
        claimables[0xe613F5442E9860B3F17c7999dD1f39cdf16C986E] = 5000000000000;
        claimables[0x821Ce8DC31B77ae2002122b4235bC9FA1a05Ff7b] = 1190000000000;
        claimables[0x109Ca521AB17c358Db49f2CB4082f151E15074D0] = 157000000000;
        claimables[0xB3651418D9439b0d5e7f0f636c98F37018603c9D] = 200000000000;
        claimables[0x54c7Bb36cDAdC5911B629c80d1254235389dB4f0] = 1005600000000;
        claimables[0x3169703F8C027D6d731451d5bc17eEf0b44BFdE6] = 2936000000000;
        claimables[0xF76482644d7378E35532D27698631c04D02b98Cf] = 2000000000000;
        claimables[0xBdA698512618B6a3aB7Fc3515D5729b1f6561215] = 100000000000;
        claimables[0x8Afca32A8e6BB340e1B382207AC6a07fa1d9c87c] = 3840000000000;
        claimables[0x78A655809531E0Bc2B5AA462d75a3e49eA6Fc469] = 100000000000;
        claimables[0x7B43DfA4BD9e43C1f9B183Bb51d50aC07Ba9c8b2] = 1050000000000;
        claimables[0x5A147456e501b52bD158F5b5F8B6AEC2e9302758] = 1062200000000;
        claimables[0x7ACc344c4Bc17f1AeCA39CcC1DA94d91B8dbcA79] = 1000000000000;
        claimables[0xcb59900b4D7bEe2e90e833A13A0Bea0cd11BA7A2] = 328700000000;
        claimables[0x41bA7B1a70755DA87218Acf7aEE188C22e154cB3] = 220000000000;
        claimables[0x7C95950b386AF56D1D249db3A113C8413392169E] = 440000000000;
        claimables[0x876A0045559EbC1410b47E72d004F516701db86b] = 568100000000;
        claimables[0x77138cF8262E198CD8B4938AA3479517d3EFCb7d] = 1500000000000;
        claimables[0xb8557F391a4DF3C121dD03e7Ba05eD27edbaE06C] = 1530000000000;
        claimables[0x3393DC3a09bc994f51656032f5573B2280c377E8] = 110000000000;
        claimables[0xd46655aA42adf9469bCD618Db3DEaa5738D4CF9d] = 6000000000000;
        claimables[0x6254d18Ca9323d3E4BAf2AC7f6F1bbc1C5283a42] = 1724500000000;
        claimables[0xac18a58A0D2146Bdfa70B2B91a25EE5f53Ce13BF] = 100000000000;
        claimables[0x491Ab5A84e8A74cb970fdA9F857652972c4F49C5] = 311300000000;
        claimables[0xC483e89CBF45075501E5589ED9dD61ab710772A5] = 4900000000000;
        claimables[0xFfb96dAe13806b457Cb11996C7daccDD8ECDfc2f] = 200000000000;
        claimables[0x9e8F46CD5195D3a13FBa20c5CD6C7f146b889C1a] = 300000000000;
        claimables[0xd50FBdD79238613FB5288d742D5404e477886AD2] = 110000000000;
        claimables[0x16484Ffbae42E5a307342640F83e1c06cBAB2AF3] = 1990000000000;
        claimables[0xe9E8069379525f311AB95F548042281025B5e31a] = 959300000000;
        claimables[0x6D4a04679D53A1b1b5F82424c97889507640D8e6] = 380000000000;
        claimables[0xBaBEcBFF0237F020Fc137b0641286f23c4FF7d22] = 200000000000;
        claimables[0x32F14e61124859E707Bc71564Bf7a3892f0183d2] = 100000000000;
        claimables[0xd1089b14c64744E6ca0Efb8AefD0301767f1ba53] = 527500000000;
        claimables[0xe1331b158Fa415059Ef89A5f5d96478c49A3973C] = 10980000000000;
        claimables[0x655026A4Ca6331b3f90675E606D59b3C45B2282B] = 216800000000;
        claimables[0x9032efA1B22bBcD78cB85eBD88377Da4E87Ef66F] = 430000000000;
        claimables[0xF6AAB7CA44C4f80b8871150c549285b1300caf05] = 2795700000000;
        claimables[0xd9154f020AAF0E2E09C53de07A2B9DeeD2C7ACA5] = 490000000000;
        claimables[0xb34aC934410BFBb356Dab0463c2678C3C37f7637] = 353600000000;
        claimables[0xb73F79557337C4eEb0628888F6ea7985b048Ca57] = 100000000000;
        claimables[0xD56669d887d89B92517B95CcD2cbFf126b39459e] = 233000000000;
        claimables[0xf4751B0Fb43904928d48A81cD7bFaD63f1F3348a] = 10000000000000;
        claimables[0x6A044989d6586477378d8bEa75E83b72E9e37BFd] = 497000000000;
        claimables[0xDC195Ca67a27Df68d92B18EbC476728328A2557e] = 100000000000;
        claimables[0x510c93F5f6c9a5f6015d2B332cEe2DEba9A41940] = 150000000000;
        claimables[0xE20E98894E79b1327204018f61b674CeF479F7c3] = 2116400000000;
        claimables[0xC8F2DA31565C2b1594373e24C1b5d9Dd6eC8146d] = 2089800000000;
        claimables[0x0D34806CA42B46f91F95Bd0641b78a43Ff9CAC05] = 185400000000;
        claimables[0xFa021B803FCcE5DC418215Fc07CF0d6541f5A472] = 2200000000000;
        claimables[0x7D71f486c7207a232ceD5cf19b04ab01D4975f94] = 100000000000;
        claimables[0x3890509fEA9B07Dc3CC43dC713B4eA0A4b48bC95] = 2740000000000;
        claimables[0x9b5f620212C16Ca6ce3fD75a1B9a27b4beE9F2D7] = 1504200000000;
        claimables[0xbBF4aA71D717536814cc3a53A4C082A331348B86] = 2600000000000;
        claimables[0x7c3395771bE3258547D2A9091Cf9cD9c6c029423] = 138000000000;
        claimables[0x5616E90b15FC137702F7c876DAC3c59f073C73c6] = 100000000000;
        claimables[0x8738e68ff67cB91EfEC0e6AF16a6319db556BadE] = 200000000000;
        claimables[0x6d12aAadE13aB30241cEAf2FaD4eb722204b0a04] = 718300000000;
        claimables[0x4a091D2962c66b43474d5490535cAe25c7Aef47E] = 240000000000;
        claimables[0x51683c7825a59BfDd8f1558EAf138d03D0DEAB28] = 5080000000000;
        claimables[0x3a2E43E50e1c09968Cf179ddfc3fDeF5e62AA52F] = 7500000000000;
        claimables[0xE2eFED1A422dF747b69608ac30Ad407874826e2f] = 199900000000;
        claimables[0xb1C521B8bcd55b34f48f498ef8c1a4c9a366D157] = 1000000000000;
        claimables[0x7F818B4ccEaa425d5638CCD31827A4E0731652FE] = 300000000000;
        claimables[0x6EbBA605d61ffB40055e53194c257932BB28A849] = 200000000000;
        claimables[0x925420c3CEf514A5CD1D8d1A46050571CCcB228b] = 850000000000;
        claimables[0xa81d2c424C88fA20DB8954C6B544277B9fc20033] = 213500000000;
        claimables[0x5185f290cB937666c084e7ae0e1bB4eCCDc1aac2] = 4156100000000;
        claimables[0xAD621f70B68b44E471E70A06C625b08963b1a4c2] = 110000000000;
        claimables[0xedB8BC9a18c66D73202B715AcceE0A8fbc5C7682] = 100000000000;
        claimables[0x8CbEc562046c41f882b6b81c98CdCFd02D9A3f1D] = 8910400000000;
        claimables[0x81E1775a07AC91fA12040fAeF55C40209b76E504] = 180000000000;
        claimables[0x7bAA0DDbf87BDaF5d68783523fa520ec24076Bd5] = 110000000000;
        claimables[0x9798467342d248dcd030e38e3725bA67A375FEC5] = 165000000000;
        claimables[0x0014615C91a6a39d0E4F56278fD74f1A04022c78] = 2929900000000;
        claimables[0x430e8BC9EFE1961E8108Be9B0938745e8B61F205] = 100000000000;
        claimables[0xCFd1231E396ccd570F6bE5704A5B4485D6e89c9d] = 100000000000;
        claimables[0x29a6ef18bF18F1343978Bc3260dd2ea467Dc9139] = 100000000000;
        claimables[0xD6783694Bc5FD6DE00643c34fee0198781AD7eBD] = 220000000000;
        claimables[0x52C07B5422b0B931926C088479B03fD07e899a4E] = 500000000000;
        claimables[0x5e5F036237dDeEd07B646c38C5C0522414701285] = 120000000000;
        claimables[0xfFc5B06EF1B629065bE1A51dae3b92112c0170e7] = 1400000000000;
        claimables[0xf9061D9686503e5E7E5f3b2443a188Da2AF9c48e] = 190000000000;
        claimables[0x8ca1826D1f478fDA46eDdE0aaa53D5acaa4F50ad] = 378200000000;
    }

    function setClaimableBalance(address address_, uint256 amount_) public onlyOwner {
        claimables[address_] = amount_;
    }

    function setToken(IERC20 token_) public onlyOwner {
        token = token_;
    }

    function setVestingContract(ITokenVestingV2 vesting_) public onlyOwner {
        require(address(vesting_) != address(0x0), "Vesting contract should not be zero address");
        vesting = vesting_;
    }

    function withdraw(uint256 amount) external nonReentrant onlyOwner {
        SafeERC20.safeTransfer(token, msg.sender, amount);
    }

    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function getClaimableBalance(address account_) public view returns (uint256) {
        return claimables[account_];
    }

    function claim() public nonReentrant {
        require(claimables[_msgSender()] > 0, "No claimable token");

        uint256 balance = claimables[_msgSender()];
        uint256 currentTime = getCurrentTime();

        claimables[_msgSender()] = 0;

        uint256 tgeAmount = balance / 100 * 10;
        uint256 firstVestAmount = balance / 100 * 10;
        uint256 secondVestAmount = (balance - tgeAmount - firstVestAmount);

        // Send vest tokens into vesting contract
        SafeERC20.safeTransfer(token, address(vesting), (secondVestAmount + firstVestAmount));

        // Create vesting schedule after 3 month (%10 directly unlock)
        vesting.createVestingSchedule(
            _msgSender(),
            (currentTime + (3 * 30 days)),
            0,
            (1),
            (1),
            false,
            firstVestAmount
        );

        // Create vesting schedule after 3 month linear daily for 9 month
        vesting.createVestingSchedule(
            _msgSender(),
            (currentTime + (3 * 30 days)),
            0,
            (9 * 30 days),
            (1 days),
            false,
            secondVestAmount
        );

        // Send %10 for TGE to user
        SafeERC20.safeTransfer(token, _msgSender(), tgeAmount);
    }

}