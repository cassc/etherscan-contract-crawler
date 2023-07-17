// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/IPudgyPanda.sol";
import "../interfaces/IPudgyPandaMetadata.sol";

contract PudgyPanda is
    ERC721Enumerable,
    Ownable,
    IPudgyPanda,
    IPudgyPandaMetadata
{
    using Strings for uint256;

    uint256 public constant PANDA_OWNER = 20;
    uint256 public constant PANDA_GIFT = 100;
    uint256 public constant PANDA_PUBLIC = 9880;
    uint256 public constant PANDA_MAX = PANDA_OWNER + PANDA_GIFT + PANDA_PUBLIC;

    uint256 public mintPrice = 0.045 ether;
    uint256 public publicMaxMint = 16;
    uint256 public allowListMaxMint = 6;

    bool public isActive = false;
    bool public isAllowListActive = false;
    bool public isLocked = false;
    string public baseExtension = ".json";
    string public proof;

    /// @dev We will use these to be able to calculate remaining correctly.
    uint256 public totalGiftSupply;
    uint256 public totalPublicSupply;

    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _allowListClaimed;

    string private _contractURI = "";
    string private _tokenBaseURI = "";

    uint256 private _lockerCounter = 0;

    address t1 = 0x4ba6cfE4992399fD0858A702C77fCb5B416FdF37;
    address t2 = 0xF5264EF3D443C1c981b0e8FB106a1e9d97093FB8;
    address t3 = 0x4A4406FF8DD1D3AC06Ded163DD5BF481AdA67039;

    modifier notLocked() {
        require(!isLocked, "Contract has been locked");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory initContractURI
    ) ERC721(name, symbol) {
        _contractURI = initContractURI;
        _ownerStarterMint();
    }

    function addToAllowList(address[] calldata addresses)
        external
        override
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _allowList[addresses[i]] = true;
            /**
             * @dev We don't want to reset _allowListClaimed count
             * if we try to add someone more than once.
             */
            _allowListClaimed[addresses[i]] > 0
                ? _allowListClaimed[addresses[i]]
                : 0;
        }
    }

    function onAllowList(address addr) external view override returns (bool) {
        return _allowList[addr];
    }

    function removeFromAllowList(address[] calldata addresses)
        external
        override
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            /// @dev We don't want to reset possible _allowListClaimed numbers.
            _allowList[addresses[i]] = false;
        }
    }

    /**
     * @dev We want to be able to distinguish tokens bought during isAllowListActive
     * and tokens bought outside of isAllowListActive
     */
    function allowListClaimedBy(address owner)
        external
        view
        override
        returns (uint256)
    {
        require(owner != address(0), "Zero address not on Allow List");

        return _allowListClaimed[owner];
    }

    function purchase(uint256 numberOfTokens) external payable override {
        require(isActive, "Contract is not active");
        require(!isAllowListActive, "Only allowing from Allow List");
        require(totalSupply() < PANDA_MAX, "All tokens have been minted");
        require(numberOfTokens < publicMaxMint, "Would exceed publicMaxMint");
        /**
         * @dev The last person to purchase might pay too much.
         * This way however they can't get sniped.
         * If this happens, we'll refund the Eth for the unavailable tokens.
         */
        require(
            totalPublicSupply < PANDA_PUBLIC,
            "Purchase would exceed PANDA_PUBLIC"
        );
        require(
            mintPrice * numberOfTokens <= msg.value,
            "ETH amount is not sufficient"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            /**
             * @dev Since they can get here while exceeding the PANDA_MAX,
             * we have to make sure to not mint any additional tokens.
             */
            if (totalPublicSupply < PANDA_PUBLIC) {
                /**
                 * @dev Public token numbering starts after PANDA_GIFT.
                 * And we don't want our tokens to start at 0 but at 1.
                 */
                uint256 tokenId = PANDA_OWNER +
                    PANDA_GIFT +
                    totalPublicSupply +
                    1;

                totalPublicSupply += 1;
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function purchaseAllowList(uint256 numberOfTokens)
        external
        payable
        override
    {
        require(isActive, "Contract is not active");
        require(isAllowListActive, "Allow List is not active");
        require(_allowList[msg.sender], "You are not on the Allow List");
        require(totalSupply() < PANDA_MAX, "All tokens have been minted");
        require(
            numberOfTokens < allowListMaxMint,
            "Cannot purchase this many tokens"
        );
        require(
            totalPublicSupply + numberOfTokens <= PANDA_PUBLIC,
            "Purchase would exceed PANDA_PUBLIC"
        );
        require(
            _allowListClaimed[msg.sender] + numberOfTokens < allowListMaxMint,
            "Purchase exceeds max allowed"
        );
        require(
            mintPrice * numberOfTokens <= msg.value,
            "ETH amount is not sufficient"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            /**
             * @dev Public token numbering starts after PANDA_GIFT.
             * We don't want our tokens to start at 0 but at 1.
             */
            uint256 tokenId = PANDA_OWNER + PANDA_GIFT + totalPublicSupply + 1;

            totalPublicSupply += 1;
            _allowListClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        string memory currentBaseURI = _baseURI();
        return
            string(
                abi.encodePacked(
                    currentBaseURI,
                    tokenId.toString(),
                    baseExtension
                )
            );
    }

    function walletOfOwner(address _owner)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // Admin methods
    function ownerMint(uint256 quantity) external override onlyOwner {
        for (uint256 i = 0; i < quantity; i++) {
            _mintInternal(msg.sender);
        }
    }

    function gift(address[] calldata to) external override onlyOwner {
        // require(totalSupply() < PANDA_MAX, "All tokens have been minted");
        require(
            totalGiftSupply + to.length <= PANDA_GIFT,
            "Not enough tokens left to gift"
        );

        for (uint256 i = 0; i < to.length; i++) {
            /// @dev We don't want our tokens to start at 0 but at 1.
            uint256 tokenId = PANDA_OWNER + totalGiftSupply + 1;

            totalGiftSupply += 1;
            _safeMint(to[i], tokenId);
        }
    }

    function setIsActive(bool _isActive) external override onlyOwner {
        isActive = _isActive;
    }

    function setIsAllowListActive(bool _isAllowListActive)
        external
        override
        onlyOwner
    {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowListMaxMint(uint256 maxMint) external override onlyOwner {
        allowListMaxMint = maxMint;
    }

    function setPublicMaxMint(uint256 maxMint) external override onlyOwner {
        publicMaxMint = maxMint;
    }

    function setProof(string calldata proofString)
        external
        override
        onlyOwner
        notLocked
    {
        proof = proofString;
    }

    function setContractURI(string calldata URI)
        external
        override
        onlyOwner
        notLocked
    {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI)
        external
        override
        onlyOwner
        notLocked
    {
        _tokenBaseURI = URI;
    }

    function lock() external override onlyOwner {
        _lockerCounter += 1;
        if (_lockerCounter >= 5) {
            isLocked = true;
        }
    }

    function emergencyWithdraw() external payable override {
        require(msg.sender == t1, "Wrong sender address");
        (bool success, ) = payable(t1).call{value: address(this).balance}("");
        require(success);
    }

    function withdrawAll() external payable override onlyOwner {
        uint256 _each = address(this).balance / 3;
        require(payable(t1).send(_each));
        require(payable(t2).send(_each));
        require(payable(t3).send(_each));
    }

    function setMintPrice(uint256 price) external override onlyOwner {
        mintPrice = price;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    // Private Methods
    function _ownerStarterMint() private {
        // require(!_exists(1), "Owner tokens already minted");
        _safeMint(t1, 1);
        _safeMint(t2, 2);
        _safeMint(t3, 3);
        for (uint256 i = 3; i < PANDA_OWNER; i++) {
            uint256 tokenId = i + 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function _mintInternal(address owner) private {
        uint256 tokenId = PANDA_OWNER + PANDA_GIFT + totalPublicSupply + 1;
        totalPublicSupply += 1;
        _safeMint(owner, tokenId);
    }
}