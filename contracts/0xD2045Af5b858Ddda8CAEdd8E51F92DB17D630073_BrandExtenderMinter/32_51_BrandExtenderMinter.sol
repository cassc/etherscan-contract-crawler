// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "stl-contracts/royalty/DerivedERC2981RoyaltyUpgradeable.sol";
import "stl-contracts/ERC/ERC5169Upgradable.sol";
import "stl-contracts/tokens/OptimizedEnumerableUpgradeable.sol";

import "stl-contracts/security/VerifyLinkAttestation.sol";
import "stl-contracts/tokens/extensions/ParentContractsUpgradeable.sol";
import "./libs/interfaces.sol";

import "stl-contracts/tokens/extensions/Minter.sol";
import "stl-contracts/tokens/extensions/SharedHolders.sol";

import "stl-contracts/royalty/RoyaltySpliterStatic.sol";
import "stl-contracts/access/UriChangerUpgradeable.sol";
import "stl-contracts/security/VerifySignature.sol";

import {DefaultOperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract BrandExtenderMinter is
    iMinterAndParent,
    OwnableUpgradeable,
    ERC5169Upgradable,
    VerifySignature,
    UriChangerBase,
    DerivedERC2981RoyaltyUpgradeable,
    OptimizedEnumerableUpgradeable,
    ParentContractsUpgradeable,
    SharedHolders,
    Minter,
    UUPSUpgradeable,
    // Required to suport OpenSea Royalty support
    DefaultOperatorFiltererUpgradeable
{
    using Strings for uint256;
    using AddressUpgradeable for address;

    using Counters for Counters.Counter;

    mapping(uint256 => ERC721s) internal _parents;

    // relation of combined contract_and_id to tokenIds, kind of Enumerable
    mapping(uint256 => uint256[]) internal _childrenArr;
    mapping(uint256 => uint256) internal _childrenIndex;
    mapping(uint256 => uint256) internal _childrenCounter;

    string constant _METADATA_URI = "https://resources.smarttokenlabs.com";
    uint256 constant _CONTRACT_MINT_ROYALTY = 500;

    address _royaltyReceiver;
    address _mintFundsReceiver;

    uint256 _mintStartTimestamp;
    uint256 _mintEndTimestamp;

    uint256 public mintPriceUpTo3;
    uint256 public mintPrice3Plus;
    mapping(address => uint256) internal _mintedByWallet;
    bool internal _collectContracts;

    event BaseUriUpdated(string uri);
    event MintStartUpdated(uint256 timestamp);
    event MintEndUpdated(uint256 timestamp);
    event RoyaltyContractUpdated(address indexed newAddress);
    event PermanentURI(string _value, uint256 indexed _id);

    event MintPricesUpdated(uint256 mintPriceUpTo3, uint256 mintPrice3Plus);
    event MintedDerived(
        address indexed parentContract,
        uint256 indexed parentId,
        uint256 indexed mintedId,
        string tmpUri,
        uint256 currentOriginIndex
    );
    event MintFundsReceiverUpdated(address indexed newAddress);

    // Base URI
    string private __baseURI;

    // count burnt token number to calc totalSupply()
    uint256 private _burnt;

    using Strings for uint256;

    struct MintRequestData {
        address erc721;
        uint256 tokenId;
        bytes signature;
        string tokenURI;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _authorizeUpdateUriChanger(address newAddress) internal override onlyOwner {}

    function _authorizeSetScripts(string[] memory) internal override onlyOwner {}

    function _authorizeAddParent(address newContract) internal override onlyUriChanger {}

    function _authorizeSetSharedHolder(address[] calldata newAddresses) internal override onlyOwner {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(Minter, OptimizedEnumerableUpgradeable) {
        Minter._beforeTokenTransfer(from, to, tokenId);
        OptimizedEnumerableUpgradeable._beforeTokenTransfer(from, to, tokenId);
    }

    function initialize(address _rr, address _newUriChanger, bool initialCollectContracts) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ERC721_init("BrandExtender", "BEX");
        __DefaultOperatorFilterer_init();
        updateUriChanger(_newUriChanger);
        _setRoyaltyContract(_rr);
        _setRoyalty(400); // 100 = 1%, 1% artist + 2% STL + 2% partner

        // 0.001 ETH
        mintPriceUpTo3 = 1 ether / 1000;
        // 0.025 ETH
        mintPrice3Plus = (1 ether * 25) / 1000;

        _collectContracts = initialCollectContracts;
    }

    function switchCollectContractsFlow() public onlyOwner {
        _collectContracts = !_collectContracts;
    }

    function getMinterAndParent(uint256 tokenId) external view returns (address minter, address parent) {
        minter = getMinter(tokenId);
        ERC721s memory _parent = getParent(tokenId);
        parent = getRoyaltyBeneficiary(_parent.erc721);
    }

    function getMinterParentHolder(
        uint256 tokenId
    ) external view returns (address minter, address parent, address holder) {
        minter = getMinter(tokenId);
        ERC721s memory _parent = getParent(tokenId);
        parent = _parent.erc721;
        holder = _getTokenOwner(parent, _parent.tokenId);
    }

    function setMintPrices(uint256 mintPriceUpTo3_, uint256 mintPrice3Plus_) external onlyUriChanger {
        emit MintPricesUpdated(mintPriceUpTo3_, mintPrice3Plus_);
        mintPriceUpTo3 = mintPriceUpTo3_;
        mintPrice3Plus = mintPrice3Plus_;
    }

    function _validateMintRequest(MintRequestData calldata data) internal view returns (bool) {
        address erc721 = data.erc721;
        require(isAllowedParent(data.erc721), "Contract not supported");

        bytes memory toSign = abi.encodePacked(
            address(this),
            msg.sender,
            balanceOf(msg.sender),
            erc721,
            data.tokenId,
            block.chainid,
            data.tokenURI
        );

        require(verifyEthHash(keccak256(toSign), data.signature) == uriChanger(), "Wrong metadata signer");

        return true;
    }

    function mintedBy(address wallet) public view returns (uint256) {
        return _mintedByWallet[wallet];
    }

    function calcMintPrice(uint256 mintNumber) public view returns (uint balance, uint mintSum) {
        balance = _mintedByWallet[msg.sender];

        if (balance > 3) {
            mintSum = mintPrice3Plus * mintNumber;
        } else {
            if ((balance + mintNumber) < 4) {
                mintSum = mintPriceUpTo3 * mintNumber;
            } else {
                mintSum = mintPriceUpTo3 * (3 - balance) + mintPrice3Plus * (mintNumber + balance - 3);
            }
        }
    }

    function _processPriceAndCounter(uint256 mintNumber) internal returns (uint256) {
        (uint balance, uint mintSum) = calcMintPrice(mintNumber);
        _mintedByWallet[msg.sender] = balance + mintNumber;

        require(msg.value >= mintSum, "Not enough ETH");

        uint256 diff = msg.value - mintSum;
        if ((diff) > 0) {
            _pay(msg.sender, diff);
        }

        return balance;
    }

    function mintDerived(MintRequestData[] calldata data) external payable virtual {
        uint256 balance = _processPriceAndCounter(data.length);

        uint256 mintedID;
        uint256 i;
        uint256 mintPrice;

        for (i = 0; i < data.length; i++) {
            require(_validateMintRequest(data[i]), "Invalid mint request");

            // pay Contract royalty 5%; rest of funds stay under contract
            // and can be withdrawn by owner

            if (!_collectContracts) {
                if ((balance + i) < 3) {
                    mintPrice = mintPriceUpTo3;
                } else {
                    mintPrice = mintPrice3Plus;
                }
                if (mintPrice > 0) {
                    uint256 contractRoyaltyAmount = (mintPrice * _CONTRACT_MINT_ROYALTY) / 10000;
                    _pay(getRoyaltyBeneficiary(data[i].erc721), contractRoyaltyAmount);
                }
            }

            mintedID = _mintDerivedMulti(data[i].erc721, data[i].tokenId, msg.sender);

            emit MintedDerived(
                data[i].erc721,
                data[i].tokenId,
                mintedID,
                data[i].tokenURI,
                tokenOfOriginCounter(data[i].erc721, data[i].tokenId) - 1
            );
        }
    }

    // slither-disable-start calls-loop
    // slither-disable-start low-level-calls
    function _pay(address ethReceiver, uint256 amount) internal {
        (bool sent, ) = ethReceiver.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    // slither-disable-end low-level-calls
    // slither-disable-end calls-loop

    function setMintFundsReceiver(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Address required");
        _mintFundsReceiver = _newAddress;
        emit MintFundsReceiverUpdated(_newAddress);
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "Empty balance");
        require(_mintFundsReceiver != address(0), "Receiver not set");

        _pay(_mintFundsReceiver, balance);
    }

    function _mintDerivedMulti(address erc721, uint256 tokenId, address to) internal returns (uint256 newTokenId) {
        require(block.timestamp >= _mintStartTimestamp, "Minting has not started");
        if (_mintEndTimestamp > 0) {
            require(block.timestamp <= _mintEndTimestamp, "Minting finished");
        }

        if (hasSharedTokenHolders()) {
            require(_isSharedHolderTokenOwner(erc721, tokenId), "Shared Holder not owner");
        } else {
            require(_isTokenOwner(erc721, tokenId), "Need to be an owner to mint");
        }

        newTokenId = _tokenIdCounter.current();

        _parents[newTokenId] = ERC721s(erc721, tokenId);

        // Get unique 256 bit pointer to specific originating Token (masked address + tokenId)
        uint256 pointer = _getPonter(erc721, tokenId);
        // How many tokens are currently dervied from the specific originating Token
        uint256 newTokenIndex = _childrenCounter[pointer];

        _childrenIndex[newTokenId] = _childrenArr[pointer].length;
        _childrenArr[pointer].push(newTokenId); // create mapping of derived tokenIds for each originating Token
        _childrenCounter[pointer] = newTokenIndex + 1;

        _safeMint(to, newTokenId);

        _tokenIdCounter.increment();
    }

    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(_METADATA_URI, "/contracts/brend_extender.json"));
    }

    function _contractAddress() internal view returns (string memory) {
        return Strings.toHexString(uint160(address(this)), 20);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length > 0) {
            return string(abi.encodePacked(base, "/", tokenId.toString()));
        } else {
            return
                string(
                    abi.encodePacked(
                        _METADATA_URI,
                        "/",
                        block.chainid.toString(),
                        "/",
                        _contractAddress(),
                        "/",
                        tokenId.toString()
                    )
                );
        }
    }

    function baseURI() public view virtual returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyUriChanger {
        _setBaseURI(baseURI_);
    }

    function _setBaseURI(string memory baseURI_) internal virtual {
        emit BaseUriUpdated(baseURI_);
        __baseURI = baseURI_;
    }

    function setMintStartTime(uint256 timestamp) external onlyOwner {
        _setMintStartTime(timestamp);
    }

    function _setMintStartTime(uint256 timestamp) internal {
        emit MintStartUpdated(timestamp);
        _mintStartTimestamp = timestamp;
    }

    function getMintStartTime() external view returns (uint256) {
        return _mintStartTimestamp;
    }

    function setMintEndTime(uint256 timestamp) external onlyOwner {
        _setMintEndTime(timestamp);
    }

    function _setMintEndTime(uint256 timestamp) internal {
        emit MintEndUpdated(timestamp);
        _mintEndTimestamp = timestamp;
    }

    function getMintEndTime() external view returns (uint256) {
        return _mintEndTimestamp;
    }

    // Form combination of address & tokenId for unique pointer to NFT - Address is 160 bits (20*8) + TokenId 96 bits
    function _getPonter(address c, uint256 tokenId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(c, tokenId)));
    }

    function tokenOfOriginByIndex(address erc721, uint256 tokenId, uint256 index) public view returns (uint256) {
        uint256 pointer = _getPonter(erc721, tokenId);
        require(index < _childrenArr[pointer].length, "Index out of bounds");
        return _childrenArr[pointer][index];
    }

    function tokenOfOriginCount(address erc721, uint256 tokenId) public view returns (uint256) {
        uint256 pointer = _getPonter(erc721, tokenId);
        return _childrenArr[pointer].length;
    }

    function tokenOfOriginCounter(address erc721, uint256 tokenId) public view returns (uint256) {
        uint256 pointer = _getPonter(erc721, tokenId);
        return _childrenCounter[pointer];
    }

    // required to solve inheritance
    function _burn(uint256 tokenId) internal virtual override {
        ERC721s memory parent = getParent(tokenId);
        uint256 pointer = _getPonter(parent.erc721, parent.tokenId);

        uint256 tokenIndex = _childrenIndex[tokenId];

        uint256 lastTokenIndex = _childrenArr[pointer].length - 1;

        //If required, swap the token to be burned and the token at the head of the stack
        //then use pop to remove the head of the _childrenArr stack mapping
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _childrenArr[pointer][lastTokenIndex];

            _childrenArr[pointer][tokenIndex] = lastTokenId;

            _childrenIndex[lastTokenId] = tokenIndex;
        }

        _childrenArr[pointer].pop();
        delete _childrenIndex[tokenId];

        delete _parents[tokenId];
        ERC721Upgradeable._burn(tokenId);
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved and not owner");
        _burnt++;
        _burn(tokenId);
    }

    // required to solve inheritance
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC5169, OptimizedEnumerableUpgradeable, DerivedERC2981RoyaltyUpgradeable)
        returns (bool)
    {
        return
            ERC5169.supportsInterface(interfaceId) ||
            OptimizedEnumerableUpgradeable.supportsInterface(interfaceId) ||
            DerivedERC2981RoyaltyUpgradeable.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view virtual override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Token doesnt exist.");
        receiver = _royaltyReceiver;
        royaltyAmount = (_getRoyalty() * salePrice) / 10000;
    }

    function setRoyaltyPercentage(uint256 value) external onlyOwner {
        require(value < 100 * 100, "Percentage more than 100%");
        _setRoyalty(value);
    }

    function setRoyaltyContract(address newAddress) external onlyOwner {
        _setRoyaltyContract(newAddress);
    }

    function _setRoyaltyContract(address newAddress) internal {
        require(newAddress.isContract(), "Only Contract allowed");
        emit RoyaltyContractUpdated(newAddress);
        _royaltyReceiver = newAddress;
    }

    function _isTokenOwner(address _contract, uint256 tokenId) internal view returns (bool) {
        return _msgSender() == _getTokenOwner(_contract, tokenId);
    }

    // slither-disable-start calls-loop
    function _getTokenOwner(address erc721, uint256 tokenId) internal view returns (address owner) {
        owner = ERC721(erc721).ownerOf(tokenId);
    }

    // slither-disable-end calls-loop

    function getParentNftHolder(uint256 tokenId) public view returns (address owner) {
        ERC721s memory data = getParent(tokenId);
        owner = ERC721(data.erc721).ownerOf(data.tokenId);
    }

    function getParent(uint256 tokenId) public view returns (ERC721s memory) {
        require(_exists(tokenId), "Non-existent token");
        return _parents[tokenId];
    }

    /**
    Required to suport OpenSea Royalty suport
     */

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}