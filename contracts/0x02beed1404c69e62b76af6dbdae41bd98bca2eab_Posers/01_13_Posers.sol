// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";

contract Posers is ERC721A, Ownable {

    using ECDSA for bytes32;

    uint constant public MAX_SUPPLY = 5000;

    // prices
    uint public wlPrice = 0.02 ether;
    uint public poserPrice = 0.03 ether;
    uint public degenPrice = 0.05 ether;

    // constraints
    uint public maxMintsPerWallet = 3;
    mapping(address => bool) public isUsedFreeMint;
    mapping(address => uint) public mintedNFTs;

    // oracle data signer
    address public authorizedSigner = 0x05565f89Af3EeECd460d45047A659670CE1ED65b;

    // random things
    uint public collectionSeed;
    mapping(uint => uint) public batchSeed;

    // poser collections
    address[] public poserCollections;
    // open sale manually
    bool public saleStartedForcibly;

    // metadata generator
    address public metadataProvider = 0x0DF7552D49137fF65986dEeb18A11450458D6507;

    constructor() ERC721A("posers", "pos", 20) {
        poserCollections = [
            0x620b70123fB810F6C653DA7644b5dD0b6312e4D8,
            0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85,
            0xED5AF388653567Af2F388E6224dC7C4b3241C544,
            0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6,
            0x23581767a106ae21c074b2276D25e5C3e136a68b,
            0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e,
            0x79FCDEF22feeD20eDDacbB2587640e45491b757f,
            0xa3AEe8BcE55BEeA1951EF834b99f3Ac60d1ABeeB,
            0xb668beB1Fa440F6cF2Da0399f8C28caB993Bdd65,
            0x922b95416763a9C37BeAC82DE7E2dDB75ac35F37,
            0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB,
            0x86357A19E5537A8Fba9A004E555713BC943a66C0,
            0x7Bd29408f11D2bFC23c34f18275bBf23bB716Bc7,
            0xfC23F958C86D944418D7965a5F6582d1E96Db1be,
            0x08D7C0242953446436F34b4C78Fe9da38c73668d,
            0x49cF6f5d44E70224e2E23fDcdd2C053F30aDA28B,
            0x1A92f7381B9F03921564a437210bB9396471050C,
            0xBd3531dA5CF5857e7CfAA92426877b022e612cf8,
            0x59468516a8259058baD1cA5F8f4BFF190d30E066,
            0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03,
            0xcBd38d10511F0274e040085c0BC1F85CC96Fff82,
            0x42069ABFE407C60cf4ae4112bEDEaD391dBa1cdB,
            0x57a204AA1042f6E66DD7730813f4024114d74f37,
            0x209e639a0EC166Ac7a1A4bA41968fa967dB30221,
            0xbCe3781ae7Ca1a5e050Bd9C4c77369867eBc307e,
            0x08BA8CBbefa64Aaf9DF25e57fE3f15eCC277Af74,
            0x39cbE44fe0161785F643b53489a549d802478ddf,
            0x26BAdF693F2b103B021c670c852262b379bBBE8A,
            0x80336Ad7A747236ef41F47ed2C7641828a480BAA,
            0x9df8Aa7C681f33E442A0d57B838555da863504f3,
            0x916c6AF08BF922Eaf80C05975886c0A421C78A35,
            0x39ee2c7b3cb80254225884ca001F57118C8f21B6,
            0x394E3d3044fC89fCDd966D3cb35Ac0B32B0Cda91,
            0x9ada21A8bc6c33B49a089CFC1c24545d2a27cD81,
            0xEDc3AD89f7b0963fe23D714B34185713706B815b,
            0x60E4d786628Fea6478F785A6d7e704777c86a7c6
        ];
    }

    // poser
    function isPOSer(address account) public view returns (bool){
        for (uint i = 0; i < poserCollections.length; i++) {
            if (IERC721(poserCollections[i]).balanceOf(account) > 0) {
                return true;
            }
        }
        return false;
    }

    // wl checks
    function hashTransaction(address minter) internal pure returns (bytes32) {
        bytes32 argsHash = keccak256(abi.encodePacked(minter));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", argsHash));
    }

    function recoverSignerAddress(address minter, bytes calldata signature) internal pure returns (address) {
        bytes32 hash = hashTransaction(minter);
        return hash.recover(signature);
    }

    function isAccountWhitelisted(address account, bytes calldata signature) public view returns (bool) {
        return signature.length > 0 && recoverSignerAddress(account, signature) == authorizedSigner;
    }

    // poser && signed
    function mintWl(uint amount, bytes calldata signature) public payable {
        require(isSaleStarted(), "Mint is not open");
        require(isAccountWhitelisted(msg.sender, signature), "msg.sender is not whitelisted");
        require(isPOSer(msg.sender), "msg.sender is not HODLer");

        uint amountToPay = isUsedFreeMint[msg.sender] ? amount : amount - 1;
        isUsedFreeMint[msg.sender] = true;

        require(mintedNFTs[msg.sender] + amount <= maxMintsPerWallet, "Too much mints for this wallet!");
        require(amountToPay * wlPrice == msg.value, "Wrong msg.value");

        setCollectionSeedIfNotSet();
        mintedNFTs[msg.sender] += amount;
        mint(msg.sender, amount);
    }

    // poser only
    function mintPoser(uint amount) public payable {
        require(isSaleStarted(), "Mint is not open");
        require(isPOSer(msg.sender), "msg.sender is not HODLer");

        require(mintedNFTs[msg.sender] + amount <= maxMintsPerWallet, "Too much mints for this wallet!");
        require(amount * poserPrice == msg.value, "Wrong msg.value");

        setCollectionSeedIfNotSet();
        mintedNFTs[msg.sender] += amount;
        mint(msg.sender, amount);
    }

    // for degens only
    function mintDegen(uint amount) public payable {
        require(isSaleStarted(), "Mint is not open");

        require(mintedNFTs[msg.sender] + amount <= maxMintsPerWallet, "Too much mints for this wallet!");
        require(amount * degenPrice == msg.value, "Wrong msg.value");

        setCollectionSeedIfNotSet();
        mintedNFTs[msg.sender] += amount;
        mint(msg.sender, amount);
    }

    // for devs and winners
    function airdrop(address[] calldata addresses, uint[] calldata amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            mint(addresses[i], amounts[i]);
        }
    }

    // set collection seed
    function setCollectionSeedIfNotSet() internal {
        if (collectionSeed == 0) {
            collectionSeed = uint(blockhash(block.number - 1));
        }
    }

    // mint and save batch seed
    function mint(address account, uint amount) internal {
        require(totalSupply() + amount <= MAX_SUPPLY, "Out of tokens!");
        batchSeed[totalSupply()] = random(account);
        _safeMint(account, amount);
    }

    // pseudo random
    function random(address minter) public view returns (uint) {
        return uint(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    totalSupply(),
                    minter
                )
            )
        );
    }

    // extract token seed using batch seed
    function getTokenKey(uint tokenId) public view returns (uint) {
        require(collectionSeed != 0, "Collection seed is not set");
        for (uint i = 0; i < maxBatchSize; i++) {
            uint seed = batchSeed[tokenId - i];
            if (seed != 0) {
                return uint(keccak256(abi.encode(collectionSeed, seed, i)));
            }
        }
        revert("unreachable code I hope");
    }

    // base64 encoded meta and image from metadata provider
    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(metadataProvider != address(0), "Metadata Provider is not set");

        return MetadataProvider(metadataProvider)
            .tokenMeta(tokenId, getTokenKey(tokenId));
    }

    // sale opened manually or the merge occurred
    function isSaleStarted() public view returns (bool) {
        return saleStartedForcibly || block.difficulty > 2 ** 64 || block.difficulty == 0;
    }

    // place to setters available before renounceOwnership()
    // configure all variables
    function configure(
        uint _wlPrice,
        uint _poserPrice,
        uint _degenPrice,
        address _authorizedSigner,
        bool _saleStartedForcibly,
        address _metadataProvider
    ) external onlyOwner {
        wlPrice = _wlPrice;
        poserPrice = _poserPrice;
        degenPrice = _degenPrice;
        authorizedSigner = _authorizedSigner;
        saleStartedForcibly = _saleStartedForcibly;
        metadataProvider = _metadataProvider;
    }

    // add poser collections
    function addPoserCollections(address[] calldata _poserCollections) external onlyOwner {
        for (uint i = 0; i < _poserCollections.length; i++) {
            poserCollections.push(_poserCollections[i]);
        }
    }

    // modify inplace
    function modifyPoserAt(uint index, address replaceCollection) external onlyOwner {
        poserCollections[index] = replaceCollection;
    }

    // reset poser collections
    function resetPoserCollections() external onlyOwner {
        delete poserCollections;
    }

    // start salemanually
    function setSaleStartedForcibly(bool _saleStartedForcibly) external onlyOwner {
        saleStartedForcibly = _saleStartedForcibly;
    }

    // withdraw
    function withdraw() external {
        uint balance = address(this).balance;
        payable(0xFeE836516a3Fc5f053F35964a2Bed9af65Da8159).transfer(balance * 5 / 100);
        payable(0xA12EEeAad1D13f0938FEBd6a1B0e8b10AB31dbD6).transfer(balance * 61 / 100);
        payable(0x853B28a4A0cFc0DBAf5349824063Eb5DB54775C1).transfer(balance * 5 / 100);
        payable(0x612DBBe0f90373ec00cabaEED679122AF9C559BE).transfer(balance * 8 / 100);
        payable(0x9db13B06345c1bf5684f02aA2022103e11B3a702).transfer(balance * 8 / 100);
        payable(0x11CaFe39a4d956c0c9ed0EE780e83A8245885917).transfer(balance * 8 / 100);
        payable(0xeFA6F0951E1F8Df2F8EBf2D879ac6A137688fE4B).transfer(balance * 5 / 100);
    }
}

interface MetadataProvider {
    function tokenMeta(uint tokenId, uint tokenSeed) external view returns (string memory);
}