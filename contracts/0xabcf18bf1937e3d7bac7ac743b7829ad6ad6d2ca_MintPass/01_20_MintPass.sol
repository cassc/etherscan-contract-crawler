// SPDX-License-Identifier: MIT

/* 

_____/\\\\\\\\\_____/\\\\\_____/\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\___        
 ___/\\\///////\\\__\/\\\\\\___\/\\\___/\\\\\\\\\\\\\__\/\\\/////////\\\_       
  __\/\\\_____\/\\\__\/\\\/\\\__\/\\\__/\\\/////////\\\_\/\\\_______\/\\\_      
   __\///\\\\\\\\\/___\/\\\//\\\_\/\\\_\/\\\_______\/\\\_\/\\\\\\\\\\\\\/__     
    ___/\\\///////\\\__\/\\\\//\\\\/\\\_\/\\\\\\\\\\\\\\\_\/\\\/////////____    
     __/\\\______\//\\\_\/\\\_\//\\\/\\\_\/\\\/////////\\\_\/\\\_____________   
      _\//\\\______/\\\__\/\\\__\//\\\\\\_\/\\\_______\/\\\_\/\\\_____________  
       __\///\\\\\\\\\/___\/\\\___\//\\\\\_\/\\\_______\/\\\_\/\\\_____________ 
        ____\/////////_____\///_____\/////__\///________\///__\///______________

Smartcontract developed by 256ART.

 */
pragma solidity ^0.8.19;

