// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract WarriorsOfPeace is ERC721, Ownable, IERC2981 {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    Counters.Counter private supply;
    string private contractUri;

    string public baseURI;
    string public baseExtension = ".json";

    uint256 public constant MAX_SUPPLY = 1390;
    uint256 public constant MINT_COST = 0.05 ether;
    uint256 public constant WHITELIST_MINT_COST = 0.005 ether;
    uint256 public constant MAX_MINT_AMOUNT = 10;

    uint256 public constant ROYALTY_PERCENT = 5;

    uint256 public constant SALE_START = 1660089599;
    uint256 public constant SALE_STOP = 1660885199;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public minted;

    event RoyaltiesReceived(
        address indexed _royaltyRecipient,
        address indexed _buyer,
        uint256 indexed _tokenId,
        address _tokenPaid,
        uint256 _amount,
        bytes32 _metadata
    );

    constructor() ERC721("Warriors of Peace", "WOP") {
        contractUri = "https://warriorsofpeacenft.com/nft/jsons/collection.json";
        baseURI = "https://warriorsofpeacenft.com/nft/jsons/";
        initWhitelist();
        transferOwnership(0xAAf67c8333Fa0D65e38c11e3657cd36f79a6f3bD);
    }

    /**
     * @notice get contract uri
     * @return contract uri
     */
    function contractURI() external view returns (string memory) {
        return contractUri;
    }

    /**
     * @notice get token uri
     * @param tokenId token id to get uri
     * @return token uri
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /**
     * @notice mint tokens
     * @param amount qty to mint
     */
    function mint(uint256 amount) external payable {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= SALE_START, "Not started");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= SALE_STOP, "Finished");
        require(amount > 0, "Mint amount should be > 0");
        require(amount <= MAX_MINT_AMOUNT, "Max mint amount overflow");
        require(supply.current() + amount <= MAX_SUPPLY, "Max supply overflow");
        require(msg.value == MINT_COST * amount, "Wrong ETH amount");

        for (uint256 i = 1; i <= amount; i++) {
            supply.increment();
            uint256 newTokenId = supply.current();
            _mint(msg.sender, newTokenId);
        }
    }

    /**
     * @notice mint token by owner
     * @param tokenId token id to mint
     * @dev callable only by contract owner
     */
    function mintWithOwner(uint256 tokenId) external onlyOwner {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp > SALE_STOP, "Not allowed");
        require(MAX_SUPPLY > supply.current(), "Max supply is reached");
        require(tokenId <= MAX_SUPPLY, "Token id is not allowed");
        require(!_exists(tokenId), "Token already minted");
        supply.increment();
        _mint(owner(), tokenId);
    }

    /**
     * @notice mint tokens for free for whitelist
     */
    function mintWhitelist() external payable {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= SALE_START, "Not started");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= SALE_STOP, "Finished");
        require(whitelist[msg.sender], "Not allowed");
        require(!minted[msg.sender], "Already minted");
        require(supply.current() + 1 <= MAX_SUPPLY, "Max supply overflow");
        require(msg.value == WHITELIST_MINT_COST, "Wrong ETH amount");

        minted[msg.sender] = true;
        supply.increment();
        uint256 newTokenId = supply.current();
        _mint(msg.sender, newTokenId);
    }

    /**
     * @notice get total supply
     * @return total supply of tokens
     */
    function totalSupply() external view returns (uint256) {
        return supply.current();
    }

    /**
     * @notice update contract uri
     * @param newURI new contract uri
     * @dev callable only by contract owner
     */
    function setContractURI(string memory newURI) external onlyOwner {
        contractUri = newURI;
    }

    /**
     * @notice update base uri
     * @param newBaseURI new base uri
     * @dev callable only by contract owner
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * @notice update base extension
     * @param newBaseExtension new base extension
     * @dev callable only by contract owner
     */
    function setBaseExtension(string memory newBaseExtension) public onlyOwner {
        baseExtension = newBaseExtension;
    }

    /**
     * @notice get base uri, internal
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice check if contract supports interface id
     * @param interfaceId interface Id
     * @dev callable only by contract owner
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns royalty reciever address and royalty amount
     * @param tokenId Token Id
     * @param salePrice Value to calculate royalty from
     * @return receiver Royalty reciever address
     * @return royaltyAmount Royalty amount
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Query for nonexistent token");
        return (this.owner(), salePrice * ROYALTY_PERCENT / 100);
    }

    /**
     * @notice Calls when royalty recieved
     */
    function onRoyaltiesReceived(
        address _royaltyRecipient,
        address _buyer,
        uint256 _tokenId,
        address _tokenPaid,
        uint256 _amount,
        bytes32 _metadata
    ) external returns (bytes4) {
        emit RoyaltiesReceived(
            _royaltyRecipient,
            _buyer,
            _tokenId,
            _tokenPaid,
            _amount,
            _metadata
        );
        return
            bytes4(
                keccak256(
                    "onRoyaltiesReceived(address,address,uint256,address,uint256,bytes32)"
                )
            );
    }

    /**
     * @notice It allows the admins to get tokens sent to the contract
     * @param tokenAddress: the address of the token to withdraw
     * @param tokenAmount: the number of token amount to withdraw
     * @dev Only callable by contract owner.
     */
    function recoverTokens(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(tokenAddress != address(0), "Address can not be zero!");
        IERC20(tokenAddress).safeTransfer(address(msg.sender), tokenAmount);
    }

    /**
     * @notice withdraw ETH
     * @dev callable only by contract owner
     */
    function withdraw() external onlyOwner {
        require(
            payable(msg.sender).send(address(this).balance),
            "Can not withdraw"
        );
    }

    function initWhitelist() internal {
        address[230] memory accounts = [
            0x2E10Fd3884dce04F992a3b68D52f807014b41237,
            0x3341DD81D325F231aa744efD603B8255D8cc3515,
            0x44500A3D9B73B605aE860D0C12d7cbF31a2Da5E5,
            0x7B01429e5ade22C5b4002F0DA287717E8aD05375,
            0x9474F08CB0B82863A04bdCd26238E274BaaAE42a,
            0x3686A4b272C646ef6fBE34377337d95Db7356E63,
            0xaC880de77E5DD805E7B724F1DEC0a85602e57FB5,
            0xe738052de24CDadb701Be3a5F92516b72541f74B,
            0xB32B4350C25141e779D392C1DBe857b62b60B4c9,
            0x0D439E560aa68b1C5A4580084d55D251C8F5bEF9,
            0x98EF61a73A79A61D2eAb1C9fB388566cAeA11fc0,
            0x5449209b61b472124708100f699e36d2217154c5,
            0x20eC02894D748C59c01B6bF08FE283D7bB75A5d2,
            0x058a9BBaA8E8e4Dbd3DEfB383aEe69D617e83d6A,
            0xD651E2c626eE210Fc38676124D5007Ac822AD749,
            0xab4787b17BfB2004C4B074Ea64871dfA238bd50c,
            0x2eC5EBac21b1a03FaCBff9EDbF4C906737f9E8f5,
            0x6E63a4CAeCcb4F341EE9C9175c9Cc554bDB6d10B,
            0xAd5C955274B7B66330c070417C79e5896BA91E75,
            0x935584a2e880B8eB225b44Bd9ED6A52EAE538f3c,
            0x6207405Ef8E92Dbe7Ae67a256211D85BCdB63799,
            0x591631285F17e0e3aE23c2695b632575B2455A1C,
            0x7bd083591D46381b606813b5F6670A55363e5947,
            0x2F7B9F2F5f00Dd2293b159B6E580a01E8dA7ACb1,
            0x588a4C42c3Bd422a02F96041dFCc65Eec59b7CC4,
            0x34f3802366A59d96565ffDEd9BB601d5e28A3b82,
            0x825449d201aB8FBb27e339141d0bd75C2EF7CE21,
            0x3fF66e83e8D0219363cB27AaAD8ee34b93BF757A,
            0x9a33ac1be5833cdAA83D88e121cac3Ebc5A7BD5f,
            0xfee4DB0e8Bb10B4D5c50B67A3fd073A434910d28,
            0x067d3A2c55086C4080ffb3f42c70F5721Bb63d5D,
            0x001DaaA0b2e05A6a102437e525042ce2F11f4818,
            0xD35231F0d9Ac7BbcE8A985C75EBe855d054d1BeC,
            0x1BF66cB6114E8BA9Ed2D32B021cc2DDc7c785c50,
            0x11360F0c5552443b33720a44408aba01a809905e,
            0x0a61693925F8092040c3E5ff950DaA58F8EF263E,
            0xAB83996cF53b6eB77a2fB27Fb101b278670CD440,
            0x6f583c478e61f08FdE0097bDCb8AE7A88a28255b,
            0x1E3C06381A11375AAeE09c0A368c81E950211EA7,
            0x7dC86FAb58672F39435F5249f6751B937244D663,
            0x1cA42bb6d30D13ad38B54BEeB7c0E1eb2abEB5CD,
            0xd7189A81961CB3cC0Dd6eC6a1f90Bc5f95DfD7f0,
            0x9C4d96683af2329Edd49c257D5411deFFF4B8D5C,
            0x010462E09d11875B5b17e1d800951919423F9616,
            0xA00373e6cfDC3839619Bf2B645C2028ca83f7580,
            0x4E984E6c138BD8Dc8637eD9e082117cce062A94B,
            0x44D5a0B1E165A17c16d940ca774a28e62D4b44b0,
            0xE82660AA4fdbaBAc5c9fEa0F1A217B8CEaF050Cc,
            0x1EC19d4A0521E1F915327715e0C0c2CD73B4dC74,
            0x6d25415569524DeB1780eCC9b6F66097134AF29E,
            0x65FDC1863a34d51bd40BE0E8582554ee42769d4b,
            0x228f9fD74F35080771A9e858f9575451d3ccF7ED,
            0x2BaFc1e12704563e329cbFE8332695D72065Ba19,
            0x3c1D98Cbc61109D49373d2944B3AE3700be923Ed,
            0x8d2f3a76a76f055D62A931678ab16b042E7BADeb,
            0xB8ef7f2082a0783aef1a8F85ecf89f06CD94F812,
            0x2D9C503c98707611a7f94a8ae5127713bd24b790,
            0xd6e3D88e5c3d7D3D204497aB53Cc212Ebde663Df,
            0x53b244E43dEFaDD6c3c62AAb90B8FC9C483264f6,
            0x6a8d75c3f7cAB0d65a4BaACc2633FE3E31b8F278,
            0x504C11bDBE6E29b46E23e9A15d9c8d2e2e795709,
            0xb9E6c686A6E091036Fa9d5fe9c0b2Bd0537CB95c,
            0x341F196BeBA72155E7cB67a3ad02C67DBE54Ea48,
            0x42a60D2f2FfA2150C568010A8D425f0AAD284fd2,
            0xC13483CeDE1433A4ea42BFa6e05Ef03B427c9EE2,
            0x4df20811f63519532D0C6dc68DEF530f52C4e06E,
            0xb2ecf0a0d4361E243dcc5206b71aaF2Dff0b805D,
            0xF7c66bCD6EA3607174DA0bC8458bd1508027e539,
            0x3F6224798FCC06C5710C60a60FB57E4edBa6b839,
            0x73fFfb65b2C8f61Cb2a11548E88a94Fd9fc7dc0B,
            0xA1D112C61544Bb72C83A866a08155E1b18831028,
            0xFda21479846B909a9B64A955B6644c725feEc4b3,
            0x435EA0FbF0c516FF31D88e990b773EB84e8cDBe5,
            0xf013E5F697E84C6831220A21a96556242Ee9AD86,
            0xF97f757Ed3Aa1eF705F2957698A2b3B2CF2dcEBb,
            0x3Db405ED4023aa389843297385bd65Cae0b46621,
            0x25F89312F39938314b615e85211Ff03d5D0088c0,
            0x84C42a0F1DFf1bb673BCCd63bCa73e672225EDA2,
            0x889cC8342C4AE6C390D74BceF706F656F85E5aC2,
            0x62F9ACbD11350FB05B3215507dD1f6e05ed27aF5,
            0x067AA2fFdC80E558A2b01C349190eef0c6a773cf,
            0x8E72ae54eC2C556070C1D395a0bE8397A1E66474,
            0x720E7be35069a46596D96dc0E58Cb40675ebCfdf,
            0x9dD6eDe5b1cF2d975a5c831A288B8ed7Eca24f80,
            0x68233a413A6B48B348f2AE3E646BAaaa839ca245,
            0x1Ee8657Df36C16753359EF1B9Ef876e300740CC2,
            0x72b9B8643B008240F6dFA0c684614DBb60458d38,
            0x08e7dc763EA6F6f9865A76675DAcccF3D3981fdA,
            0x925c559c7A4015fd25B47db32c85a4902c021952,
            0x2865ec116A7742A0f3A0caD741f994E2C01Ee6dc,
            0x6B916D50869CDF9955fEcb5dAcB75278E31b2174,
            0x75e06a34c1Ef068fC43ad56A1a5193f3778bF0B2,
            0xc160BCf9a40532E3c1c4cE83020469CB851081cC,
            0x477b6F91c9481fC64E9080ffD00527CD53563dD6,
            0x3dfe98db80ecf45760F23e5517eFe29423571eb1,
            0x24B34FD24BbBc51fF9161D8f3782a1519a3c0d14,
            0xF3aBCcC785165d1600DEF7F44c505DBFCDdCF0E4,
            0xd6a984153aCB6c9E2d788f08C2465a1358BB89A7,
            0xF8beB91324Bd3A4b201D23Ded9EB4a9F7d6A072C,
            0x85DE83464ddE6D3557cC86bBB5EDE4E73C787e8f,
            0xdA793c60c22Afe53e3b0bD39c3E49D44D6aF4F1e,
            0x7C6823F61223b71e9Fd0b62bD43E326732D3B147,
            0xB092e3F536Ed6bce2d166b72aA27465a0Ffd8a4F,
            0x9d185b6146b50541F510aDf722d13071e8A237ac,
            0x6d4b3a607450005fB8f807940733F73974a08435,
            0xf817B32dCBdACCCAeD4d80c70d57d03A8C238902,
            0x1Bb01159AB168ACD0Cc055eAD980729A2ADAe919,
            0xd82E0032A9030835cf5A384344638faa8b18A219,
            0x12f16863343061BDFbF85292A414a159dD92Dafb,
            0x589DBECe842C413be18a603E44E0dabCe4908cde,
            0x231E9bd5C74caF431F17e421d103E0F121B66f1c,
            0x50ab88046E972ef974755B9b0bCE6053702abA19,
            0x04Fb523ef05daDC443F61ae6ef59C5dBBB4406a9,
            0xeF984Be913C22645Bdd7Dc1388b3D2B9C5744092,
            0x0d75b5214B1b2181FE4D1830CA428AE860aAC5a9,
            0x3Ee3d0cceF50bc9a6Ac43e763180C0c870fd2787,
            0x1C4e90fC8bdAdE442aeD58f8011db5A17A2E7199,
            0x6e6561f85DCc43c8dc717Be06b4000B06D8c7DcB,
            0x34548011fB8e54418A90d004b9FC3224F8C65051,
            0xE6DC5a552E55824625703Fa015C568Fbd3171875,
            0x8f40496973fC78d389571812c0D43620369102c6,
            0xA2089abCe87Ed0D44401f35aA4A1e2073f32C318,
            0xdfb7B991CD8d36e747f81495DA43AB429489Bf9d,
            0xA7230946A4421a68EFC625b9E420D916c3924722,
            0x79b651B0c9819d9DF785E20F05a53f06E487542A,
            0x28c122c94De37ec0eeC4D7DD3dEf807CE13f8A25,
            0xa0c08f25FB30F43bc83346aD3049295dB5EcF5b6,
            0xf60B4342cf2a83451CBc17b40C0f9527908f6C0d,
            0x4E99667ad4A71F00486C01082F515E71422E786d,
            0xBf26925f736E90E1715ce4E04cD9c289dD1bc002,
            0x90e5aa59a9dF2ADd394df81521DbBEd5F3c4A1A3,
            0x6e58309CD851A5B124E3A56768a42d12f3B6D104,
            0xBedAF1ed65daF1E076fd1C49E1E893027005a1bB,
            0x0f9079c3a101eAfa19bd5d83857efbA8D34df047,
            0x29f9ef8286dcc4F9a94340278DB01f12c3483988,
            0x3Be320A51bc61feb5C3EDF65ffb225A39362cF1B,
            0xcC3d6ac59CF8ED1f5528cAD140266c9Ce3d3c41B,
            0x66c17Dcef1B364014573Ae0F869ad1c05fe01c89,
            0x66bDc08a0dB3A83D374670a57aA8ECd5b51b55e5,
            0x7742e29f398329d0A60246CE55DB226b76893578,
            0x547b166Bdf86eEc60b269564553F37838C6f1C0a,
            0x98f973f10Dd3263ae811CB1d7c9df31D1db12995,
            0x669631DBfeEAF801d221079f9F4ED22b96e0529E,
            0xc851D9C6A6a5bF109493Dc909e3FAA311E0B220D,
            0x322Af0da66D00be980C7aa006377FCaaEee3BDFD,
            0x9fF50B3C3aEd6638Cb5B631d09ce682b0D3Ad9b2,
            0x3168f1B642401234D48890ee9c30F67feEC02c21,
            0x74f54b4435eff8d5f680644Cc6482434eB9221dB,
            0x53c3fDE3A71880Af3A692266ee9778c938248874,
            0xFa34804390a2f6e14C547aFa976d4479F5f660E2,
            0xd011EFb7aC56497ba459FC0Ea593F06bcA97B3dD,
            0x2D631a9C0FF16B57E6c85789341ef2C1BC7d0a2b,
            0xA2bdFe560084E1Cd2AD6BCEFf045F123D633dD56,
            0x0B32b6a775cCF57ff75078a702249A65c8A581Fe,
            0x200167320bD54CbF3732da291AC907BEeD6B7365,
            0xD5Bce7d1DD106b6Eb0f5caA590f75BCf561eb7B2,
            0xaB268c14e235e65c1c2f4aBc673B3b03Ae6FbF9E,
            0x5c6Ec56843182FE04271715c6BE04BbC7Edf0F84,
            0xFABCEe287b5E76A128E3c8E876E2Ab2Edb9ca101,
            0xf9B2b433Fc953C209957D754A5e4334f2C8676Cf,
            0x707357F2d99f4432225195d5304A3112200d2Cfc,
            0xb46782E99CDdc4Ef6e235ad84b16DdFE9b807D41,
            0x6FD5E120dc8Af1dcB2Ecb73DE4eD408a4ED46569,
            0x06e28C3c956D47eb163C8462F77CF52e3E00C2F8,
            0x50367bE5Fde4EC65eDA56461F9675B95C2144a02,
            0x4B41775Ab35e75982fb1A3027D7fBA786B47cF15,
            0x076610A4494528a637A4Fa0CF1119c6d15a66754,
            0xBB4571aC427690c869Fb98D0EE41e31Bd2EE3332,
            0xD492c4971eF568F33a1255a8B346f572ba65173b,
            0xc800363b8b19C4a0f5E35047e87dAb4B31C6e99F,
            0x375c8d30eA2363e374915FC341f0412D001587Cb,
            0x4f896dae9f8016871a802F059E1F5B9a287eD79f,
            0xe2EA08D1fF6Eb2D238086b57D7b2441ebF045512,
            0x201B7B11A4d2f7b9227d86aCBfdcB60687FC1154,
            0xDEc096F829AAc7bF4b9D927903eF08F51De34a21,
            0xc08A111F737C5FFc07A2558c554dFc4DE5694EC0,
            0x6f2d9b59F562d3148845676646eA053cDA537632,
            0x4f4531df6F06a5A29ce19158bbe81f940c0cC886,
            0x2e02Cc491d5B7ca08e58a3b40b1AD76f3FdeA149,
            0xfAE8F86710e97dc8b667DDb55dF5D62C3307e5f3,
            0x5db123ed2656f3E1dBA4AdC6AA7250684A3AA072,
            0x0f5a6c496fa973b961cd76707D653424e615e17b,
            0x66Eb811Fd65677d7A320bF673db3DBE01EA688bB,
            0x7B943e4Cb3bE59E52A41eF0c232B0d2daB9CB7FD,
            0x028b19906cF2C423621CE818505c97da5d3283F0,
            0xCc48857242141CC7F4f8555f8a3d5bED03556C19,
            0xA327a16b71bA107393E0dC046B0Be0908AA667aD,
            0xaC359Bb02E4F5fbf0EADA1a3410086fF7F648f5e,
            0x9B31a51DF352C7Cc0372b013172DaD16Cb40E314,
            0x9F387401b2C566f621081989f7753B7cbDd1fe77,
            0x198e62b7d6aC3e41c009346e51B5cF53dB019aF7,
            0xB158572Fc732Ab7F4b3616871840726abC6A8015,
            0x151d74A53E886980A9F0Afc7d392C37E48A743ba,
            0xfB5Cb3c7d2C04f17B1c8b3c742d0d508BF481928,
            0x690Da1F118eF4ad056785A1bb0A63D77F84c1Ca7,
            0x563b26BA6a2dB99EB40Aa4566aEe341011Dc70f3,
            0x6E7013Ef472Cd749Ffb04C74fD9C2525888bE5c6,
            0x05Cc51F9d3c90E5438D26bEc7cA1983d6d9a04a2,
            0x2fa510caf46f88Ae7Cab8DaEc696aBBc299f8D20,
            0xB9858685c5F4478FFa22A32107036782878305B9,
            0x258A3Cc3b154B090ae37A0aBBA9965f24E012cA6,
            0x4D2Fb20B25E39cc6Db1E673aCBb8C6C467b7c594,
            0xa75d6cd046b55c808c23bD2e4eFC0B8910F3C7Cf,
            0xba8BAFF5bc5CC65749A62b51F328BE91786Ffde1,
            0xc7CFf3E96e553eAAF434749f88A0DF920588cBCC,
            0xBEdAef8720A3c265919D051F3951bA5fB9c220Ae,
            0xD825cD88c7Ce286350a734DCeE2CCdb2D3149EC3,
            0x241Ed4222CE93fABe19892E15DBeC5b640e6CC3f,
            0xe73e90fc400c0256Bc271C83e576ACb97603452b,
            0x8BB900A63D240F6B8f9aC3C1432760b1C2e79710,
            0x6AB16923dAA8109153680F4338028a98eaC04725,
            0xa0faE875F761c933C90c7706a51239D73233770C,
            0xE310e94B4c239396BeAC0E3A6498E5b296C37616,
            0x0047b224C56cfb6E3cfdF1ee3CC1d99527d67aEa,
            0x111B99d48B2e4Ec1d059061314EFA941FDadf25A,
            0xb0708326673D57738eA85b2ECE055B9fD114Ce25,
            0xD59753c4AD33D78e3E7Dfa79c5cde5834167817b,
            0x4D10AFe09aE7EeD0bEAa46207D381C71D315E43A,
            0x9a3c2b07B8A305A38C3dBdb4c2f076b44cAEB175,
            0x682065D9136F6a3397ed3623F7b62F7693D6B0d9,
            0x40A0Bdc98adDe176a359B071c91eCDad6F995e5d,
            0xca2E2B6e1973cfA495A877481999B90FDBf2920f,
            0x840A1068f5825E983cD0Eb9e82E489905Dd456fb,
            0xC9B3d0AB776c9CaAB78Feb4D2AafA87a24cB5d87,
            0x94Cf72b0f97072aF598Add966aC90aCCe801FF1f,
            0xF53366d315D4Aa114227F886045980789F698797,
            0x766E5ccdf4593BF6CC3CD482745e7529133dD698,
            0x6bE91ABF32d3aAe75Ac78Bc4bf53D9eC66708A14,
            0xEe85Ad2378B50B5d693Cc29184e74b245Bb45819,
            0x6Bb4958A7F95e63Ee2b2cf5aCb4ae3D1aa9A895B
        ];

        for (uint16 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = true;
        }
    }
}