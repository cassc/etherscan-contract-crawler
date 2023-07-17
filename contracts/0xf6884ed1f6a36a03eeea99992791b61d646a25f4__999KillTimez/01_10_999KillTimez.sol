//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


// █████╗  █████╗  █████╗     ██╗  ██╗██╗██╗     ██╗  ████████╗██╗███╗   ███╗███████╗███████╗
//██╔══██╗██╔══██╗██╔══██╗    ██║ ██╔╝██║██║     ██║  ╚══██╔══╝██║████╗ ████║██╔════╝╚══███╔╝
//╚██████║╚██████║╚██████║    █████╔╝ ██║██║     ██║     ██║   ██║██╔████╔██║█████╗    ███╔╝
// ╚═══██║ ╚═══██║ ╚═══██║    ██╔═██╗ ██║██║     ██║     ██║   ██║██║╚██╔╝██║██╔══╝   ███╔╝
// █████╔╝ █████╔╝ █████╔╝    ██║  ██╗██║███████╗███████╗██║   ██║██║ ╚═╝ ██║███████╗███████╗
// ╚════╝  ╚════╝  ╚════╝     ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝




    error SaleNotStarted();
    error RoundSoldOut();
    error PublicSaleStillLive();
    error MaxMints();
    error SoldOut();
    error ValueTooLow();
    error NotWL();
    error NotVIP();
    error NotAllowedToCreateReferralCodes();



/*
Contract created by Ivan Rubio
Deployment By: LunarXY
*/
import "ERC721A.sol";
import "ERC721AQueryable.sol";
import "ECDSA.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";