import "./helpers/SSTORE2.sol";
import "./helpers/OwnableUpgradeable.sol";
import "./helpers/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract MintPass is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(address => bool) private addressToClaimed;

    struct Project {
        string name; //unknown
        string imageBase; //unkown
        address[] artScripts; //unknown
        bytes32 merkleRoot; //32
        address artInfo; //20
        uint56 biddingStartTimeStamp; //8
        uint32 maxSupply; //4
        address payable ownerAddress; //20
        uint56 allowListStartTimeStamp; //8
        uint24 royalty; //3
        uint96 reservePrice; //12
        address payable royaltyAddress; //20
        uint56 burnCounter; //8
    }

    struct TotalAndCount {
        uint128 total;
        uint128 count;
    }

    Project private project;

    /**
     * @notice Initializes the project.
     * @dev Initializes the ERC721 contract.
     * @param _p The project data.
     */
    function initProject(Project calldata _p) public initializer {
        __ERC721_init(_p.name, "256ART");
        __Ownable_init(_p.ownerAddress);
        project = _p;
    }

    /**
     * @notice Gets the current price.
     */
    function currentPrice() public view returns (uint256) {
        require(
            block.timestamp > project.biddingStartTimeStamp,
            "Mint not started"
        );

        uint256 timeElapsed = block.timestamp - project.biddingStartTimeStamp;

        uint256 startPrice = project.reservePrice * 5; // 5 ETH in wei
        uint256 timeInterval = 15 * 60; // 15 minutes in seconds

        if (timeElapsed < 4 * timeInterval) {
            uint256 elapsedIntervals = timeElapsed / timeInterval;
            uint256 price = startPrice - (elapsedIntervals * 10 ** 18);
            return price;
        } else {
            return project.reservePrice;
        }
    }

    /**
     * @notice Mint tokens to an address (owner only)
     * @dev Mints a given number of tokens to a specified address. Can only be called by the project owner.
     * @param count The number of tokens to be minted.
     * @param a The address to which the tokens will be minted.
     */
    function ownerMint(uint24 count, address a) public onlyOwner {
        uint256 totalMinted = _owners.length;
        require(totalMinted + count < project.maxSupply, "Minted out");
        require(count < 5, "Mint max four per tx");

        for (uint256 i; i < count; ) {
            unchecked {
                uint256 tokenId = totalMinted + i;
                tokenIdToHash[tokenId] = createHash(
                    tokenId,
                    project.ownerAddress
                );
                _mint(a, tokenId);
                i++;
            }
        }
    }

    /**
     * @notice Mint a token to an allow listed address if conditions met.
     * @dev Mints a token to a specified address if that address is on the project's allow list and has not already claimed a token.
     * @param proof The proof of inclusion in the project's Merkle tree.
     * @param a The address to which the token will be minted.
     */
    function allowListMint(bytes32[] memory proof, address a) public payable {
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
                keccak256(abi.encodePacked(a))
            ),
            "Not on allow list"
        );
        require(addressToClaimed[a] == false, "Already claimed");

        uint256 totalMinted = _owners.length;

        require(totalMinted + 1 < project.maxSupply, "Minted out");
        require(project.reservePrice <= msg.value, "Invalid funds provided");
        require(msg.sender == tx.origin, "No contract minting");

        unchecked {
            uint256 tokenId = totalMinted;
            addressToClaimed[a] = true;
            tokenIdToHash[tokenId] = createHash(tokenId, msg.sender);
            _mint(a, tokenId);
        }
    }

    /**
     * @notice Check whether a given address is on the allowlist and whether it has already claimed a token.
     * @dev Returns two boolean values. The first indicates whether the address is on the allowlist, and the second indicates whether the address has already claimed a token.
     * @param a The address to check.
     * @param proof The proof of inclusion in the project's Merkle tree for the given address.
     * @return isOnList Whether the address is on the allowlist.
     * @return hasClaimed Whether the address has already claimed a token.
     */
    function checkAllowListAndClaimStatus(
        address a,
        bytes32[] memory proof
    ) public view returns (bool, bool) {
        bool isOnList = MerkleProofUpgradeable.verify(
            proof,
            project.merkleRoot,
            keccak256(abi.encodePacked(a))
        );
        bool hasClaimed = addressToClaimed[a];
        return (isOnList, hasClaimed);
    }

    /**
     * @notice Mint tokens to an address through a Dutch auction until reserve price is met, while checking for various conditions.
     * @dev Mints a given number of tokens to a specified address through a Dutch auction process that ends when the reserve price is met. Also checks various conditions such as max supply, minimum and maximum number of tokens that can be minted per transaction, and that the sender is not a contract.
     * @param count The number of tokens to be minted.
     * @param a The address to which the tokens will be minted.
     */
    function mint(uint128 count, address a) public payable {
        require(count > 0, "Mint at least one");
        require(count < 5, "Mint max four per tx");

        uint256 totalMinted = _owners.length;

        require(totalMinted + count < project.maxSupply, "Minted out");

        uint256 price = currentPrice();
        uint256 total = count * price;

        require(total <= msg.value, "Invalid funds provided");
        require(msg.sender == tx.origin, "No contract minting");

        for (uint256 i; i < count; ) {
            unchecked {
                uint256 tokenId = totalMinted + i;

                tokenIdToHash[tokenId] = createHash(tokenId, msg.sender);

                _mint(a, tokenId);
                i++;
            }
        }
    }

    /**
     * @notice Create a hash for the given tokenId, blockNumber and sender.
     * @param tokenId The ID of the token.
     * @param sender The address of the receiver.
     * @return The resulting hash.
     */
    function createHash(
        uint256 tokenId,
        address sender
    ) private view returns (bytes32) {
        unchecked {
            return
                keccak256(
                    abi.encodePacked(
                        tokenId,
                        sender,
                        blockhash(block.number - 1),
                        blockhash(block.number - 2),
                        blockhash(block.number - 4),
                        block.prevrandao,
                        block.coinbase
                    )
                );
        }
    }

    /**
     * @notice Get the hash associated with a given tokenId.
     * @param _id The ID of the token.
     * @return The hash associated with the given tokenId.
     */
    function tokenHash(uint256 _id) public view returns (bytes32) {
        return tokenIdToHash[_id];
    }

    /**
     * @notice Withdraw funds from the contract
     * @dev Transfers a percentage of the balance to the 256ART address and optionally a third party, the rest to the owner address.
     */
    function withdraw() public {
        require(msg.sender == project.ownerAddress, "Not allowed");

        uint256 balance = address(this).balance;

        require(balance > 0, "Balance is zero");

        project.ownerAddress.transfer(balance);
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
     * @dev This function generates the HTML code for the artwork.
     * @param tokenId The ID of the token whose artwork will be generated.
     * @return artwork A string containing the base64 encoded HTML code for the artwork.
     */
    function tokenHTML(
        uint256 tokenId
    ) public view returns (string memory artwork) {
        require(_exists(tokenId), "Token not found");

        string memory artScript;
        string memory blockParams;

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
            StringsUpgradeable.toString(totalSupply()),
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
                        toHex(tokenHash(tokenId)),
                        "'",
                        blockParams,
                        "};",
                        "</script>",
                        "<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1'><style type='text/css'>html{height:100%;width:100%;}body{height:100%;width:100%;margin:0;padding:0;background-color:#000000;}canvas{display:block;max-width:100%;max-height:100%;padding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0;object-fit:contain;}</style>",
                        "</head><body><script defer>async function ls256(e){let t=new TextDecoder,a=window.atob(e),n=a.length,r=new Uint8Array(n);for(var o=0;o<n;o++)r[o]=a.charCodeAt(o);let d=r.buffer;let c=new ReadableStream({start(e){e.enqueue(d),e.close()}}).pipeThrough(new DecompressionStream('gzip')),i=await new Response(c),p=await i.arrayBuffer(),l=await t.decode(p),s=document.createElement('script');s.type='text/javascript',s.appendChild(document.createTextNode(l)),document.body.appendChild(s)};async function la256(){",
                        "await ls256('",
                        artScript,
                        "');"
                        "};la256();</script></body></html>"
                    )
                )
            );
    }

    /**
     * @notice Returns the metadata of the token with the given ID, including name, owner, description, license, image and animation URL, and attributes.
     * @dev It returns a base64 encoded JSON object which conforms to the ERC721 metadata standard.
     * @param _tokenId The ID of the token to retrieve metadata for.
     * @return A base64 encoded JSON object that contains the metadata of the given token.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_exists(_tokenId), "Token not found");

        IArtInfo artInfoToGet = IArtInfo(project.artInfo);

        string memory imageBase;
        string memory librariesUsed = ',"libraries_used": "None';
        string memory attributes;

        if (bytes(project.imageBase).length != 0) {
            imageBase = string.concat(
                ',"image":"',
                project.imageBase,
                StringsUpgradeable.toString(_tokenId),
                '"'
            );
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
                        toHex(tokenHash(_tokenId)),
                        '"',
                        librariesUsed,
                        '"',
                        imageBase,
                        ',"animation_url":"',
                        tokenHTML(_tokenId),
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
        project.maxSupply = _maxSupply + 1; // We always set maxSupply one higher for gas savings during mint
    }

    /**
     * @notice Allows to set the art scripts for the project
     * @param _artScripts Array of addresses representing the art scripts
     */
    function setArtScripts(address[] calldata _artScripts) public onlyOwner {
        project.artScripts = _artScripts;
    }

    /**
     * @notice Allows to set the merkle root for the project (owner)
     * @dev Only callable by the owner
     * @param _merkleRoot Bytes32 value to set as the merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        project.merkleRoot = _merkleRoot;
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

    /**
     * @notice Allows an address to destroy a token.
     * @dev The caller must own `tokenId`.
     * @param tokenId the ID of the token to burn
     */
    function burnToken(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );

        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        project.burnCounter++;
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply() - project.burnCounter;
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