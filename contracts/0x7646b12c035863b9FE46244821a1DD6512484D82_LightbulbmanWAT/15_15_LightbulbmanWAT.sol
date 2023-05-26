//
//    █     █░ ▄▄▄     ▄▄▄█████▓
//    ▓█░ █ ░█░▒████▄   ▓  ██▒ ▓▒
//    ▒█░ █ ░█ ▒██  ▀█▄ ▒ ▓██░ ▒░
//    ░█░ █ ░█ ░██▄▄▄▄██░ ▓██▓ ░
//    ░░██▒██▓  ▓█   ▓██▒ ▒██▒ ░
//    ░ ▓░▒ ▒   ▒▒   ▓▒█░ ▒ ░░
//    ▒ ░ ░    ▒   ▒▒ ░   ░
//    ░   ░    ░   ▒    ░
//        ░          ░  ░
//
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
error LightbulbmanWAT__NeedMoreEthSent();
error LightbulbmanWAT__TransferFailed();

interface ILbmGenesis {
    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256);
}

/**@title Lightbulbman WAT Collection
 * @author Bjarne Melgaard Enterprises & NORN
 * @notice This is the second release in the Lightbulbman Series
 */

contract LightbulbmanWAT is Ownable, ERC721Enumerable, ReentrancyGuard {
    using Strings for uint256;

    enum SaleStatus {
        NOT_ACTIVE,
        HOLDER,
        WHITELIST,
        PUBLIC
    }

    SaleStatus public saleStatus = SaleStatus.NOT_ACTIVE;

    ILbmGenesis LbmGenesis;
    bool public revealed;
    string private s_baseURI =
        "ipfs://bafkreic2kzw2k4gecxmhjvztv5a26472nqes546rdcwvbwsiqgl7mmdy2m/";
    uint256 private constant MAX_SUPPLY = 1025;
    uint256 private s_nextPublicTokenId;
    uint256 public s_publicMintPrice;
    uint256 public s_preMintPrice;
    uint256 public s_whiteListMintPrice;
    uint256 public s_totalSupply;
    uint256 public s_maxAllowedWhitelistMint;
    uint256 public s_maxAllowedPublicMint;
    address payable private s_withdrawalAddress;

    mapping(address => bool) public whitelist;
    mapping(uint256 => bool) public mintedTokens;
    mapping(address => uint256) public whitelistMintedTokens;
    mapping(address => uint256) public publicMintedTokens;

    event ToggleSaleState(bool saleActive);
    event PublicMintPriceChanged(uint256 _mintPrice);
    event PreMintPriceChanged(uint256 _mintPrice);
    event WhitelistMintPriceChanged(uint256 _mintPrice);
    event PublicMint(uint256 indexed _tokenId);
    event PreMint(uint256 indexed _tokenId);
    event WhitelistMint(uint256 indexed _tokenId);
    event WithdrawalAddressChanged(address payable _newWithdrawalAddress);

    constructor(
        address _lbmGenesisContractAddress,
        uint256 _publicMintPrice,
        uint256 _whiteListMintPrice,
        uint256 _preMintPrice,
        uint256 _maxAllowedWhitelistMint,
        uint256 _maxAllowedPublicMint,
        address payable _withdrawalWallet
    ) ERC721("LIGHTBULBMAN WAT", "WAT") {
        LbmGenesis = ILbmGenesis(_lbmGenesisContractAddress);
        s_totalSupply;
        s_publicMintPrice = _publicMintPrice;
        s_whiteListMintPrice = _whiteListMintPrice;
        s_preMintPrice = _preMintPrice;
        saleStatus;
        s_maxAllowedWhitelistMint = _maxAllowedWhitelistMint;
        s_maxAllowedPublicMint = _maxAllowedPublicMint;
        s_withdrawalAddress = _withdrawalWallet;
    }

    function changeSaleStatus(uint8 _newStatus) external onlyOwner {
        require(_newStatus >= 0 && _newStatus <= 3, "Invalid status");
        saleStatus = SaleStatus(_newStatus);
    }

    function setWhithdrawalWallet(
        address payable _withdrawalWallet
    ) external onlyOwner {
        s_withdrawalAddress = _withdrawalWallet;
        emit WithdrawalAddressChanged(s_withdrawalAddress);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        s_withdrawalAddress.transfer(balance);
    }

    function availableMint(
        address owner
    ) external view returns (uint256[] memory) {
        uint256 tokenCount = LbmGenesis.balanceOf(owner);

        uint256[] memory ownedTokenIds = new uint256[](tokenCount);
        uint256 currentIndex;
        for (uint256 i; i < tokenCount; ++i) {
            uint256 tokenId = LbmGenesis.tokenOfOwnerByIndex(owner, i);
            if (!mintedTokens[tokenId]) {
                ownedTokenIds[currentIndex] = tokenId;
                ++currentIndex;
            }
        }

        uint256[] memory unmintedOwnedTokenIds = new uint256[](currentIndex);
        for (uint256 i; i < currentIndex; ++i) {
            unmintedOwnedTokenIds[i] = ownedTokenIds[i];
        }

        return unmintedOwnedTokenIds;
    }

    function gift(
        address _receiverAddress,
        uint16[] calldata _nTokens
    ) external onlyOwner {
        require(
            _nTokens.length <= MAX_SUPPLY - s_totalSupply,
            "Exeeded supply"
        );
        require(saleStatus == SaleStatus.NOT_ACTIVE, "Invalid status");

        for (uint16 i; i < _nTokens.length; ++i) {
            uint16 tokenId = _nTokens[i];
            require(tokenId >= 0 && tokenId < MAX_SUPPLY, "Invalid token id");
            require(!_exists(tokenIDToLBMID(tokenId)), "Token already minted");

            mintedTokens[tokenId] = true;

            _safeMint(_receiverAddress, tokenIDToLBMID(tokenId));
        }

        s_totalSupply = s_totalSupply + _nTokens.length;
        // s_nextPublicTokenId = ++tokenId; !!! TODO HOW DOES THIS IMPACT next public token id? SHould be fine
    }

    function preMintNTokens(uint256[] calldata tokens) external payable {
        require(saleStatus == SaleStatus.HOLDER, "Invalid status");
        if (msg.value < s_preMintPrice * tokens.length) {
            revert LightbulbmanWAT__NeedMoreEthSent();
        }

        for (uint256 i; i < tokens.length; ++i) {
            preMint(tokens[i]);
        }
        s_totalSupply = s_totalSupply + tokens.length;
    }

    function preMint(uint256 versionOneTokenId) internal returns (uint256) {
        require(
            versionOneTokenId >= 0 && versionOneTokenId < MAX_SUPPLY,
            "Invalid tokenId"
        );
        require(
            LbmGenesis.ownerOf(versionOneTokenId) == msg.sender,
            "Not the owner"
        );
        require(!_exists(versionOneTokenId), "Token already minted");

        mintedTokens[versionOneTokenId] = true;
        _safeMint(msg.sender, tokenIDToLBMID(versionOneTokenId));

        emit PreMint(tokenIDToLBMID(versionOneTokenId));

        return versionOneTokenId;
    }

    function whitelistMint(
        uint8 _nTokens
    ) external payable nonReentrant returns (uint256) {
        require(saleStatus == SaleStatus.WHITELIST, "Invalid status");
        require(whitelist[msg.sender], "NOT_IN_WHITELIST");
        if (msg.value < s_whiteListMintPrice * _nTokens) {
            revert LightbulbmanWAT__NeedMoreEthSent();
        }
        require(
            s_maxAllowedWhitelistMint - whitelistMintedTokens[msg.sender] >=
                _nTokens,
            "Exeeded max allowed"
        );
        uint256 tokenId = s_nextPublicTokenId;
        require(tokenId < MAX_SUPPLY, "Finished");
        for (uint8 i; i < _nTokens; ++i) {
            while (mintedTokens[tokenId]) {
                ++tokenId;
                require(tokenId < MAX_SUPPLY, "Finished");
            }

            mintedTokens[tokenId] = true;
            _safeMint(msg.sender, tokenIDToLBMID(tokenId));

            emit WhitelistMint(tokenIDToLBMID(tokenId));
        }
        whitelistMintedTokens[msg.sender] =
            whitelistMintedTokens[msg.sender] +
            _nTokens;
        s_totalSupply = s_totalSupply + _nTokens;
        s_nextPublicTokenId = ++tokenId;
        return s_nextPublicTokenId;
    }

    function publicMint(
        uint8 _nTokens
    ) external payable nonReentrant returns (uint256) {
        require(saleStatus == SaleStatus.PUBLIC, "Invalid status");

        if (msg.value < s_publicMintPrice * _nTokens) {
            revert LightbulbmanWAT__NeedMoreEthSent();
        }
        require(
            s_maxAllowedPublicMint - publicMintedTokens[msg.sender] >= _nTokens,
            "Exeeded max allowed"
        );

        uint256 tokenId = s_nextPublicTokenId;
        require(tokenId < MAX_SUPPLY, "Finished");
        for (uint8 i; i < _nTokens; ++i) {
            while (mintedTokens[tokenId]) {
                ++tokenId;
                require(tokenId < MAX_SUPPLY, "Finished");
            }

            mintedTokens[tokenId] = true;
            _safeMint(msg.sender, tokenIDToLBMID(tokenId));

            emit PublicMint(tokenIDToLBMID(tokenId));
        }
        publicMintedTokens[msg.sender] =
            publicMintedTokens[msg.sender] +
            _nTokens;
        s_totalSupply = s_totalSupply + _nTokens;
        s_nextPublicTokenId = ++tokenId;
        return s_nextPublicTokenId;
    }

    function addToWhitelist(
        address[] calldata toAddAddresses
    ) external onlyOwner {
        for (uint i; i < toAddAddresses.length; ++i) {
            whitelist[toAddAddresses[i]] = true;
        }
    }

    function setPreMintPrice(uint256 _mintPrice) external onlyOwner {
        s_preMintPrice = _mintPrice;
        emit PreMintPriceChanged(_mintPrice);
    }

    function setWhitelistMintPrice(uint256 _mintPrice) external onlyOwner {
        s_whiteListMintPrice = _mintPrice;
        emit WhitelistMintPriceChanged(_mintPrice);
    }

    function setPublicMintPrice(uint256 _mintPrice) external onlyOwner {
        s_publicMintPrice = _mintPrice;
        emit PublicMintPriceChanged(_mintPrice);
    }

    function setMaxAllowedWhitelistMint(uint256 _value) external onlyOwner {
        s_maxAllowedWhitelistMint = _value;
    }

    function setMaxAllowedPublicMint(uint256 _value) external onlyOwner {
        s_maxAllowedPublicMint = _value;
    }

    function setBaseUri(string calldata _baseUri) external onlyOwner {
        s_baseURI = _baseUri;
    }

    function toggleReveal() external onlyOwner {
        revealed = !revealed;
    }

    function getPublicMintPrice() public view returns (uint256) {
        return s_publicMintPrice;
    }

    function getMaxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function getSaleStatus() public view returns (SaleStatus) {
        return saleStatus;
    }

    function getWithdrawalAddress() public view returns (address) {
        return s_withdrawalAddress;
    }

    function getActivePrice() public view returns (uint256) {
        if (saleStatus == SaleStatus.HOLDER) {
            return s_preMintPrice;
        } else if (saleStatus == SaleStatus.WHITELIST) {
            return s_whiteListMintPrice;
        } else if (saleStatus == SaleStatus.PUBLIC) {
            return s_publicMintPrice;
        } else {
            return s_preMintPrice;
        }
    }

    function getBaseUri() public view onlyOwner returns (string memory) {
        return s_baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();

        return
            revealed
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : string(abi.encodePacked(baseURI));
    }

    function _baseURI() internal view override returns (string memory) {
        return s_baseURI;
    }

    function tokenIDToLBMID(
        uint256 tokenID
    ) internal pure returns (uint256 lbmID) {
        if (0 <= tokenID && tokenID <= 653) {
            lbmID = tokenID + 468;
        } else if (654 <= tokenID && tokenID <= 1024) {
            lbmID = tokenID - 654;
        } else {
            revert("Invalid ID");
        }
    }
}