contract _999KillTimez is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    //@dev adjust these values for your collection
    uint public maxSupply = 666;

    uint public wlMintCounter = 169;

    uint public vipMintCounter = 130;
    uint public maxVipMints = 999;

    uint public publicPrice = 0.0199 ether;
    uint public whitelistPrice = 0 ether;


    //@dev byte-pack bools and address to save gas
    bool publicSaleStarted = true;
    bool whiteListStarted = true;
    bool vipStarted = true;

    mapping(address => uint) public giftReceived;

    /*@dev Reference Address to Compare ECDSA Signature
    Fill this in with your own WL Address
    To learn more about signatures check out
    https://docs.ethers.io/v5/api/signer/#:~:text=A%20Signer%20in%20ethers%20is,on%20the%20sub%2Dclass%20used.*/
    address private vipAddress = 0x150B0Bed2B8a0D293252b9910cc9ee47FeAb51Aa;
    address private whitelistAddress = 0xECDA7Af07E5F228fBF2e9f23186b251c3dA9deB6;

    /*
    43% Community Wallet
    13% Development Team
    28% Creador
    12% Community Manager
    4% Marketing*/
    address private communityPayoutAddress = 0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA;
    address private developmentPayoutAddress = 0x78Cca4e539EB68cc0b01A11034434BA67314456C;
    address private creatorPayoutAddress = 0x5F7F0560C7d8ECfD341620888df2BB072e064BF0;
    address private communityManagerPayoutAddress = 0x61C2138d7A63bf100eEAedE90a55a65736A3DFAD;
    address private marketingPayoutAddress = 0x58b54887DE1aE8D85351BE9112355465F9cD438D;


    /* @dev Used in TokenURI Function for exchanges.
        For more information about this standard check out
        https://docs.opensea.io/docs/metadata-standards
    */
    string public baseURI = "https://api.nft.lunarxy.com/v1/nft/metadata/999killtimez/";
    string public uriSuffix = ".json";


    // @dev these mappings track how many one has minted on public and WL respectively
    mapping(address => uint) public publicMints;
    mapping(address => uint) public wlMints;
    mapping(address => uint) public vipMints;
    //This is where the staking contract will be stored.

    constructor()
    ERC721A("999KillTimez", "999KT")
    {
        wlMints[0x04d619ff29c74e17e5FEf02E543de668C0296519] = 2;
        wlMints[0x0EDf79CBd5BEF41e59D8e4ddAd352DDf6aAb6560] = 1;
        vipMints[0x0EDf79CBd5BEF41e59D8e4ddAd352DDf6aAb6560] = 7;
        publicMints[0x0EDf79CBd5BEF41e59D8e4ddAd352DDf6aAb6560] = 3;
        giftReceived[0x0EDf79CBd5BEF41e59D8e4ddAd352DDf6aAb6560] = 1;
        wlMints[0x766D5f2d38589aC4702184199c540cD97565B13B] = 5;
        vipMints[0x766D5f2d38589aC4702184199c540cD97565B13B] = 2;
        giftReceived[0x766D5f2d38589aC4702184199c540cD97565B13B] = 1;
        wlMints[0x47B73B6B53152470052AfD207017d812C73e26D6] = 3;
        vipMints[0x47B73B6B53152470052AfD207017d812C73e26D6] = 4;
        giftReceived[0x47B73B6B53152470052AfD207017d812C73e26D6] = 1;
        wlMints[0x40d429507e88f69F41DF6a1A822711E12649dE04] = 1;
        vipMints[0x18B1146573cEbdF82D8Ce7D7698D172499C95755] = 2;
        wlMints[0x9e468A8E352ED80BB7e09CB0aB6E49ef77741938] = 1;
        giftReceived[0x9e468A8E352ED80BB7e09CB0aB6E49ef77741938] = 1;
        wlMints[0xb69C70A15954316920896cf11cEC942bB3CeA06f] = 16;
        vipMints[0xb69C70A15954316920896cf11cEC942bB3CeA06f] = 12;
        publicMints[0xb69C70A15954316920896cf11cEC942bB3CeA06f] = 2;
        giftReceived[0xb69C70A15954316920896cf11cEC942bB3CeA06f] = 2;
        wlMints[0x7A0CdF925C4796519ddd2DCDfe63E2d6880E1FFF] = 3;
        giftReceived[0x7A0CdF925C4796519ddd2DCDfe63E2d6880E1FFF] = 1;
        publicMints[0x94a7A0cCBbf54E37b154737B8cc1ecB5cC5310BB] = 3;
        wlMints[0x30faC264384582Fe99411c4D893F7e0b838708DA] = 3;
        vipMints[0x30faC264384582Fe99411c4D893F7e0b838708DA] = 1;
        wlMints[0xd434B922e30193f9181284382517884c94350f9e] = 12;
        vipMints[0xd434B922e30193f9181284382517884c94350f9e] = 16;
        giftReceived[0xd434B922e30193f9181284382517884c94350f9e] = 4;
        wlMints[0x878bA4295Ee46b2Fc055cB216218d0445a3f1DAF] = 1;
        giftReceived[0x878bA4295Ee46b2Fc055cB216218d0445a3f1DAF] = 1;
        vipMints[0xc6513B70666C4a682D8FECF16B4D45BB8a2DA534] = 1;
        publicMints[0xc6513B70666C4a682D8FECF16B4D45BB8a2DA534] = 3;
        wlMints[0xC59297F3aCDe356f546c925FD5943a860A296603] = 5;
        giftReceived[0xC59297F3aCDe356f546c925FD5943a860A296603] = 1;
        publicMints[0xd6E0F82a4bD119Ee24b8708a880e6167ed5a7a7E] = 1;
        wlMints[0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49] = 8;
        vipMints[0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49] = 18;
        publicMints[0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49] = 6;
        giftReceived[0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49] = 6;
        wlMints[0xb5105c731c5F3ec29eE4E84C7e0D45e8Ef43B300] = 8;
        vipMints[0xb5105c731c5F3ec29eE4E84C7e0D45e8Ef43B300] = 15;
        publicMints[0xb5105c731c5F3ec29eE4E84C7e0D45e8Ef43B300] = 3;
        giftReceived[0xb5105c731c5F3ec29eE4E84C7e0D45e8Ef43B300] = 3;
        wlMints[0xc170A147c93a19a2D77385545C13FDC09555e622] = 1;
        vipMints[0x98eEd6Ce0b0b4bF302315C50d0Fe694305242105] = 7;
        wlMints[0xCEA431A6f20889670e59e2CEeb5E41Ba0d6d88c3] = 1;
        vipMints[0xCEA431A6f20889670e59e2CEeb5E41Ba0d6d88c3] = 4;
        giftReceived[0xCEA431A6f20889670e59e2CEeb5E41Ba0d6d88c3] = 1;
        wlMints[0x73F43E66041f8804DaB52592d1c0f1C26fF6fefe] = 5;
        giftReceived[0x73F43E66041f8804DaB52592d1c0f1C26fF6fefe] = 1;
        vipMints[0x90c0F855979018daBC6b517f39FAddc90Acae292] = 2;
        wlMints[0x62e3E1f39025fdADD7454704C13B7b2AE8C1A8EA] = 22;
        vipMints[0x62e3E1f39025fdADD7454704C13B7b2AE8C1A8EA] = 12;
        giftReceived[0x62e3E1f39025fdADD7454704C13B7b2AE8C1A8EA] = 2;
        vipMints[0x73cFA71eD8EF82c85B28D9CbB58365cB22191141] = 1;
        publicMints[0x5Fa60DB0C6422f09925a45eae367F5C205feC961] = 6;
        wlMints[0xAf46585a4d22dAB188D3c7c4bE08c9e2d1C980d5] = 2;
        vipMints[0xAf46585a4d22dAB188D3c7c4bE08c9e2d1C980d5] = 7;
        publicMints[0xAf46585a4d22dAB188D3c7c4bE08c9e2d1C980d5] = 1;
        giftReceived[0xAf46585a4d22dAB188D3c7c4bE08c9e2d1C980d5] = 2;
        wlMints[0x305Bf946250A380b160ae6FD4dF64AeeA7813677] = 2;
        vipMints[0x305Bf946250A380b160ae6FD4dF64AeeA7813677] = 1;
        wlMints[0xc55f0572178d6A6217Be36d3f756eF7f5a7F396c] = 4;
        giftReceived[0xc55f0572178d6A6217Be36d3f756eF7f5a7F396c] = 1;
        wlMints[0x1D884A8cB1a18E3435112d503897B40dE464F822] = 2;
        giftReceived[0x1D884A8cB1a18E3435112d503897B40dE464F822] = 2;
        wlMints[0x2C077C051fdBaDc8388427E3aD30059E050b5f8f] = 5;
        vipMints[0x2C077C051fdBaDc8388427E3aD30059E050b5f8f] = 7;
        giftReceived[0x2C077C051fdBaDc8388427E3aD30059E050b5f8f] = 1;
        wlMints[0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA] = 11;
        vipMints[0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA] = 10;
        publicMints[0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA] = 5;
        giftReceived[0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA] = 1;
        wlMints[0x37667d93e047e1231e2CE3BC7a762dD36bCf6aFE] = 2;
        giftReceived[0x37667d93e047e1231e2CE3BC7a762dD36bCf6aFE] = 1;
        publicMints[0x9b95d8f7c44efc92B03ae2f17E2344E67de04F96] = 1;
        wlMints[0x7c0a1f789c683B6636837C9D51c8AA2469d30ed6] = 5;
        vipMints[0x7c0a1f789c683B6636837C9D51c8AA2469d30ed6] = 1;
        giftReceived[0x7c0a1f789c683B6636837C9D51c8AA2469d30ed6] = 2;
        wlMints[0x2FFb3aA4359be1DAa675E13882F24a530cF273f9] = 1;
        giftReceived[0x2FFb3aA4359be1DAa675E13882F24a530cF273f9] = 1;
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 2);
        _mint(0x98eEd6Ce0b0b4bF302315C50d0Fe694305242105, 1);
        _mint(0xc6513B70666C4a682D8FECF16B4D45BB8a2DA534, 1);
        _mint(0xb5105c731c5F3ec29eE4E84C7e0D45e8Ef43B300, 5);
        _mint(0x40d429507e88f69F41DF6a1A822711E12649dE04, 1);
        _mint(0x2C077C051fdBaDc8388427E3aD30059E050b5f8f, 2);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 1);
        _mint(0xd434B922e30193f9181284382517884c94350f9e, 1);
        _mint(0x2C077C051fdBaDc8388427E3aD30059E050b5f8f, 1);
        _mint(0xd434B922e30193f9181284382517884c94350f9e, 2);
        _mint(0xc55f0572178d6A6217Be36d3f756eF7f5a7F396c, 5);
        _mint(0x644580B17fd98F42B37B56773e71dcfD81eff4cB, 2);
        _mint(0xfC6f3a3874c75c887Df42605FA0150b9cdBca81E, 2);
        _mint(0x7A0CdF925C4796519ddd2DCDfe63E2d6880E1FFF, 4);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 1);
        _mint(0x98eEd6Ce0b0b4bF302315C50d0Fe694305242105, 1);
        _mint(0x62e3E1f39025fdADD7454704C13B7b2AE8C1A8EA, 4);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 1);
        _mint(0x8AC65B1D807EB2C8BbB04B90c3Aee2E49aaCD6A7, 1);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 1);
        _mint(0xCEA431A6f20889670e59e2CEeb5E41Ba0d6d88c3, 2);
        _mint(0x40d429507e88f69F41DF6a1A822711E12649dE04, 1);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 1);
        _mint(0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA, 1);
        _mint(0x766D5f2d38589aC4702184199c540cD97565B13B, 2);
        _mint(0x30faC264384582Fe99411c4D893F7e0b838708DA, 1);
        _mint(0xc170A147c93a19a2D77385545C13FDC09555e622, 1);
        _mint(0x2FFb3aA4359be1DAa675E13882F24a530cF273f9, 2);
        _mint(0x644580B17fd98F42B37B56773e71dcfD81eff4cB, 2);
        _mint(0xb5105c731c5F3ec29eE4E84C7e0D45e8Ef43B300, 1);
        _mint(0x73F43E66041f8804DaB52592d1c0f1C26fF6fefe, 2);
        _mint(0x98eEd6Ce0b0b4bF302315C50d0Fe694305242105, 1);
        _mint(0x2C077C051fdBaDc8388427E3aD30059E050b5f8f, 1);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 1);
        _mint(0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA, 1);
        _mint(0x9e468A8E352ED80BB7e09CB0aB6E49ef77741938, 1);
        _mint(0xAf46585a4d22dAB188D3c7c4bE08c9e2d1C980d5, 2);
        _mint(0x90c0F855979018daBC6b517f39FAddc90Acae292, 2);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 3);
        _mint(0x98eEd6Ce0b0b4bF302315C50d0Fe694305242105, 1);
        _mint(0xfC6f3a3874c75c887Df42605FA0150b9cdBca81E, 1);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 1);
        _mint(0xd434B922e30193f9181284382517884c94350f9e, 2);
        _mint(0x766D5f2d38589aC4702184199c540cD97565B13B, 2);
        _mint(0xb5105c731c5F3ec29eE4E84C7e0D45e8Ef43B300, 1);
        _mint(0x73F43E66041f8804DaB52592d1c0f1C26fF6fefe, 1);
        _mint(0x7c0a1f789c683B6636837C9D51c8AA2469d30ed6, 2);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 1);
        _mint(0x0EDf79CBd5BEF41e59D8e4ddAd352DDf6aAb6560, 2);
        _mint(0x18B1146573cEbdF82D8Ce7D7698D172499C95755, 2);
        _mint(0x7c0a1f789c683B6636837C9D51c8AA2469d30ed6, 2);
        _mint(0x2C077C051fdBaDc8388427E3aD30059E050b5f8f, 1);
        _mint(0xd434B922e30193f9181284382517884c94350f9e, 6);
        _mint(0x98eEd6Ce0b0b4bF302315C50d0Fe694305242105, 1);
        _mint(0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA, 2);
        _mint(0x7c0a1f789c683B6636837C9D51c8AA2469d30ed6, 2);
        _mint(0x644580B17fd98F42B37B56773e71dcfD81eff4cB, 1);
        _mint(0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA, 1);
        _mint(0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49, 1);
        _mint(0x1D884A8cB1a18E3435112d503897B40dE464F822, 4);
        _mint(0x73cFA71eD8EF82c85B28D9CbB58365cB22191141, 1);
        _mint(0x62e3E1f39025fdADD7454704C13B7b2AE8C1A8EA, 6);
        _mint(0x878bA4295Ee46b2Fc055cB216218d0445a3f1DAF, 2);
        _mint(0xc6513B70666C4a682D8FECF16B4D45BB8a2DA534, 3);
        _mint(0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA, 1);
        _mint(0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49, 1);
        _mint(0xc6513B70666C4a682D8FECF16B4D45BB8a2DA534, 1);
        _mint(0xb5105c731c5F3ec29eE4E84C7e0D45e8Ef43B300, 3);
        _mint(0x62e3E1f39025fdADD7454704C13B7b2AE8C1A8EA, 3);
        _mint(0x0EDf79CBd5BEF41e59D8e4ddAd352DDf6aAb6560, 2);
        _mint(0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49, 2);
        _mint(0xAf46585a4d22dAB188D3c7c4bE08c9e2d1C980d5, 2);
        _mint(0xd434B922e30193f9181284382517884c94350f9e, 7);
        _mint(0x98eEd6Ce0b0b4bF302315C50d0Fe694305242105, 1);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 1);
        _mint(0x98eEd6Ce0b0b4bF302315C50d0Fe694305242105, 1);
        _mint(0x37667d93e047e1231e2CE3BC7a762dD36bCf6aFE, 3);
        _mint(0xb5105c731c5F3ec29eE4E84C7e0D45e8Ef43B300, 1);
        _mint(0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA, 1);
        _mint(0x62e3E1f39025fdADD7454704C13B7b2AE8C1A8EA, 5);
        _mint(0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49, 4);
        _mint(0xCEA431A6f20889670e59e2CEeb5E41Ba0d6d88c3, 1);
        _mint(0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49, 3);
        _mint(0xb5105c731c5F3ec29eE4E84C7e0D45e8Ef43B300, 1);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 2);
        _mint(0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA, 2);
        _mint(0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49, 1);
        _mint(0xAf46585a4d22dAB188D3c7c4bE08c9e2d1C980d5, 1);
        _mint(0x40d429507e88f69F41DF6a1A822711E12649dE04, 1);
        _mint(0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49, 6);
        _mint(0x0EDf79CBd5BEF41e59D8e4ddAd352DDf6aAb6560, 1);
        _mint(0xAf46585a4d22dAB188D3c7c4bE08c9e2d1C980d5, 1);
        _mint(0xb5105c731c5F3ec29eE4E84C7e0D45e8Ef43B300, 1);
        _mint(0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA, 1);
        _mint(0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49, 1);
        _mint(0xd6E0F82a4bD119Ee24b8708a880e6167ed5a7a7E, 1);
        _mint(0x5Fa60DB0C6422f09925a45eae367F5C205feC961, 1);
        _mint(0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA, 5);
        _mint(0x5Fa60DB0C6422f09925a45eae367F5C205feC961, 3);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 1);
        _mint(0xC59297F3aCDe356f546c925FD5943a860A296603, 1);
        _mint(0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA, 1);
        _mint(0x30faC264384582Fe99411c4D893F7e0b838708DA, 1);
        _mint(0xd6E0F82a4bD119Ee24b8708a880e6167ed5a7a7E, 1);
        _mint(0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49, 2);
        _mint(0xb5105c731c5F3ec29eE4E84C7e0D45e8Ef43B300, 5);
        _mint(0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49, 5);
        _mint(0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA, 5);
        _mint(0x0EDf79CBd5BEF41e59D8e4ddAd352DDf6aAb6560, 5);
        _mint(0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49, 11);
        _mint(0xb5105c731c5F3ec29eE4E84C7e0D45e8Ef43B300, 4);
        _mint(0xCEA431A6f20889670e59e2CEeb5E41Ba0d6d88c3, 3);
        _mint(0xd434B922e30193f9181284382517884c94350f9e, 6);
        _mint(0x94a7A0cCBbf54E37b154737B8cc1ecB5cC5310BB, 3);
        _mint(0x98eEd6Ce0b0b4bF302315C50d0Fe694305242105, 7);
        _mint(0xb5105c731c5F3ec29eE4E84C7e0D45e8Ef43B300, 4);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 4);
        _mint(0xd434B922e30193f9181284382517884c94350f9e, 4);
        _mint(0x8AC65B1D807EB2C8BbB04B90c3Aee2E49aaCD6A7, 1);
        _mint(0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA, 3);
        _mint(0xAf46585a4d22dAB188D3c7c4bE08c9e2d1C980d5, 6);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 1);
        _mint(0xC59297F3aCDe356f546c925FD5943a860A296603, 2);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 2);
        _mint(0x0EDf79CBd5BEF41e59D8e4ddAd352DDf6aAb6560, 1);
        _mint(0x2C077C051fdBaDc8388427E3aD30059E050b5f8f, 7);
        _mint(0xb5105c731c5F3ec29eE4E84C7e0D45e8Ef43B300, 1);
        _mint(0x62e3E1f39025fdADD7454704C13B7b2AE8C1A8EA, 5);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 1);
        _mint(0x478FFba8eA4945fB9327812231dfB1c6cAFD2C49, 1);
        _mint(0x0EDf79CBd5BEF41e59D8e4ddAd352DDf6aAb6560, 1);
        _mint(0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA, 2);
        _mint(0x766D5f2d38589aC4702184199c540cD97565B13B, 4);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 1);
        _mint(0xd434B922e30193f9181284382517884c94350f9e, 3);
        _mint(0x73F43E66041f8804DaB52592d1c0f1C26fF6fefe, 3);
        _mint(0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA, 2);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 3);
        _mint(0xC59297F3aCDe356f546c925FD5943a860A296603, 3);
        _mint(0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA, 2);
        _mint(0x62e3E1f39025fdADD7454704C13B7b2AE8C1A8EA, 13);
        _mint(0xb69C70A15954316920896cf11cEC942bB3CeA06f, 2);
        _mint(0x7c0a1f789c683B6636837C9D51c8AA2469d30ed6, 2);


    }

    //SIGNATURE VERIFICATION

    /*@dev helper function for WL sale
        returns true if reference address and signature match
        false otherwise
        Read more about ECDSA @openzeppelin https://docs.openzeppelin.com/contracts/2.x/utilities
    */
    function verifyAddressSigner(
        address referenceAddress,
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (bool) {
        return
        referenceAddress ==
        messageHash.toEthSignedMessageHash().recover(signature);
    }


    // @dev, helper hash function for WL Mint
    function hashMessage(uint number, address sender)
    private
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(number, sender));
    }

    // @dev, helper hash function for WL Mint
    function hashMessageGift(uint number, uint gift, address sender)
    private
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(number, gift, sender));
    }

    //END SIGNATURE VERIFICATION


    /* MINTING */

    //@dev The Max Someone Can Mint is Encoded In The Signature. Be careful
    function vipMint(uint amount, uint max, bytes memory signature) external {
        if (!vipStarted) revert SaleNotStarted();
        if (totalSupply() + amount > maxSupply) revert SoldOut();
        if (vipMintCounter + amount > maxVipMints) revert RoundSoldOut();
        if (vipMints[_msgSender()] + amount > max) revert MaxMints();
        if (!verifyAddressSigner(vipAddress, hashMessage(max, msg.sender), signature)) revert NotWL();

        vipMints[_msgSender()] += amount;
        vipMintCounter += amount;
        _mint(_msgSender(), amount);
    }


    //@dev The Max Someone Can Mint is Encoded In The Signature. Be careful
    function whiteListMint(uint amount, uint max, uint gift, bytes memory signature) external payable {

        if (!whiteListStarted) revert SaleNotStarted();
        if (totalSupply() + amount > maxSupply) revert SoldOut();
        if (!verifyAddressSigner(whitelistAddress, hashMessageGift(max, gift, msg.sender), signature)) revert NotWL();
        if (msg.value < (amount * whitelistPrice)) revert ValueTooLow();
        if (wlMints[_msgSender()] + amount > max) revert MaxMints();

        uint payout = amount * whitelistPrice;
        wlMints[msg.sender] += amount;

        // Other collections holders received 1 free NFT
        uint gift_diff = gift - giftReceived[_msgSender()];
        if (gift_diff > 0) {
            giftReceived[_msgSender()] = gift;
            amount += gift_diff;
        }

        wlMintCounter += amount;
        _mint(msg.sender, amount);


        spreadPayments(payout);

    }

    //@dev minting function for public sale
    function publicMint(uint amount) external payable {
        if (!publicSaleStarted) revert SaleNotStarted();
        if (totalSupply() + amount > maxSupply) revert SoldOut();
        if (msg.value < amount * publicPrice) revert ValueTooLow();

        publicMints[_msgSender()] += amount;
        _mint(msg.sender, amount);

        uint payout = amount * publicPrice;
        spreadPayments(payout);

    }

    function spreadPayments(uint payout) private {
        uint communityPayout = payout * 4300 / 10000;
        uint developmentPayout = payout * 1300 / 10000;
        uint creatorPayout = payout * 2800 / 10000;
        uint communityManagerPayout = payout * 1200 / 10000;
        uint marketingPayout = payout * 400 / 10000;

        (bool osCommunity,) = payable(communityPayoutAddress).call{value: communityPayout}("");
        (bool osDevelopment,) = payable(developmentPayoutAddress).call{value: developmentPayout}("");
        (bool osCreator,) = payable(creatorPayoutAddress).call{value: creatorPayout}("");
        (bool osCommunityManager,) = payable(communityManagerPayoutAddress).call{value: communityManagerPayout}("");
        (bool osMarketing,) = payable(marketingPayoutAddress).call{value: marketingPayout}("");
    }



    /* END MINTING */

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWlAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        whitelistAddress = _newAddress;
    }

    function setVipAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        vipAddress = _newAddress;
    }

    function setCommunityPayoutAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        communityPayoutAddress = _newAddress;
    }

    function setdevelopmentPayoutAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        developmentPayoutAddress = _newAddress;
    }

    function setCreatorPayoutAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        creatorPayoutAddress = _newAddress;
    }

    function setCommunityManagerPayoutAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        communityManagerPayoutAddress = _newAddress;
    }

    function setMarketingPayoutAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        marketingPayoutAddress = _newAddress;
    }

    function setUriSuffix(string memory _newSuffix) external onlyOwner {
        uriSuffix = _newSuffix;
    }

    function setPublicStatus(bool status) external onlyOwner {
        publicSaleStarted = status;
    }

    function setWhiteListStatus(bool status) external onlyOwner {
        whiteListStarted = status;
    }

    function setVipStatus(bool status) external onlyOwner {
        vipStarted = status;
    }

    function setPublicPrice(uint64 _newPrice) external onlyOwner {
        publicPrice = _newPrice;
    }

    function setWhiteListPrice(uint64 _newPrice) external onlyOwner {
        whitelistPrice = _newPrice;
    }

    function setMaxVipSupply(uint16 _wlSupply) external onlyOwner {
        maxVipMints = _wlSupply;
    }

    function setMaxSupply(uint newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    //END SETTERS


    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    // FACTORY

    function tokenURI(uint256 tokenId)
    public
    view
    override(IERC721A, ERC721A)
    returns (string memory)
    {

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), uriSuffix))
                : "";
    }


    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool r1,) = payable(owner()).call{value: balance}("");
        require(r1);
    }

    function contractURI() public view returns (string memory) {
        return "https://alphainchain.io/contract-metadata.json";
    }
}