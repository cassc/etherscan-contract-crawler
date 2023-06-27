pragma solidity ^0.8.10;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

//*******************************************************************************
//*******************************************************************************
//...............................................................................
//......................,,::,....................................................
//.........*%*;:,,......+##S%?+;:,...............................................
//.........,+S##S%?*+;,,.+#@@###S%?+,............................................
//............;S######SS%*+#@@@#####S?+:,........................................
//............+#@@#SS###@@######@@######S%?+::,..................................
//....,:;:,[email protected]##@####@@@@@#####@@##########SS?+,...............................
//....+##S%%*;:[email protected]##@###@@@@@@@@##############@@#?;.............................
//.....;[email protected]####SS####S#######@@@@@########SSS#######%?,...........................
//......,*#@@#####@######@S###@S##;:S######S*%####@@@*,..........................
//........,*#@@@####@@##S#@@#S##:,,;###@###S%?*?S###@@S?+:.......................
//.......,?#@#S##SSS###S###@#S#S+;.:##@#@@@##SS%*#@##@@S*+.......................
//........:*@@%S#S%SSS######S#@##S?S##@@@##@@#%SS?%#@##@#+.......................
//..........*S##@#%#S%%S####SSS#@@#@@@@@@@@#####S#S?%#@##@%:.....................
//...........,;*%#@########@@@###@@#@@@@@@@@@@#######%%#####+,...................
//...............:+S#####SSSSS####@@@@@###@@@@@@####@@#S####@S,..................
//..................;%#########S#S%S#@@###@@@@@@@@###@@@@####@?,.................
//....................:+*%##@##[email protected]@@#####S###@@@##@@@@@@@@###@#?+,..............
//.......................,;+*%S*,;?%SSS;,*,,;S##@@@##@@###@@@###@#S?:............
//............................,;:,...:+;;,...,;?S#@@@#@@@##@@##S##S#*............
//..............................................,;?S#####@@@@@@@##SSS*:..........
//.................................................,;?S########@@@@@###:.........
//.....%%..%%..%%%%%%...%%%%...%%..%%.................,;+?%S##@##@@@@@@+.........
//.....%%..%%..%%......%%..%%..%%..%%......................:*%S####@@@@S,........
//.....%%..%%..%%%%....%%......%%%%%%..........................:+?%#@@#S?........
//......%%%%...%%......%%..%%..%%..%%..............................:;++.,........
//.......%%....%%%%%%...%%%%...%%..%%............................................
//...............................................................................
//... Founders: HYDN#1234 & fudzero#0856 ........................................
//... Contract developer: Moonfarm#1138 .........................................
//...............................................................................
//*******************************************************************************
//*******************************************************************************

