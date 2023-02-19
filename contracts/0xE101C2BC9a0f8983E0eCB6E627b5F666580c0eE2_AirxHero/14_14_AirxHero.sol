//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

enum MintType {
    NONE_MINT,
    RANDOM_MINT,
    AIRDROP_MINT
}

/**
 * @notice AirxHero on ethereum chains
 * @dev token id and airdrop id starts at 1 but not zero.
 */
contract AirxHero is Ownable, ERC721Enumerable {
    using Strings for uint256;

    bool public paused = true;

    string public uriPrefix = "https://airxhero.herokuapp.com/api/token";

    /// Price is 0.05ETH
    uint256 public price = 0.05 ether;
    /// Airdrop amount
    uint256 public totalAirdropAmount = 1000;
    uint256 public totalSupplyLimit = 5050;
    /// airdrop indexer
    uint256 public airdropIdCounter = 0;
    /// token id map indexer
    uint256 public generalIdCounter = 0;
    /// admin address
    address public admin;

    /// address => token id
    mapping(address => uint256) private userLastTokenId;
    /// token id => Mint type
    mapping(uint256 => MintType) private tokenType;
    mapping(uint256 => uint256) private tokenIdMap;
    /// token id => token Level
    mapping(uint256 => uint256) private levels;

    /// Level changes
    event HeroLevel(uint256 _tokenId, uint256 _newLevel, uint256 _preLevel);

    constructor() ERC721("AIRx HERO", "HERO") {
        admin = _msgSender();
    }

    /**
     * @notice get your last token Id
     * @param _sender address of target user
     */
    function getYourLastTokenId(
        address _sender
    ) external view returns (uint256) {
        return userLastTokenId[_sender];
    }

    /**
     * @notice get map ID from token ID
     * @param _tokenId token id
     */
    function getTokenMapId(uint256 _tokenId) external view returns (uint256) {
        return tokenIdMap[_tokenId];
    }

    /**
     * @notice get level from token ID
     * @param _tokenId token id
     */
    function getLevel(uint256 _tokenId) external view returns (uint256) {
        return levels[_tokenId];
    }

    /**
     * @notice get token type of target token ID
     * @param _tokenId token id
     */
    function getTokenType(uint256 _tokenId) external view returns (MintType) {
        return tokenType[_tokenId];
    }

    /**
     * @notice increase level of hero
     * @param _level increase amount of level
     * @param _tokenId hero token id
     */
    function increaseLevel(uint256 _level, uint256 _tokenId) external {
        require(admin == _msgSender(), "Invalid admin");
        require(_level != 0, "Invalid number");
        uint256 curLevel = levels[_tokenId];
        levels[_tokenId] = curLevel + _level;
        emit HeroLevel(_tokenId, levels[_tokenId], curLevel);
    }

    /**
     * @notice decrease level of hero
     * @param _level decrease amount of level
     * @param _tokenId hero token id
     */
    function decreaseLevel(uint256 _level, uint256 _tokenId) external {
        require(admin == _msgSender(), "Invalid admin");
        require(levels[_tokenId] >= _level, "Invalid admin");
        require(_level != 0, "Invalid number");

        uint256 curLevel = levels[_tokenId];
        levels[_tokenId] = curLevel - _level;

        emit HeroLevel(_tokenId, levels[_tokenId], curLevel);
    }

    /**
     * update admin address
     * @param _newAdmin new admin address
     */
    function updateAdmin(address _newAdmin) external onlyOwner {
        require(admin != _newAdmin, "Same admin");
        admin = _newAdmin;
    }

    /**
     * @notice Customers can mint Hero
     */
    function mintRandomHero(uint256 _mintCount) external payable {
        require(!paused, "The contract is paused!");
        if (msg.sender != owner()) {
            require(
                msg.value >= price * _mintCount,
                "Please send the exact amount."
            );
        }

        for (uint256 i = 0; i < _mintCount; i++) {
            mint(MintType.RANDOM_MINT, msg.sender);
        }
    }

    /**
     * @notice Hero will be airdropped to AIRxKicks & AIRx holders
     * @param _users array of target addresses
     */
    function airdropHero(address[] calldata _users) external onlyOwner {
        uint256 len = _users.length;
        require(totalAirdropAmount >= airdropIdCounter + len, "No more");

        for (uint256 i = 0; i < len; i++) {
            address _user = _users[i];
            require(_user != address(0), "Invalid address");
            mint(MintType.AIRDROP_MINT, _user);
        }
    }

    /**
     * @notice Update total supply limit
     */
    function updateTotalSupplyLimit(
        uint256 _totalSupplyLimit
    ) external onlyOwner {
        require(
            _totalSupplyLimit >= totalAirdropAmount + generalIdCounter,
            "Invalid amount"
        );

        totalSupplyLimit = _totalSupplyLimit;
    }

    /**
     * @notice Update total airdrop amount
     */
    function updateTotalAirdropAmount(
        uint256 _totalAirdropAmount
    ) external onlyOwner {
        require(
            totalSupplyLimit >= _totalAirdropAmount + generalIdCounter,
            "Overflow total supply limit"
        );
        require(_totalAirdropAmount >= airdropIdCounter, "Too small");

        totalAirdropAmount = _totalAirdropAmount;
    }

    function changePrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    function mint(MintType _mintType, address _user) private {
        uint256 currentIndex = totalSupply();
        uint256 id = currentIndex + 1;
        require(totalSupplyLimit >= id, "Overflow total supply");
        require(_mintType != MintType.NONE_MINT, "Invalid mint type");

        userLastTokenId[_user] = id;
        tokenType[id] = _mintType;

        if (_mintType == MintType.AIRDROP_MINT) {
            airdropIdCounter = airdropIdCounter + 1;
            tokenIdMap[id] = airdropIdCounter;
        } else {
            generalIdCounter = generalIdCounter + 1;
            require(
                totalSupplyLimit - totalAirdropAmount >= generalIdCounter,
                "No more"
            );

            tokenIdMap[id] = generalIdCounter;
        }
        _safeMint(_user, id);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();

        if (bytes(currentBaseURI).length > 0) {
            // uint256 mapId = tokenIdMap[_tokenId];
            if (tokenType[_tokenId] == MintType.RANDOM_MINT) {
                return
                    string(
                        abi.encodePacked(
                            currentBaseURI,
                            "/general/",
                            _tokenId.toString()
                        )
                    );
            } else {
                return
                    string(
                        abi.encodePacked(
                            currentBaseURI,
                            "/airdrop/",
                            _tokenId.toString()
                        )
                    );
            }
        } else {
            return "";
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}