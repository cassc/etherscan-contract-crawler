// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// upgradeable erc721
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

// contruct stakin interface
interface IStaking {
    function checkTokenStakedPeriodForUser(
        uint256 _tokenId,
        address _user
    ) external view returns (uint256);
}

contract Summoner is
    Initializable,
    ContextUpgradeable,
    IERC2981Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    ERC721EnumerableUpgradeable
{
    using StringsUpgradeable for uint256;

    address public pixelatedApeStaking;
    string private _baseTokenURI;
    string private _tokenURISuffix;
    uint256 public constant MAX_SUPPLY = 10000;
    address payable public paymentAddress; // address to receive payments
    uint96 public royaltyFee; // royalty fee in basis points
    string public contractURI; // contract URI
    uint256 priceWhitelist; // price of summoner
    uint256 pricePublic; // price of summoner
    bytes32 merketRootAddress; // address of merkle root
    address treasury;

    // claimed addresses
    mapping(address => bool) public whitelistClaimed;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Set whitelist address
    function setWhiteListAddress(bytes32 _address) public onlyOwner {
        merketRootAddress = _address;
    }

    // update treasury
    function updateTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    enum Stages {
        NotStarted,
        Summoning,
        whitelist,
        PublicMint,
        Finished
    }
    // current stage of minting
    Stages public stage;

    function initialize(
        address thePixApe,
        address _paymentAddress,
        uint96 royaltyAmount,
        string memory baseURI,
        string memory suffix,
        string memory _contractURI, // contractURI for opensea royalties
        uint256 _whitelistPrice,
        uint256 _publicPrice
    ) public initializer {
        __Context_init_unchained();
        __ERC721_init_unchained("PixApe Summoner", "PAS");
        __ERC721Enumerable_init_unchained();
        __Ownable_init_unchained();
        __DefaultOperatorFilterer_init();
        __UUPSUpgradeable_init_unchained();
        pixelatedApeStaking = thePixApe;
        _baseTokenURI = baseURI;
        _tokenURISuffix = suffix;
        paymentAddress = payable(_paymentAddress);
        royaltyFee = royaltyAmount;
        contractURI = _contractURI;
        priceWhitelist = _whitelistPrice;
        pricePublic = _publicPrice;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    // calculate royalty fee
    function _calculateRoyalty(
        uint256 _salePrice
    ) internal view returns (uint256) {
        return (_salePrice * 10000) / royaltyFee;
    }

    // update contract URI
    function updateContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        if (_tokenId >= 0 && _tokenId < MAX_SUPPLY) {
            return (paymentAddress, _calculateRoyalty(_salePrice));
        }
    }

    // set stage if minting
    function setStage(Stages _stage) public onlyOwner {
        stage = _stage;
    }

    // get stage of minting
    function getStage() public view returns (Stages) {
        return stage;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setTokenURISuffix(string memory suffix) public onlyOwner {
        _tokenURISuffix = suffix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function walletOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        _tokenURISuffix
                    )
                )
                : "";
    }

    // update pixelatedApeStaking 
    function updatePixelatedApeStaking(address _pixelatedApeStaking) public onlyOwner {
        pixelatedApeStaking = _pixelatedApeStaking;
    }

    function mintSummoner(uint256 tokenId) public {
        // require that the stage is summoning
        require(stage == Stages.Summoning, "Minting not started");
        IStaking staking = IStaking(pixelatedApeStaking);
        uint256 time = staking.checkTokenStakedPeriodForUser(
            tokenId,
            msg.sender
        );
        require(time > 0, "You must stake the pixelated ape");
        // time must be greater than 0
        // if token is 10000 replace with 94
        if (tokenId == 10000) {
            require(!_exists(94), "Token already minted");
            _safeMint(msg.sender, 94);
        } else {
            require(!_exists(tokenId), "Token already minted");
            _safeMint(msg.sender, tokenId);
        }
    }

    function mintSummoners(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            mintSummoner(tokenIds[i]);
        }
    }

    // update whitelist price
    function updateWhitelistPrice(uint256 _price) public onlyOwner {
        priceWhitelist = _price;
    }

    function getUnmintedTokens() public view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](MAX_SUPPLY);
        uint256 count = 0;
        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            if (!_exists(i)) {
                tokenIds[count] = i;
                count++;
            }
        }
        return tokenIds;
    }

    // update public price
    function updatePublicPrice(uint256 _price) public onlyOwner {
        pricePublic = _price;
    }

    function mintWhitelistSummoners(
        bytes32[] calldata _merketProof,
        uint256[] memory tokenIds_
    ) public payable {
        require(stage == Stages.whitelist, "whitelist Minting not started");
        // max of 2 tokens
        require(tokenIds_.length <= 2, "you can claim Max of 2 tokens");
        // check that has not been claimed
        // value must be greater than whitelist price
        require(
            msg.value >= priceWhitelist * tokenIds_.length,
            "Insufficient funds"
        );
        require(
            whitelistClaimed[msg.sender] != true,
            "You have already claimed"
        );

        // create leaf from sender address
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        // check merkle proof
        require(
            MerkleProofUpgradeable.verify(
                _merketProof,
                merketRootAddress,
                leaf
            ),
            "Invalid proof"
        );

        whitelistClaimed[msg.sender] = true;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(msg.value >= priceWhitelist, "Price is too low");
            require(
                tokenIds_[i] >= 0 && tokenIds_[i] <= MAX_SUPPLY,
                "Token ID invalid"
            );

            // if token is 10000 replace with 94
            if (tokenIds_[i] == 10000) {
                require(!_exists(94), "Token already minted");
                _safeMint(msg.sender, 94);
            } else {
                require(
                    tokenIds_[i] >= 0 && tokenIds_[i] < MAX_SUPPLY,
                    "Token ID invalid"
                );
                require(!_exists(tokenIds_[i]), "Token already minted");
                _safeMint(msg.sender, tokenIds_[i]);
            }
        }
    }

    function isWhitelistedClaimed(address _address) public view returns (bool) {
        return whitelistClaimed[_address];
    }

    function canWhitelistClaim(
        bytes32[] calldata _merketProof,
        address _address
    ) public view returns (bool) {
        if (stage != Stages.whitelist) {
            return false;
        }
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        if (whitelistClaimed[_address]) {
            return false;
        }
        return
            MerkleProofUpgradeable.verify(
                _merketProof,
                merketRootAddress,
                leaf
            );
    }

    function mintAllSummoners(uint256 tokenId_) public payable {
        require(stage == Stages.PublicMint, "Public Minting not started");
        require(msg.value >= pricePublic, "Price is too low");
        require(tokenId_ >= 0 && tokenId_ <= MAX_SUPPLY, "Token ID invalid");
        // if token is 10000 replace with 94
        if (tokenId_ == 10000) {
            require(!_exists(94), "Token already minted");
            _safeMint(msg.sender, 94);
        } else {
            require(!_exists(tokenId_), "Token already minted");
            _safeMint(msg.sender, tokenId_);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(treasury).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}