contract VechTokenContract is ERC721Enumerable, Ownable, ERC721Pausable {
    using SafeMath for uint256;
    using MerkleProof for bytes32[];

    struct PartialReveal {
        uint256 seed;
        uint256 tokenCount;
    }

    /// max amount of tokens in the collection
    uint256 public maxTokens = 8888;
    /// minted public tokens
    uint256 public mintedPublicTokens;
    /// price per token minted
    uint256 public whitelistTokenPrice = 0.05 ether;
    /// price per token minted
    uint256 public publicTokenPrice = 0.08 ether;
    /// amount of tokens a whitelisted address can mint
    uint256 public preSaleTokensPerAddress = 3;
    /// max amount of tokens minted in one transaction
    uint256 public maxTokensPerTxn = 5;

    // ### Reserved tokens ###

    /// reserved tokens for the team
    uint8 public teamReservedTokens = 30; 
    /// amount of reserved tokens minted
    uint256 public mintedReservedTokenCount;
    /// reserved tokens for promotions
    uint256 public collabReservedTokens = 98; 
    /// amount of reserved tokens minted
    uint256 public mintedCollabTokenCount;
    
    // ###

    /// max amount of tokens in the collection
    uint256 public maxPublicMintableTokens = maxTokens - collabReservedTokens; // 8888 - 98 = 8790

    // ### Active Sales ###

    /// og-sale allows addresses in ogAddress to mint
    /// through ogSaleMint()
    bool public ogSaleIsActive;
    /// pre-sale allows addresses in whitelistedAddress to mint
    /// through preSaleMint()
    bool public preSaleIsActive;
    /// public-sale allows anyone to mint
    /// through publicMint()
    bool public publicSaleIsActive;

    // ###

    // saves the baseURI internally
    string private baseURI;
    // saves the baseURI for unrevealed tokens internally
    string private unrevealedBaseURI;

    /// track how many tokens every og has minted
    mapping(address => uint8) public ogMints;
    // merkle root used to verify that a user is in the og-list
    bytes32 ogMerkleRoot;

    /// minted tokens per whitelisted address
    mapping(address => uint8) public whitelistedMints;
    // merkle root used to verify that a user is in the whitelist
    bytes32 whitelistMerkleRoot;

    /// save seeds and tokenCounts for reveals
    mapping(uint8 => PartialReveal) public partialReveals;
    uint8 reveals;
    uint256 revealedTokens;

    // ### Payout addresses for the team ###
    address mintersAddress = 0xd52A48A06D63754972F90Cd22D2b91649CFdf231; // Minters collective
    address maximAddress = 0x261AC500143171b14Adf7729d33eECD1C5859206; // Lead FX Artist
    address gilliesAddress = 0x71917bc9F1cc593ab86eDE456E54fF1De33362D3; // Consultant
    address rodneyAddress = 0x4a53132d7c16240A834f165237Acb72be8E85B3A; // Partner
    address moonfarmAddress = 0x0C7a1AE154717fdA46A8cc52913C63572FDb66e8; // Developer
    address burnzAddress = 0x5Df222B967b0C609573Df5e71339616722935303; // Discord team
    address dvolutionAddress = 0x327c4CDE7c1980D5327982cA2FCA195a20bB7825; // Discord team
    address cuhryptoAddress = 0x92265F4C85619eC8b70BB179ff1F86C56e54d348; // Discord team
    address haydenAddress = 0x9b7df2A8Fd78923BB5e3329aA7e024a613a92d5F; // Vech co-founder
    address fudzeroAddress = 0x9b80a7D7E4CD5CB47a8Bee52fe312dc9267ADaBF; // Vech co-founder
    address vechOperations = 0xafbfe9fA0348EEefD281fE317bDe861DC4F74910; // Vech operations
    address vechTreasury = 0xbD9a34eBc30ce0328B759038d41546A354C9bd74; // Vech treasury

    /// URI for a specific token
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("VECH", "VECH") {}

    // ### Minting ###

    /// Pre sale minting, for everyone who is on the OG list.
    /// note: First token is free
    function ogSaleMint(bytes32[] calldata proof, uint8 amount)
        public
        payable
        activeSale(ogSaleIsActive)
        ogListed(proof, amount)
        amountWithinMaxTokens(amount)
    {
        if (ogMints[msg.sender] > 0) {
            require(
                whitelistTokenPrice.mul(amount) <= msg.value,
                "Not enough ether to mint"
            );
        } else {
            // first token minted is free for OGs
            require(
                whitelistTokenPrice.mul(amount - 1) <= msg.value,
                "Not enough ether to mint"
            );
        }
        mint(amount);
        ogMints[msg.sender] += amount;
    }

    /// Pre sale minting, for everyone who is on the whitelist
    function preSaleMint(bytes32[] calldata proof, uint8 amount)
        public
        payable
        activeSale(preSaleIsActive)
        correctWhitelistPayment(amount)
        whitelisted(proof, amount)
        amountWithinMaxTokens(amount)
    {
        mint(amount);
        whitelistedMints[msg.sender] += amount;
    }

    /// Public minting, everyone can mint as long as publicSaleIsActive = true
    function publicMint(uint8 amount)
        public
        payable
        activeSale(publicSaleIsActive)
        correctPublicPayment(amount)
        amountWithinMaxTokens(amount)
    {
        mint(amount);
    }

    /// Reserved token minting
    function collabMint(uint8 amount, address to) public onlyOwner {
        require(
            mintedCollabTokenCount.add(amount) <= collabReservedTokens,
            "Can not mint more than reserved"
        );
        uint256 startId = maxPublicMintableTokens + mintedCollabTokenCount;
        for (uint8 i = 0; i < amount; i++) {
            _safeMint(to, startId + i);
        }
        mintedCollabTokenCount += amount;
    }

    /// Reserved token minting
    function reservedMint(uint8 amount, address to) public onlyOwner {
        require(
            mintedReservedTokenCount.add(amount) <= teamReservedTokens,
            "Can not mint more than reserved"
        );
        require(
            mintedPublicTokens.add(amount) <= maxPublicMintableTokens,
            "No tokens left to mint"
        );
        for (uint8 i = 0; i < amount; i++) {
            _safeMint(to, mintedPublicTokens + i);
        }
        mintedReservedTokenCount += amount;
        mintedPublicTokens += amount;
    }

    function mint(uint8 amount) private whenNotPaused {
        require(amount <= maxTokensPerTxn, "Too many mints in a txn");
        for (uint8 i = 0; i < amount; i++) {
            _safeMint(msg.sender, mintedPublicTokens + i);
        }
        mintedPublicTokens += amount;
    }

    // ### Administration ###

    /// pause contract
    function pause() public onlyOwner {
        _pause();
    }

    /// unpause contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /// set which sale(s) should be active or inactive
    function setOGPreAndPublicSale(
        bool _ogSaleIsActive,
        bool _preSaleIsActive,
        bool _publicSaleIsActive
    ) public onlyOwner {
        ogSaleIsActive = _ogSaleIsActive;
        preSaleIsActive = _preSaleIsActive;
        publicSaleIsActive = _publicSaleIsActive;
    }

    /// set minting price
    function setMintPrice(
        uint256 _whitelistTokenPrice,
        uint256 _publicTokenPrice
    ) public onlyOwner {
        whitelistTokenPrice = _whitelistTokenPrice;
        publicTokenPrice = _publicTokenPrice;
    }

    /// set amount of tokens allowed to mint in a transaction
    function setMaxMintsPerTxn(uint256 _tokensPerTxn) public onlyOwner {
        maxTokensPerTxn = _tokensPerTxn;
    }

    /// set the amount of tokens whitelisted or og-listed
    /// addresses are allowed to mint during pre-sale and og-sale
    /// note: does not affect public sale
    function setMaxMintsPerWhitelistedAddress(uint256 tokensPerAddress)
        public
        onlyOwner
    {
        preSaleTokensPerAddress = tokensPerAddress;
    }

    /// set merkle root for og-list verification
    function setOGMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        ogMerkleRoot = merkleRoot;
    }

    /// set merkle root for whitelist verification
    function setWhitelistMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    /// set a specific tokens URI
    /// note: make sure you use the tokenId and not the vechId
    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    /// set the baseURI for the collection
    function setUnrevealedBaseURI(string memory _URI) external onlyOwner {
        unrevealedBaseURI = _URI;
    }

    /// set the baseURI for the collection
    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    /// call to reveal tokens
    /// note: can be used twice
    /// note: the second time can only be called at complete sell out
    function revealTokens() public onlyOwner {
        require(reveals <= 1, "Can only reveal twice");
        require(
            reveals == 0 || mintedPublicTokens == maxPublicMintableTokens,
            "Needs all tokens sold before next reveal"
        );
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    block.number
                )
            )
        ) % maxPublicMintableTokens;

        partialReveals[reveals] = PartialReveal(
            seed,
            mintedPublicTokens.sub(revealedTokens)
        );

        reveals++;
        revealedTokens = mintedPublicTokens;
    }

    /// withdraws funds
    function withdraw() public onlyOwner {
        uint256 amountToVechOperations = (address(this).balance * 210) / 1000; // 21%
        uint256 amountToMintersCollection = (address(this).balance * 200) /
            1000; // 20%
        uint256 amountToMaxim = (address(this).balance * 120) / 1000; // 12%
        uint256 amountToHydn = (address(this).balance * 100) / 1000; // 10%
        uint256 amountToFudzero = (address(this).balance * 100) / 1000; // 10%
        uint256 amountToMoonfarm = (address(this).balance * 100) / 1000; // 10%
        uint256 amountToGillies = (address(this).balance * 25) / 1000; // 2.5%
        uint256 amountToRodney = (address(this).balance * 25) / 1000; // 2.5%
        uint256 amountToDiscordTeam = (address(this).balance * 20) / 1000; // 2%

        sendEth(mintersAddress, amountToMintersCollection);
        sendEth(maximAddress, amountToMaxim);
        sendEth(moonfarmAddress, amountToMoonfarm);
        sendEth(gilliesAddress, amountToGillies);
        sendEth(rodneyAddress, amountToRodney);

        // discord team split 2%
        sendEth(burnzAddress, amountToDiscordTeam / 3);
        sendEth(dvolutionAddress, amountToDiscordTeam / 3);
        sendEth(cuhryptoAddress, amountToDiscordTeam / 3);

        sendEth(fudzeroAddress, amountToFudzero);
        sendEth(haydenAddress, amountToHydn);
        sendEth(vechOperations, amountToVechOperations);

        // send the rest to treasury if there's a gwei left from rounding the percentages
        uint256 amountToVechTreasury = address(this).balance; // ~10%
        sendEth(vechTreasury, amountToVechTreasury);
    }

    function sendEth(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    // ###

    // ### Utils ###

    /// get the baseURI internally
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// get the tokenURI based on seeds generated in reveal
    /// note: returns unrevealedBaseURI if tokenId hasn't been revealed yet
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory base = _baseURI();

        // Collab tokens
        if (tokenId >= maxPublicMintableTokens) {
            return string(abi.encodePacked(base, uint2str(tokenId)));
        }

        if (tokenId >= revealedTokens) {
            return unrevealedBaseURI;
        }

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is a specific token URI, return the token URI.
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        uint256 vechId;

        // At only one reveal this is a trivial case
        if (reveals == 1 || tokenId < partialReveals[0].tokenCount) {
            // Calculate vech id from one rotation
            vechId = (partialReveals[0].seed + tokenId) % maxPublicMintableTokens;
            // Bundle id with base uri
            return string(abi.encodePacked(base, uint2str(vechId)));
        }

        uint256 firstSeed = partialReveals[0].seed;
        uint256 offset = tokenId.add(partialReveals[1].seed);
        vechId = offset;

        if (offset >= firstSeed) {
            offset -= firstSeed;
            offset %= partialReveals[1].tokenCount;
            vechId = offset.add(partialReveals[0].tokenCount);
            vechId += firstSeed;
        }

        return string(abi.encodePacked(base, uint2str(vechId % maxPublicMintableTokens)));
    }

    // returns: the amount of reserved tokens
    function reservedTokens() public view returns (uint256) {
        return teamReservedTokens;
    }

    // convert int to str
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /// verify that an address is in the whitelist
    function isAddressWhitelisted(bytes32[] memory proof, address _address)
        internal
        view
        returns (bool)
    {
        return isAddressInMerkleRoot(whitelistMerkleRoot, proof, _address);
    }

    /// verify that an address is in the og-list
    function isAddressOGListed(bytes32[] memory proof, address _address)
        internal
        view
        returns (bool)
    {
        return isAddressInMerkleRoot(ogMerkleRoot, proof, _address);
    }

    function isAddressInMerkleRoot(
        bytes32 merkleRoot,
        bytes32[] memory proof,
        address _address
    ) internal pure returns (bool) {
        return proof.verify(merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    // ###

    // ### Modifiers ###

    modifier activeSale(bool sale) {
        require(sale, "this sale is not active");
        _;
    }

    modifier correctWhitelistPayment(uint8 amount) {
        require(
            whitelistTokenPrice.mul(amount) <= msg.value,
            "Not enough ether to mint"
        );
        _;
    }

    modifier correctPublicPayment(uint8 amount) {
        require(
            publicTokenPrice.mul(amount) <= msg.value,
            "Not enough ether to mint"
        );
        _;
    }

    modifier whitelisted(bytes32[] calldata proof, uint8 amount) {
        require(
            isAddressWhitelisted(proof, msg.sender),
            "Address not whitelisted"
        );
        require(
            amount + whitelistedMints[msg.sender] <= preSaleTokensPerAddress,
            "Exceeded limit of pre-sale tokens"
        );
        _;
    }

    modifier ogListed(bytes32[] calldata proof, uint8 amount) {
        require(
            isAddressOGListed(proof, msg.sender),
            "Address not whitelisted"
        );
        require(
            amount + ogMints[msg.sender] <= preSaleTokensPerAddress,
            "Exceeded limit of og-sale tokens"
        );
        _;
    }

    modifier amountWithinMaxTokens(uint8 amount) {
        require(
            mintedPublicTokens.add(amount) <= maxPublicMintableTokens.sub(reservedTokens()),
            "Not enough tokens left to mint"
        );
        _;
    }

    // ###
}