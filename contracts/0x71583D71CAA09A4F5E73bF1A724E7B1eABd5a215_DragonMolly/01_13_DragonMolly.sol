//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DragonMolly is ERC721, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public MAX_PRESALE = 1111;
    uint256 public MAX_FREE = 1000;
    uint256 public maxSupply = 6666;

    uint256 public currentSupply = 0;
    uint256 public maxPerWallet = 5;

    uint256 public salePrice = 0.1 ether;
    uint256 public presalePrice = 0.03 ether;

    uint256 public presaleCount;

    uint256 public freeMinted;

    //Placeholders
    address private presaleAddress = address(0x41451D6448082c4Bb1dED8f7991b02f60738017a);
    address private freeAddress = address(0xaABc53116F0B995BDe9D61556Ef3492043eDbF99);
    address private wallet = address(0x54F22E10Bc5a24B42cb22b1cDdB545aa448d6F35);

    string private baseURI;
    string private notRevealedUri = "ipfs://QmcmyqYcBubUpK2NjXv4K1WDfDefBVP27ikQ9KE5U9Qt4B";

    bool public revealed = false;
    bool public baseLocked = false;
    bool public marketOpened = false;
    bool public freeMintOpened = false;

    enum WorkflowStatus {
        Before,
        Presale,
        Sale,
        Paused,
        Reveal
    }

    WorkflowStatus public workflow;

    mapping(address => uint256) public freeMintAccess;
    mapping(address => uint256) public presaleMintLog;
    mapping(address => uint256) public publicMintLog;
    mapping(address => uint256) public freeMintLog;

    constructor()
        ERC721("Dragon Molly", "DragonMolly")
    {
        transferOwnership(msg.sender);
        workflow = WorkflowStatus.Before;

        initFree();
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(marketOpened, 'The sale of NFTs on the marketplaces has not been opened yet.');
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        require(marketOpened, 'The sale of NFTs on the marketplaces has not been opened yet.');
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address( this ).balance;
        
        payable( wallet ).transfer( _balance );
    }

    //GETTERS
    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    function getFreeMintAmount( address _acc ) public view returns (uint256) {
        return freeMintAccess[ _acc ];
    }

    function getFreeMintLog( address _acc ) public view returns (uint256) {
        return freeMintLog[ _acc ];
    }

    function validateSignature( address _addr, bytes memory _s ) internal view returns (bool){
        bytes32 messageHash = keccak256(
            abi.encodePacked( address(this), msg.sender)
        );

        address signer = messageHash.toEthSignedMessageHash().recover(_s);

        if( _addr == signer ) {
            return true;
        } else {
            return false;
        }
    }

    //Batch minting
    function mintBatch(
        address to,
        uint256 baseId,
        uint256 number
    ) internal {

        for (uint256 i = 0; i < number; i++) {
            _safeMint(to, baseId + i);
        }

    }

    /**
        Claims tokens for free paying only gas fees
     */
    function freeMint(uint256 _amount, bytes calldata signature) external {
        //Free mint check
        require( 
            freeMintOpened, 
            "Free mint is not opened yet." 
        );

        //Check free mint signature
        require(
            validateSignature(
                freeAddress,
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );

        uint256 supply = currentSupply;
        uint256 allowedAmount = 1;

        if( freeMintAccess[ msg.sender ] > 0 ) {
            allowedAmount = freeMintAccess[ msg.sender ];
        } 

        require( 
            freeMintLog[ msg.sender ] + _amount <= allowedAmount, 
            "You dont have permision to free mint that amount." 
        );

        require(
            supply + _amount <= maxSupply,
            "Molly: Mint too large, exceeding the maxSupply"
        );

        require(
            freeMinted + _amount <= MAX_FREE,
            "Molly: Mint too large, exceeding the free mint amount"
        );


        freeMintLog[ msg.sender ] += _amount;
        freeMinted += _amount;
        currentSupply += _amount;

        mintBatch(msg.sender, supply, _amount);
    }


    function presaleMint(
        uint256 amount,
        bytes calldata signature
    ) external payable {
        
        require(
            workflow == WorkflowStatus.Presale,
            "Molly: Presale is not currently active."
        );

        require(
            validateSignature(
                presaleAddress,
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );

        require(amount > 0, "You must mint at least one token");

        //Max per wallet check
        require(
            presaleMintLog[ msg.sender ] + amount <= maxPerWallet,
            "Molly: You have exceeded the max per wallet amount!"
        );

        //Price check
        require(
            msg.value >= presalePrice * amount,
            "Molly: Insuficient ETH amount sent."
        );
        
        require(
            presaleCount + amount <= MAX_PRESALE,
            "Molly: Selected amount exceeds the max presale supply"
        );

        presaleCount += amount;
        currentSupply += amount;
        presaleMintLog[ msg.sender ] += amount;

        mintBatch(msg.sender, currentSupply - amount, amount);
    }

    function publicSaleMint(uint256 amount) external payable {
        require( amount > 0, "You must mint at least one NFT.");
        
        uint256 supply = currentSupply;

        require( supply < maxSupply, "Molly: Sold out!" );
        require( supply + amount <= maxSupply, "Molly: Selected amount exceeds the max supply.");

        require(
            workflow == WorkflowStatus.Sale,
            "Molly: Public sale has not active."
        );

        require(
            msg.value >= salePrice * amount,
            "Molly: Insuficient ETH amount sent."
        );

        publicMintLog[ msg.sender ] += amount;
        currentSupply += amount;

        mintBatch(msg.sender, supply, amount);
    }

    function forceMint(uint256 number, address receiver) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "Molly: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch( receiver, supply, number);
    }

    function ownerMint(uint256 number) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "Molly: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch(msg.sender, supply, number);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = currentSupply;
        require(
            supply + addresses.length <= maxSupply,
            "Molly: You can't mint more than max supply"
        );

        currentSupply += addresses.length;

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], supply + i);
        }
    }

    function setUpBefore() external onlyOwner {
        workflow = WorkflowStatus.Before;
    }

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;
    }

    function setUpSale() external onlyOwner {
        workflow = WorkflowStatus.Sale;
    }

    function pauseSale() external onlyOwner {
        workflow = WorkflowStatus.Paused;
    }

    function setMaxPerWallet( uint256 _amount ) external onlyOwner {
        maxPerWallet = _amount;
    }

    function setMaxFree( uint256 _amount ) external onlyOwner {
        MAX_FREE = _amount;
    }

    function setMaxPresale( uint256 _amount ) external onlyOwner {
        MAX_PRESALE = _amount;
    }

    function openFreeMint() public onlyOwner {
        freeMintOpened = true;
    }
    
    function stopFreeMint() public onlyOwner {
        freeMintOpened = false;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require( baseLocked == false, "Base URI change has been disabled permanently");

        baseURI = _newBaseURI;
    }

    function setPresaleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        presaleAddress = _newAddress;
    }

    function setWallet(address _newWallet) public onlyOwner {
        wallet = _newWallet;
    }

    function setSalePrice(uint256 _newPrice) public onlyOwner {
        salePrice = _newPrice;
    }
    
    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
    }
    
    function setFreeMintAccess(address _acc, uint256 _am ) public onlyOwner {
        freeMintAccess[ _acc ] = _am;
    }

    //Lock base security - your nfts can never be changed.
    function lockBase() public onlyOwner {
        baseLocked = true;
    }

    //Once opened, it can not be closed again
    function openMarket() public onlyOwner {
        marketOpened = true;
    }

    // FACTORY
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),'.json'))
                : "";
    }

    function initFree() internal {
        freeMintAccess[ address(0x3fEdc94dB76395a83982277203cB5789ABa955b4) ] = 23;
        freeMintAccess[ address(0xdFA7ae04064eE82378b01FDe8Fcd1aE72cE957a8) ] = 22;
        freeMintAccess[ address(0x793089C3170C6968a7ea0cA42b3E58a12C3F7c22) ] = 15;
        freeMintAccess[ address(0x4c1447148B00692bFd46b9f67A26be44Caa115fA) ] = 13;
        freeMintAccess[ address(0x27F419ea59873fDed5aa65220792EDB6187b5036) ] = 10;
        freeMintAccess[ address(0x919D316475DD4B894E2926Fe2c24B329d8Ade524) ] = 10;
        freeMintAccess[ address(0xE0F6Bb10e17Ae2fEcD114d43603482fcEa5A9654) ] = 10;
        freeMintAccess[ address(0xC6Ac567b250b986acAE49A842Dad7865dA4be3a0) ] = 10;
        freeMintAccess[ address(0x4a9b4cea73531Ebbe64922639683574104e72E4E) ] = 8;
        freeMintAccess[ address(0xE5d08078CA78C9B14101f16fcACbEE8818D06Bfa) ] = 6;
        freeMintAccess[ address(0x7226a4ce2023D5E1228FA55C325bC6D83686c9B7) ] = 6;
        freeMintAccess[ address(0x2132F5a587163540E0858c3258A6813d31fde053) ] = 5;
        freeMintAccess[ address(0xC24838b9077720a30935A73C17d18872E570D7c9) ] = 5;
        freeMintAccess[ address(0x522dC68b2fd2da341d1d25595101E27118B232bD) ] = 5;
        freeMintAccess[ address(0x5c8aD9343c76CCE594cB3B663410DD2fa1aC0e78) ] = 5;
        freeMintAccess[ address(0x2bBD55313F6aFF47638DFe9CbCe59c3428A8C969) ] = 5;
        freeMintAccess[ address(0xc2Ad53Dcdb5A82ce0ed9F165De1BC614031Ff729) ] = 5;
        freeMintAccess[ address(0x12C97D5933f2cFCAA64FdfcC45c89705c89Ca8f1) ] = 5;
        freeMintAccess[ address(0x5b7A238EcE076288D58104AAAB26FA3fbf715957) ] = 5;
        freeMintAccess[ address(0xE170dE7864c63A2442C6FBf5Fff8322D5c72D4fe) ] = 4;
        freeMintAccess[ address(0x6EDf6b0229C9A205d0D0E4f81e6a956e064ECFAa) ] = 4;
        freeMintAccess[ address(0x8813df11Cf5DDc4cFb234eD7Bf78b2CfA9a63Ce5) ] = 4;
        freeMintAccess[ address(0x0081c79304AB6eB2824BDb5f419193ca6d506111) ] = 4;
        freeMintAccess[ address(0xFaeFb5433b70f5D0857cc7f65b32eeae0316aBcb) ] = 4;
        freeMintAccess[ address(0xBaA3f0f0983267D1B9847B6328eDa968Aa5cB0e5) ] = 4;
        freeMintAccess[ address(0xcC0862A45c1c446E62FB99387cEa44Ef4C4FC2D4) ] = 4;
        freeMintAccess[ address(0xb2aF4F684f3B660703f0dc0EabfDe9f8FB185C21) ] = 4;
        freeMintAccess[ address(0xc650846f6D9C7E0EE2A4EaAD6f4Be09789eC7141) ] = 3;
        freeMintAccess[ address(0xd8777f3f65E84CCdca6a4f2C4dCDC1a11030132c) ] = 3;
        freeMintAccess[ address(0x8CEe034078EADd552D0c8E6E80e45A9B3A7A5BE9) ] = 3;
        freeMintAccess[ address(0xc70A3Ad498E0Db94d0752cBF05dC4210aCDa0d1F) ] = 3;
        freeMintAccess[ address(0xCE5443fE2C6B2542C1331Bed2d82f0dd9c14ebbe) ] = 3;
        freeMintAccess[ address(0xa8f6deDCAe4D391Eaa009CB6f848bB31fDB47D02) ] = 3;
        freeMintAccess[ address(0x69e69571d0d07EdBEde6c43849e8d877573eE6bf) ] = 3;
        freeMintAccess[ address(0x40E5529fc270566dD00272af0Bfa684C230cb210) ] = 3;
        freeMintAccess[ address(0x15dB6B0c9D7195d7413f165dCc430cA8F520886c) ] = 3;
        freeMintAccess[ address(0x972f7dB01E68bDa714971a10061B13A563DFF012) ] = 3;
        freeMintAccess[ address(0x065735841E157d74Cd2D69A95d3E4C4003A76E28) ] = 3;
        freeMintAccess[ address(0xc9eD33f42bB0Dc26E7bA76BF61820328F03a3e5f) ] = 3;
        freeMintAccess[ address(0x45896c9885066Fe00D1C9c95B962CD5e6579bAC5) ] = 3;
        freeMintAccess[ address(0x26b7e7a30E75A468cCcC8940D4C5829910aF5073) ] = 3;
        freeMintAccess[ address(0x6BFc87A9559F0d2129C9A418821A6F1Be09d1991) ] = 3;
        freeMintAccess[ address(0x9E75aa8Da215804fa82c8C6b5F24bBb7fF069541) ] = 3;
        freeMintAccess[ address(0x3CB1FE91005B4B92F59D99D2611A0f3C6Ca1aBbb) ] = 3;
        freeMintAccess[ address(0xe120f27AC40AA4f755ebD3781C259425Ad1F9434) ] = 3;
        freeMintAccess[ address(0x400665C0eb68da4564bbbD6A24bBfac65Bd17305) ] = 3;
        freeMintAccess[ address(0xe4aF5C7037D690267bbee5C770ae5D3A1Da70862) ] = 3;
        freeMintAccess[ address(0x4CB764d39555228EAA5dCCB4b7E5bcdBfa417b75) ] = 3;
        freeMintAccess[ address(0xab0281C998BEcD891b0A1Cb443d915Af398Df443) ] = 3;
        freeMintAccess[ address(0xacCB1e0eAa4d6bB3AB8268cFa8fB08d77F082655) ] = 3;
        freeMintAccess[ address(0x6571cb1fc92d71238aE992271D4Fca16e950a40A) ] = 2;
        freeMintAccess[ address(0x05120B86e5ABFEC60a3ba7AbF60D74CF9a7d49e9) ] = 2;
        freeMintAccess[ address(0xdE694b3D3DDC92914F87c8618B067a6306BAcEDA) ] = 2;
        freeMintAccess[ address(0xa215495dB3a2923c74BF570F5253e5Bc05247635) ] = 2;
        freeMintAccess[ address(0x08528a318b20e6213d1b848Baef381B3819c139b) ] = 2;
        freeMintAccess[ address(0x545152C6c3077579702d60A1764a405575F395B2) ] = 2;
        freeMintAccess[ address(0x92b449114420c1b3F10324491727De57809f9Cc8) ] = 2;
        freeMintAccess[ address(0xFc045bFbA2Cc210993DA7D0e5240575Cd4292558) ] = 2;
        freeMintAccess[ address(0x03D98243C825b799E518e1AA4c9314E6614896b2) ] = 2;
        freeMintAccess[ address(0xdC8A96B8613C7f4834F1abC5cf52b0c6FC0730A2) ] = 2;
        freeMintAccess[ address(0xdE3ce6E4bc4967449CD1135a31D5Ae9365E0681d) ] = 2;
        freeMintAccess[ address(0xcEc32F9df33A482A02B80E9e5b41cb4970Bc4976) ] = 2;
        freeMintAccess[ address(0x94c1CB2cecb2a0e9BE3A8C24e11507BE5Ebce172) ] = 2;
        freeMintAccess[ address(0xaC08C1b08430aA3976D6d26E837cd4955e3530aA) ] = 2;
        freeMintAccess[ address(0x20B7A3C7B517e440ffFdfECf505e91D55484072E) ] = 2;
        freeMintAccess[ address(0x392623dfDAAF78C78Df19a92880A2f5F21044365) ] = 2;
        freeMintAccess[ address(0x546630E317b4732870437d9277dd2ed92758805F) ] = 2;
        freeMintAccess[ address(0x7E7c1A3541d2ff134f755ca58512B703906f2785) ] = 2;
        freeMintAccess[ address(0xeE4B71C36d17b1c70E438F8204907C5e068229cc) ] = 2;
        freeMintAccess[ address(0xe1E7A079D5bBFa741f6FA850B9100bAA0B59689C) ] = 2;
        freeMintAccess[ address(0x3C03Fb9387524111D5528eC19B606eF22D107AC0) ] = 2;
        freeMintAccess[ address(0x5F4dF796b08AcAb25dc35b14e4D3Fd0b1588290e) ] = 2;
        freeMintAccess[ address(0xE0f4f6cFb0CD8cE76e99AF76E7018F47E54D414F) ] = 2;
        freeMintAccess[ address(0x75deF0e0adAF2Cad3Ae505fDaD1fd1BeAFdB0A16) ] = 2;
        freeMintAccess[ address(0x02098bf554A48707579FcB28182D42947c013cfA) ] = 2;
        freeMintAccess[ address(0x6C543a1aCa8F972d83e4cD072B5b23Ee49ca77f5) ] = 2;
        freeMintAccess[ address(0x85C26b9287b0b77E41691E12B208396e95f66D2F) ] = 2;
        freeMintAccess[ address(0x4a437b6078Cfb41bC599C4379A9D27259F1948dF) ] = 2;
        freeMintAccess[ address(0xed9A912182745fE101ecb4291D00b802d982Ba0F) ] = 2;
        freeMintAccess[ address(0x68CfFC26438472733803372b7D7Cff58d352DFf4) ] = 2;
        freeMintAccess[ address(0xAeA6880Ea9374c3C5c9805F8CD5c21679df5f9ac) ] = 2;
        freeMintAccess[ address(0x0D57D42C7c784DA53325dA4d4287d39fcd9529de) ] = 2;
        freeMintAccess[ address(0x80Ed258780a60fe518cBc8173566A9eDC8B6598D) ] = 2;
        freeMintAccess[ address(0xC9516b1845e1150dc55B5081Dd072B6c215383A9) ] = 2;
        freeMintAccess[ address(0x8C7EE7fE4871DA8e4C2565B9109dC07a19334b43) ] = 2;
        freeMintAccess[ address(0xFCCB5fa5Aef5481C02fAAA378e663F6259C900fD) ] = 2;
        freeMintAccess[ address(0x52d09189264FaaA709F1AED9C457e55c9e4B5D29) ] = 2;
        freeMintAccess[ address(0xF13Eb1Bc8CD592b3888A67B9EFE73F8Bb41c6142) ] = 2;
        freeMintAccess[ address(0x059a06f9EE4b7D352C0a11E8f0E0995A65f41388) ] = 2;
        freeMintAccess[ address(0x9487a68681F8E114787C97079ed3E8135E12bca6) ] = 2;
        freeMintAccess[ address(0x4dD7957e0499624e65d3fd5B3E217948f2e16d38) ] = 2;
        freeMintAccess[ address(0x6ABaE536325516db0e8e68BAfB06c84FB0a1068d) ] = 2;
        freeMintAccess[ address(0x7C922CDC663367ed2ba6E84c074385121AA79291) ] = 2;
        freeMintAccess[ address(0x827cda8f8A1782040af691B73747AbE2Eeee980b) ] = 2;
        freeMintAccess[ address(0xa71eEA6cfE9f879b05dB8B776e066069419a83be) ] = 2;
        freeMintAccess[ address(0x69287Fa2B775481a43196F298F6aacF5B6A890E7) ] = 2;
        freeMintAccess[ address(0xD13667a9c6990f728610039B8D2a8d4A931308c0) ] = 2;
        freeMintAccess[ address(0x069805bEFFb3deC781aff8b71dB9357Be7ae418c) ] = 2;
        freeMintAccess[ address(0xAD17C670D27096E8a637C2D4471e355A83E9a754) ] = 2;

    }
 
}