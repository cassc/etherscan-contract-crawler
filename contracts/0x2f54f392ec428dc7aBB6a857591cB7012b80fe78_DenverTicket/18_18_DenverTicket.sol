// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract DenverTicket is
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC721Upgradeable
{
    using StringsUpgradeable for uint256;

    uint256 private _tokenIdCounter;
    address private _admin;

    string public baseURI;

    uint256 public startTime;
    uint256 public endTime;

    mapping(address => bool) public mintWhitelist;
    mapping(address => bool) public mintAddresses;
    mapping(uint256 => bool) public mintTickets;
    uint256 public totalMinted;
    uint256 public maxMint;
    uint256 public totalAirdrop;

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    modifier mintTime() {
        require(
            startTime > 0 && block.timestamp > startTime,
            "mint has not started"
        );
        require(block.timestamp < endTime, "mint has ended");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(
            msg.sender == _admin || msg.sender == owner(),
            "only admin or owner can operate"
        );
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _maxMint
    ) external initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();

        require(_maxMint > 0, "_maxMint should more than 0");
        maxMint = _maxMint;
        _tokenIdCounter = 1;
    }

    //-------------------------------
    //------- Owner functions -------
    //-------------------------------

    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

    function setMaxMint(uint256 _maxMint) external onlyAdminOrOwner {
        require(_maxMint > totalSupply(), "please set correct max supply");
        maxMint = _maxMint;
    }

    function setMintTime(uint256 _startTime, uint256 _endTime)
        external
        onlyAdminOrOwner
    {
        require(
            _startTime < _endTime && _startTime > 0,
            "please set correct mint time"
        );
        startTime = _startTime;
        endTime = _endTime;
    }

    function setBaseUri(string calldata _baseUri) external onlyAdminOrOwner {
        baseURI = _baseUri;
    }

    function setWhitelist(address[] calldata accounts, bool knob)
        external
        onlyAdminOrOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            // Already set the same value
            if (mintWhitelist[accounts[i]] == knob) {
                continue;
            }
            mintWhitelist[accounts[i]] = knob;
        }
    }

    /**
     *  @notice 1. Airdrops quantity is not included in totalSupply().
     *          2. Account will be airdropped whether the account has been mint tickets or not.
     *             The operation is controlled by the ADMIN or OWNER.
     */
    function airdrop(address[] calldata _tos) external onlyAdminOrOwner {
        uint256 currentTokenId = _tokenIdCounter;

        _tokenIdCounter += _tos.length;
        totalAirdrop += _tos.length;

        for (uint256 i = 0; i < _tos.length; ) {
            _safeMint(_tos[i], currentTokenId);

            unchecked {
                ++currentTokenId;
                ++i;
            }
        }
    }

    function burn(uint256 _tokenId) external onlyAdminOrOwner {
        if (mintTickets[_tokenId]) {
            --totalMinted;
        } else {
            --totalAirdrop;
        }

        _burn(_tokenId);
    }

    //-------------------------------
    //------- User functions --------
    //-------------------------------
    function mint() external mintTime returns (bool) {
        require(checkWhitelist(msg.sender), "only whitelist address");
        require(!mintAddresses[msg.sender], "Already minted.");
        require(totalMinted + 1 <= maxMint, "reached maxSupply");

        uint256 currentTokenId = _tokenIdCounter;

        ++_tokenIdCounter;
        mintAddresses[msg.sender] = true;
        mintTickets[currentTokenId] = true;
        ++totalMinted;

        _safeMint(msg.sender, currentTokenId);
        return true;
    }

    //-------------------------------
    //------- view functions --------
    //-------------------------------
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function totalSupply() public view returns (uint256) {
        return totalMinted;
    }

    // For back-end
    function checkWhitelist(address account) public view returns (bool) {
        return mintWhitelist[account];
    }
}