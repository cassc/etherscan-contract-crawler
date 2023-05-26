// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Royalties: Rarible
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract TunneyMunney is ERC721Enumerable, ReentrancyGuard, Ownable, RoyaltiesV2Impl {
    address payable private constant _ROYALTY_ADDRESS = payable(0x85b23C39D500Dc9BbDDc5a06b459FEf027f2F9d6);
    uint96 private constant _ROYALTY_PERCENTAGE_BASIS_POINTS = 400;
    uint256 private constant _MAXIMUM_SUPPLY = 5000;
    uint256 private constant _MAXIMUM_PURCHASE = 20;
    uint256 private constant _TUNNEY_MUNNEY_PRICE_PRESALE_AND_WHITELIST = 0.32 ether;
    uint256 private constant _TUNNEY_MUNNEY_PRICE_PUBLIC = 0.39 ether;
    uint256 private constant _TOTAL_PRESALE_NFT_COUNT = 2067;
    uint256 private constant _PRESALE_START_DATE = 1644588000;
    uint256 private constant _PRESALE_END_DATE = 1645160340;
    uint256 private constant _PUBLIC_START_DATE = 1645624800;
    uint256 private constant _PUBLIC_RESERVED_COUNT = 300;
    string private __baseURI = "ipfs://bafybwibxnu3vjzxxnhx2xpzfpdcajgtngw3l5ipvci7nkan2hiwjpne5ve/"; // Initialize with preview base URI

    // Wallet Address -> Token allowance mapping
    mapping(address => uint8) walletsPresale;

    // Wallet Address -> Boolean mappings
    mapping(address => bool) walletsPriceExempt;

    bytes4 private constant _INTERFACE_TO_ERC2981 = 0x2a55205a;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _presaleNFTsMinted;

    uint256 private _revealed = 0;

    constructor() ERC721("Tunney Munney", "TM") {
        // Start counter at 1
        _tokenIdTracker.increment();

        // Populate privileged wallets
        walletsPresale[0xc3f17178311899B068d0E2C86253E087DAB5ba8f] = 10;
        walletsPresale[0x92178Cdcf11E9f77F378503D05415D8BEb9E7bcF] = 10;
        walletsPresale[0x10a3d8178EE389208cBc5A5AaD05aA928a575C94] = 10;
        walletsPresale[0x659797d648C27c052aD95CBf7F8631f2FAD143c2] = 10;
        walletsPresale[0xb99426903d812A09b8DE7DF6708c70F97D3dD0aE] = 20;
        walletsPresale[0x810505953e7DB74b4d242773D797Ce15C68e0562] = 10;
        walletsPresale[0x08BB2f68B3A799337B14DE0f28E6E04f5DeF18a1] = 10;
        walletsPresale[0x65F65D1001dA3BAA411c5f5Fa4890713cE8f7F1D] = 10;
        walletsPresale[0x1010595F96Ab62b31BfeAc411Ec5f8f60DB5DC23] = 10;
        walletsPresale[0xA494876207Ae80D8669Dd347Fe11Fadae31c48E7] = 10;
        walletsPresale[0xe5d009bbcE5a5D7ab9c6c2B1b0A56F9B98297Cff] = 10;
        walletsPresale[0x740C569F20076F1D96be1222240d55A5eED29Df5] = 10;
        walletsPresale[0x88D78534Ccc1CA50070272E095788F9f35aD42Ba] = 10;
        walletsPresale[0x9d9B1A7be1CBA854bC4656Daa56A784b0ff056EC] = 5;
        walletsPresale[0x1fe1d8C07386d9605B548B575Fd16F3E9C5B8624] = 10;
        walletsPresale[0x60CED65A51922C9560d72631F658Db0df85BFf1f] = 10;
        walletsPresale[0x125e41f52D62464B3B57AAA2F24d7952359BAabC] = 10;
        walletsPresale[0x2931E2037376875555c0c247C66727fcA7F2648e] = 5;
        walletsPresale[0xbAfc553548242F0487a5370c54aB3048E826e514] = 5;
        walletsPresale[0xA41A4b84D74E085bd463386d55c3b6dDe6aa2759] = 10;
        walletsPresale[0xa3139f46A92cac9e5c445c5574BD10D522781037] = 10;
        walletsPresale[0x166EB9317E2540DFB7841a48a31Ba2eca5D4A9CF] = 20;
        walletsPresale[0x69E5eA08a0b708dE81906DB05B3F80644acE8D3f] = 10;
        walletsPresale[0xDd1F61E95CA9ec479de81f869921eD191DfeeBA8] = 10;
        walletsPresale[0xBcaa247d4E6678BC9D42114186c8e2dfC6b6c1bD] = 10;
        walletsPresale[0xfDc319B1327DE28C82BB283610dAFcF736a6D229] = 20;
        walletsPresale[0x0d74759D78B3A25E3c537FC3116D6f20Eb1C6dE6] = 10;
        walletsPresale[0xef30776Cd1A6cF63Acf9F72C7BF47Bd6272Ec4F9] = 10;
        walletsPresale[0x282F9b62a7Efe70eE66FF45578D22a72A3e18e01] = 10;
        walletsPresale[0x5Db6f7C9Ef71069216a176bbE6dF7f02D0fbDEfb] = 10;
        walletsPresale[0x48A75020408740589a9Fe6f7341c1B3c32d11AB8] = 10;
        walletsPresale[0xa269d981A584f6e122c4067Dfb1aA12AB1f2b38D] = 20;
        walletsPresale[0xe59E3d516f52c2E393F27232D163E51fcdA1cFe5] = 10;
        walletsPresale[0x67cf9c01afFEfaB6F99b706096bC36037f8D57c2] = 10;
        walletsPresale[0x221320D34800760E06B206aCd01e626e463eB03E] = 10;
        walletsPresale[0xc3A51fFd872d38737973EE0bbA6ffc14502a4ced] = 10;
        walletsPresale[0x7ca42F73F80C285bbE93d72f6DdEf00798e304D9] = 10;
        walletsPresale[0x44b1f231D743B9b73AaD305Fe307ce6f099c9AB4] = 10;
        walletsPresale[0xFd61F8599431ebff62DC81eFc571C1FBCb908DCF] = 10;
        walletsPresale[0xcBA88D0E47673352BdBe3Ce9788DF97bAfdC7DDE] = 10;
        walletsPresale[0x5583734DCAFc257581cc3a089C29C68aB440Da58] = 10;
        walletsPresale[0x2054B81AEd12840A17EA1fc66D233ba5B921b77d] = 1;
        walletsPresale[0xEA2761F45d274E4e314cF0Aa1A3304fD1fa69e68] = 20;
        walletsPresale[0xf1FE82F8ba582a7c3e10473C0F964C61A165CE08] = 10;
        walletsPresale[0x5Cb58a3fA9B02ae11f443b3Adc231172356EcCd7] = 10;
        walletsPresale[0x04513dc3DcdEA1A570EDe00273889F12a3f91589] = 10;
        walletsPresale[0x11b0B2DB7F2A85A8FD52917f586A278A1dBa3747] = 10;
        walletsPresale[0x7a8448C623DFD441C9B725bFAB8a002DaC25Dc75] = 10;
        walletsPresale[0x37CD8223Da1Be068Ab6BD9dE805431999EE89871] = 10;
        walletsPresale[0x49ca963Ef75BCEBa8E4A5F4cEAB5Fd326beF6123] = 10;
        walletsPresale[0x0851CeD43aab7Bc38b0fA4fBc4e3849634d2cA67] = 10;
        walletsPresale[0xAD35cAE6192acC0000b3cD2E07CF5108AF9fD015] = 10;
        walletsPresale[0x17410AC8E1e7C0296d3d1EE82C2bcE9Cf5250a5c] = 10;
        walletsPresale[0xA6EBe8639FCb0235dE905212c7ef0E2E8bb92989] = 10;
        walletsPresale[0xC914646a35786335D1226281D49edbf2d5d10485] = 10;
        walletsPresale[0x2002480606e08351B75682866642e947BD8C6bcf] = 10;
        walletsPresale[0x1adF685E4714f7c516b7bC813b3148e68bd8095c] = 20;
        walletsPresale[0x042EBfe134790c0f4e8A3699797Ac2D0833755B7] = 20;
        walletsPresale[0xB009aD5322412730E909CFC27B33c410C2B3D2Aa] = 10;
        walletsPresale[0xeF5AFBa8ec7258F96Fd7794717747AB4edD7605D] = 20;
        walletsPresale[0x0989A2A165fd66E4c64510328A1A6A9809Ef9418] = 10;
        walletsPresale[0x3EBCcC002Ff8aED4e982F0011fC2090799F844e0] = 10;
        walletsPresale[0xf2C8797A4815002f62007BB43a5462Aeb6c0b7b9] = 20;
        walletsPresale[0x070B0700bc42F080b970A58e592bCfb0357d11Fb] = 100;
        walletsPresale[0x61c3476D99E6fa4b66c5D7d46738e0EF6049C844] = 10;
        walletsPresale[0xA3f1b25bD254A0fb0CAA6c1a784a120da49F99EC] = 5;
        walletsPresale[0x4E05Bc165652140654e0F07b7cB429E5E1B0ed92] = 10;
        walletsPresale[0xB9E651ab75e2CE8a292F60a37d258F8BbcFF4368] = 20;
        walletsPresale[0x0a159aE5b783545D328d7799D523961D5Cc47eA0] = 10;
        walletsPresale[0xB5696E4057B9BA76616cEcB5A537eAcA7B3CDf54] = 10;
        walletsPresale[0xF349CC68cF9820247E3f7465fDaD807b6FbCA3CD] = 10;
        walletsPresale[0x993a69EFE73e3f87df4276E40E81E426385Fd2D8] = 10;
        walletsPresale[0x46aB683c6D4f42666826Bf6D6Da1C131B71318d8] = 10;
        walletsPresale[0xB8e52606BDa86d031f7c8E2D73C95cD020002F03] = 10;
        walletsPresale[0x5F4C5ef5Be53Db7631d5257348BBcD354159269A] = 10;
        walletsPresale[0xa4c36e63cAa42cAE77f7A8f72b9f4dD7f5740a05] = 10;
        walletsPresale[0x80f176A4009d91bAdA3ace15692418990Be8B0a7] = 10;
        walletsPresale[0xfBA32e383CF23992249ac0E5B113bc4d092bb668] = 10;
        walletsPresale[0x11C331c574C4F6a97B596fDf17266EBB7f0aCb91] = 20;
        walletsPresale[0xb5771A5cBE3fbf377c4969D58fcec943C898a905] = 10;
        walletsPresale[0x3AFe0eb50CFd574E260ea1f99dBBCA4FFB384E0e] = 10;
        walletsPresale[0x180c7F25A4DBA3310cC3746619256d1EDA5a4F5A] = 10;
        walletsPresale[0xA883B60C5EaD0EFD604b41a7C0509c3c6b81739e] = 10;
        walletsPresale[0x54296Fe0C5eB70bA5D893e744733ebB9846ece72] = 10;
        walletsPresale[0x0277278833e8A40197dF5D54fC425D123b0dc6D1] = 10;
        walletsPresale[0x572Ec7691b6aE768fD71098bf815785A7BAE6480] = 5;
        walletsPresale[0xA75323816443d49a1142f4E8d84F579bBc1B06fE] = 20;
        walletsPresale[0xa802d76BBc1adEB3aF9F8a73114856D39D52b4f9] = 10;
        walletsPresale[0x91F1d086B83584b5da60eC8c426c8f7b1023F42D] = 10;
        walletsPresale[0x12331ABA9762b52b69109a06B84F6404B75BB478] = 10;
        walletsPresale[0xe51BA9BE3751eff989e53e9d234915db2dFFFAb6] = 10;
        walletsPresale[0xcEB0eF1bA3F3A543ea13cD6953A1c5978C5BFD14] = 10;
        walletsPresale[0xFd61F8599431ebff62DC81eFc571C1FBCb908DCF] = 10;
        walletsPresale[0x3F1A421b47c5a9ec1025475a3Fd3e99cE20616A2] = 10;
        walletsPresale[0xF80CD8714d092771e6D95DB5ba7Cc5ae960948Dd] = 20;
        walletsPresale[0x2C79A929a7b6dBaC83bE6690F69737D873c58941] = 20;
        walletsPresale[0x3C2175a86eaffac2Ea609Ab4db6aB8e27Ff56Db2] = 10;
        walletsPresale[0x363e89408093719f67b7a674B74006989442116A] = 10;
        walletsPresale[0x5C27b3a3D46D8728f0eeEB9342F50AA13A27ff5f] = 10;
        walletsPresale[0x8097222c73362cD7F9f313aA720bB85A0FCA3C3c] = 10;
        walletsPresale[0x1e8eAA773F43844813F0842E15ac9B1fd40A2d92] = 10;
        walletsPresale[0xA98220f6dC5DFcA27ff19605a0a6D3E1dDE4CFE8] = 10;
        walletsPresale[0x9B7d8DbD54e5aeBbEDdb1722C9aB8956Bc2003A5] = 10;
        walletsPresale[0x19F87442CC618751406fFC37cc1A0e6111071030] = 20;
        walletsPresale[0x16faDFebD498813B63fBcd399571fbf1Cfa86550] = 10;
        walletsPresale[0x07cd101a8cd329a170d3A762d9d1645A2adB7f7A] = 10;
        walletsPresale[0x32d29de590eC186eC5B28710E7659D5Fb18419C0] = 10;
        walletsPresale[0x838d673258CEAb8E78c31a6088227DAc593B2d72] = 10;
        walletsPresale[0x18A0e52AD9d827E7BCb456f70888B45854dCf099] = 20;
        walletsPresale[0xbca572D1928b34Cf2e86b32295Cd27ff71A554Bf] = 10;
        walletsPresale[0x02aEB12821C2c18A61373B1931dE24b0c4f2e7f0] = 10;
        walletsPresale[0xc8d5E6d8da7792006D75BEE8856Af73037e20291] = 10;
        walletsPresale[0xAf2F83b3C5086BFa613A00f1637a920b50230e27] = 20;
        walletsPresale[0x056F154C822cB374508Cd318038C3d1e1230c377] = 10;
        walletsPresale[0x23CAF6c7BA9C315569Dba9A0B33265c58eEF020D] = 1;
        walletsPresale[0x85b23C39D500Dc9BbDDc5a06b459FEf027f2F9d6] = 25;
        walletsPresale[0x672E5F3D8f007826C64Fce3644938f596fB521E1] = 10;
        walletsPresale[0x2d15e7F2061eBdf16B37c62Df4ae2d3550a1617F] = 1;
        walletsPresale[0x3599564B917588C2a42C365B306dFDF6c34BBb55] = 10;
        walletsPresale[0x67644b68B24505c37EEc4Ed070C7fd78Aa560777] = 30;
        walletsPresale[0x4bd8FA4995a6C6CDe085e044cd09194Dc8CF533f] = 40;
        walletsPresale[0xFC5446EfE679f109f2772e45EA623CaA63791d5e] = 10;
        walletsPresale[0x091B9eC195247d5226cFC23D4d2F919B053B07c1] = 10;
        walletsPresale[0x195d76F290E660D56e25515a982C77EE4aaE7Ed1] = 10;
        walletsPresale[0x0925af5b3A31B6458357E8B01804B0a598c55bdD] = 20;
        walletsPresale[0x23Adbac7540eb3E7ab100FAb282fe006d5D72073] = 16;
        walletsPresale[0x7894c47148642C4396D9CE2929d8603Fb48Ad22A] = 10;
        walletsPresale[0xE3e97ede6F9995331A665687509be4Ecc5292cf4] = 10;
        walletsPresale[0xb8e01f384E385A6E1F0f37d0BE3aB39945A09F43] = 10;
        walletsPresale[0x73f7Ad858ae331C91BFDF9BBAE5E1b8A13f802b3] = 10;
        walletsPresale[0xc96722455ce56F676D4aD9343b3631d1fB4FD621] = 20;
        walletsPresale[0x180EE781e84A4f554562d1CC2ea677c6e8776302] = 2;
        walletsPresale[0xeE9F2A814b3e27dF5044b771973C7a7589478580] = 10;
        walletsPresale[0xCecE436D727DC4De835D8a0f2e930c7D29C556fD] = 20;
        walletsPresale[0x3A7b011311581e1D7FC5c97c558726aabB598aEE] = 30;
        walletsPresale[0x559de301EffC4338b2805f79B4e815F387332d23] = 10;
        walletsPresale[0xD2cc3E17c813e24C8a66e3CA2DeA7125EF64BFBE] = 20;
        walletsPresale[0x3F3c1471889604dE57ea3f17548014CeEB29Ce82] = 20;
        walletsPresale[0xE9581fb58eB6fdcBD45fcBA793149bAb6B0e0c4B] = 10;
        walletsPresale[0x4D2C5853F18eA553CF5716a9AF95bCD7f4095cc5] = 10;
        walletsPresale[0xa03d58D41b8978fF2F1DCA861faf0DC842E25F72] = 20;
        walletsPresale[0xB91105F277a6b5046Cf5faf3e8033eA31D4A0023] = 20;
        walletsPresale[0x7F3535b21F9747076d0f4a4d7C8328505ACC7A69] = 30;
        walletsPresale[0x4B4C57286a90e5DdB08a4Cb826F8209a0B15E677] = 50;
        walletsPresale[0x0C64D5DA9CBc8bbeE994166FF8dd47809DF0002b] = 5;
        walletsPresale[0xc436292c46E642185d96A570108C369f0F1a4Ccf] = 10;
        walletsPresale[0x28512542eB68f758fF60D68DB0fd00c0918D0C4a] = 10;
        walletsPresale[0x366036DB07c04A3fE224909E6067730DB491b3f9] = 10;
        walletsPresale[0xA38500bc712Ff5C52B146CdA22fF625d766C7D2F] = 10;
        walletsPresale[0x9c090D8EdABAF6ef7D77632a16d1Db67ae5d4DE4] = 10;
        walletsPresale[0x2Ba11189F73757319460967f569C5F1Ca5e44E8E] = 10;
        walletsPresale[0x9a1C13dcE181087d7C03A12E4CBE8A2a62312420] = 30;
        walletsPresale[0x6f67d99EE4CaA0056A3cd80F5b0019BF305aE706] = 10;
        walletsPresale[0x3f3599943d83Dd5C241Fb767A526b260fc2D62Ee] = 20;
        walletsPresale[0xa240eAdb80C2Cc19731Ad62EF856d6d225d6c7B8] = 10;
        walletsPresale[0x6Cd064f3c9028Af67eDdc24dd936c9f3FAeF963C] = 10;
        walletsPresale[0x91bf1E0Bc322450142383B88e515C3D798102377] = 20;
        walletsPresale[0xAA3d165d24C159F04EaBedE92e263E1840E4a5b8] = 10;
        walletsPresale[0xbA726320a6D963b3a9E7E3685fb12AEA71Af3f6d] = 10;
        
        walletsPriceExempt[0x1F1Fd08ED5f3dBC2158D96Cd5eC063A7A5AeBc67] = true;
        
    }

    function reveal() public onlyOwner {
        if (_revealed == 0) {
            _revealed = 1;
        }
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(_revealed == 0, "Cannot call setBaseURI() after Tunney Munney has been revealed."); // Must not be revealed yet
       __baseURI = newBaseURI;
    }

    function withdraw() public onlyOwner {
        // uint256 balance = address(this).balance;
        // payable(msg.sender).transfer(balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    function addPresaleWallet(address purchaser, uint8 tokenAllotment) public onlyOwner {
        walletsPresale[purchaser] = tokenAllotment;
    }

    function totalMinted() public view returns (uint256) {
        return _tokenIdTracker.current() - 1;
    }

    function calculateCost(address purchaser, uint256 numberOfTokensToMint) public view returns (uint256) {
        if (walletsPriceExempt[purchaser]) return 0;

        uint256 calculatedCost = 0;

        // Do not mutate walletPresale[msg.sender] until token is actually minted
        uint256 walletPresaleAllowance = walletsPresale[purchaser];

        while (numberOfTokensToMint > 0) {
            if (walletPresaleAllowance > 0) {
                walletPresaleAllowance = walletPresaleAllowance - 1;
            } else {
                if (block.timestamp < _PUBLIC_START_DATE) {
                    calculatedCost = calculatedCost + _TUNNEY_MUNNEY_PRICE_PRESALE_AND_WHITELIST;
                } else {
                    calculatedCost = calculatedCost + _TUNNEY_MUNNEY_PRICE_PUBLIC;
                }
            }

            numberOfTokensToMint = numberOfTokensToMint - 1;
        }

        return calculatedCost;
    }

    function mint(uint256 numberOfTokensToMint) public payable nonReentrant {
        require(block.timestamp > _PRESALE_START_DATE, "Minting hasn't started yet.");
        if (block.timestamp < _PRESALE_END_DATE) {
            require(numberOfTokensToMint <= walletsPresale[msg.sender], "Minting is active for presale collectors only. Please wait for whitelist or public minting to begin.");
        }

        require(numberOfTokensToMint <= _MAXIMUM_PURCHASE, "You can only mint 20 Tunney Munney at a time.");

        uint totalMintedTokens = totalMinted();
        uint numberOfTokensToMintNotInPresale = numberOfTokensToMint - Math.min(walletsPresale[msg.sender], numberOfTokensToMint);
        uint unmintedPresaleTokensReserved = _TOTAL_PRESALE_NFT_COUNT - _presaleNFTsMinted.current();

        require(totalMintedTokens + numberOfTokensToMint <= _MAXIMUM_SUPPLY, "Purchase exceeds available supply of Tunney Munney.");
        require(totalMintedTokens + numberOfTokensToMintNotInPresale + unmintedPresaleTokensReserved <= _MAXIMUM_SUPPLY, "Purchase exceeds available supply of Tunney Munney as there are un-minted NFTs reserved as part of the pre-sale.");
        require(calculateCost(msg.sender, numberOfTokensToMint) <= msg.value, "Amount of ether sent for purchase is incorrect.");

        // If before public mint date, reserve some tokens
        if (block.timestamp < _PUBLIC_START_DATE) {
            require(totalMintedTokens + unmintedPresaleTokensReserved + numberOfTokensToMintNotInPresale + _PUBLIC_RESERVED_COUNT <= _MAXIMUM_SUPPLY, "The remaining tokens have been reserved for the pre-sale collectors and the public mint.");
        }

        for (uint256 i = 0; i < numberOfTokensToMint; i++) {
            // If this was a walletPresale mint, subtract one from allowance.
            if (walletsPresale[msg.sender] > 0) {
                walletsPresale[msg.sender] = walletsPresale[msg.sender] - 1;
                _presaleNFTsMinted.increment();
            }

            _tokenIdTracker.increment();
            _safeMint(msg.sender, _tokenIdTracker.current() - 1);
        }
    }

    // Royalties Implementation: Rarible
    //    function setRoyalties(uint256 _tokenId) public onlyOwner {
    //        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    //        _royalties[0].value = _ROYALTY_PERCENTAGE_BASIS_POINTS;
    //        _royalties[0].account = _ROYALTY_ADDRESS;
    //        _saveRoyalties(_tokenId, _royalties);
    //    }

    // Royalties Implementation: ERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        if (_exists(_tokenId)) {
            return (_ROYALTY_ADDRESS, _salePrice * _ROYALTY_PERCENTAGE_BASIS_POINTS / 10000);
        } else {
            return (_ROYALTY_ADDRESS, 0);
        }
    }

    // OpenSea Contract-level metadata implementation (https://docs.opensea.io/docs/contract-level-metadata)
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(__baseURI, "contract"));
    }

    // Supports Interface Override
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        // Rarible Royalties Interface
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        // ERC2981 Royalty Standard
        if (interfaceId == _INTERFACE_TO_ERC2981) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }
}