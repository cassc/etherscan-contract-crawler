//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract JillByMolly is ERC721, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 888;
    uint256 public currentSupply = 0;

    uint256 public salePrice = 0.05 ether;
    uint256 public presalePrice = 0.04 ether;

    uint256 public presaleCount;
    uint256 public freeMinted;

    //Placeholders
    address private presaleAddress = address(0xB09356a4c137bB462120B362A4837C9F7C9FBb90);
    address private freeAddress = address(0x5b051517516fC9B3E647678aD346a1a122a52ed4);
    address private wallet = address(0x17Ed15ea125055E0234a0022F05a1d942D489877);

    string private baseURI;
    string private notRevealedUri = "ipfs://QmUfq7oXsjHEYeSgTa7jkvqoKVazyZNDe4DR7pYtNTbkQ6";

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
    mapping(address => uint256) public freeMintLog;

    constructor()
        ERC721("Jill By Molly", "Jill")
    {
        transferOwnership(msg.sender);
        workflow = WorkflowStatus.Before;

        initFree();
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
            "Jill By Molly: Mint too large, exceeding the maxSupply"
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
            "Jill By Molly: Presale is not currently active."
        );

        require(
            validateSignature(
                presaleAddress,
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );

        require(amount > 0, "You must mint at least one token");

        //Price check
        require(
            msg.value >= presalePrice * amount,
            "Jill By Molly: Insuficient ETH amount sent."
        );

        presaleCount += amount;
        currentSupply += amount;
        presaleMintLog[ msg.sender ] += amount;

        mintBatch(msg.sender, currentSupply - amount, amount);
    }

    function publicSaleMint(uint256 amount) external payable {
        require( amount > 0, "You must mint at least one NFT.");
        
        uint256 supply = currentSupply;

        require( supply < maxSupply, "Jill By Molly: Sold out!" );
        require( supply + amount <= maxSupply, "Jill By Molly: Selected amount exceeds the max supply.");

        require(
            workflow == WorkflowStatus.Sale,
            "Jill By Molly: Public sale has not active."
        );

        require(
            msg.value >= salePrice * amount,
            "Jill By Molly: Insuficient ETH amount sent."
        );

        currentSupply += amount;

        mintBatch(msg.sender, supply, amount);
    }

    function forceMint(uint256 number, address receiver) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "Jill By Molly: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch( receiver, supply, number);
    }

    function ownerMint(uint256 number) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "Jill By Molly: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch(msg.sender, supply, number);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = currentSupply;
        require(
            supply + addresses.length <= maxSupply,
            "Jill By Molly: You can't mint more than max supply"
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
        freeMintAccess[ address(0x2b79a93D04A1655BAE5E7ba927B87Fa01b059f0c) ] = 61;
        freeMintAccess[ address(0xC475915010B03Bb3399D869ce27e79A76cAd7A01) ] = 25;
        freeMintAccess[ address(0x59F2052a3ff8cDfe4cBAae027364bdFE52715e33) ] = 10;
        freeMintAccess[ address(0xbD519E4fcf0cE7d3C7fd8f5aD2BdF4E9B869B445) ] = 9;
        freeMintAccess[ address(0xD58D449Af4832d76eD247e0b2DD80327CfE377c0) ] = 9;
        freeMintAccess[ address(0xf2ECcCCcDB5a56fD2E37a4e79BdD70F48Ec48a07) ] = 9;
        freeMintAccess[ address(0x7E6ddE8aE44dC50C24fD344dc5e4d3B07db1c23F) ] = 7;
        freeMintAccess[ address(0x258E0eF6F63077c0Ab26837597541312Db1EB06e) ] = 6;
        freeMintAccess[ address(0x771448e7eb02906e42AaEFb39da32603D011b8a9) ] = 6;
        freeMintAccess[ address(0xC06bf0e39507aCB0D46b66a4aC8fb71db9D0337b) ] = 6;
        freeMintAccess[ address(0xe033D76E565D855101fB788881abEA51066BDCb0) ] = 6;
        freeMintAccess[ address(0x88C9484c3107A309Cd30A1671d7B7Fa42995559E) ] = 5;
        freeMintAccess[ address(0xB18150275285BeCfcBb717f65B10Df2d211D5a02) ] = 5;
        freeMintAccess[ address(0xc6abc8CD657b44254c24ED304Fc953D5F58824d3) ] = 5;
        freeMintAccess[ address(0x85dc799427210ACD1E1347A080618145Dd1E42C3) ] = 4;
        freeMintAccess[ address(0x049c08f98A751F64DF8e0867457db2Fb21F573B6) ] = 3;
        freeMintAccess[ address(0x0dA1E9705F3393D55a1645c30aC26869D5553AbD) ] = 3;
        freeMintAccess[ address(0x11450A28c4A687A134AaD319ADc0d53900eaD50F) ] = 3;
        freeMintAccess[ address(0x15491db59C7C9B98B290935dc0465Cac5576B12B) ] = 3;
        freeMintAccess[ address(0x23db0c948329A33383945B5C3497ebc0819ACdfb) ] = 3;
        freeMintAccess[ address(0x265677Fc8754D5C2A3EEF2c5E0a85eEf35Bd205f) ] = 3;
        freeMintAccess[ address(0x26e1C4be5915F51946190033F89c9Ea3d2C470dB) ] = 3;
        freeMintAccess[ address(0x2Ae45Cc80909746E9dAE8D561BB7E83466273961) ] = 3;
        freeMintAccess[ address(0x2e16ee698B05BDFc0125DD0de5C8913004F5E5c3) ] = 3;
        freeMintAccess[ address(0x37735C72b0b1936EA79d6183849Fe5aF008B53fE) ] = 3;
        freeMintAccess[ address(0x3d3b44e1b9372Ff786aF1f160793AC580B2b22ae) ] = 3;
        freeMintAccess[ address(0x4261DB973C27f7e4CDC2090990c2ebB52935B8E2) ] = 3;
        freeMintAccess[ address(0x434f1A372D0A873E59882998194559A46bD651e9) ] = 3;
        freeMintAccess[ address(0x488aE9C7439e68d82280E23C02c1767bccD2B3eD) ] = 3;
        freeMintAccess[ address(0x4aD09330ACF67d2E9b8FeEf4420BEDB8b6b2605c) ] = 3;
        freeMintAccess[ address(0x533BE8603F70070f418c7d53CC68d72D345C33f8) ] = 3;
        freeMintAccess[ address(0x69e69571d0d07EdBEde6c43849e8d877573eE6bf) ] = 3;
        freeMintAccess[ address(0x6D147067c67bEF245875d968dfbc4715c23a8Bb6) ] = 3;
        freeMintAccess[ address(0x6D35fa416e615bB28feA3c970575c33fa155Ef9f) ] = 3;
        freeMintAccess[ address(0x7dF943591d4b71e5E5E3be9a4B1963b0476bB432) ] = 3;
        freeMintAccess[ address(0x870Bf9b18227aa0d28C0f21689A21931aA4FE3DE) ] = 3;
        freeMintAccess[ address(0x8D98139512ac57459A468BC10ccf30Fd9dd6149A) ] = 3;
        freeMintAccess[ address(0x9D47C98EB709603Aa82514F96b6EfA7939F2eDc1) ] = 3;
        freeMintAccess[ address(0xA0C155D1FdeA5393Cd6175c4620a3dfBDE330b72) ] = 3;
        freeMintAccess[ address(0xA7cd7Fe9e0300eC83117914b944AeA93b5F3E22B) ] = 3;
        freeMintAccess[ address(0xaCff0c9930700e8aF89b4DA0360753941180C601) ] = 3;
        freeMintAccess[ address(0xAd3Daf78B01DF5bE01AF74CD10837b9436F57520) ] = 3;
        freeMintAccess[ address(0xAfC458296efcE0f2838Ef8367666B2ab3554dC41) ] = 3;
        freeMintAccess[ address(0xD4BCE9c082e315b8E3D0A79bFB5c6daA36e9531B) ] = 3;
        freeMintAccess[ address(0xe3CfcA77ABD43195E0838DBe692D4E6313CAfCcb) ] = 3;
        freeMintAccess[ address(0xE5d08078CA78C9B14101f16fcACbEE8818D06Bfa) ] = 3;
        freeMintAccess[ address(0xE92DD81DD13F053cb5dcF0A7f5731db6937E992B) ] = 3;
        freeMintAccess[ address(0xe9bB334033e377E50038132556f285408B0478e0) ] = 3;
        freeMintAccess[ address(0xEd76E6b7E643A4476033c75Cb1f1fAeAe4cA12D9) ] = 3;
        freeMintAccess[ address(0xf4aD9E72311a38F7D3Eeec61d161fd525Ecd2f93) ] = 3;
        freeMintAccess[ address(0x00D4da27deDce60F859471D8f595fDB4aE861557) ] = 2;
        freeMintAccess[ address(0x1306Ad73b6B3561906E2703244b302b31e849f2D) ] = 2;
        freeMintAccess[ address(0x14eca571cdA7a721171fa2b575a1DAbE1f8369Fc) ] = 2;
        freeMintAccess[ address(0x1BCAb05F4eE1f5dBCa5ed52D8ad204bdC39C58F6) ] = 2;
        freeMintAccess[ address(0x1Cf5B683643D382284c6b3fCCf425c612b8C69e3) ] = 2;
        freeMintAccess[ address(0x1D2aD10a77CCCF343f8D5c7d78eaa6B5f7a0547B) ] = 2;
        freeMintAccess[ address(0x23f3c4dD6297A36A2140d5478188D9e773D3Ac9E) ] = 2;
        freeMintAccess[ address(0x2f161c1ceBBcDc1A0C843Bd09a202E4BFc2C717D) ] = 2;
        freeMintAccess[ address(0x2fF79f7B42FE97A72c54cFc985589B4f55A7423d) ] = 2;
        freeMintAccess[ address(0x3220E8846D1D3b1a82D2342f4351d7E0e834fC49) ] = 2;
        freeMintAccess[ address(0x351E0db8bDE58C73CB2F168Fed7fA5B65Bde7f2f) ] = 2;
        freeMintAccess[ address(0x36d2a0E77EA4Ada81B0c6b183aCFe12c430C1074) ] = 2;
        freeMintAccess[ address(0x400665C0eb68da4564bbbD6A24bBfac65Bd17305) ] = 2;
        freeMintAccess[ address(0x447119994c803260BA30e989bb633Fe8B650652c) ] = 2;
        freeMintAccess[ address(0x4cEA643706ACc07dDC9b58570A55c6e86d281e73) ] = 2;
        freeMintAccess[ address(0x508acec8601AfEf3A1285f7C8c913077452A891c) ] = 2;
        freeMintAccess[ address(0x564F8293d69c8D3f8b840A26a2cff63112b78061) ] = 2;
        freeMintAccess[ address(0x57b979011859cf161793A1E8cCf623CCDAbbEea3) ] = 2;
        freeMintAccess[ address(0x59626e6237bA2C9DDD4fC2C05d38A63B895ab8bf) ] = 2;
        freeMintAccess[ address(0x6cf995436E97beD7c1611f18B3b73d60Ca50A1Dd) ] = 2;
        freeMintAccess[ address(0x6EDf6b0229C9A205d0D0E4f81e6a956e064ECFAa) ] = 2;
        freeMintAccess[ address(0x7254a934DAd6aB3559efDBc7c2e8FD3D3825146D) ] = 2;
        freeMintAccess[ address(0x7Ec94fD63f07ab5B35323A393DEF89aC6Ab652CA) ] = 2;
        freeMintAccess[ address(0x828ED67AD51733F51c2067BFE1bF478405177C98) ] = 2;
        freeMintAccess[ address(0x888c636fc34aADA02942262c78B7be8Ded0C93A9) ] = 2;
        freeMintAccess[ address(0xA04294Ca075F369c900D6399c3D809Ee4417C5B5) ] = 2;
        freeMintAccess[ address(0xA4d9E8beB4Cd00Da4E14a073935fb2f4A9ea0FD0) ] = 2;
        freeMintAccess[ address(0xacCB1e0eAa4d6bB3AB8268cFa8fB08d77F082655) ] = 2;
        freeMintAccess[ address(0xB1Dfd9b8E9cE5E0886A29f3878A72cf843e28d0B) ] = 2;
        freeMintAccess[ address(0xBCAacC0497e8A0e808243C0b492c3AE97fb9b4A8) ] = 2;
        freeMintAccess[ address(0xC375AF9666078099A4CA193B3252Cc19F2af464B) ] = 2;
        freeMintAccess[ address(0xc4727E16A08097c9f0f79385559908d576D0e9e3) ] = 2;
        freeMintAccess[ address(0xC69Cf303fFBbAcf328667744dfA7940F6f031914) ] = 2;
        freeMintAccess[ address(0xCBc6C9CeF4f3C7cbBb8Eb82A2aD60c00e631A8C1) ] = 2;
        freeMintAccess[ address(0xCbd548A8D5c52A6116dF65A08B73C0dCDE9412ff) ] = 2;
        freeMintAccess[ address(0xD1a733172DBf8B2b9e1815b37749CBAcc56F0F9e) ] = 2;
        freeMintAccess[ address(0xD53406AAec8D9650e118eC385c71c00adf6a06F3) ] = 2;
        freeMintAccess[ address(0xdB0201713165d8056cFC308EA5B4aAc78f362EE7) ] = 2;
        freeMintAccess[ address(0xe8F2EEB6CC1eF517C5DDE6a3E4dfE0a83D5dB207) ] = 2;
        freeMintAccess[ address(0xFaB96a307b54564d227866Ed9106368079415196) ] = 2;
        freeMintAccess[ address(0xff43bcCA6A913c0af7cFCE7fA5Ccc0D61B4Fa801) ] = 2;
    }

}