// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract DeezChristmasNuts is ERC721, Ownable {
    
    string public baseURI;
    
    uint16 MAX_NUTS = 3900;
    
    uint16 public totalSupply = 0;

    address proxyRegistryAddress;

    mapping(address => uint256) whitelist;

    mapping(address => uint256) alreadyMinted;

    bytes32 quadMerkleRoot = 0x8a5f23696618d8ec08d8ff0eddfdbea4115d7adc3338a9fc35f25e5f4a70b6b8;
    bytes32 tripleMerkleRoot = 0xdfa0cf29b15a72bd6811b80ca03972535022644df6a45542e8bc2c7f1a7d2565;
    bytes32 doubleMerkleRoot = 0x40de5e23047e3a36df0cdc034ad11cbef7c2db757629ee2b026386e7d0a92db0;
    bytes32 singleMerkleRoot = 0x1dd6f0f46cc19d13a505c433b4ceaad206e8143c68e5b77ee912f19c8ebc6225;

    bool public whitelistMinting;

    constructor(address _proxyRegistryAddress) ERC721("DeezChristmasNuts", "DCN") {
        proxyRegistryAddress = _proxyRegistryAddress;
        whitelistMinting = false;

        whitelist[0xEf72D8793Ab32d20358aa0303ae1405E8B695DA6] = 40;
        whitelist[0x4aE91684870B8B9C30fD79eF329dbaa96487948E] = 7;
        whitelist[0xBC2E6F35B3a525DEAa87919746cf6734E7591599] = 14;
        whitelist[0x0aBa7aAB3cA8B6330C9aE4C7989f347b5D4c9845] = 17;
        whitelist[0x177a683dCB55Dea54c422a15f4dF5bbcf4555985] = 19;
        whitelist[0xfDCF1850AF279738a00037486dA9A23e34E29bc1] = 6;
        whitelist[0x9c3bcBB07A40326B4A44D49df2Bdb83E6bce92aA] = 25;
        whitelist[0x19b44654A1FdD943AF5fb7fBC2C543fC7089A48a] = 5;
        whitelist[0x5bC124b3F28C301F497D3d44eB5c3225651143cb] = 27;
        whitelist[0x1097F467E199018e1F2E506cb646431E863C417f] = 9;
        whitelist[0x719f075ffFF05F1Ea5be249E1C160FFeEa881879] = 28;
        whitelist[0x27Da09392eb0a29511daB80F37f794FB7A103b3b] = 24;
        whitelist[0x82815C90D40073Ad14e1D0cB5bccbf8883862483] = 40;
        whitelist[0x27731cfE14982b9ccF8f7f9149B0CF854c51CA80] = 8;
        whitelist[0x1878388d2AbEF1D5305e2BF1c3Faaf2Cef037a8a] = 10;
        whitelist[0x9809F8AB3767555De4A41dC5E1Ffc15603B947c4] = 21;
        whitelist[0xFeEbB7251827A89143049d400573f71f54676adf] = 6;
        whitelist[0x0228dce3FDBc8381CDfCb3F7Ba9aa08f79b53D11] = 7;
        whitelist[0xfF47e41188Ed3B6598BD30730EccaCeF47985e7D] = 8;
        whitelist[0xa81D50239B25B41Ae762F481dA4DFE2F988A9211] = 35;
        whitelist[0x91684937A44b8bbee1aC193B753Ad50Ae16FC5F0] = 15;
        whitelist[0xAC701696fB691AE00a4d84C67b345Ba55f1C62a3] = 13;
        whitelist[0x9499054d02A725316d61fA896c29D58550ee4a5b] = 5;
        whitelist[0xD9CA2B65B8a90589a16354Ea178A14427b10AD32] = 5;
        whitelist[0x59AdCFcC37c5e58D954fb07162e3d0a14627E595] = 29;
        whitelist[0xD8e84A531b25faaFDa8C59F47ffCf41238AE2005] = 15;
        whitelist[0x54669Ca58bf3A59CaeA8AE5135Db491E4738f65A] = 26;
        whitelist[0x85Bf85Be063129f69D4D1633925A2E440805165A] = 5;
        whitelist[0x61431F590f9bFd848C7d51317A5e7d6e45bEccA2] = 26;
        whitelist[0x1b4b91bb747176451F0F7f73b636baBAfCF31Cc4] = 8;
        whitelist[0x9E68a58209aE4B04755CCEcD2E24A9dD0470755e] = 18;
        whitelist[0xd37893681919ab6b73A402c8E768F5E0ae54B52b] = 7;
        whitelist[0x19F25427742d51289AbA0F0D0EFB7C9d94EE02Db] = 10;
        whitelist[0xDaAf0EE861d80225FB906aeded033B034CA0bc7c] = 6;
        whitelist[0x1fbF4789Ac39De79936cCC29FA6789Db6848a275] = 7;
        whitelist[0x22d6d82aca6065547946b58DcEd7201670d1c1D0] = 12;
        whitelist[0xa28A86E0eAd66214efDC20E3c8193D0cE09268D1] = 14;
        whitelist[0xc5f5380FB9A03526bC256A5C8dfc845Eb9ade311] = 6;
        whitelist[0x791eE19eD660135878D35908D183b7171314D65D] = 8;
        whitelist[0xE3b42E0d193feB565D6fdF27571c178b887e274f] = 17;
        whitelist[0x56a5BBfB753CE8bC7bdeaAF5f68B073a658487B2] = 10;
        whitelist[0xCC850794Ba01EBD8142c8ca32e735f1A942068a0] = 5;
        whitelist[0x08Df0997964fAE66474C4A9Ddb1F7346aC5B5755] = 7;
        whitelist[0x0cac1CA1224c9793975DF39fDB6da713fe5eBA0A] = 5;
        whitelist[0x170a6428e8c06b2Bf63Eb5C32255125E251f7C4a] = 10;
        whitelist[0x8f2838D10F1047Db59D16FC617456C2d4EdA1BA4] = 8;
        whitelist[0x6cdF86e8892CDf00a7a144D81eDb8e8fb6325461] = 7;
        whitelist[0x00818d05Ec157c1E7A77E132761F5553e7800d49] = 5;
        whitelist[0x25aaD7773Ab2cE31b912381e81D3B8e38853FEC6] = 7;
        whitelist[0x379F2C9EE2EC7e52993222Ca95a067f20418CB91] = 9;
        whitelist[0xFce4B6287D101738d133a0AA7b5563316D1A04Dd] = 6;
        whitelist[0x1cb4bFA85adDbe39c028eEEF7f3677Abd86Eb8F6] = 15;
        whitelist[0xc9377B597CA47A54387C11C3bF257e226672C444] = 7;
        whitelist[0xb76f62C8995a14379A3D6d7BCBb8848473C63a29] = 9;
        whitelist[0x4577F7e3e6D7F249f3A4035c96bF14722eF5cfeC] = 7;
        whitelist[0x3810353c0eA030369c48448F992674657e77FDfa] = 5;
        whitelist[0xd88809018C63aB48c284342E24C11805d4870D43] = 5;
        whitelist[0x9f876D90731ea9d8B368BbC1e050A2082077085e] = 6;
        whitelist[0x4344Cf6B85BA6DD3A78ad051459cb1599B68124b] = 6;
        whitelist[0xEa5039f7346F0eE37C943c79dD368C78F0bc8Bac] = 5;
        whitelist[0x1cCDE298D9eA5621B7072caC8196db222164aa50] = 6;
        whitelist[0x7f5bEf39af11AA83dBC4366Dc12053834C1524f6] = 5;
        whitelist[0x274a5F5Ea6a2E0D184800FE891C4Aa5bCc715347] = 11;
        whitelist[0x0F293E7091aA4Fd1002Ee9D98Dd94Bbd310541b0] = 5;
        whitelist[0xf264330b74148F6717b60645350603Be913C0a91] = 5;
        whitelist[0xfa12CD4642C25f893CcBCb9c4b5FeF4c402940E7] = 7;
        whitelist[0x224F0f63DDcb29E9b53277D9000315d04Cc7CB8F] = 5;
        whitelist[0xdeeb758e147ea422E6bAd89bcfAFAbfAc0527949] = 16;
        whitelist[0x2cDA849421183AEFb697455E5610Db2ddF00dD1a] = 6;
        whitelist[0x4676B78d1eF20149d45bfC7eF3Fe4f127c184Be6] = 10;
        whitelist[0x94b5849D9880D5918E4C75e60c84F1c77EF627BF] = 6;
        whitelist[0x96acC14F8d521546637C3f4A6e08127da0f46139] = 5;
        whitelist[0x553aAcf16E6496F2778D810Ae37352C6342bd854] = 5;
        whitelist[0x02DEE48A27027B09b62ad062DC5e08B78eeE59E2] = 7;
        whitelist[0x548E68E4b2d2c0E02bBC43A29DF74B30C5BA1248] = 5;
        whitelist[0xa2F3AD23574867471231126B3C1a5B9b5c663E9A] = 5;
        whitelist[0x389Ea24a2f22E0113Efd1ae606B8E11659FAA8C8] = 12;
        whitelist[0xF4Dc66D1802d76D3B663556ff96F1F35dD01a9BB] = 5;
        whitelist[0xe705E2Cc9cCF39615f3a58fcc0F0D8fB0b6403bD] = 5;
        whitelist[0xD3acb55e8a58a29139e9404dEE5F0bAE5a21c7DA] = 6;
        whitelist[0xf4C3bc30D17B87462397BCBa443361056DC9E31D] = 5;
        whitelist[0xE7A5b718e6111eb3e389668cb76064C19AFDBc78] = 12;
        whitelist[0xdb2b59095Df5a0968DA15B5524f7773f37139528] = 5;
        whitelist[0x056171A08fe9cB2746A3F73C5d8d7c9c211754FF] = 5;
        whitelist[0x44ACeC69a158aAA061C364F8e83275a408B64fb3] = 6;
        whitelist[0x0C377e9832490D17b7F3F27f293386aDd677eD7B] = 5;
        whitelist[0xA21a8e443d516383B2f4108d581D4B4FD767214D] = 5;
        whitelist[0x75ee810CDcDd8750457BA6201F063B33CeBD0E71] = 10;
        whitelist[0x071Ee0E8A94184013cEB38a32d726012872E5354] = 5;
        whitelist[0x048977752E8163EF75e71B4D526e0a36F07A6DD5] = 6;
        whitelist[0x65607550d5D8233772ff5f09b668151381E80c12] = 5;
        whitelist[0xe5B2ebD020CaeB2CBa3d08d9748A7F2D257d1B24] = 5;
        whitelist[0x6d3A613DA670c4d12EA7B29B5774c60C6aeee955] = 5;
        whitelist[0x35389b42afDFca76317aE60920Cf6ae4406d2171] = 33;
        whitelist[0x6478c54d7e93801950Ef4970424D2E84BD1A7eA1] = 6;
        whitelist[0x801f59E2e3373e5401df55b37dC6E6f64bC82BBA] = 9;
        whitelist[0xF7c3ed5ae30561C65b3cd13cc265A5753Ba212Ef] = 33;
        whitelist[0x2b177fdb87A9Bab54b55f1eFf89B0Cf785513403] = 8;
        whitelist[0x01Fb51F8A664f0f2B7cf8f6EEE89F7C1b7e05Ba1] = 6;
        whitelist[0x2E999C8441e6EcA993966f1826199c8260D7237E] = 5;
        whitelist[0x7687B0b3ECD4D659aB6471c75FbeE8C6b069Bb27] = 5;
        whitelist[0x8aD5659a9c25Ee536cBF59c4d61BE4Ae27d25D0F] = 27;
        whitelist[0x37b8218472B7Ae973a94075eEBFa669C1fed0Ffd] = 5;
        whitelist[0x5Bf86144556B3EC85ce16efFb3e2fc458fF18F0B] = 5;
        whitelist[0xFA43c78aF9E7aa87DCB1E552645b27CC952108DD] = 7;
        whitelist[0x4aBff092BbF9e5705ba5216478F3AD0e3468b7E0] = 6;
        whitelist[0x19f8683373259db0c92360BC89D5D8e3624154df] = 5;
        whitelist[0xDAE5F98819cCC28E996c264E63421DB09b307B38] = 5;
        whitelist[0x2dAA384aE89124498D2Ab8115c6E5f2b6eE9d3De] = 5;
        whitelist[0x805b01E7F3Fe127769B249763250222630968b4d] = 7;
        whitelist[0xd5a9C4a92dDE274e126f82b215Fccb511147Cd8e] = 7;
        whitelist[0x32525ad3d4f20eA6732b5069CBD057a861a5Cb61] = 5;
        whitelist[0x7C229eC494Bc316dbAaf4eAB0FBbc19678eA315f] = 8;
        whitelist[0x004e20Cd7d2188fB812BfdB3F8F8bf3b3dA05874] = 5;
        whitelist[0x6e72A7916B0c2d6b09F7DBe8ee60536429633856] = 10;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseURI(string memory base) public onlyOwner {
        baseURI = base;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function whitelistMint(uint256 amount) external {
        require(whitelistMinting, "Whitelist minting isn't allowed yet");
        require(totalSupply + amount <= MAX_NUTS, "Purchase would exceed max supply");
        require(whitelist[msg.sender] > 0, "Sender is not whitelisted!");
        require(alreadyMinted[msg.sender] + amount <= whitelist[msg.sender], "Mint amount would exceed allowance");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply + 1);
            totalSupply += 1;
        }
        alreadyMinted[msg.sender] = alreadyMinted[msg.sender] + amount; 
    }

    function mintQuadMerkle(bytes32[] calldata _merkleProof) external {
        require(whitelistMinting, "Whitelist minting isn't allowed yet");
        require(totalSupply + 4 <= MAX_NUTS, "Purchase would exceed max supply");
        require(alreadyMinted[msg.sender] < 4, "User already minted 4!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, quadMerkleRoot, leaf), "User not whitelisted for 4 mints");

        for (uint256 i = 0; i < 4; i++) {
            _safeMint(msg.sender, totalSupply + 1);
            totalSupply += 1;
        }
        alreadyMinted[msg.sender] = 4;

    }

    function mintTripleMerkle(bytes32[] calldata _merkleProof) external {
        require(whitelistMinting, "Whitelist minting isn't allowed yet");
        require(totalSupply + 3 <= MAX_NUTS, "Purchase would exceed max supply");
        require(alreadyMinted[msg.sender] < 3, "User already minted 3!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, tripleMerkleRoot, leaf), "User not whitelisted for 3 mints");

        for (uint256 i = 0; i < 3; i++) {
            _safeMint(msg.sender, totalSupply + 1);
            totalSupply += 1;
        }  

        alreadyMinted[msg.sender] = 3;
        
    }

    function mintDoubleMerkle(bytes32[] calldata _merkleProof) external {
        require(whitelistMinting, "Whitelist minting isn't allowed yet");
        require(totalSupply + 2 <= MAX_NUTS, "Purchase would exceed max supply");
        require(alreadyMinted[msg.sender] < 2, "User already minted 2!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, doubleMerkleRoot, leaf), "User not whitelisted for 2 mints");

        for (uint256 i = 0; i < 2; i++) {
            _safeMint(msg.sender, totalSupply + 1);
            totalSupply += 1;
        }  

        alreadyMinted[msg.sender] = 2;
        
    }

    function mintSingle(bytes32[] calldata _merkleProof) external {
        require(whitelistMinting, "Whitelist minting isn't allowed yet");
        require(totalSupply + 1 <= MAX_NUTS, "Purchase would exceed max supply");
        require(alreadyMinted[msg.sender] < 1, "User already minted 1!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, singleMerkleRoot, leaf), "User not whitelisted for 1 mints");

        _safeMint(msg.sender, totalSupply + 1);
        totalSupply += 1;
        alreadyMinted[msg.sender] = 1;

        
    }

    function mint(address _address) public onlyOwner {
        require(totalSupply + 1 < MAX_NUTS, "All nuts have already been minted!");
        
        _safeMint(_address, totalSupply + 1);
        
        totalSupply += 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        return string(abi.encodePacked(_baseURI(), uint2str(tokenId), ".json"));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function enableWhitelistMinting() external onlyOwner {
        whitelistMinting = true;
    }


    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

     /**
     * @dev override transfer to prevent transfer of calimed tokens
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev override transfer to prevent transfer of calimed tokens
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev override transfer to prevent transfer of calimed tokens
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}