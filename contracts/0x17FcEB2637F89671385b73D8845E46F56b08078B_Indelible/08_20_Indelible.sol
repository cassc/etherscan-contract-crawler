// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "../extensions/ERC721AX.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "solady/src/utils/LibPRNG.sol";
import "solady/src/utils/Base64.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";
import "./lib/DynamicBuffer.sol";
import "./lib/HelperLib.sol";
import "./interfaces/IIndeliblePro.sol";
import "./interfaces/IAmmoToken.sol";
import "./interfaces/IBanditsRenderer.sol";

contract Indelible is ERC721AX, DefaultOperatorFilterer, ReentrancyGuard, Ownable {
    using HelperLib for uint;
    using DynamicBuffer for bytes;
    using LibPRNG for *;

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    
    struct LinkedTraitDTO {
        uint[] traitA;
        uint[] traitB;
    }
    
    struct TraitDTO {
        string name;
        string mimetype;
        bytes data;
        bool hide;
        bool useExistingData;
        uint existingDataIndex;
    }
    
    struct ContractData {
        string name;
        string description;
        string image;
        string banner;
        string website;
        uint royalties;
        string royaltiesRecipient;
    }
    
    struct WithdrawRecipient {
        string name;
        string imageUrl;
        address recipientAddress;
        uint percentage;
    }

    mapping(uint => bool) private _renderTokenOffChain;
    
    address payable private immutable COLLECTOR_FEE_RECIPIENT = payable(0x29FbB84b835F892EBa2D331Af9278b74C595EDf1);
    uint public constant COLLECTOR_FEE = 0.000777 ether;
    uint private constant MAX_BATCH_MINT = 20;
    bytes32 private constant TIER_2_MERKLE_ROOT = 0xda7f079e6aa74db0530c8b389db82b798e4c0ccc29d03db83649f8f5bc9a51ff;
    address private constant INDELIBLE_PRO = 0xf3DAEb3772B00dFB3BBb1Ad4fB3494ea6b9Be4fE;

    uint[] private primeNumbers = [
        210274846431799116011758110065640037513167259397816953288411,
        258651016223339299696400112684012163441306064889610262117641,
        655243881460218654410017181868621550334352057041656691604337,
        432534654635437988648695007417836862217547977730730769366091,
        308303271162912952052809502865981780926461827259681571923267,
        947803185312051153680939138255132052147806649202034860102891,
        881620940286709375756927686087073151589884188606081093706959,
        233798546572035042606454030173068619364505814127183530498703
    ];
    uint[][8] private tiers;
    uint private randomSeed;
    bytes32 private merkleRoot;
    string private networkId = "1";
    
    uint public maxSupply = 10000;
    uint public maxPerAddress = 5;
    uint public publicMintPrice;
    string public baseURI;
    bool public isPublicMintActive;
    uint public allowListPrice;
    uint public maxPerAllowList = 5;
    bool public isAllowListActive;
    address public ammoToken;
    address public banditsRenderer;

    ContractData public contractData = ContractData("OnChainBandits",unicode"On-chain game coming soon.","https://files.indelible.xyz/profile/a590dcbc-d140-4447-8bb8-76976eb2ba37","https://files.indelible.xyz/banner/a590dcbc-d140-4447-8bb8-76976eb2ba37","https://app.indelible.xyz/mint/onchainbandits",500,"0x29FbB84b835F892EBa2D331Af9278b74C595EDf1");
    WithdrawRecipient[] public withdrawRecipients;

    constructor() ERC721A("OnChainBandits", "BANDIT") {
        tiers[0] = [2998,1975,1806,1343,1218,660];
        tiers[1] = [1821,1679,1640,1311,1192,903,438,374,369,273];
        tiers[2] = [1893,1594,1336,1202,1182,1101,872,481,339];
        tiers[3] = [3413,2976,2429,1182];
        tiers[4] = [2763,2029,1726,1683,1329,470];
        tiers[5] = [3274,2516,2188,1863,159];
        tiers[6] = [1068,1054,983,932,714,694,609,581,571,566,541,473,301,216,196,176,121,89,74,41];
        tiers[7] = [1068,1054,983,932,714,694,609,581,571,566,541,473,301,216,196,176,121,89,74,41];
        randomSeed = uint(
            keccak256(
                abi.encodePacked(
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    msg.sender
                )
            )
        );
    }

    modifier whenMintActive() {
        require(isMintActive(), "Minting is not active");
        _;
    }

    receive() external payable {
        require(isPublicMintActive, "Public minting is not active");
        handleMint(msg.value / publicMintPrice, msg.sender);
    }

    function rarityGen(uint randinput, uint rarityTier)
        internal
        view
        returns (uint)
    {
        uint currentLowerBound = 0;
        for (uint i = 0; i < tiers[rarityTier].length; i++) {
            uint thisPercentage = tiers[rarityTier][i];
            if (
                randinput >= currentLowerBound &&
                randinput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    function getTokenDataId(uint tokenId) internal view returns (uint) {
        uint[] memory indices = new uint[](maxSupply);

        unchecked {
            for (uint i; i < maxSupply; i += 1) {
                indices[i] = i;
            }
        }

        LibPRNG.PRNG memory prng;
        prng.seed(randomSeed);
        prng.shuffle(indices);

        return indices[tokenId];
    }

    function tokenIdToHash(
        uint tokenId
    ) public view returns (string memory) {
        require(_exists(tokenId), "Invalid token");
        bytes memory hashBytes = DynamicBuffer.allocate(tiers.length * 4);
        uint tokenDataId = getTokenDataId(tokenId);

        uint[] memory hash = new uint[](tiers.length);
        uint traitSeed = randomSeed % maxSupply;

        for (uint i = 0; i < tiers.length; i++) {
            uint traitRangePosition = ((tokenDataId + i + traitSeed) * primeNumbers[i]) % maxSupply;
            hash[i] = rarityGen(traitRangePosition, i);
        }

        for (uint i = 0; i < hash.length; i++) {
            if (hash[i] < 10) {
                hashBytes.appendSafe("00");
            } else if (hash[i] < 100) {
                hashBytes.appendSafe("0");
            }
            if (hash[i] > 999) {
                hashBytes.appendSafe("999");
            } else {
                hashBytes.appendSafe(bytes(_toString(hash[i])));
            }
        }

        return string(hashBytes);
    }

    function handleMint(uint count, address recipient) internal whenMintActive {
        uint totalMinted = _totalMinted();
        require(count > 0, "Invalid token count");
        require(totalMinted + count <= maxSupply, "All tokens are gone");
        uint mintPrice = isPublicMintActive ? publicMintPrice : allowListPrice;
        bool shouldCheckProHolder = count * (mintPrice + COLLECTOR_FEE) != msg.value;

        if (isPublicMintActive && msg.sender != owner()) {
            if (shouldCheckProHolder) {
                require(checkProHolder(msg.sender), "Missing collector's fee.");
                require(count * publicMintPrice == msg.value, "Incorrect amount of ether sent");
            } else {
                require(count * (publicMintPrice + COLLECTOR_FEE) == msg.value, "Incorrect amount of ether sent");
            }
            require(_numberMinted(msg.sender) + count <= maxPerAddress, "Exceeded max mints allowed");
            require(msg.sender == tx.origin, "EOAs only");
        }

        uint batchCount = count / MAX_BATCH_MINT;
        uint remainder = count % MAX_BATCH_MINT;

        for (uint i = 0; i < batchCount; i++) {
            _mint(recipient, MAX_BATCH_MINT);
        }

        if (remainder > 0) {
            _mint(recipient, remainder);
        }

        if (!shouldCheckProHolder && COLLECTOR_FEE > 0) {
            handleCollectorFee(count);
        }
    }

    function handleCollectorFee(uint count) internal {
        uint256 totalFee = COLLECTOR_FEE * count;
        (bool sent, ) = COLLECTOR_FEE_RECIPIENT.call{value: totalFee}("");
        require(sent, "Failed to send collector fee");
    }

    function mint(uint count, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        whenMintActive
    {
        if (!isPublicMintActive && msg.sender != owner()) {
            bool shouldCheckProHolder = count * (allowListPrice + COLLECTOR_FEE) != msg.value;
            if (shouldCheckProHolder) {
                require(checkProHolder(msg.sender), "Missing collector's fee.");
                require(count * allowListPrice == msg.value, "Incorrect amount of ether sent");
            } else {
                require(count * (allowListPrice + COLLECTOR_FEE) == msg.value, "Incorrect amount of ether sent");
            }
            require(onAllowList(msg.sender, merkleProof), "Not on allow list");
            require(_numberMinted(msg.sender) + count <= maxPerAllowList, "Exceeded max mints allowed");
        }
        handleMint(count, msg.sender);
    }

    function checkProHolder(address collector) public view returns (bool) {
        IIndeliblePro proContract = IIndeliblePro(INDELIBLE_PRO);
        uint256 tokenCount = proContract.balanceOf(collector);
        return tokenCount > 0;
    }

    function airdrop(uint count, address[] calldata recipients)
        external
        payable
        nonReentrant
        whenMintActive
    {
        require(isPublicMintActive || msg.sender == owner(), "Public minting is not active");

        for (uint i = 0; i < recipients.length; i++) {
            handleMint(count, recipients[i]);
        }
    }

    function isMintActive() public view returns (bool) {
        return _totalMinted() < maxSupply && (isPublicMintActive || isAllowListActive || msg.sender == owner());
    }

    function hashToSVG(string memory _hash)
        public
        view
        returns (string memory)
    {
        IBanditsRenderer renderer = IBanditsRenderer(banditsRenderer);
        return renderer.hashToSVG(_hash);
    }

    function hashToSVG(string memory _hash, uint tokenId)
        public
        view
        returns (string memory)
    {
        IBanditsRenderer renderer = IBanditsRenderer(banditsRenderer);
        return renderer.hashToSVG(_hash, tokenId);
    }

    function hashToMetadata(string memory _hash)
        public
        view
        returns (string memory)
    {
        IBanditsRenderer renderer = IBanditsRenderer(banditsRenderer);
        return renderer.hashToMetadata(_hash);
    }

    function onAllowList(address addr, bytes32[] calldata merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(addr))) || MerkleProof.verify(merkleProof, TIER_2_MERKLE_ROOT, keccak256(abi.encodePacked(addr)));
    }

    function tokenURI(uint tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Invalid token");

        bytes memory jsonBytes = DynamicBuffer.allocate(1024 * 128);

        jsonBytes.appendSafe(
            abi.encodePacked(
                '{"name":"',
                contractData.name,
                " #",
                _toString(tokenId),
                '","description":"',
                contractData.description,
                '",'
            )
        );

        string memory tokenHash = tokenIdToHash(tokenId);
        
        if (bytes(baseURI).length > 0 && _renderTokenOffChain[tokenId]) {
            jsonBytes.appendSafe(
                abi.encodePacked(
                    '"image":"',
                    baseURI,
                    _toString(tokenId),
                    "?dna=",
                    tokenHash,
                    '&networkId=',
                    networkId,
                    '",'
                )
            );
        } else {
            jsonBytes.appendSafe(
                abi.encodePacked(
                    '"image":"',
                    hashToSVG(tokenHash),
                    '",'
                )
            );
        }

        jsonBytes.appendSafe(
            abi.encodePacked(
                '"attributes":',
                hashToMetadata(tokenHash),
                "}"
            )
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(jsonBytes)
            )
        );
    }

    function contractURI()
        public
        view
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        contractData.name,
                        '","description":"',
                        contractData.description,
                        '","image":"',
                        contractData.image,
                        '","banner":"',
                        contractData.banner,
                        '","external_link":"',
                        contractData.website,
                        '","seller_fee_basis_points":',
                        _toString(contractData.royalties),
                        ',"fee_recipient":"',
                        contractData.royaltiesRecipient,
                        '"}'
                    )
                )
            )
        );
    }

    function tokenIdToSVG(uint tokenId)
        public
        view
        returns (string memory)
    {
        return hashToSVG(tokenIdToHash(tokenId), tokenId);
    }

    function walletOfOwner(address addr)
        external
        view
        returns (uint256[] memory)
    {
        uint256 count;
        uint256 walletBalance = balanceOf(addr);
        uint256[] memory tokens = new uint256[](walletBalance);

        uint256 i;
        for (; i < maxSupply; ) {
            // early break if all tokens found
            if (count == walletBalance) {
                return tokens;
            }

            // exists will prevent throw if burned token
            if (_exists(i) && ownerOf(i) == addr) {
                tokens[count] = i;
                count++;
            }

            ++i;
        }
        return tokens;
    }

    function setContractData(ContractData calldata data) external onlyOwner {
        contractData = data;
    }

    function setMaxPerAddress(uint max) external onlyOwner {
        maxPerAddress = max;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
        emit BatchMetadataUpdate(0, maxSupply - 1);
    }

    function setRenderOfTokenId(uint tokenId, bool renderOffChain) external {
        require(msg.sender == ownerOf(tokenId), "Not token owner");
        _renderTokenOffChain[tokenId] = renderOffChain;
        emit MetadataUpdate(tokenId);
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setMaxPerAllowList(uint max) external onlyOwner {
        maxPerAllowList = max;
    }

    function setAllowListPrice(uint price) external onlyOwner {
        allowListPrice = price;
    }

    function setPublicMintPrice(uint price) external onlyOwner {
        publicMintPrice = price;
    }

    function setAmmoToken(address ammoTokenAddress) external onlyOwner {
        ammoToken = ammoTokenAddress;
    }

    function setBanditsRenderer(address banditsRendererAddress) external onlyOwner {
        banditsRenderer = banditsRendererAddress;
        emit BatchMetadataUpdate(0, maxSupply - 1);
    }

    function toggleAllowListMint() external onlyOwner {
        isAllowListActive = !isAllowListActive;
    }

    function togglePublicMint() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint balance = address(this).balance;
        uint amount = balance;
        uint distAmount = 0;
        uint totalDistributionPercentage = 0;

        address payable receiver = payable(owner());

        if (withdrawRecipients.length > 0) {
            for (uint i = 0; i < withdrawRecipients.length; i++) {
                totalDistributionPercentage = totalDistributionPercentage + withdrawRecipients[i].percentage;
                address payable currRecepient = payable(withdrawRecipients[i].recipientAddress);
                distAmount = (amount * (10000 - withdrawRecipients[i].percentage)) / 10000;

                Address.sendValue(currRecepient, amount - distAmount);
            }
        }
        balance = address(this).balance;
        Address.sendValue(receiver, balance);
    }

    function transferFrom(address from, address to, uint tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint startTokenId,
        uint quantity
    ) internal virtual override {
        if (from != address(0)) {
            IAmmoToken(ammoToken).stopDripping(from, 1);
        }
        if (to != address(0)) {
            IAmmoToken(ammoToken).startDripping(to, 1);
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}