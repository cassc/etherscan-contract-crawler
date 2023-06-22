//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract Land is ERC721A, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    string public PROVENANCE_HASH;

    uint256 public presaleR1StartTime = 1667750400;
    uint256 public presaleR2StartTime = 1667750700;
    uint256 public totalPresaleMinted;
    mapping(address => uint256) public presaleMinted;
    uint256 public constant MAX_PRESALE_LANDS = 888;
    uint256 public constant PRESALE_MINT_PRICE = 0.1 ether;
    uint256 public constant PRESALE_UNLOCK_TIME = 1668355200;

    uint256 public allowListR1StartTime = 1667752200;
    uint256 public allowListR2StartTime = 1667752500;
    uint256 public allowListStartTokenId;
    uint256 public totalAllowListMinted;
    mapping(address => uint256) public allowListMinted;
    uint256 public constant MAX_ALLOW_LIST_LANDS = 3900;
    uint256 public constant ALLOW_LIST_MINT_PRICE = 0.25 ether;

    uint256 public claimableStartTime = 1667754000;
    uint256 public claimableStartTokenId;
    uint256 public totalLandsClaimed;
    mapping(address => uint256) public claimMinted;
    uint256 public constant MAX_CLAIMABLE_LANDS = 600;
    uint256 public constant CLAIMABLE_UNLOCK_TIME = 1668960000;

    uint256 public mintStartTime = 1667755800;
    uint256 public mintEndTime = 1667928600;
    uint256 public mintStartTokenId;
    uint256 public constant MINT_PRICE = 0.4 ether;

    uint256 public totalReservedMinted;
    uint256 public constant MAX_RESERVED_LANDS = 500;

    string private baseURI;
    string private hiddenMetadataURI;
    bool public revealed;

    address private signer;
    uint256 public MAX_LANDS;
    bool public transferEnabled = false;
    uint256 public maxMintPerAddress = 4;

    bool public bonusMarketingFeeSet = false;
    address payable public marketingWallet;

    enum Round {
        PresaleR1,
        PresaleR2,
        AllowListR1,
        AllowListR2,
        Claim
    }

    constructor(uint256 maxLands) ERC721A("Worlds Beyond Official - Genesis Land Collection", "BEYONDLG") {
        MAX_LANDS = maxLands;
    }

    function presaleR1MintLands(
        uint256 numLands,
        uint256 maxLands,
        bytes calldata signature
    )
        external
        payable
        mustBetween(presaleR1StartTime, presaleR2StartTime)
        onlyVerified(Round.PresaleR1, maxLands, signature)
        mustMatchPrice(PRESALE_MINT_PRICE, numLands)
    {
        _presaleMintLands(numLands, maxLands);
    }

    function presaleR2MintLands(
        uint256 numLands,
        uint256 maxLands,
        bytes calldata signature
    )
        external
        payable
        mustBetween(presaleR2StartTime, allowListR1StartTime)
        onlyVerified(Round.PresaleR2, maxLands, signature)
        mustMatchPrice(PRESALE_MINT_PRICE, numLands)
    {
        _presaleMintLands(numLands, maxLands);
    }

    function allowListR1MintLands(
        uint256 numLands,
        uint256 maxLands,
        bytes calldata signature
    )
        external
        payable
        mustBetween(allowListR1StartTime, allowListR2StartTime)
        onlyVerified(Round.AllowListR1, maxLands, signature)
        mustMatchPrice(ALLOW_LIST_MINT_PRICE, numLands)
    {
        _allowListMintLands(numLands, maxLands);
    }

    function allowListR2MintLands(
        uint256 numLands,
        uint256 maxLands,
        bytes calldata signature
    )
        external
        payable
        mustBetween(allowListR2StartTime, claimableStartTime)
        onlyVerified(Round.AllowListR2, maxLands, signature)
        mustMatchPrice(ALLOW_LIST_MINT_PRICE, numLands)
    {
        _allowListMintLands(numLands, maxLands);
    }

    function claimLands(
        uint256 numLands,
        uint256 maxLands,
        bytes calldata signature
    )
        external
        mustBetween(claimableStartTime, mintStartTime)
        onlyVerified(Round.Claim, maxLands, signature)
    {
        require(
            numLands + claimMinted[msg.sender] <= maxLands,
            "Max claimable lands per address exceeded"
        );
        require(
            totalLandsClaimed + numLands <= MAX_CLAIMABLE_LANDS,
            "Max claimable lands exceeded"
        );

        if (claimableStartTokenId == 0) {
            claimableStartTokenId = _nextTokenId();
        }

        claimMinted[msg.sender] += numLands;
        totalLandsClaimed += numLands;
        _mintLands(msg.sender, numLands);
    }

    function mintLands(uint256 numLands)
        external
        payable
        mustBetween(mintStartTime, mintEndTime)
        mustMatchPrice(MINT_PRICE, numLands)
    {
        require(
            msg.sender == tx.origin,
            "Minting from smart contracts is disallowed"
        );
        require(
            numLands + _numberMinted(msg.sender) <= maxMintPerAddress,
            "Max lands per address exceeded"
        );

        if (mintStartTokenId == 0) {
            mintStartTokenId = _nextTokenId();
        }

        _mintLands(msg.sender, numLands);

        uint256 elapsed = block.timestamp - mintStartTime;
        if (elapsed <= 1800 && !bonusMarketingFeeSet && totalSupply() - mintStartTokenId + 1 >= 750) {
            bonusMarketingFeeSet = true;
        }

        if (totalSupply() == MAX_LANDS) {
            transferEnabled = true;
            _payBonusMarketingFee(elapsed);
        }
    }

    // Internal functions

    function _presaleMintLands(uint256 numLands, uint256 maxLands) internal {
        require(
            numLands + presaleMinted[msg.sender] <= maxLands,
            "Max lands per address exceeded"
        );
        require(
            totalPresaleMinted + numLands <= MAX_PRESALE_LANDS,
            "Max presale lands exceeded"
        );

        presaleMinted[msg.sender] += numLands;
        totalPresaleMinted += numLands;
        _mintLands(msg.sender, numLands);
    }

    function _allowListMintLands(uint256 numLands, uint256 maxLands) internal {
        require(
            numLands + allowListMinted[msg.sender] <= maxLands,
            "Max lands per address exceeded"
        );
        require(
            totalAllowListMinted + numLands <= MAX_ALLOW_LIST_LANDS,
            "Max allow list lands exceeded"
        );

        if (allowListStartTokenId == 0) {
            allowListStartTokenId = _nextTokenId();
        }

        allowListMinted[msg.sender] += numLands;
        totalAllowListMinted += numLands;
        _mintLands(msg.sender, numLands);
    }

    function _mintLands(address recipient, uint256 numLands) internal {
        require(
            totalSupply() + numLands <= MAX_LANDS,
            "Max lands supply exceeded"
        );

        _mint(recipient, numLands);
    }

    function _payBonusMarketingFee(uint256 elapsed) internal {
        if (marketingWallet != address(0)) {
            uint256 _percent;
            if (elapsed <= 3600) {
                _percent = 8;
            } else if (bonusMarketingFeeSet) {
                _percent = 4;
            }
            if (_percent > 0) {
                uint256 amount = address(this).balance * _percent / 100;
                Address.sendValue(marketingWallet, amount);
            }
        }
    }

    function _verify(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (bool)
    {
        return hash.toEthSignedMessageHash().recover(signature) == signer;
    }

    // ERC721A

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        if (from == address(0)) {
            return;
        }

        if (allowListStartTokenId == 0 || startTokenId < allowListStartTokenId) {
            require(block.timestamp >= PRESALE_UNLOCK_TIME, "Transfer is not enabled");
        } else if (claimableStartTokenId == 0 || startTokenId < claimableStartTokenId) {
            require(transferEnabled, "Transfer is not enabled");
        } else if (mintStartTokenId == 0 || startTokenId < mintStartTokenId) {
            require(block.timestamp >= CLAIMABLE_UNLOCK_TIME, "Transfer is not enabled");
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // External functions

    function tokensOf(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function mintedPerAddress(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

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

        if (!revealed) {
            return hiddenMetadataURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    // Modifiers

    modifier onlyVerified(
        Round round,
        uint256 maxLands,
        bytes calldata signature
    ) {
        require(
            _verify(
                keccak256(
                    abi.encodePacked(msg.sender, uint256(round), maxLands)
                ),
                signature
            ),
            "Invalid signature"
        );
        _;
    }

    modifier mustMatchPrice(uint256 price, uint256 numLands) {
        require(
            msg.value == price * numLands,
            "Ether value sent is not correct"
        );
        _;
    }

    modifier mustBetween(uint256 startTime, uint256 endTime) {
        require(
            startTime > 0 &&
                startTime <= block.timestamp &&
                block.timestamp < endTime,
            "Mint not started"
        );
        _;
    }

    // Owner functions

    function setPresaleStartTime(uint256 _r1StartTime, uint256 _r2StartTime) external onlyOwner {
        presaleR1StartTime = _r1StartTime;
        presaleR2StartTime = _r2StartTime;
    }

    function setAllowListStartTime(uint256 _r1StartTime, uint256 _r2StartTime) external onlyOwner {
        allowListR1StartTime = _r1StartTime;
        allowListR2StartTime = _r2StartTime;
    }

    function setClaimableStartTime(uint256 _startTime) external onlyOwner {
        claimableStartTime = _startTime;
    }

    function setMintStartTime(uint256 _mintStartTime, uint256 _mintEndTime) external onlyOwner {
        mintStartTime = _mintStartTime;
        mintEndTime = _mintEndTime;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function burnSupply(uint256 _newSupply) external onlyOwner {
        require(_newSupply > 0, "New supply must > 0");
        require(
            _newSupply < MAX_LANDS,
            "Can only reduce max supply"
        );
        require(
            _newSupply >= totalSupply(),
            "Cannot burn more than current supply"
        );
        MAX_LANDS = _newSupply;
        transferEnabled = true;
    }

    function setMaxMintPerAddress(uint256 _maxMintPerAddress) external onlyOwner {
        maxMintPerAddress = _maxMintPerAddress;
    }

    function emergencyEnableTransfer() external onlyOwner {
        transferEnabled = true;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setHiddenMetadataURI(string memory _hiddenURI) external onlyOwner {
        hiddenMetadataURI = _hiddenURI;
    }

    function mintReservedLands(address recipient, uint256 numLands) external onlyOwner {
        require(
            totalReservedMinted + numLands <= MAX_RESERVED_LANDS,
            "Max reserved lands exceeded"
        );
        totalReservedMinted += numLands;
        _mintLands(recipient, numLands);
    }

    function setMarketingWallet(address payable _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function setProvenanceHash(string memory _provenance) external onlyOwner {
        PROVENANCE_HASH = _provenance;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function withdraw(uint256 amount) external onlyOwner {
        Address.sendValue(payable(owner()), amount);
    }
}