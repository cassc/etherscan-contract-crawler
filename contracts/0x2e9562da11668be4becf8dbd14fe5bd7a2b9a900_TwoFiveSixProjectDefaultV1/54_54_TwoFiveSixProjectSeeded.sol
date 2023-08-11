// SPDX-License-Identifier: MIT

/* 

██████╗ ███████╗ ██████╗ 
╚════██╗██╔════╝██╔════╝ 
 █████╔╝███████╗███████╗ 
██╔═══╝ ╚════██║██╔═══██╗
███████╗███████║╚██████╔╝
╚══════╝╚══════╝ ╚═════╝ 

Using this contract? 
A shout out to @Mint256Art is appreciated!
 */
pragma solidity ^0.8.19;

import "./helpers/SSTORE2.sol";
import "./helpers/OwnableUpgradeable.sol";
import "./helpers/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract TwoFiveSixProjectSeededV1 is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;
    mapping(address => TotalAndCount) private addressToTotalAndCount;
    mapping(address => bool) private addressToClaimed;

    struct Project {
        string name; //unknown
        string imageBase; //unkown
        address[] artScripts; //unknown
        bytes32 merkleRoot; //32
        address artInfo; //20
        uint56 biddingStartTimeStamp; //8
        uint32 maxSupply; //4
        address payable artistAddress; //20
        uint56 allowListStartTimeStamp; //8
        uint32 totalAllowListMints; //4
        address payable twoFiveSix; //20
        uint24 artistAuctionWithdrawalsClaimed; //3
        uint24 artistAllowListWithdrawalsClaimed; //3
        uint24 twoFiveSixShare; //3
        uint24 royalty; //3
        address traits; //20
        uint96 reservePrice; //12
        address payable royaltyAddress; //20
        uint96 lastSalePrice; //12
        address libraryScripts; //20
        uint56 endingTimeStamp; //8
        uint24 thirdPartyShare; //3
        bool fixedPrice; //1
        address payable thirdPartyAddress; //20
    }
    struct Trait {
        string name;
        string[] values;
        string[] descriptions;
        uint256[] weights;
    }

    struct TotalAndCount {
        uint128 total;
        uint128 count;
    }
    struct LibraryScript {
        address fileStoreFrontEnd;
        address fileStore;
        string fileName;
    }
    Project private project;

    /**
     * @notice Initializes the project.
     * @dev Initializes the ERC721 contract.
     * @param _p The project data.
     */
    function initProject(
        Project calldata _p,
        address _traits,
        address _libraryScripts
    ) public initializer {
        __ERC721_init(_p.name, "256ART");
        __Ownable_init(_p.artistAddress);
        project = _p;
        if (_traits != address(0)) {
            project.traits = _traits;
        }
        if (_libraryScripts != address(0)) {
            project.libraryScripts = _libraryScripts;
        }
    }

    /**
     * @notice Gets the current price.
     */
    function currentPrice() public view returns (uint256 p) {
        require(
            block.timestamp > project.biddingStartTimeStamp,
            "Mint not started"
        );
        require(block.timestamp < project.endingTimeStamp, "Mint ended");
        uint256 timeElapsed = block.timestamp - project.biddingStartTimeStamp;
        uint256 price;
        if (timeElapsed < 3600 && !project.fixedPrice) {
            price =
                (((((project.reservePrice * 15 ** 8) / (10 ** 8)) /
                    (15 ** (timeElapsed / 450))) *
                    (10 ** (timeElapsed / 450))) / 10 ** 14) *
                10 ** 14;

            return price;
        } else {
            return project.reservePrice;
        }
    }

    /**
     * @notice Mint tokens to an address (artist only)
     * @dev Mints a given number of tokens to a specified address. Can only be called by the project owner.
     * @param seeds The seeds for which to mint.
     * @param a The address to which the tokens will be minted.
     */
    function artistMint(bytes32[] calldata seeds, address a) public onlyOwner {
        uint256 totalSupply = _owners.length;
        require(totalSupply + seeds.length < project.maxSupply, "Minted out");
        require(block.timestamp < project.endingTimeStamp, "Mint ended");
        require(seeds.length < 5, "Mint max four per tx");
        if (!project.fixedPrice) {
            require(
                ((block.timestamp > project.biddingStartTimeStamp + 3600) ||
                    (block.timestamp < project.biddingStartTimeStamp)),
                "No artist mint during auction"
            );
        }

        for (uint256 i; i < seeds.length; ) {
            require(hashToTokenId[seeds[i]] == 0, "Seed already used");
            require(tokenIdToHash[0] != seeds[i], "Seed already used");

            unchecked {
                uint256 tokenId = totalSupply + i;
                _mint(a, tokenId);
                tokenIdToHash[tokenId] = seeds[i];
                hashToTokenId[seeds[i]] = tokenId;
                i++;
            }
        }
        unchecked {
            project.artistAuctionWithdrawalsClaimed =
                project.artistAuctionWithdrawalsClaimed +
                uint24(seeds.length);
        }
    }

    /**
     * @notice Mint a token to an allow listed address if conditions met.
     * @dev Mints a token to a specified address if that address is on the project's allow list and has not already claimed a token.
     * @param proof The proof of inclusion in the project's Merkle tree.
     * @param a The address to which the token will be minted.
     * @param seed The seeds for the mint.
     */
    function allowListMint(
        bytes32[] memory proof,
        address a,
        bytes32 seed
    ) public payable {
        require(
            block.timestamp > project.allowListStartTimeStamp,
            "Allow list mint not started"
        );
        require(
            block.timestamp < project.biddingStartTimeStamp,
            "Allow list mint ended"
        );
        require(
            MerkleProofUpgradeable.verify(
                proof,
                project.merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on allow list"
        );
        require(addressToClaimed[msg.sender] == false, "Already claimed");

        uint256 totalSupply = _owners.length;

        require(totalSupply + 1 < project.maxSupply, "Minted out");
        require(project.reservePrice <= msg.value, "Invalid funds provided");
        require(msg.sender == tx.origin, "No contract minting");

        require(hashToTokenId[seed] == 0, "Seed already used");
        require(tokenIdToHash[0] != seed, "Seed already used");

        unchecked {
            uint256 tokenId = totalSupply;
            addressToClaimed[msg.sender] = true;
            project.totalAllowListMints = project.totalAllowListMints + 1;
            _mint(a, tokenId);
            tokenIdToHash[tokenId] = seed;
            hashToTokenId[seed] = tokenId;
        }
    }

    /**
     * @notice Mint tokens to an address through a Dutch auction until reserve price is met, while checking for various conditions.
     * @dev Mints a given number of tokens to a specified address through a Dutch auction process that ends when the reserve price is met. Also checks various conditions such as max supply, minimum and maximum number of tokens that can be minted per transaction, and that the sender is not a contract.
     * @param seeds The seeds for which to mint.
     * @param a The address to which the tokens will be minted.
     */
    function mint(bytes32[] calldata seeds, address a) public payable {
        uint256 totalSupply = _owners.length;
        uint256 price = currentPrice();
        uint256 total = seeds.length * price;
        require(
            block.timestamp > project.biddingStartTimeStamp,
            "Mint not started"
        );
        require(totalSupply + seeds.length < project.maxSupply, "Minted out");
        require(seeds.length > 0, "Mint at least one");
        require(seeds.length < 5, "Mint max four per tx");
        require(total <= msg.value, "Invalid funds provided");
        require(msg.sender == tx.origin, "No contract minting");

        if (price != project.reservePrice) {
            addressToTotalAndCount[a] = TotalAndCount(
                uint128(addressToTotalAndCount[a].total + msg.value),
                addressToTotalAndCount[a].count + uint128(seeds.length)
            );
        }
        if (
            totalSupply + seeds.length == project.maxSupply - 1 &&
            !project.fixedPrice
        ) {
            project.lastSalePrice = uint96(price);
        }

        for (uint256 i; i < seeds.length; ) {
            require(hashToTokenId[seeds[i]] == 0, "Seed already used");
            require(tokenIdToHash[0] != seeds[i], "Seed already used");
            unchecked {
                uint256 tokenId = totalSupply + i;

                _mint(a, tokenId);
                tokenIdToHash[tokenId] = seeds[i];
                hashToTokenId[seeds[i]] = tokenId;
                i++;
            }
        }
    }

    /**
     * @notice Claim a rebate for each token minted at a higher price than the final price
     * @param a The address to which the rebate is paid.
     */
    function claimRebate(address payable a) public {
        require(
            block.timestamp > project.biddingStartTimeStamp + 3600,
            "Rebate phase has not started"
        );
        uint256 finalPrice;

        if (
            _owners.length < (project.maxSupply - 1) ||
            project.lastSalePrice == 0
        ) {
            finalPrice = project.reservePrice;
        } else {
            finalPrice = project.lastSalePrice;
        }

        uint256 rebate = addressToTotalAndCount[msg.sender].total -
            (addressToTotalAndCount[msg.sender].count * finalPrice);

        delete addressToTotalAndCount[msg.sender];
        a.transfer(rebate);
    }

    /**
     * @notice Get the hash associated with a given tokenId.
     * @param _id The ID of the token.
     * @return The hash associated with the given tokenId.
     */
    function getHashFromTokenId(uint256 _id) public view returns (bytes32) {
        return tokenIdToHash[_id];
    }

    /**
     * @notice Withdraw funds from the contract
     * @dev Transfers a percentage of the balance to the 256ART address and optionally a third party, the rest to the artist address.
     */
    function withdraw() public {
        require(
            (msg.sender == project.twoFiveSix ||
                msg.sender == project.artistAddress ||
                msg.sender == project.thirdPartyAddress),
            "Not allowed"
        );

        uint256 totalSupply = _owners.length;

        uint256 finalPrice;
        uint256 balance;

        if (project.fixedPrice) {
            balance = address(this).balance;
        } else {
            require(
                block.timestamp > project.biddingStartTimeStamp + 3600,
                "Auction still in progress"
            );
            if (
                _owners.length < (project.maxSupply - 1) ||
                project.lastSalePrice == 0
            ) {
                finalPrice = project.reservePrice;
            } else {
                finalPrice = project.lastSalePrice;
            }
            balance =
                ((totalSupply -
                    project.totalAllowListMints -
                    project.artistAuctionWithdrawalsClaimed) * finalPrice) +
                ((project.totalAllowListMints -
                    project.artistAllowListWithdrawalsClaimed) *
                    project.reservePrice);
        }

        require(balance > 0, "Balance is zero");

        project.artistAuctionWithdrawalsClaimed = uint24(
            totalSupply - project.totalAllowListMints
        );
        project.artistAllowListWithdrawalsClaimed = uint24(
            project.totalAllowListMints
        );

        if (project.thirdPartyAddress == address(0)) {
            uint256 twoFiveSixBalance = (balance * project.twoFiveSixShare) /
                10000;
            uint256 artistBalance = balance - twoFiveSixBalance;

            project.twoFiveSix.transfer(twoFiveSixBalance);
            project.artistAddress.transfer(artistBalance);
        } else {
            uint256 twoFiveSixBalance = (balance * project.twoFiveSixShare) /
                10000;
            uint256 thirdPartyBalance = (balance * project.thirdPartyShare) /
                10000;
            uint256 artistBalance = balance -
                twoFiveSixBalance -
                thirdPartyBalance;

            project.twoFiveSix.transfer(twoFiveSixBalance);
            project.thirdPartyAddress.transfer(thirdPartyBalance);
            project.artistAddress.transfer(artistBalance);
        }
    }

    function walletOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public {
        for (uint256 i; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(
        address account,
        uint256[] calldata _tokenIds
    ) external view returns (bool) {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }

        return true;
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @notice Calculates the royalty information for a given sale.
     * @dev Implements the required royaltyInfo function for the ERC2981 standard.
     * @param _salePrice The sale price of the token being sold.
     * @return receiver The address of the royalty recipient.
     * @return royaltyAmount The amount of royalty to be paid.
     */
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        return (project.royaltyAddress, (_salePrice * project.royalty) / 10000);
    }

    /**
     * @notice Converts a bytes16 value to its hexadecimal representation as a bytes32 value.
     * @param data The bytes16 value to convert.
     * @return result The hexadecimal representation of the input value as a bytes32 value.
     */
    function toHex16(bytes16 data) internal pure returns (bytes32 result) {
        result =
            (bytes32(data) &
                0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000) |
            ((bytes32(data) &
                0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >>
                64);
        result =
            (result &
                0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000) |
            ((result &
                0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >>
                32);
        result =
            (result &
                0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000) |
            ((result &
                0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >>
                16);
        result =
            (result &
                0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000) |
            ((result &
                0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >>
                8);
        result =
            ((result &
                0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >>
                4) |
            ((result &
                0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >>
                8);
        result = bytes32(
            0x3030303030303030303030303030303030303030303030303030303030303030 +
                uint256(result) +
                (((uint256(result) +
                    0x0606060606060606060606060606060606060606060606060606060606060606) >>
                    4) &
                    0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) *
                7
        );
    }

    /**
     * @dev Converts a bytes32 value to its hexadecimal representation as a string.
     * @param data The bytes32 value to convert.
     * @return The hexadecimal representation of the bytes32 value, as a string.
     */
    function toHex(bytes32 data) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "0x",
                    toHex16(bytes16(data)),
                    toHex16(bytes16(data << 128))
                )
            );
    }

    /**
     * @dev Generates an array of random numbers based on a seed value.
     * @param seed The seed value used to generate the random numbers.
     * @param timesToCall The number of random numbers to generate.
     * @return An array of random numbers with length equal to `timesToCall`.
     */
    function generateRandomNumbers(
        bytes32 seed,
        uint256 timesToCall
    ) private pure returns (uint256[] memory) {
        uint256[] memory randNumbers = new uint256[](timesToCall);

        for (uint256 i; i < timesToCall; i++) {
            uint256 r = uint256(
                keccak256(abi.encodePacked(uint256(seed) + i))
            ) % 10000;
            randNumbers[i] = r;
        }

        return randNumbers;
    }

    /**
     * @notice Returns a string containing base64 encoded HTML code which renders the artwork associated with the given tokenId directly from chain.
     * @dev This function reads traits and libraries from the storage and uses them to generate the HTML code for the artwork.
     * @param tokenId The ID of the token whose artwork will be generated.
     * @return artwork A string containing the base64 encoded HTML code for the artwork.
     */
    function getTokenHtml(
        uint256 tokenId
    ) public view returns (string memory artwork) {
        require(_exists(tokenId), "Token not found");

        bytes32 tokenHash = getHashFromTokenId(tokenId);

        string memory artScript;
        string memory libraryScripts;
        string memory traits;
        string memory blockParams;

        if (project.libraryScripts != address(0)) {
            LibraryScript[] memory librariesArray = abi.decode(
                SSTORE2.read(project.libraryScripts),
                (LibraryScript[])
            );
            for (uint256 l; l < librariesArray.length; l++) {
                IFileStorage fileStoreFrontEnd = IFileStorage(
                    librariesArray[l].fileStoreFrontEnd
                );
                libraryScripts = string.concat(
                    "await ls256('",
                    fileStoreFrontEnd.readFile(
                        librariesArray[l].fileStore,
                        librariesArray[l].fileName
                    ),
                    "');"
                );
            }
        }

        if (project.traits != address(0)) {
            traits = ",";
            Trait[] memory traitsArray = abi.decode(
                SSTORE2.read(project.traits),
                (Trait[])
            );

            uint256[] memory randNumbers = generateRandomNumbers(
                tokenHash,
                traitsArray.length
            );

            for (uint256 j = 0; j < traitsArray.length; j++) {
                uint256 r = randNumbers[j];
                for (uint256 k = 0; k < traitsArray[j].weights.length; k++) {
                    if (r < traitsArray[j].weights[k]) {
                        traits = string.concat(
                            traits,
                            "'",
                            traitsArray[j].name,
                            "'",
                            ":'",
                            traitsArray[j].values[k],
                            "'"
                        );
                        if (j < traitsArray.length - 1) {
                            traits = string.concat(traits, ",");
                        }
                        break;
                    }
                }
            }
        }

        blockParams = string.concat(
            ", 'ownerOfPiece' : '",
            StringsUpgradeable.toHexString(
                uint256(uint160(ownerOf(tokenId))),
                20
            ),
            "', 'blockHash' : '",
            toHex(blockhash(block.number - 1)),
            "', 'blockNumber' : ",
            StringsUpgradeable.toString(block.number),
            ", 'prevrandao' : ",
            StringsUpgradeable.toString(block.prevrandao),
            ", 'totalSupply' : ",
            StringsUpgradeable.toString(_owners.length),
            ", 'balanceOfOwner' : ",
            StringsUpgradeable.toString(balanceOf(ownerOf(tokenId)))
        );

        for (uint256 i; i < project.artScripts.length; i++) {
            IArtScript artscriptToGet = IArtScript(project.artScripts[i]);
            artScript = string.concat(artScript, artscriptToGet.artScript());
        }

        return
            string.concat(
                "data:text/html;base64,",
                Base64Upgradeable.encode(
                    abi.encodePacked(
                        "<html><head><script>let inputData={'tokenId': ",
                        StringsUpgradeable.toString(tokenId),
                        ",'hash': '",
                        toHex(tokenHash),
                        "'",
                        traits,
                        blockParams,
                        "};",
                        "</script>",
                        "<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1'><style type='text/css'>html{height:100%;width:100%;}body{height:100%;width:100%;margin:0;padding:0;background-color:#000000;}canvas{display:block;max-width:100%;max-height:100%;padding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0;object-fit:contain;}</style>",
                        "</head><body><script defer>async function ls256(e){let t=new TextDecoder,a=window.atob(e),n=a.length,r=new Uint8Array(n);for(var o=0;o<n;o++)r[o]=a.charCodeAt(o);let d=r.buffer;let c=new ReadableStream({start(e){e.enqueue(d),e.close()}}).pipeThrough(new DecompressionStream('gzip')),i=await new Response(c),p=await i.arrayBuffer(),l=await t.decode(p),s=document.createElement('script');s.type='text/javascript',s.appendChild(document.createTextNode(l)),document.body.appendChild(s)};async function la256(){",
                        libraryScripts,
                        "await ls256('",
                        artScript,
                        "');"
                        "};la256();</script></body></html>"
                    )
                )
            );
    }

    /**
     * @notice Returns the metadata of the token with the given ID, including name, artist, description, license, image and animation URL, and attributes.
     * @dev It returns a base64 encoded JSON object which conforms to the ERC721 metadata standard.
     * @param _tokenId The ID of the token to retrieve metadata for.
     * @return A base64 encoded JSON object that contains the metadata of the given token.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_exists(_tokenId), "Token not found");

        bytes32 tokenHash = getHashFromTokenId(_tokenId);

        IArtInfo artInfoToGet = IArtInfo(project.artInfo);

        string memory imageBase;
        string memory librariesUsed = ',"libraries_used": "';
        string memory attributes;

        if (bytes(project.imageBase).length != 0) {
            imageBase = string.concat(
                ',"image":"',
                project.imageBase,
                StringsUpgradeable.toString(_tokenId),
                '"'
            );
        }

        if (project.libraryScripts != address(0)) {
            LibraryScript[] memory librariesArray = abi.decode(
                SSTORE2.read(project.libraryScripts),
                (LibraryScript[])
            );
            for (uint256 l; l < librariesArray.length; l++) {
                librariesUsed = string.concat(
                    librariesUsed,
                    librariesArray[l].fileName,
                    " "
                );
            }
        } else {
            librariesUsed = string.concat(librariesUsed, "None");
        }

        if (project.traits != address(0)) {
            Trait[] memory traitsArray = abi.decode(
                SSTORE2.read(project.traits),
                (Trait[])
            );
            uint256[] memory randNumbers = generateRandomNumbers(
                getHashFromTokenId(_tokenId),
                traitsArray.length
            );
            for (uint256 j = 0; j < traitsArray.length; j++) {
                uint256 r = randNumbers[j];
                for (uint256 k = 0; k < traitsArray[j].weights.length; k++) {
                    if (r < traitsArray[j].weights[k]) {
                        attributes = string.concat(
                            attributes,
                            '{"trait_type":"',
                            traitsArray[j].name,
                            '", "value":"',
                            traitsArray[j].descriptions[k],
                            '"}'
                        );
                        if (j < traitsArray.length - 1) {
                            attributes = string.concat(attributes, ",");
                        }
                        break;
                    }
                }
            }
        }

        return
            string.concat(
                "data:application/json;base64,",
                Base64Upgradeable.encode(
                    abi.encodePacked(
                        '{"name":"',
                        project.name,
                        " #",
                        StringsUpgradeable.toString(_tokenId),
                        '", "artist":"',
                        artInfoToGet.artist(),
                        '","description":"',
                        artInfoToGet.description(),
                        '","license":"',
                        artInfoToGet.license(),
                        '","hash":"',
                        toHex(tokenHash),
                        '"',
                        librariesUsed,
                        '"',
                        imageBase,
                        ',"animation_url":"',
                        getTokenHtml(_tokenId),
                        '","attributes":[',
                        attributes,
                        "]}"
                    )
                )
            );
    }

    /**
     * @notice Allows to set the image base URL for the project (owner)
     * @dev Only callable by the owner
     * @param _imageBase String representing the base URL for images
     */
    function setImageBase(string calldata _imageBase) public onlyOwner {
        project.imageBase = _imageBase;
    }

    /**
     * @notice Sets the maximum number of tokens that can be minted for the project (owner)
     * @dev Only the owner of the contract can call this function.
     * @dev The new maximum supply must be greater than the current number of tokens minted
     * and less than the current maximum supply
     * @param _maxSupply The new maximum number of tokens that can be minted
     */
    function setMaxSupply(uint24 _maxSupply) public onlyOwner {
        require(_maxSupply > _owners.length, "Too low");
        require(_maxSupply < project.maxSupply, "Too high");
        project.maxSupply = _maxSupply;
    }

    /**
     * @notice Allows to set the art scripts for the project
     * @param _artScripts Array of addresses representing the art scripts
     */
    function setArtScripts(address[] calldata _artScripts) public onlyOwner {
        project.artScripts = _artScripts;
    }

    /**
     * @notice Allows to set the library scripts for the project
     * @param _libraries Array of LibraryScript objects representing the library scripts
     */
    function setLibraryScripts(
        LibraryScript[] calldata _libraries
    ) public onlyOwner {
        project.libraryScripts = SSTORE2.write(abi.encode(_libraries));
    }

    /**
     * @notice Returns the reserve price for the project
     * @dev This function is view only
     * @return uint256 Representing the reserve price for the project
     */
    function getReservePrice() external view returns (uint256) {
        return project.reservePrice;
    }

    /**
     * @notice Returns the address of the ArtInfo contract used in the project
     * @dev This function is view only
     * @return address Representing the address of the ArtInfo contract
     */
    function getArtInfo() external view returns (address) {
        return project.artInfo;
    }

    /**
     * @notice Returns an array with the addresses storing the art script used in the project
     * @dev This function is view only
     * @return address[] Array of addresses storing the art script used in the project
     */
    function getArtScripts() external view returns (address[] memory) {
        return project.artScripts;
    }

    /**
     * @notice Returns the maximum number of tokens that can be minted for the project
     * @dev This function is view only
     * @return uint256 Representing the maximum number of tokens that can be minted
     */
    function getMaxSupply() external view returns (uint256) {
        return project.maxSupply - 1;
    }

    /**
     * @notice Returns the timestamp of the bidding start for the project
     * @dev This function is view only
     * @return uint256 Representing the timestamp of the bidding start
     */
    function getBiddingStartTimeStamp() external view returns (uint256) {
        return project.biddingStartTimeStamp;
    }

    /**
     * @notice Returns the timestamp of the allowlist start for the project
     * @dev This function is view only
     * @return uint256 Representing the timestamp of the allowlist start
     */
    function getallowListStartTimeStamp() external view returns (uint256) {
        return project.allowListStartTimeStamp;
    }
}

interface IArtScript {
    function artScript() external pure returns (string memory);
}

interface IArtInfo {
    function artist() external pure returns (string memory);

    function description() external pure returns (string memory);

    function license() external pure returns (string memory);
}

interface IFileStorage {
    function readFile(
        address fileStore,
        string calldata filename
    ) external pure returns (string memory);
}