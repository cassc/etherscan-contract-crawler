// SPDX-License-Identifier: CODESEKAI
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CSKNFT is
    ERC721,
    EIP712,
    ERC721Enumerable,
    ERC721Burnable,
    AccessControl,
    Ownable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;

    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;
    address payable public adminWallet;
    address public signWallet;
    address public cskGen;

    string public constant SIGNING_DOMAIN = "CODESEKAI";
    string public constant SIGNATURE_VERSION = "1";
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TIMELOCK_DEV_ROLE = keccak256("TIMELOCK_DEV_ROLE");
    address public timelockAddress;

    Counters.Counter private tokenIdCounter;

    constructor(
        string memory _baseTokenUri,
        address payable _adminWallet,
        address payable _signWallet,
        address _timelockAddress
    ) ERC721("CodeSekaiNFT", "CSK") EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        require(_timelockAddress != address(0), "Invalid Timelock address");
        require(_signWallet != address(0), "Invalid signWallet address");
        require(_adminWallet != address(0), "Invalid adminWallet address");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TIMELOCK_DEV_ROLE, _timelockAddress);

        baseTokenURI = _baseTokenUri;
        adminWallet = _adminWallet;
        signWallet = _signWallet;
        timelockAddress = _timelockAddress;
    }

    uint256 public constant TOTAL_SUPPLY = 5_555;
    uint256 public PORTAL_PRICE = 0.0015 ether;
    uint256 public constant MAX_PORTAL_PRICE = 0.0015 ether;

    enum MintType {
        Whitelist,
        Waitlist,
        Mint
    }

    struct MintDates {
        uint256 START_WHITELIST;
        uint256 END_WHITELIST;
        uint256 START_WAITLIST;
        uint256 END_WAITLIST;
        uint256 MINT_START_DATE;
        uint256 MINT_END_DATE;
    }

    struct SignInfo {
        uint256 tokenId;
        string metadata;
        bool status;
        uint256 nonce;
        uint256 expirationTime;
        bytes signature;
    }

    struct UserAsset {
        uint256 tokenId;
        bool isAvailable;
        string metadata;
    }

    MintDates public mintDates;
    mapping(address => uint256) public updateTokenNonces;
    mapping(uint256 => UserAsset) public tokenInfo;

    event MintNft(
        address indexed userAddress,
        uint256 indexed tokenId,
        uint256 createdAt,
        string metadata,
        MintType indexed _mintType
    );

    event ChangeItemStatus(address indexed userAddress, SignInfo);
    event SetCSKGen(address indexed prevCSKGen, address indexed newCSKGen);
    event ChangeSignWallet(
        address indexed prevSignWallet,
        address indexed newSignWallet,
        address indexed executor
    );
    event SetBaseURI(string indexed prevBaseURI, string indexed baseURI);
    event SetAdminWallet(
        address indexed preAdminWallet,
        address indexed adminWallet
    );
    event SetPortalPrice(
        uint256 indexed prePortalPrice,
        uint256 indexed portalPrice
    );
    event SetPeriods(
        uint256 startWhitelistTime,
        uint256 endWhitelistTime,
        uint256 startWaitlistTime,
        uint256 endWaitlistTime,
        uint256 startMintTime,
        uint256 endMintTime,
        address indexed executer
    );

    event SetTimelock(
        address indexed prevTimelockAddress,
        address indexed newTimeLockAddress
    );

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        require(checkFlagStatus(tokenId), "not available");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) {
        require(checkFlagStatus(tokenId), "not available");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        require(checkFlagStatus(tokenId), "not available");
        super.transferFrom(from, to, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(
        string memory _baseTokenURI
    ) public onlyRole(TIMELOCK_DEV_ROLE) {
        require(bytes(_baseTokenURI).length != 0, "Invalid _baseTokenURI");
        string memory prevBaseURI = baseTokenURI;
        baseTokenURI = _baseTokenURI;

        emit SetBaseURI(prevBaseURI, baseTokenURI);
    }

    function getCurrentTokenId() public view returns (uint256) {
        return tokenIdCounter.current();
    }

    function checkFlagStatus(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId);
        return tokenInfo[tokenId].isAvailable;
    }

    function checkMetadata(
        uint256 tokenId
    ) public view returns (string memory) {
        _requireMinted(tokenId);
        return tokenInfo[tokenId].metadata;
    }

    function _hash(SignInfo memory info) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "SignInfo(uint256 tokenId,string metadata,bool status,uint256 nonce,uint256 expirationTime)"
                        ),
                        info.tokenId,
                        keccak256(bytes(info.metadata)),
                        info.status,
                        info.nonce,
                        info.expirationTime
                    )
                )
            );
    }

    function _verify(SignInfo memory info) internal view returns (address) {
        bytes32 digest = _hash(info);
        return ECDSA.recover(digest, info.signature);
    }

    function getUserTokenAndInfos(
        address userAddress,
        uint256 cursor,
        uint256 resultsPerPage
    ) public view returns (UserAsset[] memory userAssets, uint256 newCursor) {
        uint256 balances = balanceOf(userAddress);
        require(cursor <= balances, "cursor is out of range");
        require(resultsPerPage > 0, "resultsPerPage cannot be 0");
        uint256 length = resultsPerPage;
        if (length > balances - cursor) {
            length = balances - cursor;
        }
        userAssets = new UserAsset[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(userAddress, cursor + i);
            string memory metadata = tokenInfo[tokenId].metadata;
            bool status = checkFlagStatus(tokenId);
            userAssets[i].tokenId = tokenId;
            userAssets[i].isAvailable = status;
            userAssets[i].metadata = metadata;
        }

        return (userAssets, cursor + length);
    }

    function setPeriods(
        uint256 startWhitelistTime,
        uint256 endWhitelistTime,
        uint256 startWaitlistTime,
        uint256 endWaitlistTime,
        uint256 startMintTime,
        uint256 endMintTime
    ) public onlyRole(TIMELOCK_DEV_ROLE) {
        require(
            endWhitelistTime > startWhitelistTime,
            "invalid whitelist time"
        );
        require(endWaitlistTime > startWaitlistTime, "invalid waitlist time");
        require(endMintTime > startMintTime, "invalid mint time");
        require(
            (endWhitelistTime < startWaitlistTime) &&
                (endWaitlistTime < startMintTime),
            "invalid periods"
        );
        mintDates.START_WHITELIST = startWhitelistTime;
        mintDates.END_WHITELIST = endWhitelistTime;
        mintDates.START_WAITLIST = startWaitlistTime;
        mintDates.END_WAITLIST = endWaitlistTime;
        mintDates.MINT_START_DATE = startMintTime;
        mintDates.MINT_END_DATE = endMintTime;

        emit SetPeriods(
            startWhitelistTime,
            endWhitelistTime,
            startWaitlistTime,
            endWaitlistTime,
            startMintTime,
            endMintTime,
            _msgSender()
        );
    }

    function delMint(address _userAddr, string memory metadata) internal {
        uint256 currentSupply = totalSupply();
        require(currentSupply < TOTAL_SUPPLY, "Max supply");

        //start tokenId at 1
        tokenIdCounter.increment();
        uint256 tokenId = tokenIdCounter.current();

        tokenInfo[tokenId] = UserAsset(tokenId, true, metadata);
        _safeMint(_userAddr, tokenId);
    }

    function mint(
        address _userAddr,
        string calldata metadata,
        MintType _mintType
    ) external {
        require(cskGen == _msgSender(), "permission denied");

        if (_mintType == MintType.Mint) {
            require(
                block.timestamp >= mintDates.MINT_START_DATE,
                "not started."
            );
            require(block.timestamp <= mintDates.MINT_END_DATE, "ended.");
        } else if (_mintType == MintType.Whitelist) {
            require(
                block.timestamp >= mintDates.START_WHITELIST,
                "Wl not started."
            );
            require(block.timestamp <= mintDates.END_WHITELIST, "Wl ended.");
        } else if (_mintType == MintType.Waitlist) {
            require(
                block.timestamp >= mintDates.START_WAITLIST,
                "Waitlist not started."
            );
            require(
                block.timestamp <= mintDates.END_WAITLIST,
                "Waitlist ended."
            );
        }

        delMint(_userAddr, metadata);

        emit MintNft(
            _userAddr,
            tokenIdCounter.current(),
            block.timestamp,
            metadata,
            _mintType
        );
    }

    function setAdminWallet(
        address _adminWallet
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_adminWallet != address(0), "Invalid adminWallet");
        address prevAdminWallet = adminWallet;
        adminWallet = payable(_adminWallet);
        emit SetAdminWallet(prevAdminWallet, _adminWallet);
    }

    function setPortalPrice(
        uint256 newPrice
    ) public onlyRole(TIMELOCK_DEV_ROLE) {
        require(newPrice <= MAX_PORTAL_PRICE, "invalid portal price");
        uint256 prevPortalPrice = PORTAL_PRICE;
        PORTAL_PRICE = newPrice;
        emit SetPortalPrice(prevPortalPrice, newPrice);
    }

    function setCSKGen(address newCSKGen) public onlyRole(TIMELOCK_DEV_ROLE) {
        require(newCSKGen != address(0), "Invalid address");
        address prevCSKGen = cskGen;
        cskGen = newCSKGen;
        emit SetCSKGen(prevCSKGen, newCSKGen);
    }

    function updateFlagStatus(
        SignInfo calldata _info
    ) external payable nonReentrant {
        require(ownerOf(_info.tokenId) == msg.sender, "Not Owner.");
        require(
            tokenInfo[_info.tokenId].isAvailable != _info.status,
            "Same status."
        );
        require(block.timestamp < _info.expirationTime, "Times out");

        //verify
        address signer = _verify(_info);
        require(signer == signWallet, "not signed");
        require(
            _info.nonce == updateTokenNonces[msg.sender]++,
            "Invalid nonce"
        );

        if (_info.status) {
            require(msg.value == PORTAL_PRICE, "Invalid Amount");

            tokenInfo[_info.tokenId].metadata = _info.metadata;

            (bool sent, ) = adminWallet.call{value: msg.value}("");
            require(sent, "Failed send");
        }

        tokenInfo[_info.tokenId].isAvailable = _info.status;

        emit ChangeItemStatus(msg.sender, _info);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) public override {
        require(checkFlagStatus(tokenId), "not available");
        delete tokenInfo[tokenId];
        super.burn(tokenId);
    }

    function setSignWallet(
        address _signWallet
    ) public onlyRole(TIMELOCK_DEV_ROLE) {
        require(_signWallet != address(0), "Invalid address");
        address prevSignWallet = signWallet;
        signWallet = _signWallet;
        emit ChangeSignWallet(prevSignWallet, signWallet, msg.sender);
    }

    function setTimelock(
        address newTimelockAddress
    ) external onlyRole(TIMELOCK_DEV_ROLE) {
        require(
            newTimelockAddress != address(0),
            "Invalid newTimelockAddress address"
        );
        address prevTimelockAddress = timelockAddress;
        timelockAddress = newTimelockAddress;
        _revokeRole(TIMELOCK_DEV_ROLE, prevTimelockAddress);
        _grantRole(TIMELOCK_DEV_ROLE, newTimelockAddress);
        emit SetTimelock(prevTimelockAddress, newTimelockAddress);
    }

    function grantRole(
        bytes32 role,
        address account
    ) public virtual override(AccessControl) onlyRole(TIMELOCK_DEV_ROLE) {
        _grantRole(role, account);
    }

    function renounceRole(
        bytes32 role,
        address account
    ) public virtual override(AccessControl) {
        require(
            !(hasRole(DEFAULT_ADMIN_ROLE, account)),
            "AccessControl: cannot renounce the DEFAULT_ADMIN_ROLE account"
        );
        super.renounceRole(role, account);
    }

    function revokeRole(
        bytes32 role,
        address account
    ) public virtual override(AccessControl) onlyRole(TIMELOCK_DEV_ROLE) {
        _revokeRole(role, account);
    }
}