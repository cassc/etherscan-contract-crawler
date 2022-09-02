// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./libs/ERC721A/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @notice JRNYMetaverseBox NFT Contract
contract JRNYMetaverseBox is ERC721AQueryable, Ownable {
    ///@notice Max Supply
    uint256 public constant TOTAL_SUPPLY = 10000;

    ///@notice Token Base Uri
    string public baseTokenURI;

    ///@notice Is baseUri locked
    bool public baseUriLocked;

    ///@notice Is Mint Active
    bool public isMintActive;

    struct WLContract {
        address contractAddress;
        uint256 price;
        uint256 start;
        uint256 end;
        bool isWhitelisted;
    }

    ///@dev Whitelisted contract's data
    mapping(uint256 => WLContract) public whitelist;

    ///@dev Mapping to contract address to whitelist index
    mapping(address => uint256) internal contractToIndex;

    ///@dev Current whitelist index (starts from 1) 
    uint256 public indexNum;

    ///@notice Is NFT's `contractAddress` Whitelisted For Mint
    ///@param contractAddress to check
    ///@return True if contract whitelisted
    function isContractWhitelisted(address contractAddress)
        external
        view
        returns (bool)
    {
        return whitelist[contractToIndex[contractAddress]].isWhitelisted;
    }

    ///@notice Mint price in eth(wei) for nft contract address
    ///@dev Can be zero
    function mintPriceForContract(address contractAddress)
        external
        view
        returns (uint256)
    {
        return whitelist[contractToIndex[contractAddress]].price;
    }

    ///@notice Is token already used for mint
    mapping(address => mapping(uint256 => bool)) public isTokenUsed;

    ///@notice Return array of used for mint tokens in the range [`startId`,`endId`] for `contractAddress`
    ///@param contractAddress NFT Contact Address
    ///@param startId Range Start Id
    ///@param startId Range End Id
    ///@return Array of used tokens
    function usedTokensIn(
        address contractAddress,
        uint256 startId,
        uint256 endId
    ) external view returns (uint256[] memory) {
        require(startId < endId, "JRNYMetaverseBox: Sort error");
        uint256 len;
        for (uint256 i = startId; i <= endId; i++) {
            if (isTokenUsed[contractAddress][i]) {
                len++;
            }
        }
        uint256[] memory tmpArr = new uint256[](len);
        uint256 ind = 0;
        for (uint256 i = startId; i <= endId; i++) {
            if (isTokenUsed[contractAddress][i]) {
                tmpArr[ind] = i;
                ind++;
            }
        }
        return tmpArr;
    }

    ///@dev Retusn whitelist array
    function getWhitelist() external view returns (WLContract[] memory) {
        uint256 len = indexNum;
        if (len <= 1) {
            WLContract[] memory emptyArr = new WLContract[](1);
            return emptyArr;
        }
        WLContract[] memory tmpArr = new WLContract[](len - 1);
        for (uint256 i = 1; i < len; i++) {
            tmpArr[i - 1] = whitelist[i];
        }
        return tmpArr;
    }

    constructor(address newOwner) ERC721A("JRNY Metaverse Box", "JMB") {
        baseTokenURI = "https://metaversebox.jrny.club/nft/api/metadata/";
        transferOwnership(newOwner);
        indexNum = 1;
    }

    ///@dev Changes token name and symbol
    function editTokenNameAndTicker(
        string memory _tokenName,
        string memory _ticker
    ) external onlyOwner {
        editTokenNameAndSymbol(_tokenName, _ticker);
    }

    ///@dev Returns base uri
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    ///@notice Mints tokens for whitelisted `nftContact` and not-used `tokenIds`
    /**
     * @dev
     * Requirements:
     * - Executor need to be a owner of `nftContract`'s `tokenIds`
     * - `nftContract` must be whitelisted
     * - `tokenIds` of `nftContract` must be unused for mint before
     * - ETH value must be greater or equals to mint price for `nftContract`
     */
    ///@param nftContract NFT Contract address
    ///@param tokenIds Owned token ids
    function mint(IERC721 nftContract, uint256[] memory tokenIds)
        public
        payable
    {
        require(isMintActive, "JRNYMetaverseBox: Minting Inactive");

        uint256 tokenId = _nextTokenId();

        uint256 len = tokenIds.length;

        require(
            tokenId + len - 1 < TOTAL_SUPPLY,
            "JRNYMetaverseBox: Max supply reached"
        );

        WLContract memory wl = whitelist[contractToIndex[address(nftContract)]];
        require(
            wl.isWhitelisted,
            "JRNYMetaverseBox: Contract is not whitelisted"
        );
        require(
            block.timestamp >= wl.start,
            "JRNYMetaverseBox: Not started yet"
        );
        require(block.timestamp <= wl.end, "JRNYMetaverseBox: Ended");

        uint256 price = len * wl.price;
        require(msg.value >= price, "JRNYMetaverseBox: Not enough ETH");

        for (uint256 i = 0; i < len; i++) {
            uint256 idForCheck = tokenIds[i];
            require(
                nftContract.ownerOf(idForCheck) == msg.sender,
                "JRNYMetaverseBox: Ownership mismatch"
            );
            require(
                !isTokenUsed[address(nftContract)][idForCheck],
                "JRNYMetaverseBox: Token already used"
            );
            isTokenUsed[address(nftContract)][tokenIds[i]] = true;
        }

        _mint(msg.sender, len);

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    ///@notice Edits whitelist `statuses` for `contractAddreses` sets `prices` for as mint price
    ///@param contractAddreses Contract Address
    ///@param statuses New statuses for contracts (true - enabled, false - disabled)
    ///@param prices Mint ETH Prices (in wei) for contracts (0 - free mint)
    ///@dev Can be executed only by contract owner
    function whitelistContracts(
        address[] memory contractAddreses,
        bool[] memory statuses,
        uint256[] memory prices,
        uint256[] memory startDates,
        uint256[] memory endDates
    ) external onlyOwner {
        uint256 len = contractAddreses.length;
        uint256 sum = 0;
        uint256 actIndex = indexNum;
        for (uint256 i = 0; i < len; i++) {
            WLContract memory wl = WLContract(
                contractAddreses[i],
                prices[i],
                startDates[i],
                endDates[i],
                statuses[i]
            );
            uint256 ind = actIndex;
            if (contractToIndex[contractAddreses[i]] == 0) {
                ind = ind + sum;
                contractToIndex[contractAddreses[i]] = ind;
                sum++;
            } else {
                ind = contractToIndex[contractAddreses[i]];
            }
            whitelist[ind] = wl;
        }
        indexNum += sum;
    }

    ///@notice Sets Mint status
    ///@param newStatus New status (true - enable, false - disable)
    ///@dev Can be executed only by contract owner
    function setMintStatus(bool newStatus) external onlyOwner {
        isMintActive = newStatus;
    }

    ///@notice Sets permanent lock for editing URI
    ///@dev Can be executed only by contract owner
    function lockBaseTokenUri() external onlyOwner {
        baseUriLocked = true;
    }

    ///@notice Sets new base uri
    ///@param _baseTokenURI New base token uri
    ///@dev Can be executed only by contract owner if base uri doesnt lock
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        require(!baseUriLocked, "JRNYMetaverseBox: Base Uri locked");
        baseTokenURI = _baseTokenURI;
    }

    ///@notice Withdraws ETH from contract
    ///@dev Can be executed only by contract owner
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}